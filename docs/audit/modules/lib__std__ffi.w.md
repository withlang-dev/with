# Primary verification — `lib/std/ffi.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 70 lines (single complete read)

## Scope examined

`box_ctx[T]` (`:37`, `Box.new` erased to `*mut c_void`),
`ctx_ref[T]` (`:44`, unsafe borrow-back), `unbox_ctx[T]` (`:49`,
move-out + `with_free`), `drop_ctx[T]` (`:56`, drop glue +
`with_free`), plus the documented per-type destroy-trampoline
pattern (`:61`-`:70`, no generic trampoline by design — no
per-instantiation C-ABI symbol guarantee). Dep: `std.box`.
Callers: none in `lib/`/`rt/`/`tests/`/`examples/`; sole in-tree
reference is the heap-constructor allowlist in
`src/SemaCheck.w:5261,5267` (`box_ctx` alongside `Box.new`/
`Rc.new`/`Arc.new`), which is consistent with the implementation.
Spec home: §16.7 (callback pattern) names stdlib boxing helpers;
§16.11 (raw-pointer/`unsafe` boundary) covers the recovery side.
No ffi test files.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/ffi/roundtrip.w` (oracle: literal value
  preservation — boxed inputs must read back identical):
  i32 `41` via box → raw deref → `ctx_ref` borrow → `unbox_ctx`;
  `State { count: 7 }` struct via box → `ctx_ref` → `unbox_ctx`;
  module-doc destroy-trampoline pattern
  (`fn destroy_state(ctx: *mut c_void)` → `drop_ctx`) on
  `State { count: 9 }`; `Drop`-counting guard proves no drop at box
  time and exactly one drop on the `drop_ctx` path
  (`FFI_DROP_TRACE == "D"`). Prints `ffi-roundtrip-ok`. PASS.
- `with check lib/std/ffi.w` → ok (stage1).

## Findings

None. In-report notes (not filed):

- The module doc (`:32`-`:36`) openly discloses that boxing a
  borrow-holding ephemeral is not yet rejected at compile time and
  that the `unsafe` recovery helpers are the backstop (same gap as
  `Box.new[T]`). Refutation attempt: no new evidence needed or
  sought — this is a disclosed limitation with an accurate in-source
  warning, not an undisclosed defect; per task scope no issue filed.
- `unbox_ctx`/`drop_ctx` both `with_free` the same allocation
  `box_ctx` created, and `ctx_ref` performs no free — exactly-once
  ownership transfer verified by the Drop-counting leg of the probe.

Verdict: COMPLETE
