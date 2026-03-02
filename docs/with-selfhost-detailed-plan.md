# Self-Hosting the With Compiler

## Architecture-First Execution Plan

**Status:** Wave 0 complete (determinism + stable dumps + golden baseline).
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

## Wave 6 — Semantic Analysis

Two-pass:

1. Collect declarations
2. Check bodies

No move checking here except Copy knowledge.

Validation:
Typed dump identical.

---

## Wave 7 — MIR Lowering

* CFG construction
* Explicit drops
* Desugar everything
* No sugar beyond this point

Validation:
MIR → LLVM produces semantically identical behavior.

---

## Wave 8 — Borrow Checking

* NLL on CFG
* Aliasing enforcement
* Ephemeral rules

Validation:
All borrow diagnostics match Stage0.

---

## Wave 9 — Async-MIR

* Suspend-aware lowering
* Generator vs async split
* select lowering

Validation:
Async tests pass identically.

---

## Wave 10 — Codegen

* MIR → LLVM
* Monomorphization
* Vtable generation
* Enum layout

Validation:
Programs behave identically to Stage0.

---

## Wave 11 — Driver + CLI

* Full pipeline orchestration
* Linking
* c_import finalization

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
