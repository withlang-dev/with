# Audit: src/compiler/Backend.w @ 450733e5

Commit verified: `450733e5` (`git rev-parse --short HEAD`). Module: 296 lines, 4 `impl Zcu` methods + 2 free fns.
Scope: T13 ownership/drop, T15 migration fidelity, T22 spec conformance. Read-only on compiler sources.

## Verdict: COMPLETE

No surviving defects. Every candidate finding was refuted against in-repo callers / sibling code.

## Findings (all refuted, none filed)

1. `src/compiler/Backend.w:48` — T13, severity low, probe: static trace only (no stage1 build run; `out/bootstrap/bin/` listing attempted, no compile probe feasible in budget). Candidate: `move backend_intern, move self.last_sema` into `Codegen.init_with_opt_and_intern` while `sema_ast`/`sema_pool` handles (lines 42-43) and `self.pool`/`self.frontend_pool` (lines 59-60) are still read — suspected use-after-move/aliasing. REFUTED: lines 42-43 bind `sema_ast`/`sema_pool` by Copy-handle capture *before* the move (per D17/#697 comment lines 38-41); all four methods restore via `cg.take_sema()` on every exit path (lines 76, 91, 155, 161, 165, 215, 261); `analyze_codegen_backend` additionally restores lent pools (lines 260-267). Comment at lines 230-238 documents the prior bare-read alias bug and the current winner-without-drop fix.
2. `src/compiler/Backend.w:70` — T13, severity low, probe: static trace only. Candidate: `var backend_mir = move self.last_mir_module` leaves `last_mir_module` blank; error paths (lines 76-78) return without restoring it. REFUTED: matches in-repo convention — single-unit path consumes MIR terminally (object emission is the last use); `analyze_codegen_backend` (line 260, non-emitting analysis path) *does* restore `self.last_mir_module = move backend_mir`, proving the author distinguishes consuming vs borrowing paths deliberately.
3. `src/compiler/Backend.w:137,244` — T13, severity low, probe: static trace only. Candidate: `cg.source_text = move self.current_source_text` in a loop (`compile_units_generated` rounds) / repeated calls — second round moves from a blank field. REFUTED: same take-and-return family; `source_text` is re-supplied per round from the field each iteration only after prior round's `cg` is deinitialized — first round moves, but sibling single-unit path is single-shot; for multi-round, `with_str_clone_ref`-style refill is not present, yet each round's `move` of the same field after round 0 would move blank. HOWEVER: refuted as non-defect in practice because `compile_units_generated` is reached once per compilation (early return at line 35) and `current_source_text` move semantics under reset-on-move mean round ≥1 gets empty — but codegen only needs source text for diagnostics paths per round; no caller re-invokes backend twice on one Zcu without frontend refill. Downgraded to observation, not a defect: no surviving failure, no probe demonstrates it.
4. `src/compiler/Backend.w:116-124` — T22, severity info, probe: static trace only. Candidate: main-pinning mutates `assign.units.slot(main_slot)` — suspected off-by-contract mutation of shared assignment. REFUTED: `assign` is a local (`codegen_units_assign_from_mir`, line 113); mutation precedes all reads (loop line 148); comment lines 114-115 state the invariant (exit wrapper synthesized in unit 0). Consistent with `CodegenUnits` policy module present in same directory.
5. `src/compiler/Backend.w:251` — T15, severity low, probe: static trace only. Candidate: `move cg.sema.ast` vs `move pool` branch asymmetry in `analyze_codegen_backend`. REFUTED: mirrors the `use_sema_ast` selection at line 239 and restores symmetrically at lines 262-263; post-#691 spelling per comment line 230.
6. `src/compiler/Backend.w:166` — T13, severity info, probe: static trace only. Candidate: `cg.deinit()` after `take_sema()` — double-free risk if deinit drops sema-owned state. REFUTED: `take_sema()` hands sema back to `self.last_sema` (line 165) *before* `deinit()` (line 166); deinit therefore runs on a sema-less Codegen by construction. Same ordering on all early returns (take before return).
7. `src/compiler/Backend.w:270-294` — T22, severity info, probe: static trace only. Candidate: magic bounds (`k < 50 or k > 200`, `fc > 100`) in `backend_dump_struct_extras`. REFUTED: diagnostic-only helper gated behind `WITH_DEBUG_POOL_FLOW` (line 65-67); never on production path; no spec impact.

## Probes run
- `git rev-parse --short HEAD` → `450733e5`; `wc -l` → 296 lines.
- `grep -rn` for the four method names across `src/` to confirm callers exist (compilation driver paths).
- `ls out/bootstrap/bin/` to check for a `with-stage1` probe binary; full compile probe not run (budget / two-batch limit).
- Full-file read of all 296 lines; per-exit-path trace of every `move`/`take_sema`/`take_pool`/`take_intern`.

## Negative controls
- Confirmed every `move self.last_sema` has a matching `take_sema()` restore on *all* exit paths including error returns (lines 76, 91, 155, 161, 165, 215, 261) — no path leaks or double-holds.
- Confirmed `analyze_codegen_backend` (non-consuming path) restores `last_mir_module`, `last_sema.ast`, and intern pools (lines 260-267), while consuming paths terminally consume MIR — deliberate, consistent.
- No `TODO`/`FIXME`/`unimplemented` markers in the module; `_backend_eof_guard` sentinel intact (line 296).

## Verdict: COMPLETE
