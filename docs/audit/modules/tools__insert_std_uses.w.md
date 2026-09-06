# Primary verification — `tools/insert_std_uses.w`

Status: **INCOMPLETE** (tool broken at this revision — see Findings)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 129 lines (single complete read)
Last touched: `7d8d085e` (WIP #747 Phase C step 1: flip read-only fs/env/exec/io/str extern ABI to &str)

## Scope examined

D29 #750 scaffolding: insert `use` lines chosen by live gate
diagnostics ("… add: use M.N"), dry-run default. `source_path`
(`:17`, `<embedded-std>/` → `lib/`), `gate_use_line` (`:21`),
`diag_path` (`:26`, strips trailing `:line:col`), 
`header_insert_offset` (`:41`, after the last leading `use`/`module`
line), `vec_contains` (`:58`), top-level driver (`:63`–`:129`,
implicit-main style: parse saved diags into distinct (file, use)
pairs, print in dry-run, idempotent header insert under `--apply`).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_insert_std_uses/check.txt` (seed)
  and `check_stage2.txt` (stage2): `with check` rejects the
  implicit-main top-level statements from `:66` on
  ("expected declaration") — same expected non-defect as the
  other run-scripts in this batch (isolated in
  `docs/audit/probes/tools_implicit_main/`: a one-line `print("hi")`
  file fails `check` with exit 1 yet `run`s with exit 0 printing
  `hi` under stage2).
- EXECUTED `run_noargs.txt` (stage2 `run`, no args) and
  `run_installed_noargs.txt` (`with` v0.15.1.6 `run`, no args):
  parsing succeeds under `run`, then semantic check fails
  identically under BOTH compilers before any tool logic
  executes: manual `extern fn` calls outside `unsafe` (`:74`,
  `:112`, `:125`) plus `&str`→`str` mismatches at `:101`,
  `:103` (`pair_paths.get()` / `path` into `vec_contains` /
  `Vec[str].push`). The usage path (`:70`–`:72`) is unreachable.
- HELD: dry-run scrape of a crafted gate-diagnostic file and the
  `--apply` insert path — impossible while the tool does not
  compile. Re-attempt after the Finding is fixed.

## Findings

1. (execution-verified, NOT filed as an issue per task scope)
   `tools/insert_std_uses.w` does not compile under `with run`
   at `450733e5` (seed and stage2 agree). Exact output in
   `docs/audit/probes/tools_insert_std_uses/run_noargs.txt`. The
   top-level driver calls `with_fs_read_file`/`with_fs_write_file`
   without `unsafe` (`:74`, `:112`, `:125`) and passes
   `&str` values to `str` slots (`:101`, `:103`) — predates the
   `7d8d085e` `&str` ABI flip. (The `check`-only "expected
   declaration" errors are the batch-wide implicit-main
   asymmetry, not a tool defect — see matrix.) Probable fix
   direction (not applied — read-only audit): wrap the three
   extern calls in `unsafe` (as the `fn main` tools in this
   batch already do) and take `&str` in `vec_contains`.
   Refutation attempted: ran under stage2 to rule out a stale
   seed; identical failure — the breakage is current.

Verdict: INCOMPLETE (blocked on Finding 1)
