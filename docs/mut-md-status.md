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
| P7 Place-driven diagnostics | ✅ closed for this slice — see §15 table |
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
| 15.8 | closure capture conflict via iterator | ⏳ scheduled (see plan below) |
| 15.9 | escaping mutating closure | ✅ |
| 15.10 | assign through read-only place | ✅ |
| 15.11 | index-assign without IndexPlace | ✅ |
| 15.12 | rebinding stable global | ✅ |
| 15.13 | `&raw mut` requires a place | ✅ |
| 15.14 | `&raw mut` requires mutable place | ✅ |
| 15.15 | write through `*const T` | ✅ (via §15.10's *const T path) |
| 15.16 | deref-precedence | ✅ |
| 15.17 | mutation through for-loop view-var | ✅ implemented; see activation note below |

**Tally: 16/17 implemented; 1/17 scheduled with full plan.**

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

## §15.8 follow-up — ephemeral-of-source iterator typing

Spec example:
```with
some_function(xs.iter(), item => xs.push(item.value))
// ERROR: iterator over xs retains access; cannot also mutably capture xs
```

### Why it's not implemented

`xs.iter()` returns `VecIter[T]`. With's type system has no way to
express "this iterator value retains access to xs" — `VecIter` is
just a struct holding raw pointers; the borrow checker can't see the
implicit borrow.

P7.4 (closure capture conflict) already detects the related case
where another argument is `&xs` directly — the existing borrow
checker registers the SHARED borrow and flags the conflict with the
closure's EXCLUSIVE capture-borrow on the same place. What's missing
is treating iterator-method results as if they registered a SHARED
borrow on their receiver's place root.

### Two options considered

**Option A — hardcode method names (rejected as fragile):**
Detect arg-position calls whose method name is one of `iter`,
`entries`, `keys`, `values`, `slice`, `as_slice`, `range` (etc.) and
treat them as registering a SHARED borrow on the receiver's place
root for the duration of the enclosing call. Catches the canonical
case but breaks for any user-defined iterator method (and there's no
way to know which ones produce iterators).

**Option B — ephemeral-of-source typing (chosen as the principled fix):**
Extend the existing ephemeral-types machinery in Sema to mark certain
method return types as "ephemeral-of-receiver." The mechanism is
either:

  1. A trait, e.g., `trait IterFromRef[Source]` with a sentinel
     subtrait `EphemeralOfSelf` that the compiler recognizes. Methods
     returning a value implementing `EphemeralOfSelf` of `Self` (or a
     similar marker) have their return type tagged as ephemeral-of-
     the-receiver-place.
  2. A method-level attribute, e.g., `@[ephemeral_of_self] fn
     iter(self: &Self) -> VecIter[T]`. Simpler than a trait but
     requires per-method opt-in. Stdlib audit needed.

Option 1 fits With's existing trait dispatch better. Option 2 is more
mechanical to implement.

### Implementation slice plan

1. **Decide on the mechanism** (trait vs attribute). Trait is more
   principled; attribute is simpler. Recommend the trait route since
   it composes with user-defined iterator types.

2. **Extend ephemeral-type machinery in `src/Sema.w`** so that when a
   method-call result's declared return type carries the
   ephemeral-of-self marker, sema:
   - Records a place root for the produced value (the receiver's
     place root).
   - Registers a SHARED borrow on that place via
     `check_borrow_create_direct` for the lifetime of the enclosing
     call (released when the call returns).

3. **Audit stdlib for iterator methods that need the marker:**
   - `Vec.iter()`, `Vec.entries()`
   - `HashMap.entries()`, `HashMap.keys()`, `HashMap.values()`
   - `HashSet.iter()`
   - Slice `.iter()`, `.as_slice()`, `.range()`
   - Range `.iter()` (if applicable)
   - Any user-defined types implementing `Iter` that should retain
     access — TBD.

4. **Wire P7.4's closure-capture conflict** to consume the new
   borrow. With the SHARED borrow registered on the receiver place
   for the duration of the call, the existing
   `check_borrow_create_direct` SHARED+EXCLUSIVE conflict path will
   fire when the sibling closure mutably captures the same place.
   No new closure-side logic needed.

5. **Tests:**
   - Accepted: `f(xs.len(), |item| xs.push(item))` (independent value).
   - Rejected: `f(xs.iter(), |item| xs.push(item))` (iterator + mutable
     capture).
   - Rejected: `f(xs.entries(), |k, v| xs.insert(k, v))`.
   - Make sure user-defined iterators work the same way.

6. **Documentation:** update docs/mut.md §15.8 example with the help
   text pointing at the trait/attribute mechanism.

### Estimated effort

Few days of careful work. The ephemeral-types extension is the bulk;
the diagnostic itself is ~50 lines once the type tracking exists.

### Schedule

Land in the next focused slice immediately after this session's
follow-ups. Until then, P7.4's existing channels (direct &xs +
closure capture; field-access + closure capture) cover the most
common conflict patterns.

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
