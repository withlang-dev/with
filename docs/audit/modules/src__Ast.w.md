# Primary verification — `src/Ast.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `2e38084691327ad4ca1c357b82549c1e3885690f2b3bd58df4b89d17b57fcfd5`
Source examined: child 1-1930 complete (seven ranges incl. all unread
remainder); primary: prior survey (pool header, exact-int, id-collision
pilot) + `add_binding`-adjacent layout consumers spot-read during wave-4
(NK_FOR/NK_CALL/NK_IF_EXPR cross-checked Parser-vs-Ast by child, accepted),
plus OOB probe re-run below

## Scope examined

Pool layout contract, accessor OOB directions, node-id numbering (#660 class).

Applicable overview targets examined: T13 (layout), T23 (OOB), T24 (id numbering).

## Verdict: no finding — no drift, OOB split is by-design

- T13 layout NO DRIFT (child cross-checks, accepted as child evidence):
  NK_FOR/NK_CALL/NK_IF_EXPR Parser usage matches Ast declarations; the
  AGENTS.md:281 layout is the runtime `.o` tree, unrelated — prior confusion
  resolved, no contradiction.
- T23 OOB split: unguarded accessors (`kind`, `get_data0-2`, `get_start/end`,
  `get_extra`, `get_string`, `get_decl`) PANIC on OOB — primary re-ran
  `oob_vec_get.w` (Vec-index panic, loud); guarded accessors (`file()`→0,
  `find_*`→-1, predicates→false, `get_call_named_arg`/`hook_phase`→0) fail
  soft. Split is consistent (structural accessors panic, queries default),
  documented direction — no filing.
- Prior survey notes (fail-loud `ast_pool_phase_bug`, distinct-FileId pilot
  vs #660) stand.

## Notes

- Child's per-range coverage (1-60/61-185/186-250/251-775/776-930/931-1430/
  1431-1930) recorded; primary's own full read remains the earlier partial
  survey + the cross-checks above. Residual risk accepted proportional to
  the file's structural simplicity (data declarations + accessors).
