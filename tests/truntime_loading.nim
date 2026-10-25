## Runtime imports stay nil until an explicit, recoverable library load.
when defined(harfbuzzRuntime):
  import std/[dynlib, os, unittest]
  import harfbuzzy/raw

  const expectMissing {.booldefine.} = false

  suite "runtime HarfBuzz libraries":
    test "importing does not open libraries or assign procedure pointers":
      check hb_version_string == nil
      check hb_subset_input_create_or_fail == nil

    test "missing libraries leave procedure pointers nil and can be retried":
      for attempt in 0 .. 1:
        expect HarfBuzzLoadError:
          loadHarfbuzz(
            path = currentSourcePath().parentDir / "missing-harfbuzz-library"
          )
        check hb_version_string == nil

    test "a library without the identifying symbol is rejected":
      let path =
        when defined(windows):
          "kernel32.dll"
        elif defined(macosx):
          "/usr/lib/libSystem.B.dylib"
        else:
          "libc.so.6"
      expect HarfBuzzLoadError:
        loadHarfbuzz(path = path)
      check hb_version_string == nil

    when expectMissing:
      test "default discovery failures are catchable and can be retried":
        for attempt in 0 .. 1:
          expect HarfBuzzLoadError:
            loadHarfbuzz()
          check hb_version_string == nil

      test "a successful explicit load recovers after failed discovery":
        let path = getEnv("HARFBUZZ_TEST_CORE_PATH")
        if path.len > 0:
          loadHarfbuzz(path = path)
          check hb_version_atleast(7, 0, 0) != 0
          check ($hb_version_string()).len > 0
    else:
      when compileOption("threads"):
        test "concurrent loads publish procedure pointers before returning":
          proc probe(ok: ptr bool) {.thread.} =
            loadHarfbuzz()
            ok[] = true
            for i in 0 ..< 100:
              ok[] = ok[] and hb_version_atleast(7, 0, 0) != 0

          var results: array[2, bool]
          var threads: array[2, Thread[ptr bool]]
          for i in 0 ..< threads.len:
            createThread(threads[i], probe, addr results[i])
          joinThreads(threads)
          check results[0] and results[1]

      test "core calls use the stored procedure pointer":
        loadHarfbuzz()
        let versionAtLeast = hb_version_atleast
        check versionAtLeast(7, 0, 0) != 0
        check ($hb_version_string()).len > 0
        var major, minor, micro: cuint
        hb_version(addr major, addr minor, addr micro)
        check major >= 7
        loadHarfbuzz()
        check hb_version_atleast == versionAtLeast

      test "procedure pointers are the native symbol addresses":
        let path = getEnv("HARFBUZZ_TEST_CORE_PATH")
        if path.len > 0:
          let handle = loadLib(path)
          require handle != nil
          defer:
            unloadLib(handle)
          check cast[pointer](hb_version_string) == symAddr(handle, "hb_version_string")

      test "missing companion libraries leave core usable":
        expect HarfBuzzLoadError:
          loadHarfbuzz(HarfBuzzLibrary.Subset, "missing-harfbuzz-subset-library")
        check hb_subset_input_create_or_fail == nil
        check hb_version_atleast(7, 0, 0) != 0
