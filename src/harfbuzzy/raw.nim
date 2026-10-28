## Compatibility facade over the HarfBuzz C API used by harfbuzzy.
##
## All builds use the upstream `harfbuzz` package. Dynamic Windows and C++
## builds probe its runtime libraries automatically. Pass `-d:harfbuzzRuntime`
## explicitly to control when the libraries are loaded instead.

const
  hbStaticEnabled* = defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)
  hbRuntimeFeature =
    defined(feature.harfbuzzy.runtime) or defined(features.harfbuzzy.runtime)
  hbAutoLoad =
    not hbStaticEnabled and not defined(harfbuzzRuntime) and not hbRuntimeFeature and
    (defined(windows) or defined(cpp))

when hbStaticEnabled and defined(harfbuzzRuntime):
  {.error: "harfbuzzyStatic and harfbuzzRuntime are mutually exclusive".}

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
elif hbAutoLoad or hbRuntimeFeature:
  {.define: harfbuzzRuntime.}

when defined(harfbuzzRuntime):
  {.define: harfbuzzNoPkgConfig.}

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

when defined(harfbuzzRuntime):
  import harfbuzzy/private/runtime_api
  export runtime_api
else:
  import harfbuzzy/private/native_api
  export native_api

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

when hbAutoLoad:
  # Preserve the default shared-build setup while allowing missing libraries.
  # Explicit runtime mode leaves loading entirely to the caller.
  try:
    loadHarfbuzz()
    loadHarfbuzz(HarfBuzzLibrary.Subset)
  except HarfBuzzLoadError:
    discard
