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
that step before shaping. Script segmentation uses HarfBuzz's Unicode data for
the full script set, keeps common and inherited characters with adjacent runs,
and separates emoji sequences so a `ShapeContext` can choose an emoji-capable
fallback. `ParagraphOptions.language` supplies the BCP 47 language used for
each detected run.

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

For paragraph shaping with font fallback, use a `ShapeContext`:

```nim
let context = initShapeContext(
  typefaceFromFile("latin.ttf"),
  [typefaceFromFile("arabic.ttf")],
  initParagraphOptions(shapers = ["ot"]),
)

let paragraph = context.shapeParagraph("abc \u0633\u0644\u0627\u0645")

for run in paragraph.visualRuns:
  echo run.typefaceIndex, " ", run.textRun.byteStart, "..", run.textRun.byteEnd
```

The primary typeface remains selected wherever it has glyph coverage. Within a
single bidirectional/script run, shaping splits at unsupported codepoints and
uses ordered fallback typefaces for maximal covered segments.

`ShapedParagraph` also exposes logical/visual run index maps and byte/codepoint
to glyph-range helpers for editor and layout integrations.

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

By default, the raw modules include HarfBuzz headers from `deps/harfbuzz/src`
when that checkout exists, otherwise they use `pkg-config --cflags harfbuzz`.
They dynamically load `libharfbuzz`, `libharfbuzz-subset`, and `libfribidi`. On
macOS they use Homebrew prefixes when available. Override library paths when
needed:

```sh
nim c -r -d:harfbuzzyDynlib=/path/to/libharfbuzz.dylib \
  -d:harfbuzzySubsetDynlib=/path/to/libharfbuzz-subset.dylib \
  -d:harfbuzzyFribidiDynlib=/path/to/libfribidi.dylib \
  tests/tharfbuzzy.nim
```

To download HarfBuzz 14.2.0, build it, and statically link the HarfBuzz and
HarfBuzz subset libraries, compile with `-d:harfbuzzyStatic`:

```sh
nim c -r -d:harfbuzzyStatic tests/tharfbuzzy.nim
```

This opt-in build requires CMake and a native C/C++ toolchain. The release
archive is pinned by version and SHA-256 hash. Build files are cached under the
platform cache directory (for example, `~/.cache/harfbuzzy` on Linux), so later
compiles reuse the same build. Override that location when needed:

```sh
nim c -d:harfbuzzyStatic \
  -d:harfbuzzyStaticCache=/path/to/cache \
  your_program.nim
```

Pass additional CMake configuration arguments with
`-d:harfbuzzyStaticCmakeArgs="..."`, or select a CMake executable with
`-d:harfbuzzyStaticCmake=/path/to/cmake`. On Windows, the static build requires
MSVC and `--cc:vcc`. FriBidi remains dynamically loaded in this mode.

## Regenerating Raw Seeds

`tools/generate_raw_bindings.sh` runs `c2nim` with the directive file in
`tools/harfbuzz.c2nim`. The generated file is a seed for review, not the final
raw layer; HarfBuzz macros and enum domains still need manual curation.
