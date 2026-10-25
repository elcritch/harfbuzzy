## Startup and default handle cleanup must work without a HarfBuzz DLL.
import harfbuzzy

const expectMissing {.booldefine.} = false

var font: Font
doAssert font.isNil
try:
  loadHarfbuzz()
  doAssert not expectMissing
  doAssert versionString().len > 0
except HarfBuzzLoadError:
  doAssert expectMissing
