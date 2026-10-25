## Compatibility facade over the HarfBuzz C API used by harfbuzzy.
##
## Unix C builds use the externally maintained `harfbuzz` package. Bundled-static,
## C++, and Windows builds use a private compatibility backend until that package
## supports their compiler and link modes.

const hbStaticEnabled* = defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)

when hbStaticEnabled or defined(windows) or defined(cpp):
  # harfbuzz-nim currently discovers and links HarfBuzz through pkg-config.
  # It also declares opaque types in a way that is incompatible with C++'s
  # stricter type checking. Keep the existing compatibility backend for those
  # link and compiler modes until the upstream package supports them.
  import harfbuzzy/private/staticRaw

  export staticRaw
else:
  const hbPkgConfigIncludeDir = gorge("pkg-config --variable=includedir harfbuzz")

  {.passC: "-I" & hbPkgConfigIncludeDir.}
  {.passC: gorge("pkg-config --cflags harfbuzz").}
  # Upstream emits Nim struct pointers rather than importing the C typedefs.
  # Their layouts are ABI-checked in tests; GCC 14+ otherwise rejects the
  # generated calls (including function pointers) as incompatible pointer types.
  {.passC: "-Wno-incompatible-pointer-types".}
  when defined(vcc):
    {.passC: "/DHB_NO_SINGLE_HEADER_ERROR".}
  else:
    {.passC: "-DHB_NO_SINGLE_HEADER_ERROR".}

  import
    harfbuzz/[
      hb_aat_layout, hb_blob, hb_buffer, hb_common, hb_face, hb_font, hb_map,
      hb_ot_font, hb_ot_layout, hb_set, hb_shape, hb_shape_plan, hb_subset, hb_unicode,
      hb_version,
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
