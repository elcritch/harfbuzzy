## Private HarfBuzz bindings for the Windows and C++ compatibility backend.
##
## Unix C builds use the upstream `harfbuzz` package for both shared and static
## libraries. These declarations retain native C types and runtime DLL loading
## for compiler modes that still need them.

import std/os

const hbStaticEnabled = defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)

when hbStaticEnabled:
  import harfbuzzy/private/staticHarfbuzz

const hbSourceDir =
  when hbStaticEnabled:
    staticHarfbuzz.harfbuzzSourceDir
  else:
    currentSourcePath().parentDir().parentDir().parentDir() / "deps" / "harfbuzz" / "src"

when dirExists(hbSourceDir):
  const hbIncludeFlag =
    when defined(vcc):
      "/I" & quoteShell(hbSourceDir)
    else:
      "-I" & quoteShell(hbSourceDir)
  {.passC: hbIncludeFlag.}
else:
  const hbPkgConfigCflags = staticExec(
    "sh -c 'if command -v pkg-config >/dev/null 2>&1; then pkg-config --cflags harfbuzz 2>/dev/null | tr -d \"\\n\"; fi'"
  )
  when hbPkgConfigCflags.len > 0:
    {.passC: hbPkgConfigCflags.}

when hbStaticEnabled:
  {.passL: quoteShell(staticHarfbuzz.harfbuzzSubsetStaticLib).}
  {.passL: quoteShell(staticHarfbuzz.harfbuzzStaticLib).}
  when defined(posix):
    # Static archive dependencies must follow the archives on ELF linkers.
    {.passL: "-pthread -lm".}

const
  hbHeader = "hb.h"
  hbSubsetHeader = "hb-subset.h"

when hbStaticEnabled:
  const hbAatHeader = "hb-aat.h"
  const hbOtHeader = "hb-ot.h"

const hbDynlibOverride* {.strdefine: "harfbuzzyDynlib".} = ""

when defined(macosx):
  const hbDetectedBrewPrefix = staticExec(
    "sh -c 'if command -v brew >/dev/null 2>&1; then brew --prefix harfbuzz 2>/dev/null | tr -d \"\\n\"; fi'"
  )
else:
  const hbDetectedBrewPrefix = ""

const hbLib* =
  when hbDynlibOverride.len > 0:
    hbDynlibOverride
  elif defined(windows):
    "harfbuzz.dll"
  elif defined(macosx) and hbDetectedBrewPrefix.len > 0:
    hbDetectedBrewPrefix & "/lib/libharfbuzz.dylib"
  elif defined(macosx):
    "libharfbuzz.dylib"
  else:
    "libharfbuzz.so(|.0)"

const hbSubsetDynlibOverride* {.strdefine: "harfbuzzySubsetDynlib".} = ""

const hbSubsetLib* =
  when hbSubsetDynlibOverride.len > 0:
    hbSubsetDynlibOverride
  elif defined(windows):
    "harfbuzz-subset.dll"
  elif defined(macosx) and hbDetectedBrewPrefix.len > 0:
    hbDetectedBrewPrefix & "/lib/libharfbuzz-subset.dylib"
  elif defined(macosx):
    "libharfbuzz-subset.dylib"
  else:
    "libharfbuzz-subset.so(|.0)"

when hbStaticEnabled:
  {.pragma: hbDynlib, header: hbHeader.}
  {.pragma: hbAatDynlib, header: hbAatHeader.}
  {.pragma: hbOtDynlib, header: hbOtHeader.}
  {.pragma: hbSubsetDynlib, header: hbSubsetHeader.}
  # Header-based calls require native C struct types. The dynlib path retains
  # its Nim-defined value types for compatibility with C++ callers.
  {.pragma: hbVarIntType, importc: "hb_var_int_t", header: hbHeader, completeStruct.}
  {.pragma: hbVarNumType, importc: "hb_var_num_t", header: hbHeader, completeStruct.}
  {.pragma: hbFeatureType, importc: "hb_feature_t", header: hbHeader, completeStruct.}
  {.
    pragma: hbVariationType, importc: "hb_variation_t", header: hbHeader, completeStruct
  .}
  {.
    pragma: hbGlyphExtentsType,
    importc: "hb_glyph_extents_t",
    header: hbHeader,
    completeStruct
  .}
  {.
    pragma: hbFontExtentsType,
    importc: "hb_font_extents_t",
    header: hbHeader,
    completeStruct
  .}
  {.
    pragma: hbGlyphInfoType,
    importc: "hb_glyph_info_t",
    header: hbHeader,
    completeStruct
  .}
  {.
    pragma: hbGlyphPositionType,
    importc: "hb_glyph_position_t",
    header: hbHeader,
    completeStruct
  .}
  {.
    pragma: hbSegmentPropertiesType,
    importc: "hb_segment_properties_t",
    header: hbHeader,
    completeStruct
  .}
  {.
    pragma: hbUserDataKeyType,
    importc: "hb_user_data_key_t",
    header: hbHeader,
    completeStruct
  .}
  const hbArrayPrefix = "harfbuzzy_"
  const hbArrayHeader = currentSourcePath().parentDir() / "staticArrays.h"
  {.pragma: hbArrayDynlib, header: hbArrayHeader.}
else:
  {.pragma: hbDynlib, dynlib: hbLib.}
  {.pragma: hbAatDynlib, dynlib: hbLib.}
  {.pragma: hbOtDynlib, dynlib: hbLib.}
  {.pragma: hbSubsetDynlib, dynlib: hbSubsetLib.}
  {.pragma: hbVarIntType.}
  {.pragma: hbVarNumType.}
  {.pragma: hbFeatureType.}
  {.pragma: hbVariationType.}
  {.pragma: hbGlyphExtentsType.}
  {.pragma: hbFontExtentsType.}
  {.pragma: hbGlyphInfoType.}
  {.pragma: hbGlyphPositionType.}
  {.pragma: hbSegmentPropertiesType.}
  {.pragma: hbUserDataKeyType.}
  const hbArrayPrefix = ""
  {.pragma: hbArrayDynlib, dynlib: hbLib.}

type
  hb_bool_t* = cint
  hb_codepoint_t* = uint32
  hb_position_t* = int32
  hb_mask_t* = uint32
  hb_tag_t* = uint32
  hb_script_t* = hb_tag_t
  hb_color_t* = uint32
  hb_language_t* = pointer

  hb_direction_t* = distinct cuint
  hb_memory_mode_t* = distinct cuint
  hb_glyph_flags_t* = distinct cuint
  hb_buffer_content_type_t* = distinct cuint
  hb_buffer_flags_t* = distinct cuint
  hb_buffer_cluster_level_t* = distinct cuint
  hb_buffer_serialize_flags_t* = distinct cuint
  hb_buffer_serialize_format_t* = distinct uint32
  hb_subset_sets_t* = distinct cuint
  hb_subset_flags_t* = distinct cuint

  hb_var_int_t* {.hbVarIntType, bycopy, union.} = object
    u32*: uint32
    i32*: int32
    u16*: array[2, uint16]
    i16*: array[2, int16]
    u8*: array[4, uint8]
    i8*: array[4, int8]

  hb_var_num_t* {.hbVarNumType, bycopy, union.} = object
    f*: cfloat
    u32*: uint32
    i32*: int32
    u16*: array[2, uint16]
    i16*: array[2, int16]
    u8*: array[4, uint8]
    i8*: array[4, int8]

  hb_feature_t* {.hbFeatureType, bycopy.} = object
    tag*: hb_tag_t
    value*: uint32
    start*: cuint
    `end`*: cuint

  hb_variation_t* {.hbVariationType, bycopy.} = object
    tag*: hb_tag_t
    value*: cfloat

  hb_glyph_extents_t* {.hbGlyphExtentsType, bycopy.} = object
    x_bearing*: hb_position_t
    y_bearing*: hb_position_t
    width*: hb_position_t
    height*: hb_position_t

  hb_font_extents_t* {.hbFontExtentsType, bycopy.} = object
    ascender*: hb_position_t
    descender*: hb_position_t
    line_gap*: hb_position_t
    reserved9*: hb_position_t
    reserved8*: hb_position_t
    reserved7*: hb_position_t
    reserved6*: hb_position_t
    reserved5*: hb_position_t
    reserved4*: hb_position_t
    reserved3*: hb_position_t
    reserved2*: hb_position_t
    reserved1*: hb_position_t

  hb_glyph_info_t* {.hbGlyphInfoType, bycopy.} = object
    codepoint*: hb_codepoint_t
    mask*: hb_mask_t
    cluster*: uint32
    var1*: hb_var_int_t
    var2*: hb_var_int_t

  hb_glyph_position_t* {.hbGlyphPositionType, bycopy.} = object
    x_advance*: hb_position_t
    y_advance*: hb_position_t
    x_offset*: hb_position_t
    y_offset*: hb_position_t
    `var`*: hb_var_int_t

  hb_segment_properties_t* {.hbSegmentPropertiesType, bycopy.} = object
    direction*: hb_direction_t
    script*: hb_script_t
    language*: hb_language_t
    reserved1*: pointer
    reserved2*: pointer

  hb_user_data_key_t* {.hbUserDataKeyType, bycopy.} = object
    unused*: cchar

  hb_destroy_func_t* = proc(user_data: pointer) {.cdecl.}

  hb_blob_t* {.importc: "hb_blob_t", header: hbHeader, incompleteStruct.} = object
  hb_face_t* {.importc: "hb_face_t", header: hbHeader, incompleteStruct.} = object
  hb_font_t* {.importc: "hb_font_t", header: hbHeader, incompleteStruct.} = object

  hb_font_funcs_t* {.importc: "hb_font_funcs_t", header: hbHeader, incompleteStruct.} = object
  hb_buffer_t* {.importc: "hb_buffer_t", header: hbHeader, incompleteStruct.} = object

  hb_draw_funcs_t* {.importc: "hb_draw_funcs_t", header: hbHeader, incompleteStruct.} = object
  hb_draw_state_t* {.importc: "hb_draw_state_t", header: hbHeader, incompleteStruct.} = object

  hb_draw_move_to_func_t* = proc(
    funcs: ptr hb_draw_funcs_t,
    drawData: pointer,
    state: ptr hb_draw_state_t,
    toX, toY: cfloat,
    userData: pointer,
  ) {.cdecl.}
  hb_draw_line_to_func_t* = hb_draw_move_to_func_t
  hb_draw_quadratic_to_func_t* = proc(
    funcs: ptr hb_draw_funcs_t,
    drawData: pointer,
    state: ptr hb_draw_state_t,
    controlX, controlY, toX, toY: cfloat,
    userData: pointer,
  ) {.cdecl.}
  hb_draw_cubic_to_func_t* = proc(
    funcs: ptr hb_draw_funcs_t,
    drawData: pointer,
    state: ptr hb_draw_state_t,
    control1X, control1Y, control2X, control2Y, toX, toY: cfloat,
    userData: pointer,
  ) {.cdecl.}
  hb_draw_close_path_func_t* = proc(
    funcs: ptr hb_draw_funcs_t,
    drawData: pointer,
    state: ptr hb_draw_state_t,
    userData: pointer,
  ) {.cdecl.}

  hb_shape_plan_t* {.importc: "hb_shape_plan_t", header: hbHeader, incompleteStruct.} = object
  hb_set_t* {.importc: "hb_set_t", header: hbHeader, incompleteStruct.} = object
  hb_map_t* {.importc: "hb_map_t", header: hbHeader, incompleteStruct.} = object

  hb_unicode_funcs_t* {.
    importc: "hb_unicode_funcs_t", header: hbHeader, incompleteStruct
  .} = object

  hb_subset_input_t* {.
    importc: "hb_subset_input_t", header: hbSubsetHeader, incompleteStruct
  .} = object

  hb_subset_plan_t* {.
    importc: "hb_subset_plan_t", header: hbSubsetHeader, incompleteStruct
  .} = object

func HB_TAG*(c1, c2, c3, c4: char): hb_tag_t =
  (uint32(ord(c1)) shl 24) or (uint32(ord(c2)) shl 16) or (uint32(ord(c3)) shl 8) or
    uint32(ord(c4))

const
  HB_VERSION_MAJOR* = 14
  HB_VERSION_MINOR* = 2
  HB_VERSION_MICRO* = 0
  HB_VERSION_STRING* = "14.2.0"

  HB_CODEPOINT_INVALID* = hb_codepoint_t.high

  HB_TAG_NONE* = hb_tag_t(0)
  HB_TAG_MAX* = hb_tag_t(uint32.high)
  HB_TAG_MAX_SIGNED* = HB_TAG(char(0x7f), char(0xff), char(0xff), char(0xff))

  HB_DIRECTION_INVALID* = hb_direction_t(0)
  HB_DIRECTION_LTR* = hb_direction_t(4)
  HB_DIRECTION_RTL* = hb_direction_t(5)
  HB_DIRECTION_TTB* = hb_direction_t(6)
  HB_DIRECTION_BTT* = hb_direction_t(7)

  HB_LANGUAGE_INVALID* = hb_language_t(nil)

  HB_SCRIPT_COMMON* = HB_TAG('Z', 'y', 'y', 'y')
  HB_SCRIPT_INHERITED* = HB_TAG('Z', 'i', 'n', 'h')
  HB_SCRIPT_UNKNOWN* = HB_TAG('Z', 'z', 'z', 'z')
  HB_SCRIPT_ARABIC* = HB_TAG('A', 'r', 'a', 'b')
  HB_SCRIPT_LATIN* = HB_TAG('L', 'a', 't', 'n')
  HB_SCRIPT_INVALID* = HB_TAG_NONE

  HB_FEATURE_GLOBAL_START* = cuint(0)
  HB_FEATURE_GLOBAL_END* = cuint.high

  HB_MEMORY_MODE_DUPLICATE* = hb_memory_mode_t(0)
  HB_MEMORY_MODE_READONLY* = hb_memory_mode_t(1)
  HB_MEMORY_MODE_WRITABLE* = hb_memory_mode_t(2)
  HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE* = hb_memory_mode_t(3)

  HB_GLYPH_FLAG_UNSAFE_TO_BREAK* = hb_glyph_flags_t(0x00000001)
  HB_GLYPH_FLAG_UNSAFE_TO_CONCAT* = hb_glyph_flags_t(0x00000002)
  HB_GLYPH_FLAG_SAFE_TO_INSERT_TATWEEL* = hb_glyph_flags_t(0x00000004)
  HB_GLYPH_FLAG_DEFINED* = hb_glyph_flags_t(0x00000007)

  HB_BUFFER_CONTENT_TYPE_INVALID* = hb_buffer_content_type_t(0)
  HB_BUFFER_CONTENT_TYPE_UNICODE* = hb_buffer_content_type_t(1)
  HB_BUFFER_CONTENT_TYPE_GLYPHS* = hb_buffer_content_type_t(2)

  HB_BUFFER_FLAG_DEFAULT* = hb_buffer_flags_t(0x00000000)
  HB_BUFFER_FLAG_BOT* = hb_buffer_flags_t(0x00000001)
  HB_BUFFER_FLAG_EOT* = hb_buffer_flags_t(0x00000002)
  HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES* = hb_buffer_flags_t(0x00000004)
  HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES* = hb_buffer_flags_t(0x00000008)
  HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE* = hb_buffer_flags_t(0x00000010)
  HB_BUFFER_FLAG_VERIFY* = hb_buffer_flags_t(0x00000020)
  HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT* = hb_buffer_flags_t(0x00000040)
  HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL* = hb_buffer_flags_t(0x00000080)
  HB_BUFFER_FLAG_DEFINED* = hb_buffer_flags_t(0x000000ff)

  HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES* = hb_buffer_cluster_level_t(0)
  HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS* = hb_buffer_cluster_level_t(1)
  HB_BUFFER_CLUSTER_LEVEL_CHARACTERS* = hb_buffer_cluster_level_t(2)
  HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES* = hb_buffer_cluster_level_t(3)
  HB_BUFFER_CLUSTER_LEVEL_DEFAULT* = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES

  HB_BUFFER_SERIALIZE_FLAG_DEFAULT* = hb_buffer_serialize_flags_t(0x00000000)
  HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS* = hb_buffer_serialize_flags_t(0x00000001)
  HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS* = hb_buffer_serialize_flags_t(0x00000002)
  HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES* = hb_buffer_serialize_flags_t(0x00000004)
  HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS* = hb_buffer_serialize_flags_t(0x00000008)
  HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS* = hb_buffer_serialize_flags_t(0x00000010)
  HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES* = hb_buffer_serialize_flags_t(0x00000020)
  HB_BUFFER_SERIALIZE_FLAG_DEFINED* = hb_buffer_serialize_flags_t(0x0000003f)

  HB_BUFFER_SERIALIZE_FORMAT_TEXT* =
    hb_buffer_serialize_format_t(HB_TAG('T', 'E', 'X', 'T'))
  HB_BUFFER_SERIALIZE_FORMAT_JSON* =
    hb_buffer_serialize_format_t(HB_TAG('J', 'S', 'O', 'N'))
  HB_BUFFER_SERIALIZE_FORMAT_INVALID* = hb_buffer_serialize_format_t(HB_TAG_NONE)

  HB_OT_TAG_GSUB* = HB_TAG('G', 'S', 'U', 'B')
  HB_OT_TAG_GPOS* = HB_TAG('G', 'P', 'O', 'S')
  HB_OT_LAYOUT_NO_FEATURE_INDEX* = cuint(0xffff)
  HB_OT_LAYOUT_DEFAULT_LANGUAGE_INDEX* = cuint(0xffff)

  HB_SET_VALUE_INVALID* = HB_CODEPOINT_INVALID

  HB_SUBSET_SETS_GLYPH_INDEX* = hb_subset_sets_t(0)
  HB_SUBSET_SETS_UNICODE* = hb_subset_sets_t(1)
  HB_SUBSET_SETS_NO_SUBSET_TABLE_TAG* = hb_subset_sets_t(2)
  HB_SUBSET_SETS_DROP_TABLE_TAG* = hb_subset_sets_t(3)
  HB_SUBSET_SETS_NAME_ID* = hb_subset_sets_t(4)
  HB_SUBSET_SETS_NAME_LANG_ID* = hb_subset_sets_t(5)
  HB_SUBSET_SETS_LAYOUT_FEATURE_TAG* = hb_subset_sets_t(6)
  HB_SUBSET_SETS_LAYOUT_SCRIPT_TAG* = hb_subset_sets_t(7)

func hb_direction_is_valid*(dir: hb_direction_t): bool =
  (cuint(dir) and not 3'u32) == 4'u32

func hb_direction_is_horizontal*(dir: hb_direction_t): bool =
  (cuint(dir) and not 1'u32) == 4'u32

func hb_direction_is_vertical*(dir: hb_direction_t): bool =
  (cuint(dir) and not 1'u32) == 6'u32

func hb_direction_reverse*(dir: hb_direction_t): hb_direction_t =
  hb_direction_t(cuint(dir) xor 1'u32)

func `or`*(a, b: hb_buffer_flags_t): hb_buffer_flags_t =
  hb_buffer_flags_t(cuint(a) or cuint(b))

func `and`*(a, b: hb_buffer_flags_t): hb_buffer_flags_t =
  hb_buffer_flags_t(cuint(a) and cuint(b))

func contains*(flags, flag: hb_buffer_flags_t): bool =
  (cuint(flags) and cuint(flag)) != 0

func `or`*(a, b: hb_buffer_serialize_flags_t): hb_buffer_serialize_flags_t =
  hb_buffer_serialize_flags_t(cuint(a) or cuint(b))

proc hb_version*(
  major, minor, micro: ptr cuint
) {.cdecl, importc: "hb_version", hbDynlib.}

proc hb_version_string*(): cstring {.cdecl, importc: "hb_version_string", hbDynlib.}

proc hb_version_atleast*(
  major, minor, micro: cuint
): hb_bool_t {.cdecl, importc: "hb_version_atleast", hbDynlib.}

proc hb_tag_from_string*(
  str: cstring, len: cint
): hb_tag_t {.cdecl, importc: "hb_tag_from_string", hbDynlib.}

proc hb_tag_to_string*(
  tag: hb_tag_t, buf: cstring
) {.cdecl, importc: "hb_tag_to_string", hbDynlib.}

proc hb_direction_from_string*(
  str: cstring, len: cint
): hb_direction_t {.cdecl, importc: "hb_direction_from_string", hbDynlib.}

proc hb_direction_to_string*(
  direction: hb_direction_t
): cstring {.cdecl, importc: "hb_direction_to_string", hbDynlib.}

proc hb_language_from_string*(
  str: cstring, len: cint
): hb_language_t {.cdecl, importc: "hb_language_from_string", hbDynlib.}

proc hb_language_to_string*(
  language: hb_language_t
): cstring {.cdecl, importc: "hb_language_to_string", hbDynlib.}

proc hb_language_get_default*(): hb_language_t {.
  cdecl, importc: "hb_language_get_default", hbDynlib
.}

proc hb_language_matches*(
  language, specific: hb_language_t
): hb_bool_t {.cdecl, importc: "hb_language_matches", hbDynlib.}

proc hb_script_from_iso15924_tag*(
  tag: hb_tag_t
): hb_script_t {.cdecl, importc: "hb_script_from_iso15924_tag", hbDynlib.}

proc hb_script_from_string*(
  str: cstring, len: cint
): hb_script_t {.cdecl, importc: "hb_script_from_string", hbDynlib.}

proc hb_script_to_iso15924_tag*(
  script: hb_script_t
): hb_tag_t {.cdecl, importc: "hb_script_to_iso15924_tag", hbDynlib.}

proc hb_script_get_horizontal_direction*(
  script: hb_script_t
): hb_direction_t {.cdecl, importc: "hb_script_get_horizontal_direction", hbDynlib.}

proc hb_unicode_funcs_get_default*(): ptr hb_unicode_funcs_t {.
  cdecl, importc: "hb_unicode_funcs_get_default", hbDynlib
.}

proc hb_unicode_script*(
  ufuncs: ptr hb_unicode_funcs_t, unicode: hb_codepoint_t
): hb_script_t {.cdecl, importc: "hb_unicode_script", hbDynlib.}

proc hb_feature_from_string*(
  str: cstring, len: cint, feature: ptr hb_feature_t
): hb_bool_t {.cdecl, importc: "hb_feature_from_string", hbDynlib.}

proc hb_feature_to_string*(
  feature: ptr hb_feature_t, buf: cstring, size: cuint
) {.cdecl, importc: "hb_feature_to_string", hbDynlib.}

proc hb_blob_create*(
  data: cstring,
  length: cuint,
  mode: hb_memory_mode_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
): ptr hb_blob_t {.cdecl, importc: "hb_blob_create", hbDynlib.}

proc hb_blob_create_or_fail*(
  data: cstring,
  length: cuint,
  mode: hb_memory_mode_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
): ptr hb_blob_t {.cdecl, importc: "hb_blob_create_or_fail", hbDynlib.}

proc hb_blob_create_from_file*(
  fileName: cstring
): ptr hb_blob_t {.cdecl, importc: "hb_blob_create_from_file", hbDynlib.}

proc hb_blob_create_from_file_or_fail*(
  fileName: cstring
): ptr hb_blob_t {.cdecl, importc: "hb_blob_create_from_file_or_fail", hbDynlib.}

proc hb_blob_create_sub_blob*(
  parent: ptr hb_blob_t, offset, length: cuint
): ptr hb_blob_t {.cdecl, importc: "hb_blob_create_sub_blob", hbDynlib.}

proc hb_blob_get_empty*(): ptr hb_blob_t {.
  cdecl, importc: "hb_blob_get_empty", hbDynlib
.}

proc hb_blob_reference*(
  blob: ptr hb_blob_t
): ptr hb_blob_t {.cdecl, importc: "hb_blob_reference", hbDynlib.}

proc hb_blob_destroy*(
  blob: ptr hb_blob_t
) {.cdecl, importc: "hb_blob_destroy", hbDynlib.}

proc hb_blob_get_length*(
  blob: ptr hb_blob_t
): cuint {.cdecl, importc: "hb_blob_get_length", hbDynlib.}

proc hb_blob_get_data*(
  blob: ptr hb_blob_t, length: ptr cuint
): cstring {.cdecl, importc: "hb_blob_get_data", hbDynlib.}

proc hb_blob_make_immutable*(
  blob: ptr hb_blob_t
) {.cdecl, importc: "hb_blob_make_immutable", hbDynlib.}

proc hb_blob_is_immutable*(
  blob: ptr hb_blob_t
): hb_bool_t {.cdecl, importc: "hb_blob_is_immutable", hbDynlib.}

proc hb_face_count*(
  blob: ptr hb_blob_t
): cuint {.cdecl, importc: "hb_face_count", hbDynlib.}

proc hb_face_create*(
  blob: ptr hb_blob_t, index: cuint
): ptr hb_face_t {.cdecl, importc: "hb_face_create", hbDynlib.}

proc hb_face_create_or_fail*(
  blob: ptr hb_blob_t, index: cuint
): ptr hb_face_t {.cdecl, importc: "hb_face_create_or_fail", hbDynlib.}

proc hb_face_create_from_file_or_fail*(
  fileName: cstring, index: cuint
): ptr hb_face_t {.cdecl, importc: "hb_face_create_from_file_or_fail", hbDynlib.}

proc hb_face_get_empty*(): ptr hb_face_t {.
  cdecl, importc: "hb_face_get_empty", hbDynlib
.}

proc hb_face_reference*(
  face: ptr hb_face_t
): ptr hb_face_t {.cdecl, importc: "hb_face_reference", hbDynlib.}

proc hb_face_destroy*(
  face: ptr hb_face_t
) {.cdecl, importc: "hb_face_destroy", hbDynlib.}

proc hb_face_reference_table*(
  face: ptr hb_face_t, tag: hb_tag_t
): ptr hb_blob_t {.cdecl, importc: "hb_face_reference_table", hbDynlib.}

proc hb_face_reference_blob*(
  face: ptr hb_face_t
): ptr hb_blob_t {.cdecl, importc: "hb_face_reference_blob", hbDynlib.}

proc hb_face_get_index*(
  face: ptr hb_face_t
): cuint {.cdecl, importc: "hb_face_get_index", hbDynlib.}

proc hb_face_get_upem*(
  face: ptr hb_face_t
): cuint {.cdecl, importc: "hb_face_get_upem", hbDynlib.}

proc hb_face_get_glyph_count*(
  face: ptr hb_face_t
): cuint {.cdecl, importc: "hb_face_get_glyph_count", hbDynlib.}

proc hb_font_create*(
  face: ptr hb_face_t
): ptr hb_font_t {.cdecl, importc: "hb_font_create", hbDynlib.}

proc hb_font_get_empty*(): ptr hb_font_t {.
  cdecl, importc: "hb_font_get_empty", hbDynlib
.}

proc hb_font_reference*(
  font: ptr hb_font_t
): ptr hb_font_t {.cdecl, importc: "hb_font_reference", hbDynlib.}

proc hb_font_destroy*(
  font: ptr hb_font_t
) {.cdecl, importc: "hb_font_destroy", hbDynlib.}

proc hb_font_get_face*(
  font: ptr hb_font_t
): ptr hb_face_t {.cdecl, importc: "hb_font_get_face", hbDynlib.}

proc hb_font_set_scale*(
  font: ptr hb_font_t, xScale, yScale: cint
) {.cdecl, importc: "hb_font_set_scale", hbDynlib.}

proc hb_font_get_scale*(
  font: ptr hb_font_t, xScale, yScale: ptr cint
) {.cdecl, importc: "hb_font_get_scale", hbDynlib.}

proc hb_font_set_ppem*(
  font: ptr hb_font_t, xPpem, yPpem: cuint
) {.cdecl, importc: "hb_font_set_ppem", hbDynlib.}

proc hb_font_get_ppem*(
  font: ptr hb_font_t, xPpem, yPpem: ptr cuint
) {.cdecl, importc: "hb_font_get_ppem", hbDynlib.}

proc hb_font_set_variations*(
  font: ptr hb_font_t, variations: ptr hb_variation_t, variationsLength: cuint
) {.cdecl, importc: "hb_font_set_variations", hbDynlib.}

proc hb_font_get_h_extents*(
  font: ptr hb_font_t, extents: ptr hb_font_extents_t
): hb_bool_t {.cdecl, importc: "hb_font_get_h_extents", hbDynlib.}

proc hb_font_get_v_extents*(
  font: ptr hb_font_t, extents: ptr hb_font_extents_t
): hb_bool_t {.cdecl, importc: "hb_font_get_v_extents", hbDynlib.}

proc hb_font_get_nominal_glyph*(
  font: ptr hb_font_t, unicode: hb_codepoint_t, glyph: ptr hb_codepoint_t
): hb_bool_t {.cdecl, importc: "hb_font_get_nominal_glyph", hbDynlib.}

proc hb_font_get_glyph*(
  font: ptr hb_font_t,
  unicode, variationSelector: hb_codepoint_t,
  glyph: ptr hb_codepoint_t,
): hb_bool_t {.cdecl, importc: "hb_font_get_glyph", hbDynlib.}

proc hb_font_get_glyph_h_advance*(
  font: ptr hb_font_t, glyph: hb_codepoint_t
): hb_position_t {.cdecl, importc: "hb_font_get_glyph_h_advance", hbDynlib.}

proc hb_font_get_glyph_v_advance*(
  font: ptr hb_font_t, glyph: hb_codepoint_t
): hb_position_t {.cdecl, importc: "hb_font_get_glyph_v_advance", hbDynlib.}

proc hb_font_get_extents_for_direction*(
  font: ptr hb_font_t, direction: hb_direction_t, extents: ptr hb_font_extents_t
) {.cdecl, importc: "hb_font_get_extents_for_direction", hbDynlib.}

proc hb_font_get_glyph_advance_for_direction*(
  font: ptr hb_font_t,
  glyph: hb_codepoint_t,
  direction: hb_direction_t,
  x, y: ptr hb_position_t,
) {.cdecl, importc: "hb_font_get_glyph_advance_for_direction", hbDynlib.}

proc hb_font_get_glyph_extents*(
  font: ptr hb_font_t, glyph: hb_codepoint_t, extents: ptr hb_glyph_extents_t
): hb_bool_t {.cdecl, importc: "hb_font_get_glyph_extents", hbDynlib.}

proc hb_ot_font_set_funcs*(
  font: ptr hb_font_t
) {.cdecl, importc: "hb_ot_font_set_funcs", hbOtDynlib.}

proc hb_aat_layout_has_substitution*(
  face: ptr hb_face_t
): hb_bool_t {.cdecl, importc: "hb_aat_layout_has_substitution", hbAatDynlib.}

proc hb_aat_layout_has_positioning*(
  face: ptr hb_face_t
): hb_bool_t {.cdecl, importc: "hb_aat_layout_has_positioning", hbAatDynlib.}

proc hb_aat_layout_has_tracking*(
  face: ptr hb_face_t
): hb_bool_t {.cdecl, importc: "hb_aat_layout_has_tracking", hbAatDynlib.}

proc hb_ot_layout_has_substitution*(
  face: ptr hb_face_t
): hb_bool_t {.cdecl, importc: "hb_ot_layout_has_substitution", hbOtDynlib.}

proc hb_ot_layout_has_positioning*(
  face: ptr hb_face_t
): hb_bool_t {.cdecl, importc: "hb_ot_layout_has_positioning", hbOtDynlib.}

proc hb_ot_layout_table_get_feature_tags*(
  face: ptr hb_face_t,
  tableTag: hb_tag_t,
  startOffset: cuint,
  featureCount: ptr cuint,
  featureTags: ptr hb_tag_t,
): cuint {.cdecl, importc: "hb_ot_layout_table_get_feature_tags", hbOtDynlib.}

proc hb_ot_layout_table_find_script*(
  face: ptr hb_face_t, tableTag, scriptTag: hb_tag_t, scriptIndex: ptr cuint
): hb_bool_t {.cdecl, importc: "hb_ot_layout_table_find_script", hbOtDynlib.}

proc hb_ot_layout_script_select_language2*(
  face: ptr hb_face_t,
  tableTag: hb_tag_t,
  scriptIndex: cuint,
  languageCount: cuint,
  languageTags: ptr hb_tag_t,
  languageIndex: ptr cuint,
  chosenLanguage: ptr hb_tag_t,
): hb_bool_t {.cdecl, importc: "hb_ot_layout_script_select_language2", hbOtDynlib.}

proc hb_ot_layout_language_get_feature_tags*(
  face: ptr hb_face_t,
  tableTag: hb_tag_t,
  scriptIndex: cuint,
  languageIndex: cuint,
  startOffset: cuint,
  featureCount: ptr cuint,
  featureTags: ptr hb_tag_t,
): cuint {.cdecl, importc: "hb_ot_layout_language_get_feature_tags", hbOtDynlib.}

proc hb_buffer_create*(): ptr hb_buffer_t {.
  cdecl, importc: "hb_buffer_create", hbDynlib
.}

proc hb_buffer_create_similar*(
  src: ptr hb_buffer_t
): ptr hb_buffer_t {.cdecl, importc: "hb_buffer_create_similar", hbDynlib.}

proc hb_buffer_get_empty*(): ptr hb_buffer_t {.
  cdecl, importc: "hb_buffer_get_empty", hbDynlib
.}

proc hb_buffer_reference*(
  buffer: ptr hb_buffer_t
): ptr hb_buffer_t {.cdecl, importc: "hb_buffer_reference", hbDynlib.}

proc hb_buffer_destroy*(
  buffer: ptr hb_buffer_t
) {.cdecl, importc: "hb_buffer_destroy", hbDynlib.}

proc hb_buffer_reset*(
  buffer: ptr hb_buffer_t
) {.cdecl, importc: "hb_buffer_reset", hbDynlib.}

proc hb_buffer_clear_contents*(
  buffer: ptr hb_buffer_t
) {.cdecl, importc: "hb_buffer_clear_contents", hbDynlib.}

proc hb_buffer_set_content_type*(
  buffer: ptr hb_buffer_t, contentType: hb_buffer_content_type_t
) {.cdecl, importc: "hb_buffer_set_content_type", hbDynlib.}

proc hb_buffer_get_content_type*(
  buffer: ptr hb_buffer_t
): hb_buffer_content_type_t {.cdecl, importc: "hb_buffer_get_content_type", hbDynlib.}

proc hb_buffer_set_direction*(
  buffer: ptr hb_buffer_t, direction: hb_direction_t
) {.cdecl, importc: "hb_buffer_set_direction", hbDynlib.}

proc hb_buffer_get_direction*(
  buffer: ptr hb_buffer_t
): hb_direction_t {.cdecl, importc: "hb_buffer_get_direction", hbDynlib.}

proc hb_buffer_set_script*(
  buffer: ptr hb_buffer_t, script: hb_script_t
) {.cdecl, importc: "hb_buffer_set_script", hbDynlib.}

proc hb_buffer_get_script*(
  buffer: ptr hb_buffer_t
): hb_script_t {.cdecl, importc: "hb_buffer_get_script", hbDynlib.}

proc hb_buffer_set_language*(
  buffer: ptr hb_buffer_t, language: hb_language_t
) {.cdecl, importc: "hb_buffer_set_language", hbDynlib.}

proc hb_buffer_get_language*(
  buffer: ptr hb_buffer_t
): hb_language_t {.cdecl, importc: "hb_buffer_get_language", hbDynlib.}

proc hb_buffer_set_segment_properties*(
  buffer: ptr hb_buffer_t, props: ptr hb_segment_properties_t
) {.cdecl, importc: "hb_buffer_set_segment_properties", hbDynlib.}

proc hb_buffer_get_segment_properties*(
  buffer: ptr hb_buffer_t, props: ptr hb_segment_properties_t
) {.cdecl, importc: "hb_buffer_get_segment_properties", hbDynlib.}

proc hb_buffer_guess_segment_properties*(
  buffer: ptr hb_buffer_t
) {.cdecl, importc: "hb_buffer_guess_segment_properties", hbDynlib.}

proc hb_buffer_set_flags*(
  buffer: ptr hb_buffer_t, flags: hb_buffer_flags_t
) {.cdecl, importc: "hb_buffer_set_flags", hbDynlib.}

proc hb_buffer_get_flags*(
  buffer: ptr hb_buffer_t
): hb_buffer_flags_t {.cdecl, importc: "hb_buffer_get_flags", hbDynlib.}

proc hb_buffer_set_cluster_level*(
  buffer: ptr hb_buffer_t, level: hb_buffer_cluster_level_t
) {.cdecl, importc: "hb_buffer_set_cluster_level", hbDynlib.}

proc hb_buffer_get_cluster_level*(
  buffer: ptr hb_buffer_t
): hb_buffer_cluster_level_t {.cdecl, importc: "hb_buffer_get_cluster_level", hbDynlib.}

proc hb_buffer_add*(
  buffer: ptr hb_buffer_t, codepoint: hb_codepoint_t, cluster: cuint
) {.cdecl, importc: "hb_buffer_add", hbDynlib.}

proc hb_buffer_add_utf8*(
  buffer: ptr hb_buffer_t,
  text: cstring,
  textLength: cint,
  itemOffset: cuint,
  itemLength: cint,
) {.cdecl, importc: "hb_buffer_add_utf8", hbDynlib.}

proc hb_buffer_add_utf32*(
  buffer: ptr hb_buffer_t,
  text: ptr uint32,
  textLength: cint,
  itemOffset: cuint,
  itemLength: cint,
) {.cdecl, importc: "hb_buffer_add_utf32", hbDynlib.}

proc hb_buffer_add_codepoints*(
  buffer: ptr hb_buffer_t,
  text: ptr hb_codepoint_t,
  textLength: cint,
  itemOffset: cuint,
  itemLength: cint,
) {.cdecl, importc: "hb_buffer_add_codepoints", hbDynlib.}

proc hb_buffer_set_length*(
  buffer: ptr hb_buffer_t, length: cuint
): hb_bool_t {.cdecl, importc: "hb_buffer_set_length", hbDynlib.}

proc hb_buffer_get_length*(
  buffer: ptr hb_buffer_t
): cuint {.cdecl, importc: "hb_buffer_get_length", hbDynlib.}

proc hb_buffer_get_glyph_infos*(
  buffer: ptr hb_buffer_t, length: ptr cuint
): ptr UncheckedArray[hb_glyph_info_t] {.
  cdecl, importc: "hb_buffer_get_glyph_infos", hbDynlib
.}

proc hb_buffer_get_glyph_positions*(
  buffer: ptr hb_buffer_t, length: ptr cuint
): ptr UncheckedArray[hb_glyph_position_t] {.
  cdecl, importc: "hb_buffer_get_glyph_positions", hbDynlib
.}

proc hb_buffer_has_positions*(
  buffer: ptr hb_buffer_t
): hb_bool_t {.cdecl, importc: "hb_buffer_has_positions", hbDynlib.}

proc hb_buffer_serialize_format_from_string*(
  str: cstring, len: cint
): hb_buffer_serialize_format_t {.
  cdecl, importc: "hb_buffer_serialize_format_from_string", hbDynlib
.}

proc hb_buffer_serialize_format_to_string*(
  format: hb_buffer_serialize_format_t
): cstring {.cdecl, importc: "hb_buffer_serialize_format_to_string", hbDynlib.}

proc hb_buffer_serialize_list_formats*(): ptr cstring {.
  cdecl, importc: (hbArrayPrefix & "hb_buffer_serialize_list_formats"), hbArrayDynlib
.}

proc hb_buffer_serialize_glyphs*(
  buffer: ptr hb_buffer_t,
  start, ending: cuint,
  buf: cstring,
  bufSize: cuint,
  bufConsumed: ptr cuint,
  font: ptr hb_font_t,
  format: hb_buffer_serialize_format_t,
  flags: hb_buffer_serialize_flags_t,
): cuint {.cdecl, importc: "hb_buffer_serialize_glyphs", hbDynlib.}

proc hb_shape*(
  font: ptr hb_font_t,
  buffer: ptr hb_buffer_t,
  features: ptr hb_feature_t,
  numFeatures: cuint,
) {.cdecl, importc: "hb_shape", hbDynlib.}

proc hb_shape_full*(
  font: ptr hb_font_t,
  buffer: ptr hb_buffer_t,
  features: ptr hb_feature_t,
  numFeatures: cuint,
  shaperList: ptr cstring,
): hb_bool_t {.cdecl, importc: (hbArrayPrefix & "hb_shape_full"), hbArrayDynlib.}

proc hb_shape_list_shapers*(): ptr cstring {.
  cdecl, importc: (hbArrayPrefix & "hb_shape_list_shapers"), hbArrayDynlib
.}

proc hb_shape_plan_create*(
  face: ptr hb_face_t,
  props: ptr hb_segment_properties_t,
  userFeatures: ptr hb_feature_t,
  numUserFeatures: cuint,
  shaperList: ptr cstring,
): ptr hb_shape_plan_t {.
  cdecl, importc: (hbArrayPrefix & "hb_shape_plan_create"), hbArrayDynlib
.}

proc hb_shape_plan_create_cached*(
  face: ptr hb_face_t,
  props: ptr hb_segment_properties_t,
  userFeatures: ptr hb_feature_t,
  numUserFeatures: cuint,
  shaperList: ptr cstring,
): ptr hb_shape_plan_t {.
  cdecl, importc: (hbArrayPrefix & "hb_shape_plan_create_cached"), hbArrayDynlib
.}

proc hb_shape_plan_reference*(
  shapePlan: ptr hb_shape_plan_t
): ptr hb_shape_plan_t {.cdecl, importc: "hb_shape_plan_reference", hbDynlib.}

proc hb_shape_plan_destroy*(
  shapePlan: ptr hb_shape_plan_t
) {.cdecl, importc: "hb_shape_plan_destroy", hbDynlib.}

proc hb_shape_plan_execute*(
  shapePlan: ptr hb_shape_plan_t,
  font: ptr hb_font_t,
  buffer: ptr hb_buffer_t,
  features: ptr hb_feature_t,
  numFeatures: cuint,
): hb_bool_t {.cdecl, importc: "hb_shape_plan_execute", hbDynlib.}

proc hb_shape_plan_get_shaper*(
  shapePlan: ptr hb_shape_plan_t
): cstring {.cdecl, importc: "hb_shape_plan_get_shaper", hbDynlib.}

proc hb_set_create*(): ptr hb_set_t {.cdecl, importc: "hb_set_create", hbDynlib.}
proc hb_set_get_empty*(): ptr hb_set_t {.cdecl, importc: "hb_set_get_empty", hbDynlib.}
proc hb_set_reference*(
  set: ptr hb_set_t
): ptr hb_set_t {.cdecl, importc: "hb_set_reference", hbDynlib.}

proc hb_set_destroy*(set: ptr hb_set_t) {.cdecl, importc: "hb_set_destroy", hbDynlib.}
proc hb_set_copy*(
  set: ptr hb_set_t
): ptr hb_set_t {.cdecl, importc: "hb_set_copy", hbDynlib.}

proc hb_set_clear*(set: ptr hb_set_t) {.cdecl, importc: "hb_set_clear", hbDynlib.}
proc hb_set_is_empty*(
  set: ptr hb_set_t
): hb_bool_t {.cdecl, importc: "hb_set_is_empty", hbDynlib.}

proc hb_set_has*(
  set: ptr hb_set_t, codepoint: hb_codepoint_t
): hb_bool_t {.cdecl, importc: "hb_set_has", hbDynlib.}

proc hb_set_add*(
  set: ptr hb_set_t, codepoint: hb_codepoint_t
) {.cdecl, importc: "hb_set_add", hbDynlib.}

proc hb_set_add_range*(
  set: ptr hb_set_t, first, last: hb_codepoint_t
) {.cdecl, importc: "hb_set_add_range", hbDynlib.}

proc hb_set_del*(
  set: ptr hb_set_t, codepoint: hb_codepoint_t
) {.cdecl, importc: "hb_set_del", hbDynlib.}

proc hb_set_get_population*(
  set: ptr hb_set_t
): cuint {.cdecl, importc: "hb_set_get_population", hbDynlib.}

proc hb_set_get_min*(
  set: ptr hb_set_t
): hb_codepoint_t {.cdecl, importc: "hb_set_get_min", hbDynlib.}

proc hb_set_get_max*(
  set: ptr hb_set_t
): hb_codepoint_t {.cdecl, importc: "hb_set_get_max", hbDynlib.}

proc hb_set_next*(
  set: ptr hb_set_t, codepoint: ptr hb_codepoint_t
): hb_bool_t {.cdecl, importc: "hb_set_next", hbDynlib.}

proc hb_subset_input_create_or_fail*(): ptr hb_subset_input_t {.
  cdecl, importc: "hb_subset_input_create_or_fail", hbSubsetDynlib
.}

proc hb_subset_input_reference*(
  input: ptr hb_subset_input_t
): ptr hb_subset_input_t {.cdecl, importc: "hb_subset_input_reference", hbSubsetDynlib.}

proc hb_subset_input_destroy*(
  input: ptr hb_subset_input_t
) {.cdecl, importc: "hb_subset_input_destroy", hbSubsetDynlib.}

proc hb_subset_input_keep_everything*(
  input: ptr hb_subset_input_t
) {.cdecl, importc: "hb_subset_input_keep_everything", hbSubsetDynlib.}

proc hb_subset_input_unicode_set*(
  input: ptr hb_subset_input_t
): ptr hb_set_t {.cdecl, importc: "hb_subset_input_unicode_set", hbSubsetDynlib.}

proc hb_subset_input_glyph_set*(
  input: ptr hb_subset_input_t
): ptr hb_set_t {.cdecl, importc: "hb_subset_input_glyph_set", hbSubsetDynlib.}

proc hb_subset_input_set*(
  input: ptr hb_subset_input_t, setType: hb_subset_sets_t
): ptr hb_set_t {.cdecl, importc: "hb_subset_input_set", hbSubsetDynlib.}

proc hb_subset_input_set_flags*(
  input: ptr hb_subset_input_t, value: cuint
) {.cdecl, importc: "hb_subset_input_set_flags", hbSubsetDynlib.}

proc hb_subset_input_get_flags*(
  input: ptr hb_subset_input_t
): hb_subset_flags_t {.cdecl, importc: "hb_subset_input_get_flags", hbSubsetDynlib.}

proc hb_subset_input_pin_axis_location*(
  input: ptr hb_subset_input_t,
  face: ptr hb_face_t,
  axisTag: hb_tag_t,
  axisValue: cfloat,
): hb_bool_t {.cdecl, importc: "hb_subset_input_pin_axis_location", hbSubsetDynlib.}

proc hb_subset_preprocess*(
  source: ptr hb_face_t
): ptr hb_face_t {.cdecl, importc: "hb_subset_preprocess", hbSubsetDynlib.}

proc hb_subset_or_fail*(
  source: ptr hb_face_t, input: ptr hb_subset_input_t
): ptr hb_face_t {.cdecl, importc: "hb_subset_or_fail", hbSubsetDynlib.}

proc hb_subset_plan_create_or_fail*(
  face: ptr hb_face_t, input: ptr hb_subset_input_t
): ptr hb_subset_plan_t {.
  cdecl, importc: "hb_subset_plan_create_or_fail", hbSubsetDynlib
.}

proc hb_subset_plan_reference*(
  plan: ptr hb_subset_plan_t
): ptr hb_subset_plan_t {.cdecl, importc: "hb_subset_plan_reference", hbSubsetDynlib.}

proc hb_subset_plan_destroy*(
  plan: ptr hb_subset_plan_t
) {.cdecl, importc: "hb_subset_plan_destroy", hbSubsetDynlib.}

proc hb_subset_plan_execute_or_fail*(
  plan: ptr hb_subset_plan_t
): ptr hb_face_t {.cdecl, importc: "hb_subset_plan_execute_or_fail", hbSubsetDynlib.}

proc hb_draw_funcs_create*(): ptr hb_draw_funcs_t {.
  cdecl, importc: "hb_draw_funcs_create", hbDynlib
.}

proc hb_draw_funcs_destroy*(
  funcs: ptr hb_draw_funcs_t
) {.cdecl, importc: "hb_draw_funcs_destroy", hbDynlib.}

proc hb_draw_funcs_make_immutable*(
  funcs: ptr hb_draw_funcs_t
) {.cdecl, importc: "hb_draw_funcs_make_immutable", hbDynlib.}

proc hb_draw_funcs_set_move_to_func*(
  funcs: ptr hb_draw_funcs_t,
  callback: hb_draw_move_to_func_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
) {.cdecl, importc: "hb_draw_funcs_set_move_to_func", hbDynlib.}

proc hb_draw_funcs_set_line_to_func*(
  funcs: ptr hb_draw_funcs_t,
  callback: hb_draw_line_to_func_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
) {.cdecl, importc: "hb_draw_funcs_set_line_to_func", hbDynlib.}

proc hb_draw_funcs_set_quadratic_to_func*(
  funcs: ptr hb_draw_funcs_t,
  callback: hb_draw_quadratic_to_func_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
) {.cdecl, importc: "hb_draw_funcs_set_quadratic_to_func", hbDynlib.}

proc hb_draw_funcs_set_cubic_to_func*(
  funcs: ptr hb_draw_funcs_t,
  callback: hb_draw_cubic_to_func_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
) {.cdecl, importc: "hb_draw_funcs_set_cubic_to_func", hbDynlib.}

proc hb_draw_funcs_set_close_path_func*(
  funcs: ptr hb_draw_funcs_t,
  callback: hb_draw_close_path_func_t,
  userData: pointer,
  destroy: hb_destroy_func_t,
) {.cdecl, importc: "hb_draw_funcs_set_close_path_func", hbDynlib.}

proc hb_font_draw_glyph*(
  font: ptr hb_font_t,
  glyph: hb_codepoint_t,
  funcs: ptr hb_draw_funcs_t,
  drawData: pointer,
) {.cdecl, importc: "hb_font_draw_glyph", hbDynlib.}
