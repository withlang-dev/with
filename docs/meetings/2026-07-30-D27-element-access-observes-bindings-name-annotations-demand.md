# D27 — Element access observes; bindings name, annotations demand; JsonView is a Copy token

**Date:** 2026-07-30
**Status:** Ruled by Eric ("My will be done. Enshrine the doctrine. Purge any
dissent.") on the three-brief presentation of the parked questions from #715/
#730/#737 close-outs. Three rulings, one doctrine. Extends D22 beyond its §2.2
scope carve-out; partially supersedes D26 (see below). Implemented by the E1–E4
element-view campaign in `docs/d27-implementation-plan.md` (#740).

**Ruling 1 — Serialize/Deserialize signatures stand; JsonView opts into Copy.**
`fn serialize(self: &Self, out: JsonWriter) -> JsonWriter` and
`fn deserialize(input: JsonView) -> Self` are correct as declared. The sink is
genuinely consumed (thread-and-return, the same take-and-return idiom the
compiler itself uses); §15.1 bans the `&mut` sink every other reference uses,
and Go's `TextAppender` proves the threading shape sound. `input` stays owned
because `JsonView` is a view token — it opts into `Copy` (the D25 execution
pattern: `ReceiverMode`, `AstFileId`, `CancellationToken`). No trait-impl
churn. Docs spelling `out: &mut Writer` are dissent and were repaired. Audit
note: the #691 str flip must decide what `Copy` means for str-bearing structs;
JsonView joins Package/ProjectInfo on that list.

**Ruling 2 — Element access observes; `remove` transfers.** Normative text
landed beside the operator-trait table in the specification. `xs[i]` denotes
the element place (view on read, `IndexPlace` mutation on write — receiver
chains included); `xs.get(i)` returns `&T`, read-only, panicking on
out-of-range (absence is a bug for positional access; keyed maps keep
`Option[&V]` per D22 because absence is normal there); `remove(i) -> T` is
the transfer op. Copy elements materialize at owned demands; non-Copy owned
demands are rejected per D22 §13.6. Reference basis, verified in-tree: Vale
(`List.get -> &E`, `a[i]` is an AddressExpression, `UseP` loads a borrow,
move-out unexpressible) and Rust (`Index -> &Output`, E0508) — the only two
references with ownership + destructors both chose this; the shape-dependent
copy semantics we shipped instead produced the #715/#726 double-free class in
our own compiler ~45 times. Consequences the campaign must land: the interim
element gate (D26) is SUPERSEDED, not layered, when views land;
mutation-through-`get` chains (issue64 pins) are respelled to the `[i]` place
form — `get` chains observe only.

**Ruling 3 — A binding names what's there; an annotation demands what it
says.** Unannotated `let` binds the view unchanged (D22 rule 2); a typed
binding establishes an owned-value demand (D22 §6.2) — uniformly for field
projections and element access. Two implementation divergences to repair: the
#730 field gate fires at unannotated lets (over-broad — retained DELIBERATELY
as the safe conservative stand-in until origins-through-bindings can catch a
let-bound view consumed later; retire it with the ruling-2 campaign, not
before), and typed lets of elements were not gated (closed immediately —
annotation present means demand established).

**Supersession.** D26's "let is not a demand" holds for unannotated lets and
is now grounded in the ruling's own §6.2 text; its blanket exclusion of ALL
let sites from the element gate is superseded for typed bindings. D22 §2.2's
"does not restandardize Vec indexing or lookup" is superseded by ruling 2 —
that carve-out was scope discipline, not a semantic choice, and this ruling
fills it with the same doctrine D22 applied to keyed maps.

**Reopen if:** the #691 str-flip audit finds Copy-with-str untenable for view
tokens (ruling 1's mechanism, not its intent, would need a new shape); or the
element-view campaign finds receiver-chain place semantics for `[i]`
irreconcilable with view-liveness (§3.2) — surface to Eric, do not narrow the
doctrine unilaterally.

---
