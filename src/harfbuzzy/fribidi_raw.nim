## Minimal FriBidi bindings used by the paragraph shaping pipeline.

const fribidiStatic =
  (defined(harfbuzzyStatic) or defined(features.harfbuzzy.static)) and
  not defined(harfbuzzyNoFribidi)

when defined(macosx) or fribidiStatic:
  import std/os

when not fribidiStatic:
  import std/[dynlib, locks, strutils]

when fribidiStatic:
  import harfbuzzy/private/staticHarfbuzz

  when defined(vcc):
    {.
      passC:
        "/I" & quoteShell(staticHarfbuzz.fribidiIncludeDir) & " /DFRIBIDI_LIB_STATIC"
    .}
  else:
    {.
      passC:
        "-I" & quoteShell(staticHarfbuzz.fribidiIncludeDir) & " -DFRIBIDI_LIB_STATIC"
    .}
  {.passL: quoteShell(staticHarfbuzz.fribidiStaticLib).}
  {.pragma: fribidiImport, header: "fribidi.h".}

const fribidiDynlibOverride* {.strdefine: "harfbuzzyFribidiDynlib".} = ""

when defined(macosx) and not fribidiStatic:
  const fribidiDetectedBrewPrefix = staticExec(
    "sh -c 'if command -v brew >/dev/null 2>&1; then brew --prefix fribidi 2>/dev/null | tr -d \"\\n\"; fi'"
  )
else:
  const fribidiDetectedBrewPrefix = ""

const fribidiLib* =
  when fribidiDynlibOverride.len > 0:
    fribidiDynlibOverride
  elif defined(windows):
    "fribidi.dll"
  elif defined(macosx) and fribidiDetectedBrewPrefix.len > 0:
    fribidiDetectedBrewPrefix / "lib" / "libfribidi.dylib"
  elif defined(macosx):
    "libfribidi.dylib"
  else:
    "libfribidi.so(|.0)"

type
  FriBidiBoolean* = cint
  FriBidiChar* = uint32
  FriBidiStrIndex* = cint
  FriBidiCharType* = uint32
  FriBidiBracketType* = uint32
  FriBidiFlags* = uint32
  FriBidiLevel* = int8
  FriBidiParType* = uint32

const
  FRIBIDI_MASK_RTL* = FriBidiCharType(0x00000001)
  FRIBIDI_MASK_ARABIC* = FriBidiCharType(0x00000002)
  FRIBIDI_MASK_STRONG* = FriBidiCharType(0x00000010)
  FRIBIDI_MASK_LETTER* = FriBidiCharType(0x00000100)
  FRIBIDI_MASK_NEUTRAL* = FriBidiCharType(0x00000040)

  FRIBIDI_TYPE_LTR* = FriBidiCharType(0x00000110)
  FRIBIDI_TYPE_RTL* = FriBidiCharType(0x00000111)
  FRIBIDI_TYPE_AL* = FriBidiCharType(0x00000113)
  FRIBIDI_TYPE_ON* = FriBidiCharType(0x00000040)

  FRIBIDI_PAR_LTR* = FriBidiParType(FRIBIDI_TYPE_LTR)
  FRIBIDI_PAR_RTL* = FriBidiParType(FRIBIDI_TYPE_RTL)
  FRIBIDI_PAR_ON* = FriBidiParType(FRIBIDI_TYPE_ON)
  FRIBIDI_PAR_WLTR* = FriBidiParType(0x00000020)
  FRIBIDI_PAR_WRTL* = FriBidiParType(0x00000021)

  FRIBIDI_FLAGS_DEFAULT* = FriBidiFlags(0x00040003)

func fribidi_level_is_rtl*(level: FriBidiLevel): bool =
  (level.int and 1) != 0

func fribidi_is_rtl*(typ: FriBidiCharType): bool =
  (typ and FRIBIDI_MASK_RTL) != 0

func fribidi_is_arabic*(typ: FriBidiCharType): bool =
  (typ and FRIBIDI_MASK_ARABIC) != 0

when fribidiStatic:
  proc fribidi_get_bidi_type*(
    ch: FriBidiChar
  ): FriBidiCharType {.cdecl, importc: "fribidi_get_bidi_type", fribidiImport.}

  proc fribidi_get_bidi_types*(
    str: ptr FriBidiChar, len: FriBidiStrIndex, btypes: ptr FriBidiCharType
  ) {.cdecl, importc: "fribidi_get_bidi_types", fribidiImport.}

  proc fribidi_get_bracket_types*(
    str: ptr FriBidiChar,
    len: FriBidiStrIndex,
    types: ptr FriBidiCharType,
    btypes: ptr FriBidiBracketType,
  ) {.cdecl, importc: "fribidi_get_bracket_types", fribidiImport.}

  proc fribidi_get_par_embedding_levels_ex*(
    bidiTypes: ptr FriBidiCharType,
    bracketTypes: ptr FriBidiBracketType,
    len: FriBidiStrIndex,
    pbaseDir: ptr FriBidiParType,
    embeddingLevels: ptr FriBidiLevel,
  ): FriBidiLevel {.
    cdecl, importc: "fribidi_get_par_embedding_levels_ex", fribidiImport
  .}

else:
  type FriBidiLoadError* = object of CatchableError
    ## FriBidi or a required symbol could not be loaded.

  var
    fribidi_get_bidi_type*:
      proc(ch: FriBidiChar): FriBidiCharType {.cdecl, gcsafe, raises: [].}
    fribidi_get_bidi_types*: proc(
      str: ptr FriBidiChar, len: FriBidiStrIndex, btypes: ptr FriBidiCharType
    ) {.cdecl, gcsafe, raises: [].}
    fribidi_get_bracket_types*: proc(
      str: ptr FriBidiChar,
      len: FriBidiStrIndex,
      types: ptr FriBidiCharType,
      btypes: ptr FriBidiBracketType,
    ) {.cdecl, gcsafe, raises: [].}
    fribidi_get_par_embedding_levels_ex*: proc(
      bidiTypes: ptr FriBidiCharType,
      bracketTypes: ptr FriBidiBracketType,
      len: FriBidiStrIndex,
      pbaseDir: ptr FriBidiParType,
      embeddingLevels: ptr FriBidiLevel,
    ): FriBidiLevel {.cdecl, gcsafe, raises: [].}
    fribidiLock: Lock
    fribidiHandle: LibHandle
    # Shared path has the same process lifetime as the library handle.
    fribidiLoadedPath: cstring

  initLock(fribidiLock)

  proc loadFribidi*(path = "") {.gcsafe.} =
    ## Load FriBidi before using paragraph shaping or its raw procedures.
    ## A path overrides platform discovery and the compile-time override.
    ## Failed loads can be retried; successful libraries stay loaded for the process lifetime.
    ## Call before starting workers that use FriBidi.
    {.cast(gcsafe).}:
      withLock fribidiLock:
        if fribidiHandle != nil:
          if path.len > 0 and path != $fribidiLoadedPath:
            raise newException(ValueError, "FriBidi is already loaded")
          return
        var names =
          if path.len > 0:
            @[path]
          elif fribidiDynlibOverride.len > 0:
            var candidates: seq[string]
            libCandidates(fribidiDynlibOverride, candidates)
            candidates
          elif defined(windows):
            @["fribidi.dll", "libfribidi-0.dll", "libfribidi.dll"]
          elif defined(macosx):
            @[
              "libfribidi.0.dylib", "libfribidi.dylib",
              "/opt/homebrew/opt/fribidi/lib/libfribidi.0.dylib",
              "/usr/local/opt/fribidi/lib/libfribidi.0.dylib",
            ]
          else:
            @["libfribidi.so.0", "libfribidi.so"]
        when defined(macosx) and fribidiDetectedBrewPrefix.len > 0:
          if path.len == 0 and fribidiDynlibOverride.len == 0:
            names.add fribidiDetectedBrewPrefix / "lib" / "libfribidi.dylib"
        for name in names:
          let handle = loadLib(name)
          if handle != nil:
            let symbols = [
              symAddr(handle, "fribidi_get_bidi_type"),
              symAddr(handle, "fribidi_get_bidi_types"),
              symAddr(handle, "fribidi_get_bracket_types"),
              symAddr(handle, "fribidi_get_par_embedding_levels_ex"),
            ]
            const symbolNames = [
              "fribidi_get_bidi_type", "fribidi_get_bidi_types",
              "fribidi_get_bracket_types", "fribidi_get_par_embedding_levels_ex",
            ]
            for i, symbol in symbols:
              if symbol == nil:
                unloadLib(handle)
                raise newException(
                  FriBidiLoadError,
                  "missing FriBidi symbol: " & symbolNames[i] & " in " & name,
                )
            fribidi_get_bidi_type = cast[typeof(fribidi_get_bidi_type)](symbols[0])
            fribidi_get_bidi_types = cast[typeof(fribidi_get_bidi_types)](symbols[1])
            fribidi_get_bracket_types =
              cast[typeof(fribidi_get_bracket_types)](symbols[2])
            fribidi_get_par_embedding_levels_ex =
              cast[typeof(fribidi_get_par_embedding_levels_ex)](symbols[3])
            fribidiHandle = handle
            fribidiLoadedPath = cast[cstring](allocShared0(name.len + 1))
            copyMem(fribidiLoadedPath, name.cstring, name.len)
            return
        raise newException(
          FriBidiLoadError, "could not load FriBidi; tried: " & names.join(", ")
        )

  when not (
    defined(harfbuzzRuntime) or defined(harfbuzzyFribidiRuntime) or
    defined(feature.harfbuzzy.runtime) or defined(features.harfbuzzy.runtime)
  ):
    try:
      loadFribidi()
    except FriBidiLoadError:
      discard
