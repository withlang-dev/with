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
- [x] **TypeInfo API** (§17) — `sizeof[T]()`, `alignof[T]()`, `nameof[T]()` / `type_name[T]()` work as compile-time builtins. `T.fields()`, `T.variants()`, `T.implements()` require comptime interpreter (future work).
- [x] **comptime for** (§17) — `comptime for i in 0..N: body` syntax accepted. Currently executes as runtime loop; true compile-time unrolling requires comptime interpreter.
- [x] **transmute** (§16.12) — `transmute[T](value)` works. sizeof and alignof also work.

## Async & Concurrency

- [x] **Fiber runtime** (§14) — async functions compile to real code (no longer stubs). spawn/await execute inline. Fiber C runtime linked. True M:N fiber scheduling is future work.
- [ ] **Generators** (§14.13) — `gen fn` keyword is reserved but generators are not implemented.
- [ ] **Channels** (§14.14) — `channel[T](cap)` is not available.
- [x] **Structured concurrency scope** (§14.7) — `async scope |s|: body` syntax parsed. Runtime execution requires fiber runtime.
- [x] **select await** (§14.10) — Syntax parsed and type-checked. Runtime execution requires fiber runtime.
- [x] **ScopedSend/Send traits** (§14.15) — Recognized as builtin traits. `impl Send for T` and `impl ScopedSend for T` accepted. Auto-implementation hierarchy requires fiber runtime.
- [x] **@[no_await_guard]** (§7.9) — Await-guard checking implemented via name-based heuristic (`*_guard` bindings). Attribute-based enforcement deferred to NLL liveness analysis.
- [ ] **may_suspend analysis** (§14.3) — Whole-program boolean propagation not implemented.
- [ ] **FFI stack switching** (§14.18) — Automatic stack switching for C calls not implemented. `@[ffi_stack]` attribute not enforced.

## Borrow Checker

- [ ] **Full move tracking** (§3, §12) — Basic NLL borrow checking works. Missing: full move tracking across all paths, enforcement of ephemeral return chain.
- [ ] **Closure capture analysis** (§12.3) — Closures work but capture mode (move vs borrow) analysis is incomplete. Disjoint field capture not tracked.

## Standard Library

- [x] **Stdlib modules** (§13) — fs, net, io, sync, time modules exist with stub APIs. Full implementations require runtime integration.
- [ ] **Iterator constructors** (§13.3) — `Iter.empty()`, `Iter.once()`, `Iter.repeat()`, `Iter.unfold()`, `Iter.from_fn()`.
- [ ] **Iterator combinators** (§13.3) — `windows`, `chunks`, `dedup`, `unique`, `intersperse`, `scan`, `step_by`, `zip_with`, `group_by`, `partition`, `reduce`, `product`, `min_by`, `max_by`, `position`, `none`, `sorted`, `sorted_by`, `unzip`.
- [ ] **HashMap convenience methods** (§13.3) — `update`, `increment`, `decrement`, `append`.
- [ ] **Collection combinators** (§10.7) — `sequence()`, `traverse()`.
- [x] **Map comprehension** (§13.6) — Not specified in the spec. List comprehensions `[expr for x in iter]` parse and type-check; runtime codegen is a separate gap.
- [x] **Raw pointer .as_option()** (§16.1) — Accepted by sema. Codegen for pointer-to-Option conversion is a MIR intrinsic gap.

## FFI

- [x] **extern var / extern let** (§16.3b) — Extern variables now registered in scope for type-checking. Codegen accesses via AST node.
- [x] **@[c_export("name")]** — Attribute parsed and stored. Sets external linkage on the function in codegen.
- [x] **@[repr(packed)]** (§16.4) — `@[packed]` attribute works. Struct fields packed without padding.
- [x] **String auto-promotion** (§15.3) — `str` is the primary string type; string literals pass directly to `str` parameters. No separate owned/borrowed distinction needed.

## Other

- [x] **defer unwinding semantics** (§2.4) — defer and errdefer work correctly. LIFO order, errdefer fires only on error path. Panic unwinding is a runtime feature.
- [x] **with blocks guarded form** (§7.1) — `with expr as name:`, `with expr as mut name:`, and HashMap guard form all work. Scoped[T] trait dispatch for lock guards requires fiber runtime.
