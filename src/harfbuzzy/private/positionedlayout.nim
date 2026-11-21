## Geometry and adapter hooks for the standalone layout frontends.

import std/unicode
import ../paragraph

type
  PositionedHyphen* = object
    found*: bool
    glyphId*: uint32
    advance*: float32

  PositionedRecord = object
    glyph: LayoutGlyph
    selection: LayoutRect
    visualKey: float64

func vec2*(x, y: float32): LayoutPoint {.inline.} =
  LayoutPoint(x: x, y: y)
func rect*(x, y, w, h: float32): LayoutRect {.inline.} =
  LayoutRect(x: x, y: y, w: w, h: h)

func xy*(r: LayoutRect): LayoutPoint {.inline.} =
  vec2(r.x, r.y)
func `+`*(a, b: LayoutPoint): LayoutPoint {.inline.} =
  vec2(a.x + b.x, a.y + b.y)
func `-`*(a, b: LayoutPoint): LayoutPoint {.inline.} =
  vec2(a.x - b.x, a.y - b.y)
proc `+=`*(a: var LayoutPoint, b: LayoutPoint) {.inline.} =
  a = a + b

func `+`*(a, b: LayoutRect): LayoutRect {.inline.} =
  rect(a.x + b.x, a.y + b.y, a.w + b.w, a.h + b.h)

func bytes*(text: string): lent string {.inline.} =
  text
func byteLength*(text: string): int {.inline.} =
  text.len
func fallbackLineHeight*(text: PositionedText): float32 =
  0

proc appendGlyph*(text: var PositionedText, glyph: LayoutGlyph) =
  text.arrangedGlyphs.add glyph
  text.positions.add glyph.pos
  text.selectionRects.add glyph.rect
  text.runes.add glyph.rune

proc decompose*(text: PositionedText): seq[PositionedRecord] =
  result = newSeq[PositionedRecord](text.arrangedGlyphs.len)
  for i, glyph in text.arrangedGlyphs:
    result[i] = PositionedRecord(
      glyph: glyph, selection: text.selectionRects[i], visualKey: i.float64
    )

proc recompose*(text: var PositionedText, records: openArray[PositionedRecord]) =
  text.arrangedGlyphs.setLen(records.len)
  text.positions.setLen(records.len)
  text.selectionRects.setLen(records.len)
  text.runes.setLen(0)
  for i, record in records:
    text.arrangedGlyphs[i] = record.glyph
    text.positions[i] = record.glyph.pos
    text.selectionRects[i] = record.selection
    text.runes.add record.glyph.rune

func withHyphen*(
    base: PositionedRecord,
    hyphen: PositionedHyphen,
    selection: LayoutRect,
    visualKey: float64,
): PositionedRecord =
  result = base
  result.glyph.glyphId = hyphen.glyphId
  result.glyph.rune = Rune('-')
  result.glyph.isWhitespace = false
  result.glyph.advance = vec2(hyphen.advance, 0)
  result.glyph.offset = vec2(0, 0)
  result.glyph.pos = vec2(selection.x, base.glyph.pos.y)
  result.glyph.rect = rect(selection.x, selection.y, hyphen.advance, selection.h)
  result.selection = result.glyph.rect
  result.visualKey = visualKey

func calcMinMaxContent*(text: PositionedText): tuple[bounding: LayoutRect] =
  if text.arrangedGlyphs.len == 0:
    return
  var
    left = float32.high
    top = float32.high
    right = -float32.high
    bottom = -float32.high
  for glyph in text.arrangedGlyphs:
    left = min(left, glyph.rect.x)
    top = min(top, glyph.rect.y)
    right = max(right, glyph.rect.x + glyph.rect.w)
    bottom = max(bottom, glyph.rect.y + glyph.rect.h)
  result.bounding = rect(left, top, right - left, bottom - top)

proc measureParagraphs*(
    text: var PositionedText, paragraphs: openArray[LayoutParagraph]
) =
  ## Intrinsic widths before wrapping. The minimum is the widest unbroken word.
  for paragraph in paragraphs:
    var
      width = 0'f32
      word = 0'f32
      height = 0'f32
    for i in paragraph.glyphs:
      let glyph = text.arrangedGlyphs[i]
      height = max(height, glyph.rect.h)
      if glyph.rune == Rune(0xAD):
        continue
      let advance = glyph.glyphWrapWidth()
      width += advance
      if glyph.isWhitespace:
        word = 0
      else:
        word += advance
        text.minSize.x = max(text.minSize.x, word)
        if glyph.rune.canBreakAfterRune:
          word = 0
    let indent = paragraph.style.firstLineIndent + paragraph.style.tailIndent
    text.maxSize.x = max(text.maxSize.x, width + indent)
    text.maxSize.y += height
    text.minSize.y = max(text.minSize.y, height)

proc finishLayout*(
    text: var PositionedText,
    paragraphs: openArray[LayoutParagraph],
    safeBreakAfter: openArray[bool],
    options: ParagraphLayoutOptions,
    hyphen: proc(fontId: int): PositionedHyphen {.closure.},
) =
  text.measureParagraphs(paragraphs)
  let lines = text.breakParagraphLines(
    paragraphs, safeBreakAfter, options.width, options.wrap, hyphen, options.hyphenation
  )
  text.reflowParagraphLines(lines, paragraphs, options.width, options.wrap)
  text.alignParagraphLines(
    lines,
    paragraphs,
    rect(0, 0, options.width, options.height),
    options.horizontal,
    options.vertical,
  )
  text.bounding = text.calcMinMaxContent().bounding
