## Compatibility facade over the HarfBuzz C API used by harfbuzzy.
##
## All builds use the upstream `harfbuzz` package. Dynamic Windows and C++
## builds enable its deferred DLL loading; other dynamic builds can opt in
## with `-d:harfbuzzRuntime`.

const hbStaticEnabled* = defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)

when hbStaticEnabled:
  import std/os
  import harfbuzzy/private/staticHarfbuzz

  {.define: harfbuzzStatic.}
  when defined(vcc):
    {.passC: "/I" & quoteShell(staticHarfbuzz.harfbuzzIncludeDir).}
  else:
    {.passC: "-I" & quoteShell(staticHarfbuzz.harfbuzzIncludeDir).}
  {.passL: quoteShell(staticHarfbuzz.harfbuzzSubsetStaticLib).}
  {.passL: quoteShell(staticHarfbuzz.harfbuzzStaticLib).}
  when defined(posix):
    {.passL: "-pthread -lm".}
elif defined(windows) or defined(cpp):
  {.define: harfbuzzRuntime.}

when not hbStaticEnabled and not defined(harfbuzzRuntime):
  const hbPkgConfigIncludeDir = gorge("pkg-config --variable=includedir harfbuzz")
  {.passC: "-I" & hbPkgConfigIncludeDir.}
  {.passC: gorge("pkg-config --cflags harfbuzz").}
  # Upstream dynamic bindings use nominal Nim structs; static bindings import
  # the native C types. Dynamic struct layouts are ABI-checked in tests.
  {.passC: "-Wno-incompatible-pointer-types".}
  {.passC: "-Wno-incompatible-function-pointer-types".}
when defined(vcc):
  {.passC: "/DHB_NO_SINGLE_HEADER_ERROR".}
else:
  {.passC: "-DHB_NO_SINGLE_HEADER_ERROR".}

import
  harfbuzz/[
    hb_aat_layout, hb_blob, hb_buffer, hb_common, hb_face, hb_font, hb_map, hb_ot_font,
    hb_ot_layout, hb_set, hb_shape, hb_shape_plan, hb_subset, hb_unicode, hb_version,
  ]

export
  hb_aat_layout, hb_blob, hb_buffer, hb_common, hb_face, hb_font, hb_map, hb_ot_font,
  hb_ot_layout, hb_set, hb_shape, hb_shape_plan, hb_subset, hb_unicode, hb_version

func hb_direction_is_valid*(direction: hb_direction_t): bool =
  HB_DIRECTION_IS_VALID(direction)

func hb_direction_is_horizontal*(direction: hb_direction_t): bool =
  HB_DIRECTION_IS_HORIZONTAL(direction)

func hb_direction_is_vertical*(direction: hb_direction_t): bool =
  HB_DIRECTION_IS_VERTICAL(direction)

func hb_direction_reverse*(direction: hb_direction_t): hb_direction_t =
  cast[hb_direction_t](cuint(direction) xor 1)

func `or`*(a, b: hb_buffer_flags_t): hb_buffer_flags_t =
  cast[hb_buffer_flags_t](cuint(a) or cuint(b))

func `and`*(a, b: hb_buffer_flags_t): hb_buffer_flags_t =
  cast[hb_buffer_flags_t](cuint(a) and cuint(b))

func contains*(flags, flag: hb_buffer_flags_t): bool =
  (cuint(flags) and cuint(flag)) != 0

func `or`*(a, b: hb_buffer_serialize_flags_t): hb_buffer_serialize_flags_t =
  cast[hb_buffer_serialize_flags_t](cuint(a) or cuint(b))

when defined(harfbuzzRuntime):
  import harfbuzz/runtime
  export runtime except harfbuzzSymbol
