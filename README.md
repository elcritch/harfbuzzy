# harfbuzzy

Idiomatic Nim wrappers for HarfBuzz, with the low-level C API supplied by
[`harfbuzz-nim`](https://github.com/nimbase/harfbuzz-nim).

The package has two layers:

- `harfbuzzy/raw`: the snake_case HarfBuzz C API used by this package. Normal
  Unix builds re-export the relevant `harfbuzz-nim` modules; bundled-static
  builds, C++ builds, and Windows retain a compatible private backend for their
  custom compiler and link modes.
- `harfbuzzy`: camelCase, reference-counted Nim wrappers for blobs, faces,
  fonts, buffers, sets, shaping, and subsetting.

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

`harfbuzzy` requires Nim 2.2.10 or newer and `--mm:arc`, `--mm:orc`, or
`--mm:atomicArc`. Its high-level types own HarfBuzz handles through `=destroy`,
`=copy`, `=dup`, and `=wasMoved` hooks, so callers do not call `hb_*_destroy`
directly. The repository default is `--mm:atomicArc`.

On Linux and macOS, `harfbuzz-nim` discovers the system HarfBuzz headers and
libraries with `pkg-config`. FriBidi remains dynamically loaded. On Windows,
the compatibility backend dynamically loads HarfBuzz and FriBidi from the
normal DLL search path. Override the Windows DLL paths when needed:

```sh
nim c -r -d:harfbuzzyDynlib=C:/path/to/harfbuzz.dll \
  -d:harfbuzzySubsetDynlib=C:/path/to/harfbuzz-subset.dll \
  -d:harfbuzzyFribidiDynlib=C:/path/to/fribidi.dll \
  tests/tharfbuzzy.nim
```

To download and statically link HarfBuzz 14.2.0 (including its subset library)
and FriBidi 1.0.16, request the `static` Atlas feature in your manifest:

```nim
requires "gh:elcritch/harfbuzzy[static]"
```

Run `atlas install` after changing the requirement. When building this repository
directly, use `atlas install --features:static`. You can also select the same
build path with `-d:harfbuzzyStatic`:

```sh
nim c -r -d:harfbuzzyStatic tests/tharfbuzzy.nim
```

This opt-in build uses Nim's C backend and requires CMake 3.24 or newer, Meson,
Ninja, and a native C/C++ toolchain. Both release archives are pinned by version
and SHA-256 hash. FriBidi
uses its upstream Meson build to generate its Unicode tables and headers.
Build files are cached under the
platform cache directory (for example, `~/.cache/harfbuzzy` on Linux), so later
compiles reuse the same build without downloading the source again. Separate
checkouts, compiler settings, and CMake arguments use separate build directories.
Concurrent builds sharing a directory wait for its native build lock.
The native build uses two jobs by default; set `CMAKE_BUILD_PARALLEL_LEVEL` to
choose another limit.
Override the cache location when needed:

```sh
nim c -d:harfbuzzyStatic \
  -d:harfbuzzyStaticCache=/path/to/cache \
  your_program.nim
```

Pass additional CMake configuration arguments with
`-d:harfbuzzyStaticCmakeArgs="..."`, or select a CMake executable with
`-d:harfbuzzyStaticCmake=/path/to/cmake`. On Windows, the static build requires
MSVC and `--cc:vcc`. Neither HarfBuzz nor FriBidi needs a shared library in this mode.
Run Windows builds from a Visual Studio Developer shell. The native archives
use the static MSVC runtime (`/MT`) by default; if your Nim build uses `/MD`,
pass `-d:harfbuzzyStaticCmakeArgs="-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL"`.
Both native builds use the same compiler and MSVC runtime.

The downloaded source trees retain their upstream `COPYING` files. HarfBuzz uses
its permissive license; FriBidi is LGPL-2.1-or-later. Static linking does not
change either library's license.

Windows CI tests dynamic loading with both MSVC and MinGW, using each compiler's
matching vcpkg libraries. Static builds require MSVC on Windows.
The static archives can also be linked into a shared library on Unix.

## Maintaining the Private Raw Backend

`tools/generate_raw_bindings.sh` runs `c2nim` with the directive file in
`tools/harfbuzz.c2nim`. The generated file is only a seed for the bundled-static
and Windows compatibility backend, not the normal low-level layer. HarfBuzz
macros and enum domains still need manual curation.
