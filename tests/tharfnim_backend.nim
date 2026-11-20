when defined(feature.harfbuzzy.harfnim) or defined(feature.figdraw.textBackendHarfnim):
  import std/[os, sequtils, unittest]
  import harfbuzzy/harfnim_backend

  const fixtures = currentSourcePath().parentDir / "fixtures" / "outlines"

  suite "Harfnim backend":
    test "draws cubic and quadratic glyph outlines":
      for (name, curve) in [
        ("quadratic.ttf", OutlineCommandKind.quadraticTo),
        ("cubic.otf", OutlineCommandKind.cubicTo),
      ]:
        let face = typefaceFromFile(fixtures / name)
        let glyph = face.font.nominalGlyph(uint32('A'))
        require glyph != 0
        let commands = face.font.glyphOutline(glyph)
        check commands.anyIt(it.kind == curve)
        check commands[^1].kind == OutlineCommandKind.closePath
        check face.font.glyphOutline(face.font.nominalGlyph(uint32(' '))).len == 0

    test "changes advance-independent outline bounds at a variable location":
      var face = typefaceFromFile(fixtures / "variable.ttf")
      let glyph = face.font.nominalGlyph(uint32('A'))
      let width = face.font.glyphExtents(glyph).width
      let advance = face.font.horizontalAdvance(glyph)
      face.font.setVariations([initVariation(toTag("wght"), 900)])
      check face.font.glyphExtents(glyph).width == width + 100
      check face.font.horizontalAdvance(glyph) == advance
      face.font.setVariations([])
      check face.font.glyphExtents(glyph).width == width
