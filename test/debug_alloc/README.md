# Debug-allocator fixture lane

These fixtures give the test floor **eyes for the over/under-drop blind spot** it
is structurally unable to see (the floor has zero `Vec[Drop]`). Each is run under
the native debug allocator and checked against its `//! expect-debug-alloc:`
directive. Run the lane with:

```
with build :debug-alloc-tests
```

(which builds `tools/debug_drop.w` and runs it in `check` mode over this corpus).

The directives are now soundness gates for #607's inline-drop field ownership
work. Inline-drop fields must be freed exactly once in every covered
construction and escape shape: `leak count=0`, never `DOUBLE FREE`.

- The `da_vecdrop_*` fixtures cover inline `Vec[Drop]` fields across in-place
  construction, local move-in, rvalue move-in, nested structs, tail/trailing
  positions, field-receiver push tails, and field chaining. They all expect
  `leak count=0`.
- `da_manual_double_free` (`with_free` twice) expects `DOUBLE FREE` — a stable,
  compiler-independent check that the ledger detects a double free.
- `da_pod_vec` expects `leak count=1` — a POD `Vec[i32]` buffer is not freed under
  the narrow drop gate (#608, separate from #607; documented here so the
  instrument's view of it is pinned).

See `docs/debug-allocator.md` for the design and `tools/debug_drop*.lldb` for
resolving the source sites behind a flagged address.
