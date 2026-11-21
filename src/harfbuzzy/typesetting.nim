## Wrap and position HarfBuzz-shaped paragraphs without a renderer.

import std/[algorithm, unicode]
import ../harfbuzzy
import ./paragraph
import ./private/positionedlayout

export layout

type FontMetrics = object
  xScale, yScale: float32
  baseline, height: float32

const UnsafeToBreak = 1'u32

func pixelScale(units: int, size: float32): float32 =
  if units == 0:
    1'f32
  else:
    size / abs(units.float32)

proc metrics(typeface: Typeface, size: float32): FontMetrics =
  let scale = typeface.font.scale
  result.xScale = pixelScale(scale.x, size)
  result.yScale = pixelScale(scale.y, size)
  try:
    let extents = typeface.font.horizontalExtents()
    result.baseline =
      (extents.ascender.float32 + extents.lineGap.float32 / 2) * result.yScale
    result.height = max(extents.lineAdvance.float32 * result.yScale, size)
  except ValueError:
    result.baseline = size
    result.height = size

iterator hardParagraphs(text: string): tuple[start, stop, breakBytes: int] =
  var start = 0
  while true:
    var stop = start
    while stop < text.len and text[stop] notin {'\r', '\n'}:
      inc stop
    let length =
      if stop == text.len:
        0
      elif text[stop] == '\r' and stop + 1 < text.len and text[stop + 1] == '\n':
        2
      else:
        1
    yield (start, stop, length)
    if length == 0:
      break
    start = stop + length

iterator clusters(run: ShapedRun): tuple[first, after, byteStart, byteEnd: int] =
  var
    first = 0
    previous = run.textRun.byteEnd
  let rtl = run.textRun.direction == Direction.rtl
  while first < run.glyphRun.glyphs.len:
    let start = int(run.glyphRun.glyphs[first].cluster)
    var after = first + 1
    while after < run.glyphRun.glyphs.len and
        int(run.glyphRun.glyphs[after].cluster) == start:
      inc after
    let stop =
      if rtl:
        previous
      elif after < run.glyphRun.glyphs.len:
        int(run.glyphRun.glyphs[after].cluster)
      else:
        run.textRun.byteEnd
    yield (first, after, start, stop)
    previous = start
    first = after

proc layoutText*(
    context: ShapeContext,
    text: string,
    fontSize: float32,
    options = ParagraphLayoutOptions(),
): PositionedText =
  ## Positions glyphs in pixel units. Glyph IDs index the selected typeface in
  ## `context.typefaces`. Source ranges refer to the original UTF-8 string.
  ## Clusters use monotone grapheme boundaries for wrapping and selection.
  if context.typefaces.len == 0:
    raise newException(ValueError, "layout requires at least one typeface")
  if not (fontSize > 0 and fontSize < float32.high):
    raise newException(ValueError, "layout requires a positive finite font size")

  var context = context
  context.options.clusterLevel = ClusterLevel.monotoneGraphemes
  var fontMetrics = newSeqOfCap[FontMetrics](context.typefaces.len)
  for typeface in context.typefaces:
    fontMetrics.add typeface.metrics(fontSize)

  result.sourceRunes = text
  if text.len == 0:
    return
  var
    paragraphs: seq[LayoutParagraph]
    safe: seq[bool]
    runeOffset = 0
  for (byteStart, byteEnd, breakBytes) in text.hardParagraphs:
    let part = text[byteStart ..< byteEnd]
    let shaped = context.shapeParagraph(part)
    let firstGlyph = result.arrangedGlyphs.len
    var offsets: seq[int]
    var index = 0
    while index < part.len:
      offsets.add index
      index += part.runeLenAt(index)
    offsets.add part.len
    var pen = vec2(0, 0)
    for run in shaped.visualRuns:
      let metrics = fontMetrics[run.typefaceIndex]
      for (first, after, start, stop) in run.clusters:
        let
          runeStart = offsets.lowerBound(start)
          runeEnd = offsets.lowerBound(stop)
          source = GlyphSourceRange(
            byteStart: byteStart + start,
            byteEnd: byteStart + stop,
            runeStart: runeOffset + runeStart,
            runeEnd: runeOffset + runeEnd,
          )
          rune = part.runeAt(start)
        var whitespace = true
        for i in runeStart ..< runeEnd:
          if not part.runeAt(offsets[i]).isSpaceRune:
            whitespace = false
            break
        for i in first ..< after:
          let
            glyph = run.glyphRun.glyphs[i]
            advance = vec2(
              glyph.xAdvance.float32 * metrics.xScale,
              -glyph.yAdvance.float32 * metrics.yScale,
            )
            offset = vec2(
              glyph.xOffset.float32 * metrics.xScale,
              -glyph.yOffset.float32 * metrics.yScale,
            )
            pos = pen + offset + vec2(0, metrics.baseline)
          result.appendGlyph LayoutGlyph(
            fontId: run.typefaceIndex,
            glyphId: glyph.codepoint,
            source: source,
            rune: rune,
            isWhitespace: whitespace,
            pos: pos,
            advance: advance,
            offset: offset,
            rect: rect(pos.x, pos.y - metrics.baseline, abs(advance.x), metrics.height),
          )
          safe.add i + 1 == run.glyphRun.glyphs.len or
            (run.glyphRun.glyphs[i + 1].flags and UnsafeToBreak) == 0
          pen += advance

    if result.arrangedGlyphs.len == firstGlyph:
      let metrics = fontMetrics[0]
      result.appendGlyph LayoutGlyph(
        source: GlyphSourceRange(
          byteStart: byteStart,
          byteEnd: byteStart,
          runeStart: runeOffset,
          runeEnd: runeOffset,
        ),
        isWhitespace: true,
        pos: vec2(0, metrics.baseline),
        rect: rect(0, 0, 0, metrics.height),
      )
      safe.add true

    paragraphs.add LayoutParagraph(
      glyphs: firstGlyph .. result.arrangedGlyphs.high,
      style: options.style,
      language: options.language,
      rightToLeft: shaped.baseDirection == Direction.rtl,
    )
    runeOffset += offsets.high + breakBytes

  proc hyphen(fontId: int): PositionedHyphen =
    let font = context.typefaces[fontId].font
    try:
      let glyphId = font.nominalGlyph(uint32('-'))
      result = PositionedHyphen(
        found: true,
        glyphId: glyphId,
        advance: font.horizontalAdvance(glyphId).float32 * fontMetrics[fontId].xScale,
      )
    except ValueError:
      discard

  result.finishLayout(paragraphs, safe, options, hyphen)
