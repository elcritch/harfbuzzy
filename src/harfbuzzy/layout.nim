## Shared storage for positioned text. Adapters choose their glyph, source text,
## and geometry types while sharing the same arrangement fields.

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
