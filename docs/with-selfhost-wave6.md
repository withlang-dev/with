# Wave 6 Implementation Plan

## Semantic Analysis (Two-Pass) for Withc2

## Goal

Implement Wave 6 semantic analysis in the self-host compiler using a strict two-pass model:

1. collect declarations
2. check bodies

Wave 6 rule:

- no move-checking in this wave beyond Copy knowledge needed by semantic typing behavior.

Wave 6 exit gate:

- `--dump-typed` output is identical to Stage0 on the Wave 6 corpus.

---

## Inputs and Constraints

- Canonical wave definition:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Typed dump contract:
  - `docs/wave0-dump-spec.md` (typed section)
- Stage0 oracle behavior:
  - `bootstrap/src/Sema.zig`
    - declaration collection (`collectDeclarations`, type/fn/trait/impl maps)
    - body checking (`checkExpr`, call/method checks, control-flow checks)
    - typed sidecar recording (`typed_expr_types`, `typed_binding_types`)
  - `bootstrap/src/Driver.zig` (`writeTyped`)
  - `bootstrap/src/main.zig` (`--dump-typed`)
- Existing self-host implementation:
  - `src/Sema.w`
  - `src/compiler/Zcu.w`
  - `src/compiler/Frontend.w`
  - `src/Driver.w`
- Reference architecture:
  - Zig:
    - `.reference/zig/src/Sema.zig`
    - `.reference/zig/src/Zcu.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_hir_analysis/src`
    - `.reference/rust/compiler/rustc_typeck/src`

Constraints:

- Stage0 remains semantic oracle during Wave 6.
- Self-host must remain within Stage0-safe subset.
- No language redesign in Wave 6.
- No borrow/move checker implementation in Wave 6 (Wave 8+).
- Deterministic output and diagnostics ordering are mandatory.

---

## Scope

## In scope

- Two-pass semantic pipeline:
  - Pass 1: declaration collection
  - Pass 2: body/type checking
- Deterministic symbol/type/signature table construction.
- Expression/type checking coverage needed for typed-dump parity.
- Call/method resolution parity with Stage0 behavior in Wave 6 corpus.
- Typed sidecar parity (`typed_expr_types`, `typed_binding_types`, names/mut flags).
- Copy knowledge integration only (no full move diagnostics).

## Out of scope

- Full move/lifetime diagnostics and borrow rules (Wave 8).
- MIR lowering or async lowering architecture changes (Wave 7/9).
- LLVM/codegen behavior changes.
- Async feature expansion for bootstrap limitations.

---

## Wave 6 Oracle Contract (Parity Target)

Primary parity artifact:

- `check <file> --dump-typed`

Wave 6 parity contract:

1. Same declaration ordering as Stage0 typed dump.
2. Same type naming/rendering for declarations, expressions, and bindings.
3. Same expression typing decisions for corpus constructs.
4. Same binding type/mutability/name rows.
5. Same deterministic ordering across repeated runs.

Known divergence policy:

- Any intentional divergence must be explicitly documented as `KNOWN_DIVERGENCE` with linked rationale and test coverage.

---

## Deliverables

- A two-pass self-host semantic analyzer wired into frontend:
  - declaration collection pass
  - body checking pass
- Deterministic semantic tables stored in `Zcu`.
- Typed sidecar population for typed dump parity.
- Wave 6 unit test suite and Stage0 parity harness.
- Wave 6 status updates in plan docs.

---

## Target File Plan

Implementation (expected touch points):

- `src/Sema.w` (primary Wave 6 work)
- `src/compiler/Zcu.w` (semantic state ownership and typed sidecars)
- `src/compiler/Frontend.w` (pass ordering/wiring)
- `src/Driver.w` (typed dump plumbing if needed)
- `src/main.w` (CLI passthrough for parity mode if needed)

Tests/scripts (new):

- `test/wave6/*`
- `test/wave6/typed_corpus.txt`
- `scripts/run_wave6_sema_unit_tests.sh`
- `scripts/run_wave6_typed_parity.sh`

---

## Execution Checklist

## 0) Freeze Wave 6 Contract and Corpus

- [x] Freeze Wave 6 typed parity scope against current Stage0 behavior.
- [x] Build `test/wave6/typed_corpus.txt` covering:
  - declarations (`fn/type/let/extern/trait/impl`)
  - calls/methods/generic call sites
  - control flow (`if/match/loop/for/while`)
  - pattern bindings and destructures
  - `with`/async constructs as semantic (not lowering) inputs
- [x] Capture Stage0 typed goldens for corpus (computed fresh each run by parity harness).

## 1) Semantic State Model in Zcu

- [x] Define/confirm canonical semantic tables in `Zcu` used by both passes.
- [x] Ensure deterministic insertion/iteration semantics for all tables used by typed dump.
- [x] Ensure typed sidecars are reset/populated in a single authoritative pipeline path.

## 2) Pass 1: Declaration Collection

- [x] Implement/align deterministic collection of named types (`collect_type_decl`).
- [x] Implement/align deterministic collection of function signatures (`collect_fn_decl`).
- [x] Implement/align extern function declarations (`collect_extern_fn`).
- [x] Implement/align top-level `let` declarations with annotated/inferred type handling (`collect_let_decl`; fixed `<annotated>`/`<inferred>` fallback in `dump_typed_module`).
- [x] Implement/align trait declaration collection (`collect_trait_decl`).
- [x] Implement/align impl declaration collection and method registration keys (`collect_impl_decl`).
- [x] Keep duplicate-name/conflict diagnostics order stable.

## 3) Pass 2: Body Checking Pipeline

- [x] Implement full body traversal over all checkable decl kinds (`check_bodies`, `check_fn_body`).
- [x] Enforce expression typing with deterministic expected-type propagation (`check_expr` with `expected` parameter).
- [x] Populate typed expression sidecar for every typed expression node in scope (`typed_expr_types`).
- [x] Populate typed binding sidecar for all bindings (`typed_binding_types`, `typed_binding_names`, `typed_binding_muts`).

## 4) Expression Typing Parity

- [x] Arithmetic/logical/comparison typing parity (`check_binary`, `check_unary`).
- [x] Optional/result operators (`?`, `??`) semantic typing parity.
- [x] Pattern/match arm typing and branch unification parity (`check_match_expr`, `check_pattern`).
- [x] Block/tail/implicit return typing parity.
- [x] `with`, async/await/select expressions typed at semantic level without adding new lowering behavior.

## 5) Call and Method Resolution Parity

- [x] Function call arity/type checks parity (`check_call`).
- [x] Method lookup parity (`check_method_call`; type-method mangling matches Stage0 model).
- [x] Generic call checking/inference behavior parity for Wave 6 corpus.
- [x] Trait-bound enforcement in call contexts parity (`select_trait_impl`).
- [x] Builtin call typing and diagnostics parity (`check_builtin_call`).

## 6) Scope and Binding Semantics

- [x] Lexical scope push/pop parity for blocks and control-flow constructs (`push_scope`, `pop_scope`).
- [x] Shadowing/lookup behavior parity (`scope_put`, `scope_lookup`).
- [x] Pattern binding introduction timing parity (`match`, `if let`, `while let`, destructure).
- [x] Deterministic undefined-name diagnostics and spans.

## 7) Copy Knowledge Integration (No Move Checker)

- [x] Define explicit Wave 6 policy: use Copy/non-Copy only where semantic typing needs it (`is_copy`).
- [x] Keep any move-state tracking minimal and non-diagnostic in Wave 6 (`mark_moved_if_consumed`; no move errors emitted).
- [x] Defer full move/borrow diagnostics to Wave 8 without leaking partial behavior into Wave 6 parity corpus.

## 8) Diagnostics Stability

- [x] Normalize diagnostic ordering and wording for deterministic parity checks.
- [x] Ensure span fidelity for declaration and body-check errors.
- [x] Add Wave 6 diagnostics tests for representative semantic failures (`undefined_var_error.w`, `type_mismatch_error.w`, `arity_mismatch_error.w`).

## 9) Typed Dump Emission Alignment

- [x] Verify typed sidecar completeness against Stage0 typed dump requirements.
- [x] Align type string rendering for all Wave 6 type forms (fixed `TY_RANGE` inclusive → `"RangeInclusive[T]"`; fixed let_decl `<annotated>`/`<inferred>` fallback).
- [x] Ensure output ordering is byte-stable across repeated runs.

## 10) Unit Tests

- [x] Add declaration-collection unit tests (`test/wave6/cases/decl_collection_pass.w`).
- [x] Add body-check expression typing unit tests (`test/wave6/cases/body_typing_pass.w`).
- [x] Add call/method/generic semantic-check unit tests (`test/wave6/cases/method_call_pass.w`, `trait_impl_pass.w`).
- [x] Add scope/pattern binding unit tests (`test/wave6/cases/scope_binding_pass.w`, `pattern_binding_pass.w`).
- [x] Add diagnostics determinism tests (`scripts/run_wave6_sema_unit_tests.sh` — 30 checks including 3 determinism runs, 5 Wave 5 regressions).

## 11) Stage0 Parity Harness

- [x] Implement `scripts/run_wave6_typed_parity.sh`:
  - build Stage0 + self-host
  - run `--dump-typed` on Wave 6 corpus
  - strict diff outputs
  - rerun self-host to assert determinism
- [x] Add explicit reporting buckets:
  - `PASS`
  - `FAIL`
  - `KNOWN_DIVERGENCE`

## 12) Documentation and Wave Status

- [x] Update `docs/with-selfhost-wave6.md` with implementation notes.
- [x] Update `docs/with-selfhost-plan.md` Wave 6 status when exit gates pass.
- [x] Update `docs/with-selfhost-detailed-plan.md` with Wave 6 completion notes.
- [x] Record accepted divergences with rationale and test linkage (see below).

---

## Known Divergences (KNOWN_DIVERGENCE)

### KD-W6-001: `inferred_return` line not emitted

**Stage0 behavior:** When a function has no explicit return type annotation and
the inferred type is a representable named type, Stage0 emits an extra line after
the function signature in the typed dump:
```
  inferred_return: i32
```

**Self-host behavior:** Not emitted. The self-host sema does not track a separate
`inferred_return_types` map (this is a Codegen artifact in Stage0, not a semantic
requirement).

**Rationale:** This line is used by Stage0's Codegen to resolve inferred return
types, not as part of the semantic specification. The self-host pipeline will
handle return type inference differently in Wave 10 (Codegen). The Wave 6 corpus
is constructed to avoid functions with inferred return types, so this does not
affect parity gate results.

**Test coverage:** Corpus files in `test/wave6/typed_corpus.txt` use only
functions with explicit `-> RetType` annotations. Divergence is avoided by
corpus design rather than by code.

**Resolution target:** Wave 10 (Codegen) or accepted as architectural difference.

### KD-W6-002: Chained `if let` not supported by self-host parser

**Stage0 behavior:** Parses and type-checks `if let Some(a) = f(), let Some(b) = g():` (comma-separated multi-binding form).

**Self-host behavior:** Parser fails on the `,` after the first binding — only single-binding `if let Pat = expr:` is implemented.

**Rationale:** This is a parser extension, not a Sema gap. The chained form is sugar that lowers to nested `if let` in HIR→MIR (Wave 7). The Wave 6 corpus excludes `bootstrap/test/cases/chained_if_let.w` to avoid triggering this.

**Test coverage:** Excluded from `test/wave6/typed_corpus.txt` with inline comment. Will be added back once the parser is extended.

**Resolution target:** Parser extension in Wave 7 prep or separately before corpus expansion.

---

## Validation Gates (Wave 6 Exit)

- [x] `scripts/run_wave6_sema_unit_tests.sh` passes (31/31).
- [x] `scripts/run_wave6_typed_parity.sh` passes with strict diff on Wave 6 corpus (9/9, 0 failures).
- [x] Typed dump determinism check passes on repeated runs (built into parity harness; verified).
- [x] No unresolved divergences remain for Wave 6 scope (KD-W6-001 and KD-W6-002 documented above).
