## Harfnim shaping and glyph outlines with Harfbuzzy paragraph layout.

import std/options
import pkg/harfnim as engine

type
  Blob* = string
  Face* = engine.SfntFont
  Font* = engine.ShaperFont
  Codepoint* = uint32
  Position* = int32
  Tag* = engine.Tag
  Script* = distinct uint32
  Language* = engine.Language

  BidiMode* {.pure.} = enum
    unicode ## Resolve mixed-direction text using Harfnim.
    singleDirection ## Assume the entire paragraph has the specified direction.

include private/paragraph_types

const
  defaultBidiMode = BidiMode.unicode
  featureGlobalStart* = 0'u32
  featureGlobalEnd* = uint32.high
  scriptInvalid* = Script(0)
  scriptCommon* = Script(0x5A797979) # Zyyy
  scriptInherited* = Script(0x5A696E68) # Zinh
  scriptUnknown* = Script(0x5A7A7A7A) # Zzzz
  scriptArabic* = Script(0x41726162) # Arab
  scriptDevanagari* = Script(0x44657661) # Deva
  scriptEmoji* = Script(0x5A737965) # Zsye
  scriptHebrew* = Script(0x48656272) # Hebr
  scriptLatin* = Script(0x4C61746E) # Latn
  languageInvalid* = Language()

proc toTag*(value: string): Tag =
  if value.len == 0:
    raise newException(ValueError, "tag string is empty")
  engine.tagFromStr(value)

proc `$`*(script: Script): string =
  engine.toStr(Tag(uint32(script)))

proc toLanguage*(value: string): Language =
  engine.parseLanguage(value)

proc hasLanguage(language: Language): bool =
  language.tag.len > 0

proc defaultLanguage*(): Language =
  languageInvalid

proc scriptFor*(codepoint: Codepoint): Script =
  if isEmojiCodepoint(codepoint):
    return scriptEmoji
  Script(uint32(engine.tag(engine.scriptFor(codepoint))))

proc resolveBidiLevels(
    codepoints: openArray[Codepoint], direction: ParagraphDirection
): tuple[baseDirection: Direction, levels: seq[BidiLevel]] =
  let base =
    case direction
    of ParagraphDirection.autoDetect: engine.bdAuto
    of ParagraphDirection.ltr: engine.bdLtr
    of ParagraphDirection.rtl: engine.bdRtl
  let resolved = engine.bidiLevels(codepoints, base)
  result.baseDirection = if resolved.baseLevel == 1: Direction.rtl else: Direction.ltr
  result.levels = newSeqOfCap[BidiLevel](resolved.levels.len)
  for level in resolved.levels:
    result.levels.add BidiLevel(level)

proc initFeature*(
    tag: Tag, value = 1'u32, start = featureGlobalStart, ending = featureGlobalEnd
): Feature =
  Feature(tag: tag, value: value, start: start, ending: ending)

proc initVariation*(tag: Tag, value: float32): Variation =
  Variation(tag: tag, value: value)

proc initBlob*(data: string): Blob =
  data

proc initFace*(blob: Blob, index: Natural = 0): Face =
  engine.parseFontString(blob, index)

proc initTypeface*(face: Face): Typeface =
  Typeface(face: face, font: engine.newShaperFont(face))

proc typefaceFromFile*(path: string, index: Natural = 0): Typeface =
  initTypeface(initFace(readFile(path), index))

proc upem*(face: Face): int =
  int(face.unitsPerEm)

proc setVariations*(font: var Font, variations: openArray[Variation]) =
  var coords = newSeqOfCap[tuple[tag: uint32, value: float32]](variations.len)
  for variation in variations:
    coords.add (uint32(variation.tag), variation.value)
  engine.setVariations(font, coords)

proc nominalGlyph*(font: Font, codepoint: Codepoint): Codepoint =
  uint32(engine.nominalGlyph(font, codepoint).get(engine.GlyphId(0)))

proc hasGlyph*(font: Font, codepoint: Codepoint): bool =
  nominalGlyph(font, codepoint) != 0

proc horizontalAdvance*(font: Font, glyph: Codepoint): Position =
  engine.hAdvance(font, engine.GlyphId(glyph))

proc glyphExtents*(font: Font, glyph: Codepoint): GlyphExtents =
  let extents = engine.glyphExtents(font, engine.GlyphId(glyph))
  if extents.isNone:
    raise newException(ValueError, "glyph has no extents")
  let e = extents.get
  GlyphExtents(
    xBearing: e.xBearing, yBearing: e.yBearing, width: e.width, height: e.height
  )

func outlinePoint(point: engine.DrawPoint): OutlinePoint =
  OutlinePoint(x: float32(point.x), y: float32(point.y))

proc glyphOutline*(font: Font, glyph: Codepoint): seq[OutlineCommand] =
  var commands: seq[OutlineCommand]
  proc collect(op: engine.DrawOp) =
    case op.kind
    of engine.DrawOpKind.moveTo, engine.DrawOpKind.lineTo:
      let kind =
        if op.kind == engine.DrawOpKind.moveTo:
          OutlineCommandKind.moveTo
        else:
          OutlineCommandKind.lineTo
      commands.add OutlineCommand(kind: kind, to: outlinePoint(op.to))
    of engine.DrawOpKind.quadraticTo:
      commands.add OutlineCommand(
        kind: OutlineCommandKind.quadraticTo,
        to: outlinePoint(op.qTo),
        control1: outlinePoint(op.qCtrl),
      )
    of engine.DrawOpKind.cubicTo:
      commands.add OutlineCommand(
        kind: OutlineCommandKind.cubicTo,
        to: outlinePoint(op.cTo),
        control1: outlinePoint(op.c1),
        control2: outlinePoint(op.c2),
      )
    of engine.DrawOpKind.closePath:
      commands.add OutlineCommand(kind: OutlineCommandKind.closePath)

  discard engine.drawGlyph(font, engine.GlyphId(glyph), collect)
  result = move(commands)

proc shapeRun*(
    font: Font, text: string, run: TextRun, options = ShapeOptions()
): ShapedRun =
  if run.byteStart < 0 or run.byteEnd < run.byteStart or run.byteEnd > text.len:
    raise newException(ValueError, "text run byte range is outside the input text")
  if uint64(run.byteEnd) > uint64(uint32.high):
    raise newException(ValueError, "text run byte range does not fit glyph clusters")
  if options.shapers.len > 0 and "ot" notin options.shapers:
    raise newException(ValueError, "Harfnim supports the OpenType shaper")

  var buffer = engine.newBuffer()
  buffer.pushStr(text[run.byteStart ..< run.byteEnd])
  buffer.direction =
    case run.direction
    of Direction.ltr: engine.dirLeftToRight
    of Direction.rtl: engine.dirRightToLeft
    of Direction.ttb: engine.dirTopToBottom
    of Direction.btt: engine.dirBottomToTop
    of Direction.invalid: engine.dirInvalid
  if uint32(run.script) notin [uint32(scriptInvalid), uint32(scriptUnknown)]:
    buffer.script = some(engine.Script(uint32(run.script)))
  if run.language.hasLanguage:
    buffer.language = some(run.language)
  for flag in options.flags:
    buffer.flags = engine.BufferFlags(uint32(buffer.flags) or (1'u32 shl ord(flag)))
  buffer.clusterLevel = uint32(ord(options.clusterLevel))

  if run.direction == Direction.rtl:
    for i in 0 ..< buffer.len:
      let mirrored = engine.mirroringFor(buffer.info[i].glyphId)
      if mirrored.isSome and hasGlyph(font, mirrored.get):
        buffer.info[i].glyphId = mirrored.get

  let features = if run.features.len > 0: run.features else: options.features
  var engineFeatures = newSeqOfCap[engine.Feature](features.len)
  for feature in features:
    engineFeatures.add engine.newFeature(
      feature.tag, feature.value, feature.start, feature.ending
    )
  engine.shape(font, buffer, engine.withDefaultFeatures(engineFeatures))

  result.textRun = run
  result.glyphRun.glyphs = newSeqOfCap[Glyph](buffer.len)
  for i in 0 ..< buffer.len:
    let
      info = buffer.info[i]
      pos = buffer.pos[i]
    result.glyphRun.glyphs.add Glyph(
      codepoint: info.glyphId,
      cluster: info.cluster + uint32(run.byteStart),
      flags: uint32(engine.flagsOf(info)) and engine.DefinedGlyphFlagBits,
      xAdvance: pos.xAdvance,
      yAdvance: pos.yAdvance,
      xOffset: pos.xOffset,
      yOffset: pos.yOffset,
    )

include private/paragraph
