when defined(features.harfbuzzy.pixie) or defined(feature.harfbuzzy.pixie):
  import std/[os, unittest]
  import pkg/pixie/fonts as px
  import pkg/vmath
  import harfbuzzy/pixie as pxLayout

  const Fixture =
    currentSourcePath().parentDir / "fixtures" / "outlines" / "quadratic.ttf"

  suite "standalone Pixie layout":
    let font = px.readFont(Fixture)
    font.size = 16

    test "default layout matches native Pixie wrapping and positions":
      let text = "A A A A A A A"
      let options = ParagraphLayoutOptions(width: 20)
      let native = px.typeset([px.newSpan(text, font)], bounds = vec2(20, 0))
      let laid = pxLayout.layoutText(font, text, options)
      check laid.lines.len == native.lines.len
      for i, glyph in laid.arrangedGlyphs:
        check glyph.pos.x == native.positions[i].x
        check glyph.pos.y == native.positions[i].y

    test "intrinsic sizes are independent of wrap width and alignment":
      let text = "A AAAAAA A\nAAAA A A"
      let natural = pxLayout.layoutText(font, text)
      let narrow = pxLayout.layoutText(font, text, ParagraphLayoutOptions(width: 20))
      let wide = pxLayout.layoutText(
        font,
        text,
        ParagraphLayoutOptions(
          width: 200, height: 200, horizontal: Right, vertical: Bottom
        ),
      )
      check narrow.lines.len > natural.lines.len
      check wide.lines == natural.lines
      check narrow.minSize == natural.minSize
      check narrow.maxSize == natural.maxSize
      check wide.minSize == natural.minSize
      check wide.maxSize == natural.maxSize

    test "reports unpadded intrinsic widths and bounds":
      let laid = pxLayout.layoutText(font, "A")
      check laid.minSize == LayoutPoint(x: 11, y: 16)
      check laid.maxSize == LayoutPoint(x: 11, y: 16)
      check laid.bounding == LayoutRect(w: 11, h: 16)

    test "styled layout maps original offsets across filtered and cased spans":
      font.textCase = px.UpperCase
      let spans = [px.newSpan("a", font), px.newSpan("\t", font), px.newSpan("a", font)]
      let laid = pxLayout.layoutText(
        spans, ParagraphLayoutOptions(width: 100, style: ParagraphStyle(headIndent: 12))
      )
      require laid.arrangedGlyphs.len == 2
      check laid.sourceRunes == "a\ta"
      check laid.runes == "AA"
      check laid.arrangedGlyphs[0].fontId == 0
      check laid.arrangedGlyphs[1].fontId == 2
      check laid.arrangedGlyphs[1].source.byteStart == 2
