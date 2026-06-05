import std/[os, strutils, unittest]

import harfbuzzy
import harfbuzzy/fribidi_raw
import harfbuzzy/raw

proc findFixtureFont(paths: openArray[string]): string =
  for path in paths:
    if fileExists(path):
      return path

let fixtureFont = findFixtureFont(
  [
    "deps/luaharfbuzz/fonts/Rajdhani-Regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/Library/Fonts/Arial Unicode.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf",
  ]
)
let arabicFixtureFont = findFixtureFont(
  [
    "deps/luaharfbuzz/fonts/amiri-regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf",
    "/System/Library/Fonts/Supplemental/AlBayan.ttc",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
  ]
)

const
  hebrewText = "\u05E9\u05DC\u05D5\u05DD"
  arabicText = "\u0633\u0644\u0627\u0645"

suite "harfbuzzy raw bindings":
  test "value struct layouts match HarfBuzz headers":
    check sizeof(raw.HbVarInt) == 4
    check sizeof(raw.HbVarNum) == 4
    check sizeof(raw.HbFeature) == 16
    check sizeof(raw.HbVariation) == 8
    check sizeof(raw.HbGlyphExtents) == 16
    check sizeof(raw.HbGlyphInfo) == 20
    check sizeof(raw.HbGlyphPosition) == 20
    check sizeof(raw.HbFontExtents) == 48
    check sizeof(fribidi_raw.FriBidiChar) == 4
    check sizeof(fribidi_raw.FriBidiCharType) == 4
    check sizeof(fribidi_raw.FriBidiParType) == 4
    check sizeof(fribidi_raw.FriBidiLevel) == 1

  test "version symbols are callable":
    check versionString().len > 0
    check versionAtLeast(1, 0, 0)
    check version().major >= 1

suite "harfbuzzy wrapper":
  test "tags, scripts, languages, directions, and features":
    let liga = toTag("liga")
    check $liga == "liga"
    check $scriptLatin == "Latn"
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

    expect ValueError:
      discard bidiRuns("\xFF")

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
    check sawFallback

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
