# Porting the With Compiler from Zig to With — Execution Plan

---

## 1. Definition of Success

Self-hosting is complete when:

1. The With compiler (written in With) compiles its own source.
2. The resulting compiler compiles itself again.
3. The second self-compiled compiler produces identical semantic output.
4. The full language test suite passes under the self-hosted compiler.
5. All flagship demos (kernel module, Steam Deck game, withgrad) build with the self-hosted compiler.
6. Fixpoint verification passes (see §6).

Only then is the Zig compiler demoted to bootstrap-only.

---

## 2. Bootstrap Chain

```
STAGE 0 (Zig reference compiler):
    Zig source → Zig → with-stage0

STAGE 1:
    With compiler source → with-stage0 → with-stage1

STAGE 2:
    With compiler source → with-stage1 → with-stage2

STAGE 3 (fixpoint verification):
    With compiler source → with-stage2 → with-stage3
```

Self-hosting requires:

* Stage1 builds correctly.
* Stage2 builds correctly.
* Stage2 and Stage3 satisfy fixpoint constraints.

---

## 3. Determinism Requirements (Mandatory Before Port Begins)

Before porting any module:

* File discovery order must be sorted.
* Diagnostic output must be sorted by source position.
* Symbol tables must not be iterated in nondeterministic order for emission.
* Hash maps used in code generation must be sorted before output.
* LLVM IR emission order must be stable.
* Metadata emission must not depend on pointer identity.
* Any debug info or timestamp embedding must be disabled or normalized for comparison mode.

Add internal flags:

```
--dump-tokens
--dump-ast
--dump-typed
--dump-mir
--dump-llvm
```

These dumps must be deterministic and diffable.

---

## 4. Golden Baseline Capture

Before porting:

1. Run Stage0 on the entire test suite.
2. Capture for every test:

   * Exit code
   * Diagnostics
   * AST dump
   * Typed dump
   * MIR dump
   * LLVM IR dump (normalized)

Store as golden reference.

Every port step is validated against these.

---

## 5. Port Strategy

### Absolute rule:

No redesign during port.

No algorithm improvements.
No feature tweaks.
No semantic changes.

Only translation from Zig → With.

---

### Module Port Order (Strict Dependency Order)

### Wave 1 — Foundational Utilities

* Source locations
* Span types
* Diagnostics
* String interning
* Arena allocation
* ID types (`distinct u32` handles)

After port:

* Rebuild compiler with stage0
* Run full golden diff
* Zero divergence allowed

---

### Wave 2 — Token + Lexer

* Token enum
* Lexer
* Keyword recognition
* Literal parsing

Validation:

* `--dump-tokens` identical to golden

---

### Wave 3 — AST + Parser

* AST enums and structs
* Recursive descent parser
* Pattern parsing
* Expression parsing
* Statement parsing
* Module parsing

Validation:

* `--dump-ast` identical
* Diagnostics identical

---

### Wave 4 — Symbol Resolution + Type Representation

* Scope stack
* Symbol tables
* Type representation
* Generic instantiation
* Type equality
* Type inference

Validation:

* `--dump-typed` identical
* Diagnostics identical

---

### Wave 5 — Type Checking + All Language Features

This must include:

* Trait resolution
* Associated types (if implemented)
* Monomorphization
* Auto-ref
* Auto-deref
* Implicit Ok wrapping
* Default field insertion
* Enum accessor generation
* Pattern exhaustiveness
* Record update lowering
* `let...else`
* Chained `if let`
* Pipeline desugaring
* `with` lowering
* `defer` lowering
* Optional chaining lowering
* `??` lowering
* All syntax traits
* All attribute handling
* All derive logic
* All comptime support
* All macro-like expansions (if any)

Validation:

* Typed dump identical
* MIR dump identical

---

### Wave 6 — Borrow Checker + Ephemeral Enforcement

* NLL computation
* Overlap detection
* Ephemeral propagation
* Guard enforcement
* Drop-as-use rule

Validation:

* Diagnostics identical
* No new borrow divergences

---

### Wave 7 — MIR + Lowering

* Desugaring of:

  * `with`
  * `match`
  * `gen`
  * `async`
  * `select`
  * closures
  * tuple destructuring
  * record updates
  * builder returns
* All implicit transformations

Validation:

* `--dump-mir` identical

---

### Wave 8 — LLVM Backend

* Type lowering
* Function lowering
* Control flow
* Data layout
* Struct/enum layout
* Vtable generation
* Trait object layout
* Task lowering
* Channel lowering
* Async lowering
* All runtime calls

Validation:

* Normalized LLVM IR identical

---

### Wave 9 — Driver + Build System

* CLI parsing
* with.toml parsing
* Module graph resolution
* Linking invocation
* Build orchestration

Validation:

* Full compiler builds
* Full golden diff passes

---

## 6. Fixpoint Verification (Revised and Strict)

Fixpoint is validated in layers:

### Level 1 — Semantic Fixpoint (Required)

Stage2 compiles itself → Stage3

* Stage3 passes full test suite
* Stage3 builds demos

If this fails, self-hosting is incomplete.

---

### Level 2 — IR Fixpoint (Required)

Compare normalized LLVM IR:

```
stage2 IR == stage3 IR
```

Normalization removes:

* Debug metadata
* Non-semantic attributes
* Ordering artifacts

If IR differs, investigate nondeterminism or semantic drift.

---

### Level 3 — Binary Fixpoint (Optional but Ideal)

```
stage2 binary == stage3 binary
```

If this fails:

* Investigate linker nondeterminism
* Investigate section ordering
* Investigate embedded metadata

Binary equality is desirable but not required for semantic correctness.

---

## 7. No Feature Freeze During Port — All Features Required

This plan assumes:

* Async
* Fibers
* Channels
* c_import
* Unsafe
* All traits
* All derives
* Comptime
* All syntax sugar

The self-hosted compiler must implement the full language.

No partial subset.

---

## 8. Post Self-Host Policy

After fixpoint passes:

1. Stage2 becomes canonical.
2. Zig compiler moves to `/bootstrap`.
3. Zig compiler is frozen.
4. No new language features are added to Zig.
5. With compiler becomes the only evolving implementation.
6. CI still builds Zig bootstrap for recovery purposes.

---

## 9. Strict Rules During Port

* No architectural refactoring.
* No performance tuning.
* No stylistic cleanups.
* No semantic reinterpretation.
* Only literal translation.

After Stage2 fixpoint, improvements begin.

---

## 10. What This Plan Guarantees

If executed precisely:

* Self-hosted compiler is semantically identical to Zig compiler.
* Determinism issues are controlled.
* Stage1→Stage2 traps are caught.
* No silent drift.
* All features are implemented.
* The language is validated at full scale.
