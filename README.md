# harfbuzzy

Idiomatic Nim wrappers for HarfBuzz, with the low-level C API supplied by
[`harfbuzz-nim`](https://github.com/nimbase/harfbuzz-nim).

The package has two layers:

- `harfbuzzy/raw`: re-exports the upstream HarfBuzz C API for every build.
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

## Glyph outlines

HarfBuzzy 0.5.0 adds `font.glyphOutline(glyphId)` for renderers that need vector
contours. It returns owned `OutlineCommand` values for moves, lines, quadratic
and cubic curves, and closed contours. No rendering library is required.

```nim
let glyphId = typeface.font.nominalGlyph(uint32('A'))
for command in typeface.font.glyphOutline(glyphId):
  case command.kind
  of OutlineCommandKind.moveTo, OutlineCommandKind.lineTo:
    echo command.kind, " ", command.to.x, ", ", command.to.y
  of OutlineCommandKind.quadraticTo:
    echo command.control1, " -> ", command.to
  of OutlineCommandKind.cubicTo:
    echo command.control1, " ", command.control2, " -> ", command.to
  of OutlineCommandKind.closePath:
    echo "close contour"
```

Coordinates follow the font's current scale and variations, with Y increasing
upwards. `initTypeface` defaults to units per em. An outline-less glyph such as
a space returns an empty sequence; glyph zero selects `.notdef`. Outlines
require HarfBuzz 7.0 or newer, and remain valid after the font is released.

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

The dependency pins the upstream [`harfbuzz-nim`](https://github.com/nimbase/harfbuzz-nim)
0.3.0 merge commit containing the static C/C++ binding fixes.

Shared builds with Nim's C backend on Linux and macOS discover system HarfBuzz
through `pkg-config`. Windows and C++ builds probe the runtime libraries
at startup. To control loading explicitly on any platform, pass
`-d:harfbuzzRuntime`. FriBidi is dynamically loaded in shared builds.
Atlas consumers can request the `runtime` feature on their Harfbuzzy dependency
to select explicit runtime loading without a compiler switch. The `static`
feature takes precedence when both features are enabled.

In explicit runtime mode, call `loadHarfbuzz` before using the core APIs. A missing
library raises `HarfBuzzLoadError`, so the application can choose a fallback:

```nim
import harfbuzzy

try:
  loadHarfbuzz() # Or loadHarfbuzz(path = "/path/to/libharfbuzz")
  loadFribidi()  # Required before paragraph shaping
  echo versionString()
except HarfBuzzLoadError, FriBidiLoadError:
  echo "Use the application's fallback"
```

Set `-d:harfbuzzDynlib=...` and `-d:harfbuzzSubsetDynlib=...` to override
library discovery at build time. Set `-d:harfbuzzyFribidiDynlib=...` for
FriBidi, or pass a filename to `loadFribidi(path = ...)` at runtime.
In explicit runtime mode FriBidi is not loaded until `loadFribidi` is called;
`FriBidiLoadError` is catchable and failed loads can be retried.
Use `-d:harfbuzzyFribidiRuntime` to control FriBidi loading independently of
HarfBuzz. In other shared builds FriBidi is probed automatically at startup.
Call `loadFribidi` before using paragraph shaping or raw FriBidi procedures,
and before starting worker threads that use them. Successful loads remain valid
for the process lifetime and cannot be replaced.
Load `HarfBuzzLibrary.Subset` before using subsetting in explicit runtime mode.
HarfBuzzy derives only the procedure pointers it uses from upstream declarations.
Loading resolves them once; calls then go directly to C.
Optional symbols unavailable in the loaded library version remain nil.
Successful HarfBuzz loads remain valid for the process lifetime.
`harfbuzzLibraryStem(library)` is public for custom path discovery; it returns
`harfbuzz`, `harfbuzz-subset`, or `harfbuzz-icu` without platform prefixes or suffixes.
Pass a full filename using `loadHarfbuzz(library, path = ...)` to choose a library
at runtime. Raw C definitions remain in `harfbuzz-nim`.

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

This opt-in build supports Nim's C and C++ backends and requires CMake 3.24 or newer, Meson,
Ninja, and a native C/C++ toolchain. Harfbuzzy enables the upstream
`harfbuzzStatic` mode and supplies the bundled headers and archives, avoiding
system HarfBuzz discovery and linking. Both release archives are pinned by version
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
