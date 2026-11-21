import std/[math, os, unicode, unittest]
import harfbuzzy
import harfbuzzy/typesetting

when defined(harfbuzzRuntime) or defined(feature.harfbuzzy.runtime) or
    defined(features.harfbuzzy.runtime):
  loadHarfbuzz()
  loadFribidi()

const Fixtures = currentSourcePath().parentDir / "fixtures" / "outlines"

suite "standalone HarfBuzzy layout":
  let
    primary = typefaceFromFile(Fixtures / "quadratic.ttf")
    fallback = typefaceFromFile(Fixtures / "layout.ttf")
    context = initShapeContext(primary)
    mixed = initShapeContext(primary, [fallback])

  test "wraps a paragraph and keeps glyph positions and source ranges":
    let text = "A A A A A A A"
    let laid = context.layoutText(text, 16, ParagraphLayoutOptions(width: 20))
    check laid.sourceRunes == text
    check laid.lines.len > 1
    check laid.bounding.h > 0
    check laid.positions.len == laid.arrangedGlyphs.len
    check laid.selectionRects.len == laid.arrangedGlyphs.len
    for i, glyph in laid.arrangedGlyphs:
      check glyph.source.byteStart == glyph.source.runeStart
      check glyph.source.byteEnd == glyph.source.runeEnd
      check glyph.pos == laid.positions[i]

  test "uses document offsets across hard breaks and bidirectional runs":
    let text = "Aé\r\n\nשלום A"
    let laid = context.layoutText(text, 16, ParagraphLayoutOptions(width: 200))
    check laid.lines.len == 3
    check laid.arrangedGlyphs[laid.lines[1].a].source.byteStart == "Aé\r\n".len
    for glyph in laid.arrangedGlyphs:
      let source = glyph.source
      check source.runeStart == text[0 ..< source.byteStart].runeLen
      check source.runeEnd == text[0 ..< source.byteEnd].runeLen

  test "rejects invalid UTF-8 and invalid font size":
    expect ValueError:
      discard context.layoutText("A\xED\xA0\x80", 16)
    expect ValueError:
      discard context.layoutText("A", 0)

  test "preserves the shaped mark offset during reflow":
    let laid = mixed.layoutText("بِ", 30)
    require laid.arrangedGlyphs.len == 2
    let
      mark = laid.arrangedGlyphs[0]
      base = laid.arrangedGlyphs[1]
    check almostEqual(mark.offset.x, 7.5'f32)
    check almostEqual(mark.offset.y, 9'f32)
    check almostEqual(mark.pos.x - mark.rect.x, mark.offset.x)
    check almostEqual(mark.pos.y - base.pos.y, mark.offset.y)
    check mark.pos == laid.positions[0]
    check mark.rect == laid.selectionRects[0]

  test "keeps RTL joining clusters intact unless anywhere wrapping is requested":
    for text in ["ببب", "ببِب"]:
      let normal = mixed.layoutText(text, 30, ParagraphLayoutOptions(width: 1))
      check normal.lines == @[0 .. normal.arrangedGlyphs.high]
      let anywhere = mixed.layoutText(
        text,
        30,
        ParagraphLayoutOptions(
          width: 1, style: ParagraphStyle(overflowWrap: owAnywhere)
        ),
      )
      require anywhere.lines.len == 3
      for i, line in anywhere.lines:
        for j in line:
          check anywhere.arrangedGlyphs[j].source.runeStart ==
            (if i == 2 and text == "ببِب": 3 else: i)

  test "shares a baseline and fits both font metrics on a mixed line":
    let laid = mixed.layoutText("Aب\nب", 30)
    require laid.lines.len == 2
    require laid.arrangedGlyphs.len == 3
    let glyphs = laid.arrangedGlyphs
    check glyphs[0].fontId == 0
    check glyphs[1].fontId == 1
    check almostEqual(glyphs[0].pos.y, 24'f32)
    check almostEqual(glyphs[1].pos.y, 24'f32)
    check almostEqual(glyphs[0].rect.h, 34.5'f32)
    check almostEqual(glyphs[1].rect.h, 34.5'f32)
    check almostEqual(glyphs[2].rect.y, 34.5'f32)
    check almostEqual(glyphs[2].pos.y, 54'f32)

    let wrapped = mixed.layoutText("A ب", 30, ParagraphLayoutOptions(width: 22))
    require wrapped.lines.len == 2
    let secondLine = wrapped.arrangedGlyphs[wrapped.lines[1].a]
    check secondLine.fontId == 1
    check almostEqual(secondLine.rect.y, 30'f32)
    check almostEqual(secondLine.pos.y, 49.5'f32)
