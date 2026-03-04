# Self-Hosting With — Architecture-First Plan

**Status:** Wave 11 parity is passing for the current corpus. Driver/CLI/link/c_import orchestration is implemented in self-host and validated by Wave 11 harnesses (`processed=30`, `failures=0`, `known_divergences=2`) with coverage verification passing (`processed=9`). Accepted Wave 11 divergences are both macro-path checks where self-host is correct and Stage0 is behind: `check|test/wave11/cases/c_import_macro_constants_ok.w` and `check|test/wave11/cases/c_import_macro_function_like_ok.w`. Wave 8 keeps explicit `KNOWN_DEBT`: borrow checking is currently Sema-integrated and must be moved to a dedicated MIR pass after semantic fixpoint (v3 architecture remains authoritative: Wave 6 Sema, Wave 7 MIR, Wave 8 Borrow on MIR).

---

# 0. Guiding Principles

1. **Semantics are frozen during self-host.**
2. **Stage0 (Zig bootstrap) is the oracle.**
3. **Architecture is clean-room.**
4. **Every IR boundary has a written contract.**
5. **All sugar lowers in exactly one place.**
6. **Determinism is enforced at every layer.**
7. **No cleverness during bootstrap. Only clarity.**

## 0.1 Stage0-Safe Subset Constraint

Self-host source must stay within the subset that reliably compiles under Stage0.

Until semantic fixpoint:

* Do not add bootstrap features just to support self-host coding style.
* If Stage0 rejects a pattern, rewrite self-host code into a Stage0-safe form.
* Keep compiler core implementation synchronous and deterministic (`lex -> parse -> sema -> MIR -> codegen -> link`).

Disallowed in self-host compiler source before fixpoint:

* Generic async task-collection patterns (`Vec[Task[T]]`, `impl IntoIter[Task[_]]` in async generic paths).
* Collection async combinators (`await_all`, `await_first`, `await_any`, `await_settled`) inside compiler pipeline code.
* Work that requires bootstrap-side generic async lowering upgrades.

Allowed/expected style:

* Plain synchronous passes and explicit loops.
* Explicit state threading with stable IDs.
* Deterministic control flow over concurrency abstractions.

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
MIR
  ↓
Borrow / Ephemeral Analysis (on MIR)
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

## 2.4 MIR — Explicit Control Flow

**Purpose:** Remove language sugar and make control flow explicit.

### Input:

* Typed IR

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

## 2.5 Borrow / Ephemeral Analysis

**Purpose:** Enforce aliasing and ephemeral rules.

Runs on MIR.

### Input:

* MIR

### Output:

* MIR plus borrow/ephemeral analysis state and diagnostics:

  * Borrow lifetimes
  * Move tracking
  * Ephemeral flags
  * Guard constraints
  * `may_suspend` flags

### Required safety checks:

* No borrow ambiguity
* No move-after-use
* No ephemeral violations
* Task-boundary ephemeral escape checks across `may_suspend` boundaries
* `@[no_await_guard]` enforcement with Stage0-equivalent severity

After this stage, ownership/ephemeral semantics are fixed.

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

Wave mapping (v3, authoritative):
* Wave 6: Sema (typed IR)
* Wave 7: MIR lowering (CFG + explicit drops)
* Wave 8: Borrow/Ephemeral checking on MIR

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

## Phase 4 — MIR

Implement:

* Full sugar lowering to MIR
* Explicit CFG/basic blocks
* Explicit drops and control flow

Validate:

* `--dump-mir` deterministic on the Wave 7 corpus.
* If Stage0 gains `--dump-mir`, strict Stage0 vs self-host MIR diff gate.

---

## Phase 5 — Borrow + Ephemeral (on MIR)

Implement:

* NLL dataflow on MIR CFG
* Disjoint field borrowing
* Ephemeral propagation
* Guard enforcement
* `may_suspend`-aware task-boundary escape checks

Validate:

* Diagnostics must match Stage0.
* Explicit task-boundary ephemeral tests must pass in the Wave 8 corpus.

`KNOWN_DEBT` (current repo state): Wave 8 behavior currently lives in `src/Sema.w` for corpus parity and must be rewritten onto MIR (`src/BorrowCheck.w` + `src/BorrowCfg.w`) after semantic fixpoint.

---

## Phase 6 — Async-MIR

Implemented in self-host:

* `src/AsyncMir.w` deterministic Async-MIR artifact model.
* `src/AsyncLower.w` post-MIR async lowering pass (await/select/yield suspension points, state transitions, source spans, storage/drop snapshots).
* Driver integration after MIR lowering in `check`/`build`/`run`.
* Deterministic CLI dump path via `--dump-async-mir`.
* Runtime linkage gating for async runtime objects (`fiber.o`, `fiber_asm.o`) based on Async-MIR async usage.

Validate:

* Wave 9 async unit suite passes.
* Wave 9 Stage0 parity harness passes (`processed=38`, `failures=0`, `known_divergences=2`).
* Stage0 vs Withc2 behavior is identical for PASS entries, with accepted `KNOWN_DIVERGENCE` entries explicitly tracked.

---

## Phase 7 — LLVM Backend ✓

Implemented in self-host:

* MIR → LLVM backend boundary with explicit MIR invariant validation.
* Deterministic monomorphization emission and mangling behavior.
* Trait-object vtable generation, dyn coercions, and dyn dispatch/devirtualization paths.
* Enum layout/discriminant/accessor lowering parity for runtime behavior.
* Runtime/link integration policy consistency for sync/async codegen outputs.
* Diagnostics normalization and deterministic parity-state accounting.

Validate:

* `scripts/run_wave10_codegen_unit_tests.sh`: PASS
* `scripts/run_wave10_codegen_parity.sh`: PASS (`processed=104`, `failures=0`, `known_divergences=1`)
* `scripts/verify_wave10_coverage.sh`: PASS (`processed=13`)

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
