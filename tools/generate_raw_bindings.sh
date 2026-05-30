#!/usr/bin/env sh
set -eu

out="${1:-/tmp/harfbuzzy-harfbuzz-raw.generated.nim}"

c2nim tools/harfbuzz.c2nim \
  --concat \
  --out:"$out" \
  deps/harfbuzz/src/hb-common.h \
  deps/harfbuzz/src/hb-blob.h \
  deps/harfbuzz/src/hb-face.h \
  deps/harfbuzz/src/hb-font.h \
  deps/harfbuzz/src/hb-buffer.h \
  deps/harfbuzz/src/hb-set.h \
  deps/harfbuzz/src/hb-shape.h \
  deps/harfbuzz/src/hb-ot.h \
  deps/harfbuzz/src/hb-aat.h \
  deps/harfbuzz/src/hb-subset.h

printf '%s\n' "$out"
