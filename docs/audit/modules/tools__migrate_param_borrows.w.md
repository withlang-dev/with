# Primary verification — `tools/migrate_param_borrows.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 140 lines (single complete read)

No `with-stage1` binary exists at this commit; seed `with` and
`out/stage/bin/with-stage2` used instead. Both recorded below.

## Scope examined

#747 `str`→`&str` rewriter (`:1`): pure-Lexer scan (no compiler facts),
rewrites only params whose type is exactly `str` followed by `,`/`)`/`=`
(`:105`), so `&str`, `*str`, `Vec[str]`, `self` are never touched.
Skips `extern fn` in both spellings (`:58`, `:61`), honors a
`fn_name<TAB>param` denylist (`:108`), dry-run default, `--apply`
edits back-to-front so offsets stay valid (`:130`). Returns 2 on
missing file args (`:36`).

## Behavioral matrix (EXECUTED vs HELD)

- `with check tools/migrate_param_borrows.w` → ok (seed).
  `docs/audit/probes/tools_migrate_param_borrows/check_seed.log`. PASS.
- `./out/stage/bin/with-stage2 check tools/migrate_param_borrows.w` →
  ok. `check_stage2.log`. PASS.
- `with run ...` (no args) → `usage: migrate_param_borrows [--apply]
  <denylist> <file.w>...`, rc=2. `noargs.log`. PASS.
- Dry run on fixture (`shout(s: str)`, `echo2(s: str, t: str)`, empty
  denylist) → exactly `shout(s)`, `echo2(s)`, `echo2(t)`, `total: 3`;
  fixture byte-identical after. `dryrun.log`. PASS.
- `--apply` on a copy → `s: &str` × 3, `total: 3`, applied copy
  `with check` → ok — including the unchanged literal call
  `shout("hi")`, confirming auto-referencing keeps call sites spelled
  identically per the `:1` header claim. `apply.log`,
  `apply_check.log`. PASS.
- HELD (read, not executed): non-empty denylist filtering (`:108`,
  loop logic identical to the probed empty case), `extern "C"` skip
  (`:61`), `=` default-arg shape (`:107`).

## Findings

None. Refutation (not filed):
- First `--apply` probe reported `return type mismatch` on the applied
  file — root-caused to MY fixture, not the tool: the fixture itself
  contained `fn already(s: &str) -> str: s` (borrow returned as owned),
  which fails `with check` with or without migration. Removed the bad
  fn; clean fixture migrates and checks ok end-to-end (above).

Verdict: COMPLETE
