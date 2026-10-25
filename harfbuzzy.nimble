version       = "0.4.0"
author        = "elcritch"
description   = "Nim bindings and wrappers for HarfBuzz."
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.2.10"
requires "https://github.com/nimbase/harfbuzz-nim#ed8c3ae95675d9482fc3c764f62aac19f9a880a9"

feature "static":
  discard
