import std/[os, unicode, unittest]
import harfbuzzy
import harfbuzzy/typesetting

when defined(harfbuzzRuntime) or defined(feature.harfbuzzy.runtime) or
    defined(features.harfbuzzy.runtime):
  loadHarfbuzz()
  loadFribidi()

const Fixture =
  currentSourcePath().parentDir / "fixtures" / "outlines" / "quadratic.ttf"

suite "standalone HarfBuzzy layout":
  let context = initShapeContext(typefaceFromFile(Fixture))

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
