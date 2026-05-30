import std/[os, unittest]

import harfbuzzy
import harfbuzzy/raw

const fixtureFont = "deps/luaharfbuzz/fonts/Rajdhani-Regular.ttf"

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

  test "subset input owns only the input, not its borrowed sets":
    check fileExists(fixtureFont)
    let face = faceFromFile(fixtureFont)
    var input = initSubsetInput()
    input.keepEverything()

    let subsetFace = subset(face, input)
    check subsetFace.upem == face.upem
    check subsetFace.glyphCount > 0
