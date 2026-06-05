import std/os

import harfbuzzy

proc findFont(paths: openArray[string]): string =
  for path in paths:
    if fileExists(path):
      return path
  raise newException(ValueError, "could not find a usable font fixture")

const arabicText = "\u0633\u0644\u0627\u0645"

let
  latinFont = findFont(
    [
      "deps/luaharfbuzz/fonts/Rajdhani-Regular.ttf",
      "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/Library/Fonts/Arial Unicode.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
  )
  arabicFont = findFont(
    [
      "deps/luaharfbuzz/fonts/amiri-regular.ttf",
      "/usr/share/fonts/truetype/noto/NotoNaskhArabic-Regular.ttf",
      "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf",
      "/System/Library/Fonts/Supplemental/AlBayan.ttc",
      "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
  )

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
