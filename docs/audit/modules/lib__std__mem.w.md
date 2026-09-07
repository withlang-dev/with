# Primary verification — `lib/std/mem.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 51 lines (single complete read)

## Scope examined

Thin safe wrappers over the `with_*` freelist runtime in `rt/rt_core.w`:
`alloc` (`:18`), `alloc_zeroed` (`:22`), `realloc_mem` (`:26`),
`free_mem` (`:31`), `mem_copy` (`:35`), `mem_move` (`:40`),
`mem_set` (`:45`), `mem_cmp` (`:50`). No `c_import`; all work goes
through `extern fn with_alloc/with_alloc_zeroed/with_realloc/with_free/
with_free_sized/with_memcpy/with_memmove/with_memset/with_memcmp`.
Callers of `use std.mem`: `lib/std/alloc.w:3` (uses `free_mem`,
`mem_set`, `mem_copy`, `alloc_zeroed` at `:141`-`:367`) and
`test/behavior/issue70_small_free_reuse.w:3` (freelist reuse +
zeroing). Sibling modules (`box`, `rc`, `sync`, `string`, `sys`,
`zlib/*`, `re/*`) call the same `with_*` externs directly rather
than through `std.mem`; `with_free_sized` is declared but unused by
any `std.mem` wrapper (no wrapper exposes it).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/mem/probe.w` (via `out/bootstrap/bin/with-stage1
  run`): alloc-nonzero, `mem_set` fill + direct unsafe byte read,
  `alloc_zeroed` vs filled `mem_cmp != 0`, `mem_copy` round-trip to
  `mem_cmp == 0`, single-byte mutation visible through `mem_cmp`,
  overlapping `mem_move(a, a+1, 15)` on `[1, 7x14, 2]` producing
  `[7x14, 2, 2]` verified against an independently built expectation
  buffer (`mem_cmp == 0`), `realloc_mem(8 -> 64)` 8-byte prefix
  preserved (`mem_cmp == 0`), all frees. Output `ok`. PASS. Oracle:
  libc-documented memcpy/memmove/memset/memcmp semantics (overlap
  rule, fill rule, 3-way compare) — expectation derived by hand from
  those rules, not from the implementation.
- `with check lib/std/mem.w` → ok (stage1).
- Existing `test/behavior/issue70_small_free_reuse.w`
  (expect-stdout `ok`): covers 64-B freelist slot reuse identity and
  `alloc_zeroed` zeroing; read, not re-run (HELD — suite-owned).

## Findings

None. In-report notes (not filed):

- `realloc_mem` passes `old_size = 0` ("fallback path in allocator",
  `:27`); the prefix-preservation probe above confirms the fallback
  grows correctly for the exercised 8→64 case. Refutation attempt:
  shrinking or huge growth through the fallback is untested here —
  but the wrapper documents the delegation, and no caller in-repo
  depends on old-size fast-path behavior.
- Wrapper sizes are `i32` while the runtime takes `i64`; allocations
  above 2 GiB would truncate at the wrapper boundary. Refutation
  attempt: the API documents failure as a 0 return, all in-repo
  callers allocate small objects, and no probe or test approaches
  the bound — an API limit, not a silent wrong result.
- `with_free_sized` has no `std.mem` wrapper. Refutation attempt:
  nothing in-repo calls it through this module (only the unsized
  `free_mem` is wrapped and used); adding an unused wrapper would be
  speculation, not a fix.

Verdict: COMPLETE
