## Compile-time support for the opt-in bundled HarfBuzz build.

import std/os

const
  harfbuzzVersion* = "14.2.0"
  harfbuzzyStaticCache* {.strdefine.} = ""
  harfbuzzyStaticCmake* {.strdefine.} = "cmake"
  harfbuzzyStaticCmakeArgs* {.strdefine.} = ""

  targetName = hostOS & "-" & hostCPU
  defaultCacheDir = getCacheDir() / "harfbuzzy"
  cacheDir = if harfbuzzyStaticCache.len > 0: harfbuzzyStaticCache else: defaultCacheDir
  harfbuzzBuildDir* = cacheDir / ("harfbuzz-" & harfbuzzVersion) / targetName
  harfbuzzSourceDir* = harfbuzzBuildDir / "_deps" / "harfbuzz-src" / "src"
  harfbuzzCmakeDir = currentSourcePath().parentDir() / "harfbuzz-static"
  harfbuzzLibDir = harfbuzzBuildDir / "lib"

  harfbuzzStaticLib* =
    when defined(windows):
      harfbuzzLibDir / "harfbuzz.lib"
    else:
      harfbuzzLibDir / "libharfbuzz.a"

  harfbuzzSubsetStaticLib* =
    when defined(windows):
      harfbuzzLibDir / "harfbuzz-subset.lib"
    else:
      harfbuzzLibDir / "libharfbuzz-subset.a"

  configureCommand =
    quoteShell(harfbuzzyStaticCmake) & " -S " & quoteShell(harfbuzzCmakeDir) & " -B " &
    quoteShell(harfbuzzBuildDir) & " -DCMAKE_BUILD_TYPE=Release" &
    (if harfbuzzyStaticCmakeArgs.len > 0: " " & harfbuzzyStaticCmakeArgs
    else: "")
  buildCommand =
    quoteShell(harfbuzzyStaticCmake) & " --build " & quoteShell(harfbuzzBuildDir) &
    " --config Release --target harfbuzz harfbuzz-subset --parallel"

when defined(windows) and not defined(vcc):
  {.error: "harfbuzzy's static HarfBuzz build requires --cc:vcc on Windows".}

static:
  if not fileExists(harfbuzzCmakeDir / "CMakeLists.txt"):
    raise newException(
      IOError, "harfbuzzy static build support is missing its CMakeLists.txt"
    )

  discard staticExec(configureCommand)
  discard staticExec(buildCommand)

  if not fileExists(harfbuzzStaticLib) or not fileExists(harfbuzzSubsetStaticLib):
    raise newException(
      IOError, "harfbuzzy's static HarfBuzz build did not produce its libraries"
    )
