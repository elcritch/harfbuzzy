## Compile-time support for the opt-in bundled HarfBuzz build.

import std/[hashes, os]

const
  harfbuzzVersion* = "14.2.0"
  harfbuzzyStaticCache* {.strdefine.} = ""
  harfbuzzyStaticCmake* {.strdefine.} = "cmake"
  harfbuzzyStaticCmakeArgs* {.strdefine.} = ""
  buildJobs = getEnv("CMAKE_BUILD_PARALLEL_LEVEL", "2")

  targetName = hostOS & "-" & hostCPU
  defaultCacheDir = getCacheDir() / "harfbuzzy"
  cacheDir = if harfbuzzyStaticCache.len > 0: harfbuzzyStaticCache else: defaultCacheDir
  harfbuzzCmakeDir = currentSourcePath().parentDir() / "harfbuzz-static"
  # CMake caches absolute source paths and compiler choices. Keep independent
  # checkouts and configurations from reusing incompatible build directories.
  buildKey =
    $hash(
      harfbuzzCmakeDir & "\n" & readFile(harfbuzzCmakeDir / "CMakeLists.txt") & "\n" &
        harfbuzzyStaticCmake & "\n" & harfbuzzyStaticCmakeArgs & "\n" & getEnv("CC") &
        "\n" & getEnv("CXX") & "\n" & getEnv("CMAKE_GENERATOR")
    )
  harfbuzzBuildDir* = cacheDir / ("harfbuzz-" & harfbuzzVersion) / targetName / buildKey
  harfbuzzSourceDir* = harfbuzzBuildDir / "_deps" / "harfbuzz-src" / "src"
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
    (when defined(vcc): " -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded" else: "") &
    (if harfbuzzyStaticCmakeArgs.len > 0: " " & harfbuzzyStaticCmakeArgs
    else: "")
  buildCommand =
    quoteShell(harfbuzzyStaticCmake) & " --build " & quoteShell(harfbuzzBuildDir) &
    " --config Release --target harfbuzz harfbuzz-subset --parallel " &
    quoteShell(buildJobs)

when defined(windows) and not defined(vcc):
  {.error: "harfbuzzy's static HarfBuzz build requires --cc:vcc on Windows".}

proc runBuildCommand(command: string) {.compileTime.} =
  let (output, exitCode) = gorgeEx(command)
  if exitCode != 0:
    raise
      newException(IOError, "HarfBuzz native build failed: " & command & "\n" & output)

static:
  if not fileExists(harfbuzzCmakeDir / "CMakeLists.txt"):
    raise newException(
      IOError, "harfbuzzy static build support is missing its CMakeLists.txt"
    )

  runBuildCommand(configureCommand)
  runBuildCommand(buildCommand)

  if not fileExists(harfbuzzStaticLib) or not fileExists(harfbuzzSubsetStaticLib):
    raise newException(
      IOError, "harfbuzzy's static HarfBuzz build did not produce its libraries"
    )
