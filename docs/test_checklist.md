# With Compiler Test Checklist

Derived from:
- `docs/with-compiler-plan.md`
- `docs/with-specification.md`
- `docs/with-implementation-notes.md`

Use this file as the master test inventory for compiler, runtime, stdlib, and tooling.

## A) Compiler Plan Phase Checklist

### Phase 0: Bootstrap + C Interop

- [x] Project scaffolding modules (`ast`, `types`, `parse`, `check`, `mir`, `codegen`, `driver`, `diag`)
- [x] CI on Linux/macOS/Windows (`zig build test`)
- [x] Test harness (`tests/*.w` compile/run/exit/output validation)
- [x] Snapshot harness with update mode
- [x] Lexer coverage: keywords
- [x] Lexer coverage: operators (`|>`, `<|`, `>>`, `<<`, `?`, `?.`, `??`, `->`, `=>`, `..`, `..=`, wrapping ops)
- [x] Lexer coverage: brackets/punctuation/newline significance
- [x] Lexer coverage: literals (int/float/bool/string/interpolation)
- [x] Lexer coverage: identifiers and `.Variant`
- [x] Lexer coverage: comments
- [x] Parser: module declarations/imports
- [x] Parser: function definitions
- [x] Parser: let/var/defer
- [x] Parser: core expressions (calls, field/index, unary/binary, block, if/else, ranges)
- [x] Parser: type syntax (primitives/named/generics/references/function types/tuples)
- [x] Parser: `unsafe` blocks
- [x] Parser error recovery to next top-level declaration
- [x] Name resolution: locals/params/module scope/prelude/use-imports
- [x] Minimal type checking: literals/inference/returns/calls/operators
- [x] Struct construction and field access typing
- [x] Tuple typing/tuple indexing/tuple destructuring
- [x] Range typing (`Range[T]`, `RangeInclusive[T]`)
- [x] Pointer typing (`*const T`, `*mut T`)
- [x] Raw pointer `.as_option()` null/non-null mapping
- [x] Built-in aliases: `str = String`, `&str = StrView`
- [x] `c_import` via libclang parse + AST walk + type mapping + injected module
- [x] `c_import` link directives
- [x] `c_import` caching/invalidation
- [x] LLVM backend minimal codegen path
- [x] LLVM verify + IR dump
- [x] Object emission + system link
- [x] Driver commands: `with run`, `with build`, `with test`
- [x] Phase milestone: `c_import("stdio.h")` and `puts/printf` end-to-end

### Phase 1: Ownership Core

- [x] Move semantics on assignment
- [x] Use-after-move diagnostics
- [x] `Copy` types remain copyable
- [x] Drop insertion at scope exits in reverse declaration order
- [x] `Copy` and `Drop` mutual exclusivity
- [x] CFG construction for borrow checking
- [x] NLL range computation by liveness
- [x] Overlap conflict checks (shared vs mutable, mutable vs mutable)
- [x] Disjoint field borrow acceptance
- [x] No borrow storage across boundaries (ephemeral enforcement)
- [x] Ephemeral marking propagation
- [x] Ephemeral restriction: not storable in structs
- [x] Ephemeral restriction: not storable in collections
- [x] Ephemeral restriction: return only in ephemeral positions
- [x] Closure capture interaction with ephemerals
- [x] Reference return provenance enforcement
- [x] Phase milestone: tests 25.1-25.6

### Phase 2: Generics + Ergonomic Surface

- [x] Generic type definitions
- [x] Generic function definitions
- [x] Monomorphization for concrete instantiations
- [x] Type parameter inference at call sites
- [x] No unused-instantiation monomorphization
- [x] `with` Form 1 guarded lowering (`enter`/`enter_mut`)
- [x] `with` Form 2 builder lowering
- [x] `with` Form 3 binding lowering
- [x] `with` Form 4 record update lowering
- [x] `with` dispatch rule
- [x] Non-local control flow transparency inside `with`
- [x] Closure parse forms (`|...| expr` and block form)
- [x] Closure capture analysis
- [x] Closure capture mode inference (move vs borrow)
- [x] Closure escaping classification and restrictions
- [x] Closure codegen (env + function pointer model)
- [x] Pattern variants: literal/variable/wildcard/constructor/nested/or-pattern/guards/bindings
- [x] Exhaustiveness checks
- [x] Unreachable arm usefulness warnings
- [x] `if let` lowering
- [x] Chained `if let` lowering
- [x] Pipeline/backward-application/composition operators lowering
- [x] Field shorthand in struct literals and updates
- [x] Default field value insertion
- [x] Enum variant shorthand contextual resolution
- [x] Auto-generated enum accessors (`is_`, `as_`, `_ref`, `_mut`)
- [x] Tuple patterns/destructuring/nested destructuring/for-loop destructuring
- [x] Optional chaining (`?.`) desugaring and typing
- [x] Default operator (`??`) desugaring/laziness/chaining
- [x] Early-exit `??` form in bindings
- [x] Comprehension desugaring (`for`, multiple `for`, `if`)
- [x] `let ... else` divergence enforcement
- [x] Slice patterns
- [x] Parameter destructuring patterns
- [x] `match` as pipeline stage
- [x] Error declaration lowering
- [x] `error ... from` conversion generation
- [x] `?` lowering on `Result` and `Option`
- [x] Implicit `Ok` wrapping
- [x] Unit elision (`Ok()`, unit defaults)
- [x] Denied patterns checker E0701/E0802/E0801/E0901/E0201/E0601
- [x] `for` loop iterator protocol lowering
- [x] Tail call optimization and `@[tailrec]` verification
- [x] Phase milestone: listed 25.x groups in plan all pass

### Phase 3: Standard Library

- [x] `std.mem` APIs
- [x] `std.fmt` formatting and interpolation backend
- [x] `std.io` reader/writer/stdio APIs
- [x] `std.fs` file and directory APIs
- [x] `std.string` string/strview APIs
- [x] `std.collections` (`Vec`, `HashMap`, `HashSet`)
- [x] HashMap convenience methods (`update`, `increment`, `decrement`, `append`)
- [x] `Option` combinators
- [x] `Result` combinators
- [x] `ContextError` and `.context()` behavior
- [x] Collection combinators (`sequence`, `traverse`)
- [x] `std.time` APIs
- [x] `std.math` libm wrappers
- [x] `std.process` args/env/command APIs
- [x] `std.random` RNG APIs
- [x] `std.hash` hasher/default hasher
- [x] Additional collections (`SlotMap`, `Handle`, `BTreeMap`)
- [x] `std.thread` wrappers
- [x] `std.sync` primitives
- [x] `std.alloc` arena/pool APIs
- [x] Generator lowering readiness for stdlib usage
- [x] Phase milestone: 25.8, 25.15, 25.16, 25.22, 25.97, 25.98

### Phase 4: Concurrency

- [x] Fiber context switching implementation (assembly or fallback)
- [x] Fiber pool and stack reuse
- [x] Stack growth strategy limits
- [x] M:N scheduler behavior and work stealing
- [x] Runtime linkage/availability rules
- [x] `async fn` lowering to fiber + `Task[T]`
- [x] `.await` suspension/resume lowering
- [x] `async:` block lowering/capture semantics
- [x] `spawn` detached semantics and return type
- [x] `Task[T]` `@[must_use]` enforcement
- [x] Task ephemerality propagation from captures
- [x] Task cancellation flag + unwind-on-next-await behavior
- [x] `async scope` tracked-task completion/cancellation behavior
- [x] `select await` first-ready behavior
- [x] Channel implementation (bounded/unbounded MPMC)
- [x] `Send`/`Sync`/`ScopedSend` boundary enforcement
- [x] `std.net` sockets and DNS + scheduler integration
- [x] `std.signal` wrapper behavior
- [x] Phase milestone: 25.17 and 25.18

### Phase 5: Traits

- [x] Trait definition parsing (required/default methods)
- [x] Impl block parsing
- [x] Orphan/coherence rule enforcement
- [x] Method resolution order (inherent then trait)
- [x] Trait bounds in signatures
- [x] Multiple bounds and where-clauses
- [x] Bounds enforced at call sites and in bodies
- [x] Syntax trait wiring (`Iter`, `Scoped`, `ScopedMut`, `Index`, `Try`, ops, `Drop`, `Display`, `Debug`)
- [x] Dynamic dispatch (`dyn Trait`) and vtables
- [x] Object safety diagnostics
- [x] `Box[dyn Trait]` and `&dyn Trait`
- [x] Devirtualization when concrete type known
- [x] Stdlib trait impl coverage (`Vec`, `HashMap`, `Result`, guards, `String`)
- [x] Phase milestone: 25.10 and 25.11

### Phase 6: Polish

- [x] `comptime if` and `comptime for`
- [x] Type-as-object API (`T.fields()`, `T.variants()`, `T.size()`, etc.)
- [x] `TypeInfo` equivalent APIs in non-generic contexts
- [x] Comptime cascade inside `comptime fn`
- [x] `comptime fn` constraints (deterministic, no I/O)
- [x] `comptime_error`
- [x] Generated code re-enters normal checking pipeline
- [x] `@[derive(...)]` integration
- [x] `@[derive(all)]` conservative trait derivation
- [x] `@[derive(Builder)]` generated API + required/optional field handling
- [x] `with fmt` canonical formatting and comment preservation
- [x] `with doc` docs generation/cross-links/example extraction
- [x] LSP: goto-def/find-refs/hover/completion/diagnostics/rename
- [x] `with repl` JIT execution path
- [x] MIR-level optimizations (devirtualization, escape analysis, dead field elimination, move elision)
- [x] `c_import` macro translation and diagnostics improvements
- [x] `c_import` cache invalidation improvements
- [x] `with migrate rust` transform coverage
- [x] `with migrate zig` transform coverage
- [x] `with migrate swift` transform coverage
- [x] `with migrate` CLI modes (`--check`, `--diff`)
- [x] Phase milestone: 25.40, 25.95, 25.96

## B) Specification Section Coverage (Behavioral)

### Core semantics

- [x] Section 2 Values and Ownership
- [x] Section 3 References and Borrowing
- [x] Section 4 Types
- [x] Section 5 Ephemeral Types
- [x] Section 6 Handles and Generational Arenas
- [x] Section 7 `with` scoped access and dispatch/control-flow semantics
- [x] Section 8 Memory Management model (no GC/no implicit RC/allocators)
- [x] Section 9 Functions and Expressions
- [x] Section 10 Error Handling
- [x] Section 11 Traits
- [x] Section 12 Closures and Escaping
- [x] Section 13 Iteration and Collection Operations
- [x] Section 14 Concurrency
- [x] Section 15 Strings
- [x] Section 16 FFI and C Interoperability
- [x] Section 17 Metaprogramming
- [x] Section 18 Modules and Packages
- [x] Section 19 Safety Boundaries
- [x] Section 20 Performance Guarantees

### Denied patterns and normative rule sections

- [x] Section 20b Denied Patterns (all six diagnostics)
- [x] Section 21 Borrow Checker Rules (including implicit-drop-as-use behavior)
- [x] Section 22 Ephemeral Type Rules
- [x] Section 23 `with` Block Semantics
- [x] Section 24 `async`/`.await` equivalence + `no_runtime` gate

## C) Implementation Notes Coverage (Compiler/Runtime Invariants)

- [x] 1 Compiler architecture pipeline and compilation unit model
- [x] 2 Borrow checker algorithm/data model/NLL/overlap/cross-function boundaries
- [x] 3 Ephemeral checker rules including task ephemerality
- [x] 4 `with` lowering forms and non-local return implementation
- [x] 5 Generator compilation/state machine properties
- [x] 6 `async` lowering (`async fn`, `.await`, `async:` blocks, scopes, spawn, may-suspend, `no_runtime`)
- [x] 7 Fiber runtime architecture/scheduler/fiber states
- [x] 8 Fiber stack strategy and borrow-checker integration
- [x] 9 Pattern match decision trees/exhaustiveness/or-pattern handling
- [x] 10 Record update lowering including Drop interaction
- [x] 11 Tail call optimization verification/lowering
- [x] 12 Error type lowering
- [x] 13 Monomorphization strategy/code-size/perf
- [x] 14 Backend mapping and fiber runtime backend integration
- [x] 15 Diagnostic quality + key scenarios + denied-pattern diagnostics
- [x] 16 `c_import` architecture/preprocess/parser/type mapping/macro/caching/errors
- [x] 17 Stdlib implementation architecture/priorities/scoped integration/testing/docs
- [x] 18 Default field values algorithm and record-update interaction
- [x] 19 Enum accessor generation rules/properties
- [x] 20 Tuple representation/properties + unit elision implementation
- [x] 21 Implicit `Ok` wrapping algorithm/implementation
- [x] 22 `defer` lowering rules and restrictions
- [x] 23 `select await` desugaring/fairness/loop composition
- [x] 24 Channel architecture/properties/fiber-aware blocking
- [x] 25 `ScopedSend` hierarchy, auto-impl, boundary enforcement
- [x] 26 `comptime` evaluator/type API/unrolling/deferred-branch checking/derive integration
- [x] 27 Closure classification and lowering (escaping/non-escaping/disjoint capture)
- [x] 28 Distinct type representation/lowering
- [x] 29 String auto-promotion rules and non-trigger contexts + C-string literals
- [x] 30 Object safety checks and `Box[dyn Trait]` exception
- [x] 31 FFI stack switching + `@[ffi_stack]` + no-suspend-in-C-frames
- [x] 32 Attribute system (`@[no_await_guard]`, `cfg`, built-ins)
- [x] 33 Extension block coherence
- [x] 34 Normative rule 21.7 implicit-drop-as-use implementation
- [x] 35 Auto-dereferencing algorithm
- [x] 36 Auto-referencing rules and method-call behavior
- [x] 37 Implicit trait object coercion algorithm
- [x] 38 Chained `if let` desugaring/properties
- [x] 39 `@[derive(Builder)]` generated code + required/optional fields
- [x] 40 HashMap convenience method implementation
- [x] 41 Raw pointer `.as_option()` implementation
- [x] 42 Task cancellation as unwinding (no error-type infection)

## D) Specification Part III Test Cases (Must All Exist and Pass)

- [x] 25.1 Ownership and Moves (Section 2)
- [x] 25.2 References and Second-Class Rule (Section 3)
- [x] 25.3 Returning References (Section 3.4)
- [x] 25.4 NLL Borrow Scoping (Section 3.5)
- [x] 25.5 Disjoint Field Borrowing (Section 3.6)
- [x] 25.6 Ephemeral Types (Section 5)
- [x] 25.7 `with` Blocks (Section 7)
- [x] 25.8 Handles and SlotMap (Section 6)
- [x] 25.9 Error Handling (Section 10)
- [x] 25.10 Traits and Coherence (Section 11)
- [x] 25.11 FFI and `c_import` (Section 16)
- [x] 25.12 Tail Recursion (Section 9.2)
- [x] 25.13 Partial Application (Section 9.4)
- [x] 25.14 Pattern Matching (Section 9.7)
- [x] 25.15 Collection Operations (Section 13.3)
- [x] 25.16 Generators (Section 13.4)
- [x] 25.17 Async/Await (Section 14)
- [x] 25.18 Async Calling Is Unrestricted (Section 14.3)
- [x] 25.19 Numerics (Section 4.2)
- [x] 25.20 Exhaustiveness (Section 9.7)
- [x] 25.21 Record Update Syntax (Section 4.3)
- [x] 25.22 Option/Result Combinators (Section 10.3, 10.4)
- [x] 25.23 Ranges (Section 4.7)
- [x] 25.24 Function Composition (Section 9.6)
- [x] 25.25 Parameter Patterns (Section 9.7)
- [x] 25.26 Enum Constructor Imports (Section 4.4, 18.2)
- [x] 25.27 Comprehensions (Section 13.6)
- [x] 25.27b Implicit Ok Wrapping (Section 4.9)
- [x] 25.28 sequence / traverse / transpose (Section 10.5)
- [x] 25.29 Backward Application (Section 9.6)
- [x] 25.30 Denied Patterns (Section 20b)
- [x] 25.31 Copy Safety (Section 2.3)
- [x] 25.32 Task Ephemerality (Section 14.20)
- [x] 25.33 Postfix `.await` (Section 14.5)
- [x] 25.34 Field Shorthand (Section 4.3)
- [x] 25.35 Enum Variant Shorthand (Section 4.4)
- [x] 25.36 Tuples (Section 4.8)
- [x] 25.37 Optional Chaining (Section 10.3)
- [x] 25.38 Default Operator `??` (Section 10.4)
- [x] 25.39 Destructuring Let (Section 9.7)
- [x] 25.40 Derive (Section 11.8)
- [x] 25.41 Ephemeral Structs (Section 5.5)
- [x] 25.42 Default Field Values (Section 4.3)
- [x] 25.43 Error Context (Section 10.6)
- [x] 25.44 String Literals (Section 15.3)
- [x] 25.45 Unit Elision (Section 4.8)
- [x] 25.46 Implicit Iteration (Section 13.5)
- [x] 25.47 Collection Length Methods (Section 18.6)
- [x] 25.48 Unwrap and Expect (Section 10.6)
- [x] 25.49 Unreachable, Todo, Assert_matches (Section 18.6)
- [x] 25.50 Builder Block Return (Section 7.2)
- [x] 25.51 Select Await (Section 14.9)
- [x] 25.52 Enum Accessor Methods (Section 4.4)
- [x] 25.53 Scoped Task Tracking (Section 14.8)
- [x] 25.54 By-Value Self Method Chaining (Section 9.5)
- [x] 25.55 Disjoint Closure Captures (Section 3.6)
- [x] 25.56 Select Await with Let-Else in Branches (Section 14.9)
- [x] 25.57 Drop in Prelude (Section 18.2)
- [x] 25.58 Await Inside Iterators (Section 14.12)
- [x] 25.59 Async Blocks (Section 14.6)
- [x] 25.60 Reference Pattern Ergonomics (Section 9.7)
- [x] 25.61 By-Value Drop (Section 2.4)
- [x] 25.62 Ephemeral Task Cancellation (Section 14.7)
- [x] 25.63 ScopedSend (Section 14.15)
- [x] 25.64 Partial Move from Drop Types (Section 2.4)
- [x] 25.65 No References Across Yield (Section 13.4)
- [x] 25.66 Comptime Unreachable Exemption (Section 20b.6)
- [x] 25.67 May-Suspend Analysis (Section 14.3, Invariant 5)
- [x] 25.68 FFI Callback No-Suspend (Section 14.18)
- [x] 25.69 With Type-Based Dispatch (Section 7.5)
- [x] 25.70 Iter One-Implementation Rule (Section 13.2)
- [x] 25.71 Operator One-Impl Rule (Section 11.7)
- [x] 25.72 Fair Select Await (Section 14.10)
- [x] 25.73 Defer Control Flow Restriction (Section 2.4)
- [x] 25.74 Spawn Fire-and-Forget (Section 14.7)
- [x] 25.75 Iterator Borrowing (Section 13.2)
- [x] 25.76 Channel Send Requires Send (Section 14.14)
- [x] 25.77 Ephemeral Owned Passing Restriction (Section 14.21)
- [x] 25.78 Disjoint Slice Operations (Section 3.4)
- [x] 25.79 Optional Chaining Type-Aware Desugaring (Section 10.3)
- [x] 25.80 Drop Field Moves (Section 2.4)
- [x] 25.81 HashMap Lookup Borrowing (Section 13.2)
- [x] 25.82 NLL-Based @[no_await_guard] (Section 7.9)
- [x] 25.83 Object Safety (Section 11.3)
- [x] 25.84 C-String Literals (Section 15.3)
- [x] 25.85 Record Update Drops Overwritten Fields (Section 4.3)
- [x] 25.86 Ephemeral Task OS Thread Restriction (Section 14.7)
- [x] 25.87 String Literal Auto-Promotion (Section 15.3)
- [x] 25.88 FFI Direct Call (Section 16.1)
- [x] 25.89 With Type-Based Guard Inference (Section 7.1)
- [x] 25.90 Auto-Dereferencing (Section 3.7)
- [x] 25.91 Auto-Referencing (Section 3.8)
- [x] 25.92 Implicit Trait Object Coercion (Section 3.9)
- [x] 25.93 Enum Auto-Generated _ref and _mut (Section 4.4)
- [x] 25.94 Chained if let (Section 9.7)
- [x] 25.95 Comptime Cascade (Section 17.4)
- [x] 25.96 derive(Builder) (Section 11.8)
- [x] 25.97 Raw Pointer .as_option() (Section 16.1)
- [x] 25.98 HashMap Convenience Methods (Section 13.3)

## E) Test Quality Gates

- [x] Positive behavior tests for all implemented features
- [x] Negative tests for all denied/invalid feature uses
- [x] Diagnostics snapshot tests (error code + span + key message)
- [x] AST/MIR/lowering snapshot tests where syntax sugar desugars
- [x] Runtime integration tests for async, channels, cancellation, and FFI
- [x] Cross-platform tests (Linux/macOS/Windows) for runtime and `c_import`
- [x] No XFAIL tests in final suite
