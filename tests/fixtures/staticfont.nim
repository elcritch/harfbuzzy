## Compile OpenType font setup without pulling in the subset or AAT headers.
import harfbuzzy/raw

let font = hb_font_create(hb_face_get_empty())
doAssert font != nil
hb_ot_font_set_funcs(font)
var glyph: HbCodepoint
doAssert hb_font_get_nominal_glyph(font, 65, addr glyph) == 0
hb_font_destroy(font)
