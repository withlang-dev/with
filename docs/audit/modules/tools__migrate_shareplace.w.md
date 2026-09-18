# Primary verification — `tools/migrate_shareplace.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 288 lines (single complete read)

No `with-stage1` binary exists at this commit; seed `with` and
`out/stage/bin/with-stage2` used instead. Both recorded below.

## Scope examined

D5-supersession migrator (`:1`): selects read-only owned free parameters
(`detail` starts with `"owned"`, no WRITE/CONSUME/ESCAPE_VALUE effects,
`:82`) from live `facts`, excluding receivers (`:87`), externs without
declaration facts (`:96`), and already-`&`/` *` params (loud refusal,
`:230`). Lexer-walks to the type token and inserts one `&` (`:237`,
`:279`); per-file ascending sort with cross-specialization dedup
(`:239`, `:265`). Dry run default, `--apply` writes (`:274`); any
preflight failure aborts with nothing written (`:247`). Self-documents
the #730 caveat: `eff=[read]` can lie for move-out-through-param bodies,
so the apply diff must be swept (`:79`).

## Behavioral matrix (EXECUTED vs HELD)

- `with check tools/migrate_shareplace.w` → ok (seed).
  `docs/audit/probes/tools_migrate_shareplace/check_seed.log`. PASS.
- `./out/stage/bin/with-stage2 check tools/migrate_shareplace.w` → ok.
  `check_stage2.log`. PASS.
- `with run tools/migrate_shareplace.w` (no args) → usage, rc=1.
  `noargs.log`. PASS.
- Fixture (`docs/audit/probes/tools_migrate_shareplace/fixture.w`:
  `fn sum(p: Pair) -> i64` reading fields only): dry run → `targets: 1`,
  `target: ...:sum parameter 0`, `total: 1 parameters to annotate (dry
  run)`; fixture untouched. `dryrun_fixture.log`. PASS.
- `--apply` on a copy → `fn sum(p: &Pair) -> i64`, call `sum(p)`
  unchanged, `total: 1 parameters annotated`, applied copy `with check`
  → ok. `apply.log`, `apply_check.log`. PASS.
- HELD (read, not executed): receiver `src_pos` adjustment (`:185`),
  extern/already-`&`/no-decl refusal arms (`:96`, `:230`), multi-file
  sort+dedup (`:239`-`:287`) — single-file path probed; shared code.

## Findings

None. In-report notes (not filed):
- Probe routing: a first fixture using `Vec.push`/`for x in xs` aborted
  the *seed compiler itself* during `with check` (`BUG: user generic
  call lacks a concrete contract ... MirModule.validate_generic_call_contracts`,
  SIGABRT rc=134) before the tool ever ran. That is seed-compiler
  behavior on generic-call shapes, not a tool defect; the struct-based
  fixture above avoids the shape and probes the tool cleanly. Exact
  output was overwritten by the passing re-run log; the shape is
  reproducible from `Vec[i32]` + `v.push(1)`.
- The #730 unsoundness caveat (`:79`) is real but disclosed in-source
  and mitigated by dry-run-default; no action.

Verdict: COMPLETE
