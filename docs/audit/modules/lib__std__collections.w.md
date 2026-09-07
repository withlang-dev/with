# Primary verification — `lib/std/collections.w` + `lib/std/hash.w` + `lib/std/option.w` + `lib/std/result.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: collections `b8cee10de409d9aaeda2f5643bf2ec914d0a733a1115cd761967997cd37fc003`;
hash `bbb3d2f37dfdeb5c740b9f11391f7d5875e04929ee6795ddc7e79ec6d40188c9`;
option `7af35f62282f4ecd99d3c6cff8561a52fb540d6a434db521d6f0d7a2585c9db7`;
result `f706d2388772362f6ed5008160ad125f2de1aafe880083d3464b2314fbdb23ba`
Source examined: child collections/hash (+ CodegenDispatch lowering regions
+ rt_core OOB paths); primary: full probe-matrix re-runs below (behavior is
the contract for these thin surface types)

## Scope examined

Container semantics: ownership transfer, D22 view/owned returns, OOB behavior.

Applicable overview targets examined: T5 (drop/ownership), T10 (D22 honesty), T23 (OOB).

## Behavioral matrix

All probes in `docs/audit/probes/std_coll/` re-run by primary, all pass:
- `p1_hashmap_get_remove`: get→`Option[&i32]` borrows (value ok),
  missing→None, remove→`Option[i32]` owned (value ok, key gone),
  missing-remove→None. **D22-conformant by execution.**
- `p2_btreemap_get_remove`: same shapes pass (dup-replace, remove-some,
  gone, missing-none).
- `p3a_vec_happy` (pop value/empty-None), `p3b_vec_oob` (check rc=0,
  RUN panics `Vec index out of bounds` loud), `p4_drop_ownership`
  (exact-once transfers, dup-replace, removes — all-ok).

## Verdict: no finding — D22-conformant, ownership exact-once, OOB loud

- `get` borrows / `remove` transfers uniformly across HashMap and BTreeMap,
  matching docs/d22-Eric-Ruling.md. Missing keys → None (Option-design
  silence, correct — not a T23 issue).
- Child's lowering-region reads (VEC_REMOVE load-then-compact, MAP_INSERT
  dup-drops-old, MAP_CLEAR walker, rt_core OOB panic) corroborate the
  executed behavior; recorded as child evidence.

## Notes

- option.w (24 lines) / result.w (13 lines): surface type decls exercised
  through every probe above (Some/None/unwrap/is_some/is_none paths all hit).
