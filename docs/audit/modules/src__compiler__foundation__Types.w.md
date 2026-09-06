# Audit: src/compiler/foundation/Types.w @ 450733e5

- Commit: 450733e58a1a7cce14f9cb2084943fc178815111 (HEAD; commit does not touch this module)
- Module: 200 lines, read in full. Wave 1 foundations: internable `TypeKey` + canonical-key constructors.
- Ownership model: `TypeKey.name: str` is owned, non-Copy (`impl Copy` removed in 882921e8 by intent).

## Targets traced

- T13 ownership/drop: all 7 `name`-producing sites (Types.w:46,127,136,145,154,163,200) clone via the
  `&str` twin `with_str_clone_ref`; constructors take `&str` borrows, so no double-free/consume.
  `type_key_clone` (Types.w:199-200) performs the explicit owned copy; sole in-repo caller
  `InternPool.resolve_type` (src/compiler/foundation/InternPool.w:139) clones out of the pool,
  `intern_type` (InternPool.w:121-131) moves the owned key in via `push`. No missing-drop surface
  in source (str-drop glue is runtime-side per 882921e8).
- T15 migration fidelity: extern decl is exactly `with_str_clone_ref(s: &str)` (Types.w:6); the stale
  plain-consuming `with_str_clone(s: str)` decl was deleted by landed commit a69e77e0 (D30 R1b) —
  current state matches that intent. Observer `type_key_to_string(key: &TypeKey)` borrows per D5
  intent from 882921e8. No residue.
- T22 spec conformance: `type_key_to_string` (Types.w:169-196) covers every non-invalid tag
  (NAMED/PTR/REF/SLICE/ARRAY/TUPLE2/TUPLEN/OPTIONAL/RESULT2/FN_SIG/TRAIT_OBJECT/GENERIC_PARAM/
  GENERIC_APPLY2) with deterministic field encodings (mut/variadic/arity/count in flags/arg slots),
  fallback `"invalid"`. Encodings are injective over the fields each tag carries. `GENERIC_APPLY2`
  stores only a0/a1 by design (name says 2); no in-repo caller passes wider arities, so no
  truncation defect (checked vs callers, not just the signature).

## Probes run

1. `out/bootstrap/bin/with-stage1 check src/compiler/foundation/Types.w` → `ok` (seed binary exists
   at out/bootstrap/bin/with-stage1; `bootstrap/bin/with-stage1` does not exist).
2. `out/bootstrap/bin/with-stage1 check src/compiler/foundation/InternPool.w` (sole caller) → `ok`,
   confirming the borrow-then-move in `intern_type` and the clone in `resolve_type` check clean.
3. Negative control: `check` on /tmp/with_neg_ctrl.w (deliberate `i32`/`str` mismatch) → correctly
   rejected (`error: type mismatch in binding`), so the two `ok`s are non-vacuous.

## Refutation attempts

- Candidate "pack1/2/3 and most constructors have no in-repo callers (dead code)": confirmed no callers
  in src/tests/tools, but public constructor/pack helpers are API surface, not a target violation —
  not filed.
- Candidate "generic_apply2 drops args beyond a0/a1": refuted — tag arity is 2 by design and no caller
  contradicts it.
- Candidate "migration-plan deviation": refuted via `git show 882921e8/a69e77e0` — current borrow/clone
  shape is exactly the landed maintainer intent.
- Legacy `src/InternPool.w` also calls `type_key_invalid()` — it is a wrapper over
  `compiler.foundation.Types`, consistent, not a fork.

## Findings

None. No numbered defects.

## Verdict

COMPLETE — src/compiler/foundation/Types.w conforms on T13, T15, T22; 0 findings; probes 1-2 pass, negative control rejects.
