"""Rebuild the synthetic test fonts with fontTools (no third-party font data)."""
from pathlib import Path

from fontTools.feaLib.builder import addOpenTypeFeaturesFromString
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import newTable
from fontTools.ttLib.tables._f_v_a_r import Axis
from fontTools.ttLib.tables.TupleVariation import TupleVariation

DEST = Path(__file__).parent


def draw(pen, cubic=False):
    pen.moveTo((100, 0))
    pen.lineTo((500, 0))
    if cubic:
        pen.curveTo((600, 100), (600, 500), (100, 600))
    else:
        pen.qCurveTo((500, 600), (100, 600))
    pen.closePath()


def build(cubic=False, cmap=None, ascent=800, descent=-200, marks=()):
    if cmap is None:
        cmap = {32: "space", 65: "A"}
    order = [".notdef", *cmap.values()]
    font = FontBuilder(1000, isTTF=not cubic)
    font.setupGlyphOrder(order)
    font.setupCharacterMap(cmap)
    font.setupHorizontalMetrics({name: (0 if name in marks else 700, 100 if name != "space" else 0)
                                 for name in order})
    font.setupHorizontalHeader(ascent=ascent, descent=descent)
    font.setupNameTable({"familyName": "Outline Fixture", "styleName": "Regular",
                         "uniqueFontIdentifier": "OutlineFixture", "fullName": "Outline Fixture",
                         "psName": "OutlineFixture"})
    font.setupOS2(sTypoAscender=ascent, sTypoDescender=descent,
                  usWinAscent=ascent, usWinDescent=-descent)
    font.setupPost()
    if cubic:
        glyphs = {}
        for name in order:
            pen = T2CharStringPen(700, None)
            if name != "space":
                draw(pen, cubic=True)
            glyphs[name] = pen.getCharString()
        font.setupCFF("OutlineFixture", {}, glyphs, {})
    else:
        glyphs = {}
        for name in order:
            pen = TTGlyphPen(None)
            if name != "space":
                draw(pen)
            glyphs[name] = pen.glyph()
        font.setupGlyf(glyphs)
    font.setupMaxp()
    font.font["head"].created = font.font["head"].modified = 2082844800
    font.font.recalcTimestamp = False
    return font


build(cubic=True).save(DEST / "cubic.otf")
font = build()
font.save(DEST / "quadratic.ttf")
# One synthetic weight axis moves the right edge by 100 design units.
axis = Axis()
axis.axisTag, axis.minValue, axis.defaultValue, axis.maxValue = "wght", 100, 100, 900
axis.flags, axis.axisNameID = 0, 256
font.font["name"].setName("Weight", 256, 3, 1, 0x409)
font.font["fvar"] = newTable("fvar")
font.font["fvar"].axes, font.font["fvar"].instances = [axis], []
font.font["gvar"] = newTable("gvar")
font.font["gvar"].variations = {name: [] for name in font.font.getGlyphOrder()}
coordinates, _, _ = font.font["glyf"]["A"].getCoordinates(font.font["glyf"])
deltas = [(100 if x == 500 else 0, 0) for x, y in coordinates] + [(0, 0)] * 4
font.font["gvar"].variations["A"] = [TupleVariation({"wght": (0, 1, 1)}, deltas)]
font.save(DEST / "variable.ttf")

# A fallback with different vertical metrics, Arabic joining, and a positioned mark.
font = build(
    cmap={32: "space", 0x0628: "beh", 0x0650: "kasra",
          0xFE91: "beh.init", 0xFE92: "beh.medi", 0xFE90: "beh.fina"},
    ascent=650, descent=-350, marks=("kasra",),
)
addOpenTypeFeaturesFromString(font.font, """
languagesystem DFLT dflt;
languagesystem arab dflt;
feature init { sub beh by beh.init; } init;
feature medi { sub beh by beh.medi; } medi;
feature fina { sub beh by beh.fina; } fina;
markClass kasra <anchor 100 500> @Below;
feature mark { pos base [beh beh.init beh.medi beh.fina] <anchor 350 200> mark @Below; } mark;
""")
font.save(DEST / "layout.ttf")
