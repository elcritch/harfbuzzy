import std/unittest

import harfbuzzy

suite "harfbuzzy":
  test "greets by name":
    check greet("Nim") == "hello, Nim"

