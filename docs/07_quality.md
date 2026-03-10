# The With Compiler: Quality Pass Manifesto

The compiler reached fixpoint on March 6, 2026. Stage 2 and Stage 3
are byte-identical. The bootstrap is dead. Everything from here is
the compiler improving itself.

This document governs the quality pass — the systematic rewrite of
the compiler from "code that works" to "code that is right." Every
decision in this pass is guided by the principles below.

---

## The Prime Directive

**If the compiler already knows it, don't make the developer type it.**

This is the language's design philosophy. It is also the compiler's
implementation philosophy. If the type system knows a fact, don't
re-derive it in codegen. If sema resolved a name, don't resolve it
again in MIR lowering. If a function's return type is known, don't
store a sentinel and guess later. Information flows forward through
the pipeline. It never flows backward. It is never re-invented.

---

## Principles

### 1. The compiler eats its own food.

The self-hosted compiler is the most important With program in
existence. It must be written in idiomatic With. If a pattern is
ugly in the compiler, it will be ugly in every user's code.

This means:

- `fn NK_BINARY -> i32: 25` becomes a `NodeKind` enum with
  discriminant values and exhaustive matching.
- Integer constant functions become `const` declarations.
- `if kind == NK_BINARY()` becomes `match kind` with `.Binary ->`.
- Parallel arrays indexed by raw `i32` become arrays indexed by
  `distinct` handle types.
- Pipelines replace nested function calls where data flows
  linearly.
- `it` replaces `|x| x.field` in closures.
- `?` replaces manual error matching.

If the compiler can't be written idiomatically in With, something
is wrong with the language, not the compiler. Every awkwardness
found here is a language design bug to be fixed.

### 2. One source of truth per fact.

The bootstrap compiler's worst architectural flaw was type
re-inference. Sema resolved types. Codegen re-inferred them from
LLVM values. When inference disagreed, the compiler crashed at
LLVM verify time — far from the actual bug.

In the quality pass:

- Sema produces typed information. MIR consumes it. Codegen
  consumes MIR. No phase re-derives what a previous phase computed.
- The intern pool is the single owner of type identity. `Vec[i32]`
  has one `TypeId` everywhere. No pointer-identity caches, no
  parallel tracking maps, no `vec_cache_map`.
- `Zcu` is the single owner of pipeline state. No `Driver` holding
  a second copy. No fields duplicated across modules.
- Every `i32` fallback — every place the compiler says "I don't
  know the type, assume `i32`" — becomes a hard compile error.
  Unknown types are errors, not defaults.

### 3. Every stage earns its existence.

The pipeline is:

```
Source → Lexer → Parser → Resolve → Sema → MIR → Backend → Link
```

Each stage exists because it transforms information in a way the
previous stage cannot:

- **Lexer:** bytes → tokens. Handles encoding, whitespace
  significance, keywords.
- **Parser:** tokens → AST. Handles grammar, precedence, nesting.
- **Resolve:** AST → named AST. Handles imports, module graph,
  name binding.
- **Sema:** named AST → typed AST. Handles types, traits,
  generics, borrow rules.
- **MIR:** typed AST → desugared CFG. Handles sugar elimination,
  drop insertion, control flow flattening.
- **Backend:** MIR → output. LLVM IR for optimized native code.
  C for cross-compilation. Both read the same MIR.
- **Link:** objects → binary. Handles runtime selection, platform
  specifics.

If a stage cannot justify itself in one sentence, it should be
merged with its neighbor. If a stage is doing work that belongs
to another stage, move it.

### 4. Phase boundaries are contracts.

Each stage produces a defined output and consumes a defined input.
The contract is:

- **What you receive:** fully validated by the previous stage.
  You may assume it. You do not re-check it.
- **What you produce:** fully validated before handoff. The next
  stage may assume it.
- **What you do not touch:** anything owned by another stage.
  Sema does not emit LLVM. Codegen does not resolve names.
  The parser does not type-check.

If a bug manifests in codegen but the root cause is in sema,
fix sema. Do not patch codegen. Principle 2 depends on this
discipline — if codegen compensates for sema's gaps, you have
two sources of truth.

### 5. Determinism is structural, not aspirational.

The compiler produces byte-identical output for identical input.
This is not a test — it is an invariant enforced by data
structure choice:

- All maps are ordered. No `HashMap` in the compiler. Use
  `OrderedMap` or index-based arrays.
- All iteration is deterministic. No iteration over pointer
  values, memory addresses, or hash buckets.
- All intern pool lookups produce the same `TypeId` for the
  same semantic type, regardless of insertion order.
- Fixpoint is checked on every change. If stage2 != stage3,
  the change is rejected.

Nondeterminism in a self-hosting compiler is a silent corruption
vector. A nondeterministic stage2 produces a nondeterministic
stage3, and fixpoint passes by coincidence. Determinism is the
only way to trust the self-hosting chain.

### 6. Data lives in arrays, not trees.

The compiler uses SoA (Struct of Arrays) indexed by integer
handles. Not pointer trees. Not heap-allocated node objects.

- AST nodes live in `AstPool` — parallel arrays indexed by
  `NodeId`.
- Types live in the intern pool — indexed by `TypeId`.
- MIR basic blocks, statements, operands — all parallel arrays
  indexed by `i32` handles (to be rewritten as `distinct` types).

This gives: cache-friendly traversal, trivial serialization,
no use-after-free on nodes, no garbage collection, and natural
arena semantics (free the whole pool at phase end).

Handle types must be `distinct`:

```
type NodeId = distinct i32
type TypeId = distinct i32
type BlockId = distinct i32
```

Not raw `i32`. The type system prevents accidentally passing a
`NodeId` where a `TypeId` is expected.

### 7. Generic types are distinct types.

`Vec[i32]` and `Vec[str]` are different types. They have different
methods, different trait implementations, different memory layouts.
The type table represents them as distinct entries keyed by
`(base_type, type_args)`.

The quality pass adds `GenericInst` to `TypeKind`. Sema produces
fully instantiated types. Codegen never re-infers element types
from LLVM values. The parallel caches (`vec_cache_map`,
`vec_local_types`, `vec_elem_types`) are deleted.

Type substitution — replacing `T` with `i32` in `Option[T]` to
get `Option[i32]` — is a single function used by trait resolution,
method lookup, and for-loop desugaring. It lives in one place.

### 8. Errors are values, silence is a bug.

Every error the compiler detects must be reported. Silent error
swallowing — where sema detects a problem, returns a sentinel,
and codegen later crashes on the sentinel — is the most common
class of compiler bug.

Rules:

- If a phase detects an error, it emits a diagnostic immediately.
- If a phase cannot continue after an error, it returns a
  `Poisoned` node, not a sentinel integer.
- No function may return `0` to mean "I don't know." Use
  `Result[TypeId, Error]` or `Option[TypeId]`.
- The diagnostic must include: what's wrong, where it is, and
  (where possible) how to fix it.

### 9. The prelude is a normal module.

User-facing names (`println`, `map`, `filter`, `Vec`, `Result`)
are defined in `lib/std/` and made ambient by
`lib/std/prelude.w`. They are not hardcoded in sema. They are
not special-cased in codegen.

The quality pass removes all hardcoded symbol name lists from
sema and codegen. `is_builtin_fn`, `is_builtin_value`, and
name-based dispatch are deleted. If `println` is not imported,
it does not exist.

The only names hardcoded in the compiler are language primitives
that cannot be defined in With: primitive types, `c_import`,
`comptime`, operator desugaring hooks, and `it`.

### 10. The C backend is a first-class citizen.

The compiler has two backends: LLVM (optimized native code) and
C (portable, cross-compilable). Both read the same MIR. Both
produce correct output. Neither is a toy.

The C backend enables:

- Cross-compilation from a single machine.
- Universal bootstrap (any C compiler can build With).
- Debugging with standard C tools (ASan, gdb, valgrind on x86).
- Auditable output (you can read the generated C).

If a MIR construct cannot be translated to C, that is a design
flaw in the MIR, not a limitation of the C backend.

### 11. Files have a complexity budget, not a line count.

No file should be so large that its API cannot be held in one
person's head. For most files, this means 1,000–5,000 lines.
Some files (a parser for 60+ node types) may be larger. Some
files (a single data structure) should be smaller.

The rule is not "split at 5,000 lines." The rule is: if you
open a file and can't understand what it does in 60 seconds of
scanning, it's too big or too coupled. Split by responsibility,
not by line count.

### 12. Measure, then optimize.

Track self-compile time (`with-stage2 build src/main.w`) in CI.
Record it on every commit. A 0.5% regression per change becomes
a 10x slowdown over a year. One number, tracked automatically,
prevents this.

When optimizing: profile first. Use Instruments (Time Profiler),
`sample`, or Tracy integration. Never guess where time is spent.
Compiler hot paths are counterintuitive — the bottleneck is
almost never where you think it is.

### 13. Tests verify contracts, not implementations.

Each phase has a dump flag (`--dump-tokens`, `--dump-ast`,
`--dump-resolved`, `--dump-typed`, `--dump-mir`). Tests verify
the dump output at each phase boundary. When something breaks,
you immediately know which phase produced wrong output.

Test categories:

- **Phase output tests.** Does the lexer produce the right
  tokens? Does the parser produce the right AST? Does MIR
  lowering produce the right basic blocks?
- **Error message tests.** Does a specific mistake produce a
  specific diagnostic? If you change an error message, the test
  should break — that's intentional, so you review the change.
- **Fixpoint tests.** Does stage2 == stage3? Run on every
  compiler change.
- **Round-trip tests.** Does `--emit-c` → C compiler → run
  produce the same output as LLVM backend → run?

Tests are not afterthoughts. A feature without a test does not
exist.

### 14. Reserve syntax before you need it.

Adding a keyword after release is a breaking change. The quality
pass reserves all keywords and syntax forms that are planned but
not yet implemented:

- `const` (named compile-time constants)
- `where` (complex trait bounds)
- `errdefer` (error-path cleanup)
- `move` (explicit closure capture)
- `const` in generic params (const generics)
- `it` (implicit closure parameter)

The compiler rejects these with "reserved for future use" until
the feature is implemented. No user code can depend on these
being valid identifiers.

### 15. The seed is sacred.

The seed binary (`src/main`) is the root of trust for the entire
self-hosting chain. A corrupted seed produces a corrupted stage1,
which produces a corrupted stage2 — and fixpoint passes because
the corruption is self-consistent.

Rules:

- The seed is updated only from a fixpoint-verified stage2.
- The seed update is a deliberate act with its own commit.
- The previous seed is preserved as a release artifact.
- When the C backend lands, `with_compiler.c` replaces the
  binary seed — auditable, platform-independent, version-
  controllable.

---

## The Quality Pass: What Changes

### Phase 1: Idiomatic Rewrite

Rewrite compiler source to idiomatic With. This is the highest
priority because it proves the language works and finds bugs
that only surface in real code.

- Integer constant functions → `const` declarations and
  discriminant enums.
- Raw `i32` handles → `distinct` handle types.
- `if kind == NK_X()` chains → `match` on enums.
- Manual error propagation → `?` operator.
- Nested function calls → pipelines where data flows linearly.
- Verbose closures → `it` where single-parameter.
- C-style loops → `for ... in` with iterators.

### Phase 2: Type System Completion

Fix sema's generic type erasure. This is the single largest
architectural gap.

- Add `GenericInst` to `TypeKind`.
- Instantiation cache keyed by `(base_type, type_args)`.
- Fix `resolve_type_expr` (stop returning 0).
- Type substitution function.
- Trait/impl resolution with full instantiation keys.
- Delete codegen's parallel type tracking.

### Phase 3: Pipeline Ownership

Complete the `src/compiler/*` ownership migration. Delete `Driver`.

- `Zcu` owns all pipeline state.
- `main.w` talks to `Compilation`, not `Driver`.
- Both backends consume MIR from `Zcu`.
- Link logic lives in `Link.w`.
- No semantic or codegen logic outside `src/compiler/*`.

### Phase 4: Hardcode Removal

Remove all non-primitive hardcoded symbol names.

- Delete `is_builtin_fn`, `is_builtin_value` in sema.
- Delete name-based dispatch in codegen.
- Wire the prelude as the sole source of ambient names.
- Verify: `--no-prelude` makes `println` unavailable.

### Phase 5: C Backend

Add `--emit-c` for cross-compilation and universal bootstrap.

- `src/CCodegen.w`: MIR → C translation.
- `fiber_asm_x86_64.s`: x86_64 stack switching.
- `with_runtime.h` / `with_runtime.c`: portable C runtime.
- Ship `with_compiler.c` as the new seed.

### Phase 6: Tooling

Ship the tools that make the language usable.

- `with fmt`: one style, no configuration, non-negotiable.
- `with test`: zero-config test runner with `@[test]` functions.
- `with bench`: zero-config benchmarking.
- Error messages with suggestions and source locations.

---

## Non-Negotiables

These are not guidelines. They are requirements. Code that
violates them does not merge.

1. **Fixpoint holds.** stage2 == stage3 after every change.
2. **Tests pass.** No exceptions, no "known failures" without
   a tracking issue.
3. **No `i32` fallbacks.** Unknown types are errors, not defaults.
4. **No hardcoded user-facing names.** If it's not in the prelude
   or explicitly imported, it doesn't exist.
5. **Deterministic output.** Same input → same binary, always.
6. **Every error has a location.** No "error: something went wrong"
   without a file and line.

---

## When Is The Quality Pass Done?

The quality pass is done when:

1. The compiler source reads as idiomatic With — enums, const,
   match, pipelines, distinct types, `it`.
2. `Vec[i32] != Vec[str]` is enforced in sema, not worked around
   in codegen.
3. `Driver` is deleted.
4. `--emit-c` cross-compiles the compiler for four targets from
   one machine.
5. `with fmt` exists and the compiler source passes it.
6. A new contributor can clone, build, test, and submit a fix
   in under 30 minutes using only CONTRIBUTING.md.

None of these are aspirational. All of them are measurable.
All of them are achievable. The compiler already works.
Now we make it right.