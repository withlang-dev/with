# Audit: src/compiler/CodegenUnitsPolicy.w @ 450733e5

## Verdict: COMPLETE (no findings)

Module: `src/compiler/CodegenUnitsPolicy.w` (46 lines) — pure codegen-unit
decision policy (#681), no Mir/LLVM deps so internals tests can import it
directly (`test/internals/codegen_units_count_test.w`). Three public fns:
`codegen_units_count_for`, `codegen_units_bytes_per_stmt`,
`codegen_units_emit_width_for`. Sysinfo/env wrappers live in
`compiler.CodegenUnits` (`CodegenUnits.w:51-69`).
Commit verified: `450733e5` (`git rev-parse --short HEAD` = 450733e5).

## Targets traced

- **T13 ownership/drop**: NOT APPLICABLE — module owns nothing. All three
  fns take/return only `i32`/`i64` scalars; no `Vec`/`str`/extern handles,
  no `Drop`/destructor/free, no `unsafe`, no allocation. Nothing to
  leak, double-free, or drop early. Callers (`CodegenUnits.w:56,69`,
  via `Backend.w:30,113,171` + `Compilation.w:1162`) pass only counts/costs.
- **T15 migration fidelity**: NOT APPLICABLE — no migrator/receiver-rewrite
  logic in module. Split itself is faithful: policy extracted verbatim from
  the build path so the internals test can import it without LLVM deps
  (header comment lines 1-3); `CodegenUnits.w:22` re-imports it and both
  wrappers (`codegen_units_default_count`, `codegen_units_emit_width`)
  delegate to the policy fns with the same size gate (2000) and 8 GiB
  fallback. No C→With or receiver-migration rewrite fidelity to judge.
- **T22 spec conformance**: CONFORMING — decisions match the documented
  #681 contract in `docs/build_time_log.md:30` (count = size gate then
  cores clamped at 16, memory never caps count; emit window
  W = (mem − 5 GiB) / (plan_cost × 36 KB / K)) and every pinned value in
  `test/internals/codegen_units_count_test.w` (count gate/clamp, window
  6/3/1/16, compiler-scale canary W=4 @ 8 GiB / W=16 @ 16 GiB). No
  language-spec surface; internal tuning policy only.

## Probes (seed compiler out/bootstrap/bin/with-stage1, verified present via ls)

- P1 `with-stage1 run test/internals/codegen_units_count_test.w`: EXECUTED —
  output `ok`, exit 0. Covers all 21 pinned asserts (count gate/clamp lines
  13-21, window matrix lines 29-49 including 8 GiB→6/3, 6 GiB→1,
  ≤5 GiB→1, big-host→16, zero-cost→16, canary 289004→4/16).
- P2 edge/negative controls inside that run: EXECUTED as part of P1 —
  degenerate inputs (`mir_body_count` 0/1999→1, `cpu_cores` 0→1,
  `unit_count` 1→1, `mem_total` ≤ 5 GiB→1, `total_mir_cost` 0→unthrottled)
  all assert exact values and pass, so the suite is not a vacuous pass.

## Negative controls

- The suite asserts boundary failures would be visible: e.g. a wrong
  `as`-precedence parse of line 35 (`(mem−5)×1GiB` instead of `mem−5GiB`)
  would yield W=16 instead of 6 on the 8 GiB case and fail the run; it
  passes, so silent-pass is excluded for the load-bearing formula.
- Zero/degenerate inputs return clamped safe values (1 or unthrottled),
  never 0/negative widths that could break the join-oldest window in
  `CodegenUnits.w:198-247` (which additionally clamps `w` to ≥1).

## Findings

None. No file:line defect to cite. Suspect candidates raised and refuted:

1. (refuted) `CodegenUnitsPolicy.w:35` — suspected `as`-precedence bug
   (`mem_total - 5 as i64 * 1024 * 1024 * 1024` parsing as
   `(mem_total−5)×2^30`). Refutation: P1 passes with W=6 for
   (16, c8, 8 GiB) and W=3/W=1/W=16 elsewhere, which only the intended
   `mem_total − (5×2^30)` parse produces; the wrong parse overflows toward
   W=16 and would fail. Severity: none. Target: T22. Probe: P1 EXECUTED.
2. (refuted) `CodegenUnitsPolicy.w:38-40` — suspected negative
   `total_mir_cost` passthrough (`per_unit ≤ 0 → return unit_count`
   = unthrottled). Refutation: vs in-repo caller, `total_cost` in
   `CodegenUnits.w:113-144` is a sum of per-body costs each ≥1 (0 bodies
   → 0 → unthrottled, pinned by test line 43 as intended); no caller can
   pass a negative cost. Severity: none. Target: T22. Probe: P1 EXECUTED.
3. (refuted) `CodegenUnitsPolicy.w:38` — suspected i64 overflow
   (`total_mir_cost × 36000`). Refutation: calibrated cost 289004 →
   ~10.4 GiB est; overflow needs ~256M stmts, unreachable for real
   programs; no caller passes adversarial values. Severity: none.
   Target: T22. Probe: held (no adversarial harness; arithmetic review).
4. (refuted) `CodegenUnitsPolicy.w:12` — suspected negative
   `mir_body_count` mishandling. Refutation: `< 2000 → 1` covers all
   negatives; caller passes `body_count()` (non-negative). Severity: none.
   Target: T22. Probe: P1 EXECUTED (0/1999 cases).

## Notes (read-only compliance)

- No compiler sources modified; only this report written to
  `docs/audit/modules/src__compiler__CodegenUnitsPolicy.w.md`.
- Full-module read done (46 lines); line numbers above refer to
  `src/compiler/CodegenUnitsPolicy.w` at 450733e5.
- No upstream issues filed.
