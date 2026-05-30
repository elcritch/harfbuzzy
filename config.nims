import std/[os, strutils]

--mm:atomicArc
--threads:on

task test, "run unit tests":
  for testFile in listFiles("tests/"):
    if testFile.endsWith(".nim") and testFile.splitFile().name.startsWith("t"):
      exec("nim c -r " & quoteShell(testFile))
  for exampleFile in listFiles("examples/"):
    if exampleFile.endsWith(".nim"):
      exec("nim c " & quoteShell(exampleFile))
