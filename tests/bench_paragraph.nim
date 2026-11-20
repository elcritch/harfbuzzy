## Run with a primary font and an optional fallback font.
##   nim r -d:release tests/bench_paragraph.nim font.ttf [fallback.ttf]
import std/[algorithm, monotimes, os, strformat, strutils, times]
import harfbuzzy

when declared(loadHarfbuzz):
  loadHarfbuzz()
when declared(loadFribidi):
  loadFribidi()

proc bench(context: ShapeContext, name, text: string) =
  const Iterations = 100
  var samples: seq[float]
  var glyphs = 0
  for sample in 0 .. 7:
    let start = getMonoTime()
    for iteration in 0 ..< Iterations:
      let paragraph = context.shapeParagraph(text)
      glyphs = 0
      for run in paragraph.logicalRuns:
        glyphs += run.len
    let elapsed = (getMonoTime() - start).inNanoseconds.float / (1000 * Iterations)
    if sample > 0:
      samples.add elapsed
  samples.sort()
  echo &"{name:<12} {samples[3]:8.1f} us/paragraph   {glyphs} glyphs"

when isMainModule:
  if paramCount() notin 1 .. 2:
    quit "usage: bench_paragraph primary.ttf [fallback.ttf]"
  var faces = @[typefaceFromFile(paramStr(1))]
  if paramCount() == 2:
    faces.add typefaceFromFile(paramStr(2))
  let context = initShapeContext(faces)
  for (name, phrase) in [
    ("ASCII", "The quick brown fox balances the width of a line. "),
    ("Accented", "Le café équilibre la largeur de la première ligne. "),
    (
      "Mixed bidi",
      "Page 42 שלום עולם (123) مرحبا بالعالم — Café. ",
    ),
  ]:
    bench(context, name, phrase.repeat(48))
