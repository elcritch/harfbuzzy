# Harfbuzzy Plan

Goal: make `harfbuzzy` usable for text shaping and bidirectional text workflows
from idiomatic Nim code, while keeping C ownership hidden behind ARC/ORC-safe
wrappers.

## Current State

The library currently covers a practical core:

- High-level shaping path: `typefaceFromFile("font.ttf").shape("text")`.
- ARC/ORC/atomicArc guard for deterministic HarfBuzz handle destructors.
- Owned wrappers for `Blob`, `Face`, `Font`, `Buffer`, `Set`, `SubsetInput`,
  and `SubsetPlan`.
- `GlyphRun` output with glyph id, cluster, flags, advances, and offsets.
- Basic tags, scripts, languages, directions, OpenType feature strings, font
  metrics, glyph extents, sets, simple subsetting, and AAT presence probes.
- Raw binding coverage for the shaping-critical HarfBuzz APIs, not full
  HarfBuzz parity.

This is enough for single-run shaping where the caller already knows direction,
script, language, font, and feature settings.

## Important Bidi Constraint

HarfBuzz shapes runs. It does not implement the full Unicode Bidirectional
Algorithm for mixed-direction paragraphs.

To support bidi text properly, `harfbuzzy` needs a text pipeline around
HarfBuzz:

1. Decode input text and keep stable source cluster offsets.
2. Run the Unicode Bidirectional Algorithm to split text into directional runs.
3. Itemize by script/language/font where needed.
4. Shape each run with HarfBuzz using the correct direction, script, language,
   and feature options.
5. Return logical and visual run orders with cluster mappings intact.

The likely implementation path is to bind FriBidi as the bidi engine. ICU is
also viable but heavier. A pure Nim UAX #9 implementation is possible later,
but should not be the first implementation unless avoiding a C dependency is a
hard requirement.

## Target Public API Shape

Preferred high-level API:

```nim
let typeface = typefaceFromFile("font.ttf")
let paragraph = typeface.shapeParagraph("abc אבג 123")

for run in paragraph.visualRuns:
  for glyph in run.glyphs:
    echo glyph.codepoint, " cluster=", glyph.cluster
```

Likely public types:

- `ParagraphDirection = auto | ltr | rtl`
- `BidiLevel = distinct uint8`
- `TextRun`: source byte/codepoint range, direction, bidi level, script,
  language, and optional feature overrides.
- `ShapedRun`: one shaped HarfBuzz run plus source range and run direction.
- `ShapedParagraph`: logical runs, visual runs, total advance, and helpers for
  cluster lookup.
- `ParagraphOptions`: base direction, language, default features, cluster
  policy, and optional font fallback.

## Priority Checklist

### P0 - Make Shaping Plus Bidi Usable

- [x] Add a clear `ParagraphDirection` and `BidiLevel` API.
- [x] Choose the bidi backend. Default recommendation: FriBidi raw bindings plus
  a small ergonomic wrapper.
- [x] Add bidi run segmentation for UTF-8 input with stable source cluster
  offsets.
- [x] Add `TextRun`, `ShapedRun`, and `ShapedParagraph` public types.
- [x] Add `shapeRun(typeface, text, run, options)` for one directional run.
- [x] Add `shapeParagraph(typeface, text, options)` for mixed-direction text.
- [x] Return both logical and visual run order.
- [x] Preserve cluster mapping back to the original input string.
- [x] Add tests for LTR-only, RTL-only, and mixed English plus Hebrew/Arabic
  paragraphs.
- [x] Add tests with numbers and neutral punctuation inside RTL text.
- [x] Document that bidi is paragraph-level processing around HarfBuzz, not a
  HarfBuzz-only feature.

### P1 - Improve Shaping Quality And Controls

- [ ] Expose buffer cluster level in the high-level API.
- [ ] Add `shapeFull` support with explicit shaper lists.
- [ ] Add `shapePlan` wrappers and caching for repeated shaping with the same
  face/script/language/features.
- [ ] Add script itemization helpers for runs where the caller does not provide
  script.
- [ ] Add language handling per run, with sensible defaults.
- [ ] Add OpenType feature discovery wrappers from `hb-ot-layout`.
- [ ] Add font metrics helpers needed by layout callers: line extents, glyph
  extents, advances, and scale conversions.
- [ ] Add debug serialization of shaped buffers for test fixtures and issue
  reports.

### P2 - Make Paragraph Shaping Practical In Real Apps

- [ ] Add multi-font fallback support while preserving cluster mappings.
- [ ] Add missing-glyph detection and fallback hooks.
- [ ] Add reusable `ShapeContext` or `Shaper` object for configured fonts,
  features, and bidi backend state.
- [ ] Add APIs to map source byte/codepoint positions to shaped glyph ranges.
- [ ] Add visual-to-logical and logical-to-visual run lookup helpers.
- [ ] Add examples using Amiri or another Arabic-capable fixture font.
- [ ] Add fuzz or property tests for malformed UTF-8, empty input, long input,
  and mixed neutral characters.

### P3 - Broader HarfBuzz Coverage

- [ ] Expand `hb-ot-name` wrappers for localized names and language metadata.
- [ ] Expand `hb-ot-var` wrappers for variable font axes and named instances.
- [ ] Expand `hb-ot-color` wrappers for color font inspection.
- [ ] Expand `hb-ot-math` wrappers if math layout becomes a target.
- [ ] Add richer subset plan/mapping wrappers.
- [ ] Add optional integrations only when needed: FreeType, CoreText,
  DirectWrite, ICU, GLib, Cairo, draw/paint/vector/raster APIs.

## Definition Of Done For Bidi Shaping

- A caller can pass one UTF-8 paragraph and get shaped glyph runs in visual
  order.
- The caller can also inspect logical order and source cluster mappings.
- All HarfBuzz and bidi backend handles are released by Nim destructors.
- Mixed LTR/RTL examples render in the expected visual order at the run level.
- Tests cover Arabic or Hebrew text, embedded Latin text, digits, punctuation,
  empty strings, and invalid input handling.

## Non-Goals For The First Bidi Milestone

- Full line breaking.
- Paragraph layout, alignment, justification, or wrapping.
- Font fallback across large font collections.
- Complete HarfBuzz API parity.
- A pure Nim Unicode Bidirectional Algorithm implementation.
