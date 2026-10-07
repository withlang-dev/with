# D21 — Unit-returning mutator pipelines thread the receiver place; `mut fn` cannot duplicate receiver ownership

**Laws:** 5, 6 (docs/mission.md).

**Date:** 2026-07-22
**Status:** Accepted — BDFL ruling; implementation is NON-COMPLIANT pending the
compiler/stdlib follow-up.
**Deciders:** Eric (BDFL)

**Decision.** A pipeline stage that resolves to a `mut fn` whose resolved
concrete return type is `Unit` performs the ordinary mutating call and continues
with the same receiver place. The test is static after return inference,
overload resolution, and generic substitution; it is not restricted to a
literal `-> Unit` annotation. A `mut fn` stage with any other return type
continues with its returned value. `Never` diverges under the ordinary rules and
has no continuation.

A named receiver remains its original place. An rvalue receiver is materialized
as a statement temporary. If that place remains the pipeline's final value, an
ordinary value context may move it out; if a non-Unit stage switches the
pipeline to another value, the receiver temporary is dropped at statement end.
All argument evaluation, exclusivity, view-liveness, aliasing, and mutation
ordering are exactly those of the corresponding ordinary calls — pipelines do
not mint a second place-mutation regime.

The receiver contract and the return contract remain distinct. A `mut fn` may
return useful values, including a Copy result, a tracked view, a fresh owned
value, or ownership moved from a projection whose source is reset under D17.
It may not return the non-Copy receiver itself, or duplicate ownership of
storage the receiver still owns, because the caller retains the receiver place.
Receiver-returning fluency is a consuming contract and is spelled `move fn`.

**Supersedes.** This reverses the receiver-returning `Vec.push` design shipped
in `b99fd86c` and recorded by
`docs/feature_plans/stdlib-fluent-builder-blocker.md` and the historical
`docs/completed/build-plan.md`. It also supersedes the receiver-return/move-out/
reinitialize field-chain model in `docs/completed/drop-move-ownership.md` for
Unit mutators. `Vec.push`, `Vec.clear`, and `Vec.set_i32` are Unit-returning
in-place mutators; their pipeline fluency comes from place-threading, never from
an owned copy of the receiver.

D16 and D17 remain the ordinary ownership laws beneath this ruling: D16 governs
explicitly moved rvalue roots and statement-temporary destruction; D17 permits
a sound projection transfer only because reset-on-move removes that ownership
from the receiver. Neither permits the duplicated whole-receiver ownership this
ruling rejects.

**Why this is the With answer.** Vale's `List.add` has two overloads: a borrowed
receiver returning void and an owned receiver returning the List; its compiler
borrows a named local receiver and preserves ownership for a non-local
expression. That proves the ownership split is coherent, but Vale's fluent form
is a dot chain, not With's pipeline. Rust `Vec::push`, Swift `Array.append`, and
Zig `ArrayList.append` are Unit/void in-place mutators; Go's `append` returns a
new slice header and requires assignment. With already knows both facts needed
to remove the ceremony safely — the receiver is a place and Unit carries no
information — so the compiler threads the place only in that information-free
case.

This follows the mission literally: compiler complexity replaces programmer
ceremony without weakening ownership. It also preserves meaningful results:
`v |> try_push(x)` carries the returned bool, and `v |> pop() |> unwrap()`
carries the returned Option while leaving `v` alive and mutated.

**Alternatives rejected.**

- *Keep one universal pipeline rewrite and add Vale-style `mut`/`move`
  overloads.* This preserves `x |> f(a) == f(x, a)` as a single law and keeps
  value-category intelligence local to overload selection. Rejected because a
  natural chain works for a temporary but breaks on a named place after its
  first Unit result, forcing statements or `(move v)` where the compiler already
  knows how to preserve the place.
- *Thread the place after every `mut fn`, regardless of return type.* Rejected by
  `let succeeded = v |> try_push(x)`: it would bind/move `v` and silently discard
  the bool the API deliberately returned. With already has receiver-only builder
  semantics in `with ... as mut`; pipelines continue with meaningful results.
- *Let a `mut fn` return its non-Copy receiver.* Unsound: the caller retains the
  receiver place while the return creates a second owner of the same storage.
  Resetting or zeroing one side merely moves or destroys the caller's value and
  does not make the declared `mut` contract truthful.

**Required pins.** Named-place Unit chains; rvalue-rooted Unit chains; ordinary
assignment-move capture; generic resolved-Unit vs resolved-non-Unit stages; a
named mixed chain (`push` then `pop`) that returns the element while leaving the
receiver live and mutated; the rvalue mixed chain whose returned Option arrives
and whose hidden Vec drops exactly once at statement end; `Never` divergence;
ordinary argument-independence acceptance/rejection; and a compile error for a
`mut fn` that duplicates its non-Copy receiver into an owned return. Moved-out
projection, Copy, view, and fresh-owned returns remain accepted controls.

**What would reopen this.** A pipeline model that can carry both receiver place
and method result without ambiguity or new ceremony, or an ownership model that
can truthfully return a receiver while the caller retains its place without
creating two owners. Implementation inconvenience does not reopen it.

---
