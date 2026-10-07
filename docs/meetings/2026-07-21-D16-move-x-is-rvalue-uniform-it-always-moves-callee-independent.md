# D16 — `move x` is rvalue-uniform: it always moves, callee-independent

**Laws:** 6, 1 (docs/mission.md).

**Date:** 2026-07-21
**Status:** Accepted; D21 relies on this statement-temporary rule and does not
change explicit `move` semantics.
**Deciders:** Eric (BDFL)

**Decision.** `move x` at a call site always moves: the value is materialized
as a statement temporary and the source binding is reset immediately. An owned
(plain `T`) callee consumes the temporary through the call; a borrowing (`&T`)
callee borrows the temporary, which is destroyed at the end of the enclosing
statement (§2.4's temporary rule). `move x`'s caller-visible contract is
therefore callee-independent: after the statement, the binding is invalid and
the value is gone. Plain `T` already declares consumption and needs no
call-site acknowledgment; there is likewise no diagnostic for `move` into a
borrowing callee — it is meaningful early destruction, not noise.

**Context.** Before this ruling, `f(move x)` into a borrowing param
borrowed: the binding was statically invalidated but the value silently lived
until the caller's scope exit — a deferred-drop lie (a lock/fd moved into a
consumer for deterministic release stayed held). Found while grounding
#697/#691. The later D5 supersession made the borrowing mode explicit as `&T`;
the rvalue-uniform temporary rule remains the same.

**Alternatives weighed.**
- *Make it illegal* (`move` iff callee consumes; Rust/Vale make the construct
  inexpressible by typing): fails the no-ceremony diagnostic bar — after this
  ruling the construct has a well-defined, harmless meaning, and an error
  would force interaction about nothing (the same test that forbids must-use
  Result ceremony). Also an instantiation-dependent legality cliff for generic
  forwarders (effects are inferred per specialization), and callee body edits
  (consume → read) would break every `move` caller.
- *Warning*: post-ruling the operation does something (early destruction);
  warning on meaningful code is noise.
- *Status quo*: a silent RAII-timing surprise.

**References.** Swift is the only reference language with the exact construct
and chose the same semantics (OwnershipManifesto: `move(x)` yields an rvalue
and leaves the variable uninitialized; reinit heals a `var`; a temporary
passed to a borrowing parameter dies at end of the full expression). Rust's
`Operand::Move` passes call arguments "in-place — the callee might just get a
reference to this place" with the source set to uninit: uniform pointer ABI,
ownership follows the contract (D6 stays intact). The implementation may later
elide the temporary copy by aliasing the source storage; this entry fixes the
semantics, not the materialization strategy.

**Enforced by:** test/debug_alloc/da_move_into_shareplace_timing.w (legacy
fixture name; timing),
drop-audit cell move_into_borrow/bare (exactly-once). Would reopen on: a
borrowing ABI change that makes borrowing a doomed temporary unsound.

---
