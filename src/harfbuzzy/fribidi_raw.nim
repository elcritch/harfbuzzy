## Minimal FriBidi bindings used by the paragraph shaping pipeline.

import std/os

const fribidiDynlibOverride* {.strdefine: "harfbuzzyFribidiDynlib".} = ""

when defined(macosx):
  const fribidiDetectedBrewPrefix = staticExec(
    "sh -c 'if command -v brew >/dev/null 2>&1; then brew --prefix fribidi 2>/dev/null | tr -d \"\\n\"; fi'"
  )
else:
  const fribidiDetectedBrewPrefix = ""

const fribidiIncludeDir =
  when defined(macosx) and fribidiDetectedBrewPrefix.len > 0:
    fribidiDetectedBrewPrefix / "include" / "fribidi"
  else:
    ""

when fribidiIncludeDir.len > 0:
  {.passC: "-I" & fribidiIncludeDir.}

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

proc fribidi_get_bidi_type*(
  ch: FriBidiChar
): FriBidiCharType {.cdecl, importc: "fribidi_get_bidi_type", dynlib: fribidiLib.}

proc fribidi_get_bidi_types*(
  str: ptr FriBidiChar, len: FriBidiStrIndex, btypes: ptr FriBidiCharType
) {.cdecl, importc: "fribidi_get_bidi_types", dynlib: fribidiLib.}

proc fribidi_get_bracket_types*(
  str: ptr FriBidiChar,
  len: FriBidiStrIndex,
  types: ptr FriBidiCharType,
  btypes: ptr FriBidiBracketType,
) {.cdecl, importc: "fribidi_get_bracket_types", dynlib: fribidiLib.}

proc fribidi_get_par_embedding_levels_ex*(
  bidiTypes: ptr FriBidiCharType,
  bracketTypes: ptr FriBidiBracketType,
  len: FriBidiStrIndex,
  pbaseDir: ptr FriBidiParType,
  embeddingLevels: ptr FriBidiLevel,
): FriBidiLevel {.
  cdecl, importc: "fribidi_get_par_embedding_levels_ex", dynlib: fribidiLib
.}
