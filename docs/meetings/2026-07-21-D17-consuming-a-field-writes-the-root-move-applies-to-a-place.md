# D17 — Consuming a field writes the root; `move` applies to a place

**Date:** 2026-07-21
**Status:** Accepted for projection transfers. D21 supersedes any
receiver-returning extrapolation from this rule.
**Deciders:** Eric (BDFL)

**Decision.** Ownership-forcing effects (consume/escape_value) do not cross
a NON-COPY projection: a callee that consumes a FIELD of a place blanks the
field (reset-on-move, §2.5.1) and leaves the root's place valid-but-changed
— a WRITE on the root, never a consume of it. A `mut fn` receiver therefore
suffices for methods that hand a field to a consuming callee; the
`move fn` escalation cascade (#691's 57 blocked methods, the promotion
`audit_receiver_projection_origins` already branded incorrect) is gone.
Alongside it, `move` applies to a place: `f(move self.r)` is the explicit
spelling; the field is blanked through whatever pointer reaches the base
(#697 machinery), so the caller's later drop skips it. POD-field moves are
plain copies. Under §3.8 a plain-`T` parameter consumes without an extra
call-site `move`; explicit `move self.r` remains a legal intent spelling.
Section 2.4's partial-move ban for Drop-impl owners is unchanged.

**D21 boundary.** "A field transfer writes the root" does not mean "a mutable
borrow may return an owned copy of the root." A transferred non-Copy projection
remains valid only because reset-on-move blanks that projection. D21 supersedes
any broader reading that would let a `mut fn` return the whole non-Copy receiver
or storage whose ownership the receiver retains; the sound projection-transfer
rule above remains in force for `pop`, `remove`, `take`, and equivalent APIs.

**The Copy-projection distinction (load-bearing).** A COPY-typed projection
(raw pointer, handle) keeps the old promotion: escaping it captures the
root's CONTENT by aliasing — nothing is blanked, so demoting to write would
be unsound for lifetime reasoning. std/thread.w's `@[effect(worker:
escape_value)]` pin on spawn_os caught exactly this during implementation
(the transmuted fn value escapes via a Copy fn_ptr field) — the effect-pin
feature enforcing its contract as designed.

**Alternatives weighed.** Keeping the promotion forces `move fn` on every
method that consumes any field, transitively — Rust-shaped virality that
made the compiler's own driver API unusable under the #691 flip. Weakening
without the Copy guard breaks aliasing-escape contracts (the pin caught
it). Threading `&mut`-style out-params instead is forbidden by §1.4/§3.3.

**Enforced by:** the m-probe matrix in the D17 commit, `--dump-abi`
verdicts (field-consuming `mut fn` receiver: eff=[write], by-place), drop-audit
field_take cells, and the #697/#698 debug-alloc fixtures. Would reopen on:
per-field effect summaries (which could carry field-precise consume without
promotion), or a change to reset-on-move that makes field blanks
observable.

---
