# Primary verification — `tools/migrate_d22_copy_views.w`

Status: **INCOMPLETE** (tool broken at this revision — see Findings)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 205 lines (single complete read)
Last touched: `7d8d085e` (WIP #747 Phase C step 1: flip read-only fs/env/exec/io/str extern ABI to &str)

## Scope examined

D22 Copy-view migration driven by candidate-compiler §22.3
diagnostics: `find_from`/`line_end`/`line_text` (`:17`–`:32`),
`diagnostic_source_path` (`:34`, `<embedded-std>/` → `lib/`),
`parse_i32_text` (`:40`), `source_line_start`/`source_line_end`
(`:48`–`:62`), `Edits` accumulator + `edit_key`/`has_edit`
(`:64`–`:77`), `parse_diagnostics` (`:79`–`:136`: scrapes
"cannot mutate … while … is a live view" blocks for path, `= label @`
binding line, and `` `let <name>: <ty> = ...` `` target type),
`locate_binding_insert` (`:138`–`:154`: Lexer-accurate `let`/`var`
`<name> =` site search, refuses annotated bindings),
`apply_one` (`:156`–`:169`, dry-run default), `main` (`:171`–`:205`:
runs `<candidate> check <source>`, no-ops when the candidate already
accepts it, else applies/scrapes proven edits).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_migrate_d22_copy_views/check.txt`
  (seed `out/bootstrap/bin/with-stage1`) and `check_stage2.txt`
  (`out/stage/bin/with-stage2`): `check` fails, exit 1. Two error
  classes: (a) `Vec[str].get()` now yields `&str` passed to
  `str` parameters (`:76` in `has_edit`, `:202` in `main`);
  (b) `str` by-value parameters consume on first use, so every
  subsequent use of `text`/`block`/`error_prefix`/`label_prefix`
  is "use of moved value" (`:86`–`:164`, ~40 diagnostics).
- EXECUTED `run_noargs.txt` (stage2 `run`, no args) and
  `run_installed_noargs.txt` (`with` v0.15.1.6 `run`, no args):
  identical compile failure before any tool logic executes — the
  usage path (`:173`) is unreachable. Breakage is current under
  both compilers, not a stale-seed artifact.
- HELD: dry-run scrape against a crafted §22.3 diagnostic, and the
  `--apply` path — impossible while the tool does not compile.
  Re-attempt after the Finding is fixed. No fixture was run with
  `--apply` (writes in place by design).

## Findings

1. (execution-verified, NOT filed as an issue per task scope)
   `tools/migrate_d22_copy_views.w` does not compile at `450733e5`
   under the seed, stage2, or installed compiler. Exact output in
   `docs/audit/probes/tools_migrate_d22_copy_views/check.txt`
   (`check_stage2.txt` identical in kind). Read-only helpers take
   `str` by value (`find_from(text: str, ...)`,
   `diagnostic_source_path(path: str)`,
   `locate_binding_insert(text: str, ...)`,
   `edit_key(path: str, ...)`, `apply_one(path: str, ...)`)
   and were last written before `7d8d085e` flipped the read-only
   ABI to `&str`; `str` is not Copy, so callers that reuse a value
   after passing it fail, and `Vec[str].get()` results (`&str`)
   no longer coerce to the `str` parameters. Probable fix
   direction (not applied — read-only audit): take `&str`
   parameters and clone only at the `Vec[str].push` sinks,
   matching the already-green `rename_rt_libc_externs.w` style.
   Refutation attempted: ran under stage2 and the installed
   compiler to rule out a stale seed; identical failure — the
   breakage is current.

Verdict: INCOMPLETE (blocked on Finding 1)
