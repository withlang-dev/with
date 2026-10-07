# D77 — Matching on a borrowed trait object: `name: C` binds `&C`; sealed implementors are the domain

**Laws:** 5 (docs/mission.md).

**Date:** 2026-09-28 (design, option (a)); 2026-09-29 (wording: "blessed").
**Status:** BDFL ruling. Spec v7.10: §9.7 "Trait-object downcast patterns",
§11.3 by-value `dyn` refusal, grammar `TYPED_BIND_PAT`. Issues #1860, #1852.

**Decision.** In a match whose subject is `&dyn T`, the pattern `name: C`
tests the concrete type and binds `name: &C` observing the same object,
keeping the subject's view origin (D22: a reference stays a reference
through pattern projection). A `@[sealed]` trait's closed implementor set
is the exhaustiveness domain; an open trait needs a wildcard; a guarded arm
alone covers nothing. Mutation goes through the trait's `mut fn` methods —
the pattern grants no write access and With has no `&mut T`. Owned
by-value trait-object matching is not defined until the consuming-transfer
story (#724) is. A parameter cannot take a bare `dyn Trait` by value: `&dyn
Trait` borrows, `Box[dyn Trait]` transfers (#1852, landed immediately with
its tests rewritten onto `&dyn`).

**Why.** The former lowering copied the object into an owned `C` binding,
a second owner of one value (§2.3: transport is not duplication). The
subject already says the object is borrowed, so the programmer never
repeats `&` in the pattern; the concrete type is the one choice the
compiler cannot make, so it is spelled.

**Alternatives.** (b) bind an owned `C` by moving out of the box — needs
a by-value `dyn` subject and the #724 story; deferred, not rejected.
(c) a method (`as[C]()` returning `Option[&C]`, Rust's `downcast_ref`,
Vale's `as<Raza>()`) — adds a call where a pattern already has the arm
structure and loses sealed exhaustiveness.

**References.** Vale `downcastBorrowSuccessful.vale` (a downcast keeps the
borrow); Go's type switch (interface subject, each case binds the concrete
type; With binds a view); Rust `Any::downcast_ref` → `Option<&T>`.

**Reopen if** owned `dyn` values become matchable (#724), or `@[sealed]`
gains cross-bundle implementors.
