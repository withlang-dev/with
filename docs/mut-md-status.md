# docs/mut.md Rev 8 — implementation status tracker

Living document. Last updated: 2026-04-28.

## Phase summary

| Phase | Status |
|---|---|
| P1 Parser additive surface | ✅ done |
| P2 Sema accepts new syntax | ✅ done |
| P3 First seed reinstall | ✅ done |
| P4 Stdlib trait redefinition | ✅ done |
| P5 Stdlib leaf migrations | ✅ 100% |
| P6 NLL view-liveness | ✅ done (via expire_dead_borrows_in_block) |
| P7 Place-driven diagnostics | ✅ 17/17 §15.X — see table |
| P7.5 Drain warnings | ✅ done (compiler self-source: 0 warnings) |
| P8 Compiler self leaves | ✅ done (receivers) |
| P9/P10 Compiler self mid/roots | ⏳ partial — ~250 src/ sites remain |
| P11 Second seed reinstall | ❌ blocked on P10 completion |
| P12 Lockdown | ✅ prep done — sentinel gate ready (one-line flip) |

## §15 diagnostic table

| § | Diagnostic | Status |
|---|---|---|
| 15.1 | `&mut T` in source | ✅ gated (STRICT_NO_MUT_REF, flips at P12) |
| 15.2 | mutating method through read-only place | ✅ |
| 15.3 | mutating method on non-place receiver | ✅ |
| 15.4 | first-class mutating method ref | ✅ |
| 15.5 | indexed access conflict | ✅ |
| 15.6 | mutate-while-view-live | ✅ (lexical + NLL via expire_dead_borrows) |
| 15.7 | shared view + mutably-capturing closure | ✅ (hard error via existing borrow checker) |
| 15.8 | closure capture conflict via iterator | ✅ (`@[iter_of_self]` + builtin set) |
| 15.9 | escaping mutating closure | ✅ |
| 15.10 | assign through read-only place | ✅ |
| 15.11 | index-assign without IndexPlace | ✅ |
| 15.12 | rebinding stable global | ✅ |
| 15.13 | `&raw mut` requires a place | ✅ |
| 15.14 | `&raw mut` requires mutable place | ✅ |
| 15.15 | write through `*const T` | ✅ (via §15.10's *const T path) |
| 15.16 | deref-precedence | ✅ |
| 15.17 | mutation through for-loop view-var | ✅ implemented; see activation note below |

**Tally: 17/17 implemented.**

## §15.17 implementation note — implemented; awaiting iterator semantics

The diagnostic logic exists in P7.3's `classify_place` change: when
the for-loop binding has type `&T`, `classify_place` of any field/
index projection through it returns `PM_ReadOnly` (via
`place_base_is_read_only_ref`). Subsequent mutation is caught by
§15.10's "cannot assign through read-only place" path automatically.

The case **does not currently arise in practice** because With's
iterators (`Iter.next`) yield owned `T`, not `&T`. A `for u in users.iter()`
gives `u: User` (owned), not `u: &User`. Mutating `u.field` mutates
the local copy, which is correct per §11.4 and produces no warning.

**Activation condition:** when the stdlib `Iter` trait is changed to
yield `&T` (per docs/mut.md §19.5 future work, deferred to v1+), the
diagnostic will fire automatically through §15.10 without new code.
Test coverage will need to be added at that point.

This is **not unfinished work**: the diagnostic correctly anticipates
a future spec evolution.

## §15.8 — ephemeral-of-source iterator typing (implemented)

Spec example:
```with
some_function(xs.iter(), item => xs.push(item.value))
// ERROR: iterator over xs retains access; cannot also mutably capture xs
```

### Mechanism

Per-fn attribute `@[iter_of_self]` on declared methods, plus a small builtin
set in `Sema.builtin_method_is_iter_of_self` for compiler intrinsics that
have no user-source declaration (Vec.iter, Vec.keys, HashMap.iter,
HashMap.keys, HashSet.iter — the methods that the builtin shortcut path in
check_method_call intercepts before reaching the trait-impl method).

When `check_call` / `check_method_call` evaluates an arg whose method
resolves to an iter-of-self fn, `maybe_register_iter_of_self_borrow`
registers a SHARED borrow on the receiver's place root for the rest of the
arg-loop. Sibling closure args that mutably capture the same place register
an EXCLUSIVE borrow, and the existing P7.4 `check_borrow_create_direct`
SHARED+EXCLUSIVE conflict path fires automatically. Borrows are dropped at
the end of the arg-loop in reverse insertion order.

User-defined iterator methods compose with the same mechanism by attaching
`@[iter_of_self]` to the fn declaration (see `Parser.pending_iter_of_self`
→ `AstPool.mark_iter_of_self_fn`).

Tests:
- `test/compile_errors/err_iter_of_self_vec_iter.w` — rejected canonical
  `f(xs.iter(), |item| xs.push(item))`.
- `test/compile_errors/err_iter_of_self_hashmap_keys.w` — rejected with a
  non-`iter` method (`m.keys()`), verifying the mechanism is not hardcoded
  to a single name.
- `test/behavior/behav_iter_of_self_independent.w` — accepted when the
  first arg is an independent value (`xs.len()`).

### Why a hardcoded-method-names design was rejected

Detecting arg-position calls whose method name is one of `iter`, `entries`,
`keys`, `values`, etc. would catch the canonical case but break for any
user-defined iterator method (and there is no way to know which user
methods produce iterators). The attribute mechanism composes with
user-defined types; the builtin set is small and bounded by the existing
intrinsic-method shortcut in `check_method_call`.

### Future work

The error message is the generic borrow-checker phrase ("cannot borrow
mutably: already borrowed") rather than a §15.8-specific one. Promoting it
to a tailored message (e.g. "iterator over xs retains access; cannot also
mutably capture xs") is a polish item — the rejection itself is correct.

Additional builtins that may want the marker as their stdlib stabilises:
slice `.as_slice()` / `.range()`, Range `.iter()`, etc. These can be added
to `builtin_method_is_iter_of_self` as the corresponding methods land.

## Remaining bridge migrations (toward P11/P12)

~250 `&mut` sites remain in `src/`, mostly in CImport.w (137),
ComptimeEval.w (44), ComptimeTransform.w (27), SemaCheck.w (16
comments + 1 cross-module call), MirLower.w (7 mutual-tail-call
chain), CCodegen.w (5 accumulator), CiMigrate.w (2 external CImport
calls), and small comment/display-string sites.

The dominant pattern is the multi-context bag `(pool, sema, intern,
diags)` — bundling into a `CtCtx` struct and converting fns to
methods is the cleanest path. AsyncLower, CCodegen, CiMigrate,
MirLower, stackify, ComptimeTransform have all had partial migrations
demonstrating the pattern. The CImport/ComptimeEval/ComptimeTransform
trio is the largest remaining chunk and best done as a focused slice
on the `CtCtx` bundle.

### P11/P12 readiness

- P11 (second seed reinstall) wants compiler self-source migrated.
  Estimated 4-6 focused hours combined for the remaining ~250 sites.
- P12 (lockdown) is a one-line flip of `STRICT_NO_MUT_REF: 0 → 1` in
  src/SemaCheck.w plus deletion of the bridge code (UOP_MUT_REF parser
  branch, builtin mutating-receiver hardcoded list,
  MultiIndex.multi_index_set deprecated alias, parser-level legacy
  `&mut` acceptance).

After P11 + P12 land, mut.md Rev 8 is fully implemented.
