## Derive the runtime APIs used by HarfBuzzy from upstream C declarations.
import std/[macros, dynlib]
import harfbuzzy/runtime

macro bindRuntimeLibrary(
    library: static[HarfBuzzLibrary], procedures: varargs[typed]
): untyped =
  result = newStmtList()
  let handle = genSym(nskParam, "handle")
  let assignments = newStmtList()
  for symbol in procedures:
    if symbol.kind != nnkSym or symbol.symKind != nskProc:
      error("expected an imported C procedure", symbol)
    let signature = symbol.getTypeInst.copyNimTree()
    signature[1] = newTree(
      nnkPragma,
      ident"cdecl",
      ident"gcsafe",
      newColonExpr(ident"raises", newNimNode(nnkBracket)),
    )
    for params in signature[0]:
      if params.kind == nnkIdentDefs:
        for i in 0 ..< params.len - 2:
          params[i] = ident(params[i].strVal)
    let name = ident(symbol.strVal)
    result.add newTree(
      nnkVarSection, newIdentDefs(postfix(name, "*"), signature.copyNimTree())
    )
    assignments.add newAssignment(
      name,
      newTree(
        nnkCast, signature, newCall(bindSym"symAddr", handle, newLit(symbol.strVal))
      ),
    )
  let binder = genSym(nskProc, "bindImports")
  result.add newProc(
    binder,
    params = [newEmptyNode(), newIdentDefs(handle, bindSym"LibHandle")],
    body = assignments,
    pragmas = newTree(
      nnkPragma, ident"gcsafe", newColonExpr(ident"raises", newNimNode(nnkBracket))
    ),
  )
  result.add newCall(bindSym"registerHarfbuzzImports", newLit(library), binder)

macro bindRuntimeProcs*(source: untyped, groups: untyped): untyped =
  result = newStmtList()
  let exports = newTree(nnkExportExceptStmt, source.copyNimTree())
  for group in groups:
    let call = newCall(bindSym"bindRuntimeLibrary", group[0])
    group.expectKind(nnkCall)
    group[1].expectKind(nnkStmtList)
    group[1][0].expectKind(nnkBracket)
    for name in group[1][0]:
      exports.add name.copyNimTree()
      call.add newDotExpr(source.copyNimTree(), name.copyNimTree())
    result.add call
  result.add exports
