import harfbuzzy

const
  latinFont = "deps/luaharfbuzz/fonts/Rajdhani-Regular.ttf"
  arabicFont = "deps/luaharfbuzz/fonts/amiri-regular.ttf"
  arabicText = "\u0633\u0644\u0627\u0645"

let context = initShapeContext(
  typefaceFromFile(latinFont),
  [typefaceFromFile(arabicFont)],
  initParagraphOptions(shapers = ["ot"], clusterLevel = ClusterLevel.characters),
)

let paragraph = context.shapeParagraph("abc " & arabicText & " 123")

for visualRun in paragraph:
  echo "font=",
    visualRun.typefaceIndex, " bytes=", visualRun.textRun.byteStart, "..",
    visualRun.textRun.byteEnd, " glyphs=", visualRun.len
