# What's Missing

Features specified but not yet fully implemented. Items are grouped by
category. Parenthetical references point to the specification section.

---

## Type System

- [x] **Copy trait** (§2.3) — `impl Copy for T` recognized. Copy+Drop mutual exclusion enforced. Field-level Copy checking for concrete types works. Copy-size warning deferred.
- [x] **Distinct type methods** (§4.5) — `Meters(42)` constructor works, `.value` field access works, methods on distinct types work.
- [x] **Ephemeral type system** (§5) — Refs rejected in non-ephemeral struct fields. Ephemeral user types rejected in non-ephemeral struct fields. Refs allowed in ephemeral structs. Container-with-ref check enforced.
- [x] **Named enum variant fields** (§4.4) — `Circle(radius: f64)` declarations parse and positional construction works. Named construction (`Circle(radius: 5.0)`) depends on named arguments (see below).
- [x] **Implicit Ok wrapping** (§4.9) — Functions returning `Result[T, E]` can return `T` directly; compiler auto-wraps in `Ok(...)`. Sema validates type compatibility, MIR emits Ok variant construction.

## Control Flow

- [ ] **for-else** (§9.10) — `for x in iter: ... else: ...` (body when iterator is empty) not implemented.
- [ ] **Named/labeled breaks** (§9.4) — `@label` syntax on loops causes compiler hang.
- [ ] **in pattern in match arms** (§9.9) — `in expr` as a match arm pattern is not parsed. The `in`/`not in` operators work in expressions.
- [ ] **let-else** (§9.6) — `let Some(x) = expr else return` is not parsed.

## Pattern Matching

- [ ] **Tuple rest pattern** (§9.8) — `let (first, ..rest) = tuple` not supported ("tuple destructuring requires identifier bindings").

## Functions

- [ ] **Named arguments at call site** (§9.1) — `f(x: 1, y: 2)` or `f(x = 1, y = 2)` not supported.
- [ ] **Partial application** (§9.4) — Placeholder `_` syntax for partial application (`add(5, _)`) not implemented.

## Traits & Generics

- [ ] **Contains trait** (§11.7) — Not defined as a built-in syntax trait. `in` operator works but through a different mechanism.
- [ ] **Index/IndexMut traits** (§11.7) — Not defined as built-in syntax traits for user types. Subscript works on built-in collections.
- [ ] **Object safety checking** (§11.3) — Trait objects work but object safety rules (by-value self exclusion, generic method exclusion) are not enforced.
- [ ] **Associated type bound checking** (§11.6) — `type Item: Eq` bounds on associated types not implemented (deferred in v1.0 spec).
- [ ] **Implicit trait object coercion** (§3.9) — `&T` → `&dyn Trait` automatic vtable construction not fully implemented.

## Comptime & Metaprogramming

- [ ] **comptime if cfg** (§17) — `comptime if cfg.target_os` conditional compilation not implemented.
- [ ] **TypeInfo API** (§17) — `T.fields()` / `T.variants()` / `T.size()` / `T.name()` / `T.implements()` type reflection not implemented.
- [ ] **comptime for** (§17) — Compile-time loop unrolling not implemented.
- [ ] **transmute** (§16.12) — Not available as a built-in. sizeof and alignof work.

## Async & Concurrency

- [ ] **Fiber runtime** (§14) — async/await syntax is parsed and lowered but the fiber runtime is not operational.
- [ ] **Generators** (§14.13) — `gen fn` keyword is reserved but generators are not implemented.
- [ ] **Channels** (§14.14) — `channel[T](cap)` is not available.
- [ ] **Structured concurrency scope** (§14.7) — `scope s =>` syntax is not parsed. Task cancellation as unwinding not implemented.
- [ ] **select await** (§14.10) — Syntax is parsed but runtime support is not operational.
- [ ] **ScopedSend/Send traits** (§14.15) — Not implemented. Auto-implementation hierarchy (`Send ⊂ ScopedSend`) missing.
- [ ] **@[no_await_guard]** (§7.9) — Attribute not enforced.
- [ ] **may_suspend analysis** (§14.3) — Whole-program boolean propagation not implemented.
- [ ] **FFI stack switching** (§14.18) — Automatic stack switching for C calls not implemented. `@[ffi_stack]` attribute not enforced.

## Borrow Checker

- [ ] **Full move tracking** (§3, §12) — Basic NLL borrow checking works. Missing: full move tracking across all paths, enforcement of ephemeral return chain.
- [ ] **Closure capture analysis** (§12.3) — Closures work but capture mode (move vs borrow) analysis is incomplete. Disjoint field capture not tracked.

## Standard Library

- [ ] **Stdlib modules** (§13) — fs, net, io, sync, time not implemented.
- [ ] **Iterator constructors** (§13.3) — `Iter.empty()`, `Iter.once()`, `Iter.repeat()`, `Iter.unfold()`, `Iter.from_fn()`.
- [ ] **Iterator combinators** (§13.3) — `windows`, `chunks`, `dedup`, `unique`, `intersperse`, `scan`, `step_by`, `zip_with`, `group_by`, `partition`, `reduce`, `product`, `min_by`, `max_by`, `position`, `none`, `sorted`, `sorted_by`, `unzip`.
- [ ] **HashMap convenience methods** (§13.3) — `update`, `increment`, `decrement`, `append`.
- [ ] **Collection combinators** (§10.7) — `sequence()`, `traverse()`.
- [ ] **Map comprehension** (§13.6) — `{k: v for ...}` syntax. List comprehensions work.
- [ ] **Raw pointer .as_option()** (§16.1) — Convert null pointers to Option type.

## FFI

- [ ] **extern var / extern let** (§16.3b) — External variable declarations for C globals not implemented.
- [ ] **@[c_export("name")]** — C linkage export attribute not implemented.
- [ ] **@[repr(packed)]** (§16.4) — Packed struct layout attribute not implemented.
- [ ] **String auto-promotion** (§15.3) — Automatic `.to_owned()` insertion on string literals in owned contexts not implemented.

## Other

- [ ] **defer unwinding semantics** (§2.4) — Basic defer works. Unwinding interaction with errdefer and panic is incomplete.
- [ ] **with blocks guarded form** (§7.1) — Basic `with expr as name:` works. Guard trait (`Scoped[T]`) integration for automatic lock/resource management is not fully wired.
