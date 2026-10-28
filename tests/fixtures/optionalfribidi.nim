## Missing FriBidi must not prevent applications from starting.
import harfbuzzy

try:
  discard bidiRuns("hello")
  doAssert false, "paragraph analysis should require FriBidi"
except FriBidiLoadError:
  discard

try:
  loadFribidi()
  doAssert false, "the configured FriBidi library should be missing"
except FriBidiLoadError:
  discard

let ltrOptions = initParagraphOptions(
  baseDirection = ParagraphDirection.ltr, bidiMode = BidiMode.singleDirection
)
let rtlOptions = initParagraphOptions(
  baseDirection = ParagraphDirection.rtl, bidiMode = BidiMode.singleDirection
)
let ltrRuns = bidiRuns("hello 世界", ltrOptions)
doAssert ltrRuns.len == 2
doAssert ltrRuns[0].direction == Direction.ltr
doAssert ltrRuns[1].byteEnd == "hello 世界".len
let rtlRuns = bidiRuns("שלום سلام", rtlOptions)
doAssert rtlRuns.len == 2
doAssert rtlRuns[0].direction == Direction.rtl
doAssert rtlRuns[0].level.levelValue == 1
try:
  discard bidiRuns("", initParagraphOptions(bidiMode = BidiMode.singleDirection))
  doAssert false, "single-direction mode requires a direction"
except ValueError:
  discard
try:
  discard bidiRuns("\xFF", ltrOptions)
  doAssert false, "invalid UTF-8 must be rejected"
except ValueError:
  discard

let typeface = typefaceFromFile("tests/fixtures/outlines/quadratic.ttf")
let paragraph = typeface.shapeParagraph("hello 世界", ltrOptions)
doAssert paragraph.logicalRuns.len == 2
doAssert paragraph.visualRuns.len == 2
doAssert paragraph.baseDirection == Direction.ltr
let context = initShapeContext(typeface, options = rtlOptions)
let rtlParagraph = context.shapeParagraph("שלום سلام")
doAssert rtlParagraph.logicalRuns.len >= 2
doAssert rtlParagraph.visualRuns[0].textRun.byteStart > 0
