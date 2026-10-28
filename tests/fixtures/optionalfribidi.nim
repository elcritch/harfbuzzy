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
