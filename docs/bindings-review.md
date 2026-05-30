# Binding Review Notes

## Sources Reviewed

- `deps/harfbuzz/src`: HarfBuzz 14.2.0 public C headers.
- `deps/harfbuzz-bindings`: Rust bindgen wrapper over `hb.h`, `hb-ot.h`,
  `hb-aat.h`, and `hb-subset.h`.
- `deps/luaharfbuzz`: manual Lua wrapper for the practical HarfBuzz surface:
  blobs, faces, fonts, buffers, tags, scripts, languages, features, sets, shape,
  OpenType helpers, and subset input.

## c2nim Result

`tools/generate_raw_bindings.sh` runs `c2nim` with the directive file in
`tools/harfbuzz.c2nim`. Direct generation succeeds as a seed, but the output is
not suitable as the final raw layer without curation:

- C enum domains are emitted as Nim `enum`; the checked-in raw layer uses
  distinct integer types for ABI stability.
- Macro helpers such as `HB_UNTAG` need hand-written Nim equivalents or should
  be omitted.
- Platform typedef branches produce noise for MSVC-only integer aliases.
- Ownership is not expressible in generated raw declarations.

The checked-in `harfbuzzy/raw` module is therefore a curated raw binding over
the same header set, with struct layout checks in `tests/tharfbuzzy.nim`.

## Ownership Notes

HarfBuzz handles use internal reference counts. The public Nim wrappers are
small value handles whose `=copy`/`=dup` call `hb_*_reference` and whose
`=destroy` calls `hb_*_destroy`.

One luaharfbuzz issue worth avoiding: `hb_subset_input_unicode_set()` returns a
borrowed set owned by the subset input, but luaharfbuzz wraps it as a normal
`Set` userdata with a `__gc` destructor. `harfbuzzy` does not expose that
borrowed set as an owning `Set`; it provides `inclUnicode` and `inclGlyph`
helpers that mutate the borrowed set without taking ownership.
