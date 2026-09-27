# Share-Place: The Minimal Design (Historical — Superseded)

> **SUPERSEDED (2026-07-23).** Free-function SHARE-PLACE is not the current
> language design. Specification §3.8 is authoritative: `&T` borrows and plain
> `T` consumes. This file is retained only as design archaeology. Receiver-mode
> by-place mutation remains current and is governed by D12/D21. Every
> free-parameter SHARE-PLACE design or implementation directive below is void.
> For D22,
> `docs/d22-Eric-Ruling.md` is canonical and every conflict here is false.

A from-scratch sketch of the *smallest* thing that is share-place, what each
reference language already proves works, and what pieces of With must move to fit
it. Companion to `mutability.md` (the spec) and `share_place_restoration_plan.md`
(the site-by-site restoration).

## What the references already prove (each does a PIECE)

No language does the whole thing (mutable, inferred borrow-vs-own for every
param, with destructors). But each ships a load-bearing piece in production:

- **Zig — the ABI.** langref §"Pass-by-value Parameters": for structs/unions/
  arrays "Zig may choose to copy and pass by value, or pass by reference,
  whichever ... will be faster. This is made possible, in part, by the fact that
  parameters are immutable." That IS the share-place ABI: pass a **pointer to the
  caller's place** when safe. Zig's safety precondition is *immutable params*.
  With's one addition: params may be mutated, and the mutation is *intentionally*
  caller-visible — so With needs an analysis (below) to know when a param is
  borrowed vs owned. Same ABI mechanism; With earns observable mutation.
- **Go — the inference.** `cmd/compile/internal/escape` is a dedicated pass (not
  woven into typing) with a graph **fixpoint solver** (`solve.go`) producing a
  compact **per-parameter summary** (`leaks [8]uint8`, `leaks.go`) recording flow
  from a param to the heap (`leakHeap`), to the callee (`leakCallee`), to a result
  (`leakResult`), or a mutation (`leakMutator`). Encoded into the function's param
  tag for cross-package use. This is *exactly* With's effect summary
  (escape_value = leakHeap, escape_view = leakResult, consume = leakCallee,
  write = leakMutator) — and it validates the shape: **a standalone analysis, a
  call-graph fixpoint, a per-param summary, exported in the interface.** (With's
  P0 fixpoint is this.)
- **Rust — the algorithm.** `rustc_hir_typeck/src/upvar.rs`
  (`InferBorrowKindVisitor`) infers a *closure's* capture kind (by-ref / by-mut-
  ref / by-move) and Fn/FnMut/FnOnce trait by **visiting the body and picking the
  weakest mode the usage supports**. That is share-place's rule (read→borrow,
  write→mut-borrow, consume→own) — Rust already ships it, but only for closures.
  **With generalizes Rust's closure-capture inference to every parameter.**
  (mutability.md already says closures follow the same model — consistent.)
- **Vale — the ownership model.** Single ownership, consuming destructors (Higher
  RAII), *no* borrow checker (generational references for safety), with region
  borrowing for zero-cost refs. This is With's ownership/drop substrate, and
  region-borrow ≈ "borrow the caller's place for the call's duration."

**Synthesis:** share-place = Zig's ABI + Go's escape analysis + Rust's
capture-inference algorithm + Vale's ownership. It is a *composition of four
proven ideas*, not a novel gamble. No one language combined them; With does.

## The minimal core (one enum, one analysis, four one-line consumers)

Every parameter has a **PassMode**, and that is the whole abstraction:

```
PassMode(param) =
    Copy    if type is Copy
    Own     if effect ∩ {consume, escape_value} ≠ ∅       // Go leakHeap/leakCallee
    Borrow  otherwise (effect ⊆ {read, write})            // Zig by-ref
```

One **analysis** computes it: a call-graph fixpoint that marks a param `Own` when
it escapes or is consumed, transitively (passing a param to an `Own` param makes
it `Own`). That is Go's escape analysis, minimized to one bit (plus a read/write
bit for borrow-check strength). Everything richer in mutability.md — escape_view
origin sets, `@[effect]` pins, the five-way effect lattice — is **refinement
layered on top**, not part of the minimum.

Then **four consumers, each a one-liner keyed on PassMode**:

1. **Callee ABI.** `Borrow` → the param is a plain `ptr` (to the caller's place).
   `Own`/`Copy` → by value.
2. **Call marshalling.** `Borrow` → push the **address** of the caller's place
   (materialize a caller-scope temp for an rvalue). `Own` → push the value;
   require `move`/`copy` for a *named binding* (rvalue passes directly). `Copy` →
   push a copy.
3. **Drop placement.** The callee drops a param **iff** `Own`. `Borrow` params are
   the caller's; the destructor runs in the caller's scope.
4. **Borrow check.** A `Borrow` call takes a shared borrow (read) or exclusive
   borrow (write) on the arg for the call's duration.

That is the entire language feature. One enum, one fixpoint, four trivial
consumers. It is *smaller* than what With has today.

## Overlaid on With — what already fits, what must move

With is not missing pieces; it **over-built the periphery and under-wired the
core**, then let the core drift to "always Own."

Already fits (keep):
- The effect lattice + inference + `@[effect]` pins + escape_view origins — this
  is the refinement layer, richer than the minimum. `sig_param_effects` is the
  `leaks` summary.
- **P0 (done):** the call-graph fixpoint = Go's `solve.go`. The analysis exists.
- `value_ref_abi` → plain-`ptr` ABI (Codegen.w:4094) = Zig's by-ref. The Borrow
  ABI mechanism exists; receivers already use it (share-place already works for
  `self`).
- `is_copy` aggregate-opt-in, the `&T` niche — already correct.

Must move (the real work), smallest to largest:

1. **Derive PassMode once, post-fixpoint, into the sig.** Reuse
   `value_ref_abi` as the `Borrow` bit: after the P0 fixpoint, set it for every
   non-Copy, by-value param whose effect excludes consume/escape_value. Replaces
   the structural, decl-time, owner-type-only computation with one effect-driven
   pass. *Small.*
2. **Collapse drop placement + call-site consume onto PassMode.** MirLower's two
   `schedule_drop` sites and SemaCheck's call-site consume stop keying on
   `is_copy`/"always move" and key on `Own`. *Small.*
3. **THE BIG MOVE — unify argument marshalling behind one PassMode routine.**
   Today the "push address vs value" decision is **duplicated per call-lowering
   path** (free / method / generic / multi-index …), each doing ad-hoc
   `is_ref_param(fn_sym, 0)` receiver-address handling; there is no single choke
   point. The pure vision needs ONE routine — `push_arg(callee_sig, pi,
   operand)` → address / value / copy per PassMode + rvalue-temp materialization —
   that every call path routes through. This is the structural refactor share-
   place actually demands, and it is where With fights the vision. It is also the
   only genuinely new mechanism (rvalue-temp-for-Borrow), and small once
   centralized. *Large / the crux.*
4. **Delete the move-by-default residue.** Unconditional move-marking, callee-
   drop-every-non-Copy, and the two inverted lints ("by-value here, so the callee
   owns it" / "consider `&T` so callers keep their binding") are the negative
   space the pure model fills. Remove, don't gate (D5).

## The one-sentence version

Share-place is Zig's by-ref ABI + Go's escape-analysis fixpoint + Rust's
weakest-capture inference + Vale's single-ownership, unified behind a single
per-parameter `PassMode`; With already has the analysis (P0) and the ABI
mechanism (`value_ref_abi`) — the work is to **route every call's arguments
through one PassMode-driven marshaller** and delete the move-by-default residue,
after which callee-ABI, drop, and call-site rules are one-liners.
