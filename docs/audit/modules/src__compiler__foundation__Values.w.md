# Audit: src/compiler/foundation/Values.w @ 450733e5

Verdict: COMPLETE

Module: 75-line Wave 1 foundation — internable `ValueKey` (tag + int/text/type_ref)
plus constructors, `value_key_to_string`, `value_key_clone`. Read in full.

## Targets traced

- T13 (ownership/drop): `impl Copy for ValueKey` removed in 882921e8; owned-str
  boundaries clone explicitly (`value_key_string` line 44-50,
  `value_key_clone` line 74-75, both via `with_str_clone_ref`); observers
  borrow (`value_key_to_string(key: &ValueKey)` line 60). Only extern decl is
  the `&str` twin (line 4); no plain `with_str_clone` decl or call remains.
  Both `InternPool.intern_value` callers pass owned `key` to the borrowing
  `value_key_to_string` (auto-ref per D30 R1b) then move it into
  `value_keys.push` after the borrow ends; both files `check` clean.
- T15 (migration fidelity): history is coherent — 882921e8 (de-Copy + clone
  helper + borrow observer), 7d3e754b (`value_key_string(v: str)` ->
  `(v: &str)`), 2e135933 (add `_ref` twin decl), a69e77e0 (delete dangling
  plain `with_str_clone` decl). Current state matches landed-commit intent;
  no migration-plan deviation. Parallel root module `src/InternPool.w` is a
  maintainer-sanctioned forwarding-layer arrangement per
  docs/completed/with-selfhost-wave1.md ("Keep existing root modules ...
  as thin forwarding layers"), and it also checks clean — not a defect.
- T22 (spec conformance): canonical structural keys per wave1 contract
  (same key -> same ID; tag-prefixed canonical strings `int:`/`bool:`/
  `str:`/`ty:`/`invalid` keep int/bool/str/marker/invalid domains disjoint;
  `bool:true` -> `bool:1` distinct from `int:1`). Dedup + resolve round-trip
  covered by test/internals/intern_pool_test.w lines 74-87, passing.

## Findings

None. No defects survived refutation.

1. (considered, refuted) `out ++ key.text_value` (line 67) reads owned str
   through `&ValueKey` — refuted: `check` clean under seed stage1; concat
   through borrow is the D30 R1b-blessed pattern.
2. (considered, refuted) dual `src/InternPool.w` vs
   `src/compiler/foundation/InternPool.w` — refuted: wave1 plan explicitly
   sanctions root forwarding layers; both check clean; ownership of that
   arrangement belongs to the InternPool module, not this one.
3. (considered, refuted) `bool` canonicalized via `int_value` 1/0 —
   refuted: `bool:` vs `int:` prefixes keep the domains disjoint (test
   asserts `v0 != v2`).

## Probes run

- `out/bootstrap/bin/with-stage1 check src/compiler/foundation/Values.w`
  -> `ok` (exit 0). Binary verified present via `ls out/bootstrap/bin/`.
- `with-stage1 check src/compiler/foundation/InternPool.w` -> `ok`.
- `with-stage1 check src/InternPool.w` -> `ok`.
- `with-stage1 test test/internals/intern_pool_test.w`
  -> `ok: 1 test passed` (exercises int dedup, bool/str/marker
  distinctness, resolve round-trip `rv.text_value == "hello"`, count == 4).

## Negative controls

- `grep with_str_clone\\( Values.w` -> no match (no plain consuming-str call).
- `grep "impl Copy" Values.w` -> no match (stays non-Copy).
- `git log --follow` shows only the four expected #747/D30 commits; no
  unrelated rewrite of key semantics.
- Caller search (`value_key_[a-z_]+|ValueKey|VALUE_KEY_[A-Z_]+`, REGEX mode
  via grep): only InternPool twins + Mod.w re-export + self; no stale
  by-value `value_key_to_string` caller, no missed `value_key_clone` site
  (`resolve_value` clones at both tails, foundation:159 and root:172).

## Git intent check

`git show` per commit (882921e8, 7d3e754b, 2e135933, a69e77e0) confirms each
hunk on this module is the maintainer-described #747 step; HEAD is
450733e5 as requested. No parallel-implementation surprise.
