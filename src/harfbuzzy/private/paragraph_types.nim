# Shared by the native and Harfnim shaping engines.

type
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

  Feature* = object
    tag*: Tag
    value*: uint32
    start*: uint32
    ending*: uint32

  Variation* = object
    tag*: Tag
    value*: float32

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

func isEmojiCodepoint(codepoint: Codepoint): bool =
  codepoint in 0x1F000'u32 .. 0x1FAFF'u32 or codepoint in 0x1FC00'u32 .. 0x1FFFF'u32 or
    codepoint in 0x2600'u32 .. 0x27BF'u32
