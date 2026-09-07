# Primary verification — `tools/sweep_gate_corpus.w`

Status: **INCOMPLETE** (tool broken at this revision — see Findings)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 57 lines (single complete read)
Last touched: `7d8d085e` (WIP #747 Phase C step 1: read-only fs/env/
exec/io/str extern ABI flip to `&str` — the flip this file predates)

## Scope examined

D29 #750 scaffolding sweep: for each file in a list, `check` with a
gate-aware compiler; on "requires an explicit import" diagnostics, fork
the file into a quarantine corpus dir, apply
`tools/insert_std_uses.w --apply`, recheck to fixpoint (max 4 passes).
`sh` (`:12`: `/bin/sh -c` via `run`), `gate_count` (`:19`), top-level
driver (`:25`–`:57`: implicit-main; usage `sweep_gate_corpus <stage1>
<list> <diag_tmp> [d_corpus_dir]`, prints `fixed`/`STUCK` lines +
`affected/fixed/stuck` summary). Dependency `tools/insert_std_uses.w`
exists in-tree.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_sweep_gate_corpus/check.txt` /
  `stage2_check.txt`: `with check` (seed and stage2) rejects the
  implicit-main top-level statements (`:26`, `:37`–`:49`) — same
  expected non-defect as the other run-scripts.
- EXECUTED `docs/audit/probes/tools_sweep_gate_corpus/noargs.txt` (seed)
  and `stage2_run_noargs.txt` (stage2): `with run
  tools/sweep_gate_corpus.w` (no args) never reaches the usage guard —
  compilation fails first with 6 errors under BOTH compilers (rc=1):
  `manual extern function call requires unsafe context` for bare
  `with_fs_read_file` calls (`:21` ×2, `:37` ×2); `if would need to
  copy a str, which is not Copy` (`:32`, `argv.get(4)` in if/else);
  `wrong argument type ... expects str`, actual `&str` at
  `gate_count(diag_tmp)` (`:40`, `:49`). Consistent with the file
  predating the #747 `&str` extern flip (its last touch IS that flip's
  WIP commit, which migrated other files but left this one's call sites
  and `gate_count(diag_path: str)` signature behind).
- HELD: fixture-list sweep (clean list → `affected=0`; gated list →
  fixpoint) — impossible while the tool does not compile. Re-attempt
  after the Finding is fixed.

## Findings

1. (execution-verified, NOT filed as an issue per task scope)
   `tools/sweep_gate_corpus.w` does not compile at `450733e5` under the
   seed or the tree-built stage2 — 6 errors, exact output in
   `docs/audit/probes/tools_sweep_gate_corpus/noargs.txt` and
   `stage2_run_noargs.txt`. Probable fix direction (not applied —
   read-only audit): wrap the extern calls in `unsafe:`, thread `&str`
   through `gate_count`, and clone the `argv.get(4)` arm (the
   `owned(...)`/`++ ""` idiom used by drop_audit/move_audit).
   Refutation attempted: ran under stage2 to rule out a stale seed;
   identical failure — the breakage is current.

Verdict: INCOMPLETE (blocked on Finding 1)
