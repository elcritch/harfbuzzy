# harfbuzzy

Nim bindings for HarfBuzz, generated and curated against the vendored
`deps/harfbuzz` 14.2.0 headers.

The package has two layers:

- `harfbuzzy/raw`: ABI-shaped C bindings for the core HarfBuzz, OpenType, AAT,
  and subset entry points used by this package.
- `harfbuzzy`: reference-counted Nim handle wrappers for blobs, faces, fonts,
  buffers, sets, shaping, and subset input.

## Example

```nim
import harfbuzzy

let typeface = typefaceFromFile("font.ttf")
let run = typeface.shape("hello")

for glyph in run:
  echo glyph.codepoint, " cluster=", glyph.cluster
```

For mixed-direction paragraphs, `harfbuzzy` uses FriBidi for paragraph-level
bidi analysis and HarfBuzz for shaping each directional run:

```nim
let paragraph = typeface.shapeParagraph("abc \u05E9\u05DC\u05D5\u05DD 123")

for run in paragraph.visualRuns:
  for glyph in run:
    echo glyph.codepoint, " cluster=", glyph.cluster
```

Clusters are byte offsets into the original UTF-8 input string. HarfBuzz itself
does not implement the Unicode Bidirectional Algorithm; the paragraph API runs
that step before shaping.

More shaping controls are available when needed:

```nim
let options = initShapeOptions(
  direction = Direction.ltr,
  script = scriptLatin,
  language = toLanguage("en"),
  features = [toFeature("kern=0")],
  shapers = ["ot"],
  clusterLevel = ClusterLevel.characters,
)

let plan = initShapePlan(typeface, options)
let plannedRun = typeface.shape("hello", plan, options)

echo typeface.face.substitutionFeatureTags()
echo typeface.font.horizontalExtents().lineAdvance
```

## Build

Install dependencies with Atlas:

```sh
atlas install
```

Run tests:

```sh
nim test
```

`harfbuzzy` requires `--mm:arc`, `--mm:orc`, or `--mm:atomicArc`. The wrapper
types own HarfBuzz handles with Nim destructors, so callers do not call
`hb_*_destroy` directly. The repository default is `--mm:atomicArc`.

The raw modules include headers from `deps/harfbuzz/src` and dynamically load
`libharfbuzz`, `libharfbuzz-subset`, and `libfribidi`. On macOS they use
Homebrew prefixes when available. Override library paths when needed:

```sh
nim c -r -d:harfbuzzyDynlib=/path/to/libharfbuzz.dylib \
  -d:harfbuzzySubsetDynlib=/path/to/libharfbuzz-subset.dylib \
  -d:harfbuzzyFribidiDynlib=/path/to/libfribidi.dylib \
  tests/tharfbuzzy.nim
```

## Regenerating Raw Seeds

`tools/generate_raw_bindings.sh` runs `c2nim` with the directive file in
`tools/harfbuzz.c2nim`. The generated file is a seed for review, not the final
raw layer; HarfBuzz macros and enum domains still need manual curation.
