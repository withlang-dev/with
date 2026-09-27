# D22 — Keyed-map lookup returns a uniform view; Copy materializes only under owned demand

**Date:** 2026-07-23
**Status:** Accepted — BDFL ruling. A new decision has been made, but
implementation is still in progress; the compiler/stdlib are NON-COMPLIANT
until the D22 requirements and pins pass.
**Deciders:** Eric (BDFL)

**Authority:** `docs/d22-Eric-Ruling.md` is the canonical and complete D22
ruling. This entry is only a compact index and rationale summary; any omission
or conflict here is false and must be repaired in favor of Eric's ruling.

**Decision.** `HashMap[K, V].get` and `BTreeMap[K, V].get` return
`Option[&V]` for every `V`. Their return shape never depends on whether `V` is
`Copy`. Lookup observes map-owned storage; `remove` transfers ownership and
returns `Option[V]`. The view from `get` originates only in the receiver, not
the transient key.

A `&T` remains a reference during inference, unannotated binding, inferred
return, pattern projection, and closure capture. When `T: Copy`, it may satisfy
an independently established owned demand: an explicit/declared target, a
resolved by-value argument/component/receiver, a resolved operator contract,
or an owned branch-join result. The compiler copies the pointee at that demand
boundary and then applies ordinary value coercions. Raw pointers do not
participate, and this is not a receiver-ABI change.

Patterns are structural projections, not owned-demand positions. `Some(v)` on
`Option[&V]` binds `v: &V` in every instantiation; nested projection through a
reference produces reference subviews. `unwrap`, `expect`, and `?` likewise
preserve the exact payload type. `??`, `unwrap_or`, and `unwrap_or_else` use the
general join rule: all-reference paths preserve the reference and union their
origins; an enclosing expected owned type or any independently-owned reaching
expression anchors an owned result and compatible `&Copy` paths materialize.
The rule is independent of arm order. Removing the last owned anchor may
change an inferred result back to a reference; an explicit target type pins
the intended result.

Origins follow semantic values through `Option`, `Result`, tuples, patterns,
branches, and compiler-generated elimination. Wrapper spelling never erases a
view origin. A contextual Copy read, explicit clone, or consuming ownership
transfer ends the origin only for the independent owned result. D22 also
standardizes `Option[&T].copied() -> Option[T]` for `T: Copy` and
`Option[&T].cloned() -> Option[T]` for `T: Clone` as explicit ownership
boundaries.

**Diagnostic contract.** If a later error depends on a join's owned anchor,
the diagnostic identifies that anchor and the relevant materialized arms. A
view-invalidating mutation explains that the binding views its collection and
offers an owned type annotation for `Copy` pointees. A non-`Copy` `??` mismatch
explains the borrowed-success/owned-default split and suggests `.cloned()`, a
borrowed default, or `remove` only when each remedy is actually applicable.

**Why this is the With answer.** Rust and Vale give keyed lookup one borrowed
shape. Zig keeps two uniformly typed operations (`get` by value and `getPtr`
by address); Go and Swift return values because their value/GC models make
that safe. None makes `get` itself change shape by generic instantiation. With
keeps that uniform contract and spends compiler complexity at the place where
the programmer's intent becomes knowable: an owned-value demand. Python/Mojo
users get `counts.get(k) ?? 0` and ordinary arithmetic without sigils; Rust
users get a stateable borrowing API; C/C++ users retain native, explicit
ownership. Reference identity and lifetime remain real information until an
owned context deliberately spends them.

**Alternatives rejected.** Copy-or-view lookup was rejected because a method's
public return shape would vary by instantiation and forwarding generic APIs
could not state one contract. Uniform borrow with only explicit dereference or
`.copied()` was safe and pure but imposed Rust-shaped ceremony on the common
Copy case. Eager materialization at `unwrap` or pattern binding merely moved
the conditional return shape to every elimination spelling and made generic
patterns unstable. Ambient `&Copy -> Copy` inference was rejected because an
unannotated binding would silently discard identity and origin information.

**Supersedes.** This reverses §3.8's former call-site-only boundary for Copy
pointee reads and retires
`test/compile_errors/err_ref_copy_no_return_coercion.w` as a language
requirement. The fixture remains temporarily as a marked NON-COMPLIANCE pin
until implementation converts it to a must-compile test. D22 also supersedes
every active statement that `HashMap.get` or `BTreeMap.get` returns
`Option[V]`. No decision-log rationale for the old call-site-only boundary was
found; this record does not invent one.

`Vec`, string, array, and slice indexing/lookup signatures are not
restandardized here. D22's general expression, pattern, join, and origin rules
apply to their existing signatures; changing those signatures is a separate
D23-candidate ruling. `SlotMap.get` already has the required uniform
`Option[&T]` contract.

**Required pins.** Origin survives `unwrap`; origin survives pattern/`if let`;
origin survives `?`; two borrowed `??` paths union origins; an annotated Copy
snapshot remains usable after map mutation; a removed owned value remains
usable after mutation; and mutation after the final view use remains accepted
as the NLL precision control. A mixed five-arm match pins one owned anchor,
four materialized view arms, arm-order independence, and an explicit result
annotation that stabilizes later edits. Non-`Copy` `??` diagnostics pin every
applicable remedy and never recommend an unavailable clone or invalid borrow.

**Implementation sequencing.** Doctrine lands first. The excluded
`test/non_compliant/d22/` matrix versions the acceptance criteria without
weakening the green battery. Transparent-carrier origin propagation lands
before contextual Copy reads and join materialization; implementation design
is a separate follow-up and must preserve the one ABI descriptor rule.

**What would reopen this.** Evidence that contextual Copy materialization
cannot be defined as one expected-type operation across calls, returns,
operators, and joins without changing inference or ABI unpredictably; or a
uniform alternative that preserves map API contracts, Copy ergonomics, view
identity, and generic forwarding with less language machinery. Implementation
inconvenience alone does not reopen it.

---
