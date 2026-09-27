# D18 — Leak-freedom is a language invariant, not an optimization target

**Date:** 2026-07-22
**Status:** Accepted (mission-level ruling; mission.md amended).
**Deciders:** Eric (BDFL)

**Decision.** Making a memory leak must take deliberate, visible effort.
Every allocation is owned from the moment it is made — by the handle that
holds it, not by virtue of what it contains — and its owner's scope releases
it, compiler-proven. This supersedes the *provisional* status of A5/#608
("POD-element buffers leak by design"): that state was always scheduled to
end with #691, but as an optimization/scheduling matter; it is now a
mission violation with the flip as its first (not final) installment.

**The conceptual root cause (recorded so it cannot recur).** The 2026-07-22
memory campaign (issues #701–#703) traced every observed leak class — POD
Vec/str buffers, `++` rebuild-and-abandon chains, extern-returned strings,
per-call interpreter frames, ~890 concurrent accumulation ladders in the
build runner — to one chain of design errors:

1. *Reclamation was coupled to the wrong predicate.* One flag
   (`type_needs_drop`) answered two orthogonal questions: "does dropping
   this have user-observable effects?" and "does this value own heap?"
   Ownership was derived from a value's CONTENTS (POD elements ⇒ no drop)
   instead of from the HANDLE (it allocated; it owns). A `Vec[i32]` owns a
   buffer no matter how trivial its elements are.
2. *The obligation had inverted polarity.* Sound RAII makes "every
   allocation has an owner charged with freeing it" the default and makes
   opting out explicit. With made obligation the exception (Drop impls)
   and leak the default for everything else. Dead values from
   reassignment (`s = s ++ x`) had no scheduled release at all.
3. *Allocation paths existed outside the model.* Extern fns returning
   heap values (`with_fs_read_file -> str`) recorded no ownership fact;
   nobody was ever charged with the free. The runtime's own primitives
   must live under the same discipline (vec_grow already frees its
   superseded buffer — the discipline is achievable at every layer).
4. *Nothing forced the provisional state to end.* Leaking is memory-safe,
   so no gate tripped: the allocator was invisible to platform tools, the
   debug ledger truncated at scale, and there was no leak gate in the
   battery. A "temporary" decision with no forcing function is permanent.
5. *The mission bar was borrowed, not derived.* "Exactly as safe as Rust"
   imported Rust's frame — and Rust defines leaking as safe (mem::forget
   is safe). The invariant that IS this language's identity — the `with`
   scope releases what it holds — was never written down, so every
   downstream decision could trade it away without contradiction. Vale,
   our chosen ownership reference, gets this right: linear values MUST be
   consumed; there is no silent forget. We adopted Vale's machinery and
   initially skipped the one property that guarantees leak-freedom.

**Consequences.**
- #691 (the flip) is the first installment: heap-owning handles get
  scope-end release regardless of element POD-ness, and reassignment
  releases the superseded value.
- Extern signatures returning heap values must carry an ownership
  contract; an extern `-> str` means caller-owned with a scheduled drop,
  or must be spelled borrowed. No allocation path outside the model.
  [Superseded in part by D30/§16.3e: an extern `-> str` (or `str`/`&str`
  param) is now a hard error at ABI boundaries — With-managed types do
  not cross them at all. The leak-freedom reasoning stands; the ownership
  contract lives in the §16.3c binding model, never in a `str`-spelled
  boundary signature.]
- Deliberate leaking gets a loud spelling (explicit forget/arena types
  with named scopes), never a silent default. Long-lived memory is owned
  by a named scope (`with arena:` …), which is the language's own idiom.
- The battery gains a leak gate (debug-alloc leak count = 0) once the
  flip lands, and the #702 8GB runner budget is the flip's acceptance
  test. Observability keeps the invariant honest: WITH_ALLOC_SYSTEM=1
  (leaks/Instruments visibility) and #703 (scalable ledger with site
  attribution) exist so a leak is always one command away from a name.

**What would reopen this.** Nothing short of a mission change. Performance
work may batch or arena-ize releases (an arena is an owner with a named
scope) but may not reintroduce ownerless allocations.

---
