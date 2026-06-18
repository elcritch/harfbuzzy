## Ergonomic HarfBuzz wrapper built on top of `harfbuzzy/raw`.

when not (defined(gcarc) or defined(gcorc) or defined(gcatomicarc)):
  {.
    error:
      "harfbuzzy requires --mm:arc, --mm:orc, or --mm:atomicArc for deterministic HarfBuzz handle destructors"
  .}

import harfbuzzy/[fribidi_raw, raw]

type
  Blob* = object
    handle: raw.HbBlob

  Face* = object
    handle: raw.HbFace

  Font* = object
    handle: raw.HbFont

  Buffer* = object
    handle: raw.HbBuffer

  ShapePlan* = object
    handle: raw.HbShapePlan

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

proc `=destroy`(x: ShapePlan) =
  destroyHandle(x.handle, raw.hb_shape_plan_destroy)

proc `=wasMoved`(x: var ShapePlan) =
  x.handle = nil

proc `=copy`(dest: var ShapePlan, src: ShapePlan) =
  copyHandle(
    dest.handle, src.handle, raw.hb_shape_plan_reference, raw.hb_shape_plan_destroy
  )

proc `=dup`(src: ShapePlan): ShapePlan =
  dupHandle(src, raw.hb_shape_plan_reference)

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

  ClusterLevel* {.pure.} = enum
    monotoneGraphemes
    monotoneCharacters
    characters
    graphemes

  SerializeFormat* {.pure.} = enum
    text
    json

  SerializeFlag* = enum
    noClusters
    noPositions
    noGlyphNames
    glyphExtents
    glyphFlags
    noAdvances

  SerializeFlags* = set[SerializeFlag]

  Feature* = object
    tag*: Tag
    value*: uint32
    start*: uint32
    ending*: uint32

  Variation* = object
    tag*: Tag
    value*: float32

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

  Advance* = object
    x*: Position
    y*: Position

  Ppem* = object
    x*: uint
    y*: uint

  Version* = object
    major*: int
    minor*: int
    micro*: int

  Glyph* = object
    codepoint*: Codepoint
    cluster*: uint32
    flags*: uint32
    xAdvance*: Position
    yAdvance*: Position
    xOffset*: Position
    yOffset*: Position

  GlyphRun* = object
    glyphs*: seq[Glyph]

  ParagraphDirection* {.pure.} = enum
    autoDetect
    ltr
    rtl

  BidiLevel* = distinct uint8

  TextRun* = object
    byteStart*: int
    byteEnd*: int
    codepointStart*: int
    codepointEnd*: int
    direction*: Direction
    level*: BidiLevel
    script*: Script
    language*: Language
    features*: seq[Feature]

  ShapedRun* = object
    textRun*: TextRun
    glyphRun*: GlyphRun
    typefaceIndex*: int

  ShapedParagraph* = object
    baseDirection*: Direction
    logicalRuns*: seq[ShapedRun]
    visualRuns*: seq[ShapedRun]

  ShapeOptions* = object
    direction*: Direction
    script*: Script
    language*: Language
    features*: seq[Feature]
    shapers*: seq[string]
    flags*: BufferFlags
    clusterLevel*: ClusterLevel

  ParagraphOptions* = object
    baseDirection*: ParagraphDirection
    language*: Language
    features*: seq[Feature]
    shapers*: seq[string]
    flags*: BufferFlags
    clusterLevel*: ClusterLevel

  Typeface* = object
    face*: Face
    font*: Font

  GlyphRange* = object
    glyphStart*: int
    glyphEnd*: int

  RunGlyphRange* = object
    runIndex*: int
    glyphStart*: int
    glyphEnd*: int

  FontFallbackProc* =
    proc(text: string, run: TextRun, typefaces: seq[Typeface]): int {.nimcall.}

  ShapeContext* = object
    typefaces*: seq[Typeface]
    options*: ParagraphOptions
    fallback*: FontFallbackProc

  DecodedText = object
    codepoints: seq[Codepoint]
    byteStarts: seq[int]
    byteEnds: seq[int]

  BidiAnalysis = object
    baseDirection: Direction
    runs: seq[TextRun]

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
  scriptDevanagari* = Script(raw.hbTag('D', 'e', 'v', 'a'))
  scriptHebrew* = Script(raw.hbTag('H', 'e', 'b', 'r'))
  scriptLatin* = Script(raw.HB_SCRIPT_LATIN)
  scriptInvalid* = Script(raw.HB_SCRIPT_INVALID)
  languageInvalid* = Language(raw.HB_LANGUAGE_INVALID)
  tableGsub* = Tag(raw.HB_OT_TAG_GSUB)
  tableGpos* = Tag(raw.HB_OT_TAG_GPOS)

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

func toRaw(level: ClusterLevel): raw.HbBufferClusterLevel =
  case level
  of ClusterLevel.monotoneGraphemes:
    raw.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
  of ClusterLevel.monotoneCharacters:
    raw.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
  of ClusterLevel.characters:
    raw.HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
  of ClusterLevel.graphemes:
    raw.HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES

func toClusterLevel(level: raw.HbBufferClusterLevel): ClusterLevel =
  case cuint(level)
  of cuint(raw.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS):
    ClusterLevel.monotoneCharacters
  of cuint(raw.HB_BUFFER_CLUSTER_LEVEL_CHARACTERS):
    ClusterLevel.characters
  of cuint(raw.HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES):
    ClusterLevel.graphemes
  else:
    ClusterLevel.monotoneGraphemes

func toRaw(flags: SerializeFlags): raw.HbBufferSerializeFlags =
  result = raw.HB_BUFFER_SERIALIZE_FLAG_DEFAULT
  if noClusters in flags:
    result = result or raw.HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS
  if noPositions in flags:
    result = result or raw.HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS
  if noGlyphNames in flags:
    result = result or raw.HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES
  if glyphExtents in flags:
    result = result or raw.HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS
  if glyphFlags in flags:
    result = result or raw.HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS
  if noAdvances in flags:
    result = result or raw.HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES

func toRaw(format: SerializeFormat): raw.HbBufferSerializeFormat =
  case format
  of SerializeFormat.text: raw.HB_BUFFER_SERIALIZE_FORMAT_TEXT
  of SerializeFormat.json: raw.HB_BUFFER_SERIALIZE_FORMAT_JSON

func isNil*(blob: Blob): bool =
  blob.handle == nil
func isNil*(face: Face): bool =
  face.handle == nil
func isNil*(font: Font): bool =
  font.handle == nil
func isNil*(buffer: Buffer): bool =
  buffer.handle == nil
func isNil*(plan: ShapePlan): bool =
  plan.handle == nil
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

proc requirePlan(plan: ShapePlan): raw.HbShapePlan =
  if plan.handle == nil:
    raise newException(ValueError, "HarfBuzz shape plan is uninitialized")
  plan.handle

proc requireSet(set: Set): raw.HbSet =
  if set.handle == nil:
    raise newException(ValueError, "HarfBuzz set is uninitialized")
  set.handle

proc requireInput(input: SubsetInput): raw.HbSubsetInput =
  if input.handle == nil:
    raise newException(ValueError, "HarfBuzz subset input is uninitialized")
  input.handle

proc requireSubsetPlan(plan: SubsetPlan): raw.HbSubsetPlan =
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

proc initVariation*(tag: Tag, value: float32): Variation =
  Variation(tag: tag, value: value)

proc initShapeOptions*(
    features: openArray[Feature] = [],
    shapers: openArray[string] = [],
    direction = Direction.invalid,
    script = scriptInvalid,
    language = languageInvalid,
    flags: BufferFlags = {},
    clusterLevel = ClusterLevel.monotoneGraphemes,
): ShapeOptions =
  ShapeOptions(
    direction: direction,
    script: script,
    language: language,
    features: @features,
    shapers: @shapers,
    flags: flags,
    clusterLevel: clusterLevel,
  )

proc initParagraphOptions*(
    baseDirection = ParagraphDirection.autoDetect,
    language = languageInvalid,
    features: openArray[Feature] = [],
    shapers: openArray[string] = [],
    flags: BufferFlags = {},
    clusterLevel = ClusterLevel.monotoneGraphemes,
): ParagraphOptions =
  ParagraphOptions(
    baseDirection: baseDirection,
    language: language,
    features: @features,
    shapers: @shapers,
    flags: flags,
    clusterLevel: clusterLevel,
  )

proc byteValue(text: string, index: int): uint8 =
  uint8(ord(text[index]))

proc continuationValue(text: string, index: int): uint32 =
  if index >= text.len:
    raise newException(ValueError, "malformed UTF-8: truncated sequence")
  let value = byteValue(text, index)
  if (value and 0xC0'u8) != 0x80'u8:
    raise newException(ValueError, "malformed UTF-8: invalid continuation byte")
  uint32(value and 0x3F'u8)

proc addDecoded(decoded: var DecodedText, codepoint: uint32, byteStart, byteEnd: int) =
  if codepoint > 0x10FFFF'u32 or (codepoint >= 0xD800'u32 and codepoint <= 0xDFFF'u32):
    raise newException(ValueError, "malformed UTF-8: invalid Unicode scalar value")
  decoded.codepoints.add Codepoint(codepoint)
  decoded.byteStarts.add byteStart
  decoded.byteEnds.add byteEnd

proc decodeUtf8(text: string): DecodedText =
  var index = 0
  while index < text.len:
    let start = index
    let first = byteValue(text, index)
    if first < 0x80'u8:
      inc index
      result.addDecoded(uint32(first), start, index)
    elif (first and 0xE0'u8) == 0xC0'u8:
      if first < 0xC2'u8:
        raise newException(ValueError, "malformed UTF-8: overlong sequence")
      let codepoint =
        ((uint32(first and 0x1F'u8) shl 6) or continuationValue(text, index + 1))
      index += 2
      result.addDecoded(codepoint, start, index)
    elif (first and 0xF0'u8) == 0xE0'u8:
      let second = continuationValue(text, index + 1)
      let codepoint = (
        (uint32(first and 0x0F'u8) shl 12) or (second shl 6) or
        continuationValue(text, index + 2)
      )
      if codepoint < 0x800'u32:
        raise newException(ValueError, "malformed UTF-8: overlong sequence")
      index += 3
      result.addDecoded(codepoint, start, index)
    elif (first and 0xF8'u8) == 0xF0'u8:
      let codepoint = (
        (uint32(first and 0x07'u8) shl 18) or (
          continuationValue(text, index + 1) shl 12
        ) or (continuationValue(text, index + 2) shl 6) or
        continuationValue(text, index + 3)
      )
      if codepoint < 0x10000'u32:
        raise newException(ValueError, "malformed UTF-8: overlong sequence")
      index += 4
      result.addDecoded(codepoint, start, index)
    else:
      raise newException(ValueError, "malformed UTF-8: invalid leading byte")

func toFriBidiPar(direction: ParagraphDirection): fribidi_raw.FriBidiParType =
  case direction
  of ParagraphDirection.autoDetect: fribidi_raw.FRIBIDI_PAR_ON
  of ParagraphDirection.ltr: fribidi_raw.FRIBIDI_PAR_LTR
  of ParagraphDirection.rtl: fribidi_raw.FRIBIDI_PAR_RTL

func levelDirection(level: fribidi_raw.FriBidiLevel): Direction =
  if fribidi_raw.fribidi_level_is_rtl(level): Direction.rtl else: Direction.ltr

func baseDirection(base: fribidi_raw.FriBidiParType): Direction =
  if base == fribidi_raw.FRIBIDI_PAR_RTL or base == fribidi_raw.FRIBIDI_PAR_WRTL:
    Direction.rtl
  else:
    Direction.ltr

func levelValue*(level: BidiLevel): int =
  int(uint8(level))

func direction*(level: BidiLevel): Direction =
  if (level.levelValue and 1) == 0: Direction.ltr else: Direction.rtl

func isArabicCodepoint(codepoint: Codepoint): bool =
  (codepoint >= 0x0600'u32 and codepoint <= 0x06FF'u32) or
    (codepoint >= 0x0750'u32 and codepoint <= 0x077F'u32) or
    (codepoint >= 0x08A0'u32 and codepoint <= 0x08FF'u32) or
    (codepoint >= 0xFB50'u32 and codepoint <= 0xFDFF'u32) or
    (codepoint >= 0xFE70'u32 and codepoint <= 0xFEFF'u32)

func isHebrewCodepoint(codepoint: Codepoint): bool =
  codepoint >= 0x0590'u32 and codepoint <= 0x05FF'u32

func isDevanagariCodepoint(codepoint: Codepoint): bool =
  (codepoint >= 0x0900'u32 and codepoint <= 0x097F'u32) or
    (codepoint >= 0xA8E0'u32 and codepoint <= 0xA8FF'u32) or
    (codepoint >= 0x11B00'u32 and codepoint <= 0x11B5F'u32)

func isLatinCodepoint(codepoint: Codepoint): bool =
  (codepoint >= 0x0041'u32 and codepoint <= 0x005A'u32) or
    (codepoint >= 0x0061'u32 and codepoint <= 0x007A'u32) or
    (codepoint >= 0x00C0'u32 and codepoint <= 0x024F'u32)

func shouldSetScript(script: Script): bool =
  raw.HbScript(script) != raw.HB_SCRIPT_INVALID and
    raw.HbScript(script) != raw.HB_SCRIPT_UNKNOWN

func scriptFor*(codepoint: Codepoint): Script =
  if isArabicCodepoint(codepoint):
    scriptArabic
  elif isHebrewCodepoint(codepoint):
    scriptHebrew
  elif isDevanagariCodepoint(codepoint):
    scriptDevanagari
  elif isLatinCodepoint(codepoint):
    scriptLatin
  else:
    scriptUnknown

func inferScript(text: openArray[Codepoint], first, last: int): Script =
  for index in first ..< last:
    let script = scriptFor(text[index])
    if raw.HbScript(script) != raw.HB_SCRIPT_UNKNOWN:
      return script
  scriptUnknown

proc defaultLanguageForScript*(script: Script): Language =
  if raw.HbScript(script) == raw.HB_SCRIPT_ARABIC:
    toLanguage("ar")
  elif raw.HbScript(script) == raw.HbScript(scriptDevanagari):
    toLanguage("hi")
  elif raw.HbScript(script) == raw.HbScript(scriptHebrew):
    toLanguage("he")
  elif raw.HbScript(script) == raw.HB_SCRIPT_LATIN:
    toLanguage("en")
  else:
    defaultLanguage()

proc analyzeBidi(text: string, options: ParagraphOptions): BidiAnalysis =
  let decoded = decodeUtf8(text)
  if decoded.codepoints.len == 0:
    result.baseDirection =
      if options.baseDirection == ParagraphDirection.rtl:
        Direction.rtl
      else:
        Direction.ltr
    return

  let length = checkedCint(decoded.codepoints.len, "codepoint count")
  var bidiTypes = newSeq[fribidi_raw.FriBidiCharType](decoded.codepoints.len)
  var bracketTypes = newSeq[fribidi_raw.FriBidiBracketType](decoded.codepoints.len)
  var levels = newSeq[fribidi_raw.FriBidiLevel](decoded.codepoints.len)
  var base = options.baseDirection.toFriBidiPar

  fribidi_raw.fribidi_get_bidi_types(
    unsafeAddr decoded.codepoints[0], length, addr bidiTypes[0]
  )
  fribidi_raw.fribidi_get_bracket_types(
    unsafeAddr decoded.codepoints[0], length, addr bidiTypes[0], addr bracketTypes[0]
  )
  let maxLevel = fribidi_raw.fribidi_get_par_embedding_levels_ex(
    addr bidiTypes[0], addr bracketTypes[0], length, addr base, addr levels[0]
  )
  if maxLevel == 0:
    raise newException(ValueError, "FriBidi could not resolve embedding levels")

  result.baseDirection = base.baseDirection
  var first = 0
  while first < levels.len:
    var runScript = scriptFor(decoded.codepoints[first])
    var last = first + 1
    while last < levels.len and levels[last] == levels[first]:
      let nextScript = scriptFor(decoded.codepoints[last])
      if raw.HbScript(runScript) == raw.HB_SCRIPT_UNKNOWN:
        runScript = nextScript
      elif raw.HbScript(nextScript) != raw.HB_SCRIPT_UNKNOWN and
          raw.HbScript(nextScript) != raw.HbScript(runScript):
        break
      inc last
    if raw.HbScript(runScript) == raw.HB_SCRIPT_UNKNOWN:
      runScript = inferScript(decoded.codepoints, first, last)
    let language =
      if raw.HbLanguage(options.language) != raw.HB_LANGUAGE_INVALID:
        options.language
      else:
        defaultLanguageForScript(runScript)
    result.runs.add TextRun(
      byteStart: decoded.byteStarts[first],
      byteEnd: decoded.byteEnds[last - 1],
      codepointStart: first,
      codepointEnd: last,
      direction: levels[first].levelDirection,
      level: BidiLevel(uint8(levels[first])),
      script: runScript,
      language: language,
      features: options.features,
    )
    first = last

proc bidiRuns*(text: string, options = ParagraphOptions()): seq[TextRun] =
  analyzeBidi(text, options).runs

proc reverseRange[T](values: var seq[T], first, last: int) =
  var left = first
  var right = last - 1
  while left < right:
    swap values[left], values[right]
    inc left
    dec right

func visualOrderIndices(runs: openArray[TextRun]): seq[int] =
  result = newSeq[int](runs.len)
  if runs.len == 0:
    return
  var maxLevel = 0
  var minOddLevel = int.high
  for index, run in runs:
    result[index] = index
    let level = run.level.levelValue
    if level > maxLevel:
      maxLevel = level
    if (level and 1) == 1 and level < minOddLevel:
      minOddLevel = level
  if minOddLevel == int.high:
    return
  var level = maxLevel
  while level >= minOddLevel:
    var index = 0
    while index < result.len:
      if runs[result[index]].level.levelValue >= level:
        let first = index
        while index < result.len and runs[result[index]].level.levelValue >= level:
          inc index
        result.reverseRange(first, index)
      else:
        inc index
    dec level

proc toRaw(feature: Feature): raw.HbFeature =
  raw.HbFeature(
    tag: raw.HbTag(feature.tag),
    value: feature.value,
    start: cuint(feature.start),
    ending: cuint(feature.ending),
  )

proc toRaw(variation: Variation): raw.HbVariation =
  raw.HbVariation(tag: raw.HbTag(variation.tag), value: cfloat(variation.value))

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
    raw.hb_blob_create(dataPtr, length, raw.HB_MEMORY_MODE_DUPLICATE, nil, nil)
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
    raw.hb_blob_create(dataPtr, length, raw.HB_MEMORY_MODE_DUPLICATE, nil, nil)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz blob")

proc blobFromFile*(path: string): Blob =
  if path.len == 0:
    raise newException(ValueError, "font path is empty")
  result.handle = raw.hb_blob_create_from_file(path.cstring)
  if result.handle == nil or raw.hb_blob_get_length(result.handle) == 0:
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
    raw.hb_face_create(blob.requireBlob, checkedCuint(index, "face index"))
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz face")

proc faceFromFile*(path: string, index: Natural = 0): Face =
  if path.len == 0:
    raise newException(ValueError, "font path is empty")
  result = initFace(blobFromFile(path), index)

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

proc hasOpenTypeSubstitution*(face: Face): bool =
  raw.hb_ot_layout_has_substitution(face.requireFace).boolValue

proc hasOpenTypePositioning*(face: Face): bool =
  raw.hb_ot_layout_has_positioning(face.requireFace).boolValue

proc layoutFeatureTags*(face: Face, tableTag: Tag): seq[Tag] =
  const chunkSize = 64
  var start: cuint
  while true:
    var count = cuint(chunkSize)
    var tags = newSeq[raw.HbTag](chunkSize)
    let fetched = raw.hb_ot_layout_table_get_feature_tags(
      face.requireFace, raw.HbTag(tableTag), start, addr count, addr tags[0]
    )
    for i in 0 ..< int(count):
      result.add Tag(tags[i])
    if fetched == 0 or count < chunkSize:
      break
    start += count

proc layoutFeatureTags*(face: Face, tableTag: Tag, script: Script): seq[Tag] =
  var scriptIndex: cuint
  if not raw.hb_ot_layout_table_find_script(
    face.requireFace,
    raw.HbTag(tableTag),
    raw.hb_script_to_iso15924_tag(raw.HbScript(script)),
    addr scriptIndex,
  ).boolValue:
    return

  const chunkSize = 64
  var start: cuint
  while true:
    var count = cuint(chunkSize)
    var tags = newSeq[raw.HbTag](chunkSize)
    let fetched = raw.hb_ot_layout_language_get_feature_tags(
      face.requireFace,
      raw.HbTag(tableTag),
      scriptIndex,
      raw.HB_OT_LAYOUT_DEFAULT_LANGUAGE_INDEX,
      start,
      addr count,
      addr tags[0],
    )
    for i in 0 ..< int(count):
      result.add Tag(tags[i])
    if fetched == 0 or count < chunkSize:
      break
    start += count

proc substitutionFeatureTags*(face: Face): seq[Tag] =
  layoutFeatureTags(face, tableGsub)

proc positioningFeatureTags*(face: Face): seq[Tag] =
  layoutFeatureTags(face, tableGpos)

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

proc setVariations*(font: var Font, variations: openArray[Variation]) =
  if variations.len == 0:
    raw.hb_font_set_variations(font.requireFont, nil, 0)
    return

  var rawVariations = newSeq[raw.HbVariation](variations.len)
  for i, variation in variations:
    rawVariations[i] = variation.toRaw
  raw.hb_font_set_variations(
    font.requireFont,
    addr rawVariations[0],
    checkedCuint(rawVariations.len, "variation count"),
  )

proc horizontalExtents*(font: Font): FontExtents =
  var extents: raw.HbFontExtents
  if not raw.hb_font_get_h_extents(font.requireFont, addr extents).boolValue:
    raise newException(ValueError, "font has no horizontal extents")
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.lineGap
  )

proc verticalExtents*(font: Font): FontExtents =
  var extents: raw.HbFontExtents
  if not raw.hb_font_get_v_extents(font.requireFont, addr extents).boolValue:
    raise newException(ValueError, "font has no vertical extents")
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.lineGap
  )

proc extents*(font: Font, direction: Direction): FontExtents =
  var extents: raw.HbFontExtents
  raw.hb_font_get_extents_for_direction(font.requireFont, direction.toRaw, addr extents)
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.lineGap
  )

func lineAdvance*(extents: FontExtents): Position =
  extents.ascender - extents.descender + extents.lineGap

proc nominalGlyph*(font: Font, codepoint: Codepoint): Codepoint =
  if not raw.hb_font_get_nominal_glyph(font.requireFont, codepoint, addr result).boolValue:
    raise newException(ValueError, "font has no glyph for codepoint " & $codepoint)

proc glyph*(
    font: Font, codepoint: Codepoint, variationSelector: Codepoint = 0
): Codepoint =
  if not raw.hb_font_get_glyph(
    font.requireFont, codepoint, variationSelector, addr result
  ).boolValue:
    raise newException(ValueError, "font has no glyph for codepoint " & $codepoint)

proc hasGlyph*(
    font: Font, codepoint: Codepoint, variationSelector: Codepoint = 0
): bool =
  var glyph: Codepoint

  raw.hb_font_get_glyph(font.requireFont, codepoint, variationSelector, addr glyph).boolValue and
    glyph != 0

proc horizontalAdvance*(font: Font, glyph: Codepoint): Position =
  raw.hb_font_get_glyph_h_advance(font.requireFont, glyph)

proc verticalAdvance*(font: Font, glyph: Codepoint): Position =
  raw.hb_font_get_glyph_v_advance(font.requireFont, glyph)

proc advance*(font: Font, glyph: Codepoint, direction: Direction): Advance =
  raw.hb_font_get_glyph_advance_for_direction(
    font.requireFont, glyph, direction.toRaw, addr result.x, addr result.y
  )

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

proc toEm*(face: Face, value: Position): float =
  let units = face.upem
  if units <= 0:
    raise newException(ValueError, "face has no units-per-em value")
  float(value) / float(units)

proc fromEm*(face: Face, value: float): Position =
  let units = face.upem
  if units <= 0:
    raise newException(ValueError, "face has no units-per-em value")
  Position(value * float(units))

proc initTypeface*(face: Face, useOpenTypeFuncs = true, scaleToUpem = true): Typeface =
  result.face = face
  result.font = initFont(result.face, useOpenTypeFuncs)
  if scaleToUpem:
    let units = result.face.upem
    if units > 0:
      result.font.setScale(units, units)

proc typefaceFromFile*(
    path: string, index: Natural = 0, useOpenTypeFuncs = true, scaleToUpem = true
): Typeface =
  initTypeface(faceFromFile(path, index), useOpenTypeFuncs, scaleToUpem)

proc initShapeContext*(
    primary: Typeface,
    fallbacks: openArray[Typeface] = [],
    options = ParagraphOptions(),
    fallback: FontFallbackProc = nil,
): ShapeContext =
  result.typefaces.add primary
  for typeface in fallbacks:
    result.typefaces.add typeface
  result.options = options
  result.fallback = fallback

proc initShapeContext*(
    typefaces: openArray[Typeface],
    options = ParagraphOptions(),
    fallback: FontFallbackProc = nil,
): ShapeContext =
  if typefaces.len == 0:
    raise newException(ValueError, "shape context requires at least one typeface")
  result.typefaces = @typefaces
  result.options = options
  result.fallback = fallback

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

proc setClusterLevel*(buffer: var Buffer, level: ClusterLevel) =
  raw.hb_buffer_set_cluster_level(buffer.requireBuffer, level.toRaw)

proc clusterLevel*(buffer: Buffer): ClusterLevel =
  raw.hb_buffer_get_cluster_level(buffer.requireBuffer).toClusterLevel

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

proc glyphInfos*(buffer: Buffer): seq[GlyphInfo] =
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

proc glyphPositions*(buffer: Buffer): seq[GlyphPosition] =
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

proc hasPositions*(buffer: Buffer): bool =
  raw.hb_buffer_has_positions(buffer.requireBuffer).boolValue

proc availableSerializeFormats*(): seq[string] =
  let formats = raw.hb_buffer_serialize_list_formats()
  if formats == nil:
    return
  var index = 0
  while formats[index] != nil:
    result.add $formats[index]
    inc index

proc serializeGlyphs*(
    buffer: Buffer,
    font: Font,
    format = SerializeFormat.text,
    flags: SerializeFlags = {},
): string =
  let total = buffer.len
  if total == 0:
    return ""
  var start = 0
  var chunkSize = 4096
  while start < total:
    var chunk = newString(chunkSize)
    var consumed: cuint
    let serialized = raw.hb_buffer_serialize_glyphs(
      buffer.requireBuffer,
      checkedCuint(start, "serialization start"),
      checkedCuint(total, "serialization end"),
      cast[cstring](addr chunk[0]),
      checkedCuint(chunk.len, "serialization buffer length"),
      addr consumed,
      font.requireFont,
      format.toRaw,
      flags.toRaw,
    )
    if consumed == 0 and serialized == 0:
      chunkSize *= 2
      if chunkSize > 1_048_576:
        raise newException(ValueError, "HarfBuzz buffer serialization made no progress")
      continue
    result.add chunk[0 ..< int(consumed)]
    start += int(serialized)

proc applyShapeOptions*(buffer: var Buffer, options: ShapeOptions) =
  if options.direction != Direction.invalid:
    buffer.setDirection(options.direction)
  if options.script.shouldSetScript:
    buffer.setScript(options.script)
  if raw.HbLanguage(options.language) != raw.HB_LANGUAGE_INVALID:
    buffer.setLanguage(options.language)
  if options.flags != {}:
    buffer.setFlags(options.flags)
  buffer.setClusterLevel(options.clusterLevel)
  buffer.guessSegmentProperties()

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

proc shapeFull*(
    font: Font,
    buffer: var Buffer,
    features: openArray[Feature] = [],
    shapers: openArray[string] = [],
) =
  if shapers.len == 0:
    shape(font, buffer, features)
    return

  var rawFeatures = newSeq[raw.HbFeature](features.len)
  for i, feature in features:
    rawFeatures[i] = feature.toRaw
  let shaperList = allocCStringArray(shapers)
  try:
    let featurePtr =
      if rawFeatures.len == 0:
        cast[ptr raw.HbFeature](nil)
      else:
        addr rawFeatures[0]
    if not raw.hb_shape_full(
      font.requireFont,
      buffer.requireBuffer,
      featurePtr,
      checkedCuint(rawFeatures.len, "feature count"),
      shaperList,
    ).boolValue:
      raise newException(ValueError, "HarfBuzz could not shape with requested shapers")
  finally:
    deallocCStringArray(shaperList)

proc availableShapers*(): seq[string] =
  let shapers = raw.hb_shape_list_shapers()
  if shapers == nil:
    return
  var index = 0
  while shapers[index] != nil:
    result.add $shapers[index]
    inc index

proc initShapePlan*(face: Face, options: ShapeOptions, cached = true): ShapePlan =
  var props = raw.HbSegmentProperties(
    direction: (
      if options.direction == Direction.invalid: Direction.ltr else: options.direction
    ).toRaw,
    script: (
      if raw.HbScript(options.script) == raw.HB_SCRIPT_INVALID:
        raw.HB_SCRIPT_UNKNOWN
      else:
        raw.HbScript(options.script)
    ),
    language: (
      if raw.HbLanguage(options.language) == raw.HB_LANGUAGE_INVALID:
        raw.HbLanguage(defaultLanguage())
      else:
        raw.HbLanguage(options.language)
    ),
  )
  var rawFeatures = newSeq[raw.HbFeature](options.features.len)
  for i, feature in options.features:
    rawFeatures[i] = feature.toRaw
  let shaperList =
    if options.shapers.len == 0:
      cast[cstringArray](nil)
    else:
      allocCStringArray(options.shapers)
  try:
    let featurePtr =
      if rawFeatures.len == 0:
        cast[ptr raw.HbFeature](nil)
      else:
        addr rawFeatures[0]
    result.handle =
      if cached:
        raw.hb_shape_plan_create_cached(
          face.requireFace,
          addr props,
          featurePtr,
          checkedCuint(rawFeatures.len, "feature count"),
          shaperList,
        )
      else:
        raw.hb_shape_plan_create(
          face.requireFace,
          addr props,
          featurePtr,
          checkedCuint(rawFeatures.len, "feature count"),
          shaperList,
        )
    if result.handle == nil:
      raise newException(ValueError, "could not create HarfBuzz shape plan")
  finally:
    if shaperList != nil:
      deallocCStringArray(shaperList)

proc initShapePlan*(
    typeface: Typeface, options: ShapeOptions, cached = true
): ShapePlan =
  initShapePlan(typeface.face, options, cached)

proc execute*(
    plan: ShapePlan, font: Font, buffer: var Buffer, features: openArray[Feature] = []
) =
  var rawFeatures = newSeq[raw.HbFeature](features.len)
  for i, feature in features:
    rawFeatures[i] = feature.toRaw
  let featurePtr =
    if rawFeatures.len == 0:
      cast[ptr raw.HbFeature](nil)
    else:
      addr rawFeatures[0]
  if not raw.hb_shape_plan_execute(
    plan.requirePlan,
    font.requireFont,
    buffer.requireBuffer,
    featurePtr,
    checkedCuint(rawFeatures.len, "feature count"),
  ).boolValue:
    raise newException(ValueError, "HarfBuzz shape plan execution failed")

proc shaper*(plan: ShapePlan): string =
  fromCString(raw.hb_shape_plan_get_shaper(plan.requirePlan))

proc toGlyphRun*(buffer: Buffer): GlyphRun =
  var infoLength: cuint
  let infos = raw.hb_buffer_get_glyph_infos(buffer.requireBuffer, addr infoLength)
  var positionLength: cuint
  let positions =
    raw.hb_buffer_get_glyph_positions(buffer.requireBuffer, addr positionLength)

  if infoLength != positionLength:
    raise newException(ValueError, "HarfBuzz glyph info and position lengths differ")

  result.glyphs = newSeq[Glyph](int(infoLength))
  if result.glyphs.len > 0:
    if infos == nil:
      raise newException(ValueError, "HarfBuzz returned null glyph info data")
    if positions == nil:
      raise newException(ValueError, "HarfBuzz returned null glyph position data")

  for i in 0 ..< result.glyphs.len:
    result.glyphs[i] = Glyph(
      codepoint: infos[i].codepoint,
      cluster: infos[i].cluster,
      flags: infos[i].mask and uint32(raw.HB_GLYPH_FLAG_DEFINED),
      xAdvance: positions[i].xAdvance,
      yAdvance: positions[i].yAdvance,
      xOffset: positions[i].xOffset,
      yOffset: positions[i].yOffset,
    )

proc shapeText*(font: Font, text: string, options = ShapeOptions()): GlyphRun =
  var buffer = initBuffer()
  buffer.addUtf8(text)
  buffer.applyShapeOptions(options)
  shapeFull(font, buffer, options.features, options.shapers)
  buffer.toGlyphRun()

proc shape*(font: Font, text: string, options = ShapeOptions()): GlyphRun =
  shapeText(font, text, options)

proc shapeText*(typeface: Typeface, text: string, options = ShapeOptions()): GlyphRun =
  shapeText(typeface.font, text, options)

proc shape*(typeface: Typeface, text: string, options = ShapeOptions()): GlyphRun =
  shapeText(typeface, text, options)

proc shapeText*(
    font: Font, text: string, plan: ShapePlan, options = ShapeOptions()
): GlyphRun =
  var buffer = initBuffer()
  buffer.addUtf8(text)
  buffer.applyShapeOptions(options)
  execute(plan, font, buffer, options.features)
  buffer.toGlyphRun()

proc shape*(
    font: Font, text: string, plan: ShapePlan, options = ShapeOptions()
): GlyphRun =
  shapeText(font, text, plan, options)

proc shapeText*(
    typeface: Typeface, text: string, plan: ShapePlan, options = ShapeOptions()
): GlyphRun =
  shapeText(typeface.font, text, plan, options)

proc shape*(
    typeface: Typeface, text: string, plan: ShapePlan, options = ShapeOptions()
): GlyphRun =
  shapeText(typeface, text, plan, options)

proc shapeRun*(
    font: Font, text: string, run: TextRun, options = ShapeOptions()
): ShapedRun =
  if run.byteStart < 0 or run.byteEnd < run.byteStart or run.byteEnd > text.len:
    raise newException(ValueError, "text run byte range is outside the input text")
  if run.byteStart > int(uint32.high):
    raise newException(ValueError, "text run byte start does not fit glyph clusters")

  var buffer = initBuffer()
  buffer.addUtf8(text[run.byteStart ..< run.byteEnd])
  buffer.setDirection(run.direction)
  if run.script.shouldSetScript:
    buffer.setScript(run.script)
  if raw.HbLanguage(run.language) != raw.HB_LANGUAGE_INVALID:
    buffer.setLanguage(run.language)
  if options.flags != {}:
    buffer.setFlags(options.flags)
  buffer.setClusterLevel(options.clusterLevel)
  buffer.guessSegmentProperties()

  let features = if run.features.len > 0: run.features else: options.features
  shapeFull(font, buffer, features, options.shapers)

  result = ShapedRun(textRun: run, glyphRun: buffer.toGlyphRun())
  let clusterOffset = uint32(run.byteStart)
  for glyph in result.glyphRun.glyphs.mitems:
    glyph.cluster += clusterOffset

proc shapeRun*(
    typeface: Typeface, text: string, run: TextRun, options = ShapeOptions()
): ShapedRun =
  shapeRun(typeface.font, text, run, options)

proc shapeRun*(
    context: ShapeContext,
    text: string,
    run: TextRun,
    typefaceIndex: Natural,
    options = ShapeOptions(),
): ShapedRun =
  if typefaceIndex >= context.typefaces.len:
    raise newException(ValueError, "typeface index is outside the shape context")
  result = shapeRun(context.typefaces[typefaceIndex].font, text, run, options)
  result.typefaceIndex = int(typefaceIndex)

proc missingGlyphIndices*(run: GlyphRun): seq[int] =
  for index, glyph in run.glyphs:
    if glyph.codepoint == 0:
      result.add index

proc hasMissingGlyphs*(run: GlyphRun): bool =
  for glyph in run.glyphs:
    if glyph.codepoint == 0:
      return true

proc missingGlyphIndices*(run: ShapedRun): seq[int] =
  missingGlyphIndices(run.glyphRun)

proc hasMissingGlyphs*(run: ShapedRun): bool =
  run.glyphRun.hasMissingGlyphs

func codepointNeedsGlyph(codepoint: Codepoint): bool =
  not (
    codepoint == 0x0009'u32 or codepoint == 0x000A'u32 or codepoint == 0x000D'u32 or
    codepoint == 0x0020'u32
  )

proc supportsRun(typeface: Typeface, decoded: DecodedText, run: TextRun): bool =
  for index in run.codepointStart ..< run.codepointEnd:
    let codepoint = decoded.codepoints[index]
    if codepointNeedsGlyph(codepoint) and not typeface.font.hasGlyph(codepoint):
      return false
  true

proc selectTypefaceIndex(
    context: ShapeContext, text: string, decoded: DecodedText, run: TextRun
): int =
  if context.typefaces.len == 0:
    raise newException(ValueError, "shape context requires at least one typeface")
  if context.fallback != nil:
    result = context.fallback(text, run, context.typefaces)
    if result < 0 or result >= context.typefaces.len:
      raise newException(ValueError, "font fallback callback returned an invalid index")
    return
  for index, typeface in context.typefaces:
    if typeface.supportsRun(decoded, run):
      return index
  0

proc shapeParagraph*(
    font: Font, text: string, options = ParagraphOptions()
): ShapedParagraph =
  let analysis = analyzeBidi(text, options)
  result.baseDirection = analysis.baseDirection
  result.logicalRuns = newSeq[ShapedRun](analysis.runs.len)
  for index, run in analysis.runs:
    let shapeOptions = initShapeOptions(
      features = run.features,
      direction = run.direction,
      script = run.script,
      language = run.language,
      flags = options.flags,
      shapers = options.shapers,
      clusterLevel = options.clusterLevel,
    )
    result.logicalRuns[index] = shapeRun(font, text, run, shapeOptions)

  let visualIndices = visualOrderIndices(analysis.runs)
  result.visualRuns = newSeq[ShapedRun](visualIndices.len)
  for outputIndex, runIndex in visualIndices:
    result.visualRuns[outputIndex] = result.logicalRuns[runIndex]

proc shapeParagraph*(
    typeface: Typeface, text: string, options = ParagraphOptions()
): ShapedParagraph =
  shapeParagraph(typeface.font, text, options)

proc shapeParagraph*(context: ShapeContext, text: string): ShapedParagraph =
  let analysis = analyzeBidi(text, context.options)
  let decoded = decodeUtf8(text)
  result.baseDirection = analysis.baseDirection
  result.logicalRuns = newSeq[ShapedRun](analysis.runs.len)
  for index, run in analysis.runs:
    let typefaceIndex = context.selectTypefaceIndex(text, decoded, run)
    let shapeOptions = initShapeOptions(
      features = run.features,
      direction = run.direction,
      script = run.script,
      language = run.language,
      flags = context.options.flags,
      shapers = context.options.shapers,
      clusterLevel = context.options.clusterLevel,
    )
    result.logicalRuns[index] =
      shapeRun(context, text, run, typefaceIndex, shapeOptions)
    if result.logicalRuns[index].hasMissingGlyphs:
      for fallbackIndex, typeface in context.typefaces:
        if fallbackIndex != typefaceIndex and typeface.supportsRun(decoded, run):
          result.logicalRuns[index] =
            shapeRun(context, text, run, fallbackIndex, shapeOptions)
          break

  let visualIndices = visualOrderIndices(analysis.runs)
  result.visualRuns = newSeq[ShapedRun](visualIndices.len)
  for outputIndex, runIndex in visualIndices:
    result.visualRuns[outputIndex] = result.logicalRuns[runIndex]

func len*(run: GlyphRun): int =
  run.glyphs.len

iterator items*(run: GlyphRun): lent Glyph =
  for glyph in run.glyphs:
    yield glyph

func totalAdvance*(run: GlyphRun): Advance =
  for glyph in run.glyphs:
    result.x += glyph.xAdvance
    result.y += glyph.yAdvance

func len*(run: ShapedRun): int =
  run.glyphRun.len

iterator items*(run: ShapedRun): lent Glyph =
  for glyph in run.glyphRun:
    yield glyph

func len*(paragraph: ShapedParagraph): int =
  paragraph.visualRuns.len

iterator items*(paragraph: ShapedParagraph): lent ShapedRun =
  for run in paragraph.visualRuns:
    yield run

func totalAdvance*(run: ShapedRun): Advance =
  run.glyphRun.totalAdvance

func totalAdvance*(paragraph: ShapedParagraph): Advance =
  for run in paragraph.visualRuns:
    let advance = run.totalAdvance
    result.x += advance.x
    result.y += advance.y

func glyphRangeForByteRange*(run: ShapedRun, byteStart, byteEnd: int): GlyphRange =
  result.glyphStart = run.glyphRun.len
  result.glyphEnd = 0
  for index, glyph in run.glyphRun.glyphs:
    let cluster = int(glyph.cluster)
    if cluster >= byteStart and cluster < byteEnd:
      if index < result.glyphStart:
        result.glyphStart = index
      result.glyphEnd = index + 1
  if result.glyphStart == run.glyphRun.len:
    result.glyphStart = 0
    result.glyphEnd = 0

func glyphRangeForByte*(run: ShapedRun, byteOffset: int): GlyphRange =
  glyphRangeForByteRange(run, byteOffset, byteOffset + 1)

proc glyphRangeForCodepoint*(
    run: ShapedRun, text: string, codepointIndex: int
): GlyphRange =
  let decoded = decodeUtf8(text)
  if codepointIndex < run.textRun.codepointStart or
      codepointIndex >= run.textRun.codepointEnd or
      codepointIndex >= decoded.byteStarts.len:
    raise newException(ValueError, "codepoint index is outside the shaped run")
  glyphRangeForByteRange(
    run, decoded.byteStarts[codepointIndex], decoded.byteEnds[codepointIndex]
  )

func sameTextRun(a, b: TextRun): bool =
  a.byteStart == b.byteStart and a.byteEnd == b.byteEnd and
    a.codepointStart == b.codepointStart and a.codepointEnd == b.codepointEnd and
    a.level.levelValue == b.level.levelValue

proc logicalRunIndex*(paragraph: ShapedParagraph, visualIndex: int): int =
  if visualIndex < 0 or visualIndex >= paragraph.visualRuns.len:
    raise newException(ValueError, "visual run index is outside the paragraph")
  let run = paragraph.visualRuns[visualIndex].textRun
  for index, candidate in paragraph.logicalRuns:
    if candidate.textRun.sameTextRun(run):
      return index
  raise newException(ValueError, "visual run is not present in logical order")

proc visualRunIndex*(paragraph: ShapedParagraph, logicalIndex: int): int =
  if logicalIndex < 0 or logicalIndex >= paragraph.logicalRuns.len:
    raise newException(ValueError, "logical run index is outside the paragraph")
  let run = paragraph.logicalRuns[logicalIndex].textRun
  for index, candidate in paragraph.visualRuns:
    if candidate.textRun.sameTextRun(run):
      return index
  raise newException(ValueError, "logical run is not present in visual order")

proc logicalToVisualMap*(paragraph: ShapedParagraph): seq[int] =
  result = newSeq[int](paragraph.logicalRuns.len)
  for index in 0 ..< paragraph.logicalRuns.len:
    result[index] = paragraph.visualRunIndex(index)

proc visualToLogicalMap*(paragraph: ShapedParagraph): seq[int] =
  result = newSeq[int](paragraph.visualRuns.len)
  for index in 0 ..< paragraph.visualRuns.len:
    result[index] = paragraph.logicalRunIndex(index)

proc glyphRangeForByte*(
    paragraph: ShapedParagraph, byteOffset: int, visual = false
): RunGlyphRange =
  let runs = if visual: paragraph.visualRuns else: paragraph.logicalRuns
  for index, run in runs:
    if byteOffset >= run.textRun.byteStart and byteOffset < run.textRun.byteEnd:
      let glyphRange = run.glyphRangeForByte(byteOffset)
      return RunGlyphRange(
        runIndex: index,
        glyphStart: glyphRange.glyphStart,
        glyphEnd: glyphRange.glyphEnd,
      )
  raise newException(ValueError, "byte offset is outside the shaped paragraph")

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
  result.handle = raw.hb_subset_plan_execute_or_fail(plan.requireSubsetPlan)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset plan execution failed")
