# D87 — An implicit fill observes the binding and never consumes it; `std.context` APIs take `implicit &Context`

**Laws:** 5 (docs/mission.md).

**Date:** 2026-10-03. **Status:** BDFL ruling (Eric: "blessed. approved."
on the words and on the arena fix). Spec v7.19: with-scoped-access.md
§7.3a. Issue #2049. **The compiler is NON-COMPLIANT**: an implicit fill
of a consuming plain-`T` parameter copies the binding and is never
move-checked, so two fills free it twice (debug allocator: DOUBLE FREE);
`lib/std/context.w`'s arena cannot allocate through `&Context`.

**Context.** #2049 found the double free: `with c(Ctx{..})` with two calls
to `fn compute(x: i32, ctx: implicit Ctx)`. §7.3a told library authors to
accept a plain `implicit Context`, and `Context` is not Copy (its temp
arena holds a `Vec`).

**Decision.** An implicit fill observes the binding and never consumes it.
`implicit &T` borrows it; `implicit T` is filled only when `T` is Copy; a
non-Copy `implicit T` is not filled implicitly, and the caller passes the
argument explicitly, which moves it (§3.8). `std.context` APIs take
`implicit &Context`. The temp arena becomes a shared handle whose
allocation takes `&self`, so `implicit &Context` can allocate (Jai's
context holds `temporary_storage` as a pointer for the same reason); the
handle's internals are library-maintainer `unsafe`.

**Alternatives.** D5 move reading (a plain `implicit T` fill consumes):
rejected — a consumption with no token at the call site; the later
"use of moved value" points at a call that never names the binding.
Implicit clone per fill: rejected (no implicit copy unless O(1)).
Refusing every non-Copy plain `implicit T`: rejected — the explicit
argument remains the spelling for a function that truly consumes it.
A mutable implicit parameter: not taken; the storage-types ruling keeps
`implicit` with `inout`/`byref` an error.

**References.** Jai: one implicit `context` passed to every procedure,
read or pushed per scope, never consumed (The_Way_to_Jai ch. 25). Scala 3
`using` parameters are references; one given fills any number of calls.

**Reopens if.** A context needs mutation that a shared handle cannot
express safely.
