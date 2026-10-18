## Link a real HarfBuzz symbol into a shared library to check archive PIC flags.
import harfbuzzy/raw

proc harfbuzzyVersion*(): cstring {.exportc, dynlib.} =
  raw.hb_version_string()
