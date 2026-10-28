## Explicit loading for `-d:harfbuzzRuntime`. No DLL is opened at import time.
## Successful handles remain loaded for the process lifetime, so native objects
## and callbacks cannot outlive their libraries.
import std/[dynlib, locks, strutils]

type
  HarfBuzzLibrary* {.pure.} = enum
    Core
    Subset
    Icu

  HarfBuzzLoadError* = object of CatchableError
    ## A shared library or its identifying C symbol could not be loaded.

  ImportBinder = proc(handle: LibHandle) {.gcsafe, raises: [].}

const
  harfbuzzDynlib* {.strdefine.} = ""
  harfbuzzSubsetDynlib* {.strdefine.} = ""
  harfbuzzIcuDynlib* {.strdefine.} = ""

var
  loaderLock: Lock
  handles: array[HarfBuzzLibrary, LibHandle]
  # Shared paths have the same process lifetime as the library handles.
  loadedPaths: array[HarfBuzzLibrary, cstring]
  binders: array[HarfBuzzLibrary, seq[ImportBinder]]

initLock(loaderLock)

func harfbuzzLibraryStem*(library: HarfBuzzLibrary): string =
  ## Returns the library basename without a platform prefix, suffix, or version.
  case library
  of HarfBuzzLibrary.Core: "harfbuzz"
  of HarfBuzzLibrary.Subset: "harfbuzz-subset"
  of HarfBuzzLibrary.Icu: "harfbuzz-icu"

proc libraryNames(library: HarfBuzzLibrary): seq[string] =
  let override =
    case library
    of HarfBuzzLibrary.Core: harfbuzzDynlib
    of HarfBuzzLibrary.Subset: harfbuzzSubsetDynlib
    of HarfBuzzLibrary.Icu: harfbuzzIcuDynlib
  if override.len > 0:
    return @[override]
  let stem = harfbuzzLibraryStem(library)
  when defined(windows):
    result = @[stem & ".dll", "lib" & stem & "-0.dll", "lib" & stem & ".dll"]
  elif defined(macosx):
    result = @["lib" & stem & ".0.dylib", "lib" & stem & ".dylib"]
    for prefix in ["/opt/homebrew/opt/harfbuzz/lib/", "/usr/local/opt/harfbuzz/lib/"]:
      result.add prefix & "lib" & stem & ".0.dylib"
  else:
    result = @["lib" & stem & ".so.0", "lib" & stem & ".so"]

proc registerHarfbuzzImports*(library: HarfBuzzLibrary, binder: ImportBinder) =
  ## Internal registration used by the generated import blocks.
  withLock loaderLock:
    binders[library].add binder
    if handles[library] != nil:
      binder(handles[library])

proc loadHarfbuzz*(library = HarfBuzzLibrary.Core, path = "") {.gcsafe.} =
  ## Loads a library and resolves its C procedure pointers once.
  ## Call before using that library's API, including before starting workers.
  ## `path` overrides platform discovery and the corresponding string define.
  ## Raises `HarfBuzzLoadError` on failure; failed loads can be retried.
  ## Optional symbols absent from the loaded version remain nil.
  ## Successful libraries stay loaded and cannot be replaced.
  {.cast(gcsafe).}:
    withLock loaderLock:
      if handles[library] != nil:
        if path.len > 0 and path != $loadedPaths[library]:
          raise newException(ValueError, "HarfBuzz " & $library & " is already loaded")
        return
      let names =
        if path.len > 0:
          @[path]
        else:
          libraryNames(library)
      let sentinel =
        case library
        of HarfBuzzLibrary.Core: "hb_version_atleast"
        of HarfBuzzLibrary.Subset: "hb_subset_input_create_or_fail"
        of HarfBuzzLibrary.Icu: "hb_icu_get_unicode_funcs"
      for name in names:
        let handle = loadLib(name)
        if handle == nil:
          continue
        if symAddr(handle, sentinel.cstring) == nil:
          unloadLib(handle)
          raise newException(
            HarfBuzzLoadError, "missing HarfBuzz symbol: " & sentinel & " in " & name
          )
        for binder in binders[library]:
          binder(handle)
        handles[library] = handle
        loadedPaths[library] = cast[cstring](allocShared0(name.len + 1))
        copyMem(loadedPaths[library], name.cstring, name.len)
        return
      raise newException(
        HarfBuzzLoadError,
        "could not load HarfBuzz " & $library & "; tried: " & names.join(", "),
      )
