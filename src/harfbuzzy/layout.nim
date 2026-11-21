## Shared storage for positioned text. Adapters choose their glyph, source text,
## and geometry types while sharing the same arrangement fields.

from std/unicode import Rune

type TextLayout*[Glyph, Source, Point, Bounds] = object
  ## Glyph indices address the arrays in visual order within each line.
  lines*: seq[Slice[int]] ## Inclusive glyph ranges, in reading order.
  sourceRunes*: Source ## Original text addressed by the glyph source ranges.
  arrangedGlyphs*: seq[Glyph] ## Positioned glyphs with source mappings.
  runes*: Source ## Display text, when available.
  positions*: seq[Point] ## Glyph positions, when stored separately.
  selectionRects*: seq[Bounds] ## Selection bounds, when stored separately.
  maxSize*: Point ## Maximum content size.
  minSize*: Point ## Minimum content size.
  bounding*: Bounds ## Bounds of the positioned text.

type
  FontHorizontal* = enum
    Left
    Center
    Right

  FontVertical* = enum
    Top
    Middle
    Bottom

  ParagraphAlign* = enum
    ## Horizontal placement of a paragraph's lines.
    paInherit ## Use the typeset call's `hAlign`.
    paLeft
    paCenter
    paRight
    paJustify ## Stretch inter-word spaces so wrapped lines fill the measure.

  ParagraphLineBreaking* = enum
    plbGreedy ## Fill each line in turn; linear time.
    plbOptimal
      ## Choose breaks for the whole paragraph that minimize uneven spacing
      ## (Knuth-Plass). Applies to justified paragraphs; falls back to greedy
      ## breaking when no break set fits.

  OverflowWrap* = enum
    ## What to do with a word wider than the measure that has no
    ## shaping-safe break point, like CSS `overflow-wrap`.
    owNormal ## Let the word overflow; shaping stays exact.
    owAnywhere
      ## Break at any cluster boundary to stay inside the box. Glyphs beside
      ## the break keep the shaping they had while joined, e.g. kerning.

  ParagraphStyle* = object
    ## Paragraph layout applied from the style of a paragraph's first span.
    ## Lengths are pixels. The default value preserves unstyled layout.
    firstLineIndent*: float32 ## Leading inset of a paragraph's first line.
    headIndent*: float32 ## Leading inset of the paragraph's following lines.
    tailIndent*: float32 ## Trailing inset of every line.
    align*: ParagraphAlign
    lastLineAlign*: ParagraphAlign
      ## Last-line placement of a justified paragraph; `paInherit` uses the
      ## paragraph direction's leading edge and `paJustify` stretches it too.
    lineBreaking*: ParagraphLineBreaking
    overflowWrap*: OverflowWrap
    hyphenate*: bool
      ## Break overflowing words at hyphenation points registered for the font
      ## language. Soft hyphens (U+00AD) are honored whenever text wraps.
    lineSpacing*: float32 ## Extra space after each line in the paragraph.
    spacingBefore*: float32 ## Extra space above the paragraph, except the first.
    spacingAfter*: float32 ## Extra space below the paragraph, except the last.

func isDefault*(style: ParagraphStyle): bool =
  ## Whether `style` leaves layout identical to unstyled text.
  style == ParagraphStyle()

type
  LayoutPoint* = object
    x*, y*: float32

  LayoutRect* = object
    x*, y*, w*, h*: float32

  GlyphSourceRange* = object
    byteStart*, byteEnd*: int ## Half-open UTF-8 byte range in the original text.
    runeStart*, runeEnd*: int ## Half-open codepoint range in the original text.

  LayoutGlyph* = object
    fontId*: int ## Index in the backend's input font list.
    glyphId*: uint32 ## HarfBuzz glyph ID or Pixie rune value.
    source*: GlyphSourceRange
    rune*: Rune ## Representative display rune.
    isWhitespace*: bool
    pos*, advance*, offset*: LayoutPoint
    rect*: LayoutRect

  PositionedText* = TextLayout[LayoutGlyph, string, LayoutPoint, LayoutRect]

  HyphenationLookup* = proc(language, word: string): seq[int] {.closure.}
    ## Returns source-rune boundaries within a word, in ascending order.

  ParagraphLayoutOptions* = object
    width*, height*: float32
    horizontal*: FontHorizontal
    vertical*: FontVertical
    style*: ParagraphStyle
    wrap*: bool = true
    language*: string ## Hyphenation language.
    hyphenation*: HyphenationLookup
