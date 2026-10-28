import std/[os, sequtils, strutils, unittest]

import harfbuzzy
import harfbuzzy/fribidi_raw
import harfbuzzy/raw
from harfbuzz/hb_draw import nil

when not hbStaticEnabled and (
  defined(harfbuzzRuntime) or defined(feature.harfbuzzy.runtime) or
  defined(features.harfbuzzy.runtime)
):
  loadHarfbuzz()
  loadHarfbuzz(HarfBuzzLibrary.Subset)

when not hbStaticEnabled and (
  defined(harfbuzzRuntime) or defined(harfbuzzyFribidiRuntime) or
  defined(feature.harfbuzzy.runtime) or defined(features.harfbuzzy.runtime)
):
  loadFribidi()

when hbStaticEnabled:
  import harfbuzzy/private/staticHarfbuzz

proc findFixtureFont(paths: openArray[string]): string =
  for path in paths:
    if fileExists(path):
      return path

let fixtureFont = findFixtureFont(
  [
    "deps/luaharfbuzz/fonts/Rajdhani-Regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/Library/Fonts/Arial Unicode.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    getEnv("WINDIR", "C:/Windows") / "Fonts" / "consola.ttf",
  ]
)
let arabicFixtureFont = findFixtureFont(
  [
    "deps/luaharfbuzz/fonts/amiri-regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf",
    "/System/Library/Fonts/Supplemental/AlBayan.ttc",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    getEnv("WINDIR", "C:/Windows") / "Fonts" / "arial.ttf",
  ]
)
let emojiFixtureFont = findFixtureFont(
  [
    "../pixie/tests/fonts/NotoEmoji.otf", "deps/pixie/tests/fonts/NotoEmoji.otf",
    "/usr/share/fonts/truetype/noto/NotoEmoji-Regular.ttf",
  ]
)
let symbolFixtureFont = findFixtureFont(
  [
    "/System/Library/Fonts/Apple Symbols.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansSymbols2-Regular.ttf",
    getEnv("WINDIR", "C:/Windows") / "Fonts" / "seguisym.ttf",
  ]
)

const
  hebrewText = "\u05E9\u05DC\u05D5\u05DD"
  arabicText = "\u0633\u0644\u0627\u0645"

static:
  when hbStaticEnabled:
    doAssert defined(harfbuzzStatic)
    doAssert not declared(hbLib)
  doAssert sizeof(hb_var_int_t) == 4
  doAssert sizeof(hb_var_num_t) == 4
  doAssert sizeof(hb_feature_t) == 16
  doAssert sizeof(hb_variation_t) == 8
  doAssert sizeof(hb_glyph_extents_t) == 16
  doAssert sizeof(hb_font_extents_t) == 48
  doAssert sizeof(hb_glyph_info_t) == 20
  doAssert sizeof(hb_glyph_position_t) == 20
  doAssert sizeof(hb_segment_properties_t) == 8 + 3 * sizeof(pointer)
  doAssert sizeof(hb_user_data_key_t) == 1

suite "harfbuzzy raw bindings":
  test "value struct layouts match HarfBuzz headers":
    check sizeof(hb_var_int_t) == 4
    check sizeof(hb_var_num_t) == 4
    check sizeof(hb_feature_t) == 16
    check sizeof(hb_variation_t) == 8
    check sizeof(hb_glyph_extents_t) == 16
    check sizeof(hb_glyph_info_t) == 20
    check sizeof(hb_glyph_position_t) == 20
    check sizeof(hb_font_extents_t) == 48
    check sizeof(hb_segment_properties_t) == 8 + 3 * sizeof(pointer)
    check offsetOf(hb_feature_t, `end`) == 12
    check offsetOf(hb_glyph_info_t, cluster) == 8
    check offsetOf(hb_glyph_position_t, y_offset) == 12
    check offsetOf(hb_segment_properties_t, language) == 8
    check sizeof(fribidi_raw.FriBidiChar) == 4
    check sizeof(fribidi_raw.FriBidiCharType) == 4
    check sizeof(fribidi_raw.FriBidiParType) == 4
    check sizeof(fribidi_raw.FriBidiLevel) == 1

  test "version symbols are callable":
    check versionString().len > 0
    check versionAtLeast(1, 0, 0)
    check version().major >= 1
    when hbStaticEnabled:
      check versionString() == staticHarfbuzz.harfbuzzVersion

  test "FriBidi classifies brackets and resolves mixed-direction levels":
    var
      chars = [0x61'u32, 0x28'u32, 0x5D0'u32, 0x29'u32]
      types: array[4, FriBidiCharType]
      brackets: array[4, FriBidiBracketType]
      levels: array[4, FriBidiLevel]
      direction = FRIBIDI_PAR_LTR
    check fribidi_raw.fribidi_get_bidi_type(chars[2]) == FRIBIDI_TYPE_RTL
    fribidi_raw.fribidi_get_bidi_types(addr chars[0], chars.len.cint, addr types[0])
    check types[2] == FRIBIDI_TYPE_RTL
    fribidi_raw.fribidi_get_bracket_types(
      addr chars[0], chars.len.cint, addr types[0], addr brackets[0]
    )
    check brackets[1] != 0
    check brackets[3] != 0
    check fribidi_raw.fribidi_get_par_embedding_levels_ex(
      addr types[0], addr brackets[0], chars.len.cint, addr direction, addr levels[0]
    ) > 0
    check direction == FRIBIDI_PAR_LTR
    check levels[0] == 0
    check fribidi_raw.fribidi_level_is_rtl(levels[2])

  test "array APIs can be used as C function pointers":
    var
      listShapers = hb_shape_list_shapers
      listFormats = hb_buffer_serialize_list_formats
      shapeFull = hb_shape_full
      createPlan = hb_shape_plan_create
      createCachedPlan = hb_shape_plan_create_cached
      props =
        hb_segment_properties_t(direction: HB_DIRECTION_LTR, script: HB_SCRIPT_LATIN)
    check listShapers() != nil
    check listFormats() != nil
    let buffer = hb_buffer_create()
    defer:
      hb_buffer_destroy(buffer)
    hb_buffer_set_segment_properties(buffer, addr props)
    check shapeFull(hb_font_get_empty(), buffer, nil, 0, nil) != 0
    let plan = createPlan(hb_face_get_empty(), addr props, nil, 0, nil)
    check plan != nil
    hb_shape_plan_destroy(plan)
    let cachedPlan = createCachedPlan(hb_face_get_empty(), addr props, nil, 0, nil)
    check cachedPlan != nil
    hb_shape_plan_destroy(cachedPlan)

suite "upstream draw interoperability":
  test "upstream callbacks accept handles from the raw backend":
    type DrawData = object
      moves: int
      validState: bool
      x, y: cfloat

    proc moveTo(
        funcs: ptr hb_draw.hb_draw_funcs_t,
        data: pointer,
        state: ptr hb_draw.hb_draw_state_t,
        x, y: cfloat,
        userData: pointer,
    ) {.cdecl, raises: [].} =
      let draw = cast[ptr DrawData](data)
      inc draw.moves
      draw.validState = funcs != nil and state != nil
      draw.x = x
      draw.y = y

    let path = currentSourcePath().parentDir / "fixtures" / "outlines" / "quadratic.ttf"
    let blob = hb_blob_create_from_file_or_fail(path.cstring)
    require blob != nil
    defer:
      hb_blob_destroy(blob)
    let face = hb_face_create(blob, 0)
    require face != nil
    defer:
      hb_face_destroy(face)
    let font = hb_font_create(face)
    require font != nil
    defer:
      hb_font_destroy(font)
    hb_ot_font_set_funcs(font)
    hb_font_set_scale(font, 1000, 1000)
    var glyph: hb_codepoint_t
    require hb_font_get_nominal_glyph(font, 65, addr glyph) != 0

    let funcs = hb_draw_funcs_create()
    require funcs != nil
    defer:
      hb_draw_funcs_destroy(funcs)
    let callback: hb_draw.hb_draw_move_to_func_t = moveTo
    hb_draw_funcs_set_move_to_func(funcs, callback, nil, nil)
    var data: DrawData
    hb_font_draw_glyph(font, glyph, funcs, addr data)
    check data.moves == 1
    check data.validState
    check data.x == 100
    check data.y == 0

suite "harfbuzzy wrapper":
  test "tags, scripts, languages, directions, and features":
    let liga = toTag("liga")
    check $liga == "liga"
    check $scriptLatin == "Latn"
    check $scriptDevanagari == "Deva"
    check horizontalDirection(scriptArabic) == Direction.rtl
    check $toLanguage("en") == "en"
    check toDirection("rtl") == Direction.rtl
    check $toFeature("kern=0") == "-kern"

  test "blob data is copied and reference counted":
    let blob = initBlob("abc")
    var copy = blob
    check blob.len == 3
    check copy.data == "abc"
    copy.makeImmutable()
    check copy.isImmutable

  test "sets expose a Nim container surface":
    var set = initSet()
    check set.isEmpty
    set.incl(65'u32)
    set.incl(67'u32, 68'u32)
    check 65'u32 in set
    check 66'u32 notin set
    check set.len == 3
    var seen: seq[Codepoint]
    for codepoint in set:
      seen.add codepoint
    check seen == @[65'u32, 67'u32, 68'u32]

  test "font file can be shaped":
    check fileExists(fixtureFont)
    var face = faceFromFile(fixtureFont)
    check face.upem > 0
    check face.glyphCount > 0
    discard face.hasAatSubstitution
    discard face.hasAatPositioning
    discard face.hasAatTracking

    var font = initFont(face)
    var buffer = initBuffer()
    buffer.addUtf8("hello")
    buffer.guessSegmentProperties()

    shape(font, buffer)

    let infos = buffer.glyphInfos()
    let positions = buffer.glyphPositions()
    check buffer.hasPositions
    check infos.len > 0
    check positions.len == infos.len

  test "typeface shapes text without exposing buffer ownership":
    check fileExists(fixtureFont)
    let typeface = typefaceFromFile(fixtureFont)
    let options = initShapeOptions(features = [toFeature("kern=0")])

    let run = typeface.shape("hello", options)

    check run.len > 0
    check run.totalAdvance.x > 0
    for glyph in run:
      check glyph.codepoint != 0

  test "shape options expose cluster levels and explicit shapers":
    check fileExists(fixtureFont)
    let face = faceFromFile(fixtureFont)
    var font = initFont(face)
    var buffer = initBuffer()
    buffer.addUtf8("hello")
    buffer.applyShapeOptions(
      initShapeOptions(
        direction = Direction.ltr,
        script = scriptLatin,
        clusterLevel = ClusterLevel.characters,
      )
    )

    check buffer.clusterLevel == ClusterLevel.characters
    check "ot" in availableShapers()
    shapeFull(font, buffer, shapers = ["ot"])
    check buffer.toGlyphRun.len > 0

  test "shape plans can be cached and reused":
    check fileExists(fixtureFont)
    let typeface = typefaceFromFile(fixtureFont)
    let options = initShapeOptions(
      direction = Direction.ltr,
      script = scriptLatin,
      language = toLanguage("en"),
      features = [toFeature("kern=0")],
      shapers = ["ot"],
    )
    let plan = initShapePlan(typeface, options)
    let run = typeface.shape("hello", plan, options)

    check plan.shaper.len > 0
    check run.len > 0
    check run.totalAdvance.x > 0

  test "OpenType features and layout metrics are discoverable":
    check fileExists(fixtureFont)
    let face = faceFromFile(fixtureFont)
    let typeface = initTypeface(face)
    let glyph = typeface.font.nominalGlyph(65)
    let horizontal = typeface.font.horizontalExtents()

    check face.hasOpenTypeSubstitution or face.hasOpenTypePositioning
    check face.substitutionFeatureTags.len + face.positioningFeatureTags.len > 0
    check horizontal.lineAdvance > 0
    check typeface.font.horizontalAdvance(glyph) > 0
    check typeface.font.advance(glyph, Direction.ltr).x > 0
    check face.fromEm(face.toEm(horizontal.ascender)) == horizontal.ascender

  test "shaped buffers serialize for fixtures":
    check fileExists(fixtureFont)
    let face = faceFromFile(fixtureFont)
    var font = initFont(face)
    var buffer = initBuffer()
    buffer.addUtf8("hello")
    buffer.applyShapeOptions(
      initShapeOptions(direction = Direction.ltr, script = scriptLatin)
    )
    shape(font, buffer)

    check "text" in availableSerializeFormats()
    let serialized = buffer.serializeGlyphs(font, flags = {noGlyphNames})
    check serialized.len > 0
    check serialized[0] == '['

  test "bidi run segmentation handles ltr, rtl, and invalid input":
    let ltrRuns = bidiRuns("hello")
    check ltrRuns.len == 1
    check ltrRuns[0].direction == Direction.ltr
    check ltrRuns[0].byteStart == 0
    check ltrRuns[0].byteEnd == "hello".len

    let rtlRuns = bidiRuns(hebrewText)
    check rtlRuns.len == 1
    check rtlRuns[0].direction == Direction.rtl
    check $rtlRuns[0].script == "Hebr"
    check rtlRuns[0].byteStart == 0
    check rtlRuns[0].byteEnd == hebrewText.len

    let devanagariRuns = bidiRuns("क्ष")
    check devanagariRuns.len == 1
    check devanagariRuns[0].direction == Direction.ltr
    check $devanagariRuns[0].script == "Deva"

    let mixedRuns = bidiRuns("hello 世界 👋")
    check mixedRuns.len >= 3
    check mixedRuns.anyIt($it.script == "Latn")
    check mixedRuns.anyIt($it.script == "Hani")
    check mixedRuns.anyIt($it.script == "Zsye")

    expect ValueError:
      discard bidiRuns("\xFF")

  test "unknown script option lets HarfBuzz infer complex script properties":
    var buffer = initBuffer()
    buffer.addUtf8("क्ष")
    buffer.applyShapeOptions(
      initShapeOptions(direction = Direction.ltr, script = scriptUnknown)
    )

    check $buffer.script == "Deva"

  test "paragraph shaping returns logical and visual runs":
    check fileExists(arabicFixtureFont)
    let typeface = typefaceFromFile(arabicFixtureFont)
    let text = "abc (" & arabicText & " 123) xyz"
    let paragraph = typeface.shapeParagraph(text)

    check paragraph.baseDirection == Direction.ltr
    check paragraph.logicalRuns.len >= 2
    check paragraph.visualRuns.len == paragraph.logicalRuns.len
    check paragraph.totalAdvance.x > 0

    var hasRtl = false
    for run in paragraph.logicalRuns:
      if run.textRun.direction == Direction.rtl:
        hasRtl = true
      check run.textRun.byteStart >= 0
      check run.textRun.byteEnd <= text.len
      check run.len > 0
      for glyph in run:
        check glyph.cluster >= uint32(run.textRun.byteStart)
        check glyph.cluster < uint32(run.textRun.byteEnd)
    check hasRtl

  test "shape context chooses fallback fonts per run":
    check fileExists(fixtureFont)
    check fileExists(arabicFixtureFont)
    let latinTypeface = typefaceFromFile(fixtureFont)
    let arabicTypeface = typefaceFromFile(arabicFixtureFont)
    let context = initShapeContext(latinTypeface, [arabicTypeface])
    let text = "abc " & arabicText
    let paragraph = context.shapeParagraph(text)
    let primaryCoversArabic = not latinTypeface.shape(arabicText).hasMissingGlyphs

    check paragraph.logicalRuns.len >= 2
    var sawPrimary = false
    var sawFallback = false
    for run in paragraph.logicalRuns:
      if $run.textRun.script == "Latn":
        sawPrimary = sawPrimary or run.typefaceIndex == 0
      if $run.textRun.script == "Arab":
        sawFallback = sawFallback or run.typefaceIndex == 1
      check not run.hasMissingGlyphs
    check sawPrimary
    check sawFallback == not primaryCoversArabic

  test "shape context splits one script run across fallback fonts":
    if fileExists(fixtureFont) and fileExists(emojiFixtureFont):
      let
        primary = typefaceFromFile(fixtureFont)
        emoji = typefaceFromFile(emojiFixtureFont)
        music = 0x266B'u32
        coffee = 0x2615'u32
      if primary.font.hasGlyph(music) and not primary.font.hasGlyph(coffee) and
          emoji.font.hasGlyph(coffee) and not emoji.font.hasGlyph(music):
        let paragraph = initShapeContext(primary, [emoji]).shapeParagraph("♫☕")

        require paragraph.logicalRuns.len == 2
        check paragraph.logicalRuns[0].typefaceIndex == 0
        check paragraph.logicalRuns[1].typefaceIndex == 1
        check paragraph.logicalRuns[0].textRun.codepointStart == 0
        check paragraph.logicalRuns[0].textRun.codepointEnd == 1
        check paragraph.logicalRuns[1].textRun.codepointStart == 1
        check paragraph.logicalRuns[1].textRun.codepointEnd == 2
        check not paragraph.logicalRuns[0].hasMissingGlyphs
        check not paragraph.logicalRuns[1].hasMissingGlyphs

  test "shape context preserves the primary face before fallback":
    if fileExists(fixtureFont) and fileExists(symbolFixtureFont):
      let
        primary = typefaceFromFile(fixtureFont)
        symbols = typefaceFromFile(symbolFixtureFont)
        music = 0x266B'u32
        coffee = 0x2615'u32
      if primary.font.hasGlyph(music) and not primary.font.hasGlyph(coffee) and
          symbols.font.hasGlyph(music) and symbols.font.hasGlyph(coffee):
        let paragraph = initShapeContext(primary, [symbols]).shapeParagraph("♫☕")

        require paragraph.logicalRuns.len == 2
        check paragraph.logicalRuns[0].typefaceIndex == 0
        check paragraph.logicalRuns[1].typefaceIndex == 1

  test "font fallback callback can override selection":
    proc chooseFallback(text: string, run: TextRun, typefaces: seq[Typeface]): int =
      discard text
      discard run
      if typefaces.len > 1: 1 else: 0

    check fileExists(fixtureFont)
    check fileExists(arabicFixtureFont)
    let context = initShapeContext(
      [typefaceFromFile(fixtureFont), typefaceFromFile(arabicFixtureFont)],
      fallback = chooseFallback,
    )
    let paragraph = context.shapeParagraph(arabicText)

    check paragraph.logicalRuns.len == 1
    check paragraph.logicalRuns[0].typefaceIndex == 1

  test "source and visual logical mapping helpers are stable":
    check fileExists(arabicFixtureFont)
    let typeface = typefaceFromFile(arabicFixtureFont)
    let text = "abc " & arabicText & " xyz"
    let paragraph = typeface.shapeParagraph(text)

    check paragraph.visualToLogicalMap.len == paragraph.visualRuns.len
    check paragraph.logicalToVisualMap.len == paragraph.logicalRuns.len
    for logicalIndex in 0 ..< paragraph.logicalRuns.len:
      let visualIndex = paragraph.visualRunIndex(logicalIndex)
      check paragraph.logicalRunIndex(visualIndex) == logicalIndex

    let runRange = paragraph.glyphRangeForByte(0)
    check runRange.runIndex >= 0
    check runRange.glyphEnd > runRange.glyphStart
    let glyphRange = paragraph.logicalRuns[0].glyphRangeForCodepoint(text, 0)
    check glyphRange.glyphEnd > glyphRange.glyphStart

  test "rtl paragraph with digits and neutral punctuation shapes visually":
    check fileExists(arabicFixtureFont)
    let typeface = typefaceFromFile(arabicFixtureFont)
    let text = arabicText & " (123) abc"
    let options = initParagraphOptions(baseDirection = ParagraphDirection.rtl)
    let paragraph = typeface.shapeParagraph(text, options)

    check paragraph.baseDirection == Direction.rtl
    check paragraph.logicalRuns.len >= 2
    check paragraph.visualRuns.len == paragraph.logicalRuns.len
    check paragraph.totalAdvance.x > 0

  test "paragraph shaping handles edge-case inputs deterministically":
    check fileExists(arabicFixtureFont)
    let typeface = typefaceFromFile(arabicFixtureFont)

    check typeface.shapeParagraph("").len == 0
    let longText = "abc (123) " & arabicText & " " & "xyz ".repeat(64)
    let longParagraph = typeface.shapeParagraph(longText)
    check longParagraph.logicalRuns.len >= 2
    check longParagraph.totalAdvance.x > 0

    for bad in ["\x80", "\xC0\x80", "\xE0\x80\x80", "\xF0\x80\x80\x80", "\xED\xA0\x80"]:
      expect ValueError:
        discard bidiRuns(bad)

  test "subset input owns only the input, not its borrowed sets":
    check fileExists(fixtureFont)
    let face = faceFromFile(fixtureFont)
    var input = initSubsetInput()
    input.keepEverything()

    let subsetFace = subset(face, input)
    check subsetFace.upem == face.upem
    check subsetFace.glyphCount > 0

const outlineFixtureDir = currentSourcePath().parentDir / "fixtures" / "outlines"

proc outlineFixtureFont(name: string): Font =
  initTypeface(initFace(initBlob(readFile(outlineFixtureDir / name)))).font

suite "glyph outlines":
  test "TrueType outlines retain quadratic control points and closed contours":
    let font = outlineFixtureFont("quadratic.ttf")
    let commands = font.glyphOutline(font.nominalGlyph(65))
    check commands.len > 3
    check commands[0].kind == OutlineCommandKind.moveTo
    check commands[0].to == OutlinePoint(x: 100, y: 0)
    check commands[1].kind == OutlineCommandKind.lineTo
    check commands[1].to == OutlinePoint(x: 500, y: 0)
    check commands[2].kind == OutlineCommandKind.quadraticTo
    check commands[2].control1 == OutlinePoint(x: 500, y: 600)
    check commands[2].to == OutlinePoint(x: 100, y: 600)
    check commands[^1].kind == OutlineCommandKind.closePath

  test "CFF outlines retain both cubic control points":
    let font = outlineFixtureFont("cubic.otf")
    let commands = font.glyphOutline(font.nominalGlyph(65))
    check commands.len > 3
    check commands[0].to == OutlinePoint(x: 100, y: 0)
    check commands[2].kind == OutlineCommandKind.cubicTo
    check commands[2].control1 == OutlinePoint(x: 600, y: 100)
    check commands[2].control2 == OutlinePoint(x: 600, y: 500)
    check commands[2].to == OutlinePoint(x: 100, y: 600)
    check commands[^1].kind == OutlineCommandKind.closePath

  test "outline coordinates follow the font scale without flipping Y":
    var font = outlineFixtureFont("quadratic.ttf")
    let glyph = font.nominalGlyph(65)
    let original = font.glyphOutline(glyph)
    font.setScale(2000, 3000)
    let scaled = font.glyphOutline(glyph)
    check scaled.len == original.len
    for index, command in scaled:
      check command.kind == original[index].kind
      check command.to.x == original[index].to.x * 2
      check command.to.y == original[index].to.y * 3
      check command.control1.x == original[index].control1.x * 2
      check command.control1.y == original[index].control1.y * 3
      check command.control2.x == original[index].control2.x * 2
      check command.control2.y == original[index].control2.y * 3

  test "outlines follow variable font coordinates":
    var font = outlineFixtureFont("variable.ttf")
    let glyph = font.nominalGlyph(65)
    let regular = font.glyphOutline(glyph)
    font.setVariations([initVariation(toTag("wght"), 900)])
    let heavy = font.glyphOutline(glyph)
    check regular[1].to.x == 500
    check heavy[1].to.x == 600
    check heavy[2].control1.x == 600
    check heavy[2].to == regular[2].to

  test "empty outlines and the notdef glyph have distinct results":
    let font = outlineFixtureFont("quadratic.ttf")
    check font.glyphOutline(font.nominalGlyph(32)).len == 0
    check font.glyphOutline(0).len > 0

  test "commands outlive the font and successive calls own separate storage":
    var first = block:
      let font = outlineFixtureFont("quadratic.ttf")
      font.glyphOutline(font.nominalGlyph(65))
    let second = block:
      let font = outlineFixtureFont("quadratic.ttf")
      font.glyphOutline(font.nominalGlyph(65))
    check first == second
    first[0].to.x = -1
    check second[0].to.x == 100

  test "uninitialized fonts raise ValueError":
    expect ValueError:
      discard Font().glyphOutline(0)
