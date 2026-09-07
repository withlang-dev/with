# Primary verification — `lib/std/box.w`

Status: **Complete**
Primary verifier: workflow child (full source read + probe execution)
Source revision: `450733e5`
Source SHA-256: `174d5e6a105d6625b2b2418838d9506d7d16ca0b44f9b9c7d08697c0faea181d`
Source examined: all 43 lines (single complete read)

## Scope examined

Single-owner heap allocation: `Box[T]` type (`:10`), `Box.new` move-assign
construction (`:12-19`), `as_ref`/`as_ptr` accessors (`:22-26`),
`into_inner` consuming unbox (`:28-32`), `Deref` impl (`:34-36`), `Drop`
impl (`:38-43`), extern allocator declarations (`:5-7`).

Applicable overview targets examined: 13 (MIR/codegen agreement — the
move-assign store and Drop-glue emission), 15 (allocator/container
ownership — heap buffer lifecycle, double-drop, leaks), 22
(specification coverage — normative Box rules to executable tests).
(Task labels "T13 ownership/drop, T15 migration fidelity" do not match
the overview numbering; behavior traced per the overview definitions:
T13 = MIR/codegen agreement, T15 = allocator/container ownership,
T22 = spec coverage.)

## Behavioral matrix

Probes in `docs/audit/probes/box_surface/`, all `check` rc=0 and `run` rc=0
with seed `out/bootstrap/bin/with-stage1` at 450733e5:

- `box_drop_once.w`: `run` prints `box-drop-once-ok` — `Box.new` of a
  Drop-guard payload drops nothing at box time, drops exactly once at
  scope exit. Guards the f50684ec double-drop fix (T13/T15).
- `box_into_inner.w`: `run` prints `box-into-inner-ok` — `into_inner`
  transfers without dropping; the extracted value drops exactly once
  on explicit `drop` (T15).
- `box_access.w`: `run` prints `42` four times — `as_ref`, `as_ptr`
  (unsafe deref), explicit `deref()`, and auto-deref field access
  `w.val` all read the heap payload (T22; spec §3.7/§8).

In-repo coverage (files verified to exist, executed with seed stage1):

- `test/behavior/behav_box_drop.w`: `test` → 2 passed (drop-at-exit,
  into_inner transfer).
- `test/behavior/behav_ffi_box_roundtrip.w`: `test` → 3 passed
  (box/unbox round-trip, `drop_ctx` exactly-once, write-through).
- `test/behavior/behav_box_as_ref.w`, `behav_box_as_ptr.w`,
  `behav_box_deref_explicit.w`, `behav_box_as_ref_struct.w`
  (expect-stdout 42; §3.7/§8, #627) — present, covered by the
  equivalent `box_access.w` probe above.
- `test/compile_errors/err_box_unavailable_core_no_std.w`,
  `err_ephemeral_box_escape.w` — present (negative spec edges).

Negative controls (under `/tmp/boxneg/`, removed after run):

- Explicit `drop(box)` inside a scope then scope exit: prints
  `explicit-drop-once-ok`, trace `== "Q"` — no second drop from Box
  glue (T15 EXECUTED).
- `Box.new(g)` with Drop type `G` followed by `print(g.id)`: `check`
  accepts (ok), `run` prints empty line then `dropped` once —
  reset-on-move blanks the source, exactly one drop runs. Runtime is
  sound; only the use-after-move diagnostic is missing.
- Refutation of a Box defect: the same use-after-move IS rejected for
  free functions (`takeit(move v: G)` and plain `sink(v: G)` and
  generic `gsink[T](v: T)` all error `use of moved value`), but is
  ALSO accepted for a user-defined static method `W.wrap(g)`.
  The missing call-site consume diagnostic is therefore a general
  associated-function call-path gap in SemaCheck, not Box logic —
  runtime ownership (blank + single drop) holds. Not filed (compiler
  surface, out of this module; no issue-filing per instructions).

## Verdict: COMPLETE — no finding in this module

- `Box.new` (`:12-19`) stores via move-assign `unsafe { *ptr = value }`,
  consuming `value` without running its drop; the heap slot owns the
  payload. Probed single-drop confirms the f50684ec fix holds at this
  commit (T13/T15).
- `Drop` (`:38-43`) moves the payload out of the heap place, runs
  `drop(value)`, then frees — exactly-once by probe (T15).
- `into_inner` (`:28-32`) moves out and frees without dropping —
  transfer sound by probe (T15).
- `as_ref`/`as_ptr`/`deref` (`:22-26`, `:34-36`) read the box place as
  the payload pointer, matching the transparent-box lowering
  (MirLower defers to the box place, not the `Deref.deref` call, per
  f50684ec); all four access shapes probed 42 (T13/T22).
- In-repo caller `lib/std/ffi.w:38` (`box_ctx` = `Box.new(move value)`
  erased to `*mut c_void`, recovery via `unbox_ctx`/`drop_ctx`) matches
  this module's contract: box time never drops, recovery drops exactly
  once; round-trip tests pass 3/3 (T15/T22).
- `Box.new[T]` intentionally accepts ephemeral-payload boxing without a
  compile-time reject (`ffi.w:35-36` notes the same gap for `box_ctx`);
  the recovery helpers are `unsafe` so caller liveness is the backstop.
  Documented posture, noted not filed.

## Notes (no finding — analyzed, not filed)

- Static-method call sites (`Type.method(v)` form) skip the
  use-after-move diagnostic that free-function by-value calls enforce
  (EXECUTED, refuted as non-Box: `W.wrap` control shows identical
  acceptance). Candidate compiler-side note only.
- A deliberately leaked `Box` (never dropped/unboxed) has no
  backstop — standard explicit-ownership posture, documented by
  `box_ctx` ("do not let the pointer leak"); no probe contradicts it.

Verdict: COMPLETE
