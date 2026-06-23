# Debug-allocator fixture lane

These fixtures give the test floor **eyes for the over/under-drop blind spot** it
is structurally unable to see (the floor has zero `Vec[Drop]`). Each is run under
the native debug allocator and checked against its `//! expect-debug-alloc:`
directive. Run the lane with:

```
with build :debug-alloc-tests
```

(which builds `tools/debug_drop.w` and runs it in `check` mode over this corpus).

**The directives document CURRENT runtime reality, including the #606 bug** — they
assert *what the instrument observes today*, not what soundness requires:

- `da_vecdrop_taillet_movein` / `da_vecdrop_inplace_trailing` expect `leak count=1`
  — these reproduce the context-sensitive #606 inline-drop-field leak. When #606 is
  fixed they will report `leak count=0` and the lane will fail; that failure is the
  signal to update the directive to `count=0`.
- `da_manual_double_free` (`with_free` twice) expects `DOUBLE FREE` — a stable,
  compiler-independent check that the ledger detects a double free.
- `da_pod_vec` expects `leak count=1` — a POD `Vec[i32]` buffer is not freed under
  the narrow drop gate (a separate behavior from #606; documented here so the
  instrument's view of it is pinned).
- The remaining `count=0` fixtures are sound constructions (the field's buffer is
  freed exactly once) and stay green regardless of #606.

See `docs/debug-allocator.md` for the design and `tools/debug_drop*.lldb` for
resolving the source sites behind a flagged address.
