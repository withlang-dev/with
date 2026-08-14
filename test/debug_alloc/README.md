# Debug-allocator fixture lane

These fixtures give the test floor **eyes for the over/under-drop blind spot** it
is structurally unable to see (the floor has zero `Vec[Drop]`). Each is run under
the native debug allocator and checked against its `//! expect-debug-alloc:`
directive. A fixture may also set `//! debug-alloc-filter: all|non-root|roots`
to select the leak view for that test. Run the lane with:

```
with build :debug-alloc-tests
```

(which builds `tools/debug_drop.w` and runs it in `check` mode over this corpus).

The directives are now soundness gates for #607's inline-drop field ownership
work. Inline-drop fields must be freed exactly once in every covered
construction and escape shape: `leak count=0`, never `DOUBLE FREE`.

- The `da_vecdrop_*` fixtures cover inline `Vec[Drop]` fields across in-place
  construction, local move-in, rvalue move-in, tuple elements, nominal enum and
  generic `Option` payloads, nested structs, tail/trailing positions,
  field-receiver push tails, and field chaining. They all expect
  `leak count=0`.
- `da_vecdrop_struct_field_owned_elements`, `da_vecdrop_tuple_field`,
  `da_vecdrop_nested_struct_field`, `da_vecdrop_enum_payload`,
  `da_vecdrop_option_payload`, and `da_drop_array_field` use `Drop` elements
  that own native allocations. A missed element drop leaks; a duplicate element
  drop double-frees.
- `da_vecdrop_field_reassign_owned_elements`,
  `da_drop_tuple_field_reassign_owned_elements`, and
  `da_vecdrop_moved_var_reassign` cover straight-line drop-obligation updates:
  field assignment drops the old contents before overwrite, moved locals can be
  reinitialized, and replacement contents drop at scope exit.
- `da_drop_tuple_field_extract_early_return` and
  `da_drop_tuple_field_extract_defer_return` cover path-sensitive cleanup for
  tuple field moves across early-return/fallthrough cleanup paths, including an
  active `defer`.
- `da_drop_struct_tuple_field`, `da_drop_struct_option_field`, and
  `da_drop_nested_struct_tuple_field` (A6) cover Drop values embedded in an
  aggregate that is itself a struct field — a `(W, W)` tuple field, an
  `Option[W]` field, and a tuple field two struct levels deep. Together with
  `da_drop_array_field`, `da_vecdrop_struct_field_owned_elements`, and
  `da_vecdrop_nested_struct_field` they pin the nested
  aggregate-in-struct-field drop matrix: every element freed exactly once at
  the owner's scope exit.
- `da_drop_conditional_move_value` and `da_match_conditional_move_value` cover
  the runtime drop-flag path: whole `Drop` locals moved in one side of an `if`
  or one arm of a `match` are dropped exactly once on both moved and not-moved
  paths.
- `da_channel_task_fiber` spawns producer/consumer fibers with channel endpoints
  moved into each task and awaits both; it expects `leak count=0`. It pins
  fiber-lifecycle cleanup at shutdown: pooled fiber control blocks
  (`origin=fiber`) must be freed before the ledger is walked, not reported as
  leaks.
- `da_manual_double_free` (`with_free` twice) expects `DOUBLE FREE` — a stable,
  compiler-independent check that the ledger detects a double free.
- `da_drop_origin_double_free` duplicates a `Vec[Drop]` header and explicitly
  drops both values; it expects `first_drop=drop#` so generated drop tags stay
  wired through MIR, codegen, and the allocator ledger.
- `da_str_split_lines_owned_parts` forces allocator reuse while `split` and
  `lines` results remain live, proving their raw runtime pushes transfer each
  owned string into the result Vec instead of freeing a retained header.
- `da_root_filter` marks a deliberately leaked allocation as a process-lifetime
  root and runs with `debug-alloc-filter: non-root`; it expects `leak count=0`.
- `da_pod_vec` expects `leak count=1` — a POD `Vec[i32]` buffer is not freed under
  the narrow drop gate (#608, separate from #607; documented here so the
  instrument's view of it is pinned).

See `docs/debug-allocator.md` for the design and `tools/debug_drop*.lldb` for
resolving the source sites behind a flagged address.
