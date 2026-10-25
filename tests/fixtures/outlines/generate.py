"""Rebuild the synthetic test fonts with fontTools (no third-party font data)."""
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import newTable
from fontTools.ttLib.tables._f_v_a_r import Axis
from fontTools.ttLib.tables.TupleVariation import TupleVariation

DEST = Path(__file__).parent
ORDER = [".notdef", "space", "A"]


def draw(pen, cubic=False):
    pen.moveTo((100, 0))
    pen.lineTo((500, 0))
    if cubic:
        pen.curveTo((600, 100), (600, 500), (100, 600))
    else:
        pen.qCurveTo((500, 600), (100, 600))
    pen.closePath()


def build(cubic=False):
    font = FontBuilder(1000, isTTF=not cubic)
    font.setupGlyphOrder(ORDER)
    font.setupCharacterMap({32: "space", 65: "A"})
    font.setupHorizontalMetrics({name: (700, 100 if name != "space" else 0) for name in ORDER})
    font.setupHorizontalHeader(ascent=800, descent=-200)
    font.setupNameTable({"familyName": "Outline Fixture", "styleName": "Regular",
                         "uniqueFontIdentifier": "OutlineFixture", "fullName": "Outline Fixture",
                         "psName": "OutlineFixture"})
    font.setupOS2(sTypoAscender=800, sTypoDescender=-200, usWinAscent=800, usWinDescent=200)
    font.setupPost()
    if cubic:
        glyphs = {}
        for name in ORDER:
            pen = T2CharStringPen(700, None)
            if name != "space":
                draw(pen, cubic=True)
            glyphs[name] = pen.getCharString()
        font.setupCFF("OutlineFixture", {}, glyphs, {})
    else:
        glyphs = {}
        for name in ORDER:
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
font.font["gvar"].variations = {name: [] for name in ORDER}
coordinates, _, _ = font.font["glyf"]["A"].getCoordinates(font.font["glyf"])
deltas = [(100 if x == 500 else 0, 0) for x, y in coordinates] + [(0, 0)] * 4
font.font["gvar"].variations["A"] = [TupleVariation({"wght": (0, 1, 1)}, deltas)]
font.save(DEST / "variable.ttf")
