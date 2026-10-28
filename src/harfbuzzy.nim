## Ergonomic HarfBuzz wrapper built on top of `harfbuzzy/raw`.

when not (defined(gcarc) or defined(gcorc) or defined(gcatomicarc)):
  {.
    error:
      "harfbuzzy requires --mm:arc, --mm:orc, or --mm:atomicArc for deterministic HarfBuzz handle destructors"
  .}

import harfbuzzy/[fribidi_raw, raw]

when not (defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)) or
    defined(harfbuzzyNoFribidi):
  export loadFribidi, FriBidiLoadError

when defined(harfbuzzRuntime) or (
  (defined(feature.harfbuzzy.runtime) or defined(features.harfbuzzy.runtime)) and
  not (defined(harfbuzzyStatic) or defined(features.harfbuzzy.static))
):
  export HarfBuzzLibrary, HarfBuzzLoadError, loadHarfbuzz, harfbuzzLibraryStem

type
  Blob* = object
    handle: ptr hb_blob_t

  Face* = object
    handle: ptr hb_face_t

  Font* = object
    handle: ptr hb_font_t

  Buffer* = object
    handle: ptr hb_buffer_t

  ShapePlan* = object
    handle: ptr hb_shape_plan_t

  Set* = object
    handle: ptr hb_set_t

  SubsetInput* = object
    handle: ptr hb_subset_input_t

  SubsetPlan* = object
    handle: ptr hb_subset_plan_t

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
  destroyHandle(x.handle, hb_blob_destroy)

proc `=wasMoved`(x: var Blob) =
  x.handle = nil

proc `=copy`(dest: var Blob, src: Blob) =
  copyHandle(dest.handle, src.handle, hb_blob_reference, hb_blob_destroy)

proc `=dup`(src: Blob): Blob =
  dupHandle(src, hb_blob_reference)

proc `=destroy`(x: Face) =
  destroyHandle(x.handle, hb_face_destroy)

proc `=wasMoved`(x: var Face) =
  x.handle = nil

proc `=copy`(dest: var Face, src: Face) =
  copyHandle(dest.handle, src.handle, hb_face_reference, hb_face_destroy)

proc `=dup`(src: Face): Face =
  dupHandle(src, hb_face_reference)

proc `=destroy`(x: Font) =
  destroyHandle(x.handle, hb_font_destroy)

proc `=wasMoved`(x: var Font) =
  x.handle = nil

proc `=copy`(dest: var Font, src: Font) =
  copyHandle(dest.handle, src.handle, hb_font_reference, hb_font_destroy)

proc `=dup`(src: Font): Font =
  dupHandle(src, hb_font_reference)

proc `=destroy`(x: Buffer) =
  destroyHandle(x.handle, hb_buffer_destroy)

proc `=wasMoved`(x: var Buffer) =
  x.handle = nil

proc `=copy`(dest: var Buffer, src: Buffer) =
  copyHandle(dest.handle, src.handle, hb_buffer_reference, hb_buffer_destroy)

proc `=dup`(src: Buffer): Buffer =
  dupHandle(src, hb_buffer_reference)

proc `=destroy`(x: ShapePlan) =
  destroyHandle(x.handle, hb_shape_plan_destroy)

proc `=wasMoved`(x: var ShapePlan) =
  x.handle = nil

proc `=copy`(dest: var ShapePlan, src: ShapePlan) =
  copyHandle(dest.handle, src.handle, hb_shape_plan_reference, hb_shape_plan_destroy)

proc `=dup`(src: ShapePlan): ShapePlan =
  dupHandle(src, hb_shape_plan_reference)

proc `=destroy`(x: Set) =
  destroyHandle(x.handle, hb_set_destroy)

proc `=wasMoved`(x: var Set) =
  x.handle = nil

proc `=copy`(dest: var Set, src: Set) =
  copyHandle(dest.handle, src.handle, hb_set_reference, hb_set_destroy)

proc `=dup`(src: Set): Set =
  dupHandle(src, hb_set_reference)

proc `=destroy`(x: SubsetInput) =
  destroyHandle(x.handle, hb_subset_input_destroy)

proc `=wasMoved`(x: var SubsetInput) =
  x.handle = nil

proc `=copy`(dest: var SubsetInput, src: SubsetInput) =
  copyHandle(
    dest.handle, src.handle, hb_subset_input_reference, hb_subset_input_destroy
  )

proc `=dup`(src: SubsetInput): SubsetInput =
  dupHandle(src, hb_subset_input_reference)

proc `=destroy`(x: SubsetPlan) =
  destroyHandle(x.handle, hb_subset_plan_destroy)

proc `=wasMoved`(x: var SubsetPlan) =
  x.handle = nil

proc `=copy`(dest: var SubsetPlan, src: SubsetPlan) =
  copyHandle(dest.handle, src.handle, hb_subset_plan_reference, hb_subset_plan_destroy)

proc `=dup`(src: SubsetPlan): SubsetPlan =
  dupHandle(src, hb_subset_plan_reference)

type
  Codepoint* = hb_codepoint_t
  Position* = hb_position_t

  Tag* = distinct hb_tag_t
  # Keep Nim move/reset operations independent of the native C enum type.
  Script* = distinct uint32
  Language* = distinct hb_language_t

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

  OutlinePoint* = object
    ## A point in the font's current scale, with Y increasing upwards.
    x*, y*: float32

  OutlineCommandKind* {.pure.} = enum ## An operation in a glyph's vector outline.
    moveTo
    lineTo
    quadraticTo
    cubicTo
    closePath

  OutlineCommand* = object ## A renderer-independent glyph outline operation.
    kind*: OutlineCommandKind
    to*: OutlinePoint ## Destination for all operations except `closePath`.
    control1*: OutlinePoint ## Control point for quadratic and cubic curves.
    control2*: OutlinePoint ## Second control point for cubic curves only.

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

  BidiMode* {.pure.} = enum
    ## Select paragraph direction analysis.
    fribidi ## Resolve mixed-direction text with FriBidi.
    singleDirection ## Assume the entire paragraph has the specified direction.

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
    bidiMode*: BidiMode
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
  versionMajor* = HB_VERSION_MAJOR
  versionMinor* = HB_VERSION_MINOR
  versionMicro* = HB_VERSION_MICRO
  versionHeaderString* = HB_VERSION_STRING
  featureGlobalStart* = uint32(HB_FEATURE_GLOBAL_START)
  featureGlobalEnd* = uint32(HB_FEATURE_GLOBAL_END)
  scriptCommon* = Script(HB_SCRIPT_COMMON)
  scriptInherited* = Script(HB_SCRIPT_INHERITED)
  scriptUnknown* = Script(HB_SCRIPT_UNKNOWN)
  scriptArabic* = Script(HB_SCRIPT_ARABIC)
  scriptDevanagari* = Script(HB_TAG('D', 'e', 'v', 'a'))
  scriptEmoji* = Script(HB_TAG('Z', 's', 'y', 'e'))
  scriptHebrew* = Script(HB_TAG('H', 'e', 'b', 'r'))
  scriptLatin* = Script(HB_SCRIPT_LATIN)
  scriptInvalid* = Script(HB_SCRIPT_INVALID)
  languageInvalid* = Language(HB_LANGUAGE_INVALID)
  tableGsub* = Tag(HB_OT_TAG_GSUB)
  tableGpos* = Tag(HB_OT_TAG_GPOS)

func toRaw(direction: Direction): hb_direction_t =
  cast[hb_direction_t](cuint(ord(direction)))

func toDirection(direction: hb_direction_t): Direction =
  case cuint(direction)
  of cuint(HB_DIRECTION_LTR): Direction.ltr
  of cuint(HB_DIRECTION_RTL): Direction.rtl
  of cuint(HB_DIRECTION_TTB): Direction.ttb
  of cuint(HB_DIRECTION_BTT): Direction.btt
  else: Direction.invalid

func toRaw(script: Script): hb_script_t =
  cast[hb_script_t](script)

func toScript(script: hb_script_t): Script =
  cast[Script](script)

func toRaw(flags: BufferFlags): hb_buffer_flags_t =
  result = HB_BUFFER_FLAG_DEFAULT
  if beginningOfText in flags:
    result = result or HB_BUFFER_FLAG_BOT
  if endOfText in flags:
    result = result or HB_BUFFER_FLAG_EOT
  if preserveDefaultIgnorables in flags:
    result = result or HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES
  if removeDefaultIgnorables in flags:
    result = result or HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES
  if doNotInsertDottedCircle in flags:
    result = result or HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE
  if verify in flags:
    result = result or HB_BUFFER_FLAG_VERIFY
  if produceUnsafeToConcat in flags:
    result = result or HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT
  if produceSafeToInsertTatweel in flags:
    result = result or HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL

func toFlags(flags: hb_buffer_flags_t): BufferFlags =
  if flags.contains(HB_BUFFER_FLAG_BOT):
    result.incl beginningOfText
  if flags.contains(HB_BUFFER_FLAG_EOT):
    result.incl endOfText
  if flags.contains(HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES):
    result.incl preserveDefaultIgnorables
  if flags.contains(HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES):
    result.incl removeDefaultIgnorables
  if flags.contains(HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE):
    result.incl doNotInsertDottedCircle
  if flags.contains(HB_BUFFER_FLAG_VERIFY):
    result.incl verify
  if flags.contains(HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT):
    result.incl produceUnsafeToConcat
  if flags.contains(HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL):
    result.incl produceSafeToInsertTatweel

func toRaw(level: ClusterLevel): hb_buffer_cluster_level_t =
  case level
  of ClusterLevel.monotoneGraphemes: HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
  of ClusterLevel.monotoneCharacters: HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
  of ClusterLevel.characters: HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
  of ClusterLevel.graphemes: HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES

func toClusterLevel(level: hb_buffer_cluster_level_t): ClusterLevel =
  case cuint(level)
  of cuint(HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS):
    ClusterLevel.monotoneCharacters
  of cuint(HB_BUFFER_CLUSTER_LEVEL_CHARACTERS):
    ClusterLevel.characters
  of cuint(HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES):
    ClusterLevel.graphemes
  else:
    ClusterLevel.monotoneGraphemes

func toRaw(flags: SerializeFlags): hb_buffer_serialize_flags_t =
  result = HB_BUFFER_SERIALIZE_FLAG_DEFAULT
  if noClusters in flags:
    result = result or HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS
  if noPositions in flags:
    result = result or HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS
  if noGlyphNames in flags:
    result = result or HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES
  if glyphExtents in flags:
    result = result or HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS
  if glyphFlags in flags:
    result = result or HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS
  if noAdvances in flags:
    result = result or HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES

func toRaw(format: SerializeFormat): hb_buffer_serialize_format_t =
  case format
  of SerializeFormat.text: HB_BUFFER_SERIALIZE_FORMAT_TEXT
  of SerializeFormat.json: HB_BUFFER_SERIALIZE_FORMAT_JSON

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

proc requireBlob(blob: Blob): ptr hb_blob_t =
  if blob.handle == nil:
    raise newException(ValueError, "HarfBuzz blob is uninitialized")
  blob.handle

proc requireFace(face: Face): ptr hb_face_t =
  if face.handle == nil:
    raise newException(ValueError, "HarfBuzz face is uninitialized")
  face.handle

proc requireFont(font: Font): ptr hb_font_t =
  if font.handle == nil:
    raise newException(ValueError, "HarfBuzz font is uninitialized")
  font.handle

proc requireBuffer(buffer: Buffer): ptr hb_buffer_t =
  if buffer.handle == nil:
    raise newException(ValueError, "HarfBuzz buffer is uninitialized")
  buffer.handle

proc requirePlan(plan: ShapePlan): ptr hb_shape_plan_t =
  if plan.handle == nil:
    raise newException(ValueError, "HarfBuzz shape plan is uninitialized")
  plan.handle

proc requireSet(set: Set): ptr hb_set_t =
  if set.handle == nil:
    raise newException(ValueError, "HarfBuzz set is uninitialized")
  set.handle

proc requireInput(input: SubsetInput): ptr hb_subset_input_t =
  if input.handle == nil:
    raise newException(ValueError, "HarfBuzz subset input is uninitialized")
  input.handle

proc requireSubsetPlan(plan: SubsetPlan): ptr hb_subset_plan_t =
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

proc boolValue(value: hb_bool_t): bool =
  value != 0

proc fromCString(p: cstring): string =
  if p == nil:
    ""
  else:
    $p

proc versionString*(): string =
  fromCString(hb_version_string())

proc version*(): Version =
  var major, minor, micro: cuint
  hb_version(addr major, addr minor, addr micro)
  Version(major: int(major), minor: int(minor), micro: int(micro))

proc versionAtLeast*(major, minor, micro: Natural): bool =
  hb_version_atleast(
    checkedCuint(major, "major version"),
    checkedCuint(minor, "minor version"),
    checkedCuint(micro, "micro version"),
  ).boolValue

proc toTag*(value: string): Tag =
  if value.len == 0 or value.len > 4:
    raise newException(ValueError, "HarfBuzz tags must contain 1 to 4 bytes")
  Tag(hb_tag_from_string(value.cstring, checkedCint(value.len, "tag length")))

proc `$`*(tag: Tag): string =
  var buf: array[4, cchar]
  hb_tag_to_string(hb_tag_t(tag), cast[cstring](addr buf[0]))
  result = newString(4)
  for i in 0 ..< 4:
    result[i] = char(buf[i])

proc toScript*(value: string): Script =
  if value.len == 0:
    raise newException(ValueError, "script string is empty")
  hb_script_from_string(value.cstring, checkedCint(value.len, "script length")).toScript

proc scriptToTag*(script: Script): Tag =
  Tag(hb_script_to_iso15924_tag(script.toRaw))

proc horizontalDirection*(script: Script): Direction =
  hb_script_get_horizontal_direction(script.toRaw).toDirection

proc `$`*(script: Script): string =
  $script.scriptToTag

proc toLanguage*(value: string): Language =
  if value.len == 0:
    raise newException(ValueError, "language string is empty")
  Language(
    hb_language_from_string(value.cstring, checkedCint(value.len, "language length"))
  )

proc defaultLanguage*(): Language =
  Language(hb_language_get_default())

proc matches*(language, specific: Language): bool =
  hb_language_matches(hb_language_t(language), hb_language_t(specific)).boolValue

proc `$`*(language: Language): string =
  fromCString(hb_language_to_string(hb_language_t(language)))

proc toDirection*(value: string): Direction =
  if value.len == 0:
    raise newException(ValueError, "direction string is empty")
  let direction =
    hb_direction_from_string(value.cstring, checkedCint(value.len, "direction length"))
  if not direction.hb_direction_is_valid:
    raise newException(ValueError, "invalid HarfBuzz direction: " & value)
  direction.toDirection

proc `$`*(direction: Direction): string =
  fromCString(hb_direction_to_string(direction.toRaw))

proc isHorizontal*(direction: Direction): bool =
  hb_direction_is_horizontal(direction.toRaw)

proc isVertical*(direction: Direction): bool =
  hb_direction_is_vertical(direction.toRaw)

proc reverse*(direction: Direction): Direction =
  hb_direction_reverse(direction.toRaw).toDirection

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
  var feature: hb_feature_t
  if hb_feature_from_string(
    value.cstring, checkedCint(value.len, "feature length"), addr feature
  ).boolValue:
    Feature(
      tag: Tag(feature.tag),
      value: feature.value,
      start: uint32(feature.start),
      ending: uint32(feature.`end`),
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
    bidiMode = BidiMode.fribidi,
): ParagraphOptions =
  ParagraphOptions(
    bidiMode: bidiMode,
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

func isEmojiCodepoint(codepoint: Codepoint): bool =
  codepoint in 0x1F000'u32 .. 0x1FAFF'u32 or codepoint in 0x1FC00'u32 .. 0x1FFFF'u32 or
    codepoint in 0x2600'u32 .. 0x27BF'u32

func shouldSetScript(script: Script): bool =
  script.toRaw != HB_SCRIPT_INVALID and script.toRaw != HB_SCRIPT_UNKNOWN

proc scriptFor*(codepoint: Codepoint): Script =
  if codepoint.isEmojiCodepoint:
    return scriptEmoji
  hb_unicode_script(hb_unicode_funcs_get_default(), hb_codepoint_t(codepoint)).toScript

func scriptIsNeutral(script: Script): bool =
  let value = script.toRaw
  value in [HB_SCRIPT_INVALID, HB_SCRIPT_UNKNOWN, HB_SCRIPT_COMMON, HB_SCRIPT_INHERITED]

proc inferScript(text: openArray[Codepoint], first, last: int): Script =
  for index in first ..< last:
    let script = scriptFor(text[index])
    if script.toRaw != HB_SCRIPT_UNKNOWN:
      return script
  scriptUnknown

proc defaultLanguageForScript*(script: Script): Language =
  if script.toRaw == HB_SCRIPT_ARABIC:
    toLanguage("ar")
  elif script.toRaw == scriptDevanagari.toRaw:
    toLanguage("hi")
  elif script.toRaw == scriptHebrew.toRaw:
    toLanguage("he")
  elif script.toRaw == HB_SCRIPT_LATIN:
    toLanguage("en")
  else:
    defaultLanguage()

proc analyzeBidi(text: string, options: ParagraphOptions): BidiAnalysis =
  let decoded = decodeUtf8(text)
  if options.bidiMode == BidiMode.singleDirection and
      options.baseDirection == ParagraphDirection.autoDetect:
    raise newException(
      ValueError, "single-direction paragraphs require an explicit direction"
    )
  if decoded.codepoints.len == 0:
    result.baseDirection =
      if options.baseDirection == ParagraphDirection.rtl:
        Direction.rtl
      else:
        Direction.ltr
    return

  var levels = newSeq[fribidi_raw.FriBidiLevel](decoded.codepoints.len)
  if options.bidiMode == BidiMode.singleDirection:
    result.baseDirection =
      if options.baseDirection == ParagraphDirection.rtl:
        Direction.rtl
      else:
        Direction.ltr
    if result.baseDirection == Direction.rtl:
      for level in levels.mitems:
        level = 1
  else:
    when not (defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)) or
        defined(harfbuzzyNoFribidi):
      if fribidi_raw.fribidi_get_bidi_types == nil:
        raise
          newException(FriBidiLoadError, "FriBidi is not loaded; call loadFribidi()")

    let length = checkedCint(decoded.codepoints.len, "codepoint count")
    var bidiTypes = newSeq[fribidi_raw.FriBidiCharType](decoded.codepoints.len)
    var bracketTypes = newSeq[fribidi_raw.FriBidiBracketType](decoded.codepoints.len)
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
      if runScript.scriptIsNeutral:
        runScript = nextScript
      elif not nextScript.scriptIsNeutral and nextScript.toRaw != runScript.toRaw:
        break
      inc last
    if runScript.toRaw == HB_SCRIPT_UNKNOWN:
      runScript = inferScript(decoded.codepoints, first, last)
    let language =
      if hb_language_t(options.language) != HB_LANGUAGE_INVALID:
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

proc toRaw(feature: Feature): hb_feature_t =
  hb_feature_t(
    tag: hb_tag_t(feature.tag),
    value: feature.value,
    start: cuint(feature.start),
    `end`: cuint(feature.ending),
  )

proc toRaw(variation: Variation): hb_variation_t =
  hb_variation_t(tag: hb_tag_t(variation.tag), value: cfloat(variation.value))

proc `$`*(feature: Feature): string =
  var rawFeature = feature.toRaw
  var buf: array[128, cchar]
  hb_feature_to_string(addr rawFeature, cast[cstring](addr buf[0]), cuint(buf.len))
  fromCString(cast[cstring](addr buf[0]))

proc initBlob*(data: string): Blob =
  let length = checkedCuint(data.len, "blob length")
  let dataPtr =
    if data.len == 0:
      cast[cstring](nil)
    else:
      data.cstring
  result.handle = hb_blob_create(dataPtr, length, HB_MEMORY_MODE_DUPLICATE, nil, nil)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz blob")

proc initBlob*(data: openArray[byte]): Blob =
  let length = checkedCuint(data.len, "blob length")
  let dataPtr =
    if data.len == 0:
      cast[cstring](nil)
    else:
      cast[cstring](unsafeAddr data[0])
  result.handle = hb_blob_create(dataPtr, length, HB_MEMORY_MODE_DUPLICATE, nil, nil)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz blob")

proc blobFromFile*(path: string): Blob =
  if path.len == 0:
    raise newException(ValueError, "font path is empty")
  result.handle = hb_blob_create_from_file(path.cstring)
  if result.handle == nil or hb_blob_get_length(result.handle) == 0:
    raise newException(IOError, "could not read HarfBuzz blob from " & path)

proc subBlob*(blob: Blob, offset, length: Natural): Blob =
  result.handle = hb_blob_create_sub_blob(
    blob.requireBlob,
    checkedCuint(offset, "blob offset"),
    checkedCuint(length, "blob length"),
  )
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz sub-blob")

proc len*(blob: Blob): int =
  int(hb_blob_get_length(blob.requireBlob))

proc data*(blob: Blob): string =
  var length: cuint
  let dataPtr = hb_blob_get_data(blob.requireBlob, addr length)
  let n = int(length)
  result = newString(n)
  if n > 0:
    if dataPtr == nil:
      raise newException(ValueError, "HarfBuzz returned null blob data")
    copyMem(addr result[0], dataPtr, n)

proc makeImmutable*(blob: var Blob) =
  hb_blob_make_immutable(blob.requireBlob)

proc isImmutable*(blob: Blob): bool =
  hb_blob_is_immutable(blob.requireBlob).boolValue

proc faceCount*(blob: Blob): int =
  int(hb_face_count(blob.requireBlob))

proc initFace*(blob: Blob, index: Natural = 0): Face =
  result.handle = hb_face_create(blob.requireBlob, checkedCuint(index, "face index"))
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz face")

proc faceFromFile*(path: string, index: Natural = 0): Face =
  if path.len == 0:
    raise newException(ValueError, "font path is empty")
  result = initFace(blobFromFile(path), index)

proc referenceBlob*(face: Face): Blob =
  result.handle = hb_face_reference_blob(face.requireFace)
  if result.handle == nil:
    raise newException(ValueError, "could not reference HarfBuzz face blob")

proc referenceTable*(face: Face, tag: Tag): Blob =
  result.handle = hb_face_reference_table(face.requireFace, hb_tag_t(tag))
  if result.handle == nil:
    raise newException(ValueError, "could not reference HarfBuzz face table")

proc index*(face: Face): int =
  int(hb_face_get_index(face.requireFace))

proc upem*(face: Face): int =
  int(hb_face_get_upem(face.requireFace))

proc glyphCount*(face: Face): int =
  int(hb_face_get_glyph_count(face.requireFace))

proc hasAatSubstitution*(face: Face): bool =
  hb_aat_layout_has_substitution(face.requireFace).boolValue

proc hasAatPositioning*(face: Face): bool =
  hb_aat_layout_has_positioning(face.requireFace).boolValue

proc hasAatTracking*(face: Face): bool =
  hb_aat_layout_has_tracking(face.requireFace).boolValue

proc hasOpenTypeSubstitution*(face: Face): bool =
  hb_ot_layout_has_substitution(face.requireFace).boolValue

proc hasOpenTypePositioning*(face: Face): bool =
  hb_ot_layout_has_positioning(face.requireFace).boolValue

proc layoutFeatureTags*(face: Face, tableTag: Tag): seq[Tag] =
  const chunkSize = 64
  var start: cuint
  while true:
    var count = cuint(chunkSize)
    var tags = newSeq[hb_tag_t](chunkSize)
    let fetched = hb_ot_layout_table_get_feature_tags(
      face.requireFace, hb_tag_t(tableTag), start, addr count, addr tags[0]
    )
    for i in 0 ..< int(count):
      result.add Tag(tags[i])
    if fetched == 0 or count < chunkSize:
      break
    start += count

proc layoutFeatureTags*(face: Face, tableTag: Tag, script: Script): seq[Tag] =
  var scriptIndex: cuint
  if not hb_ot_layout_table_find_script(
    face.requireFace,
    hb_tag_t(tableTag),
    hb_script_to_iso15924_tag(script.toRaw),
    addr scriptIndex,
  ).boolValue:
    return

  const chunkSize = 64
  var start: cuint
  while true:
    var count = cuint(chunkSize)
    var tags = newSeq[hb_tag_t](chunkSize)
    let fetched = hb_ot_layout_language_get_feature_tags(
      face.requireFace,
      hb_tag_t(tableTag),
      scriptIndex,
      HB_OT_LAYOUT_DEFAULT_LANGUAGE_INDEX,
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
  result.handle = hb_font_create(face.requireFace)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz font")
  if useOpenTypeFuncs:
    hb_ot_font_set_funcs(result.handle)

proc face*(font: Font): Face =
  result.handle = hb_font_get_face(font.requireFont)
  if result.handle != nil:
    discard hb_face_reference(result.handle)

proc setScale*(font: var Font, x, y: int) =
  hb_font_set_scale(
    font.requireFont, checkedCint(x, "x scale"), checkedCint(y, "y scale")
  )

proc scale*(font: Font): Scale =
  var x, y: cint
  hb_font_get_scale(font.requireFont, addr x, addr y)
  Scale(x: int(x), y: int(y))

proc setPpem*(font: var Font, x, y: Natural) =
  hb_font_set_ppem(
    font.requireFont, checkedCuint(x, "x ppem"), checkedCuint(y, "y ppem")
  )

proc ppem*(font: Font): Ppem =
  var x, y: cuint
  hb_font_get_ppem(font.requireFont, addr x, addr y)
  Ppem(x: uint(x), y: uint(y))

proc setVariations*(font: var Font, variations: openArray[Variation]) =
  if variations.len == 0:
    hb_font_set_variations(font.requireFont, nil, 0)
    return

  var rawVariations = newSeq[hb_variation_t](variations.len)
  for i, variation in variations:
    rawVariations[i] = variation.toRaw
  hb_font_set_variations(
    font.requireFont,
    addr rawVariations[0],
    checkedCuint(rawVariations.len, "variation count"),
  )

proc horizontalExtents*(font: Font): FontExtents =
  var extents: hb_font_extents_t
  if not hb_font_get_h_extents(font.requireFont, addr extents).boolValue:
    raise newException(ValueError, "font has no horizontal extents")
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.line_gap
  )

proc verticalExtents*(font: Font): FontExtents =
  var extents: hb_font_extents_t
  if not hb_font_get_v_extents(font.requireFont, addr extents).boolValue:
    raise newException(ValueError, "font has no vertical extents")
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.line_gap
  )

proc extents*(font: Font, direction: Direction): FontExtents =
  var extents: hb_font_extents_t
  hb_font_get_extents_for_direction(font.requireFont, direction.toRaw, addr extents)
  FontExtents(
    ascender: extents.ascender, descender: extents.descender, lineGap: extents.line_gap
  )

func lineAdvance*(extents: FontExtents): Position =
  extents.ascender - extents.descender + extents.lineGap

proc nominalGlyph*(font: Font, codepoint: Codepoint): Codepoint =
  if not hb_font_get_nominal_glyph(font.requireFont, codepoint, addr result).boolValue:
    raise newException(ValueError, "font has no glyph for codepoint " & $codepoint)

proc glyph*(
    font: Font, codepoint: Codepoint, variationSelector: Codepoint = 0
): Codepoint =
  if not hb_font_get_glyph(font.requireFont, codepoint, variationSelector, addr result).boolValue:
    raise newException(ValueError, "font has no glyph for codepoint " & $codepoint)

proc hasGlyph*(
    font: Font, codepoint: Codepoint, variationSelector: Codepoint = 0
): bool =
  var glyph: Codepoint

  hb_font_get_glyph(font.requireFont, codepoint, variationSelector, addr glyph).boolValue and
    glyph != 0

proc horizontalAdvance*(font: Font, glyph: Codepoint): Position =
  hb_font_get_glyph_h_advance(font.requireFont, glyph)

proc verticalAdvance*(font: Font, glyph: Codepoint): Position =
  hb_font_get_glyph_v_advance(font.requireFont, glyph)

proc advance*(font: Font, glyph: Codepoint, direction: Direction): Advance =
  hb_font_get_glyph_advance_for_direction(
    font.requireFont, glyph, direction.toRaw, addr result.x, addr result.y
  )

proc glyphExtents*(font: Font, glyph: Codepoint): GlyphExtents =
  var extents: hb_glyph_extents_t
  if not hb_font_get_glyph_extents(font.requireFont, glyph, addr extents).boolValue:
    raise newException(ValueError, "font has no extents for glyph " & $glyph)
  GlyphExtents(
    xBearing: extents.x_bearing,
    yBearing: extents.y_bearing,
    width: extents.width,
    height: extents.height,
  )

proc glyphOutline*(font: Font, glyph: Codepoint): seq[OutlineCommand] =
  ## Returns a glyph's contours as move, line, curve, and close operations.
  ## Coordinates use the font's current scale and variations, with Y upwards.
  ## A whitespace or outline-less glyph returns an empty sequence. Glyph zero
  ## selects the font's `.notdef` glyph. Requires HarfBuzz 7.0 or newer.
  ## Raises `ValueError` for an uninitialized font or draw-function allocation
  ## failure. The returned commands own their data independently of the font.
  let handle = font.requireFont
  if not versionAtLeast(7, 0, 0):
    raise newException(ValueError, "glyph outlines require HarfBuzz 7.0 or newer")

  type OutlineState = object
    commands: seq[OutlineCommand]
    error: ref Exception

  proc appendCommand(data: pointer, command: OutlineCommand) {.nimcall, raises: [].} =
    let state = cast[ptr OutlineState](data)
    if state.error == nil:
      try:
        state.commands.add command
      except Exception as error:
        # Never unwind a Nim exception through HarfBuzz's C stack.
        state.error = error

  proc moveTo(
      funcs: ptr hb_draw_funcs_t,
      data: pointer,
      state: ptr hb_draw_state_t,
      x, y: cfloat,
      userData: pointer,
  ) {.cdecl, raises: [].} =
    appendCommand(
      data,
      OutlineCommand(kind: OutlineCommandKind.moveTo, to: OutlinePoint(x: x, y: y)),
    )

  proc lineTo(
      funcs: ptr hb_draw_funcs_t,
      data: pointer,
      state: ptr hb_draw_state_t,
      x, y: cfloat,
      userData: pointer,
  ) {.cdecl, raises: [].} =
    appendCommand(
      data,
      OutlineCommand(kind: OutlineCommandKind.lineTo, to: OutlinePoint(x: x, y: y)),
    )

  proc quadraticTo(
      funcs: ptr hb_draw_funcs_t,
      data: pointer,
      state: ptr hb_draw_state_t,
      controlX, controlY, x, y: cfloat,
      userData: pointer,
  ) {.cdecl, raises: [].} =
    appendCommand(
      data,
      OutlineCommand(
        kind: OutlineCommandKind.quadraticTo,
        to: OutlinePoint(x: x, y: y),
        control1: OutlinePoint(x: controlX, y: controlY),
      ),
    )

  proc cubicTo(
      funcs: ptr hb_draw_funcs_t,
      data: pointer,
      state: ptr hb_draw_state_t,
      control1X, control1Y, control2X, control2Y, x, y: cfloat,
      userData: pointer,
  ) {.cdecl, raises: [].} =
    appendCommand(
      data,
      OutlineCommand(
        kind: OutlineCommandKind.cubicTo,
        to: OutlinePoint(x: x, y: y),
        control1: OutlinePoint(x: control1X, y: control1Y),
        control2: OutlinePoint(x: control2X, y: control2Y),
      ),
    )

  proc closePath(
      funcs: ptr hb_draw_funcs_t,
      data: pointer,
      state: ptr hb_draw_state_t,
      userData: pointer,
  ) {.cdecl, raises: [].} =
    appendCommand(data, OutlineCommand(kind: OutlineCommandKind.closePath))

  let funcs = hb_draw_funcs_create()
  if funcs == nil:
    raise newException(ValueError, "could not create HarfBuzz draw functions")
  defer:
    hb_draw_funcs_destroy(funcs)
  hb_draw_funcs_set_move_to_func(funcs, moveTo, nil, nil)
  hb_draw_funcs_set_line_to_func(funcs, lineTo, nil, nil)
  hb_draw_funcs_set_quadratic_to_func(funcs, quadraticTo, nil, nil)
  hb_draw_funcs_set_cubic_to_func(funcs, cubicTo, nil, nil)
  hb_draw_funcs_set_close_path_func(funcs, closePath, nil, nil)
  hb_draw_funcs_make_immutable(funcs)
  var state: OutlineState
  hb_font_draw_glyph(handle, glyph, funcs, addr state)
  if state.error != nil:
    raise state.error
  result = move(state.commands)

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
  result.handle = hb_buffer_create()
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz buffer")

proc similar*(buffer: Buffer): Buffer =
  result.handle = hb_buffer_create_similar(buffer.requireBuffer)
  if result.handle == nil:
    raise newException(ValueError, "could not create similar HarfBuzz buffer")

proc reset*(buffer: var Buffer) =
  hb_buffer_reset(buffer.requireBuffer)

proc clear*(buffer: var Buffer) =
  hb_buffer_clear_contents(buffer.requireBuffer)

proc len*(buffer: Buffer): int =
  int(hb_buffer_get_length(buffer.requireBuffer))

proc setDirection*(buffer: var Buffer, direction: Direction) =
  hb_buffer_set_direction(buffer.requireBuffer, direction.toRaw)

proc direction*(buffer: Buffer): Direction =
  hb_buffer_get_direction(buffer.requireBuffer).toDirection

proc setScript*(buffer: var Buffer, script: Script) =
  hb_buffer_set_script(buffer.requireBuffer, script.toRaw)

proc script*(buffer: Buffer): Script =
  hb_buffer_get_script(buffer.requireBuffer).toScript

proc setLanguage*(buffer: var Buffer, language: Language) =
  hb_buffer_set_language(buffer.requireBuffer, hb_language_t(language))

proc language*(buffer: Buffer): Language =
  Language(hb_buffer_get_language(buffer.requireBuffer))

proc guessSegmentProperties*(buffer: var Buffer) =
  hb_buffer_guess_segment_properties(buffer.requireBuffer)

proc setFlags*(buffer: var Buffer, flags: BufferFlags) =
  hb_buffer_set_flags(buffer.requireBuffer, flags.toRaw)

proc flags*(buffer: Buffer): BufferFlags =
  hb_buffer_get_flags(buffer.requireBuffer).toFlags

proc setClusterLevel*(buffer: var Buffer, level: ClusterLevel) =
  hb_buffer_set_cluster_level(buffer.requireBuffer, level.toRaw)

proc clusterLevel*(buffer: Buffer): ClusterLevel =
  hb_buffer_get_cluster_level(buffer.requireBuffer).toClusterLevel

proc add*(buffer: var Buffer, codepoint: Codepoint, cluster: Natural = 0) =
  hb_buffer_add(buffer.requireBuffer, codepoint, checkedCuint(cluster, "cluster"))

proc addUtf8*(buffer: var Buffer, text: string) =
  let length = checkedCint(text.len, "text length")
  hb_buffer_add_utf8(buffer.requireBuffer, text.cstring, length, 0, length)

proc addCodepoints*(buffer: var Buffer, text: openArray[Codepoint]) =
  let length = checkedCint(text.len, "codepoint count")
  let textPtr =
    if text.len == 0:
      cast[ptr Codepoint](nil)
    else:
      unsafeAddr text[0]
  hb_buffer_add_codepoints(buffer.requireBuffer, textPtr, length, 0, length)

proc glyphInfos*(buffer: Buffer): seq[GlyphInfo] =
  var length: cuint
  let infos = cast[ptr UncheckedArray[hb_glyph_info_t]](hb_buffer_get_glyph_infos(
    buffer.requireBuffer, addr length
  ))
  result = newSeq[GlyphInfo](int(length))
  if result.len > 0 and infos == nil:
    raise newException(ValueError, "HarfBuzz returned null glyph info data")
  for i in 0 ..< result.len:
    result[i] = GlyphInfo(
      codepoint: infos[i].codepoint,
      cluster: infos[i].cluster,
      flags: infos[i].mask and uint32(HB_GLYPH_FLAG_DEFINED),
    )

proc glyphPositions*(buffer: Buffer): seq[GlyphPosition] =
  var length: cuint
  let positions = cast[ptr UncheckedArray[hb_glyph_position_t]](hb_buffer_get_glyph_positions(
    buffer.requireBuffer, addr length
  ))
  result = newSeq[GlyphPosition](int(length))
  if result.len > 0 and positions == nil:
    raise newException(ValueError, "HarfBuzz returned null glyph position data")
  for i in 0 ..< result.len:
    result[i] = GlyphPosition(
      xAdvance: positions[i].x_advance,
      yAdvance: positions[i].y_advance,
      xOffset: positions[i].x_offset,
      yOffset: positions[i].y_offset,
    )

proc hasPositions*(buffer: Buffer): bool =
  hb_buffer_has_positions(buffer.requireBuffer).boolValue

proc availableSerializeFormats*(): seq[string] =
  let formats = cast[cstringArray](hb_buffer_serialize_list_formats())
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
    let serialized = hb_buffer_serialize_glyphs(
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
  if hb_language_t(options.language) != HB_LANGUAGE_INVALID:
    buffer.setLanguage(options.language)
  if options.flags != {}:
    buffer.setFlags(options.flags)
  buffer.setClusterLevel(options.clusterLevel)
  buffer.guessSegmentProperties()

proc shape*(font: Font, buffer: var Buffer, features: openArray[Feature] = []) =
  if features.len == 0:
    hb_shape(font.requireFont, buffer.requireBuffer, nil, 0)
  else:
    var rawFeatures = newSeq[hb_feature_t](features.len)
    for i, feature in features:
      rawFeatures[i] = feature.toRaw
    hb_shape(
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

  var rawFeatures = newSeq[hb_feature_t](features.len)
  for i, feature in features:
    rawFeatures[i] = feature.toRaw
  let shaperList = allocCStringArray(shapers)
  try:
    let featurePtr =
      if rawFeatures.len == 0:
        cast[ptr hb_feature_t](nil)
      else:
        addr rawFeatures[0]
    if not hb_shape_full(
      font.requireFont,
      buffer.requireBuffer,
      featurePtr,
      checkedCuint(rawFeatures.len, "feature count"),
      cast[ptr cstring](shaperList),
    ).boolValue:
      raise newException(ValueError, "HarfBuzz could not shape with requested shapers")
  finally:
    deallocCStringArray(shaperList)

proc availableShapers*(): seq[string] =
  let shapers = cast[cstringArray](hb_shape_list_shapers())
  if shapers == nil:
    return
  var index = 0
  while shapers[index] != nil:
    result.add $shapers[index]
    inc index

proc initShapePlan*(face: Face, options: ShapeOptions, cached = true): ShapePlan =
  var props = hb_segment_properties_t(
    direction: (
      if options.direction == Direction.invalid: Direction.ltr else: options.direction
    ).toRaw,
    script: (
      if options.script.toRaw == HB_SCRIPT_INVALID:
        HB_SCRIPT_UNKNOWN
      else:
        options.script.toRaw
    ),
    language: (
      if hb_language_t(options.language) == HB_LANGUAGE_INVALID:
        hb_language_t(defaultLanguage())
      else:
        hb_language_t(options.language)
    ),
    reserved1: nil,
    reserved2: nil,
  )
  var rawFeatures = newSeq[hb_feature_t](options.features.len)
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
        cast[ptr hb_feature_t](nil)
      else:
        addr rawFeatures[0]
    result.handle =
      if cached:
        hb_shape_plan_create_cached(
          face.requireFace,
          addr props,
          featurePtr,
          checkedCuint(rawFeatures.len, "feature count"),
          cast[ptr cstring](shaperList),
        )
      else:
        hb_shape_plan_create(
          face.requireFace,
          addr props,
          featurePtr,
          checkedCuint(rawFeatures.len, "feature count"),
          cast[ptr cstring](shaperList),
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
  var rawFeatures = newSeq[hb_feature_t](features.len)
  for i, feature in features:
    rawFeatures[i] = feature.toRaw
  let featurePtr =
    if rawFeatures.len == 0:
      cast[ptr hb_feature_t](nil)
    else:
      addr rawFeatures[0]
  if not hb_shape_plan_execute(
    plan.requirePlan,
    font.requireFont,
    buffer.requireBuffer,
    featurePtr,
    checkedCuint(rawFeatures.len, "feature count"),
  ).boolValue:
    raise newException(ValueError, "HarfBuzz shape plan execution failed")

proc shaper*(plan: ShapePlan): string =
  fromCString(hb_shape_plan_get_shaper(plan.requirePlan))

proc toGlyphRun*(buffer: Buffer): GlyphRun =
  var infoLength: cuint
  let infos = cast[ptr UncheckedArray[hb_glyph_info_t]](hb_buffer_get_glyph_infos(
    buffer.requireBuffer, addr infoLength
  ))
  var positionLength: cuint
  let positions = cast[ptr UncheckedArray[hb_glyph_position_t]](hb_buffer_get_glyph_positions(
    buffer.requireBuffer, addr positionLength
  ))

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
      flags: infos[i].mask and uint32(HB_GLYPH_FLAG_DEFINED),
      xAdvance: positions[i].x_advance,
      yAdvance: positions[i].y_advance,
      xOffset: positions[i].x_offset,
      yOffset: positions[i].y_offset,
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
  if hb_language_t(run.language) != HB_LANGUAGE_INVALID:
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

proc codepointNeedsGlyph(codepoint: Codepoint): bool =
  not (
    codepoint == 0x0009'u32 or codepoint == 0x000A'u32 or codepoint == 0x000D'u32 or
    codepoint == 0x0020'u32 or codepoint == 0x200C'u32 or codepoint == 0x200D'u32 or
    codepoint in 0xFE00'u32 .. 0xFE0F'u32 or codepoint in 0xE0100'u32 .. 0xE01EF'u32 or
    codepoint.scriptFor.toRaw == HB_SCRIPT_INHERITED
  )

proc supportsRun(typeface: Typeface, decoded: DecodedText, run: TextRun): bool =
  for index in run.codepointStart ..< run.codepointEnd:
    let codepoint = decoded.codepoints[index]
    if codepointNeedsGlyph(codepoint) and not typeface.font.hasGlyph(codepoint):
      return false
  true

proc supportedPrefixEnd(
    typeface: Typeface, decoded: DecodedText, first, ending: int
): int =
  result = first
  while result < ending:
    let codepoint = decoded.codepoints[result]
    if codepointNeedsGlyph(codepoint) and not typeface.font.hasGlyph(codepoint):
      return
    inc result

proc sliceTextRun(run: TextRun, decoded: DecodedText, first, ending: int): TextRun =
  result = run
  result.byteStart = decoded.byteStarts[first]
  result.byteEnd = decoded.byteEnds[ending - 1]
  result.codepointStart = first
  result.codepointEnd = ending

proc selectTypefaceSegment(
    context: ShapeContext, text: string, decoded: DecodedText, run: TextRun, first: int
): tuple[typefaceIndex, ending: int] =
  if context.typefaces.len == 0:
    raise newException(ValueError, "shape context requires at least one typeface")
  if context.fallback != nil:
    result.typefaceIndex = context.fallback(text, run, context.typefaces)
    if result.typefaceIndex < 0 or result.typefaceIndex >= context.typefaces.len:
      raise newException(ValueError, "font fallback callback returned an invalid index")
    result.ending = run.codepointEnd
    return

  var required = first
  while required < run.codepointEnd and
      not codepointNeedsGlyph(decoded.codepoints[required]):
    inc required
  if required == run.codepointEnd:
    return (0, run.codepointEnd)

  result.typefaceIndex = 0
  for index, typeface in context.typefaces:
    if typeface.font.hasGlyph(decoded.codepoints[required]):
      result.typefaceIndex = index
      result.ending = typeface.supportedPrefixEnd(decoded, first, run.codepointEnd)
      return
  result.ending = required + 1

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
  var logicalTextRuns: seq[TextRun]
  for run in analysis.runs:
    var first = run.codepointStart
    while first < run.codepointEnd:
      let selection = context.selectTypefaceSegment(text, decoded, run, first)
      let segment = run.sliceTextRun(decoded, first, selection.ending)
      let shapeOptions = initShapeOptions(
        features = segment.features,
        direction = segment.direction,
        script = segment.script,
        language = segment.language,
        flags = context.options.flags,
        shapers = context.options.shapers,
        clusterLevel = context.options.clusterLevel,
      )
      var shaped =
        shapeRun(context, text, segment, selection.typefaceIndex, shapeOptions)
      if shaped.hasMissingGlyphs:
        for fallbackIndex, typeface in context.typefaces:
          if fallbackIndex != selection.typefaceIndex and
              typeface.supportsRun(decoded, segment):
            shaped = shapeRun(context, text, segment, fallbackIndex, shapeOptions)
            break
      logicalTextRuns.add segment
      result.logicalRuns.add shaped
      first = selection.ending

  let visualIndices = visualOrderIndices(logicalTextRuns)
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
  result.handle = hb_set_create()
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz set")

proc len*(set: Set): int =
  int(hb_set_get_population(set.requireSet))

proc contains*(set: Set, codepoint: Codepoint): bool =
  hb_set_has(set.requireSet, codepoint).boolValue

proc incl*(set: var Set, codepoint: Codepoint) =
  hb_set_add(set.requireSet, codepoint)

proc incl*(set: var Set, first, last: Codepoint) =
  hb_set_add_range(set.requireSet, first, last)

proc excl*(set: var Set, codepoint: Codepoint) =
  hb_set_del(set.requireSet, codepoint)

proc clear*(set: var Set) =
  hb_set_clear(set.requireSet)

proc isEmpty*(set: Set): bool =
  hb_set_is_empty(set.requireSet).boolValue

proc min*(set: Set): Codepoint =
  hb_set_get_min(set.requireSet)

proc max*(set: Set): Codepoint =
  hb_set_get_max(set.requireSet)

iterator items*(set: Set): Codepoint =
  var current = HB_SET_VALUE_INVALID
  while hb_set_next(set.requireSet, addr current).boolValue:
    yield current

proc initSubsetInput*(): SubsetInput =
  result.handle = hb_subset_input_create_or_fail()
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz subset input")

proc keepEverything*(input: var SubsetInput) =
  hb_subset_input_keep_everything(input.requireInput)

proc inclUnicode*(input: var SubsetInput, codepoint: Codepoint) =
  let set = hb_subset_input_unicode_set(input.requireInput)
  if set == nil:
    raise newException(ValueError, "could not get HarfBuzz subset unicode set")
  hb_set_add(set, codepoint)

proc inclGlyph*(input: var SubsetInput, glyph: Codepoint) =
  let set = hb_subset_input_glyph_set(input.requireInput)
  if set == nil:
    raise newException(ValueError, "could not get HarfBuzz subset glyph set")
  hb_set_add(set, glyph)

proc pinAxisLocation*(
    input: var SubsetInput, face: Face, tag: Tag, value: float32
): bool =
  hb_subset_input_pin_axis_location(
    input.requireInput, face.requireFace, hb_tag_t(tag), cfloat(value)
  ).boolValue

proc subset*(face: Face, input: SubsetInput): Face =
  result.handle = hb_subset_or_fail(face.requireFace, input.requireInput)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset failed")

proc preprocess*(face: Face): Face =
  result.handle = hb_subset_preprocess(face.requireFace)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset preprocess failed")

proc initSubsetPlan*(face: Face, input: SubsetInput): SubsetPlan =
  result.handle = hb_subset_plan_create_or_fail(face.requireFace, input.requireInput)
  if result.handle == nil:
    raise newException(ValueError, "could not create HarfBuzz subset plan")

proc execute*(plan: SubsetPlan): Face =
  result.handle = hb_subset_plan_execute_or_fail(plan.requireSubsetPlan)
  if result.handle == nil:
    raise newException(ValueError, "HarfBuzz subset plan execution failed")
