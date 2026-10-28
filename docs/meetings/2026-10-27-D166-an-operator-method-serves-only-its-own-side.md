# D166 — An operator method serves only its own side; only `==`/`!=` dispatch from the right (ruled)

**Laws:** 1 (docs/mission.md: when two meanings remain, the programmer
spells the choice).

**Date:** 2026-10-27. **Status:** ruled (Eric, on #2611). **Issue:**
#2611.

**Decision.** §11.7 operator resolution selects the implementation
whose `Self` is the left operand type. A method is never run with the
operands swapped: a plain `fn sub(self, rhs: f64)` on `V` defines
`V - f64` and says nothing about `f64 - V`. The author who wants the
other order writes that implementation on the left operand's type,
its order spelled in its `Self` and parameters (for a scalar on the
left, an `extend f64:` method — D167; this entry first named
`impl Mul[f64, V] for V`, which with `Mul[Rhs, Output]` is `V * f64`,
and the reversed `impl Mul[V, V] for f64` is orphan-refused); the
call site spells nothing. The one
exception is `==`/`!=`: `Eq` is symmetric by contract, so the right
operand type's `eq` answers when the left's provides none; two
distinct applicable `eq` implementations remain ambiguous. This is
stricter than the issue's prediction, which would also have swapped
the commutative-named operators: `*` is not commutative for
quaternions or matrix×vector, so no operator name licenses a swap.

**Context.** The old rule searched the full `(lhs, rhs)` pair and, on
a right-side hit, called the method with the operands exchanged while
claiming it "still represents the original source expression order" —
one method body cannot represent both orders. In the issue's repro,
`2.0 - a` ran `a.sub(2.0)` and printed `8` where the source order
says `-8`; `2.0 / a` printed `5` for `0.2`. No diagnostic. §11.7's
step 2 selected the plain method, and the next paragraph contradicted
what that selection means.

**What the others do.** From #2611's brief, verified there: Rust has
no reversed dispatch at all (`impl Sub<f64> for V` is the only
spelling of `V - f64`; `f64 - V` needs its own impl, orphan-blocked
for foreign `Self`). Python spells the reflected operation as a
separate method (`__rsub__`) whose body knows it is reflected.
C++ free operators state both parameter types in order. Nobody runs
one body in both orders.

**Alternatives.** (a) Swap only the commutative-named operators
(`+`, `*`, `==`, `!=`, `&`, `|`, `^`): refused — commutativity is a
property of a type's operation, not of the operator's name.
(b) A reflected-method spelling (`rsub`): a second fixed name to
learn; the trait form with the order in its parameters already
spells it. (c) Keep pair search but only for trait impls: the same
one-body-two-orders defect, one level up.

**Reopens if** a scalar-left operation on a user type (NumPy's
`2.0 * v`) needs a spelling the orphan rule forbids today; that is a
facade/orphan question, not a dispatch swap. *Reopened 2026-10-28 and
answered by D167: the scalar's operator is an extension method of the
scalar's type (`extend f64:`), Scala's spelling; no swap returns.*
