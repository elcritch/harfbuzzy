## Low-level HarfBuzz C API bindings.
##
## This module is intentionally ABI-shaped: opaque handles remain raw pointers,
## C enum and flag domains are distinct integer types, and public structs keep
## the field order used by deps/harfbuzz/src/*.h.

import std/os

when defined(harfbuzzyStatic):
  import harfbuzzy/private/staticHarfbuzz

const hbSourceDir =
  when defined(harfbuzzyStatic):
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

when defined(harfbuzzyStatic):
  {.passL: quoteShell(staticHarfbuzz.harfbuzzSubsetStaticLib).}
  {.passL: quoteShell(staticHarfbuzz.harfbuzzStaticLib).}
  when defined(posix):
    {.passL: "-pthread".}

const
  hbHeader = "hb.h"
  hbSubsetHeader = "hb-subset.h"

when defined(harfbuzzyStatic):
  const hbAatHeader = "hb-aat.h"

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

when defined(harfbuzzyStatic):
  {.pragma: hbDynlib, header: hbHeader.}
  {.pragma: hbAatDynlib, header: hbAatHeader.}
  {.pragma: hbSubsetDynlib, header: hbSubsetHeader.}
else:
  {.pragma: hbDynlib, dynlib: hbLib.}
  {.pragma: hbAatDynlib, dynlib: hbLib.}
  {.pragma: hbSubsetDynlib, dynlib: hbSubsetLib.}

type
  HbBool* = cint
  HbCodepoint* = uint32
  HbPosition* = int32
  HbMask* = uint32
  HbTag* = uint32
  HbScript* = HbTag
  HbColor* = uint32
  HbLanguage* = pointer

  HbDirection* = distinct cuint
  HbMemoryMode* = distinct cuint
  HbGlyphFlags* = distinct cuint
  HbBufferContentType* = distinct cuint
  HbBufferFlags* = distinct cuint
  HbBufferClusterLevel* = distinct cuint
  HbBufferSerializeFlags* = distinct cuint
  HbBufferSerializeFormat* = distinct uint32
  HbSubsetSets* = distinct cuint
  HbSubsetFlags* = distinct cuint

  HbVarInt* {.bycopy, union.} = object
    u32*: uint32
    i32*: int32
    u16*: array[2, uint16]
    i16*: array[2, int16]
    u8*: array[4, uint8]
    i8*: array[4, int8]

  HbVarNum* {.bycopy, union.} = object
    f*: cfloat
    u32*: uint32
    i32*: int32
    u16*: array[2, uint16]
    i16*: array[2, int16]
    u8*: array[4, uint8]
    i8*: array[4, int8]

  HbFeature* {.bycopy.} = object
    tag*: HbTag
    value*: uint32
    start*: cuint
    ending* {.importc: "end".}: cuint

  HbVariation* {.bycopy.} = object
    tag*: HbTag
    value*: cfloat

  HbGlyphExtents* {.bycopy.} = object
    xBearing* {.importc: "x_bearing".}: HbPosition
    yBearing* {.importc: "y_bearing".}: HbPosition
    width*: HbPosition
    height*: HbPosition

  HbFontExtents* {.bycopy.} = object
    ascender*: HbPosition
    descender*: HbPosition
    lineGap* {.importc: "line_gap".}: HbPosition
    reserved9*: HbPosition
    reserved8*: HbPosition
    reserved7*: HbPosition
    reserved6*: HbPosition
    reserved5*: HbPosition
    reserved4*: HbPosition
    reserved3*: HbPosition
    reserved2*: HbPosition
    reserved1*: HbPosition

  HbGlyphInfo* {.bycopy.} = object
    codepoint*: HbCodepoint
    mask*: HbMask
    cluster*: uint32
    var1*: HbVarInt
    var2*: HbVarInt

  HbGlyphPosition* {.bycopy.} = object
    xAdvance* {.importc: "x_advance".}: HbPosition
    yAdvance* {.importc: "y_advance".}: HbPosition
    xOffset* {.importc: "x_offset".}: HbPosition
    yOffset* {.importc: "y_offset".}: HbPosition
    var1* {.importc: "var".}: HbVarInt

  HbSegmentProperties* {.bycopy.} = object
    direction*: HbDirection
    script*: HbScript
    language*: HbLanguage
    reserved1*: pointer
    reserved2*: pointer

  HbUserDataKey* {.bycopy.} = object
    unused*: cchar

  HbDestroyFunc* = proc(userData: pointer) {.cdecl.}

  HbBlobObj* {.importc: "hb_blob_t", header: hbHeader, incompleteStruct.} = object
  HbFaceObj* {.importc: "hb_face_t", header: hbHeader, incompleteStruct.} = object
  HbFontObj* {.importc: "hb_font_t", header: hbHeader, incompleteStruct.} = object

  HbFontFuncsObj* {.importc: "hb_font_funcs_t", header: hbHeader, incompleteStruct.} = object
  HbBufferObj* {.importc: "hb_buffer_t", header: hbHeader, incompleteStruct.} = object

  HbShapePlanObj* {.importc: "hb_shape_plan_t", header: hbHeader, incompleteStruct.} = object
  HbSetObj* {.importc: "hb_set_t", header: hbHeader, incompleteStruct.} = object
  HbMapObj* {.importc: "hb_map_t", header: hbHeader, incompleteStruct.} = object

  HbUnicodeFuncsObj* {.
    importc: "hb_unicode_funcs_t", header: hbHeader, incompleteStruct
  .} = object

  HbSubsetInputObj* {.
    importc: "hb_subset_input_t", header: hbSubsetHeader, incompleteStruct
  .} = object

  HbSubsetPlanObj* {.
    importc: "hb_subset_plan_t", header: hbSubsetHeader, incompleteStruct
  .} = object

  HbBlob* = ptr HbBlobObj
  HbFace* = ptr HbFaceObj
  HbFont* = ptr HbFontObj
  HbFontFuncs* = ptr HbFontFuncsObj
  HbBuffer* = ptr HbBufferObj
  HbShapePlan* = ptr HbShapePlanObj
  HbSet* = ptr HbSetObj
  HbMap* = ptr HbMapObj
  HbUnicodeFuncs* = ptr HbUnicodeFuncsObj
  HbSubsetInput* = ptr HbSubsetInputObj
  HbSubsetPlan* = ptr HbSubsetPlanObj

func hbTag*(c1, c2, c3, c4: char): HbTag =
  (uint32(ord(c1)) shl 24) or (uint32(ord(c2)) shl 16) or (uint32(ord(c3)) shl 8) or
    uint32(ord(c4))

const
  HB_VERSION_MAJOR* = 14
  HB_VERSION_MINOR* = 2
  HB_VERSION_MICRO* = 0
  HB_VERSION_STRING* = "14.2.0"

  HB_CODEPOINT_INVALID* = HbCodepoint.high

  HB_TAG_NONE* = HbTag(0)
  HB_TAG_MAX* = HbTag(uint32.high)
  HB_TAG_MAX_SIGNED* = hbTag(char(0x7f), char(0xff), char(0xff), char(0xff))

  HB_DIRECTION_INVALID* = HbDirection(0)
  HB_DIRECTION_LTR* = HbDirection(4)
  HB_DIRECTION_RTL* = HbDirection(5)
  HB_DIRECTION_TTB* = HbDirection(6)
  HB_DIRECTION_BTT* = HbDirection(7)

  HB_LANGUAGE_INVALID* = HbLanguage(nil)

  HB_SCRIPT_COMMON* = hbTag('Z', 'y', 'y', 'y')
  HB_SCRIPT_INHERITED* = hbTag('Z', 'i', 'n', 'h')
  HB_SCRIPT_UNKNOWN* = hbTag('Z', 'z', 'z', 'z')
  HB_SCRIPT_ARABIC* = hbTag('A', 'r', 'a', 'b')
  HB_SCRIPT_LATIN* = hbTag('L', 'a', 't', 'n')
  HB_SCRIPT_INVALID* = HB_TAG_NONE

  HB_FEATURE_GLOBAL_START* = cuint(0)
  HB_FEATURE_GLOBAL_END* = cuint.high

  HB_MEMORY_MODE_DUPLICATE* = HbMemoryMode(0)
  HB_MEMORY_MODE_READONLY* = HbMemoryMode(1)
  HB_MEMORY_MODE_WRITABLE* = HbMemoryMode(2)
  HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE* = HbMemoryMode(3)

  HB_GLYPH_FLAG_UNSAFE_TO_BREAK* = HbGlyphFlags(0x00000001)
  HB_GLYPH_FLAG_UNSAFE_TO_CONCAT* = HbGlyphFlags(0x00000002)
  HB_GLYPH_FLAG_SAFE_TO_INSERT_TATWEEL* = HbGlyphFlags(0x00000004)
  HB_GLYPH_FLAG_DEFINED* = HbGlyphFlags(0x00000007)

  HB_BUFFER_CONTENT_TYPE_INVALID* = HbBufferContentType(0)
  HB_BUFFER_CONTENT_TYPE_UNICODE* = HbBufferContentType(1)
  HB_BUFFER_CONTENT_TYPE_GLYPHS* = HbBufferContentType(2)

  HB_BUFFER_FLAG_DEFAULT* = HbBufferFlags(0x00000000)
  HB_BUFFER_FLAG_BOT* = HbBufferFlags(0x00000001)
  HB_BUFFER_FLAG_EOT* = HbBufferFlags(0x00000002)
  HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES* = HbBufferFlags(0x00000004)
  HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES* = HbBufferFlags(0x00000008)
  HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE* = HbBufferFlags(0x00000010)
  HB_BUFFER_FLAG_VERIFY* = HbBufferFlags(0x00000020)
  HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT* = HbBufferFlags(0x00000040)
  HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL* = HbBufferFlags(0x00000080)
  HB_BUFFER_FLAG_DEFINED* = HbBufferFlags(0x000000ff)

  HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES* = HbBufferClusterLevel(0)
  HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS* = HbBufferClusterLevel(1)
  HB_BUFFER_CLUSTER_LEVEL_CHARACTERS* = HbBufferClusterLevel(2)
  HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES* = HbBufferClusterLevel(3)
  HB_BUFFER_CLUSTER_LEVEL_DEFAULT* = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES

  HB_BUFFER_SERIALIZE_FLAG_DEFAULT* = HbBufferSerializeFlags(0x00000000)
  HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS* = HbBufferSerializeFlags(0x00000001)
  HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS* = HbBufferSerializeFlags(0x00000002)
  HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES* = HbBufferSerializeFlags(0x00000004)
  HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS* = HbBufferSerializeFlags(0x00000008)
  HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS* = HbBufferSerializeFlags(0x00000010)
  HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES* = HbBufferSerializeFlags(0x00000020)
  HB_BUFFER_SERIALIZE_FLAG_DEFINED* = HbBufferSerializeFlags(0x0000003f)

  HB_BUFFER_SERIALIZE_FORMAT_TEXT* = HbBufferSerializeFormat(hbTag('T', 'E', 'X', 'T'))
  HB_BUFFER_SERIALIZE_FORMAT_JSON* = HbBufferSerializeFormat(hbTag('J', 'S', 'O', 'N'))
  HB_BUFFER_SERIALIZE_FORMAT_INVALID* = HbBufferSerializeFormat(HB_TAG_NONE)

  HB_OT_TAG_GSUB* = hbTag('G', 'S', 'U', 'B')
  HB_OT_TAG_GPOS* = hbTag('G', 'P', 'O', 'S')
  HB_OT_LAYOUT_NO_FEATURE_INDEX* = cuint(0xffff)
  HB_OT_LAYOUT_DEFAULT_LANGUAGE_INDEX* = cuint(0xffff)

  HB_SET_VALUE_INVALID* = HB_CODEPOINT_INVALID

  HB_SUBSET_SETS_GLYPH_INDEX* = HbSubsetSets(0)
  HB_SUBSET_SETS_UNICODE* = HbSubsetSets(1)
  HB_SUBSET_SETS_NO_SUBSET_TABLE_TAG* = HbSubsetSets(2)
  HB_SUBSET_SETS_DROP_TABLE_TAG* = HbSubsetSets(3)
  HB_SUBSET_SETS_NAME_ID* = HbSubsetSets(4)
  HB_SUBSET_SETS_NAME_LANG_ID* = HbSubsetSets(5)
  HB_SUBSET_SETS_LAYOUT_FEATURE_TAG* = HbSubsetSets(6)
  HB_SUBSET_SETS_LAYOUT_SCRIPT_TAG* = HbSubsetSets(7)

func hb_direction_is_valid*(dir: HbDirection): bool =
  (cuint(dir) and not 3'u32) == 4'u32

func hb_direction_is_horizontal*(dir: HbDirection): bool =
  (cuint(dir) and not 1'u32) == 4'u32

func hb_direction_is_vertical*(dir: HbDirection): bool =
  (cuint(dir) and not 1'u32) == 6'u32

func hb_direction_reverse*(dir: HbDirection): HbDirection =
  HbDirection(cuint(dir) xor 1'u32)

func `or`*(a, b: HbBufferFlags): HbBufferFlags =
  HbBufferFlags(cuint(a) or cuint(b))

func `and`*(a, b: HbBufferFlags): HbBufferFlags =
  HbBufferFlags(cuint(a) and cuint(b))

func contains*(flags, flag: HbBufferFlags): bool =
  (cuint(flags) and cuint(flag)) != 0

func `or`*(a, b: HbBufferSerializeFlags): HbBufferSerializeFlags =
  HbBufferSerializeFlags(cuint(a) or cuint(b))

proc hb_version*(
  major, minor, micro: ptr cint
) {.cdecl, importc: "hb_version", hbDynlib.}

proc hb_version_string*(): cstring {.cdecl, importc: "hb_version_string", hbDynlib.}

proc hb_version_atleast*(
  major, minor, micro: cint
): HbBool {.cdecl, importc: "hb_version_atleast", hbDynlib.}

proc hb_tag_from_string*(
  str: cstring, len: cint
): HbTag {.cdecl, importc: "hb_tag_from_string", hbDynlib.}

proc hb_tag_to_string*(
  tag: HbTag, buf: cstring
) {.cdecl, importc: "hb_tag_to_string", hbDynlib.}

proc hb_direction_from_string*(
  str: cstring, len: cint
): HbDirection {.cdecl, importc: "hb_direction_from_string", hbDynlib.}

proc hb_direction_to_string*(
  direction: HbDirection
): cstring {.cdecl, importc: "hb_direction_to_string", hbDynlib.}

proc hb_language_from_string*(
  str: cstring, len: cint
): HbLanguage {.cdecl, importc: "hb_language_from_string", hbDynlib.}

proc hb_language_to_string*(
  language: HbLanguage
): cstring {.cdecl, importc: "hb_language_to_string", hbDynlib.}

proc hb_language_get_default*(): HbLanguage {.
  cdecl, importc: "hb_language_get_default", hbDynlib
.}

proc hb_language_matches*(
  language, specific: HbLanguage
): HbBool {.cdecl, importc: "hb_language_matches", hbDynlib.}

proc hb_script_from_iso15924_tag*(
  tag: HbTag
): HbScript {.cdecl, importc: "hb_script_from_iso15924_tag", hbDynlib.}

proc hb_script_from_string*(
  str: cstring, len: cint
): HbScript {.cdecl, importc: "hb_script_from_string", hbDynlib.}

proc hb_script_to_iso15924_tag*(
  script: HbScript
): HbTag {.cdecl, importc: "hb_script_to_iso15924_tag", hbDynlib.}

proc hb_script_get_horizontal_direction*(
  script: HbScript
): HbDirection {.cdecl, importc: "hb_script_get_horizontal_direction", hbDynlib.}

proc hb_unicode_funcs_get_default*(): HbUnicodeFuncs {.
  cdecl, importc: "hb_unicode_funcs_get_default", hbDynlib
.}

proc hb_unicode_script*(
  ufuncs: HbUnicodeFuncs, unicode: HbCodepoint
): HbScript {.cdecl, importc: "hb_unicode_script", hbDynlib.}

proc hb_feature_from_string*(
  str: cstring, len: cint, feature: ptr HbFeature
): HbBool {.cdecl, importc: "hb_feature_from_string", hbDynlib.}

proc hb_feature_to_string*(
  feature: ptr HbFeature, buf: cstring, size: cuint
) {.cdecl, importc: "hb_feature_to_string", hbDynlib.}

proc hb_blob_create*(
  data: cstring,
  length: cuint,
  mode: HbMemoryMode,
  userData: pointer,
  destroy: HbDestroyFunc,
): HbBlob {.cdecl, importc: "hb_blob_create", hbDynlib.}

proc hb_blob_create_or_fail*(
  data: cstring,
  length: cuint,
  mode: HbMemoryMode,
  userData: pointer,
  destroy: HbDestroyFunc,
): HbBlob {.cdecl, importc: "hb_blob_create_or_fail", hbDynlib.}

proc hb_blob_create_from_file*(
  fileName: cstring
): HbBlob {.cdecl, importc: "hb_blob_create_from_file", hbDynlib.}

proc hb_blob_create_from_file_or_fail*(
  fileName: cstring
): HbBlob {.cdecl, importc: "hb_blob_create_from_file_or_fail", hbDynlib.}

proc hb_blob_create_sub_blob*(
  parent: HbBlob, offset, length: cuint
): HbBlob {.cdecl, importc: "hb_blob_create_sub_blob", hbDynlib.}

proc hb_blob_get_empty*(): HbBlob {.cdecl, importc: "hb_blob_get_empty", hbDynlib.}
proc hb_blob_reference*(
  blob: HbBlob
): HbBlob {.cdecl, importc: "hb_blob_reference", hbDynlib.}

proc hb_blob_destroy*(blob: HbBlob) {.cdecl, importc: "hb_blob_destroy", hbDynlib.}
proc hb_blob_get_length*(
  blob: HbBlob
): cuint {.cdecl, importc: "hb_blob_get_length", hbDynlib.}

proc hb_blob_get_data*(
  blob: HbBlob, length: ptr cuint
): cstring {.cdecl, importc: "hb_blob_get_data", hbDynlib.}

proc hb_blob_make_immutable*(
  blob: HbBlob
) {.cdecl, importc: "hb_blob_make_immutable", hbDynlib.}

proc hb_blob_is_immutable*(
  blob: HbBlob
): HbBool {.cdecl, importc: "hb_blob_is_immutable", hbDynlib.}

proc hb_face_count*(blob: HbBlob): cuint {.cdecl, importc: "hb_face_count", hbDynlib.}

proc hb_face_create*(
  blob: HbBlob, index: cuint
): HbFace {.cdecl, importc: "hb_face_create", hbDynlib.}

proc hb_face_create_or_fail*(
  blob: HbBlob, index: cuint
): HbFace {.cdecl, importc: "hb_face_create_or_fail", hbDynlib.}

proc hb_face_create_from_file_or_fail*(
  fileName: cstring, index: cuint
): HbFace {.cdecl, importc: "hb_face_create_from_file_or_fail", hbDynlib.}

proc hb_face_get_empty*(): HbFace {.cdecl, importc: "hb_face_get_empty", hbDynlib.}
proc hb_face_reference*(
  face: HbFace
): HbFace {.cdecl, importc: "hb_face_reference", hbDynlib.}

proc hb_face_destroy*(face: HbFace) {.cdecl, importc: "hb_face_destroy", hbDynlib.}
proc hb_face_reference_table*(
  face: HbFace, tag: HbTag
): HbBlob {.cdecl, importc: "hb_face_reference_table", hbDynlib.}

proc hb_face_reference_blob*(
  face: HbFace
): HbBlob {.cdecl, importc: "hb_face_reference_blob", hbDynlib.}

proc hb_face_get_index*(
  face: HbFace
): cuint {.cdecl, importc: "hb_face_get_index", hbDynlib.}

proc hb_face_get_upem*(
  face: HbFace
): cuint {.cdecl, importc: "hb_face_get_upem", hbDynlib.}

proc hb_face_get_glyph_count*(
  face: HbFace
): cuint {.cdecl, importc: "hb_face_get_glyph_count", hbDynlib.}

proc hb_font_create*(
  face: HbFace
): HbFont {.cdecl, importc: "hb_font_create", hbDynlib.}

proc hb_font_get_empty*(): HbFont {.cdecl, importc: "hb_font_get_empty", hbDynlib.}
proc hb_font_reference*(
  font: HbFont
): HbFont {.cdecl, importc: "hb_font_reference", hbDynlib.}

proc hb_font_destroy*(font: HbFont) {.cdecl, importc: "hb_font_destroy", hbDynlib.}
proc hb_font_get_face*(
  font: HbFont
): HbFace {.cdecl, importc: "hb_font_get_face", hbDynlib.}

proc hb_font_set_scale*(
  font: HbFont, xScale, yScale: cint
) {.cdecl, importc: "hb_font_set_scale", hbDynlib.}

proc hb_font_get_scale*(
  font: HbFont, xScale, yScale: ptr cint
) {.cdecl, importc: "hb_font_get_scale", hbDynlib.}

proc hb_font_set_ppem*(
  font: HbFont, xPpem, yPpem: cuint
) {.cdecl, importc: "hb_font_set_ppem", hbDynlib.}

proc hb_font_get_ppem*(
  font: HbFont, xPpem, yPpem: ptr cuint
) {.cdecl, importc: "hb_font_get_ppem", hbDynlib.}

proc hb_font_set_variations*(
  font: HbFont, variations: ptr HbVariation, variationsLength: cuint
) {.cdecl, importc: "hb_font_set_variations", hbDynlib.}

proc hb_font_get_h_extents*(
  font: HbFont, extents: ptr HbFontExtents
): HbBool {.cdecl, importc: "hb_font_get_h_extents", hbDynlib.}

proc hb_font_get_v_extents*(
  font: HbFont, extents: ptr HbFontExtents
): HbBool {.cdecl, importc: "hb_font_get_v_extents", hbDynlib.}

proc hb_font_get_nominal_glyph*(
  font: HbFont, unicode: HbCodepoint, glyph: ptr HbCodepoint
): HbBool {.cdecl, importc: "hb_font_get_nominal_glyph", hbDynlib.}

proc hb_font_get_glyph*(
  font: HbFont, unicode, variationSelector: HbCodepoint, glyph: ptr HbCodepoint
): HbBool {.cdecl, importc: "hb_font_get_glyph", hbDynlib.}

proc hb_font_get_glyph_h_advance*(
  font: HbFont, glyph: HbCodepoint
): HbPosition {.cdecl, importc: "hb_font_get_glyph_h_advance", hbDynlib.}

proc hb_font_get_glyph_v_advance*(
  font: HbFont, glyph: HbCodepoint
): HbPosition {.cdecl, importc: "hb_font_get_glyph_v_advance", hbDynlib.}

proc hb_font_get_extents_for_direction*(
  font: HbFont, direction: HbDirection, extents: ptr HbFontExtents
) {.cdecl, importc: "hb_font_get_extents_for_direction", hbDynlib.}

proc hb_font_get_glyph_advance_for_direction*(
  font: HbFont, glyph: HbCodepoint, direction: HbDirection, x, y: ptr HbPosition
) {.cdecl, importc: "hb_font_get_glyph_advance_for_direction", hbDynlib.}

proc hb_font_get_glyph_extents*(
  font: HbFont, glyph: HbCodepoint, extents: ptr HbGlyphExtents
): HbBool {.cdecl, importc: "hb_font_get_glyph_extents", hbDynlib.}

proc hb_ot_font_set_funcs*(
  font: HbFont
) {.cdecl, importc: "hb_ot_font_set_funcs", hbDynlib.}

proc hb_aat_layout_has_substitution*(
  face: HbFace
): HbBool {.cdecl, importc: "hb_aat_layout_has_substitution", hbAatDynlib.}

proc hb_aat_layout_has_positioning*(
  face: HbFace
): HbBool {.cdecl, importc: "hb_aat_layout_has_positioning", hbAatDynlib.}

proc hb_aat_layout_has_tracking*(
  face: HbFace
): HbBool {.cdecl, importc: "hb_aat_layout_has_tracking", hbAatDynlib.}

proc hb_ot_layout_has_substitution*(
  face: HbFace
): HbBool {.cdecl, importc: "hb_ot_layout_has_substitution", hbDynlib.}

proc hb_ot_layout_has_positioning*(
  face: HbFace
): HbBool {.cdecl, importc: "hb_ot_layout_has_positioning", hbDynlib.}

proc hb_ot_layout_table_get_feature_tags*(
  face: HbFace,
  tableTag: HbTag,
  startOffset: cuint,
  featureCount: ptr cuint,
  featureTags: ptr HbTag,
): cuint {.cdecl, importc: "hb_ot_layout_table_get_feature_tags", hbDynlib.}

proc hb_ot_layout_table_find_script*(
  face: HbFace, tableTag, scriptTag: HbTag, scriptIndex: ptr cuint
): HbBool {.cdecl, importc: "hb_ot_layout_table_find_script", hbDynlib.}

proc hb_ot_layout_script_select_language2*(
  face: HbFace,
  tableTag: HbTag,
  scriptIndex: cuint,
  languageCount: cuint,
  languageTags: ptr HbTag,
  languageIndex: ptr cuint,
  chosenLanguage: ptr HbTag,
): HbBool {.cdecl, importc: "hb_ot_layout_script_select_language2", hbDynlib.}

proc hb_ot_layout_language_get_feature_tags*(
  face: HbFace,
  tableTag: HbTag,
  scriptIndex: cuint,
  languageIndex: cuint,
  startOffset: cuint,
  featureCount: ptr cuint,
  featureTags: ptr HbTag,
): cuint {.cdecl, importc: "hb_ot_layout_language_get_feature_tags", hbDynlib.}

proc hb_buffer_create*(): HbBuffer {.cdecl, importc: "hb_buffer_create", hbDynlib.}
proc hb_buffer_create_similar*(
  src: HbBuffer
): HbBuffer {.cdecl, importc: "hb_buffer_create_similar", hbDynlib.}

proc hb_buffer_get_empty*(): HbBuffer {.
  cdecl, importc: "hb_buffer_get_empty", hbDynlib
.}

proc hb_buffer_reference*(
  buffer: HbBuffer
): HbBuffer {.cdecl, importc: "hb_buffer_reference", hbDynlib.}

proc hb_buffer_destroy*(
  buffer: HbBuffer
) {.cdecl, importc: "hb_buffer_destroy", hbDynlib.}

proc hb_buffer_reset*(buffer: HbBuffer) {.cdecl, importc: "hb_buffer_reset", hbDynlib.}

proc hb_buffer_clear_contents*(
  buffer: HbBuffer
) {.cdecl, importc: "hb_buffer_clear_contents", hbDynlib.}

proc hb_buffer_set_content_type*(
  buffer: HbBuffer, contentType: HbBufferContentType
) {.cdecl, importc: "hb_buffer_set_content_type", hbDynlib.}

proc hb_buffer_get_content_type*(
  buffer: HbBuffer
): HbBufferContentType {.cdecl, importc: "hb_buffer_get_content_type", hbDynlib.}

proc hb_buffer_set_direction*(
  buffer: HbBuffer, direction: HbDirection
) {.cdecl, importc: "hb_buffer_set_direction", hbDynlib.}

proc hb_buffer_get_direction*(
  buffer: HbBuffer
): HbDirection {.cdecl, importc: "hb_buffer_get_direction", hbDynlib.}

proc hb_buffer_set_script*(
  buffer: HbBuffer, script: HbScript
) {.cdecl, importc: "hb_buffer_set_script", hbDynlib.}

proc hb_buffer_get_script*(
  buffer: HbBuffer
): HbScript {.cdecl, importc: "hb_buffer_get_script", hbDynlib.}

proc hb_buffer_set_language*(
  buffer: HbBuffer, language: HbLanguage
) {.cdecl, importc: "hb_buffer_set_language", hbDynlib.}

proc hb_buffer_get_language*(
  buffer: HbBuffer
): HbLanguage {.cdecl, importc: "hb_buffer_get_language", hbDynlib.}

proc hb_buffer_set_segment_properties*(
  buffer: HbBuffer, props: ptr HbSegmentProperties
) {.cdecl, importc: "hb_buffer_set_segment_properties", hbDynlib.}

proc hb_buffer_get_segment_properties*(
  buffer: HbBuffer, props: ptr HbSegmentProperties
) {.cdecl, importc: "hb_buffer_get_segment_properties", hbDynlib.}

proc hb_buffer_guess_segment_properties*(
  buffer: HbBuffer
) {.cdecl, importc: "hb_buffer_guess_segment_properties", hbDynlib.}

proc hb_buffer_set_flags*(
  buffer: HbBuffer, flags: HbBufferFlags
) {.cdecl, importc: "hb_buffer_set_flags", hbDynlib.}

proc hb_buffer_get_flags*(
  buffer: HbBuffer
): HbBufferFlags {.cdecl, importc: "hb_buffer_get_flags", hbDynlib.}

proc hb_buffer_set_cluster_level*(
  buffer: HbBuffer, level: HbBufferClusterLevel
) {.cdecl, importc: "hb_buffer_set_cluster_level", hbDynlib.}

proc hb_buffer_get_cluster_level*(
  buffer: HbBuffer
): HbBufferClusterLevel {.cdecl, importc: "hb_buffer_get_cluster_level", hbDynlib.}

proc hb_buffer_add*(
  buffer: HbBuffer, codepoint: HbCodepoint, cluster: cuint
) {.cdecl, importc: "hb_buffer_add", hbDynlib.}

proc hb_buffer_add_utf8*(
  buffer: HbBuffer, text: cstring, textLength: cint, itemOffset: cuint, itemLength: cint
) {.cdecl, importc: "hb_buffer_add_utf8", hbDynlib.}

proc hb_buffer_add_utf32*(
  buffer: HbBuffer,
  text: ptr uint32,
  textLength: cint,
  itemOffset: cuint,
  itemLength: cint,
) {.cdecl, importc: "hb_buffer_add_utf32", hbDynlib.}

proc hb_buffer_add_codepoints*(
  buffer: HbBuffer,
  text: ptr HbCodepoint,
  textLength: cint,
  itemOffset: cuint,
  itemLength: cint,
) {.cdecl, importc: "hb_buffer_add_codepoints", hbDynlib.}

proc hb_buffer_set_length*(
  buffer: HbBuffer, length: cuint
): HbBool {.cdecl, importc: "hb_buffer_set_length", hbDynlib.}

proc hb_buffer_get_length*(
  buffer: HbBuffer
): cuint {.cdecl, importc: "hb_buffer_get_length", hbDynlib.}

proc hb_buffer_get_glyph_infos*(
  buffer: HbBuffer, length: ptr cuint
): ptr UncheckedArray[HbGlyphInfo] {.
  cdecl, importc: "hb_buffer_get_glyph_infos", hbDynlib
.}

proc hb_buffer_get_glyph_positions*(
  buffer: HbBuffer, length: ptr cuint
): ptr UncheckedArray[HbGlyphPosition] {.
  cdecl, importc: "hb_buffer_get_glyph_positions", hbDynlib
.}

proc hb_buffer_has_positions*(
  buffer: HbBuffer
): HbBool {.cdecl, importc: "hb_buffer_has_positions", hbDynlib.}

proc hb_buffer_serialize_format_from_string*(
  str: cstring, len: cint
): HbBufferSerializeFormat {.
  cdecl, importc: "hb_buffer_serialize_format_from_string", hbDynlib
.}

proc hb_buffer_serialize_format_to_string*(
  format: HbBufferSerializeFormat
): cstring {.cdecl, importc: "hb_buffer_serialize_format_to_string", hbDynlib.}

proc hb_buffer_serialize_list_formats*(): cstringArray {.
  cdecl, importc: "hb_buffer_serialize_list_formats", hbDynlib
.}

proc hb_buffer_serialize_glyphs*(
  buffer: HbBuffer,
  start, ending: cuint,
  buf: cstring,
  bufSize: cuint,
  bufConsumed: ptr cuint,
  font: HbFont,
  format: HbBufferSerializeFormat,
  flags: HbBufferSerializeFlags,
): cuint {.cdecl, importc: "hb_buffer_serialize_glyphs", hbDynlib.}

proc hb_shape*(
  font: HbFont, buffer: HbBuffer, features: ptr HbFeature, numFeatures: cuint
) {.cdecl, importc: "hb_shape", hbDynlib.}

proc hb_shape_full*(
  font: HbFont,
  buffer: HbBuffer,
  features: ptr HbFeature,
  numFeatures: cuint,
  shaperList: cstringArray,
): HbBool {.cdecl, importc: "hb_shape_full", hbDynlib.}

proc hb_shape_list_shapers*(): cstringArray {.
  cdecl, importc: "hb_shape_list_shapers", hbDynlib
.}

proc hb_shape_plan_create*(
  face: HbFace,
  props: ptr HbSegmentProperties,
  userFeatures: ptr HbFeature,
  numUserFeatures: cuint,
  shaperList: cstringArray,
): HbShapePlan {.cdecl, importc: "hb_shape_plan_create", hbDynlib.}

proc hb_shape_plan_create_cached*(
  face: HbFace,
  props: ptr HbSegmentProperties,
  userFeatures: ptr HbFeature,
  numUserFeatures: cuint,
  shaperList: cstringArray,
): HbShapePlan {.cdecl, importc: "hb_shape_plan_create_cached", hbDynlib.}

proc hb_shape_plan_reference*(
  shapePlan: HbShapePlan
): HbShapePlan {.cdecl, importc: "hb_shape_plan_reference", hbDynlib.}

proc hb_shape_plan_destroy*(
  shapePlan: HbShapePlan
) {.cdecl, importc: "hb_shape_plan_destroy", hbDynlib.}

proc hb_shape_plan_execute*(
  shapePlan: HbShapePlan,
  font: HbFont,
  buffer: HbBuffer,
  features: ptr HbFeature,
  numFeatures: cuint,
): HbBool {.cdecl, importc: "hb_shape_plan_execute", hbDynlib.}

proc hb_shape_plan_get_shaper*(
  shapePlan: HbShapePlan
): cstring {.cdecl, importc: "hb_shape_plan_get_shaper", hbDynlib.}

proc hb_set_create*(): HbSet {.cdecl, importc: "hb_set_create", hbDynlib.}
proc hb_set_get_empty*(): HbSet {.cdecl, importc: "hb_set_get_empty", hbDynlib.}
proc hb_set_reference*(
  set: HbSet
): HbSet {.cdecl, importc: "hb_set_reference", hbDynlib.}

proc hb_set_destroy*(set: HbSet) {.cdecl, importc: "hb_set_destroy", hbDynlib.}
proc hb_set_copy*(set: HbSet): HbSet {.cdecl, importc: "hb_set_copy", hbDynlib.}
proc hb_set_clear*(set: HbSet) {.cdecl, importc: "hb_set_clear", hbDynlib.}
proc hb_set_is_empty*(
  set: HbSet
): HbBool {.cdecl, importc: "hb_set_is_empty", hbDynlib.}

proc hb_set_has*(
  set: HbSet, codepoint: HbCodepoint
): HbBool {.cdecl, importc: "hb_set_has", hbDynlib.}

proc hb_set_add*(
  set: HbSet, codepoint: HbCodepoint
) {.cdecl, importc: "hb_set_add", hbDynlib.}

proc hb_set_add_range*(
  set: HbSet, first, last: HbCodepoint
) {.cdecl, importc: "hb_set_add_range", hbDynlib.}

proc hb_set_del*(
  set: HbSet, codepoint: HbCodepoint
) {.cdecl, importc: "hb_set_del", hbDynlib.}

proc hb_set_get_population*(
  set: HbSet
): cuint {.cdecl, importc: "hb_set_get_population", hbDynlib.}

proc hb_set_get_min*(
  set: HbSet
): HbCodepoint {.cdecl, importc: "hb_set_get_min", hbDynlib.}

proc hb_set_get_max*(
  set: HbSet
): HbCodepoint {.cdecl, importc: "hb_set_get_max", hbDynlib.}

proc hb_set_next*(
  set: HbSet, codepoint: ptr HbCodepoint
): HbBool {.cdecl, importc: "hb_set_next", hbDynlib.}

proc hb_subset_input_create_or_fail*(): HbSubsetInput {.
  cdecl, importc: "hb_subset_input_create_or_fail", hbSubsetDynlib
.}

proc hb_subset_input_reference*(
  input: HbSubsetInput
): HbSubsetInput {.cdecl, importc: "hb_subset_input_reference", hbSubsetDynlib.}

proc hb_subset_input_destroy*(
  input: HbSubsetInput
) {.cdecl, importc: "hb_subset_input_destroy", hbSubsetDynlib.}

proc hb_subset_input_keep_everything*(
  input: HbSubsetInput
) {.cdecl, importc: "hb_subset_input_keep_everything", hbSubsetDynlib.}

proc hb_subset_input_unicode_set*(
  input: HbSubsetInput
): HbSet {.cdecl, importc: "hb_subset_input_unicode_set", hbSubsetDynlib.}

proc hb_subset_input_glyph_set*(
  input: HbSubsetInput
): HbSet {.cdecl, importc: "hb_subset_input_glyph_set", hbSubsetDynlib.}

proc hb_subset_input_set*(
  input: HbSubsetInput, setType: HbSubsetSets
): HbSet {.cdecl, importc: "hb_subset_input_set", hbSubsetDynlib.}

proc hb_subset_input_set_flags*(
  input: HbSubsetInput, value: cuint
) {.cdecl, importc: "hb_subset_input_set_flags", hbSubsetDynlib.}

proc hb_subset_input_get_flags*(
  input: HbSubsetInput
): HbSubsetFlags {.cdecl, importc: "hb_subset_input_get_flags", hbSubsetDynlib.}

proc hb_subset_input_pin_axis_location*(
  input: HbSubsetInput, face: HbFace, axisTag: HbTag, axisValue: cfloat
): HbBool {.cdecl, importc: "hb_subset_input_pin_axis_location", hbSubsetDynlib.}

proc hb_subset_preprocess*(
  source: HbFace
): HbFace {.cdecl, importc: "hb_subset_preprocess", hbSubsetDynlib.}

proc hb_subset_or_fail*(
  source: HbFace, input: HbSubsetInput
): HbFace {.cdecl, importc: "hb_subset_or_fail", hbSubsetDynlib.}

proc hb_subset_plan_create_or_fail*(
  face: HbFace, input: HbSubsetInput
): HbSubsetPlan {.cdecl, importc: "hb_subset_plan_create_or_fail", hbSubsetDynlib.}

proc hb_subset_plan_reference*(
  plan: HbSubsetPlan
): HbSubsetPlan {.cdecl, importc: "hb_subset_plan_reference", hbSubsetDynlib.}

proc hb_subset_plan_destroy*(
  plan: HbSubsetPlan
) {.cdecl, importc: "hb_subset_plan_destroy", hbSubsetDynlib.}

proc hb_subset_plan_execute_or_fail*(
  plan: HbSubsetPlan
): HbFace {.cdecl, importc: "hb_subset_plan_execute_or_fail", hbSubsetDynlib.}
