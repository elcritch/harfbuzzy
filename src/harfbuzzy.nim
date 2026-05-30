## Ergonomic HarfBuzz wrapper built on top of `harfbuzzy/raw`.

import harfbuzzy/raw

type
  Blob* = object
    handle: raw.HbBlob

  Face* = object
    handle: raw.HbFace

  Font* = object
    handle: raw.HbFont

  Buffer* = object
    handle: raw.HbBuffer

  Set* = object
    handle: raw.HbSet

  SubsetInput* = object
    handle: raw.HbSubsetInput

  SubsetPlan* = object
    handle: raw.HbSubsetPlan

template destroyHandle(handle, destroyProc: untyped) =
  if handle != nil:
    destroyProc(handle)

template copyHandle(dest, src, referenceProc, destroyProc: untyped) =
  if dest == src:
    return
  if src != nil:
    discard referenceProc(src)
  destroyHandle(dest, destroyProc)
  dest = src

template dupHandle(src, referenceProc: untyped): untyped =
  result.handle = src.handle
  if result.handle != nil:
    discard referenceProc(result.handle)

proc `=destroy`(x: Blob) =
  destroyHandle(x.handle, raw.hb_blob_destroy)

proc `=wasMoved`(x: var Blob) =
  x.handle = nil

proc `=copy`(dest: var Blob, src: Blob) =
  copyHandle(dest.handle, src.handle, raw.hb_blob_reference, raw.hb_blob_destroy)

proc `=dup`(src: Blob): Blob =
  dupHandle(src, raw.hb_blob_reference)

proc `=destroy`(x: Face) =
  destroyHandle(x.handle, raw.hb_face_destroy)

proc `=wasMoved`(x: var Face) =
  x.handle = nil

proc `=copy`(dest: var Face, src: Face) =
  copyHandle(dest.handle, src.handle, raw.hb_face_reference, raw.hb_face_destroy)

proc `=dup`(src: Face): Face =
  dupHandle(src, raw.hb_face_reference)

proc `=destroy`(x: Font) =
  destroyHandle(x.handle, raw.hb_font_destroy)

proc `=wasMoved`(x: var Font) =
  x.handle = nil

proc `=copy`(dest: var Font, src: Font) =
  copyHandle(dest.handle, src.handle, raw.hb_font_reference, raw.hb_font_destroy)

proc `=dup`(src: Font): Font =
  dupHandle(src, raw.hb_font_reference)

proc `=destroy`(x: Buffer) =
  destroyHandle(x.handle, raw.hb_buffer_destroy)

proc `=wasMoved`(x: var Buffer) =
  x.handle = nil

proc `=copy`(dest: var Buffer, src: Buffer) =
  copyHandle(dest.handle, src.handle, raw.hb_buffer_reference, raw.hb_buffer_destroy)

proc `=dup`(src: Buffer): Buffer =
  dupHandle(src, raw.hb_buffer_reference)

proc `=destroy`(x: Set) =
  destroyHandle(x.handle, raw.hb_set_destroy)

proc `=wasMoved`(x: var Set) =
  x.handle = nil

proc `=copy`(dest: var Set, src: Set) =
  copyHandle(dest.handle, src.handle, raw.hb_set_reference, raw.hb_set_destroy)

proc `=dup`(src: Set): Set =
  dupHandle(src, raw.hb_set_reference)

proc `=destroy`(x: SubsetInput) =
  destroyHandle(x.handle, raw.hb_subset_input_destroy)

proc `=wasMoved`(x: var SubsetInput) =
  x.handle = nil

proc `=copy`(dest: var SubsetInput, src: SubsetInput) =
  copyHandle(
    dest.handle, src.handle, raw.hb_subset_input_reference, raw.hb_subset_input_destroy
  )

proc `=dup`(src: SubsetInput): SubsetInput =
  dupHandle(src, raw.hb_subset_input_reference)

proc `=destroy`(x: SubsetPlan) =
  destroyHandle(x.handle, raw.hb_subset_plan_destroy)

proc `=wasMoved`(x: var SubsetPlan) =
  x.handle = nil

proc `=copy`(dest: var SubsetPlan, src: SubsetPlan) =
  copyHandle(
    dest.handle, src.handle, raw.hb_subset_plan_reference, raw.hb_subset_plan_destroy
  )

proc `=dup`(src: SubsetPlan): SubsetPlan =
  dupHandle(src, raw.hb_subset_plan_reference)

type
  Codepoint* = raw.HbCodepoint
  Position* = raw.HbPosition

  Tag* = distinct raw.HbTag
  Script* = distinct raw.HbScript
  Language* = distinct raw.HbLanguage

  Direction* {.pure.} = enum
    invalid = 0
    ltr = 4
    rtl = 5
    ttb = 6
    btt = 7

  BufferFlag* = enum
    beginningOfText
    endOfText
    preserveDefaultIgnorables
    removeDefaultIgnorables
    doNotInsertDottedCircle
    verify
    produceUnsafeToConcat
    produceSafeToInsertTatweel

  BufferFlags* = set[BufferFlag]

  Feature* = object
    tag*: Tag
    value*: uint32
    start*: uint32
    ending*: uint32

  GlyphInfo* = object
    codepoint*: Codepoint
    cluster*: uint32
    flags*: uint32

  GlyphPosition* = object
    xAdvance*: Position
    yAdvance*: Position
    xOffset*: Position
    yOffset*: Position

  FontExtents* = object
    ascender*: Position
    descender*: Position
    lineGap*: Position

  GlyphExtents* = object
    xBearing*: Position
    yBearing*: Position
    width*: Position
    height*: Position

  Scale* = object
    x*: int
    y*: int

  Ppem* = object
    x*: uint
    y*: uint

  Version* = object
    major*: int
    minor*: int
    micro*: int

const
  versionMajor* = raw.HB_VERSION_MAJOR
  versionMinor* = raw.HB_VERSION_MINOR
  versionMicro* = raw.HB_VERSION_MICRO
  versionHeaderString* = raw.HB_VERSION_STRING
  featureGlobalStart* = uint32(raw.HB_FEATURE_GLOBAL_START)
  featureGlobalEnd* = uint32(raw.HB_FEATURE_GLOBAL_END)
  scriptCommon* = Script(raw.HB_SCRIPT_COMMON)
  scriptInherited* = Script(raw.HB_SCRIPT_INHERITED)
  scriptUnknown* = Script(raw.HB_SCRIPT_UNKNOWN)
  scriptArabic* = Script(raw.HB_SCRIPT_ARABIC)
  scriptLatin* = Script(raw.HB_SCRIPT_LATIN)
  scriptInvalid* = Script(raw.HB_SCRIPT_INVALID)
  languageInvalid* = Language(raw.HB_LANGUAGE_INVALID)

func toRaw(direction: Direction): raw.HbDirection =
  raw.HbDirection(cuint(ord(direction)))

func toDirection(direction: raw.HbDirection): Direction =
  case cuint(direction)
  of cuint(raw.HB_DIRECTION_LTR): Direction.ltr
  of cuint(raw.HB_DIRECTION_RTL): Direction.rtl
  of cuint(raw.HB_DIRECTION_TTB): Direction.ttb
  of cuint(raw.HB_DIRECTION_BTT): Direction.btt
  else: Direction.invalid

func toRaw(flags: BufferFlags): raw.HbBufferFlags =
  result = raw.HB_BUFFER_FLAG_DEFAULT
  if beginningOfText in flags:
    result = result or raw.HB_BUFFER_FLAG_BOT
  if endOfText in flags:
    result = result or raw.HB_BUFFER_FLAG_EOT
  if preserveDefaultIgnorables in flags:
    result = result or raw.HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES
  if removeDefaultIgnorables in flags:
    result = result or raw.HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES
  if doNotInsertDottedCircle in flags:
    result = result or raw.HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE
  if verify in flags:
    result = result or raw.HB_BUFFER_FLAG_VERIFY
  if produceUnsafeToConcat in flags:
    result = result or raw.HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT
  if produceSafeToInsertTatweel in flags:
    result = result or raw.HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL

func toFlags(flags: raw.HbBufferFlags): BufferFlags =
  if flags.contains(raw.HB_BUFFER_FLAG_BOT):
    result.incl beginningOfText
  if flags.contains(raw.HB_BUFFER_FLAG_EOT):
    result.incl endOfText
  if flags.contains(raw.HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES):
    result.incl preserveDefaultIgnorables
  if flags.contains(raw.HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES):
    result.incl removeDefaultIgnorables
  if flags.contains(raw.HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE):
    result.incl doNotInsertDottedCircle
  if flags.contains(raw.HB_BUFFER_FLAG_VERIFY):
    result.incl verify
  if flags.contains(raw.HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT):
    result.incl produceUnsafeToConcat
  if flags.contains(raw.HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL):
    result.incl produceSafeToInsertTatweel

func isNil*(blob: Blob): bool =
  blob.handle == nil
func isNil*(face: Face): bool =
  face.handle == nil
func isNil*(font: Font): bool =
  font.handle == nil
func isNil*(buffer: Buffer): bool =
  buffer.handle == nil
func isNil*(set: Set): bool =
  set.handle == nil
func isNil*(input: SubsetInput): bool =
  input.handle == nil
func isNil*(plan: SubsetPlan): bool =
  plan.handle == nil

proc requireBlob(blob: Blob): raw.HbBlob =
  if blob.handle == nil:
    raise newException(ValueError, "HarfBuzz blob is uninitialized")
  blob.handle

proc requireFace(face: Face): raw.HbFace =
  if face.handle == nil:
    raise newException(ValueError, "HarfBuzz face is uninitialized")
  face.handle

proc requireFont(font: Font): raw.HbFont =
  if font.handle == nil:
    raise newException(ValueError, "HarfBuzz font is uninitialized")
  font.handle

proc requireBuffer(buffer: Buffer): raw.HbBuffer =
  if buffer.handle == nil:
    raise newException(ValueError, "HarfBuzz buffer is uninitialized")
  buffer.handle

proc requireSet(set: Set): raw.HbSet =
  if set.handle == nil:
    raise newException(ValueError, "HarfBuzz set is uninitialized")
  set.handle

proc requireInput(input: SubsetInput): raw.HbSubsetInput =
  if input.handle == nil:
    raise newException(ValueError, "HarfBuzz subset input is uninitialized")
  input.handle

proc requirePlan(plan: SubsetPlan): raw.HbSubsetPlan =
  if plan.handle == nil:
    raise newException(ValueError, "HarfBuzz subset plan is uninitialized")
  plan.handle

proc checkedCuint(value: int, label: string): cuint =
  if value < 0 or uint64(value) > uint64(cuint.high):
    raise newException(ValueError, label & " does not fit unsigned int")
  cuint(value)

proc checkedCint(value: int, label: string): cint =
  if value < int(cint.low) or value > int(cint.high):
    raise newException(ValueError, label & " does not fit int")
  cint(value)

proc boolValue(value: raw.HbBool): bool =
  value != 0

proc fromCString(p: cstring): string =
  if p == nil:
    ""
  else:
    $p

proc versionString*(): string =
  fromCString(raw.hb_version_string())

proc version*(): Version =
  var major, minor, micro: cint
  raw.hb_version(addr major, addr minor, addr micro)
  Version(major: int(major), minor: int(minor), micro: int(micro))

proc versionAtLeast*(major, minor, micro: Natural): bool =
  raw.hb_version_atleast(
    checkedCint(major, "major version"),
    checkedCint(minor, "minor version"),
    checkedCint(micro, "micro version"),
  ).boolValue

proc toTag*(value: string): Tag =
  if value.len == 0 or value.len > 4:
    raise newException(ValueError, "HarfBuzz tags must contain 1 to 4 bytes")
  Tag(raw.hb_tag_from_string(value.cstring, checkedCint(value.len, "tag length")))

proc `$`*(tag: Tag): string =
  var buf: array[4, cchar]
  raw.hb_tag_to_string(raw.HbTag(tag), cast[cstring](addr buf[0]))
  result = newString(4)
  for i in 0 ..< 4:
    result[i] = char(buf[i])

proc toScript*(value: string): Script =
  if value.len == 0:
    raise newException(ValueError, "script string is empty")
  Script(
    raw.hb_script_from_string(value.cstring, checkedCint(value.len, "script length"))
  )

proc scriptToTag*(script: Script): Tag =
  Tag(raw.hb_script_to_iso15924_tag(raw.HbScript(script)))

proc horizontalDirection*(script: Script): Direction =
  raw.hb_script_get_horizontal_direction(raw.HbScript(script)).toDirection

proc `$`*(script: Script): string =
  $script.scriptToTag

proc toLanguage*(value: string): Language =
  if value.len == 0:
    raise newException(ValueError, "language string is empty")
  Language(
    raw.hb_language_from_string(
      value.cstring, checkedCint(value.len, "language length")
    )
  )

proc defaultLanguage*(): Language =
  Language(raw.hb_language_get_default())

proc matches*(language, specific: Language): bool =
  raw.hb_language_matches(raw.HbLanguage(language), raw.HbLanguage(specific)).boolValue

proc `$`*(language: Language): string =
  fromCString(raw.hb_language_to_string(raw.HbLanguage(language)))

proc toDirection*(value: string): Direction =
  if value.len == 0:
    raise newException(ValueError, "direction string is empty")
  let direction = raw.hb_direction_from_string(
    value.cstring, checkedCint(value.len, "direction length")
  )
  if not direction.hb_direction_is_valid:
    raise newException(ValueError, "invalid HarfBuzz direction: " & value)
  direction.toDirection

proc `$`*(direction: Direction): string =
  fromCString(raw.hb_direction_to_string(direction.toRaw))

proc isHorizontal*(direction: Direction): bool =
  raw.hb_direction_is_horizontal(direction.toRaw)

proc isVertical*(direction: Direction): bool =
  raw.hb_direction_is_vertical(direction.toRaw)

proc reverse*(direction: Direction): Direction =
  raw.hb_direction_reverse(direction.toRaw).toDirection

proc initFeature*(
    tag: Tag,
    value: uint32 = 1,
    start: uint32 = featureGlobalStart,
    ending: uint32 = featureGlobalEnd,
): Feature =
  Feature(tag: tag, value: value, start: start, ending: ending)

proc toFeature*(value: string): Feature =
  if value.len == 0:
    raise newException(ValueError, "feature string is empty")
  var feature: raw.HbFeature
  if raw.hb_feature_from_string(
    value.cstring, checkedCint(value.len, "feature length"), addr feature
  ).boolValue:
    Feature(
      tag: Tag(feature.tag),
      value: feature.value,
      start: uint32(feature.start),
      ending: uint32(feature.ending),
    )
  else:
    raise newException(ValueError, "invalid HarfBuzz feature: " & value)

proc toRaw(feature: Feature): raw.HbFeature =
  raw.HbFeature(
    tag: raw.HbTag(feature.tag),
    value: feature.value,
    start: cuint(feature.start),
    ending: cuint(feature.ending),
  )

proc `$`*(feature: Feature): string =
  var rawFeature = feature.toRaw
  var buf: array[128, cchar]
  raw.hb_feature_to_string(addr rawFeature, cast[cstring](addr buf[0]), cuint(buf.len))
  fromCString(cast[cstring](addr buf[0]))

proc initBlob*(data: string): Blob =
  let length = checkedCuint(data.len, "blob length")
  let dataPtr =
    if data.len == 0:
      cast[cstring](nil)
    else:
      data.cstring
  result.handle =
    raw.hb_blob_create_or_fail(dataPtr, length, raw.HB_MEMORY_MODE_DUPLICATE, nil, nil)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz blob")

proc initBlob*(data: openArray[byte]): Blob =
  let length = checkedCuint(data.len, "blob length")
  let dataPtr =
    if data.len == 0:
      cast[cstring](nil)
    else:
      cast[cstring](unsafeAddr data[0])
  result.handle =
    raw.hb_blob_create_or_fail(dataPtr, length, raw.HB_MEMORY_MODE_DUPLICATE, nil, nil)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz blob")

proc blobFromFile*(path: string): Blob =
  if path.len == 0:
    raise newException(ValueError, "font path is empty")
  result.handle = raw.hb_blob_create_from_file_or_fail(path.cstring)
  if result.handle == nil:
    raise newException(IOError, "could not read HarfBuzz blob from " & path)

proc subBlob*(blob: Blob, offset, length: Natural): Blob =
  result.handle = raw.hb_blob_create_sub_blob(
    blob.requireBlob,
    checkedCuint(offset, "blob offset"),
    checkedCuint(length, "blob length"),
  )
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz sub-blob")

proc len*(blob: Blob): int =
  int(raw.hb_blob_get_length(blob.requireBlob))

proc data*(blob: Blob): string =
  var length: cuint
  let dataPtr = raw.hb_blob_get_data(blob.requireBlob, addr length)
  let n = int(length)
  result = newString(n)
  if n > 0:
    if dataPtr == nil:
      raise newException(ValueError, "HarfBuzz returned null blob data")
    copyMem(addr result[0], dataPtr, n)

proc makeImmutable*(blob: var Blob) =
  raw.hb_blob_make_immutable(blob.requireBlob)

proc isImmutable*(blob: Blob): bool =
  raw.hb_blob_is_immutable(blob.requireBlob).boolValue

proc faceCount*(blob: Blob): int =
  int(raw.hb_face_count(blob.requireBlob))

proc initFace*(blob: Blob, index: Natural = 0): Face =
  result.handle =
    raw.hb_face_create_or_fail(blob.requireBlob, checkedCuint(index, "face index"))
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz face")

proc faceFromFile*(path: string, index: Natural = 0): Face =
  if path.len == 0:
    raise newException(ValueError, "font path is empty")
  result.handle = raw.hb_face_create_from_file_or_fail(
    path.cstring, checkedCuint(index, "face index")
  )
  if result.handle == nil:
    raise newException(IOError, "could not read HarfBuzz face from " & path)

proc referenceBlob*(face: Face): Blob =
  result.handle = raw.hb_face_reference_blob(face.requireFace)
  if result.handle == nil:
    raise newException(ValueError, "could not reference HarfBuzz face blob")

proc referenceTable*(face: Face, tag: Tag): Blob =
  result.handle = raw.hb_face_reference_table(face.requireFace, raw.HbTag(tag))
  if result.handle == nil:
    raise newException(ValueError, "could not reference HarfBuzz face table")

proc index*(face: Face): int =
  int(raw.hb_face_get_index(face.requireFace))

proc upem*(face: Face): int =
  int(raw.hb_face_get_upem(face.requireFace))

proc glyphCount*(face: Face): int =
  int(raw.hb_face_get_glyph_count(face.requireFace))

proc hasAatSubstitution*(face: Face): bool =
  raw.hb_aat_layout_has_substitution(face.requireFace).boolValue

proc hasAatPositioning*(face: Face): bool =
  raw.hb_aat_layout_has_positioning(face.requireFace).boolValue

proc hasAatTracking*(face: Face): bool =
  raw.hb_aat_layout_has_tracking(face.requireFace).boolValue

proc initFont*(face: Face, useOpenTypeFuncs = true): Font =
  result.handle = raw.hb_font_create(face.requireFace)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz font")
  if useOpenTypeFuncs:
    raw.hb_ot_font_set_funcs(result.handle)

proc face*(font: Font): Face =
  result.handle = raw.hb_font_get_face(font.requireFont)
  if result.handle != nil:
    discard raw.hb_face_reference(result.handle)

proc setScale*(font: var Font, x, y: int) =
  raw.hb_font_set_scale(
    font.requireFont, checkedCint(x, "x scale"), checkedCint(y, "y scale")
  )

proc scale*(font: Font): Scale =
  var x, y: cint
  raw.hb_font_get_scale(font.requireFont, addr x, addr y)
  Scale(x: int(x), y: int(y))

proc setPpem*(font: var Font, x, y: Natural) =
  raw.hb_font_set_ppem(
    font.requireFont, checkedCuint(x, "x ppem"), checkedCuint(y, "y ppem")
  )

proc ppem*(font: Font): Ppem =
  var x, y: cuint
  raw.hb_font_get_ppem(font.requireFont, addr x, addr y)
  Ppem(x: uint(x), y: uint(y))

proc horizontalExtents*(font: Font): FontExtents =
  var extents: raw.HbFontExtents
  if not raw.hb_font_get_h_extents(font.requireFont, addr extents).boolValue:
    raise newException(ValueError, "font has no horizontal extents")
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.lineGap
  )

proc nominalGlyph*(font: Font, codepoint: Codepoint): Codepoint =
  if not raw.hb_font_get_nominal_glyph(font.requireFont, codepoint, addr result).boolValue:
    raise newException(ValueError, "font has no glyph for codepoint " & $codepoint)

proc horizontalAdvance*(font: Font, glyph: Codepoint): Position =
  raw.hb_font_get_glyph_h_advance(font.requireFont, glyph)

proc glyphExtents*(font: Font, glyph: Codepoint): GlyphExtents =
  var extents: raw.HbGlyphExtents
  if not raw.hb_font_get_glyph_extents(font.requireFont, glyph, addr extents).boolValue:
    raise newException(ValueError, "font has no extents for glyph " & $glyph)
  GlyphExtents(
    xBearing: extents.xBearing,
    yBearing: extents.yBearing,
    width: extents.width,
    height: extents.height,
  )

proc initBuffer*(): Buffer =
  result.handle = raw.hb_buffer_create()
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz buffer")

proc similar*(buffer: Buffer): Buffer =
  result.handle = raw.hb_buffer_create_similar(buffer.requireBuffer)
  if result.handle == nil:
    raise newException(ValueError, "could not create similar HarfBuzz buffer")

proc reset*(buffer: var Buffer) =
  raw.hb_buffer_reset(buffer.requireBuffer)

proc clear*(buffer: var Buffer) =
  raw.hb_buffer_clear_contents(buffer.requireBuffer)

proc len*(buffer: Buffer): int =
  int(raw.hb_buffer_get_length(buffer.requireBuffer))

proc setDirection*(buffer: var Buffer, direction: Direction) =
  raw.hb_buffer_set_direction(buffer.requireBuffer, direction.toRaw)

proc direction*(buffer: Buffer): Direction =
  raw.hb_buffer_get_direction(buffer.requireBuffer).toDirection

proc setScript*(buffer: var Buffer, script: Script) =
  raw.hb_buffer_set_script(buffer.requireBuffer, raw.HbScript(script))

proc script*(buffer: Buffer): Script =
  Script(raw.hb_buffer_get_script(buffer.requireBuffer))

proc setLanguage*(buffer: var Buffer, language: Language) =
  raw.hb_buffer_set_language(buffer.requireBuffer, raw.HbLanguage(language))

proc language*(buffer: Buffer): Language =
  Language(raw.hb_buffer_get_language(buffer.requireBuffer))

proc guessSegmentProperties*(buffer: var Buffer) =
  raw.hb_buffer_guess_segment_properties(buffer.requireBuffer)

proc setFlags*(buffer: var Buffer, flags: BufferFlags) =
  raw.hb_buffer_set_flags(buffer.requireBuffer, flags.toRaw)

proc flags*(buffer: Buffer): BufferFlags =
  raw.hb_buffer_get_flags(buffer.requireBuffer).toFlags

proc add*(buffer: var Buffer, codepoint: Codepoint, cluster: Natural = 0) =
  raw.hb_buffer_add(buffer.requireBuffer, codepoint, checkedCuint(cluster, "cluster"))

proc addUtf8*(buffer: var Buffer, text: string) =
  let length = checkedCint(text.len, "text length")
  raw.hb_buffer_add_utf8(buffer.requireBuffer, text.cstring, length, 0, length)

proc addCodepoints*(buffer: var Buffer, text: openArray[Codepoint]) =
  let length = checkedCint(text.len, "codepoint count")
  let textPtr =
    if text.len == 0:
      cast[ptr Codepoint](nil)
    else:
      unsafeAddr text[0]
  raw.hb_buffer_add_codepoints(buffer.requireBuffer, textPtr, length, 0, length)

proc glyphInfos*(buffer: var Buffer): seq[GlyphInfo] =
  var length: cuint
  let infos = raw.hb_buffer_get_glyph_infos(buffer.requireBuffer, addr length)
  result = newSeq[GlyphInfo](int(length))
  if result.len > 0 and infos == nil:
    raise newException(ValueError, "HarfBuzz returned null glyph info data")
  for i in 0 ..< result.len:
    result[i] = GlyphInfo(
      codepoint: infos[i].codepoint,
      cluster: infos[i].cluster,
      flags: infos[i].mask and uint32(raw.HB_GLYPH_FLAG_DEFINED),
    )

proc glyphPositions*(buffer: var Buffer): seq[GlyphPosition] =
  var length: cuint
  let positions = raw.hb_buffer_get_glyph_positions(buffer.requireBuffer, addr length)
  result = newSeq[GlyphPosition](int(length))
  if result.len > 0 and positions == nil:
    raise newException(ValueError, "HarfBuzz returned null glyph position data")
  for i in 0 ..< result.len:
    result[i] = GlyphPosition(
      xAdvance: positions[i].xAdvance,
      yAdvance: positions[i].yAdvance,
      xOffset: positions[i].xOffset,
      yOffset: positions[i].yOffset,
    )

proc hasPositions*(buffer: var Buffer): bool =
  raw.hb_buffer_has_positions(buffer.requireBuffer).boolValue

proc shape*(font: Font, buffer: var Buffer, features: openArray[Feature] = []) =
  if features.len == 0:
    raw.hb_shape(font.requireFont, buffer.requireBuffer, nil, 0)
  else:
    var rawFeatures = newSeq[raw.HbFeature](features.len)
    for i, feature in features:
      rawFeatures[i] = feature.toRaw
    raw.hb_shape(
      font.requireFont,
      buffer.requireBuffer,
      addr rawFeatures[0],
      checkedCuint(rawFeatures.len, "feature count"),
    )

proc initSet*(): Set =
  result.handle = raw.hb_set_create()
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz set")

proc len*(set: Set): int =
  int(raw.hb_set_get_population(set.requireSet))

proc contains*(set: Set, codepoint: Codepoint): bool =
  raw.hb_set_has(set.requireSet, codepoint).boolValue

proc incl*(set: var Set, codepoint: Codepoint) =
  raw.hb_set_add(set.requireSet, codepoint)

proc incl*(set: var Set, first, last: Codepoint) =
  raw.hb_set_add_range(set.requireSet, first, last)

proc excl*(set: var Set, codepoint: Codepoint) =
  raw.hb_set_del(set.requireSet, codepoint)

proc clear*(set: var Set) =
  raw.hb_set_clear(set.requireSet)

proc isEmpty*(set: Set): bool =
  raw.hb_set_is_empty(set.requireSet).boolValue

proc min*(set: Set): Codepoint =
  raw.hb_set_get_min(set.requireSet)

proc max*(set: Set): Codepoint =
  raw.hb_set_get_max(set.requireSet)

iterator items*(set: Set): Codepoint =
  var current = raw.HB_SET_VALUE_INVALID
  while raw.hb_set_next(set.requireSet, addr current).boolValue:
    yield current

proc initSubsetInput*(): SubsetInput =
  result.handle = raw.hb_subset_input_create_or_fail()
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz subset input")

proc keepEverything*(input: var SubsetInput) =
  raw.hb_subset_input_keep_everything(input.requireInput)

proc inclUnicode*(input: var SubsetInput, codepoint: Codepoint) =
  let set = raw.hb_subset_input_unicode_set(input.requireInput)
  if set == nil:
    raise newException(ValueError, "could not get HarfBuzz subset unicode set")
  raw.hb_set_add(set, codepoint)

proc inclGlyph*(input: var SubsetInput, glyph: Codepoint) =
  let set = raw.hb_subset_input_glyph_set(input.requireInput)
  if set == nil:
    raise newException(ValueError, "could not get HarfBuzz subset glyph set")
  raw.hb_set_add(set, glyph)

proc pinAxisLocation*(
    input: var SubsetInput, face: Face, tag: Tag, value: float32
): bool =
  raw.hb_subset_input_pin_axis_location(
    input.requireInput, face.requireFace, raw.HbTag(tag), cfloat(value)
  ).boolValue

proc subset*(face: Face, input: SubsetInput): Face =
  result.handle = raw.hb_subset_or_fail(face.requireFace, input.requireInput)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset failed")

proc preprocess*(face: Face): Face =
  result.handle = raw.hb_subset_preprocess(face.requireFace)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset preprocess failed")

proc initSubsetPlan*(face: Face, input: SubsetInput): SubsetPlan =
  result.handle =
    raw.hb_subset_plan_create_or_fail(face.requireFace, input.requireInput)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz subset plan")

proc execute*(plan: SubsetPlan): Face =
  result.handle = raw.hb_subset_plan_execute_or_fail(plan.requirePlan)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset plan execution failed")
