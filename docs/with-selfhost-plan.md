# Self-Hosting With — Architecture-First Plan

**Status:** Wave 5 complete (`--dump-typed` parity + obligation selection cache + generic bound checks + dyn trait-call compatibility + specialization cache + typed sidecar persistence).

---

# 0. Guiding Principles

1. **Semantics are frozen during self-host.**
2. **Stage0 (Zig bootstrap) is the oracle.**
3. **Architecture is clean-room.**
4. **Every IR boundary has a written contract.**
5. **All sugar lowers in exactly one place.**
6. **Determinism is enforced at every layer.**
7. **No cleverness during bootstrap. Only clarity.**

---

# 1. Compiler Architecture Spine

**Dominant style: Zig-like pipeline simplicity.**
**Diagnostics discipline: Rust-grade.**

Pipeline:

```
Source
  ↓
Lexer
  ↓
AST
  ↓
HIR (Resolved + Elaborated)
  ↓
Typed IR
  ↓
Borrow / Ephemeral Analysis
  ↓
MIR
  ↓
Async-MIR (if needed)
  ↓
LLVM IR
  ↓
Object/Binary
```

No query engine initially.
No incremental compilation initially.
No parallel passes initially.

Self-host first. Optimize later.

---

# 2. IR Contract Document (Required Before Implementation)

This is the core of your architectural discipline.

---

## 2.1 AST — Syntax Tree

**Purpose:** Lossless representation of parsed source.

### Input:

* Token stream

### Output:

* AST preserving:

  * All syntax sugar
  * Exact spans
  * All surface constructs

### Invariants:

* No name resolution
* No type information
* No desugaring
* No symbol linking
* No control flow rewriting

### Sugar allowed:

* `with`
* `?.`
* `??`
* record update
* pattern matching
* implicit returns
* `async`, `await`
* `select await`
* `gen`
* everything surface-level

### What must NOT appear:

* No lowered control flow
* No temporary variables
* No inserted implicit nodes

AST is a faithful parse tree.

---

## 2.2 HIR — Resolved & Elaborated

**Purpose:** Name resolution + structural normalization.

### Input:

* AST

### Output:

* HIR with:

  * All names resolved to symbols
  * All `use` expanded
  * All identifiers replaced by symbol IDs
  * Fully qualified paths resolved

### Invariants:

* Symbol IDs stable
* Type inference NOT yet complete
* Sugar still present
* Patterns still present
* Control flow still high-level

### Sugar allowed:

* `with`
* `?.`
* `??`
* record update
* pattern matching
* implicit Ok wrapping
* implicit default return
* async constructs

### Eliminated:

* No unresolved names
* No unbound identifiers
* No ambiguous references

HIR is still high-level but semantically anchored.

---

## 2.3 Typed IR

**Purpose:** Attach types and resolve generics.

### Input:

* HIR

### Output:

* Typed nodes
* All expressions have concrete types
* Generic instantiations resolved
* Trait resolution complete

### Invariants:

* All type inference complete
* All trait method resolution complete
* All type coercions explicit
* Auto-ref/deref resolved
* Implicit trait object coercion resolved

### Sugar allowed:

* `with`
* `?.`
* `??`
* record update
* pattern matching
* implicit Ok wrapping
* implicit default return
* async constructs

### Eliminated:

* No generic type holes
* No unresolved traits
* No type inference variables

Typed IR still preserves high-level control constructs.

---

## 2.4 Borrow / Ephemeral Analysis

**Purpose:** Enforce aliasing and ephemeral rules.

### Input:

* Typed IR

### Output:

* Same IR annotated with:

  * Borrow lifetimes
  * Move tracking
  * Ephemeral flags
  * Guard constraints
  * `may_suspend` flags

### Invariants:

* All borrow errors detected here
* All ephemeral propagation resolved
* All `@[no_await_guard]` enforcement validated

### Sugar allowed:

* `with`
* pattern matching
* record update
* async constructs

### Eliminated:

* No borrow ambiguity
* No move-after-use
* No ephemeral violations

After this stage, semantics are fixed.

---

## 2.5 MIR — Explicit Control Flow

**Purpose:** Remove language sugar and make control flow explicit.

### Input:

* Typed + Borrow-checked IR

### Output:

* Basic blocks
* Explicit temporaries
* Explicit branches
* Explicit drops

### At this stage eliminate:

| Feature                 | Lower Here                                  |
| ----------------------- | ------------------------------------------- |
| `?.`                    | Convert to explicit match / branch          |
| `??`                    | Convert to match with early exit            |
| `with` Form 1           | Lower to guard enter/exit calls             |
| `with` Form 2/3         | Lower to block + temporary                  |
| record update           | Expand to struct construction + moves/drops |
| pattern matching        | Lower to decision tree                      |
| implicit Ok             | Insert explicit Ok(...)                     |
| implicit default return | Insert explicit default value               |
| `let...else`            | Lower to match + early return               |
| chained `if let`        | Lower to nested conditionals                |

### Invariants:

* No syntactic sugar remains
* Only:

  * assignments
  * jumps
  * calls
  * temporaries
  * drops
  * returns
  * explicit match lowering

MIR is boring and explicit.

---

## 2.6 Async-MIR

**Purpose:** Lower async constructs.

### Input:

* MIR with async nodes

### Output:

* Fiber-aware control flow
* Suspension points explicit
* State transitions explicit
* `select await` expanded

### Lower:

* `.await`
* `async fn`
* `async scope`
* `select await`
* `spawn`

After this:

* Async is just runtime calls + control flow

---

## 2.7 LLVM IR

**Purpose:** Machine-level lowering.

### Input:

* Async-MIR

### Output:

* LLVM IR only

### Invariants:

* No With concepts
* No type system
* No trait system
* No borrow logic
* No sugar

Pure data layout + control flow.

---

# 3. Sugar Lowering Map (Single Source of Truth)

| Feature                 | Lowering Stage         |
| ----------------------- | ---------------------- |
| `?.`                    | HIR→MIR                |
| `??`                    | HIR→MIR                |
| `with`                  | HIR→MIR                |
| record update           | HIR→MIR                |
| implicit Ok             | MIR return elaboration |
| implicit default return | MIR return elaboration |
| `let...else`            | HIR→MIR                |
| chained `if let`        | HIR→MIR                |
| pattern matching        | HIR→MIR                |
| async constructs        | MIR→Async-MIR          |

No sugar lowers in two places.

This is how you prevent architecture drift.

---

# 4. Revised Self-Host Phases

Now we adapt your Waves to this architecture.

---

## Phase 0 — Deterministic Stage0

Before writing Withc2:

* Add all dump flags to Stage0.
* Enforce deterministic ordering.
* Capture golden baseline.

Stage0 becomes semantic oracle.

---

## Phase 1 — Lexer + AST (Withc2)

Implement:

* Lexer
* AST
* Dump comparison vs Stage0 `--dump-tokens`
* Dump comparison vs Stage0 `--dump-ast`

Zero semantic deviation allowed.

---

## Phase 2 — HIR + Name Resolution

Implement:

* Symbol tables
* ID interning
* Scope stack
* Path resolution

Validate HIR dumps vs Stage0 resolved output.

---

## Phase 3 — Type System

Implement:

* Type representation
* Trait resolution
* Generic instantiation
* Auto-ref/deref

Validate typed dump vs Stage0.

---

## Phase 4 — Borrow + Ephemeral

Implement:

* NLL
* Disjoint field borrowing
* Ephemeral propagation
* Guard enforcement
* `may_suspend`

Diagnostics must match Stage0.

---

## Phase 5 — MIR

Implement full sugar lowering.

Validate:

* MIR dumps identical to Stage0.

This is the biggest structural checkpoint.

---

## Phase 6 — Async-MIR

Implement fiber lowering.

Validate:

* Async test suite passes.
* Stage0 vs Withc2 behavior identical.

---

## Phase 7 — LLVM Backend

Implement:

* Type layout
* Vtables
* Trait objects
* Task lowering
* Channels

Validate normalized LLVM IR.

---

## Phase 8 — Self-Host

```
Stage1 = Withc2 compiled by Stage0
Stage2 = Withc2 compiled by Stage1
Stage3 = Withc2 compiled by Stage2
```

Check:

* Full test suite passes
* Demos build
* Stage2 IR structurally equals Stage3 IR
* Optional: binary fixpoint

---

# 5. Bootstrap Policy

Stage0 remains:

* Frozen
* Used only as oracle
* Never deleted

After Stage2 fixpoint:

* Stage2 becomes canonical
* Stage0 moved to `/bootstrap`
* CI builds both

---

# 6. Why This Plan Works

You get:

* Clean architecture
* No inheritance of bootstrap mess
* No semantic gamble
* Deterministic validation
* Clear sugar boundaries
* Future extensibility

And you avoid:

* Porting Zig compiler semantics
* Simultaneous multi-axis mutation
* Loss of validation anchor

---

# Final Verdict

This plan is:

* Ambitious
* Correct
* Architecturally principled
* Scalable
* Far safer than the original “mutate Zig compiler” idea
