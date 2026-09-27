# D52 — A global is never moved out of; a `const` is a value, not a place

**Date:** 2026-09-21. **Status:** ruled — the §9.1c sentence below was
blessed verbatim the same day ("blessed") and landed (#1245); the compiler
enforces it (#1242).

**Decision.** Consuming a module global — binding it by value
(`let out = g`), passing it to a plain-`T` parameter, returning it (tail or
`return`), or calling a `move self` method on it — is a compile error when
its type needs drop: "cannot move out of global `g`: a global always holds a
value; clone it (`.clone()`) instead". Reading, viewing (`g.get(0)`,
`let v = g.field` as a D27 alias), mutating in place and reassigning stay
legal. A `const` is exempt: it desugars to a comptime value and every use
materializes it, so `return SOME_CONST` transfers nothing.

**Context.** `let out = g; g = Vec.new(); out` double-freed
(`debug-alloc: DOUBLE FREE ... origin=Vec`). MIR showed why: inside a
function the global read lowered as `_1 = copy _2` — a byte copy of a
non-Copy value with no blanking — so the reassignment's `drop(_2)` and the
returned value freed one buffer (§2.3: transport never produces a second
live value). In `main` the same spelling lowered as `move` plus
`_1 = const zst`, a blanked global that every other function still sees as
holding a value. And the checker's MOVED mark on a global is not
per-function: after `fn f(): let s = g`, every later body reported
"use of moved value" for `g`.

**Alternatives.** (a) Per-global drop flags: runtime state for a property
that cannot be decided statically across functions, and it would legalize
a global that is empty from some other function's point of view. (b) Blank
on move: the same empty-global hole, silently. (c) Treat `let x = g` as a
D27 alias of the global place: consistent with `let v = g.field`, but a
spec change (the ident form moves everywhere else) and it does nothing for
the argument, return and `move self` spellings. (d) Reject: the only
option under which "a global always holds a value" is true in every
function, and the fix-it is the one the programmer means (`.clone()`).

**§9.1c (blessed).** "A global always holds
a value: it is observed, mutated in place, or reassigned, never moved out
of; an owned copy is spelled `.clone()`. A `const` is a value, not a
place — each use materializes it."

**Reopens if** globals gain a statically tracked vacancy (a `global var`
of `Option[T]` already expresses "sometimes empty" without one).

---
