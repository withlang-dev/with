# D167 — A scalar on the left is the scalar's operator, written as an extension method (Scala is the north star)

**Laws:** 1 (docs/mission.md: when two meanings remain, the programmer
spells the choice; the call site spells nothing).

**Date:** 2026-10-28. **Status:** ruled (Eric, on the review of #2765:
"we should make it possible — let's use Scala as a north star for
operator overloading"). **Issue:** #2611. **Amends:** D166, through its
own reopen clause.

**Decision.** An operator is a method of its left operand (D166), and
that holds when the left operand is a primitive. `2.0 * v` is `f64`'s
`mul`, written where Scala writes it: an extension of the scalar's type,
`extend f64: fn mul(self: &Self, v: &V) -> V` (§9.5). The extension's
`Self` is the left operand and its parameter the right, so it states its
order the way every operator method does, and the call site spells
nothing. A primitive's operator methods answer only beside a nominal
operand: primitive with primitive stays builtin arithmetic, so std's
`impl Eq for i32` never turns `1 == 2` into a call.

**Context.** D166 removed the reversed dispatch that ran `V.sub(f64)`
for `2.0 - a`, and said the author who wants the other order writes
that implementation. Review found no such implementation could be
written: `impl Sub[V, V] for f64` is refused by the orphan rule (E1101,
§11.4: the trait or the type must be local), and an `extend f64:`
method was never consulted because Sema's operator lookup took its
owner from `get_type_name`, which names only nominal types. D166's
reopen clause named exactly this case.

**What the others do.** Scala, the ruling's north star: operators are
methods (`a * b` is `a.*(b)`); `2.0 * v` needs a method on `Double`,
supplied by an extension (`extension (d: Double) def *(v: V): V`),
scoped by import. Rust: `impl Mul<V> for f64` is legal because a local
type appears in the trait's parameters. Swift and C++: a free operator
function with both parameter types in order. Python: a separate
reflected method (`__rmul__`).

**Alternatives.** (a) Relax the orphan rule so `impl Mul[V, V] for f64`
is legal (Rust's covered-type rule): a coherence change with its own
cross-package questions, and a second spelling of what `extend`
already says. Not needed for the ruling; open if a generic bound must
name the reversed order. (b) A reflected method name (`rmul`): a second
fixed name to learn, and the extension already states the order in its
`Self`.

**Diagnostic.** When only the right operand's type has the operator,
the error says which order that method serves and names the
extension: "`V.sub` serves `V - f64` only — write this order as `sub`
on f64 (`extend f64:` when it is not your type, §9.5)".

**Reopens if** a generic bound must require the reversed order
(`T: Mul[V, V]` with `T = f64`), which an extension method does not
satisfy; that is alternative (a).
