version       = "0.5.0"
author        = "elcritch"
description   = "Nim bindings and wrappers for HarfBuzz."
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.2.10"
requires "https://github.com/elcritch/harfbuzz-nim#fix/static-native-types"

feature "static":
  discard
