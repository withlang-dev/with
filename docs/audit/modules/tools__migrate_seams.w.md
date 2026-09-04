# Primary verification — `tools/migrate_seams.w`

Status: **COMPLETE** (stale tool; findings recorded, none filed per task scope)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 111 lines (single complete read)

No `with-stage1` binary exists at this commit; seed `with` and
`out/stage/bin/with-stage2` used instead. Both reject this tool
(identical errors); see Findings.

## Scope examined

Ownership-seam class fixer (`:1`): shells out to
`<compiler> analyze <root.w> seam-sites` (`:78`), filters rows to the
requested `<class>` with `context=read` (`:98`), REPORTS other classes
(`:14`). The `--apply` flag is parsed (`:74`) but implements nothing:
`main` ends at `:111` with only the summary + dry-run hint, and
`with_fs_write_file` is imported (`:22`) but never called. Report-only
by construction ("rerun with --apply once a class's edit shape is pinned
by a fixture", `:111`).

## Behavioral matrix (EXECUTED vs HELD)

- `with check tools/migrate_seams.w` → 5 errors, rc=1.
  `docs/audit/probes/tools_migrate_seams/check_seed.log`. EXECUTED (fails).
- `./out/stage/bin/with-stage2 check tools/migrate_seams.w` → same
  errors, rc=1. `check_stage2.log`. EXECUTED (fails).
- `with run tools/migrate_seams.w` (no args) → fails at compile time
  (`error: run failed`, same errors); usage line never reached.
  `run_noargs.log`. EXECUTED (fails).
- `./out/stage/bin/with-stage2 analyze <fixture> seam-sites` → rc=0,
  header `path\toffset\tfn\tclass\ttier\tcontext\tplace\ttype` plus
  rows (e.g. `copy-view-drop ... read`). `seamsites_probe.log`. PASS —
  the tool's upstream compiler contract is live; only the tool source
  itself is stale.
- HELD (cannot execute — tool does not compile): dry-run report loop,
  `--apply` (no-op even if it compiled), all class filtering.

## Findings

Execution-verified, NOT filed (developer one-shot tool; task scope
forbids issue filing for primary files):
- Stale against D22 map-view strictness. `Vec.get`/`split` results are
  `&str` views now, but helpers take `str`: `argv_append("", compiler)`
  (`:78`), `argv_append(cmd, root)` (`:80`), `split_tabs(line)` (`:94`),
  `parse_int(cols.get(1))` (`:106`) — all `&str`-vs-`str` mismatches —
  plus `with_fs_read_file(out_path)` outside `unsafe` (`:86`). Exact
  output in `check_seed.log` / `run_noargs.log`.
- `--apply` silently does nothing (no write path exists, `:109`-`:111`).
  A user passing `--apply` today gets the summary and no edits, with no
  warning that apply is unimplemented. Refuted as a *regression*: the
  header documents report-only intent; the gap is missing `--apply`
  plumbing, not a broken promise — but the flag should either work or be
  rejected loudly.

Verdict: COMPLETE (audit done; tool itself is STALE — does not compile
at 450733e5 and `--apply` is unimplemented)
