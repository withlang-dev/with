# Primary verification — `tools/migrate_method_arg_moves.w`

Status: **COMPLETE** (stale tool; findings recorded, none filed per task scope)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 258 lines (single complete read)

No `with-stage1` binary exists at this commit; seed `with` and
`out/stage/bin/with-stage2` used instead. Both reject this tool
(identical errors); see Findings.

## Scope examined

Explicit-`move` inserter (`:1`): collects sites from the
`this parameter takes ownership of a non-Copy value` diagnostic
(`:31`), refuses on any unrelated error (`:51`), optionally filters to
`last-use` via the move-sites TSV (`:155`, #691; `--from-tsv` entry
shape at `:247` for seed-vs-stage analysis splits). Validates each span
is a token boundary and not already `move`/`copy` (`:166`), sorts
offsets (`:177`), splices `move ` in dry-run-default / `--apply` modes
(`:189`). All corrupt-span cases `exit_code(1)` without writing.

## Behavioral matrix (EXECUTED vs HELD)

- `with check tools/migrate_method_arg_moves.w` → 19 errors, rc=1
  (D22 view/move violations: `:44` borrow-through-view, `:47`
  `str`==`&str`, `:69` return `&str`-as-`str`, `:124` `bcm_parse_i64`
  `&str` args, moved-value at `:159`-`:160`/`:174`/`:196`/`:199`/`:257`,
  live-view mutation at `:180`-`:184`, view consumption at `:254`,
  arg-type at `:257`).
  `docs/audit/probes/tools_migrate_method_arg_moves/check_seed.log`.
  EXECUTED (fails).
- `./out/stage/bin/with-stage2 check` → same errors, rc=1.
  `check_stage2.log`. EXECUTED (fails).
- `with run tools/migrate_method_arg_moves.w` (no args) → fails at
  compile time (`error: run failed`); usage never reached.
  `run_noargs.log`. EXECUTED (fails).
- `./out/stage/bin/with-stage2 analyze <fixture> move-sites` → rc=0:
  `file:line:col ... liveness ...` header, 1 `last-use` site,
  `move-sites: 1 owned-param sites — 1 last-use (keyword), ...`.
  `movesites_probe.log`. PASS — the upstream contract the tool is built
  on is live; only the tool source is stale.
- HELD (cannot execute — tool does not compile): site collection,
  liveness filtering, token-boundary validation, apply splicing.

## Findings

Execution-verified, NOT filed (developer one-shot tool; task scope
forbids issue filing for primary files):
- Stale against D22 view/move strictness at every layer: fact views
  (`fact.path`, `cols.get`, `files.get`) can no longer flow into
  `str` params or be compared/returned as owned (`:44`, `:47`, `:69`,
  `:124`, `:257`); loop-carried `text`/`liveness_tsv` are consumed by
  `slice`/pass-by-value then reused (`:159`-`:199`, `:257`); the
  insertion sort mutates `offsets` while `old_offset` views it
  (`:180`-`:184`, compiler suggests `let old_offset: i32`). The
  diagnostic design itself (refuse-on-unrelated-error, token-boundary
  validation, last-use-only application) reads sound — the code needs a
  mechanical view-semantics port, not redesign. Exact output in
  `check_seed.log` / `run_noargs.log`.
- Minor: `--from-tsv` (`:247`) is reachable only as a positional arg
  spelling, undocumented in the `:208` usage line. Moot until the tool
  compiles again; noted for the eventual port.

Verdict: COMPLETE (audit done; tool itself is STALE — does not compile
at 450733e5)
