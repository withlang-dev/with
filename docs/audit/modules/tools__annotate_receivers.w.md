# Primary verification — `tools/annotate_receivers.w`

Status: **INCOMPLETE** (tool broken at this revision — see Findings)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 329 lines (single complete read)
Last touched: `7d8d085e` (WIP #747 Phase C step 1: flip read-only fs/env/exec/io/str extern ABI to &str)

## Scope examined

D7 enforce-first Pass 1: stamp every mode-less by-value
`self: Type` receiver with the compiler-proven mode
(`fn` → `self: &Self`, `mut fn` → prepend `mut `, `move fn` →
prepend `move `). `line_for_offset`/`column_for_offset` (`:33`–`:44`),
`exact_mode` (`:46`–`:59`: exact fact match, else nearest preceding
fact on the same line), `compiler_receiver_modes` (`:61`–`:88`:
`select:kind=declaration` facts, skips already-moded receivers,
counts `ReceiverProven`-less declarations as unproven),
`annotate_file` (`:90`–`:209`: token scan to the receiver type span,
aborts the whole file unless proven count == token count),
`file_has_mode_less_receiver` (`:211`–`:255`: cheap pre-scan gate),
`path_excluded`/`annotate_integrated_file`/`annotate_integrated_path`
(`:257`–`:297`): file left unchanged on any unproven declaration,
directory recursion via `with_fs_list_files`), `main` (`:299`–`:329`:
`--exclude` support, totals, nonzero exit on unresolved paths).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_annotate_receivers/check.txt`
  (seed `out/bootstrap/bin/with-stage1`) and `check_stage2.txt`
  (`out/stage/bin/with-stage2`): `check` fails, exit 1. Three
  error classes: (a) `facts.modes.get()` (`&str`) returned as
  `str` (`:51`) and branched on in `if` (`:59`, "if would need to
  copy a `str`, which is not Copy"); (b) `text`/`listing`/`path`
  moved by by-value `str` parameters and reused
  (`:142`–`:273`, `:282`); (c) `argv.get()` (`&str`) pushed to
  `Vec[str]` / passed to `str` parameters (`:313`, `:315`, `:323`).
- EXECUTED `run_noargs.txt` (stage2 `run`, no args) and
  `run_installed_noargs.txt` (`with` v0.15.1.6 `run`, no args):
  identical compile failure before any tool logic executes — the
  usage path (`:301`) is unreachable. Breakage is current under
  both compilers, not a stale-seed artifact.
- HELD: annotation of a fixture copy, the abort-on-unproven path,
  and `--exclude` handling — impossible while the tool does not
  compile. Re-attempt after the Finding is fixed. The tool was
  never run against real sources (writes in place by design).

## Findings

1. (execution-verified, NOT filed as an issue per task scope)
   `tools/annotate_receivers.w` does not compile at `450733e5`
   under the seed, stage2, or installed compiler. Exact output in
   `docs/audit/probes/tools_annotate_receivers/check.txt`
   (`check_stage2.txt` identical in kind). Same drift signature
   as the sibling `migrate_d22_copy_views.w` finding: helpers
   take `str` by value and predate the `7d8d085e` `&str` ABI
   flip, and D22 map-view `Vec[str].get()` now yields `&str`,
   which no longer coerces to the `str` return/parameters at
   `:51`, `:59`, `:313`, `:315`, `:323`. Probable fix direction
   (not applied — read-only audit): `&str` parameters, clone at
   the `modes`/`paths`/`excludes` push sinks, and bind
   `.get()` results before returning/branching on them.
   Refutation attempted: ran under stage2 and the installed
   compiler to rule out a stale seed; identical failure — the
   breakage is current.

Verdict: INCOMPLETE (blocked on Finding 1)
