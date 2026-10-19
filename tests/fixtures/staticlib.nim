## Link both native libraries into a shared library to check archive PIC flags.
import harfbuzzy/raw
import harfbuzzy/fribidi_raw

proc harfbuzzyVersion*(): cstring {.exportc, dynlib.} =
  raw.hb_version_string()

proc harfbuzzyBidiType*(ch: uint32): uint32 {.exportc, dynlib.} =
  fribidi_raw.fribidi_get_bidi_type(ch)
