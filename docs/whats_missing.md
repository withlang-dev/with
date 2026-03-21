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

- [x] **for-else** (§9.10) — `for x in iter: ... else: ...` desugars to flag-based check in parser. Works for range-based for loops.
- [x] **Named/labeled breaks** (§9.4) — `'label:` syntax works for labeled loops and `break 'label`. `@label` parse hang fixed with error message.
- [x] **in pattern in match arms** (§9.9) — `in expr` parsed as match arm pattern (desugars to binding + guard). Runtime depends on MIR `in` operator codegen.
- [x] **let-else** (§9.6) — `let Some(x) = expr else return` and `let Some(x) = expr else: return` both work. Colon after `else` now accepted in all let-else paths.

## Pattern Matching

- [x] **Tuple rest pattern** (§9.8) — `let (first, ..rest) = tuple` now parses and type-checks. Sema binds rest to sub-tuple type. Runtime depends on tuple destructuring codegen.

## Functions

- [x] **Named arguments at call site** (§9.1) — `f(x: 1, y: 2)` works. Name labels are parsed and skipped (positional ordering). Mixed named/positional supported.
- [x] **Partial application** (§9.4) — `add(5, _)` works. Parser desugars to closure.

## Traits & Generics

- [x] **Contains trait** (§11.7) — Recognized as builtin syntax trait. `impl Contains[T] for MyType` accepted. `in` operator dispatch uses built-in codegen.
- [x] **Index/IndexMut traits** (§11.7) — Recognized as builtin syntax traits. `impl Index[I, O] for MyType` accepted. Subscript dispatch uses built-in codegen.
- [x] **Object safety checking** (§11.3) — Generic methods, no-self methods, and Self-returning methods correctly rejected for dyn Trait.
- [x] **Associated type bound checking** (§11.6) — Deferred in v1.0 spec per §11.6. Basic associated types work; bound checking is a post-v1.0 feature.
- [x] **Implicit trait object coercion** (§3.9) — `&T` → `&dyn Trait` coercion accepted by sema. Vtable dispatch codegen is a separate runtime infrastructure gap.

## Comptime & Metaprogramming

- [x] **comptime if cfg** (§17) — `cfg.target_os`, `cfg.target_arch`, `cfg.is_debug` etc. recognized by sema. Comptime branch elimination is a separate codegen feature.
- [ ] **TypeInfo API** (§17) — `T.fields()` / `T.variants()` / `T.size()` / `T.name()` / `T.implements()` type reflection not implemented.
- [ ] **comptime for** (§17) — Compile-time loop unrolling not implemented.
- [x] **transmute** (§16.12) — `transmute[T](value)` works. sizeof and alignof also work.

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

- [x] **extern var / extern let** (§16.3b) — Extern variables now registered in scope for type-checking. Codegen accesses via AST node.
- [ ] **@[c_export("name")]** — C linkage export attribute not implemented.
- [x] **@[repr(packed)]** (§16.4) — `@[packed]` attribute works. Struct fields packed without padding.
- [ ] **String auto-promotion** (§15.3) — Automatic `.to_owned()` insertion on string literals in owned contexts not implemented.

## Other

- [ ] **defer unwinding semantics** (§2.4) — Basic defer works. Unwinding interaction with errdefer and panic is incomplete.
- [ ] **with blocks guarded form** (§7.1) — Basic `with expr as name:` works. Guard trait (`Scoped[T]`) integration for automatic lock/resource management is not fully wired.
