# With Language — Design Rationale

**Companion to:** `docs/with-specification.md`

This document explains *why* With makes certain design choices.
For the normative rules themselves, see the specification.

---

## Language Comparison

| | Rust | With |
|---|---|---|
| **Memory safety** | Compile-time | Compile-time |
| **Lifetime annotations** | Yes (`'a`) | None |
| **Stored references** | Yes | No (handles) |
| **Borrow checker** | Full | Simplified |
| **Async model** | State machines | Fibers |
| **Runtime** | Optional | Optional |
| **Generics** | Yes | Yes |
| **C interop** | Via FFI | Native |
| **Learning curve** | Steep | Gentle |
| **Coding feel** | Explicit | Expressive |

---

## Known Tradeoffs

Eliminating lifetime annotations has real costs. With handles them
pragmatically:

**No stored references.** References can't live in structs. Service
architectures use `Arc` for shared ownership, handles for entity
relationships. This is more verbose than Rust's `&'a T` but
eliminates lifetime annotations on every struct.

**Conservative borrow analysis.** When a function returns a reference
and takes multiple reference parameters, the compiler conservatively
assumes the return borrows from all inputs. For common patterns
(HashMap::get, split_at_mut, iterators), the **compiler has built-in
knowledge** of stdlib types and does the right thing. For user code,
returning references from multi-parameter functions may over-borrow.
Workaround: return an index/handle, or restructure.

**Generator yield restriction.** Generators cannot yield references
to their own locals. Use ephemeral iterator structs (§5.5) or the
callback/visitor pattern for zero-copy iteration.

**FFI stack switching.** Fibers calling C code pay ~10–50 ns for
stack switching. Use `@[ffi_stack]` to batch FFI-heavy functions.

These are the real costs. For the target domain — services, games,
infrastructure — they're the right trade.

---

## Why Fibers, Not State Machines

| | Rust async | With |
|---|---|---|
| **Mechanism** | State machine (stackless) | Fiber (stackful) |
| **Stack** | Captured in Future struct | Real stack per fiber |
| **Refs across await** | Requires Pin | Just work |
| **Colored functions** | Yes | No (Invariant 1) |
| **Runtime** | Pluggable executors | One blessed scheduler (Invariant 3) |
| **Send bounds** | Infect async return types | Not needed |
| **Trait support** | Requires boxing or GATs | Just works |
| **Cancellation** | Drop the Future | Cancel the Task |

The fiber model was chosen because it preserves the ownership model's
invariants without special-casing for async code. References on the
stack survive suspension. No lifetime gymnastics required.
