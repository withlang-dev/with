# D55 — Six rulings of 2026-09-22: destructors are skipped only at the type's boundary; facade destroyers; examples track the spec; `Sender` is `Clone`; `print` over `Display`

**Laws:** 5, 10, 6 (docs/mission.md).

**Date:** 2026-09-22. **Status:** BDFL rulings (Eric); spec sentences in
§2.5.1, §9.7, §14.15, §16.2b.3, §18.2; examples policy in CLAUDE.md/AGENTS.md.

1. **`void *` destroyer (facade §61).** "Accepts the representation" is C's
   own conversion rule: `void *` accepts every object-pointer
   representation, never a function pointer (they do not convert to
   `void *` in standard C) nor a by-value representation. It can only accept
   or reject a program that already has a destruction path; it never grants
   ownership.
2. **`destroys` without `drop`.** Compile error at the resource; the facade
   author names the unary destroyer as `drop` — one word. **Higher RAII**
   (a must-consume linear resource, for destroyers that take arguments) is
   the right long-term answer and is a *named future ruling*: it touches
   `match`, early return, panic unwinding and fibers, and nobody
   half-implements it in the interim.
3. **Destructuring a `Drop` value (#1272).** The Swift/Mojo shape: a
   struct/enum pattern on a `Drop` value is an error everywhere except
   inside the type's own `move fn` methods, where it is the visible disarm
   and must be **total** (every field bound or `_`; partial patterns leave
   fates unstated, which Swift's "cannot partially consume" exists to kill).
   One rule for `let`, `match`, `if let`. Rulings 2 and 3 are corollaries
   of one §2.5.1 sentence: the only way to skip a destructor is a spelling
   visible at the type's own boundary.
4. **Examples track the current spec.** "Examples are contracts" and "the
   spec moved" cannot both hold; a spec change that breaks an example
   updates the example in the same change; a compiler/stdlib change that
   does is a defect. `pub(package)` (97 errors in one example is a signal)
   is a separate argument, to be brought with data on how many `pub` marks
   the fixed examples needed.
5. **`Sender[T]` is `Clone`, never `Copy`** (semantic copies are spelled),
   retaining the runtime refcount; the channel closes when the last sender
   drops; `Sender[T]: Send` requires `T: Send`.
6. **`print[T: Display](v: &T)`** as a plain generic (the `&str` case a
   monomorphized instance); the `match` arms join under the `Display` bound
   where the checker already joins arms, not as a new demanded-argument
   feature; a mixed-arm match yields nothing joinable and the fix-it is
   `print(f"{x}")` — the idiom people should learn anyway. The reference
   fizzbuzz is the mixed-arm form and is updated under ruling 4.