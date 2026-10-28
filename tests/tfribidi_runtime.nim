## Exercise explicit FriBidi loading in a separate process.
when defined(harfbuzzRuntime) or defined(harfbuzzyFribidiRuntime) or
    defined(feature.harfbuzzy.runtime) or defined(features.harfbuzzy.runtime):
  import std/[os, unittest]
  import harfbuzzy
  import harfbuzzy/fribidi_raw

  const expectMissingFriBidi {.booldefine.} = false

  when not expectMissingFriBidi:
    import std/dynlib

  suite "runtime FriBidi library":
    test "importing does not load the library":
      check fribidi_get_bidi_type == nil
      check fribidi_get_bidi_types == nil
      expect FriBidiLoadError:
        discard bidiRuns("hello")

    test "missing libraries can be retried":
      for attempt in 0 .. 1:
        expect FriBidiLoadError:
          loadFribidi(currentSourcePath().parentDir / "missing-fribidi-library")
        check fribidi_get_bidi_type == nil

    test "libraries without required symbols are rejected":
      let path =
        when defined(windows):
          "kernel32.dll"
        elif defined(macosx):
          "/usr/lib/libSystem.B.dylib"
        else:
          "libc.so.6"
      expect FriBidiLoadError:
        loadFribidi(path)
      check fribidi_get_bidi_type == nil
      check fribidi_get_bidi_types == nil

    when expectMissingFriBidi:
      test "default discovery errors are catchable":
        for attempt in 0 .. 1:
          expect FriBidiLoadError:
            loadFribidi()
          check fribidi_get_bidi_type == nil
      test "an explicit path can recover from failed discovery":
        let path = getEnv("HARFBUZZY_TEST_FRIBIDI_PATH")
        if path.len > 0:
          loadFribidi(path)
          check fribidi_get_bidi_type(0x05D0) == FRIBIDI_TYPE_RTL
    else:
      when compileOption("threads"):
        test "concurrent loads make symbols available before returning":
          proc probe(ok: ptr bool) {.thread.} =
            loadFribidi()
            ok[] = fribidi_get_bidi_type(0x05D0) == FRIBIDI_TYPE_RTL

          var results: array[2, bool]
          var threads: array[2, Thread[ptr bool]]
          for i in 0 ..< threads.len:
            createThread(threads[i], probe, addr results[i])
          joinThreads(threads)
          check results[0] and results[1]

      test "loaded calls resolve to native symbols and loading is idempotent":
        loadFribidi()
        let bidiType = fribidi_get_bidi_type
        check bidiType(0x05D0) == FRIBIDI_TYPE_RTL
        loadFribidi()
        check fribidi_get_bidi_type == bidiType
        let path = getEnv("HARFBUZZY_TEST_FRIBIDI_PATH")
        if path.len > 0:
          let handle = loadLib(path)
          require handle != nil
          defer:
            unloadLib(handle)
          check cast[pointer](bidiType) == symAddr(handle, "fribidi_get_bidi_type")
        expect ValueError:
          loadFribidi("another-library")
