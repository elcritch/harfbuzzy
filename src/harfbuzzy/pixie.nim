## Optional paragraph layout frontend using Pixie fonts and character metrics.

import std/[strutils, unicode]
import pkg/pixie/fonts as px
import pkg/vmath as pixieMath
import ./paragraph
import ./private/positionedlayout

export layout

func glyphGeometry(
    arrangement: px.Arrangement, index: int
): tuple[pos: LayoutPoint, selection: LayoutRect] =
  let
    pos = arrangement.positions[index]
    selection = arrangement.selectionRects[index]
  (
    positionedlayout.vec2(pos.x, pos.y),
    rect(selection.x, selection.y, selection.w, selection.h),
  )

func hasSoftWrap(arrangement: px.Arrangement): bool =
  for i in 0 ..< arrangement.lines.high:
    let (first, last) = arrangement.lines[i]
    if last < first or arrangement.runes[last] != Rune('\n'):
      return true

proc layoutText*(
    spans: openArray[px.Span], options = ParagraphLayoutOptions()
): PositionedText =
  ## Glyph IDs are Pixie rune values. Font IDs index the input spans, including
  ## spans that contain only filtered controls. Native Pixie wrapping is used
  ## for default paragraph styles; styled paragraphs use the shared breaker.
  ## Intrinsic sizes are measured before viewport wrapping and alignment.
  for span in spans:
    if span.isNil or span.font.isNil or span.font.typeface.isNil:
      raise newException(ValueError, "Pixie layout requires a font for each span")
    if span.text.validateUtf8() >= 0:
      raise newException(ValueError, "invalid UTF-8 in Pixie span")
    result.sourceRunes.add span.text

  let styled = not options.style.isDefault or "\u00AD" in result.sourceRunes
  let horizontal =
    case options.horizontal
    of Left: px.LeftAlign
    of Center: px.CenterAlign
    of Right: px.RightAlign
  let vertical =
    case options.vertical
    of Top: px.TopAlign
    of Middle: px.MiddleAlign
    of Bottom: px.BottomAlign
  let positioned =
    if styled:
      px.typeset(spans, wrap = false)
    else:
      px.typeset(
        spans,
        pixieMath.vec2(options.width, options.height),
        horizontal,
        vertical,
        options.wrap,
      )
  # Pixie rounds selection boxes after wrapping and alignment. Measure the
  # original paragraph geometry if either operation can change those boxes.
  let arrangement =
    if not styled and positioned.runes.len > 0 and (
      horizontal != px.LeftAlign or vertical != px.TopAlign or positioned.hasSoftWrap()
    ):
      px.typeset(spans, wrap = false)
    else:
      positioned

  var
    sourceByte = 0
    sourceRune = 0
    displayIndex = 0
  for fontId, span in spans:
    var index = 0
    while index < span.text.len:
      let start = index
      var rune: Rune
      fastRuneAt(span.text, index, rune, true)
      # Match Pixie's control filtering. Case conversion does not change the
      # source range or the association with the original font span.
      if rune.uint32 >= 32 or rune == Rune(10):
        if displayIndex >= arrangement.runes.len:
          raise newException(ValueError, "Pixie glyphs do not match the source spans")
        let
          display = arrangement.runes[displayIndex]
          (pos, selection) = arrangement.glyphGeometry(displayIndex)
        result.appendGlyph LayoutGlyph(
          fontId: fontId,
          glyphId: display.uint32,
          source: GlyphSourceRange(
            byteStart: sourceByte + start,
            byteEnd: sourceByte + index,
            runeStart: sourceRune,
            runeEnd: sourceRune + 1,
          ),
          rune: display,
          isWhitespace: display.isSpaceRune,
          pos: pos,
          advance: positionedlayout.vec2(selection.w, 0),
          rect: selection,
        )
        inc displayIndex
      inc sourceRune
    sourceByte += span.text.len
  if displayIndex != arrangement.runes.len:
    raise newException(ValueError, "Pixie glyphs do not match the source spans")

  var paragraphs = newSeqOfCap[LayoutParagraph](arrangement.lines.len)
  for (first, last) in arrangement.lines:
    paragraphs.add LayoutParagraph(
      glyphs: first .. last, style: options.style, language: options.language
    )
  if styled:
    # The resolver is used only while this call owns the openArray.
    let fontSpans = @spans
    proc hyphen(fontId: int): PositionedHyphen =
      let font = fontSpans[fontId].font
      let rune = Rune('-')
      if not px.fallbackTypeface(font.typeface, rune).isNil:
        result = PositionedHyphen(
          found: true,
          glyphId: rune.uint32,
          advance: px.getAdvance(font.typeface, rune) * px.scale(font),
        )

    result.finishLayout(paragraphs, [], options, hyphen)
  else:
    result.measureParagraphs(paragraphs)
    if positioned != arrangement:
      for i, glyph in result.arrangedGlyphs.mpairs:
        let (pos, selection) = positioned.glyphGeometry(i)
        glyph.pos = pos
        glyph.rect = selection
        glyph.advance.x = selection.w
        result.positions[i] = pos
        result.selectionRects[i] = selection
    for (first, last) in positioned.lines:
      result.lines.add first .. last
    result.bounding = result.calcMinMaxContent().bounding

proc layoutText*(
    font: px.Font, text: string, options = ParagraphLayoutOptions()
): PositionedText =
  layoutText([px.newSpan(text, font)], options)
