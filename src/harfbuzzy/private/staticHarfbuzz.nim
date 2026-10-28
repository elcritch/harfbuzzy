## Compile-time support for the opt-in bundled HarfBuzz and FriBidi build.

import std/[hashes, os]

const
  harfbuzzVersion* = "14.2.0"
  fribidiVersion* = "1.0.16"
  harfbuzzyStaticCache* {.strdefine.} = ""
  harfbuzzyStaticCmake* {.strdefine.} = "cmake"
  harfbuzzyStaticCmakeArgs* {.strdefine.} = ""
  buildJobs = getEnv("CMAKE_BUILD_PARALLEL_LEVEL", "2")

  targetName = hostOS & "-" & hostCPU
  defaultCacheDir = getCacheDir() / "harfbuzzy"
  cacheDir = if harfbuzzyStaticCache.len > 0: harfbuzzyStaticCache else: defaultCacheDir
  harfbuzzCmakeDir = currentSourcePath().parentDir() / "harfbuzz-static"
  harfbuzzBuildScript = harfbuzzCmakeDir / "build.cmake"
  # CMake caches absolute source paths and compiler choices. Keep independent
  # checkouts and configurations from reusing incompatible build directories.
  buildKey = $hash(
    harfbuzzCmakeDir & "\n" & readFile(harfbuzzCmakeDir / "CMakeLists.txt") & "\n" &
      readFile(harfbuzzBuildScript) & "\n" & harfbuzzyStaticCmake & "\n" &
      harfbuzzyStaticCmakeArgs & "\n" & getEnv("CC") & "\n" & getEnv("CXX") & "\n" &
      getEnv("CFLAGS") & "\n" & getEnv("CXXFLAGS") & "\n" & getEnv("LDFLAGS") & "\n" &
      getEnv("CMAKE_GENERATOR") & "\n" & getEnv("CMAKE_GENERATOR_PLATFORM") & "\n" &
      getEnv("CMAKE_GENERATOR_TOOLSET") & "\n" & getEnv("SDKROOT") & "\n" &
      getEnv("MACOSX_DEPLOYMENT_TARGET") & "\n" & $defined(harfbuzzyNoFribidi)
  )
  harfbuzzBuildDir* = cacheDir / ("harfbuzz-" & harfbuzzVersion) / targetName / buildKey
  harfbuzzSourceDir* = harfbuzzBuildDir / "_deps" / "harfbuzz-src" / "src"
  harfbuzzIncludeDir* = harfbuzzBuildDir / "include"
  harfbuzzLibDir = harfbuzzBuildDir / "lib"
  fribidiInstallDir* = harfbuzzBuildDir / "fribidi-install"
  fribidiIncludeDir* = fribidiInstallDir / "include" / "fribidi"
  fribidiSourceDir* = harfbuzzBuildDir / "_deps" / "fribidi-src"

  # Meson's static archive keeps its .a name when built with MSVC, too.
  fribidiStaticLib* = fribidiInstallDir / "lib" / "libfribidi.a"

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

  buildCommand =
    quoteShell(harfbuzzyStaticCmake) & " " &
    quoteShell("-DHARFBUZZY_SOURCE_DIR=" & harfbuzzCmakeDir) & " " &
    quoteShell("-DHARFBUZZY_BUILD_DIR=" & harfbuzzBuildDir) & " " &
    quoteShell("-DHARFBUZZY_EXTRA_ARGS=" & harfbuzzyStaticCmakeArgs) & " " &
    quoteShell("-DHARFBUZZY_BUILD_JOBS=" & buildJobs) & " " &
    (when defined(harfbuzzyNoFribidi): "-DHARFBUZZY_NO_FRIBIDI=ON " else: "") &
    (when defined(vcc): "-DHARFBUZZY_MSVC_RUNTIME=MultiThreaded " else: "") & "-P " &
    quoteShell(harfbuzzBuildScript)

when defined(windows) and not defined(vcc):
  {.error: "harfbuzzy's static HarfBuzz build requires --cc:vcc on Windows".}

proc runBuildCommand(command: string) {.compileTime.} =
  let (output, exitCode) = gorgeEx(command)
  if exitCode != 0:
    raise
      newException(IOError, "Harfbuzzy native build failed: " & command & "\n" & output)

static:
  if not fileExists(harfbuzzCmakeDir / "CMakeLists.txt"):
    raise newException(
      IOError, "harfbuzzy static build support is missing its CMakeLists.txt"
    )

  runBuildCommand(buildCommand)

  if not fileExists(harfbuzzStaticLib) or not fileExists(harfbuzzSubsetStaticLib) or
      (not defined(harfbuzzyNoFribidi) and not fileExists(fribidiStaticLib)):
    raise newException(
      IOError,
      "harfbuzzy's static native build did not produce its libraries:\n" &
        harfbuzzStaticLib & "\n" & harfbuzzSubsetStaticLib & "\n" & fribidiStaticLib,
    )
