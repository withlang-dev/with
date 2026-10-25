# D159 — The migrator emits a safe signature where a migrated function's body proves its contract; an unproved point keeps the function `unsafe fn` (a new migrator stage)

**Laws:** 4 (infer only what cannot create unsafety when wrong), 6 (the signature is the contract), 7 (fail loudly); tested against 3 and 10.

**Date:** 2026-10-24. **Status:** ruled by Eric on the brief posted after #2614; the implementation is NON-COMPLIANT until the stage lands. **Issues:** #2615 (the campaign). **Relates to:** D51 (modeled C), D112 (the migrator is a pinned input; no re-promotion on a migrator change), D121 (facades from evidence, proof from the library's source strongest).

## The ruling

> The migrator may emit a safe signature for a migrated function when the
> function's body proves the contract. The inferences permitted are those
> whose failure can at worst reject a valid program: (a) a pointer
> parameter the body mutates in place is `mut` receiver or `inout`; (b) a
> pointer argument the body stores into the engine's own storage is an
> ownership transfer; (c) a returned pointer derived from a parameter is a
> view with that parameter's origin. Where the body does not prove the
> contract, the function stays `pub unsafe fn`, with the unproved point
> named in the generated comment. Contracts are emitted into the corpus's
> generated source, never hand-edited. This is a migrator generation bump;
> under D112 promoted corpora are not re-promoted until their pin or a
> ruling moves them.

Two conditions Eric attached, which decide whether the inferences pass
D51's test:

> **Inference (b) is the one to be careful with.** "The body writes the
> pointer into the engine's storage" is necessary for ownership transfer
> but not sufficient: a function can store a pointer it does not own (a
> user-data pointer, an intrusive-list link in TommyDS, an aliasing view the
> caller still owns). If the migrator infers "owned" where C meant
> "borrowed and stored," the facade will drop something the caller still
> uses, which is exactly the unsafety D51 forbids inferring. So (b) should
> require *both* that the pointer is stored *and* that a destroyer in the
> same corpus frees it along that path. If only the first holds, emit
> "stored, ownership unknown" and keep the function `unsafe`. That keeps
> the inference on the safe side of D51's asymmetry.

> **The inferences are in-body facts, so they are only as stable as the
> body.** A pin bump that changes an engine's body can silently change its
> inferred contract and every facade built on it. The drift lane should
> diff the *inferred contracts* as well as the generated code, and a
> contract change should fail the gate until a human has looked. That's
> the same lesson as origin inference in §3.4: body-derived facts need a
> visible record.

> With those two, this is "proof from the library's source," which D121
> names as the strongest evidence, applied at the moment you have the most
> of it.

## Context

Every migrated corpus function is emitted `pub unsafe fn` over raw
pointers, so every STC facade writes `unsafe` around each engine call (18
to 39 sites per file after the shared slot API of #2614). D51 and D121
model `c_import`'d headers; nothing modeled a migrated function. The
reference projects split two ways: Zig's `translate-c` and Rust's bindgen
emit raw signatures forever; Swift's `ClangImporter` imports safe
signatures where the header declares its contract (nullability,
`cf_returns_retained`). The brief proposed the third way D121 already
names: proof from the library's source, at migration time, where the whole
body is in hand.

## What this changes (the campaign)

1. A migrator stage, after translation and before emission, that proves
   per function: (a) an in-place receiver/`inout` parameter, (b) a stored
   argument freed by a destroyer in the same corpus along the same path
   (both halves, or "stored, ownership unknown"), (c) a returned pointer's
   origin. The proof reads the C AST the migrator already has (libclang);
   a function it cannot prove keeps `pub unsafe fn` and a generated comment
   naming the unproved point.
2. The emitted signature carries the contract in With's own spellings
   (receiver modes, an owned parameter, `-> &T from <param>`), so a facade
   calls a proved function without `unsafe`.
3. The drift lane (`wo-drift`, `docs/spec/toolchain/wo_bundles.md`) diffs
   the inferred contracts as a separate artifact and a contract change is
   red until a human has looked.
4. A migrator generation bump (D112): new corpora and re-promotions get
   contracts; promoted corpora keep compiling raw until their pin or a
   ruling moves them. The STC facades drop their engine-call `unsafe` when
   the STC corpus is next re-promoted.

## What would reopen it

A proved contract turning out wrong on a real engine (the inference list
is then narrowed, never widened silently), or D51 §66's SQLite facade
landing a different contract vocabulary the stage must speak.
