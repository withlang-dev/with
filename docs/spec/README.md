# The With Programming Language — Specification v7.33

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
**Changelog v7.33:** locals typed by their uses, 2026-10-10 (D128). §4.2.1: a
binding whose untyped integer literal typed it takes the type its demanding
uses in its function agree on; `isize` where none narrows; two demands
that differ are an error naming both; never changes a compiling program.
**Changelog v7.32:** slice demands and views of constants, 2026-10-09
(D126, D127). §4.3c: a slice demand supplies the element type to a literal
in argument position and views it; it demands no collection. §3.1: a view
of a constant is a view of an immutable static, materialized once at the
demanded type, with static lifetime; a mutable view of a constant is an
error. The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.31:** literal join arms and what a cast does, 2026-10-09
(D125). §4.2.1 rule 8: an untyped literal arm of an `if`, `match` or `??`,
or a literal return of a function whose return type is inferred, takes the
typed arms' type (a tuple of literals and an all-literal `if` too; beside a
view, the number's type); an all-literal join is typed by its outer context;
typed arms that disagree are an error. §4.2.1: exact constant evaluation has
no width limit. §4.2.6: integer casts keep the low two's-complement bits;
float to integer truncates and saturates, NaN gives 0; to a float, nearest
ties-to-even, overflow to ±infinity. The implementation is NON-COMPLIANT
until it catches up.
**Changelog v7.30:** a cast converts an untyped constant exactly,
2026-10-09 (D124). §4.2.1: an untyped constant expression is evaluated
exactly, with no width, until a context types it; a cast is such a context
(rule 7) and converts the exact value with the runtime cast's wrap and
truncate rule, never through `isize`; float constants follow the runtime
rule. The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.29:** `offsetof[T](field)`, 2026-10-07 (D109, delegated).
§16.12: a built-in generic function returning a field's byte offset in a
struct's layout for the compilation target, beside `sizeof` and
`alignof`; the field is named bare, never evaluated. The migrator spells
C's `offsetof(T, f)` with it instead of folding the host's number
(#2131).
**Changelog v7.28:** the width of a length, 2026-10-07 (D108). §18.6:
`len()`, `count()` and `position()` return `isize`, the signed
pointer-width integer; `Int` stays the fixed 64-bit alias. §4.2: `usize`
and `isize` are pointer-width, 32 bits on wasm32 (the previous sentence
predated that target). The implementation is NON-COMPLIANT until #2262
catches up.
**Changelog v7.27:** visibility, 2026-10-05 (D100). §18.3: a declaration
without `pub` is visible throughout its package, and `pub` means it leaves
the package (it was private to its file); the rule covers methods and
fields too. A module under an `internal` path segment is importable only
from inside its parent's tree. §18.4: a package is a directory with
`with.toml`; a file run outside one is its own package; the standard
library is one package. The implementation is NON-COMPLIANT until it
catches up.
**Changelog v7.26:** three rulings, 2026-10-05 (D97). §11.7: `std.TotalF64`
(and `TotalF32`) is a float key: NaN equals NaN and sorts last, `-0.0` equals
`0.0` (#2182). §11.8: derived `Ord` orders an enum's variants by
declaration, then their payloads; §10.1: `Option` is declared
`None | Some(T)`, so `None` sorts first. §16.2b.4: a facade may state one
error type for all of its fallible operations, `error SqliteError` (#2179).
The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.25:** keys and maps, 2026-10-05 (D96). §11.7: a key is any
type whose `==` is structural and that holds no float; every key implements
`Key`; a type whose equality is about one part of its value states that
part as its key projection (`fn key()`), from which `==` and the hash both
follow; the hash is the compiler's, seeded per process; `Hash` is no longer
written or derived (§11.8). Collection operations: `HashMap` and `HashSet`
iterate in insertion order. The implementation is NON-COMPLIANT until it
catches up.
**Changelog v7.24:** five rulings, 2026-10-05 (D95). §29.6: `_` binds
nothing, so `let _ = x` moves a non-`Copy` `x` and drops it there (#2074).
§9.1b: a `pub const` may omit its type as a private one may; §4.2.1: a use
the value does not fit is an error at that use (#2101). §9.9: `??` has its
own level between the comparisons and `|>`, right-associative (#2142).
§11.8: a tuple, a fixed array, `Option` and `Result` implement `Clone`, `Eq`,
`Ord`, `Hash` and `Debug` when every element type does; a clone that panics
partway drops what it cloned (#2161). The implementation is NON-COMPLIANT
until it catches up.
**Changelog v7.23:** a collection literal's binding, 2026-10-05 (D93).
§4.3c rule 1: an annotation may name the collection without its arguments
(`let w: List = [1, 2, 3]`); a binding with no annotation takes its type
from its uses (a parameter, a typed place, a return, a method exactly one
collection has), element type included; a slice demand is met by the fixed
array; two demanded types are an error; an empty literal with no demand is
an error (#2144). The implementation is NON-COMPLIANT until it catches up.
**Changelog v7.22:** modeled-C Amendment 3, 2026-10-04 (D92). §16.2b.4: an
fn item whose C function returns a status may state `ok`, with one
constant or several, and is then presented as a `Result`; a resource may
name the operation that describes its most recent failure (`message`),
and its operations' errors carry the text. §16.2b.11: an fn item may be
written more than once under distinct `rename`s. The implementation is
NON-COMPLIANT until it catches up.
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

- [§1. Design Goals](001_design-goals.md)
  - [§1.1 Identity](001_design-goals.md#11-identity)
  - [§1.2 Positioning](001_design-goals.md#12-positioning)
  - [§1.3 Target Domains](001_design-goals.md#13-target-domains)
  - [§1.4 Ownership Philosophy](001_design-goals.md#14-ownership-philosophy)
  - [§1.5 Explicit Non-Goals](001_design-goals.md#15-explicit-non-goals)
  - [§1.6 Comparison](001_design-goals.md#16-comparison)
  - [§1.7 Ergonomics](001_design-goals.md#17-ergonomics)
  - [§1.8 Known Tradeoffs](001_design-goals.md#18-known-tradeoffs)
- [§2. Values and Ownership](002_ownership.md)
  - [§2.1 Values](002_ownership.md#21-values)
  - [§2.2 Move Semantics](002_ownership.md#22-move-semantics)
  - [§2.3 Copy Types](002_ownership.md#23-copy-types)
  - [§2.4 Destructors and `defer`](002_ownership.md#24-destructors-and-defer)
  - [§2.5 Generational Ownership](002_ownership.md#25-generational-ownership)
- [§3. References and Borrowing](003_borrowing.md)
  - [§3.1 Reference Types](003_borrowing.md#31-reference-types)
  - [§3.2 Aliasing Rule](003_borrowing.md#32-aliasing-rule)
  - [§3.3 Second-Class Restriction](003_borrowing.md#33-second-class-restriction)
  - [§3.4 Returning References](003_borrowing.md#34-returning-references)
  - [§3.5 Borrow Scope: Non-Lexical Lifetimes](003_borrowing.md#35-borrow-scope-non-lexical-lifetimes)
  - [§3.6 Disjoint Field Access](003_borrowing.md#36-disjoint-field-access)
  - [§3.7 Auto-Dereferencing](003_borrowing.md#37-auto-dereferencing)
  - [§3.8 Auto-Referencing](003_borrowing.md#38-auto-referencing)
  - [§3.9 Implicit Trait Object Coercion](003_borrowing.md#39-implicit-trait-object-coercion)
- [§4. Types](004_types.md)
  - [§4.1 Primitive Types](004_types.md#41-primitive-types)
  - [§4.2 Arithmetic and Operators](004_types.md#42-arithmetic-and-operators)
  - [§4.3 Structs](004_types.md#43-structs)
  - [§4.3a Fixed-Size Arrays](004_types.md#43a-fixed-size-arrays)
  - [§4.3b Bitpacked Structs](004_types.md#43b-bitpacked-structs)
  - [§4.3c Collection Literals](004_types.md#43c-collection-literals)
  - [§4.4a Discriminant Enums](004_types.md#44a-discriminant-enums)
  - [§4.5 Distinct Types](004_types.md#45-distinct-types)
  - [§4.6 Type Inference](004_types.md#46-type-inference)
  - [§4.7 Ranges](004_types.md#47-ranges)
  - [§4.8 Tuples](004_types.md#48-tuples)
  - [§4.8a Slices](004_types.md#48a-slices)
  - [§4.9 Implicit `Ok` Wrapping](004_types.md#49-implicit-ok-wrapping)
  - [§4.10 Implicit Default Return](004_types.md#410-implicit-default-return)
- [§5. Ephemeral Types](005_ephemeral.md)
  - [§5.1 Definition](005_ephemeral.md#51-definition)
  - [§5.2 Propagation](005_ephemeral.md#52-propagation)
  - [§5.3 Canonical Ephemeral Types](005_ephemeral.md#53-canonical-ephemeral-types)
  - [§5.4 Views: Ephemeral vs Storable](005_ephemeral.md#54-views-ephemeral-vs-storable)
  - [§5.5 Ephemeral Structs](005_ephemeral.md#55-ephemeral-structs)
- [§6. Handles and Generational Arenas](006_handles.md)
  - [§6.1 Handles](006_handles.md#61-handles)
  - [§6.2 SlotMap (Standard Library Requirement)](006_handles.md#62-slotmap-standard-library-requirement)
  - [§6.3 Performance Characteristics](006_handles.md#63-performance-characteristics)
- [§7. `with` — Scoped Access](007_with-scoped-access.md)
  - [§7.1 Form 1: Guarded Access](007_with-scoped-access.md#71-form-1-guarded-access)
  - [§7.2 Form 2: Scoped Mutation (Builder Pattern)](007_with-scoped-access.md#72-form-2-scoped-mutation-builder-pattern)
  - [§7.3 Form 3: Scoped Binding](007_with-scoped-access.md#73-form-3-scoped-binding)
  - [§7.3a Form 3a: Implicit Context](007_with-scoped-access.md#73a-form-3a-implicit-context)
  - [§7.4 Form 4: Record Update](007_with-scoped-access.md#74-form-4-record-update)
  - [§7.5 Dispatch Rule](007_with-scoped-access.md#75-dispatch-rule)
  - [§7.6 `with` as Expression](007_with-scoped-access.md#76-with-as-expression)
  - [§7.7 Control Flow Inside `with` Blocks](007_with-scoped-access.md#77-control-flow-inside-with-blocks)
  - [§7.8 `with` Frequency](guide/with-frequency.md)
  - [§7.9 `with` Idioms and Rules](guide/with-idioms-and-rules.md)
- [§8. Memory Management](008_memory.md)
  - [§8.1 No Garbage Collector](008_memory.md#81-no-garbage-collector)
  - [§8.2 No Transparent Reference Counting](008_memory.md#82-no-transparent-reference-counting)
  - [§8.3 Allocators](008_memory.md#83-allocators)
  - [§8.3a Temporary Arenas](008_memory.md#83a-temporary-arenas)
  - [§8.4 Convenience Type](008_memory.md#84-convenience-type)
- [§9. Functions and Expressions](009_functions.md)
  - [§9.1 Functions](009_functions.md#91-functions)
  - [§9.1a Named Arguments, Default Parameters, and Implicit Parameters](009_functions.md#91a-named-arguments-default-parameters-and-implicit-parameters)
  - [§9.1b `const` Declarations](009_functions.md#91b-const-declarations)
  - [§9.1c Global Declarations](009_functions.md#91c-global-declarations)
  - [§9.2 Tail Call Optimization](009_functions.md#92-tail-call-optimization)
  - [§9.3 Closures](009_functions.md#93-closures)
  - [§9.4 Partial Application](009_functions.md#94-partial-application)
  - [§9.5 Extension Blocks](009_functions.md#95-extension-blocks)
  - [§9.6 Pipeline and Composition Operators](009_functions.md#96-pipeline-and-composition-operators)
  - [§9.7 Pattern Matching](009_functions.md#97-pattern-matching)
  - [§9.8 Pipeline DSL Patterns](009_functions.md#98-pipeline-dsl-patterns)
  - [§9.9 The `in` Operator](009_functions.md#99-the-in-operator)
- [§10. Error Handling](010_errors.md)
  - [§10.1 Result and Option](010_errors.md#101-result-and-option)
  - [§10.2 The `?` Operator](010_errors.md#102-the--operator)
  - [§10.3 Optional Chaining (`?.`)](010_errors.md#103-optional-chaining-)
  - [§10.4 Default Operator (`??`)](010_errors.md#104-default-operator-)
  - [§10.5 Option Combinators (Standard Library Requirement)](010_errors.md#105-option-combinators-standard-library-requirement)
  - [§10.6 Result Combinators (Standard Library Requirement)](010_errors.md#106-result-combinators-standard-library-requirement)
  - [§10.7 Collection Combinators: `sequence` and `traverse`](010_errors.md#107-collection-combinators-sequence-and-traverse)
  - [§10.8 Error Declarations](010_errors.md#108-error-declarations)
  - [§10.9 Error Conversion with `from`](010_errors.md#109-error-conversion-with-from)
- [§11. Traits](011_traits.md)
  - [§11.1 Definition and Implementation](011_traits.md#111-definition-and-implementation)
  - [§11.2 Generic Bounds](011_traits.md#112-generic-bounds)
  - [§11.2a `where` Clauses](011_traits.md#112a-where-clauses)
  - [§11.3 Static Dispatch by Default](011_traits.md#113-static-dispatch-by-default)
  - [§11.4 Coherence (Orphan Rules)](011_traits.md#114-coherence-orphan-rules)
  - [§11.5 Async Methods in Traits](011_traits.md#115-async-methods-in-traits)
  - [§11.6 Feature Scope (v1.0)](011_traits.md#116-feature-scope-v10)
  - [§11.7 Syntax Traits](011_traits.md#117-syntax-traits)
  - [§11.8 Derive](011_traits.md#118-derive)
  - [§11.9 Debug Formatting (`:?`)](011_traits.md#119-debug-formatting-)
- [§12. Closures and Escaping](012_closures.md)
  - [§12.1 Non-Escaping Closures](012_closures.md#121-non-escaping-closures)
  - [§12.2 Escaping Closures](012_closures.md#122-escaping-closures)
  - [§12.3 Precise Rules (v1.0)](012_closures.md#123-precise-rules-v10)
  - [§12.4 Capture Semantics and Effects](012_closures.md#124-capture-semantics-and-effects)
- [§13. Iteration and Collection Operations](013_iteration.md)
  - [§13.1 Iterators Over Borrowed Data Are Ephemeral](013_iteration.md#131-iterators-over-borrowed-data-are-ephemeral)
  - [§13.2 The Iterator Trait](013_iteration.md#132-the-iterator-trait)
  - [§13.3 Collection Operations (Standard Library)](stdlib/collection-operations.md)
  - [§13.4 Generators (`yield`)](013_iteration.md#134-generators-yield)
  - [§13.5 For-In Loops](013_iteration.md#135-for-in-loops)
  - [§13.5a Labels, Labeled Break, and Continue](013_iteration.md#135a-labels-labeled-break-and-continue)
  - [§13.5b Goto Statement](013_iteration.md#135b-goto-statement)
  - [§13.5c `do`-`while` Loop](013_iteration.md#135c-do-while-loop)
  - [§13.5d The `loop` Construct](013_iteration.md#135d-the-loop-construct)
  - [§13.6 Collection Comprehensions](013_iteration.md#136-collection-comprehensions)
  - [§13.6a Option and Result For-Comprehensions](013_iteration.md#136a-option-and-result-for-comprehensions)
- [§14. Concurrency](014_concurrency.md)
  - [§14.1 Design Principles](014_concurrency.md#141-design-principles)
  - [§14.2 What `async`/`.await` Mean in With](014_concurrency.md#142-what-asyncawait-mean-in-with)
  - [§14.3 Formal Invariants](014_concurrency.md#143-formal-invariants)
  - [§14.4 `async fn` Semantics](014_concurrency.md#144-async-fn-semantics)
  - [§14.5 `.await` Semantics](014_concurrency.md#145-await-semantics)
  - [§14.6 `async:` Blocks](014_concurrency.md#146-async-blocks)
  - [§14.7 `Task[T]`](014_concurrency.md#147-taskt)
  - [§14.8 Parallel Execution](014_concurrency.md#148-parallel-execution)
  - [§14.9 Structured Concurrency](014_concurrency.md#149-structured-concurrency)
  - [§14.10 Select Await](014_concurrency.md#1410-select-await)
  - [§14.11 Concurrent Await](014_concurrency.md#1411-concurrent-await)
  - [§14.12 Why Fibers, Not State Machines?](implementation/why-fibers.md)
  - [§14.13 Interaction with Ownership](014_concurrency.md#1413-interaction-with-ownership)
  - [§14.14 OS Threads (Always Available)](014_concurrency.md#1414-os-threads-always-available)
  - [§14.15 Channels](stdlib/channels.md)
  - [§14.16 Send, Sync, and ScopedSend](stdlib/send-sync-scopedsend.md)
  - [§14.17 Synchronization Primitives](stdlib/synchronization-primitives.md)
  - [§14.18 The Fiber Runtime](implementation/fiber-runtime.md)
  - [§14.19 Fiber Stack Management](implementation/fiber-stack-management.md)
  - [§14.20 Generators vs. Async: A Clarification](014_concurrency.md#1420-generators-vs-async-a-clarification)
  - [§14.21 Real-World Example](guide/real-world-example.md)
  - [§14.22 Task Ephemerality and Send](014_concurrency.md#1422-task-ephemerality-and-send)
- [§15. Strings](015_strings.md)
  - [§15.1 String Types](015_strings.md#151-string-types)
  - [§15.2 Conversions](stdlib/string-conversions.md)
  - [§15.3 String Literals](015_strings.md#153-string-literals)
  - [§15.4 Formatted String Interpolation (F-Strings)](015_strings.md#154-formatted-string-interpolation-f-strings)
  - [§15.7 Output Functions](stdlib/output-functions.md)
  - [§15.8 Regular Expressions](stdlib/regular-expressions.md)
- [§16. FFI and C Interoperability](016_ffi.md)
  - [§16.1 `c_import`: Automatic C Header Import](016_ffi.md#161-c_import-automatic-c-header-import)
  - [§16.2 Macro Handling](016_ffi.md#162-macro-handling)
  - [§16.2a Auto-Method Generation](016_ffi.md#162a-auto-method-generation)
  - [§16.2b Facades: Modeled C Ownership, Effects and Lifetimes](016_ffi.md#162b-facades-modeled-c-ownership-effects-and-lifetimes)
  - [§16.3 Manual Declarations](016_ffi.md#163-manual-declarations)
  - [§16.3b External Variables](016_ffi.md#163b-external-variables)
  - [§16.3c Contract-Driven Coercion at `c_import` Boundaries](016_ffi.md#163c-contract-driven-coercion-at-c_import-boundaries)
  - [§16.3d `@[effect]` — Declared Effect Contracts](016_ffi.md#163d-effect--declared-effect-contracts)
  - [§16.3e ABI Boundary Signatures Are C-Representable](abi/abi-boundary-signatures.md)
  - [§16.4 Layout Control](abi/layout-control.md)
  - [§16.5 Exporting to C](abi/exporting-to-c.md)
  - [§16.6 Function Pointers](abi/function-pointers.md)
  - [§16.7 Callback Pattern](016_ffi.md#167-callback-pattern)
  - [§16.8 Link Directives](016_ffi.md#168-link-directives)
  - [§16.9 Opaque Types](016_ffi.md#169-opaque-types)
  - [§16.10 Null Pointer Literal](016_ffi.md#1610-null-pointer-literal)
  - [§16.11 Raw Pointer Operations and `unsafe`](016_ffi.md#1611-raw-pointer-operations-and-unsafe)
  - [§16.12 Intrinsics](016_ffi.md#1612-intrinsics)
  - [§16.13 Inline Assembly](016_ffi.md#1613-inline-assembly)
- [§17. Metaprogramming](017_metaprogramming.md)
  - [§17.0 Magic Constants](017_metaprogramming.md#170-magic-constants)
  - [§17.1 Compile-Time Evaluation](017_metaprogramming.md#171-compile-time-evaluation)
  - [§17.1a Tracked-Input Comptime](017_metaprogramming.md#171a-tracked-input-comptime)
  - [§17.1b Capability-Bearing Comptime](017_metaprogramming.md#171b-capability-bearing-comptime)
  - [§17.2 Compile-Time Type Introspection](017_metaprogramming.md#172-compile-time-type-introspection)
  - [§17.3 Derive-Like Code Generation](017_metaprogramming.md#173-derive-like-code-generation)
  - [§17.4 comptime Loops](017_metaprogramming.md#174-comptime-loops)
  - [§17.5 Compile-Time Branching](017_metaprogramming.md#175-compile-time-branching)
  - [§17.6 Real-World Examples](017_metaprogramming.md#176-real-world-examples)
  - [§17.6a Compiler Intrinsics](017_metaprogramming.md#176a-compiler-intrinsics)
  - [§17.7 Constraints](017_metaprogramming.md#177-constraints)
- [§18. Modules and Packages](018_modules.md)
  - [§18.1 Modules](018_modules.md#181-modules)
  - [§18.2 Imports](018_modules.md#182-imports)
  - [§18.3 Visibility](018_modules.md#183-visibility)
  - [§18.4 Packages](018_modules.md#184-packages)
  - [§18.5 Toolchain](toolchain/toolchain.md)
  - [§18.5a Project Builds](toolchain/project-builds.md)
  - [§18.5b CLI One-Liners](toolchain/cli-one-liners.md)
  - [§18.5c Bundles and interfaces](toolchain/bundles-and-interfaces.md)
  - [§18.5d Acceptance scenarios](toolchain/acceptance-scenarios.md)
  - [§18.6 Standard Library Design](stdlib/standard-library-design.md)
  - [§18.7 Freestanding Mode (`no_std`)](018_modules.md#187-freestanding-mode-no_std)
  - [§18.8 Package Management](toolchain/package-management.md)
- [§19. Safety Boundaries](019_safety.md)
  - [§19.1 Safe by Default](019_safety.md#191-safe-by-default)
  - [§19.2 `unsafe` Required For](019_safety.md#192-unsafe-required-for)
  - [§19.2a `unsafe fn` — Function-Level Unsafe Context](019_safety.md#192a-unsafe-fn--function-level-unsafe-context)
  - [§19.3 `unsafe` Constraints Across Suspension Points](019_safety.md#193-unsafe-constraints-across-suspension-points)
  - [§19.4 Unnecessary `unsafe` is a Compile Error](019_safety.md#194-unnecessary-unsafe-is-a-compile-error)
- [§20. Performance Guarantees](020_performance.md)
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

- [§21. Borrow Checker Rules](021_borrow-checker-rules.md)
  - [§21.1 Rules](021_borrow-checker-rules.md#211-rules)
- [§22. Ephemeral Type Rules](022_ephemeral-rules.md)
  - [§22.1 Rules](022_ephemeral-rules.md#221-rules)
  - [§22.2 Closure Escaping (v1.0)](022_ephemeral-rules.md#222-closure-escaping-v10)
  - [§22.3 Diagnostic Contract](022_ephemeral-rules.md#223-diagnostic-contract)
- [§23. `with` Block Semantics](023_with-block-semantics.md)
  - [§23.1 Plain Binding Desugaring](023_with-block-semantics.md#231-plain-binding-desugaring)
  - [§23.2 Multiple Bindings](023_with-block-semantics.md#232-multiple-bindings)
  - [§23.3 Non-Local Control Flow](023_with-block-semantics.md#233-non-local-control-flow)
- [§24. `async`/`.await` Equivalences](024_async-equivalences.md)
  - [§24.1 `async fn` Equivalence](024_async-equivalences.md#241-async-fn-equivalence)
  - [§24.2 `.await` Equivalence](024_async-equivalences.md#242-await-equivalence)
  - [§24.3 `no_runtime` Gate](024_async-equivalences.md#243-no_runtime-gate)
### Part III — Appendices

---

- [§25. Test Cases](guide/test-cases.md)
- [§26. Phased Implementation](implementation/phased-implementation.md)
- [§27. Known Limitations and Trade-Offs (v1.0)](guide/known-limitations.md)
- [§28. Future Work](guide/future-work.md)
- [§29. Additional Lexical and Binding Rules (Wave Language Rules)](029_lexical-and-binding-rules.md)
  - [§29.1 Numeric separators](029_lexical-and-binding-rules.md#291-numeric-separators)
  - [§29.2 Trailing commas](029_lexical-and-binding-rules.md#292-trailing-commas)
  - [§29.3 Raw string literals](029_lexical-and-binding-rules.md#293-raw-string-literals)
  - [§29.4 Triple-quoted multiline strings](029_lexical-and-binding-rules.md#294-triple-quoted-multiline-strings)
  - [§29.5 Byte literals](029_lexical-and-binding-rules.md#295-byte-literals)
  - [§29.5a Labels](029_lexical-and-binding-rules.md#295a-labels)
  - [§29.6 Unused bindings](029_lexical-and-binding-rules.md#296-unused-bindings)
  - [§29.7 String escape parity](029_lexical-and-binding-rules.md#297-string-escape-parity)
  - [§29.8 No-shadowing](029_lexical-and-binding-rules.md#298-no-shadowing)
  - [§29.9 Pipeline-first guidance](029_lexical-and-binding-rules.md#299-pipeline-first-guidance)
  - [§29.10 `todo` and `unreachable`](029_lexical-and-binding-rules.md#2910-todo-and-unreachable)
  - [§29.11 Reserved Keywords](029_lexical-and-binding-rules.md#2911-reserved-keywords)
  - [§29.12 Error Codes](029_lexical-and-binding-rules.md#2912-error-codes)
  - [§29.13 Block Body Syntax](029_lexical-and-binding-rules.md#2913-block-body-syntax)
  - [§29.14 Attribute Index](029_lexical-and-binding-rules.md#2914-attribute-index)
- [§30. Formal Grammar (Informative)](030_grammar.md)
  - [§30.1 Notation](030_grammar.md#301-notation)
  - [§30.2 Lexical Grammar](030_grammar.md#302-lexical-grammar)
  - [§30.3 Declarations](030_grammar.md#303-declarations)
  - [§30.4 Statements](030_grammar.md#304-statements)
  - [§30.5 Expressions](030_grammar.md#305-expressions)
  - [§30.6 Patterns](030_grammar.md#306-patterns)
  - [§30.7 Format Specification](030_grammar.md#307-format-specification)
  - [§30.8 Block Syntax](030_grammar.md#308-block-syntax)
  - [§30.9 Reserved Keywords](030_grammar.md#309-reserved-keywords)
