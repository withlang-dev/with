# Primary verification — `tools/drop_audit.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 467 lines (single complete read)

## Scope examined

Drop-exactly-once audit matrix: `resource_prelude` (`:52`, counted `R`
with allocator-backed payload + drop-sum slot), shape helpers
(`:91`–`:126`: bare/field/boxfield/enum/boxbare/rcbare/tuple/option),
scenario builders (`:130`–`:332`: scope-exit, branch taken/untaken,
loop3, move-out, reassign, move-then-reassign, same-place
reassign-normalize, consume-call, conditional-consume `:198`, field-take
`:215`, move-into-borrow `:239`, early/normal return, discard,
match-consume, partial-move, branch-move-state-identity `:285`,
receiver mut/move/replace, vec-elem, POD-container cells `:330`),
`build_cells` (`:334`, 8 shapes × 12 scenarios + 19 curated cells),
runner (`run_cell` `:408`: COMPILE-FAIL / DOUBLE-FREE / LEAK /
RUN-FAIL / VALUE-FAIL classification; `main` `:433`: candidate +
optional baseline with REGRESSION diff). No callers in build files
beyond the documented `with build :drop-audit` entry point.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/tools_drop_audit/check.txt`: `with check
  tools/drop_audit.w` → ok (seed; all logic inside fns, no
  implicit-main rejection).
- `docs/audit/probes/tools_drop_audit/noargs.txt`: `with run
  tools/drop_audit.w` (no args) → usage line, exit 2. PASS.
- `docs/audit/probes/tools_drop_audit/cell_scope_exit_bare.*`: hand-built
  scope_exit/bare cell (prelude + decls + main from `cell`/`sc_scope_exit`
  expansion) under `with run --debug-alloc` → prints `1`,
  `leak count=0`, rc=0 — the PASS path of `run_cell` confirmed against
  the independent allocator oracle. PASS.
- `docs/audit/probes/tools_drop_audit/full_run.txt`: full matrix with
  candidate = installed `with`, no baseline → `drop-audit: 115 cells,
  0 non-PASS`, rc=0. Every cell PASS (all 8 shapes × 12 scenarios plus
  consume/match/partial-move/receiver/vec/POD cells). PASS.

## Findings

None. In-report notes (not filed):
- Full-matrix run used the installed seed as candidate (the
  `out/release/bin/with` candidate from `with build :drop-audit` does
  not exist in this checkout); candidate-vs-baseline REGRESSION
  classification therefore unexercised — the EXPECTED-column verdicts
  all hold, which is the without-baseline contract (`:9`).
- T13: tool writes cell sources to fixed `/tmp/drop-audit-cells`, reads
  results back; no repo files touched.

Verdict: COMPLETE
