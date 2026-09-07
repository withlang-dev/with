# Primary verification — `src/AsyncLower.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `1b21e421c3d4dd1c564bbcbf6ddd996b6c41ad5d76053298bb0df6291b3548bd`
Source examined: child 424/424 complete; primary: `walk_expr` core :117-301
(full read incl. all collection/struct/match arms), link-gate
`requires_async_runtime` (AsyncMir.w:110-118, full read), fstring/BREAK arm
absence (grep-verified), plus probe re-runs below

## Scope examined

Suspend-point inventory walker feeding the async-MIR dump artifact.

Applicable overview targets examined: T4 (inventory completeness), T13
(walker coverage), T23 (silent skips).

## Behavioral matrix

Probes in `docs/audit/probes/asynclower/` re-run by primary (all `check` rc=0):
`p1_basic_await`, `p3_fstring_await`, `p6_break_await`, `p10_select`,
`p11_fstring_run` — plus `p11` RUNS `v=41` rc=0 (fstring-await end-to-end correct).

## Verdict: inventory gaps are observability-only — not filed

- `walk_expr` has NO arm for `NK_FSTRING` (a live AST node at this stage,
  Ast.w:98, Parser.w:4141) and none for `NK_BREAK`: awaits inside either are
  silently skipped by the inventory (child's p3 dump: states=1,
  suspend_points=0). Same unhandled-kind-skip SHAPE as #999, narrower blast radius.
- Blast radius verified narrow: (1) the link gate `requires_async_runtime`
  is flavor-based (`body.flavor == Async` suffices, AsyncMir.w:110-118), so a
  missed inventory entry can never drop the runtime — p11 links+runs;
  (2) the real guard (MirSuspendCheck) walks MIR independently and IS
  complete on these shapes (p3/p6 check clean for the right reason);
  (3) runtime behavior correct (p11 v=41).
- Only consumer of the inventory is `dump_async_mir_module` (observability).
  An undercounting dump is a minor; recorded here, not filed. If the
  inventory ever gains a behavioral consumer, add FSTRING/BREAK arms first —
  the missing arms are named so the future diff finds them.
