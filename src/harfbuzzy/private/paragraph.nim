# Shared script segmentation, fallback, and source mapping.

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
    bidiMode = defaultBidiMode,
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

func levelValue*(level: BidiLevel): int =
  int(uint8(level))

func direction*(level: BidiLevel): Direction =
  if (level.levelValue and 1) == 0: Direction.ltr else: Direction.rtl

func scriptIsNeutral(script: Script): bool =
  let value = uint32(script)
  value in [
    uint32(scriptInvalid),
    uint32(scriptUnknown),
    uint32(scriptCommon),
    uint32(scriptInherited),
  ]

proc inferScript(text: openArray[Codepoint], first, last: int): Script =
  for index in first ..< last:
    let script = scriptFor(text[index])
    if uint32(script) != uint32(scriptUnknown):
      return script
  scriptUnknown

proc defaultLanguageForScript*(script: Script): Language =
  if uint32(script) == uint32(scriptArabic):
    toLanguage("ar")
  elif uint32(script) == uint32(scriptDevanagari):
    toLanguage("hi")
  elif uint32(script) == uint32(scriptHebrew):
    toLanguage("he")
  elif uint32(script) == uint32(scriptLatin):
    toLanguage("en")
  else:
    defaultLanguage()

proc analyzeBidi(decoded: DecodedText, options: ParagraphOptions): BidiAnalysis =
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

  var levels: seq[BidiLevel]
  if options.bidiMode == BidiMode.singleDirection:
    levels = newSeq[BidiLevel](decoded.codepoints.len)
    result.baseDirection =
      if options.baseDirection == ParagraphDirection.rtl:
        Direction.rtl
      else:
        Direction.ltr
    if result.baseDirection == Direction.rtl:
      for level in levels.mitems:
        level = BidiLevel(1)
  else:
    (result.baseDirection, levels) =
      resolveBidiLevels(decoded.codepoints, options.baseDirection)
  var first = 0
  while first < levels.len:
    var runScript = scriptFor(decoded.codepoints[first])
    var last = first + 1
    while last < levels.len and levels[last].levelValue == levels[first].levelValue:
      let nextScript = scriptFor(decoded.codepoints[last])
      if runScript.scriptIsNeutral:
        runScript = nextScript
      elif not nextScript.scriptIsNeutral and uint32(nextScript) != uint32(runScript):
        break
      inc last
    if uint32(runScript) == uint32(scriptUnknown):
      runScript = inferScript(decoded.codepoints, first, last)
    let language =
      if options.language.hasLanguage:
        options.language
      else:
        defaultLanguageForScript(runScript)
    result.runs.add TextRun(
      byteStart: decoded.byteStarts[first],
      byteEnd: decoded.byteEnds[last - 1],
      codepointStart: first,
      codepointEnd: last,
      direction: levels[first].direction,
      level: levels[first],
      script: runScript,
      language: language,
      features: options.features,
    )
    first = last

proc bidiRuns*(text: string, options = ParagraphOptions()): seq[TextRun] =
  analyzeBidi(decodeUtf8(text), options).runs

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
    uint32(codepoint.scriptFor) == uint32(scriptInherited)
  )

proc supportsRun(typeface: Typeface, decoded: DecodedText, run: TextRun): bool =
  for index in run.codepointStart ..< run.codepointEnd:
    let codepoint = decoded.codepoints[index]
    if codepointNeedsGlyph(codepoint) and not typeface.font.hasGlyph(codepoint):
      return false
  true

proc supportedPrefixEnd(
    typefaces: openArray[Typeface],
    typefaceIndex: int,
    decoded: DecodedText,
    first, ending: int,
): int =
  ## Extends a segment while the selected face covers it and no preferred
  ## (earlier) face does, so fallback faces only cover what the primary lacks.
  result = first
  while result < ending:
    let codepoint = decoded.codepoints[result]
    if codepointNeedsGlyph(codepoint):
      if not typefaces[typefaceIndex].font.hasGlyph(codepoint):
        return
      for preferred in 0 ..< typefaceIndex:
        if typefaces[preferred].font.hasGlyph(codepoint):
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
      result.ending =
        context.typefaces.supportedPrefixEnd(index, decoded, first, run.codepointEnd)
      return
  result.ending = required + 1

proc shapeParagraph*(
    font: Font, text: string, options = ParagraphOptions()
): ShapedParagraph =
  let analysis = analyzeBidi(decodeUtf8(text), options)
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
  let decoded = decodeUtf8(text)
  let analysis = analyzeBidi(decoded, context.options)
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
