# D47 — Lending is not receiving: a `c_import`ed `const char *` parameter accepts a `str`; an application developer never writes `unsafe`

**Date:** 2026-09-20. **Status:** ruled (Eric: "there is no way this should
have to be declared unsafe. This flies in the face of the mission"; "no UAT
code should have `unsafe` in it … if 'normal' users are using unsafe - WE
forced them into a situation they shouldn't be in"). §16.3c sentence blessed
2026-09-20. Narrows #379 (a88df01a).

**Context.** 1e53f8aa (2026-06-11) modeled every `const char *` parameter of
a c_imported function as a string input; the raylib spiral on Eric's blog
dates from then. a88df01a (2026-06-17, #379) replaced that with a curated
libc overlay: outside the list, a string parameter made the function the raw
surface. That broke the spiral release UAT, which sat broken until
bd9683f0 (2026-09-07) rewrote the fixture to
`unsafe { InitWindow(900, 600, c"...".ptr) }` to go green, without Eric's
knowledge. By 2026-09-19 every release UAT fixture said `unsafe` (30 uses).

**Reasoning.** #379's rule is sound for the direction it was written for:
With never reads or frees C memory on a guess (`strlen` on an arbitrary
`char *`, ownership of a return). It was applied to the other direction,
where nothing is guessed: With hands C a valid NUL-terminated buffer it owns.
The header forces one meaning for a `str` argument to a `const char *`
parameter (mission: "forced … by a header"); c_import is the modeling step,
not raw C. The one hazard in lending is a callee that keeps the pointer,
which no spelling by the programmer resolves, so it is the compiler's: a
literal is static and cannot dangle; any other `str` goes through call-scoped
storage that stays readable, so a retaining callee reads stale text, never
freed memory. `retains:` remains the way to hand a keeping callee an owned
copy. A hand-written `extern fn` with raw pointers is still raw C.

**Alternatives weighed.** Assume non-retention (Swift's rule): a wrong guess
is a silent use-after-free. Per-library contract data: the per-package upkeep
Eric rejected for `with get` (D46). Inference from parameter names: unsound.
Proof from C source when `with get` built it: a later refinement.

**Process rules this produced** (CLAUDE.md): a UAT fixture, an example or
published code is a contract — a change that breaks one stops and goes to
Eric, and the program is never edited to pass; `with build
:user-programs-safe` fails on `unsafe` in those programs.

**Reopen if** a lent-string hazard appears that readable storage does not
cover.

---
