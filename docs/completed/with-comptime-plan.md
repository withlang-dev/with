# With Comptime Implementation Plan

This plan is based on:

- `docs/with-comptime-spec.md`
- `docs/zig_comptime_spec.md`
- selective reading of Zig's current comptime implementation in `.reference/zig`
- the current self-hosted With compiler in `src/`

The goal is not to copy Zig wholesale. The goal is to implement the With spec cleanly in the self-hosted compiler, while borrowing only the architectural parts of Zig that materially reduce risk.

## 1. What Exists Today

The current self-hosted compiler already has surface-level comptime syntax and several ad hoc compile-time behaviors, but it does not yet have a real comptime execution phase.

### 1.1 Parser and AST

- `src/Token.w` already has `TK_KW_COMPTIME` and `TK_KW_CONST`.
- `src/Ast.w` already has:
  - `NodeKind.NK_COMPTIME`
  - `NodeKind.NK_COMPTIME_ERROR`
  - `FnFlags.COMPTIME`
- `src/Parser.w` already supports:
  - `comptime fn ...`
  - `comptime expr`
  - `comptime if ...` via `NK_COMPTIME(NK_IF_EXPR(...))`
  - `comptime for ...` via `NK_COMPTIME(NK_FOR(...))`
  - `const` declarations and bindings by desugaring them to immutable `let` plus an `NK_COMPTIME` wrapper
- `@[derive(...)]` metadata is already parsed and stored in `AstPool.type_meta`.

### 1.2 Sema

- `src/Sema.w` and `src/SemaCheck.w` track `in_comptime_fn`.
- `NK_COMPTIME` is currently type-checked by simply type-checking the inner expression.
- `NK_COMPTIME_ERROR` is typed as `Never`.
- `check_if_expr` still type-checks both branches unconditionally.
- There is no real comptime evaluator.
- There is no semantic enforcement yet for most comptime restrictions from the spec.
- There is no real cascade model beyond the single `in_comptime_fn` flag.

### 1.3 MIR

- `src/MirLower.w` has a tiny integer-only `try_eval_const`.
- `NK_COMPTIME` is mostly treated as a wrapper.
- `comptime if` gets a narrow special case during MIR lowering: if the condition is an integer/bool constant, only the taken branch is lowered.
- This is too late and too weak for the spec because dead branches are still sema-checked first.

### 1.4 Codegen

- `src/CodegenTraits.w` has ad hoc evaluators for:
  - integer constants
  - string constants
  - `embed_file(...)`
  - a few `sizeof/alignof` cases
- `src/CodegenDispatch.w` also contains special handling for `embed_file`.
- `@[derive(Clone)]` is currently implemented by direct codegen synthesis, not through comptime-generated AST.

### 1.5 Pipeline

- `src/compiler/Frontend.w` freezes the merged AST before semantic analysis.
- There is no dedicated pass between sema and MIR for comptime execution / AST transformation.
- `src/compiler/Compilation.w` currently does:
  - parse/import expansion
  - sema
  - MIR lowering
  - codegen

### 1.6 Mismatch Against the Spec

Relative to `docs/with-comptime-spec.md`, the self-hosted compiler is missing or incomplete for:

- `comptime:` block parsing
- real comptime evaluation
- proper cascade semantics
- dead-branch elimination before final sema
- `comptime for` AST unrolling
- type introspection (`T.fields()`, `T.variants()`, `T.name()`, `T.size()`, `T.align()`, `T.implements(...)`, `T.is_copy()`)
- dynamic comptime field access (`self.{field.name}`)
- derive-by-comptime rather than hard-coded codegen hooks
- reliable compile-time diagnostics and stack traces
- aggregate freezing / embedding strategy beyond a few special cases

## 2. What to Borrow From Zig

The useful lessons from Zig are architectural, not translational.

### 2.1 Keep

- A distinct typed compile-time value model.
- Explicit comptime load/store rules rather than "just reuse runtime values".
- Branch pruning before later analysis when a condition is comptime-known.
- Strong diagnostics for:
  - runtime values used in forced comptime contexts
  - forbidden side effects
  - escaping references to comptime-only storage

### 2.2 Do Not Copy in v1

Zig's current comptime machinery is deep and expensive:

- `Value.zig` is a fully interned, typed value system.
- `Sema/comptime_ptr_access.zig` handles comptime pointer mutation, reinterpretation, packed-field access, and escape analysis.

With should not try to reproduce that whole stack in the first landing. The v1 plan should stay by-value and pure where possible, and reject cases that would force Zig-level pointer semantics.

## 3. Recommended Architecture

The key design decision is this:

> Do comptime as a typed AST phase, not as a MIR or codegen trick.

That matches the spec and avoids the current "too late" branch-pruning problem.

### 3.1 New Pipeline

Recommended pipeline:

`Source -> Parse/Imports -> Sema #1 -> Comptime Transform -> Sema #2 -> MIR -> Codegen`

Why two sema passes:

- `Sema #1` gives the evaluator type information and symbol tables.
- The comptime pass can then:
  - replace `const X = comptime expr`
  - prune `comptime if`
  - unroll `comptime for`
  - inject generated declarations
- `Sema #2` re-checks the transformed AST so dead branches are truly gone and generated code is treated exactly like handwritten code.

This is the cleanest way to satisfy the spec's "discarded branches are not type-checked" rule.

### 3.2 New Modules

Add at least these new modules:

- `src/ComptimeValue.w`
- `src/ComptimeEval.w`
- `src/ComptimeTransform.w`
- `src/TypeLayout.w` or equivalent shared layout helper

Responsibilities:

- `ComptimeValue.w`
  - tagged compile-time value representation
  - cloning / equality / formatting helpers
- `ComptimeEval.w`
  - tree-walking evaluator over typed AST
  - call frames, local bindings, recursion/step limits
  - evaluator intrinsics
- `ComptimeTransform.w`
  - AST cloning / rewriting
  - branch elimination
  - loop unrolling
  - constant embedding as AST literals / aggregates
- `TypeLayout.w`
  - reusable `size` / `align` queries for sema types
  - cache layout results by `TypeId`

## 4. Core Semantic Decisions

These should be decided up front and implemented consistently.

### 4.1 Canonical v1 Entry Points

Implement these first:

- `comptime fn`
- `comptime expr`
- `comptime if`
- `comptime for`
- `const X = comptime expr`
- `comptime:` block

### 4.2 Keep v1 Small

Do not block the core landing on:

- full comptime pointer mutation semantics
- general `HashMap` / `Vec` return embedding
- fully generic derive-returning-impl support

These belong in later phases.

### 4.3 Restrictions

Inside any forced comptime context, reject:

- extern / FFI calls
- I/O
- network access
- `unsafe`
- `async`, `await`, `spawn`
- mutable global writes
- values containing references/pointers that cannot be embedded safely

This restriction set should be enforced in sema, not only during evaluation.

## 5. Phase Plan

## Phase 0: Lock the v1 Semantic Boundary

Purpose: prevent scope creep.

Deliverables:

- mark the supported v1 feature set in code comments and tests
- explicitly defer full pointer/ref escape semantics
- explicitly defer `HashMap` / `Vec` result freezing
- explicitly defer generic derive-returning-impl if it complicates the first landing

Recommended v1 result types:

- integers
- floats
- bools
- strings
- tuples
- fixed arrays
- structs of embeddable values
- enums of embeddable values
- `void`

## Phase 1: Make Comptime a Real Semantic Context

Files:

- `src/Sema.w`
- `src/SemaCheck.w`
- `src/Parser.w`
- `src/Ast.w`

Changes:

- replace the single `in_comptime_fn` boolean with a more general comptime-context model:
  - inside `comptime fn`
  - inside `NK_COMPTIME(...)`
  - inside declarations marked by `comptime:`
- enforce comptime restrictions during sema:
  - forbidden calls
  - forbidden constructs
  - forbidden global mutation
- keep `comptime_error(...)` as a deferred error expression, but ensure it can be raised by the evaluator with good spans
- add parser support for `comptime:` block
- add any missing AST metadata required to mark declarations coming from a comptime block

Acceptance:

- pure `comptime fn` bodies still type-check
- forbidden side effects now fail in `with check`
- parser accepts `comptime:` blocks

## Phase 2: Build the Evaluator Foundation

Files:

- `src/ComptimeValue.w`
- `src/ComptimeEval.w`

Implement:

- a tagged `ComptimeValue` representation
- evaluator stack frames
- local immutable/mutable slots
- recursion limit
- step budget
- deterministic iteration rules
- source-span-aware error reporting

Initial node support:

- literals
- grouped expressions
- unary ops
- binary ops
- blocks
- `let` / `var`
- assignment
- `if`
- `match`
- `for`
- `while`
- calls to comptime functions
- returns
- `comptime_error`

Do not special-case codegen here. The evaluator should work only with sema + AST + a small runtime-independent helper layer.

Acceptance:

- `comptime` arithmetic works without MIR/codegen hacks
- recursive pure functions can evaluate at compile time
- evaluator diagnostics point at user spans

## Phase 3: Integrate the Comptime Transform

Files:

- `src/ComptimeTransform.w`
- `src/compiler/Frontend.w`
- `src/compiler/Compilation.w`
- `src/compiler/Zcu.w`

Changes:

- run `Sema #1` on the parsed/import-expanded pool
- feed `Sema #1` plus the original frozen pool into `ComptimeTransform`
- clone the AST into a new mutable pool for the transformed program
- perform:
  - `const` / forced comptime expression replacement
  - `comptime if` branch elimination
  - `comptime for` body unrolling
- freeze the transformed pool
- run `Sema #2` on the transformed pool
- store the transformed pool in `Zcu.typed_pool_cache`

Important detail:

Do not mutate the original frozen pool in place. The transform should produce a new canonical post-comptime pool. That avoids sidecar/node-id corruption and makes the second sema pass straightforward.

Acceptance:

- dead comptime branches are absent before MIR lowering
- MIR lowering no longer needs to decide which comptime branch survives
- transformed AST can be dumped and inspected

## Phase 4: Remove Ad Hoc MIR and Codegen Evaluation

Files:

- `src/MirLower.w`
- `src/CodegenTraits.w`
- `src/CodegenDispatch.w`

Changes:

- remove the current `try_eval_const`-driven ownership of comptime semantics from MIR
- keep only backend-oriented constant emission helpers
- move `embed_file`, string folding, and integer folding to the comptime evaluator where they belong
- make MIR and codegen consume the transformed AST rather than re-deciding comptime behavior

Acceptance:

- `NK_COMPTIME` is no longer a semantic decision point in MIR/codegen
- backend helpers only emit already-resolved values

## Phase 5: Type Introspection and Type-as-Object API

Files:

- `src/ComptimeEval.w`
- `src/SemaCheck.w`
- `src/TypeLayout.w`
- possibly `src/Ast.w` / `src/Parser.w` if new syntax is required

Implement:

- `T.fields()`
- `T.variants()`
- `T.name()`
- `T.size()`
- `T.align()`
- `T.implements(Trait)`
- `T.is_copy()`
- `TypeInfo.*` equivalents for non-generic contexts if kept by the spec

Notes:

- `size` / `align` should be computed through a shared layout helper, not by constructing a whole codegen pass ad hoc.
- `implements(...)` should reuse sema's existing trait-selection logic.
- `is_copy()` should reuse the existing copy analysis already present in sema.

Acceptance:

- current docs examples using `T.name()` and `T.is_copy()` become meaningful
- ECS-style registration checks are possible without backend hacks

## Phase 6: Computed Field Access for Generated Code

The spec depends on `self.{field.name}`. The current self-hosted AST does not have first-class support for computed field access.

Files:

- `src/Ast.w`
- `src/Parser.w`
- `src/SemaCheck.w`
- `src/ComptimeTransform.w`

Implement either:

- a dedicated AST form for computed field access, or
- a transform-only representation that rewrites it away before final sema

Recommendation:

- parse and represent computed field access explicitly
- resolve it during the comptime transform into ordinary `NK_FIELD_ACCESS`

That keeps the post-transform program simple and normal.

Acceptance:

- field-name-driven generated code can compile to ordinary field accesses

## Phase 7: Derive Through Comptime, Not Hard-Coded Codegen

This is the hardest semantic extension because the spec wants comptime to generate declarations, not only values.

Files:

- `src/ComptimeTransform.w`
- `src/Ast.w`
- `src/Parser.w`
- `src/SemaDecl.w`
- `src/Codegen.w`
- `src/CodegenDispatch.w`

Recommended rollout:

1. Keep the current hard-coded derive paths working during the core comptime landing.
2. Add a generated-declaration artifact model to the comptime transform.
3. Lower `@[derive(Trait)]` by:
   - resolving `derive_trait`
   - invoking it in comptime
   - splicing the generated `impl` / helper declarations into the transformed AST
4. Only then retire hard-coded derive synthesis trait-by-trait.

Why staged:

- returning declaration fragments is materially more complex than returning scalar/aggregate values
- it should not block the correctness of core comptime execution

## Phase 8: Intrinsics and File Embedding

Files:

- `src/ComptimeEval.w`
- `src/SemaCheck.w`

Move or formalize:

- `embed_file(path)`
- `src()`
- magic constants if they remain part of the spec

Rules:

- `embed_file` only in forced comptime contexts
- path resolution relative to the declaring source file
- deterministic diagnostics when the file is missing

Acceptance:

- existing `embed_file` behavior no longer depends on codegen-only ad hoc logic

## Phase 9: Aggregate Freezing and Dynamic Collections

This is the first phase that should touch `Vec` / `HashMap` result embedding.

Recommendation:

- do not freeze internal runtime layouts directly
- if `Vec` / `HashMap` results must cross into runtime, emit reconstruction code from a constant description

Preferred strategy:

- freeze as arrays/struct literals of primitive data
- reconstruct at startup or at first use

Do not:

- serialize the exact in-memory layout of runtime hash tables in v1

That is fragile and will create long-term ABI debt.

## 6. Testing Plan

Add or expand tests in `test/behavior` and targeted parser/sema corpora for:

- pure comptime arithmetic
- recursive comptime functions
- `comptime if` branch elimination
- `comptime for` unrolling
- cascade semantics inside `comptime fn`
- forbidden I/O / extern / unsafe / async in comptime
- type-object APIs
- `comptime_error`
- `embed_file`
- generated field access
- derive-generated code once Phase 7 lands

Also add stage-safety gates after each major phase:

- `make build`
- `make smoke`
- `make fixpoint`
- `./out/bin/with-stage2 check src/main.w`

## 7. Order of Implementation I Recommend

This is the safest sequence:

1. Phase 1: semantic comptime context and restrictions
2. Phase 2: evaluator foundation
3. Phase 3: two-pass sema + AST transform
4. Phase 4: delete MIR/codegen comptime ownership
5. Phase 5: type introspection
6. Phase 6: computed field access rewrite
7. Phase 8: formalize intrinsics
8. Phase 7: derive through generated declarations
9. Phase 9: aggregate freezing / runtime reconstruction

This order gets the core language model correct before touching the highest-risk declaration-generation features.

## 8. Main Risks

- Dead branches are currently type-checked too early. If the two-sema-pass structure is skipped, the spec will not be met.
- AST rewriting after freeze must produce a new pool; in-place mutation will make sidecar state brittle.
- `T.size()` / `T.align()` need a reusable layout query path, not a hidden dependency on full codegen.
- Generated declarations for `@[derive]` are a different class of output than normal constant values and need an explicit artifact model.
- Determinism matters. Any comptime container iteration used for code generation must be ordered deterministically.

## 9. Bottom Line

The correct shape for With comptime is:

- typed AST evaluator
- explicit compile-time value model
- AST transform before final sema/MIR
- generated code rechecked as normal With code

The current self-hosted compiler already has the syntax scaffolding and several useful special cases, but those special cases should be treated as migration aids, not the foundation. The real foundation should be a dedicated comptime phase inserted between semantic analysis and lowering, with a second sema pass over the transformed program.
