# D7 — Eliminate `self`: the receiver mode is a `fn` prefix keyword; `self` and its type are never written (Swift-style)

**Date:** 2026-07-07
**Status:** Accepted — BDFL ruling. Plan: `docs/eliminate-self.md`. Spec: §2.4, §9.5. **Deciders:** Eric (BDFL)

### The decision

A method's receiver is expressed by a keyword on the declaration, not by a
parameter. `self` is never declared and its type is never spelled:

- `fn m()` inside `impl`/`extend`/`type` — instance, **read borrow** (`self: &Self`)
- `mut fn m()` inside a type — instance, **by-place mutable borrow** (`mut self: Self`)
- `move fn m()` inside a type — instance, **consuming** (`move self: Self`)
- top-level `fn Type.name()` — **associated**, no receiver (no `static` keyword)

**Instance vs. associated is decided by *location*, not a keyword:** inside an
`impl`/`extend`/`type` the receiver is synthesised; at top level there is none
(a `mut`/`move` prefix at top level is an error). This is Rust/Zig/Go's
presence-of-receiver rule with `self` implicit. `self` remains an implicit
binding in instance-method bodies; the receiver's type is always the enclosing
type. Implemented as a **parser desugar** to the existing (verified-working)
receiver-param shapes, so sema/MIR/codegen are unchanged.

**Trait declarations are the carve-out (part of the same ruling):** a trait
body must express both instance contracts and associated contracts
(`Default.default`, `Try.from_break`), and location cannot discriminate inside
the block. So in a `trait` body only the unambiguous keyword forms synthesise
(`mut fn` / `move fn`); a plain `fn` keeps today's explicit spelling — with a
receiver parameter it is an instance contract, without one it is associated.
Trait authoring is library-maintainer tier, so the residual ceremony lands on
the right audience. The end state for `lib/std/traits.w` is therefore: keyword
forms for mut/move/destructor contracts (`move fn drop()` is the only Drop
receiver, §2.4), explicit `self: &Self` on read instance contracts, plain
no-receiver `fn` for associated contracts. Do not re-open this by flipping
trait plain-`fn` to implicit-instance; that makes associated contracts
unspellable.

### Context / why

The mission's first law — *"every unnecessary character is a compiler failure;
if With can infer it, the programmer should not have to spell it out"* — applies
directly: a receiver's type is **always** the owner type, so `: Self` is pure
ceremony, and the mode is one bit that belongs on the declaration, not smeared
across a `self` parameter. The prior form `fn m(mut self: Self)` forced the user
to write the value (`self`), its mode, and its (inferable) type.

This ruling also **dissolves** four open issues instead of patching them: #646
(unflagged `self: ConcreteType` escapes the mode check — no annotation to
escape), #645 part 2 (`mut` discarded on a param — `mut` now only prefixes
`fn`), #644 (mut-self on a primitive owner — mode is uniform, type inferred),
and the bare-`mut self` codegen failure (bare receiver forms cease to exist at
the surface).

### Alternatives weighed

- **Keep `mut self: Self` (status quo).** Rejected: maximal ceremony; the spec
  even called it "canonical," contradicting the mission's first law. The clause
  is superseded here.
- **Bare `mut self` (drop only `: Self`, Rust shorthand).** Rejected as the
  end-state: still writes `self`. Eric's ruling: if `self` can be avoided, avoid
  it. (Bare `mut self` is nonetheless the internal desugar target's cousin — the
  desugar emits `mut self: Self` with a literal `Self` node.)
- **Swift `mutating`/`consuming` spelling.** Rejected the *words*: we reuse
  existing `mut`/`move` keywords (fewer characters, Rust-adjacent, no new
  reserved words).

### Reference consensus

Swift is the model: `SelfAccessKind` (`include/swift/AST/Decl.h:262` —
`NonMutating`/`Mutating`/`Consuming`/`Borrowing`) is a **decl** property and
`self` is a compiler-synthesised `getImplicitSelfDecl()`. `mutating ⇒ inout
self` (OwnershipManifesto) is verbatim With's by-place receiver mode (D12). Swift threads a
persisted `SelfAccessKind`; we take a cheaper route (parser desugar to shapes
sema already handles). Rust's `&self`/`&mut self`/`self` shorthand and Swift's
implicit `self` both confirm "no receiver type annotation" as the ergonomic
norm; Go/Zig write the receiver type and are explicitly the more-ceremony pole
we reject.

### What would reopen it

Evidence that implicit `self` cannot express a needed method shape (verified by
running, not reasoning), or that the location discriminator (inside a type vs.
top level) creates an ambiguity the desugar cannot resolve. Supersedes the §2.4
"canonical receiver is `move self: Self`" wording (now `move fn drop()`).

---
