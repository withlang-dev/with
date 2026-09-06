# Primary verification — `tools/migrate_receivers.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 260 lines (single complete read)

No `with-stage1` binary exists at this commit (`out/stage/bin/` holds
only `with-stage2`); syntax validity was checked with the installed seed
`with` and `out/stage/bin/with-stage2` instead. Both recorded below.

## Scope examined

D7 eliminate-self migrator (`:1`): rewrites in-place receiver methods
`fn get(self: &Self)` → `fn get()`, `mut self` → `mut fn`, `move self`
→ `move fn` via compiler `select:kind=declaration` facts + Lexer byte
splices (`:42`, `:63`). Skips: dotted top-level methods (`:91`),
associated/free functions (no `self`, `:123`), trait-declaration read
contracts (`:137`); trait-IMPL read borrows DO migrate (`:131`, #727).
Fails loudly on syntax/compiler mode mismatch (`:142`) and refuses to
write when preflight fails (`:186`). No dry-run flag by design: it
writes in place whenever methods are found (`:205`); a repeat run is a
no-op (no explicit `self` remains).

## Behavioral matrix (EXECUTED vs HELD)

- `with check tools/migrate_receivers.w` → ok (seed).
  `docs/audit/probes/tools_migrate_receivers/check_seed.log`. PASS.
- `./out/stage/bin/with-stage2 check tools/migrate_receivers.w` → ok.
  `docs/audit/probes/tools_migrate_receivers/check_stage2.log`. PASS.
- `with run tools/migrate_receivers.w` (no args) → usage
  `migrate_receivers [--exclude file.w ...] <file-or-dir> ...`, rc=1.
  `noargs.log`. PASS.
- `docs/audit/probes/tools_migrate_receivers/fixture_src.w` (Counter impl:
  `get(self: &Self)`, `bump(mut self: Self, v)`, free `describe`):
  ran on a copy → `migrated ...: 2 receiver methods`, diff shows exactly
  `fn get() -> i32: self.n` + `mut fn bump(v: i32)`, free fn untouched,
  migrated copy `with check` → ok. `fixture_run.log` + diff. PASS.
- Trait fixture (`trait Summable` decl + `impl Summable for Pair` +
  dotted `fn Pair.zero()`): exactly 1 method migrated — the trait IMPL;
  trait DECL kept explicit, dotted method skipped; output checks ok.
  `fixture_trait_run.log` + diff. PASS.
- HELD (read, not executed): `--exclude` filtering (`:208`, same
  `migrate_path` loop as probed); mismatch-preflight error path
  (`:142`, needs a crafted syntax/semantics divergence); #727
  body-never-touches-self trait-impl case (covered by repo behavior
  test per the `:133` comment, not re-probed here).

## Findings

None. In-report notes (not filed):
- Write-always design (no `--apply`/dry-run gate) is acceptable for a
  one-shot migrator with preflight refusal (`:186`), but a mistaken path
  argument rewrites real files — the `--exclude` flag is the only guard.
- `get()` body still spells bare `self.n` post-migration and checks ok:
  the synthesized receiver stays in scope, confirming the D7 P2
  contract the tool relies on.

Verdict: COMPLETE
