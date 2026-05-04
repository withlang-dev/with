# docs/mut.md Rev 8 — final status

Completed 2026-05-01. All phases shipped and verified.

## Phase summary

| Phase | Status | Key commit |
|---|---|---|
| P1 Parser additive surface | done | `4ae4d13` |
| P2 Sema accepts new syntax | done | `b8dbb70`..`9d2f607` |
| P3 First seed reinstall | done | (seed updated after P2) |
| P4 Stdlib trait redefinition | done | `22bdca7`..`f92b0d4` |
| P5 Stdlib leaf migrations | done | `b12a7a7`..`cb804d3` |
| P6 NLL view-liveness | done | `b637379` |
| P7 Place-driven diagnostics (17/17) | done | `c9c6f46`..`5556cdf` |
| P7.5 Drain warnings | done | `669baf4`..`38326a9` |
| P8 Compiler self leaves | done | `2507b11`..`2ec3179` |
| P9/P10 Compiler self mid/roots | done | `502baa9`..`8331841` (Slice A+B) |
| P11 Second seed reinstall | done | (seed updated after Slice B) |
| P12 Lockdown | done | `a41130a` |

## What shipped

`&mut T` is rejected in safe With with a §15.1 diagnostic. All 17 §15
diagnostics are hard errors. The migrator (`with migrate`) emits `&raw mut`
instead of `&mut`. 727+ tests pass under strict mode.

The compiler self-hosted source contains zero `&mut` in function signatures.
Mutable access uses `mut self: Self` receivers, `&raw mut` for FFI pointer
casts, and direct `var` mutation for local state.

## Slice A (P8-P10 mechanical removal) — `b7bf86b`

Converted ~180 `&mut` sites in CImport.w free functions, ComptimeEval.w
redundant params, and InternPool to handle types. Straightforward
find-and-replace after auditing read-only vs. mutating usage. The main
insight: ~55 CImport.w params marked `&mut` were actually read-only and
could be downgraded to `&` without behavioral change.

## Slice B (handle-type conversion) — `3099ec4`..`8331841`

Converted CiTypePool, CiExprPool, CiStmtPool, CiDeclPool, and AstPool from
free-function-with-pool-pointer to method-on-handle-type pattern. This
eliminated the remaining ~70 `&mut Pool` params by making the pool the
receiver. ComptimeTransform.w and Frontend.w followed the same pattern.
The handle-type approach proved cleaner than the Sema-bundle alternative
because it preserved per-pool encapsulation.

## P6 (NLL view-liveness) — `b637379`

Implemented scoped borrow expiry in `expire_dead_borrows_in_block` rather
than full CFG-based NLL. The key mechanism: when a shared borrow's last use
precedes a mutation in the same block, the borrow is expired before the
conflict check fires. This handles the common `let r = &x; use(r); x = 5`
pattern without building a full CFG. The §15.6 diagnostic includes
three-location spans (borrow creation, last use, conflicting mutation).

## P7 (place-driven diagnostics) — `c9c6f46`..`38326a9`

All 17 §15 diagnostics implemented. The hardest were §15.8 (iterator capture
conflict via `@[iter_of_self]` attribute), §15.9 (escaping mutating closures),
and §9.2/§15.7 (closure capture conflict with sibling arguments). The
`classify_place` infrastructure proved robust — most diagnostics were
one-function additions once the place/mutability classification was solid.

## P12 (lockdown) — `a41130a`

Single coordinated commit: `STRICT_NO_MUT_REF=1`, 13 warning-to-error
promotions, `UOP_MUT_REF` removed from active codepaths, migrator updated,
49 test files migrated, `MultiIndex.multi_index_set` deprecated alias deleted.

## Post-P12 precision & API work (2026-05-01)

Implemented the remaining mut.md Rev 8 features that were deferred during
the initial migration:

| Feature | Section | Status |
|---|---|---|
| Disjoint field captures | §9.2 | done — `034aff9` |
| Nested mutating call detection | §5.4 | done — `034aff9` |
| Disjoint constant-index borrows | §8.1 | done — `e3530a5` |
| VecSlot scoped access | §10 | done — `83e956d` |
| VecIterPlace (place-yielding iteration) | §19.5 | done — `903841f` |
| HashMap.entry() scoped access | §10 | done — `2fa78c3` |
| Compound assignment single-eval | §6.3 | verified — `7a33f7c` |
| NLL branch-divergent | §8.4 | already works (AST-walk approach) |
| Argument independence | §5.5 | already works for common cases |

## Post-P12 additional work (2026-05-02)

| Feature | Section | Status |
|---|---|---|
| IndexPlace user impl dispatch | §2.4 | done — `5a6dd13` |
| IndexPlace §6.3 compound single-eval | §6.3 | done — `32033b5` |
| Scoped/ScopedMut traits removed | §17 | done — `9a9f7d3` |

## Deferred features now done (2026-05-02)

| Feature | Section | Commit |
|---|---|---|
| `move` closure semantics | §9.4 / §15.9 | `7219bfd` |
| `with` tuple destructuring | §10.2 | `f3da561` |
| `Vec.get_disjoint(i, j)` | §10.2 | `c480c4b` |
| `Vec.range(start..end)` | §19.1 | `70dc768` |
| `Vec.iter_ref()` (`&T` yields) | §19.5 / §15.17 | `862a456` |

## Still deferred (stretch goals)

- **Mutable slice APIs**: §13.5 says mutable slices are removed from safe With.
  The replacement is index-based loops (working), scoped `with` access (working
  for single slots/entries), and raw pointers at the unsafe edge (working).
  `split_at_mut`/`get_disjoint_mut` for raw pointers are low priority — the
  safe VecSlot/VecIterPlace APIs cover the common cases.

## What to watch for

- **`&raw mut` in user code**: Users migrating from `&mut x as *mut T` need
  `&raw mut x`. The migrator handles this automatically for C imports. User
  `.w` code needs manual migration — the §15.1 diagnostic points them to the
  fix.
- **`mut self: Self` receiver mode**: This is the new primary way to express
  mutating methods. Users writing `self: &mut Self` will get the §15.1
  rejection. The fix is `mut self: Self` (or `mut self: T` for concrete types).
- **Closure escape false positives**: Any closure that mutates a captured
  `var` and is passed as a function argument (not called inline) triggers
  §15.9. This is intentionally conservative — the closure might not actually
  escape, but the analysis doesn't track callee signatures.
