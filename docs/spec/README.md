# The With Programming Language — Specification v7.21

**Author:** Eric Hartford
**Status:** Reference specification for prototype implementation
**D22 authority:** `docs/meetings/d22-Eric-Ruling.md` is Eric's canonical and complete
D22 ruling. This specification records its normative language, but cannot
amend, narrow, or override it. Any D22 omission or conflict here is a
specification defect to repair in favor of the ruling.
**D22 implementation status (2026-07-23): A new decision has been made, but
implementation is still in progress.** The D22 rules are normative now. The
compiler, comptime evaluator, backends, standard library, diagnostics, and
tests are NON-COMPLIANT wherever they do not yet implement them. Existing
implementation behavior must not be treated as precedent against D22.
**Changelog v7.21:** the target at compile time, 2026-10-04 (D91). §17.1a:
`Target` is a declared build input. §17.5: `Target.os` and `Target.arch`
are compile-time constants of `OsKind` and `ArchKind`; a per-target value
is an exhaustive `comptime match`; a branch not taken is parsed and not
compiled; `with check --target <t>` checks a program as target `t`
compiles it. The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.20:** what a literal already says, 2026-10-04 (D88, D89).
§4.2.1: a `const` without a type whose initializer is unsuffixed numeric
literals has no numeric type of its own; each use is typed as the
initializer would be there (#2096). §4.3: a field with a default may omit
its type; an unsuffixed numeric default takes the type its uses in the
module demand, the default type when none does, and two demands are an
error (#2097). The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.19:** implicit fills, 2026-10-03 (D87). §7.3a: an implicit
fill observes the binding and never consumes it; a non-Copy `implicit T`
is passed explicitly; `std.context` APIs take `implicit &Context`. The
implementation is NON-COMPLIANT until it catches up.
**Changelog v7.18:** #1930 answers and the `from` grammar, 2026-10-03
(D83 and D84 amendments). §9.5: a bare name that resolves to a receiver
field and to any other name in scope is an error at that use; a
destructuring binding is a local binding. §18.1: a module names itself
by the last segment of its module path, a qualifier only; a stem that is
not an identifier is sanitized. §18.2: every prelude function and bare
intrinsic is reachable as `builtins.name`. §21.1 rule 6: what a `from`
origin names, the union over several views, inference, and the bundle
boundary. §30: `FROM_CLAUSE`, `ORIGIN`. The implementation is
NON-COMPLIANT until it catches up.
**Changelog v7.17:** four rulings of 2026-10-03. §9.5: in an instance
method declared in its type's own module, receiver fields are in scope by
bare name; every collision is a shadowing error (D83; #1930). §21.1 rule 6:
a returned view's origins include every global it views, `from G` names
one, and a global origin widens a bundle's `writes` clause past exported
globals (D84, amends D79; #1903). §16.2b.6: `returns borrow T from parent
T of param N` (D85; #2003). §18.2: `assert`, `require`, `check` are
compiler-known forms whose message is evaluated only on failure (D86;
#1864). The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.16:** §4.3d masks (D80 amendment): a mask lane is
writable, a `bool` literal in a mask context and a scalar operand of
`m.select` broadcast, the width-cast example is `m as Mask[4, 8]`; `m == n`,
mask-vector casts, `.bits()`/`.from_bits` and components on a mask, and
`~m`, are refused.
**Changelog v7.15:** §16.1: the C standard library headers `c_import`
reads come from the target's sysroot, which the compiler carries; other C
headers come from the program's dependencies; no host SDK is consulted
unless the program names one (D81).
**Changelog v7.14:** SIMD masks and lane selection (D80): `m.select(a, b)`
replaces `select(m, a, b)`, so `select` stays the `select await` keyword
alone; a scalar broadcasts on either side of every lane-wise operator;
masks construct, index, combine with `& | ^` and `not`, broadcast a
`bool`, and cast between widths; `W` includes 128, so `i128`/`u128` lanes
compare.
**Changelog v7.13:** a bundle's `pub` function declares the exported
globals it writes with a trailing `writes` clause; absent means none,
verified by the bundle build; a superset warns; transitivity is checked
from interfaces (toolchain/wo_bundles.md, grammar `WRITES_CLAUSE`, D79;
refines D39; #1827).
**Changelog v7.12:** the unsafe callable type is spelled `unsafe fn(A) -> R` /
`unsafe extern "C" fn(A) -> R`; it never coerces to the safe type of the same
signature; only the variadic type implies `unsafe` (§16.11; #1829).
**Changelog v7.11:** SIMD vectors: `Vector[N, T]` with the aliases `f32x4`…,
`Mask[N, W]` with `m32x4`…, lane-wise operators, splat in the two
one-meaning positions, swizzles, `.bits()`; c_import maps C vector types
onto them (§4.3d, §16.1, D78; #1874, retires #1872's omission).
**Changelog v7.10:** a match on a `&dyn T` subject downcasts with the typed
binding pattern `name: C`, which binds `&C` observing the same object; a
`@[sealed]` trait's implementors are the exhaustiveness domain; mutation is
only through `mut fn` methods, and owned by-value trait-object matching is
not defined (§9.7, grammar `TYPED_BIND_PAT`, D77; #1860). A parameter cannot
take a bare `dyn Trait` by value (§11.3; #1852).
**Changelog v7.9:** the type of a variadic C function as a value is `extern "C" fn(A, B, ...) -> R`, its `unsafe` implied, distinct from every fixed-arity function type (§16.2b.5, D75 item 6 extended; #1832).
**Changelog v7.8:** Process-global C state no safe view reaches is an audited
effect, not a domain (§16.2b.14, D76); a registering function may present a
callback's `argv`/`argc` as `&[Value]` and its user data as `&U` (§16.2b.9,
D76; modeled-C ruling Amendment 2).
**Changelog v7.7:** A consuming closure crosses a bundle boundary only to a
`once` parameter, and a non-`move` closure argument may not be returned
(§12.4, D75); `[value; N]` evaluates `value` once per element with a
compile-time `N` (§4.3a, D75); a cast into or out of a distinct type moves an
owned value and borrows through a view (§4.5, D75); an explicit `= N` makes a
backing-less payload enum a discriminant enum (§4.4a, D75); variadic
definitions (§16.2b.5, D75).
**Changelog v7.6:** A module file holds declarations; a file with top-level
executable statements is an entry source whose statements are its `main`,
and every command applies the same rule (§18.5b, D74). An optional chain on
a named place yields a view, `Option[&U]`; an owned demand on a non-`Copy`
payload gets the clone fix-it (§10.3, D74). Examples track §3.8/D27's
field-view binding (D74).
**Changelog v7.5:** An assignment's value is a read of the place after the
store — C's rule under With's view semantics (§9.1, D73); a `Drop` type whose
all-zero storage is a live value gets a hidden liveness byte (§2.5.1, D72).
**Changelog v7.4:** Ten rulings from the modeled-C close-out (D71): string
range slices are `&str` views (§4.8a); a positional collection has no `get`,
`xs[i]` is the one spelling (§ Element access, D27); `@[flags]` doubles
without a representation type and `from_int` requires unit variants
(§4.4a); a closure's `-> T` is checked (§12); `:?` refuses types with no
Debug form (§15.4.7); `@[repr(packed(N))]` (§16.4); and the facade gains
`ok` lists, `valid on failed`, and callback-scope `handle`s (§16.2b.4,
§16.2b.9; modeled-C ruling Amendment 1).
**Changelog v7.3:** Generators are push-based (§13.4, D69): a `gen fn`
is an ordinary function that calls the consumer's loop body at each
`yield`. A consumer's stop leaves the generator at its `yield`, releasing
its scopes; a generator may yield views of its own locals; `g.pull()`
gives a fiber-backed `Iter[T]` where code must step the sequence itself.
The state-machine model, its no-references-across-`yield` rule, and its
`.await` prohibition are retired (§13.4, §14.20).
**Changelog v7.2:** Owning keyed-map lookup has one uniform contract: `get`
returns `Option[&V]`; ownership transfer is performed by `remove`, which
returns `Option[V]`. A shared reference to a `Copy` value remains a reference
during inference and structural projection, but may satisfy an independently
established owned-value demand through contextual Copy materialization.
Pattern bindings preserve exact projected types. Option/Result elimination
preserves exact payload types, while `??`, `unwrap_or`, `unwrap_or_else`, and
other multi-expression joins use the contextual join rule. View origins
propagate through transparent carriers and eliminators until an operation
actually produces an independent owned value (§3.4, §3.8, §9.7, §10,
§13.3, §21.1, D22).
**Changelog v7.1:** Unit-returning `mut fn` pipeline stages thread the
receiver place; non-Unit stages thread their returned value, with resolved
generic returns and ordinary temporary/drop/alias rules (§9.6, D21). A
`mut fn` may not duplicate ownership still retained by its receiver into an
owned return; receiver-returning fluency is consuming (§9.5). Global
declarations specified (§9.1c): `global`
(stable) / `global var` (rebindable), pre-`main` initialization, and
the usage-based data-race rule — never-mutated and synchronized
globals always safe; bare mutation safe iff the program is provably
single-threaded, `unsafe` past the proof (E0921). §19.4 amended:
proof-dependent operations inside `unsafe` warn (not error) when
newly proven safe. **Integrated collections syntax** (Scala-inspired
target polymorphism): one bracket comprehension family with
expected-type-driven targets and `key: value` map form (§13.6);
collection literals incl. map literals `[k: v]` and `[:]` (§4.3c);
`vec![...]` examples replaced with collection literals; §30.5
grammar updated. **`loop` specified** (§13.5d): expression-valued
via `break expr`; §13.5a value-break text refined; §30.4 grammar.
**Regular expressions promoted to language surface** (§15.8): regex
literals `/pattern/flags`, `=~`/`!~` at precedence level 3,
branch-scoped `$capture` bindings as a refutable-binding condition
form; §18.5b.6 now defers to §15.8; `std.regex` added to §18.6.
`@[effect]` declared-effect contracts for bodiless declarations
(§16.3d). §14.19 `[runtime]` config for fiber stack and pool sizing.
CLI table completed (§18.5); module map extended with
regex/json/http/crypto + internal-modules note (§18.6); Attribute
Index appendix (§29.14). Named arguments: `pub` parameter names are
API surface (§9.1a). §18.7's `static` example corrected to `global`.
**Changelog v7.0:** Parameter passing: the signature states the mode —
`&T` borrows, plain `T` consumes; share-place call semantics removed
(§3.8; §12.4 retains by-place capture for closures; §21.1 example
fixed). Cancellation observation moved to the `Task` handle
(`was_cancelled`); the `TaskCancelled`/`.is_cancelled()` error story
removed — awaiting a cancelled task unwinds, never returns `Err`
(§14.7). `Result` removed from `@[must_use]` match exhaustiveness
(§9.7). `with ... as mut` always returns the binding (§7.2, §23.1).
Iterator borrow-origin via `@[iter_of_self]` specified for all
libraries (§13.2). `[]mut T` exclusivity rules and
`split_at`/`split_at_mut` (§4.8a). Ephemeral diagnostic contract
(§22.3). Fiber stack conforming baseline = fixed pooled stacks;
growth and FFI stack switching are roadmap (§14.19). c_import
contract metadata sources named, including the curated libc overlay
(§16.3c). Implicit default return gated to bodies with no explicit
value return (§4.10). Consuming-rebind shadowing exception (§29.8).
String-literal elision is an optimization, not a guarantee (§15.3,
§20). Hygiene: enum-only sum-type syntax swept (§10.1, §11.7, §30.3);
keyword list synced to the lexer (§29.11, §30.9 now defers to it);
`usize`/`isize` documented (§4.1, §4.2.1); duplicate §18.7 renumbered
to §18.8; `let mut` removed from §30.4 grammar; §14.21 match arms
fixed to `=>`; f-string examples fixed (§15.4.5, §15.4.7); generator
return type wording fixed (§13.1, §13.4); select-await dead panic
clause removed (§14.10); §22.1 Rule 6 distinguished from Rule 4;
module resolution and `pub` enforcement stated (§18.1, §18.3).
**Changelog v6.9:** CLI one-liners (`with -e`, `with -n`, `with -p`)
are specified as normal compiled With entry sources with implicit-main
semantics, stdin line bindings, `args`, semicolon splitting, and regex
capture behavior (§18.5b).
**Changelog v6.8:** Three universal body forms (§29.13) — inline colon,
indented colon, and braced — now apply to every block-introducing construct
including `defer`, `errdefer`, `comptime`, and `unsafe`. `if`, `else if`,
and `else` use those same body forms; every arm requires `:` or `{`.
`else if` is a two-token keyword pair parsed as a chain continuation.
**Changelog v6.7:** Reorganized — extracted test cases to `test/spec/`,
roadmap to `docs/proposals/roadmap.md`, and stdlib API tables to
`docs/libstd-spec.md`. Added grammar appendix (§30). Added labels on
arbitrary statements and `goto` (§13.5a, §13.5b).
**Positioning:** Systems programming that feels like a modern language.
**Principle:** Make the common case delightful. Be as safe as Rust without front-loading Rust's ceremony. Trust the programmer at the edges without accepting safety-contract violations.

---

## Table of Contents

### Part I — Language Design

---

- [§1. Design Goals](design-goals.md)
  - [§1.1 Identity](design-goals.md#11-identity)
  - [§1.2 Positioning](design-goals.md#12-positioning)
  - [§1.3 Target Domains](design-goals.md#13-target-domains)
  - [§1.4 Ownership Philosophy](design-goals.md#14-ownership-philosophy)
  - [§1.5 Explicit Non-Goals](design-goals.md#15-explicit-non-goals)
  - [§1.6 Comparison](design-goals.md#16-comparison)
  - [§1.7 Ergonomics](design-goals.md#17-ergonomics)
  - [§1.8 Known Tradeoffs](design-goals.md#18-known-tradeoffs)
- [§2. Values and Ownership](ownership.md)
  - [§2.1 Values](ownership.md#21-values)
  - [§2.2 Move Semantics](ownership.md#22-move-semantics)
  - [§2.3 Copy Types](ownership.md#23-copy-types)
  - [§2.4 Destructors and `defer`](ownership.md#24-destructors-and-defer)
  - [§2.5 Generational Ownership](ownership.md#25-generational-ownership)
- [§3. References and Borrowing](borrowing.md)
  - [§3.1 Reference Types](borrowing.md#31-reference-types)
  - [§3.2 Aliasing Rule](borrowing.md#32-aliasing-rule)
  - [§3.3 Second-Class Restriction](borrowing.md#33-second-class-restriction)
  - [§3.4 Returning References](borrowing.md#34-returning-references)
  - [§3.5 Borrow Scope: Non-Lexical Lifetimes](borrowing.md#35-borrow-scope-non-lexical-lifetimes)
  - [§3.6 Disjoint Field Access](borrowing.md#36-disjoint-field-access)
  - [§3.7 Auto-Dereferencing](borrowing.md#37-auto-dereferencing)
  - [§3.8 Auto-Referencing](borrowing.md#38-auto-referencing)
  - [§3.9 Implicit Trait Object Coercion](borrowing.md#39-implicit-trait-object-coercion)
- [§4. Types](types.md)
  - [§4.1 Primitive Types](types.md#41-primitive-types)
  - [§4.2 Arithmetic and Operators](types.md#42-arithmetic-and-operators)
  - [§4.3 Structs](types.md#43-structs)
  - [§4.3a Fixed-Size Arrays](types.md#43a-fixed-size-arrays)
  - [§4.3b Bitpacked Structs](types.md#43b-bitpacked-structs)
  - [§4.3c Collection Literals](types.md#43c-collection-literals)
  - [§4.4a Discriminant Enums](types.md#44a-discriminant-enums)
  - [§4.5 Distinct Types](types.md#45-distinct-types)
  - [§4.6 Type Inference](types.md#46-type-inference)
  - [§4.7 Ranges](types.md#47-ranges)
  - [§4.8 Tuples](types.md#48-tuples)
  - [§4.8a Slices](types.md#48a-slices)
  - [§4.9 Implicit `Ok` Wrapping](types.md#49-implicit-ok-wrapping)
  - [§4.10 Implicit Default Return](types.md#410-implicit-default-return)
- [§5. Ephemeral Types](ephemeral.md)
  - [§5.1 Definition](ephemeral.md#51-definition)
  - [§5.2 Propagation](ephemeral.md#52-propagation)
  - [§5.3 Canonical Ephemeral Types](ephemeral.md#53-canonical-ephemeral-types)
  - [§5.4 Views: Ephemeral vs Storable](ephemeral.md#54-views-ephemeral-vs-storable)
  - [§5.5 Ephemeral Structs](ephemeral.md#55-ephemeral-structs)
- [§6. Handles and Generational Arenas](handles.md)
  - [§6.1 Handles](handles.md#61-handles)
  - [§6.2 SlotMap (Standard Library Requirement)](handles.md#62-slotmap-standard-library-requirement)
  - [§6.3 Performance Characteristics](handles.md#63-performance-characteristics)
- [§7. `with` — Scoped Access](with-scoped-access.md)
  - [§7.1 Form 1: Guarded Access](with-scoped-access.md#71-form-1-guarded-access)
  - [§7.2 Form 2: Scoped Mutation (Builder Pattern)](with-scoped-access.md#72-form-2-scoped-mutation-builder-pattern)
  - [§7.3 Form 3: Scoped Binding](with-scoped-access.md#73-form-3-scoped-binding)
  - [§7.3a Form 3a: Implicit Context](with-scoped-access.md#73a-form-3a-implicit-context)
  - [§7.4 Form 4: Record Update](with-scoped-access.md#74-form-4-record-update)
  - [§7.5 Dispatch Rule](with-scoped-access.md#75-dispatch-rule)
  - [§7.6 `with` as Expression](with-scoped-access.md#76-with-as-expression)
  - [§7.7 Control Flow Inside `with` Blocks](with-scoped-access.md#77-control-flow-inside-with-blocks)
  - [§7.8 `with` Frequency](guide/with-frequency.md)
  - [§7.9 `with` Idioms and Rules](guide/with-idioms-and-rules.md)
- [§8. Memory Management](memory.md)
  - [§8.1 No Garbage Collector](memory.md#81-no-garbage-collector)
  - [§8.2 No Transparent Reference Counting](memory.md#82-no-transparent-reference-counting)
  - [§8.3 Allocators](memory.md#83-allocators)
  - [§8.3a Temporary Arenas](memory.md#83a-temporary-arenas)
  - [§8.4 Convenience Type](memory.md#84-convenience-type)
- [§9. Functions and Expressions](functions.md)
  - [§9.1 Functions](functions.md#91-functions)
  - [§9.1a Named Arguments, Default Parameters, and Implicit Parameters](functions.md#91a-named-arguments-default-parameters-and-implicit-parameters)
  - [§9.1b `const` Declarations](functions.md#91b-const-declarations)
  - [§9.1c Global Declarations](functions.md#91c-global-declarations)
  - [§9.2 Tail Call Optimization](functions.md#92-tail-call-optimization)
  - [§9.3 Closures](functions.md#93-closures)
  - [§9.4 Partial Application](functions.md#94-partial-application)
  - [§9.5 Extension Blocks](functions.md#95-extension-blocks)
  - [§9.6 Pipeline and Composition Operators](functions.md#96-pipeline-and-composition-operators)
  - [§9.7 Pattern Matching](functions.md#97-pattern-matching)
  - [§9.8 Pipeline DSL Patterns](functions.md#98-pipeline-dsl-patterns)
  - [§9.9 The `in` Operator](functions.md#99-the-in-operator)
- [§10. Error Handling](errors.md)
  - [§10.1 Result and Option](errors.md#101-result-and-option)
  - [§10.2 The `?` Operator](errors.md#102-the--operator)
  - [§10.3 Optional Chaining (`?.`)](errors.md#103-optional-chaining-)
  - [§10.4 Default Operator (`??`)](errors.md#104-default-operator-)
  - [§10.5 Option Combinators (Standard Library Requirement)](errors.md#105-option-combinators-standard-library-requirement)
  - [§10.6 Result Combinators (Standard Library Requirement)](errors.md#106-result-combinators-standard-library-requirement)
  - [§10.7 Collection Combinators: `sequence` and `traverse`](errors.md#107-collection-combinators-sequence-and-traverse)
  - [§10.8 Error Declarations](errors.md#108-error-declarations)
  - [§10.9 Error Conversion with `from`](errors.md#109-error-conversion-with-from)
- [§11. Traits](traits.md)
  - [§11.1 Definition and Implementation](traits.md#111-definition-and-implementation)
  - [§11.2 Generic Bounds](traits.md#112-generic-bounds)
  - [§11.2a `where` Clauses](traits.md#112a-where-clauses)
  - [§11.3 Static Dispatch by Default](traits.md#113-static-dispatch-by-default)
  - [§11.4 Coherence (Orphan Rules)](traits.md#114-coherence-orphan-rules)
  - [§11.5 Async Methods in Traits](traits.md#115-async-methods-in-traits)
  - [§11.6 Feature Scope (v1.0)](traits.md#116-feature-scope-v10)
  - [§11.7 Syntax Traits](traits.md#117-syntax-traits)
  - [§11.8 Derive](traits.md#118-derive)
  - [§11.9 Debug Formatting (`:?`)](traits.md#119-debug-formatting-)
- [§12. Closures and Escaping](closures.md)
  - [§12.1 Non-Escaping Closures](closures.md#121-non-escaping-closures)
  - [§12.2 Escaping Closures](closures.md#122-escaping-closures)
  - [§12.3 Precise Rules (v1.0)](closures.md#123-precise-rules-v10)
  - [§12.4 Capture Semantics and Effects](closures.md#124-capture-semantics-and-effects)
- [§13. Iteration and Collection Operations](iteration.md)
  - [§13.1 Iterators Over Borrowed Data Are Ephemeral](iteration.md#131-iterators-over-borrowed-data-are-ephemeral)
  - [§13.2 The Iterator Trait](iteration.md#132-the-iterator-trait)
  - [§13.3 Collection Operations (Standard Library)](stdlib/collection-operations.md)
  - [§13.4 Generators (`yield`)](iteration.md#134-generators-yield)
  - [§13.5 For-In Loops](iteration.md#135-for-in-loops)
  - [§13.5a Labels, Labeled Break, and Continue](iteration.md#135a-labels-labeled-break-and-continue)
  - [§13.5b Goto Statement](iteration.md#135b-goto-statement)
  - [§13.5c `do`-`while` Loop](iteration.md#135c-do-while-loop)
  - [§13.5d The `loop` Construct](iteration.md#135d-the-loop-construct)
  - [§13.6 Collection Comprehensions](iteration.md#136-collection-comprehensions)
  - [§13.6a Option and Result For-Comprehensions](iteration.md#136a-option-and-result-for-comprehensions)
- [§14. Concurrency](concurrency.md)
  - [§14.1 Design Principles](concurrency.md#141-design-principles)
  - [§14.2 What `async`/`.await` Mean in With](concurrency.md#142-what-asyncawait-mean-in-with)
  - [§14.3 Formal Invariants](concurrency.md#143-formal-invariants)
  - [§14.4 `async fn` Semantics](concurrency.md#144-async-fn-semantics)
  - [§14.5 `.await` Semantics](concurrency.md#145-await-semantics)
  - [§14.6 `async:` Blocks](concurrency.md#146-async-blocks)
  - [§14.7 `Task[T]`](concurrency.md#147-taskt)
  - [§14.8 Parallel Execution](concurrency.md#148-parallel-execution)
  - [§14.9 Structured Concurrency](concurrency.md#149-structured-concurrency)
  - [§14.10 Select Await](concurrency.md#1410-select-await)
  - [§14.11 Concurrent Await](concurrency.md#1411-concurrent-await)
  - [§14.12 Why Fibers, Not State Machines?](implementation/why-fibers.md)
  - [§14.13 Interaction with Ownership](concurrency.md#1413-interaction-with-ownership)
  - [§14.14 OS Threads (Always Available)](concurrency.md#1414-os-threads-always-available)
  - [§14.15 Channels](stdlib/channels.md)
  - [§14.16 Send, Sync, and ScopedSend](stdlib/send-sync-scopedsend.md)
  - [§14.17 Synchronization Primitives](stdlib/synchronization-primitives.md)
  - [§14.18 The Fiber Runtime](implementation/fiber-runtime.md)
  - [§14.19 Fiber Stack Management](implementation/fiber-stack-management.md)
  - [§14.20 Generators vs. Async: A Clarification](concurrency.md#1420-generators-vs-async-a-clarification)
  - [§14.21 Real-World Example](guide/real-world-example.md)
  - [§14.22 Task Ephemerality and Send](concurrency.md#1422-task-ephemerality-and-send)
- [§15. Strings](strings.md)
  - [§15.1 String Types](strings.md#151-string-types)
  - [§15.2 Conversions](stdlib/string-conversions.md)
  - [§15.3 String Literals](strings.md#153-string-literals)
  - [§15.4 Formatted String Interpolation (F-Strings)](strings.md#154-formatted-string-interpolation-f-strings)
  - [§15.7 Output Functions](stdlib/output-functions.md)
  - [§15.8 Regular Expressions](stdlib/regular-expressions.md)
- [§16. FFI and C Interoperability](ffi.md)
  - [§16.1 `c_import`: Automatic C Header Import](ffi.md#161-c_import-automatic-c-header-import)
  - [§16.2 Macro Handling](ffi.md#162-macro-handling)
  - [§16.2a Auto-Method Generation](ffi.md#162a-auto-method-generation)
  - [§16.2b Facades: Modeled C Ownership, Effects and Lifetimes](ffi.md#162b-facades-modeled-c-ownership-effects-and-lifetimes)
  - [§16.3 Manual Declarations](ffi.md#163-manual-declarations)
  - [§16.3b External Variables](ffi.md#163b-external-variables)
  - [§16.3c Contract-Driven Coercion at `c_import` Boundaries](ffi.md#163c-contract-driven-coercion-at-c_import-boundaries)
  - [§16.3d `@[effect]` — Declared Effect Contracts](ffi.md#163d-effect--declared-effect-contracts)
  - [§16.3e ABI Boundary Signatures Are C-Representable](abi/abi-boundary-signatures.md)
  - [§16.4 Layout Control](abi/layout-control.md)
  - [§16.5 Exporting to C](abi/exporting-to-c.md)
  - [§16.6 Function Pointers](abi/function-pointers.md)
  - [§16.7 Callback Pattern](ffi.md#167-callback-pattern)
  - [§16.8 Link Directives](ffi.md#168-link-directives)
  - [§16.9 Opaque Types](ffi.md#169-opaque-types)
  - [§16.10 Null Pointer Literal](ffi.md#1610-null-pointer-literal)
  - [§16.11 Raw Pointer Operations and `unsafe`](ffi.md#1611-raw-pointer-operations-and-unsafe)
  - [§16.12 Intrinsics](ffi.md#1612-intrinsics)
  - [§16.13 Inline Assembly](ffi.md#1613-inline-assembly)
- [§17. Metaprogramming](metaprogramming.md)
  - [§17.0 Magic Constants](metaprogramming.md#170-magic-constants)
  - [§17.1 Compile-Time Evaluation](metaprogramming.md#171-compile-time-evaluation)
  - [§17.1a Tracked-Input Comptime](metaprogramming.md#171a-tracked-input-comptime)
  - [§17.1b Capability-Bearing Comptime](metaprogramming.md#171b-capability-bearing-comptime)
  - [§17.2 Compile-Time Type Introspection](metaprogramming.md#172-compile-time-type-introspection)
  - [§17.3 Derive-Like Code Generation](metaprogramming.md#173-derive-like-code-generation)
  - [§17.4 comptime Loops](metaprogramming.md#174-comptime-loops)
  - [§17.5 Compile-Time Branching](metaprogramming.md#175-compile-time-branching)
  - [§17.6 Real-World Examples](metaprogramming.md#176-real-world-examples)
  - [§17.6a Compiler Intrinsics](metaprogramming.md#176a-compiler-intrinsics)
  - [§17.7 Constraints](metaprogramming.md#177-constraints)
- [§18. Modules and Packages](modules.md)
  - [§18.1 Modules](modules.md#181-modules)
  - [§18.2 Imports](modules.md#182-imports)
  - [§18.3 Visibility](modules.md#183-visibility)
  - [§18.4 Packages](modules.md#184-packages)
  - [§18.5 Toolchain](toolchain/toolchain.md)
  - [§18.5a Project Builds](toolchain/project-builds.md)
  - [§18.5b CLI One-Liners](toolchain/cli-one-liners.md)
  - [§18.5c Bundles and interfaces](toolchain/bundles-and-interfaces.md)
  - [§18.5d Acceptance scenarios](toolchain/acceptance-scenarios.md)
  - [§18.6 Standard Library Design](stdlib/standard-library-design.md)
  - [§18.7 Freestanding Mode (`no_std`)](modules.md#187-freestanding-mode-no_std)
  - [§18.8 Package Management](toolchain/package-management.md)
- [§19. Safety Boundaries](safety.md)
  - [§19.1 Safe by Default](safety.md#191-safe-by-default)
  - [§19.2 `unsafe` Required For](safety.md#192-unsafe-required-for)
  - [§19.2a `unsafe fn` — Function-Level Unsafe Context](safety.md#192a-unsafe-fn--function-level-unsafe-context)
  - [§19.3 `unsafe` Constraints Across Suspension Points](safety.md#193-unsafe-constraints-across-suspension-points)
  - [§19.4 Unnecessary `unsafe` is a Compile Error](safety.md#194-unnecessary-unsafe-is-a-compile-error)
- [§20. Performance Guarantees](performance.md)
- [§20b. Denied Patterns (Compile Errors)](toolchain/denied-patterns.md)
  - [§20b.1 `.await` Inside `@[no_await_guard]` Guard](toolchain/denied-patterns.md#20b1-await-inside-no_await_guard-guard)
  - [§20b.2 Task Disposition](toolchain/denied-patterns.md#20b2-task-disposition)
  - [§20b.3 Unnecessary `unsafe` Block](toolchain/denied-patterns.md#20b3-unnecessary-unsafe-block)
  - [§20b.4 Implicit Numeric Narrowing](toolchain/denied-patterns.md#20b4-implicit-numeric-narrowing)
  - [§20b.5 Unreachable Code](toolchain/denied-patterns.md#20b5-unreachable-code)
  - [§20b.6 Pointer Compared to Array](toolchain/denied-patterns.md#20b6-pointer-compared-to-array)
### Part II — Normative Rules

These sections define **what** the compiler must enforce. Implementation
strategies (algorithms, data structures, lowering approaches) are in
the companion document: *Implementation Notes*.

---

- [§21. Borrow Checker Rules](borrow-checker-rules.md)
  - [§21.1 Rules](borrow-checker-rules.md#211-rules)
- [§22. Ephemeral Type Rules](ephemeral-rules.md)
  - [§22.1 Rules](ephemeral-rules.md#221-rules)
  - [§22.2 Closure Escaping (v1.0)](ephemeral-rules.md#222-closure-escaping-v10)
  - [§22.3 Diagnostic Contract](ephemeral-rules.md#223-diagnostic-contract)
- [§23. `with` Block Semantics](with-block-semantics.md)
  - [§23.1 Plain Binding Desugaring](with-block-semantics.md#231-plain-binding-desugaring)
  - [§23.2 Multiple Bindings](with-block-semantics.md#232-multiple-bindings)
  - [§23.3 Non-Local Control Flow](with-block-semantics.md#233-non-local-control-flow)
- [§24. `async`/`.await` Equivalences](async-equivalences.md)
  - [§24.1 `async fn` Equivalence](async-equivalences.md#241-async-fn-equivalence)
  - [§24.2 `.await` Equivalence](async-equivalences.md#242-await-equivalence)
  - [§24.3 `no_runtime` Gate](async-equivalences.md#243-no_runtime-gate)
### Part III — Appendices

---

- [§25. Test Cases](guide/test-cases.md)
- [§26. Phased Implementation](implementation/phased-implementation.md)
- [§27. Known Limitations and Trade-Offs (v1.0)](guide/known-limitations.md)
- [§28. Future Work](guide/future-work.md)
- [§29. Additional Lexical and Binding Rules (Wave Language Rules)](lexical-and-binding-rules.md)
  - [§29.1 Numeric separators](lexical-and-binding-rules.md#291-numeric-separators)
  - [§29.2 Trailing commas](lexical-and-binding-rules.md#292-trailing-commas)
  - [§29.3 Raw string literals](lexical-and-binding-rules.md#293-raw-string-literals)
  - [§29.4 Triple-quoted multiline strings](lexical-and-binding-rules.md#294-triple-quoted-multiline-strings)
  - [§29.5 Byte literals](lexical-and-binding-rules.md#295-byte-literals)
  - [§29.5a Labels](lexical-and-binding-rules.md#295a-labels)
  - [§29.6 Unused bindings](lexical-and-binding-rules.md#296-unused-bindings)
  - [§29.7 String escape parity](lexical-and-binding-rules.md#297-string-escape-parity)
  - [§29.8 No-shadowing](lexical-and-binding-rules.md#298-no-shadowing)
  - [§29.9 Pipeline-first guidance](lexical-and-binding-rules.md#299-pipeline-first-guidance)
  - [§29.10 `todo` and `unreachable`](lexical-and-binding-rules.md#2910-todo-and-unreachable)
  - [§29.11 Reserved Keywords](lexical-and-binding-rules.md#2911-reserved-keywords)
  - [§29.12 Error Codes](lexical-and-binding-rules.md#2912-error-codes)
  - [§29.13 Block Body Syntax](lexical-and-binding-rules.md#2913-block-body-syntax)
  - [§29.14 Attribute Index](lexical-and-binding-rules.md#2914-attribute-index)
- [§30. Formal Grammar (Informative)](grammar.md)
  - [§30.1 Notation](grammar.md#301-notation)
  - [§30.2 Lexical Grammar](grammar.md#302-lexical-grammar)
  - [§30.3 Declarations](grammar.md#303-declarations)
  - [§30.4 Statements](grammar.md#304-statements)
  - [§30.5 Expressions](grammar.md#305-expressions)
  - [§30.6 Patterns](grammar.md#306-patterns)
  - [§30.7 Format Specification](grammar.md#307-format-specification)
  - [§30.8 Block Syntax](grammar.md#308-block-syntax)
  - [§30.9 Reserved Keywords](grammar.md#309-reserved-keywords)
