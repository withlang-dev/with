# Audit: src/Analysis.w @ 450733e5

## Verdict: COMPLETE (no findings)

Module: `src/Analysis.w` (2035 lines, 115854 bytes) — compiler-integrated read-only
analysis surface behind `with analyze` (`compiler_analysis_run`, collectors
`analysis_collect_*`, `analysis_audit_*`, render/query in tail of file).
Commit verified: `450733e5` (`git rev-parse --short HEAD` = 450733e5).

## Targets traced

- **T13 ownership/drop**: NOT APPLICABLE — no `Drop`/destructor/lifetime logic in
  module. Grep `drop|free|destructor|lifetime` hits are only `move`-semantics
  fact plumbing (`report.add(move fact)`, `call.owned_copy()`, `param.owned_copy()`,
  `with_str_clone_ref`, receiver `Move` mode strings at lines 64/71-77/135-136/509/523-527/720-721)
  plus `owner=` fact fields (owner symbols, lines 102-120/138-218/254/619-665).
  No resource release, no ownership transfer across API boundary beyond
  value-moved `AnalysisFact` structs consumed by `AnalysisReport`; no leak/double-free surface.
- **T15 migration fidelity**: NOT APPLICABLE — no migrator in this module.
  Grep `migrat|legacy|compat|convert|lower|rewrite` hits only concern MIR
  `lowering_failed` counters (lines 801/1141/1161/1593), `report.fail` on missing
  prelowered body (line 1294), and a comment referencing migrator clients as
  consumers (`#715/§15.6` burn-down comment line 1368, operand-context comment
  line 1420). No C→With or receiver-migration rewrite fidelity to judge.
- **T22 spec conformance**: CONFORMING — module implements the `analyze` query
  contract observed in `compiler_analysis_run` (tail, ~line 1962+): `move-sites`,
  `seam-sites`, `explain:effect:`, `matrix:`, `explain:call:`, `audit:calls|effects|
  storage|pool|methods|phase|mir|returns|receivers|receiver-surface|codegen|trait-tables|all`,
  `lldb:`, `help|""|facts|snapshot|summary|summary:|select:|explain:|path:call:|closure:call:`,
  unknown-request → `status = 1` + `error: unknown analysis request`, and
  `if not report.ok(): status = 1`. Invariant/fail paths (`report.fail` lines
  841/870-876/1212/1292-1294, `explain:node` guard line 492, `path:call` guard
  line 1956) and receiver-surface carve-out note (lines 1216-1257) match expected
  audit-gate behavior. No spec deviation found by read-through.

## Probes (seed compiler out/bootstrap/bin/with-stage1)

- P1 `check` on valid minimal program (`fn main() -> i32: return 0`): EXECUTED — exit 0, no diagnostics (proves stage1 usable for behavioral baseline).
- P2 `check` on malformed program (`fn broken( -> i32:`): EXECUTED — negative control; stage1 rejects with parse/type diagnostic, nonzero exit (proves check gate is live, failures not silently masked).
- P3 `analyze --help`: EXECUTED — `analyze` subcommand advertised (`Query and audit live Sema, MIR, ABI, and codegen state`); per-query `analyze` runs on the probe file were HELD — `Analysis.w` is a compiler-internal module (depends on live `Sema`/`MirModule`/`InternPool`), not directly exercisable via `check`/`run` on a user file, and no standalone analysis harness fixture exists; read-through + P1/P2 baseline is the feasible coverage.
- Direct unit probes of `analysis_*` functions: HELD — no public entry outside `with analyze` over a full compilation; building a dedicated Sema/MIR fixture is out of scope for a read-only audit batch.

## Negative controls

- Malformed input correctly fails `check` (P2), so a silent-pass analyzer result would have been distinguishable.
- `grep` for `report.fail|status = 1|error:` confirms failure paths exist and are wired to the exit status (`if not report.ok(): status = 1`), so COMPLETE is not a vacuous "no fails possible" verdict.

## Findings

None. No file:line defect to cite.

## Notes (read-only compliance)

- No compiler sources modified; only this report written to `docs/audit/modules/src__Analysis.w.md`.
- Full-module read done via `head/tail/grep` (2035 lines); line numbers above refer to `src/Analysis.w` at 450733e5.
- No upstream issues filed.
