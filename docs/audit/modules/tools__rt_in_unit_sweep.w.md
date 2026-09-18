# Primary verification — `tools/rt_in_unit_sweep.w`

Status: **INCOMPLETE** (tool broken at this revision — see Findings)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 50 lines (single complete read)
Last touched: `7d72cf4f` (creation, D30 #761)

## Scope examined

D30 R2c lane sweep: run every `test/behavior/*.w` under
`WITH_RT_IN_UNIT=1` via `with test --quiet`, write the fail list.
`arg_or` (`:12`), `in_glob` (`:19`: top-level `.w` files only, not
`lib/` companions or `foo/` fixtures), `sweep` (`:25`: per-file
`run(&cmd)`, counts, writes `out_path`), top-level driver (`:46`–`:50`:
implicit-main; out path defaults to `lane-fails.txt`, lane defaults to
`1`). 974 files under `test/behavior/` at this revision.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_rt_in_unit_sweep/check.txt` /
  `stage2_check.txt`: `with check` (seed and stage2) rejects the
  implicit-main top-level `exit_code(...)` (`:50`) — same expected
  non-defect as the other run-scripts in this batch.
- EXECUTED `docs/audit/probes/tools_rt_in_unit_sweep/bounded_run.txt`
  (seed) and `stage2_bounded_run.txt` (stage2, built from this tree):
  `with run tools/rt_in_unit_sweep.w <out> 1` fails identically under
  BOTH compilers before running anything:
  `error: undefined variable ... ROOT` at `:22`–`:23` (three errors),
  rc=1. The top-level `let ROOT = "test/behavior/"` (`:17`) is not
  visible inside `fn in_glob`. Distinguishing pattern: this is the only
  tool in the batch that reads a top-level `let` from inside an `fn`
  (rt_decl_audit's top-level lets are read only from top-level
  statements and run fine). Whether top-level lets are main-locals by
  rule or this is a compiler limitation, the committed tool does not
  run — execution-verified, not reasoned.
- HELD: full 974-file lane sweep — impossible while the tool does not
  compile; would also be a multi-minute run (single `with test --quiet`
  measured at ~0s for one file, but 974 sequential compile+run
  invocations). Re-attempt after the Finding is fixed.

## Findings

1. (execution-verified, NOT filed as an issue per task scope)
   `tools/rt_in_unit_sweep.w:22-23` — `ROOT` undefined inside
   `fn in_glob` under both the seed (`with` v0.15.1.6) and
   `out/stage/bin/with-stage2`. Exact output in
   `docs/audit/probes/tools_rt_in_unit_sweep/bounded_run.txt` and
   `stage2_bounded_run.txt`. Probable fix direction (not applied —
   read-only audit): pass the root as a parameter or inline the
   literal, matching the batch's otherwise param-passing style.
   Refutation attempted: ran under stage2 to rule out a stale seed;
   identical failure — the breakage is current.

Verdict: INCOMPLETE (blocked on Finding 1)
