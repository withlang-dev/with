# Primary verification — `lib/std/iter.w`

Status: **INCOMPLETE** (ownership semantics verified; value behavior held)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 69 lines (single complete read)

## Scope examined

Externs `with_vec_len`/`with_vec_get_i32`/`with_vec_get_str`/
`with_vec_push_i32`/`with_vec_new_out` (`:7-11`); `sum` (`:14`),
`map` (`:24`, `Vec[str]` → `Vec[i32]`), `filter` (`:37`),
`count[T]` (`:50`, takes `[T]` array), `contains` (`:54`, takes
`[i32]` array), `iter_sum` (`:60`, takes `VecIter[i32]`). Dep:
`std.collections` (`Vec`, `VecIter`). Callers: `build/compiler.w:1100`
(embeds `std.iter`); `src/Sema.w:3864` (comment cites `iter_sum`);
`src/CodegenDispatch.w:10942,12793` (`mir_emit_iter_sum` intrinsic
lowering); `test/behavior/behav_veciter_iter_sum.w` and
`test/d_acceptance/behav_veciter_iter_sum.w` (`use std.iter`,
expect 60); `test/behavior/prelude_shadow_*.w` docs reference
`std.iter.map`. No other lib callers.

## Behavioral matrix (EXECUTED vs HELD)

- `with check lib/std/iter.w` → ok (stage1). EXECUTED.
- `docs/audit/probes/iter/iter_move.w` (first attempt: `sum(v)`,
  `contains(v,..)`, `filter(v,..)`, `v.iter()`, `sum(empty)` +
  `empty.iter()` on shared vectors): `with-stage1 run` EXECUTED but
  failed to compile — 5× `error: use of moved value` (one each at the
  `contains` ×2, `filter`, `v.iter()`, and `empty.iter()` uses; the
  first move is `sum(v)`). Naively expected to compile; the compiler
  instead enforced consuming ownership. This EXECUTED failure is the
  evidence for Finding 1 below.
- `docs/audit/probes/iter/iter.w` (rewrite with a fresh `mk()` vector per
  call, covering `sum`→68, `count`→4, `contains`→true/false,
  `filter`→`[10,30]`, `iter_sum`→68, empty cases →0, `map`→`[1,4]`):
  written, not run (tool-batch budget exhausted). HELD.
- `map`/`filter`/`count`/`contains`/`iter_sum` value-level behavior:
  held behind the unrun rewrite. HELD.
- `mir_emit_iter_sum` intrinsic vs the With loop body equivalence:
  unverified. HELD.

## Findings

None filed (per task: no GitHub issues from this audit). In-report notes
(each with a refutation attempt):

- `sum`/`map`/`filter` (plain `Vec` params) and `contains`/`count`
  (plain `[i32]`/`[T]` params) consume their input: after `sum(v)`, `v`
  cannot be reused without a fresh/cloned vector. Execution-verified:
  observed 5× `error: use of moved value … a moved value cannot be used
  again …` vs the naive expected-compile. Refutation attempt (is this a
  bug?): the signatures declare plain by-value params, and the language
  rule is that the signature states ownership, so consuming is the
  conforming reading — the compiler enforced exactly what the signatures
  declare. Not a defect; ergonomics note (no chaining/reuse without
  clone), consistent with the D5 signature-ownsership rule.
- `contains(mk(), 10)` / `count(mk())` passed a `Vec[i32]` where `[i32]`/
  `[T]` is declared, with no type error (only move errors) — some
  Vec→array coercion exists. Refutation: the checker accepted it, so the
  mechanism is present; its exact semantics are unverified (held).
- `iter_sum` has a dedicated compiler intrinsic lowering
  (`mir_emit_iter_sum`) alongside its With loop body; their equivalence
  was not verified (held). Note only.

Verdict: INCOMPLETE (value-behavior probes held; ownership verified)
