# D106 — Law 2 has an order: a demand binds the signature's unknowns first, conversions bind nothing, and an expression's own operands bind before the outer demand

**Date:** 2026-10-06. **Status:** Eric's ruling on the law-2 tension the
Laws pass surfaced (2026-10-06); mission.md law 2 and §4.9a carry the
words. **Pins:** `test/behavior/behav_law2_demand_order.w`,
`test/compile_errors/err_d103_no_inference.w`.

**Tension.** Law 2 said "demand never solves a type variable", while the
generic result parameter from the demand (PR #2212: `let x: Option[i32] =
make()` binds `T`) solves one, and D103 says the value→Option conversion
"never participates in inference". A proposed fix — "a demand may bind an
unknown the signature leaves open and never rewrites an expression whose
type is already known" — would have forbidden D103 itself, whose
conversion rewrites exactly such an expression (`3: i32` → `Some(3)`).

**Decision.** The distinction is ordering, in two phases, not two kinds of
demand: a demand first binds the unknowns the demanded expression's own
signature leaves open (#2212); then, with both sides known, conversions
apply at the demand and bind nothing (D103). `first(3)` against
`Option[T]` fails phase one (no match without a conversion) and never
reaches phase two. Stating the order decides a case the laws did not:
`let x: Option[i32] = ident(3)` with `fn ident[T](t: T) -> T` could be
`ident(Some(3))` (result demand binds first) or `Some(ident(3))`
(operand binds first). Ruled inner-first: an expression's own operands
bind before the outer demand fills what remains. Inference stays local,
"once, at the demand" is literally the outermost point, and a demand never
silently changes a generic's instantiation.

**Compiler.** Already compliant (measured 2026-10-06 on main 0ede1d0de:
`ident` instantiates at `i32`, the `Some` aggregate is built in the
caller); the fixture pins it because a determinism audit trips here first.

**Reopen if** a demand is ever needed to pick a generic's instantiation
(none known); that would be a new law-2 phase, not a reordering.
