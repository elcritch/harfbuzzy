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

var face = faceFromFile("font.ttf")
var font = initFont(face)
var buffer = initBuffer()

buffer.addUtf8("hello")
buffer.guessSegmentProperties()
shape(font, buffer)

for info in buffer.glyphInfos:
  echo info.codepoint, " cluster=", info.cluster
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

The raw module includes headers from `deps/harfbuzz/src` and dynamically loads
`libharfbuzz` plus `libharfbuzz-subset`. On macOS it uses Homebrew's
`brew --prefix harfbuzz` when available. Override library paths when needed:

```sh
nim c -r -d:harfbuzzyDynlib=/path/to/libharfbuzz.dylib \
  -d:harfbuzzySubsetDynlib=/path/to/libharfbuzz-subset.dylib \
  tests/tharfbuzzy.nim
```

## Regenerating Raw Seeds

`tools/generate_raw_bindings.sh` runs `c2nim` with the directive file in
`tools/harfbuzz.c2nim`. The generated file is a seed for review, not the final
raw layer; HarfBuzz macros and enum domains still need manual curation.
