# Self-Hosting the With Compiler

## Architecture-First Execution Plan

**Status:** Wave 11 parity passes for the current corpus. Driver/CLI/link/c_import behavior is implemented in self-host with deterministic harness coverage (`processed=30`, `failures=0`, `known_divergences=2`) and coverage verification (`processed=9`). Accepted Wave 11 divergences are macro-path checks where self-host is correct and Stage0 remains behind: `check|test/wave11/cases/c_import_macro_constants_ok.w` and `check|test/wave11/cases/c_import_macro_function_like_ok.w`. Wave 8 keeps explicit `KNOWN_DEBT`: borrow checking behavior is currently Sema-integrated and must be rewritten as a MIR pass after semantic fixpoint (v3 order remains authoritative: Wave 6 Sema, Wave 7 MIR, Wave 8 Borrow on MIR).
**Goal:** Build a clean-room, self-hosted With compiler in With.
**Bootstrap:** Stage0 (Zig implementation) remains semantic oracle.

---

# 1. Core Principles

### 1.1 What We Are Building

A new compiler implementation (Withc2) written in With, that:

* Implements the full With language spec
* Produces semantically identical results to Stage0
* Achieves semantic fixpoint under self-compilation
* Establishes a clean long-term architecture

This is not a translation. It is a clean reimplementation guided by Stage0 as executable specification.

---

### 1.2 What We Are NOT Doing

* No line-for-line port of bootstrap.
* No semantic redesign.
* No feature additions during self-host.
* No architecture shortcuts “to rewrite later.”

---

### 1.3 Strategic Architecture Spine

Primary influence: **Zig compiler architecture**

* Clear pass boundaries
* Explicit IR transitions
* Simple pipeline
* No overengineered query system initially

Secondary influence: **Rust compiler discipline**

* MIR for borrow checking
* Structured diagnostics
* Stable IDs everywhere
* Trait resolution with obligation cache

---

### 1.4 Non-Negotiable Rules

1. Stage0 remains oracle throughout development.
2. All compiler state uses ID handles, not stored references.
3. Every IR boundary has an explicit contract.
4. All sugar lowers in exactly one stage.
5. Determinism is enforced at every stage.
6. Self-host is not complete until semantic fixpoint passes.

---

### 1.5 Stage0-Safe Subset Constraint

Self-host compiler source must remain in the subset known to compile under Stage0.

Rules during self-host bootstrap:

* Prefer rewriting self-host code over extending Stage0 for convenience features.
* Keep compiler-core code synchronous and deterministic.
* Treat Stage0 gaps as coding constraints for Withc2 until semantic fixpoint is reached.

Disallowed in Withc2 core (pre-fixpoint):

* Generic async task-collection patterns (`Vec[Task[T]]`, `impl IntoIter[Task[_]]` in async generic paths).
* Collection combinator usage (`await_all`, `await_first`, `await_any`, `await_settled`) in the compiler pipeline.
* Any design requiring bootstrap generic-async lowering improvements.

Required style:

* Synchronous pass pipeline (`lex -> parse -> sema -> MIR -> codegen -> link`).
* Explicit loops and dataflow.
* Stable-ID state threading with deterministic behavior.

---

# 2. Compiler Architecture Overview

```
Source
  ↓
Lexer
  ↓
AST (lossless syntax)
  ↓
Resolve / HIR (IDs + module graph)
  ↓
Typed IR (type inference + trait resolution)
  ↓
MIR (desugared CFG + explicit drops)
  ↓
Borrow Check (NLL + aliasing)
  ↓
Async-MIR (suspend-aware lowering)
  ↓
LLVM IR
  ↓
Binary
```

---

# 3. Identity Model (Critical Structural Rule)

The compiler uses **stable numeric IDs everywhere**.

No stored references inside persistent structures.

### Core IDs

```
FileId
ModuleId
DefId
ItemId
AdtId
TraitId
ImplId
FnId
LocalId
ScopeId
TypeId
ValueId
Symbol
```

All compiler tables are:

```
Vec<T> indexed by distinct u32 IDs
```

No `?&Scope`, no pointer-linked trees.

---

# 4. IR Contracts

Each stage defines:

* Input
* Output
* Invariants
* Allowed sugar
* Eliminated constructs

---

## 4.1 AST (Syntax Tree)

**Purpose:** Preserve parsed structure exactly.

### Input

Tokens

### Output

AST nodes with spans

### Invariants

* No name resolution
* No type info
* No symbol binding
* No desugaring
* No ID assignment

### Sugar Allowed

All language surface syntax.

---

## 4.2 Resolve / HIR

**Purpose:** Bind names and build module graph.

### Input

AST

### Output

HIR:

* All names mapped to DefIds
* Module graph built
* Imports resolved
* Use expansion complete
* Stable NodeIds assigned

### Invariants

* No unresolved identifiers
* No duplicate items
* Symbol identity separated from definition identity

### Sugar Allowed

Still high-level constructs (`with`, `??`, match, etc.)

---

## 4.3 Typed IR

**Purpose:** Attach types and resolve generics.

### Input

HIR

### Output

Typed nodes:

* Every expression has TypeId
* All generics instantiated
* Trait obligations collected
* Coherence validated

### Invariants

* No unresolved trait obligations
* No inference holes
* All coercions explicit

### Sugar Allowed

Control-flow sugar still intact.

---

## 4.4 MIR (Desugared Control Flow)

**Purpose:** Explicit control flow graph.

### Input

Typed IR

### Output

Basic blocks with:

* Explicit temporaries
* Explicit assignments
* Explicit drops
* Explicit branches

### Eliminated

* `with`
* `??`
* `?.`
* record update sugar
* pattern matching
* implicit Ok
* implicit default return
* `let...else`
* pipeline operator
* closure sugar

### Invariants

* No syntactic sugar
* Drop insertion complete
* Control flow explicit

---

## 4.5 Borrow Check

**Purpose:** Enforce aliasing + ephemeral model.

Runs on MIR.

### Enforces

* Move-after-move
* Partial move
* Drop-as-use
* NLL lifetimes
* Aliasing rule
* Disjoint field borrowing
* Second-class reference restrictions
* Guard restrictions

### Invariants

No ownership errors remain.

---

## 4.6 Async-MIR

**Purpose:** Lower suspend-aware constructs.

Separates:

* Generators (state machine)
* Async (fiber-based, stackful)
* `await`
* `select`
* `spawn`

Ensures:

* Suspension points explicit
* Guard restrictions enforced

---

## 4.7 LLVM IR

No With concepts remain.

Only:

* Types
* Control flow
* Runtime calls
* Data layout

---

# 5. Type System Architecture

## 5.1 Structural vs Nominal Split

Structural types interned:

* Ptr
* Ref
* Slice
* Array
* Tuple
* FnSig
* Option
* Result

Nominal types:

```
Adt(AdtId, SubstId)
TraitObj(TraitId)
Alias(AliasId)
```

Definitions stored separately:

```
adt_defs: Vec[AdtDef]
trait_defs: Vec[TraitDef]
impl_defs: Vec[ImplDef]
```

TypeId is always a handle into intern pool.

---

# 6. Trait Solver

Simplified Rust-style obligation solver:

* Collect obligations during typing
* Resolve via selection cache
* Enforce orphan/coherence rules
* No HKTs
* No specialization
* No GATs

---

# 7. Wave Plan

---

## Wave 0 — Determinism + Golden Baseline

* Audit Stage0 for nondeterminism
* Add stable dump flags:

  * tokens
  * AST
  * typed
  * LLVM IR
* Capture golden baselines

Stage0 becomes semantic oracle.

---

## Wave 1 — Foundations

* ID types
* InternPool (strings + types + values)
* Arena
* Diagnostics subsystem
* Span / Source

No compiler logic yet.

Validation:
Unit tests only.

---

## Wave 2 — Lexer

Token definitions + scanner.

Validation:
`--dump-tokens` matches Stage0.

---

## Wave 3 — AST + Parser

Recursive descent parser.

Validation:
`--dump-ast` matches Stage0.

---

## Wave 4 — Resolve / HIR + Module Graph

* ModuleId
* Import resolution
* `use`
* minimal `c_import` support
* stable DefIds

Validation:
Resolved symbol tables match Stage0 behavior.

---

## Wave 5 — Types + Traits

* Type representation
* Interning
* Trait solver
* Coherence
* Generic instantiation

Validation:
Typed dump matches Stage0.

---

## Wave 6 — Semantic Analysis ✓ IMPLEMENTED

Two-pass:

1. Collect declarations (`collect_type_decl`, `collect_fn_decl`, `collect_extern_fn`, `collect_let_decl`, `collect_trait_decl`, `collect_impl_decl`)
2. Check bodies (`check_bodies` → `check_fn_body` → `check_expr`)

No move checking here except Copy knowledge (`is_copy`, `mark_moved_if_consumed`).

Fixes applied for parity:
- `TY_RANGE` inclusive → `"RangeInclusive[T]"` in `type_name`
- `let` decl fallback: `"<annotated>"` vs `"<inferred>"` in `dump_typed_module`

Test infrastructure: `test/wave6/cases/` (10 files), `test/wave6/typed_corpus.txt` (10 corpus entries), `scripts/run_wave6_sema_unit_tests.sh`, `scripts/run_wave6_typed_parity.sh`.

Known divergence: KD-W6-001 (`inferred_return` line not emitted; corpus designed to avoid).

Validation:
Typed dump parity harness passes on Wave 6 corpus with explicit `KNOWN_DIVERGENCE` accounting.

---

## Wave 7 — MIR Lowering ✓ IMPLEMENTED

* CFG construction
* Explicit drops
* Desugar everything
* No sugar beyond this point

Delivered artifacts:
- `src/Mir.w` rewritten as full SoA MIR model + deterministic dump rendering.
- `src/MirLower.w` implemented for MIR lowering, drop scheduling/elaboration, pattern/discriminant lowering, and sugar lowering (`?.`, `??`, `with`, record update, `let...else`, pipeline).
- Driver/CLI plumbing for `--dump-mir` in `src/Driver.w` and `src/main.w`.
- Test infrastructure:
  - `test/wave7/mir_corpus.txt`
  - `scripts/run_wave7_mir_parity.sh`
  - `scripts/run_wave7_mir_unit_tests.sh`
  - `test/wave7/cases/*.w`

Validation:
- Wave 7 MIR parity harness passes deterministic self-host validation on 26/26 corpus files.
- Wave 7 MIR unit harness passes.
- No accepted Wave 7 `KNOWN_DIVERGENCE` entries (current count: 0).

---

## Wave 8 — Borrow Checking (MIR Contract + Current Parity) ✓

v3 contract (authoritative):
* Borrow checking runs on MIR CFG.
* NLL, aliasing, and ephemeral enforcement execute after MIR lowering.

Current repo state (parity implementation):
* NLL-style expiration, aliasing/disjoint-field checks, and core ephemeral checks are currently implemented in `src/Sema.w` for Wave 8 corpus parity.
* This is implementation debt, not architectural target.

Delivered artifacts:
- `src/Sema.w` borrow-check/ephemeral enforcement updates:
  - `check_borrow_create` + disjoint overlap logic
  - active-borrow binding association + dead-borrow expiration
  - ephemeral type declaration tracking + return restrictions
  - closure capture ephemeral diagnostics parity
- Type-decl ephemeral flag plumbing:
  - `src/Ast.w` packed type-decl kind helpers
  - `src/Parser.w` ephemeral type-decl encoding
  - `src/render.w` / `src/Codegen.w` packed-kind decoding
- Test infrastructure:
  - `test/wave8/cases/*.w`
  - `test/wave8/borrow_corpus.txt`
  - `scripts/run_wave8_borrow_unit_tests.sh`
  - `scripts/run_wave8_borrow_parity.sh`

Validation:
- Wave 8 unit harness passes.
- Wave 8 Stage0 parity harness passes (`processed=36`, `failures=0`, `known_divergences=6`).
- Accepted Wave 8 `KNOWN_DIVERGENCE` entries are explicit and tracked (current count: 6).

Known debt (must remain explicit):
- `KNOWN_DEBT-W8-ARCH-001`: Move borrow checking from `src/Sema.w` to MIR-based pass modules (`src/BorrowCheck.w`, `src/BorrowCfg.w`) after semantic fixpoint.
- `KNOWN_DEBT-W8-ARCH-002`: Add/enable task-boundary ephemeral escape checks (`may_suspend`/guard boundary behavior) with explicit Wave 8 corpus coverage.

---

## Wave 9 — Async-MIR ✓

Implemented:
* Suspend-aware Async-MIR artifact (`src/AsyncMir.w`) and lowering pass (`src/AsyncLower.w`) after MIR.
* Explicit suspend-point modeling for `await` / `select await` / `yield` with:
  - deterministic state transitions (`state_from -> state_to`)
  - source-span preservation
  - storage/drop snapshot metadata
* Generator vs async track split via function flavor classification and `yield` legality enforcement.
* Driver/CLI integration:
  - Async-MIR pass runs in `check`/`build`/`run` pipeline.
  - deterministic `--dump-async-mir` output path.
  - async runtime object linkage (`fiber.o`, `fiber_asm.o`) gated by Async-MIR async usage.
* Wave 9 unit/parity harnesses and coverage closure remain green with explicit tri-state divergence governance.

Validation:
* `scripts/run_wave9_async_unit_tests.sh`: PASS
* `scripts/run_wave9_async_parity.sh`: PASS (`processed=38`, `failures=0`, `known_divergences=2`)

---

## Wave 10 — Codegen ✓

Implemented:
* MIR → LLVM backend contract is active in `ir`/`build`/`run` (`Driver.ensure_codegen_mir` + `Codegen.gen_module_from_mir`).
* MIR backend invariants are validated before LLVM emission (`validate_mir_module`).
* Deterministic monomorphization keys/emission and stable symbol-count behavior are enforced in Wave 10 unit/parity corpus.
* Trait-object vtable generation, dyn coercions, dyn dispatch, and known-concrete devirtualization paths are parity-covered.
* Enum layout/discriminant/accessor lowering parity now includes typed-context shorthand and runtime accessor behavior.
* Runtime/link integration remains Wave 9-consistent for sync/async object linkage policy.
* Diagnostics/parity normalization is deterministic, with tri-state accounting (`PASS`/`FAIL`/`KNOWN_DIVERGENCE`) and stale-divergence gates.

Validation:
* `scripts/run_wave10_codegen_unit_tests.sh`: PASS
* `scripts/verify_wave10_coverage.sh`: PASS (`processed=13`)
* `scripts/run_wave10_codegen_parity.sh`: PASS (`processed=104`, `failures=0`, `known_divergences=1`)
* Accepted `KNOWN_DIVERGENCE`:
  - `ir|bootstrap/test/cases/enum_accessor_ref.w` (`selfhost` correct; Stage0 IR path missing accessor-ref lowering)

---

## Wave 11 — Driver + CLI ✓

Implemented:
* Full `check`/`build`/`run`/`test`/`clean`/`help`/`version` command orchestration and deterministic command-status mapping in self-host harnesses.
* Wave 11 driver unit and parity harnesses:
  - `scripts/run_wave11_driver_unit_tests.sh`
  - `scripts/run_wave11_driver_parity.sh`
  - tri-state parity accounting (`PASS`/`FAIL`/`KNOWN_DIVERGENCE`) with stale-divergence gating.
* Stage0 coverage closure mapping and enforcement:
  - `test/wave11/coverage_manifest.txt`
  - `test/wave11/coverage_matrix.md`
  - `scripts/verify_wave11_coverage.sh`
* CLI parity harness hardening:
  - isolated temp-directory execution for missing-arg/unknown-flag CLI checks
  - timeout-wrapped CLI invocations to prevent false hangs
  - absolute binary-path invocation for temp-dir command runs.

Validation:
* `scripts/run_wave11_driver_unit_tests.sh`: PASS
* `scripts/verify_wave11_coverage.sh`: PASS (`processed=9`)
* `scripts/run_wave11_driver_parity.sh`: PASS (`processed=30`, `failures=0`, `known_divergences=2`)
* Accepted `KNOWN_DIVERGENCE`:
  - `check|test/wave11/cases/c_import_macro_constants_ok.w` (`selfhost` correct; Stage0 macro constant path behind)
  - `check|test/wave11/cases/c_import_macro_function_like_ok.w` (`selfhost` correct; Stage0 function-like macro diagnostics path behind)

---

## Wave 12 — Self-Host

Stage1 = Withc2 built by Stage0
Stage2 = Withc2 built by Stage1
Stage3 = Withc2 built by Stage2

Validation levels:

1. Full test suite passes.
2. Stage2 IR structurally equals Stage3 IR.
3. Optional binary equality.

---

# 8. Testing Strategy

1. Unit tests per module.
2. Golden diff tests per wave.
3. Structured diagnostic comparison (not raw text).
4. End-to-end integration tests.
5. Regression tests for every discovered bug.

---

# 9. Post-Fixpoint Policy

After fixpoint:

* Stage2 becomes canonical.
* Stage0 frozen in `/bootstrap`.
* All future development happens in With.
* CI builds bootstrap as recovery path.

---
