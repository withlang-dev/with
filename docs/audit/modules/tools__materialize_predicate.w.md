# Primary verification — `tools/materialize_predicate.w`

Status: **INCOMPLETE** (tool broken at this revision — see Findings)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 44 lines (single complete read)
Last touched: `7d8d085e` (WIP #747 Phase C step 1: flip read-only fs/env/exec/io/str extern ABI to &str)

## Scope examined

Path-preserving adapter for reducers: write `<candidate>` to
`<materialized-path>`, run `<command>` with `{file}` substituted,
remove the materialized file, propagate the child status; child
stdio inherited for `with reduce --contains`. Arg separation at
`--` (`:20`–`:27`), materialize (`:29`–`:33`), child argv build
with `{file}` substitution (`:35`–`:38`), `run(&child)` +
cleanup + `exit_code(status)` (`:39`–`:44`). Implicit-main style,
no `fn main`.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_materialize_predicate/check.txt`
  (seed) and `check_stage2.txt` (stage2): `with check` rejects
  the implicit-main top-level statements from `:16` on
  ("expected declaration") — same expected non-defect as the
  other run-scripts in this batch (isolated in
  `docs/audit/probes/tools_implicit_main/`: a one-line `print("hi")`
  file fails `check` with exit 1 yet `run`s with exit 0 printing
  `hi` under stage2).
- EXECUTED `run_noargs.txt` (stage2 `run`, no args) and
  `run_installed_noargs.txt` (`with` v0.15.1.6 `run`, no args):
  parsing succeeds under `run`, then semantic check fails
  identically under BOTH compilers with a single error before
  any tool logic executes:
  `error: if would need to copy a 'str', which is not Copy` at
  `:38` (`child.push(if arg == "{file}": materialized else: arg)`
  — the `if` yields `materialized: str` on one arm and
  `arg: &str` on the other). The usage path (`:16`) is
  unreachable.
- HELD: end-to-end adapter run (materialize → `check {file}` →
  remove, plus the `--` validation arms) — impossible while the
  tool does not compile. Re-attempt after the Finding is fixed.

## Findings

1. (execution-verified, NOT filed as an issue per task scope)
   `tools/materialize_predicate.w:38` does not compile at
   `450733e5` under the seed or stage2. Exact output in
   `docs/audit/probes/tools_materialize_predicate/run_noargs.txt`.
   `str` is not Copy, so the `if`-as-expression mixing the owned
   `materialized` with the borrowed `arg` is rejected. Probable
   fix direction (not applied — read-only audit): bind first
   (`let sub = if arg == "{file}": ...` with an explicit clone
   of the borrowed arm, or push in two `if`/`else` arms) —
   one-line, single-expression tool otherwise. Refutation
   attempted: ran under stage2 to rule out a stale seed;
   identical single error — the breakage is current.

Verdict: INCOMPLETE (blocked on Finding 1)
