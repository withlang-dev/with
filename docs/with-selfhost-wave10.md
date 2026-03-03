# Wave 10 Implementation Plan

## Codegen (MIR -> LLVM + Monomorphization + Vtable Generation + Enum Layout) for Withc2

## Goal

Implement Wave 10 code generation in the self-host compiler so Stage0 and self-host
are behaviorally identical for codegen-visible semantics:

- MIR -> LLVM lowering,
- monomorphization behavior,
- trait-object/vtable codegen,
- enum runtime layout + discriminant behavior.

Wave 10 exit gate:

- programs behave identically to Stage0 for the Wave 10 corpus across `check`,
  `ir`, `build`, and `run` parity suites.

---

## Inputs and Constraints

- Canonical wave definitions:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle behavior:
  - `bootstrap/src/Codegen.zig`
  - `bootstrap/src/Driver.zig`
  - `bootstrap/src/Sema.zig` (generic/trait typing assumptions consumed by codegen)
  - `bootstrap/src/Types.zig`
  - key Stage0 test suites:
    - `bootstrap/test/run_phase0_llvm_codegen_tests.sh`
    - `bootstrap/test/run_phase0_llvm_verify_ir_tests.sh`
    - `bootstrap/test/run_phase2_monomorphization_tests.sh`
    - `bootstrap/test/run_phase2_generic_function_definition_tests.sh`
    - `bootstrap/test/run_phase2_generic_type_definition_tests.sh`
    - `bootstrap/test/run_phase2_generic_inference_tests.sh`
    - `bootstrap/test/run_phase2_unused_instantiation_tests.sh`
    - `bootstrap/test/run_phase2_enum_accessors_tests.sh`
    - `bootstrap/test/run_phase2_enum_variant_shorthand_tests.sh`
    - `bootstrap/test/run_phase5_dyn_trait_vtable_tests.sh`
    - `bootstrap/test/run_phase5_devirtualization_tests.sh`
    - `bootstrap/test/run_phase5_box_ref_dyn_tests.sh`
    - `bootstrap/test/run_phase5_object_safety_diagnostics_tests.sh`
- Existing self-host implementation:
  - `src/Codegen.w`
  - `src/Mir.w`
  - `src/MirLower.w`
  - `src/AsyncMir.w`
  - `src/Driver.w`
  - `src/main.w`
  - `scripts/parity_states.sh`
- Reference architecture:
  - Zig:
    - `.reference/zig/src/Air.zig`
    - `.reference/zig/src/Sema.zig`
    - `.reference/zig/src/Type.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_codegen_ssa/src/mir/mod.rs`
    - `.reference/rust/compiler/rustc_codegen_ssa/src/mir/block.rs`
    - `.reference/rust/compiler/rustc_codegen_ssa/src/mir/rvalue.rs`
    - `.reference/rust/compiler/rustc_codegen_llvm/src/abi.rs`
    - `.reference/rust/compiler/rustc_codegen_llvm/src/type_of.rs`
    - `.reference/rust/compiler/rustc_abi/src/layout.rs`

Constraints:

- Stage0 remains semantic/codegen oracle for Wave 10.
- Bootstrap compiler is not changed for Wave 10 feature work.
- Implement in self-host compiler only.
- Keep self-host source in Stage0-safe subset.
- Deterministic codegen and diagnostics ordering are mandatory.
- Wave 8 debt (borrow pass location) remains explicit and is not silently redefined.

---

## Wave 10 Oracle Contract (Parity Target)

Primary parity artifacts:

- `check <file.w>` diagnostics for codegen-relevant rejects.
- `ir <file.w>` LLVM IR generation success/failure and key structural markers.
- `build <file.w>` object/link success and diagnostics/warnings.
- `run <file.w>` stdout/stderr + exit status.

Wave 10 parity contract:

1. Same pass/fail status as Stage0 for all Wave 10 corpus entries.
2. Same primary diagnostic/warning class for codegen-related failures.
3. Same runtime output and exit behavior for run corpus entries.
4. Deterministic self-host behavior on repeated `ir/build/run`.
5. No silent exclusions.

### Three Harness States (Required)

| State | Meaning |
| --- | --- |
| `PASS` | Stage0 and self-host behavior are equivalent for the test. |
| `FAIL` | Unexpected divergence; actionable bug. |
| `KNOWN_DIVERGENCE` | Documented divergence with rationale and owner. |

`KNOWN_DIVERGENCE` format for Wave 10 corpus:

`KNOWN_DIVERGENCE|<mode>|<test>|<what_differs>|<correct_compiler>|<why>`

`<mode>` in `{check, ir, build, run}`.

`<correct_compiler>` must be one of: `stage0`, `selfhost`, `neither`.

Each `KNOWN_DIVERGENCE` entry must include:

- which test,
- which mode,
- what differs,
- which compiler is correct,
- why the divergence is accepted.

---

## Scope

## In scope

- MIR-based codegen contract and lowering pipeline.
- LLVM type lowering and ABI-sensitive call lowering used by Stage0-visible behavior.
- Generic instantiation/monomorphization parity.
- Trait-object/vtable generation and dynamic dispatch parity.
- Enum runtime layout/discriminant/payload behavior parity.
- Deterministic `ir/build/run` harnesses with tri-state divergence governance.
- Wave 10 unit + parity corpus with explicit coverage mapping.

## Out of scope

- Bootstrap changes (except explicit user-approved bug fixes, not planned here).
- New language semantics.
- Aggressive optimizer tuning/perf-only work.
- Post-fixpoint architecture cleanup unrelated to Wave 10 exit gates.

---

## Deliverables

- Wave 10 codegen implementation in self-host aligned to MIR contract.
- Deterministic Wave 10 `check`/`ir`/`build`/`run` parity harness.
- Wave 10 unit corpus for MIR->LLVM, mono, vtable, enum layout behavior.
- Explicit `KNOWN_DIVERGENCE` governance with accounting gates.
- Wave 10 documentation updates after exit gate passes.

---

## Target File Plan

Implementation (expected touch points):

- `src/Codegen.w` (existing backend; migrate/align to MIR-first contract)
- `src/Driver.w` (pipeline handoff from MIR/Async-MIR into codegen)
- `src/Mir.w` (metadata needed by backend lowering fidelity)
- `src/MirLower.w` (ensure backend-required MIR invariants)
- `src/AsyncMir.w` (async-codegen interaction points where required)
- `src/main.w` (`ir` command stability and optional dump/control flags)

Optional refactor split if needed during execution:

- `src/CodegenMir.w` (new; MIR->LLVM lowering helpers)
- `src/CodegenLayout.w` (new; struct/enum/option/result layout helpers)
- `src/CodegenVtable.w` (new; vtable + dyn dispatch helpers)

Tests/scripts (new):

- `test/wave10/cases/*.w`
- `test/wave10/codegen_corpus.txt`
- `test/wave10/coverage_matrix.md`
- `test/wave10/coverage_manifest.txt`
- `scripts/run_wave10_codegen_unit_tests.sh`
- `scripts/run_wave10_codegen_parity.sh`
- `scripts/verify_wave10_coverage.sh`

---

## Coverage Matrix (Stage0 Oracle Buckets)

Wave 10 corpus/harness must explicitly cover:

- LLVM/IR emission:
  - `run_phase0_llvm_codegen_tests.sh`
  - `run_phase0_llvm_verify_ir_tests.sh`
- Monomorphization/generic codegen:
  - `run_phase2_monomorphization_tests.sh`
  - `run_phase2_generic_function_definition_tests.sh`
  - `run_phase2_generic_type_definition_tests.sh`
  - `run_phase2_generic_inference_tests.sh`
  - `run_phase2_unused_instantiation_tests.sh`
- Enum lowering/layout behavior:
  - `run_phase2_enum_accessors_tests.sh`
  - `run_phase2_enum_variant_shorthand_tests.sh`
- Trait object/vtable/dyn dispatch:
  - `run_phase5_dyn_trait_vtable_tests.sh`
  - `run_phase5_devirtualization_tests.sh`
  - `run_phase5_box_ref_dyn_tests.sh`
  - `run_phase5_object_safety_diagnostics_tests.sh`

Any uncovered behavior requires either:

- equivalent Wave 10 corpus entries, or
- explicit `KNOWN_DIVERGENCE` entries.

---

## Execution Checklist

## 0) Freeze Wave 10 Contract and Corpus

- [ ] Freeze exact Wave 10 parity target against current Stage0 behavior.
- [ ] Create `test/wave10/codegen_corpus.txt` with explicit `check|ir|build|run` entries.
- [ ] Map each Stage0 coverage bucket to Wave 10 corpus evidence.
- [ ] Require explicit `KNOWN_DIVERGENCE` for any excluded behavior.

## 1) Backend Boundary (MIR -> LLVM)

- [ ] Define Wave 10 backend boundary as MIR (not AST) input contract.
- [ ] Ensure MIR invariants needed by backend are explicit and validated.
- [ ] Keep backend execution deterministic and single-threaded.
- [ ] Preserve existing `ir/build/run` UX behavior while switching internals.

## 2) MIR Instruction Lowering

- [ ] Lower MIR statements (`assign`, storage live/dead, drop) to LLVM operations.
- [ ] Lower MIR terminators (`goto`, `switch`, `call`, `return`, cleanup edges) to LLVM CFG.
- [ ] Preserve evaluation order and side-effect ordering parity with Stage0.
- [ ] Ensure block/phi wiring is deterministic and verifier-clean.

## 3) LLVM Type + ABI Lowering

- [ ] Centralize With type -> LLVM type mapping used by backend.
- [ ] Align primitive/integer cast and width behavior to Stage0.
- [ ] Align aggregate passing/return strategy to Stage0-visible behavior.
- [ ] Keep object emission verifier-clean across all Wave 10 corpus entries.

## 4) Monomorphization

- [ ] Ensure generic function instantiation keys are deterministic and stable.
- [ ] Ensure only used instantiations are emitted (no missing and no accidental duplication).
- [ ] Preserve mangling parity expectations for `ir` corpus checks.
- [ ] Match Stage0 behavior for uninferred/invalid generic use diagnostics.

## 5) Vtable Generation + Dyn Dispatch

- [ ] Generate trait vtable globals with deterministic method slot ordering.
- [ ] Lower `dyn` coercions to concrete `{data_ptr, vtable_ptr}` representation parity.
- [ ] Lower dyn method dispatch via vtable call path with Stage0-compatible behavior.
- [ ] Preserve devirtualization behavior for known-concrete dyn values where Stage0 does.

## 6) Enum Layout + Discriminants

- [ ] Define deterministic enum layout contract (tag + payload strategy) for self-host.
- [ ] Align discriminant/tag semantics with Stage0 runtime behavior.
- [ ] Align payload storage/reads/writes and variant accessor behavior.
- [ ] Add explicit tests for unit/payload/multi-payload enum runtime correctness.

## 7) Runtime and Link Integration

- [ ] Ensure codegen-required runtime symbols are linked exactly when needed.
- [ ] Keep sync and async runtime linkage policies consistent with Wave 9 behavior.
- [ ] Ensure no spurious LLVM bridge/runtime dependencies in unrelated binaries.
- [ ] Keep object cleanup and deterministic artifact paths stable.

## 8) Diagnostics + Determinism

- [ ] Match Stage0 primary diagnostics for codegen-time rejects.
- [ ] Stabilize codegen error detail ordering and text normalization for parity harness.
- [ ] Re-run self-host `ir/build/run` to enforce deterministic outputs/status.
- [ ] Guard against nondeterministic symbol emission order.

## 9) Unit Test Harness

- [ ] Add `scripts/run_wave10_codegen_unit_tests.sh`.
- [ ] Add focused positive/negative unit cases for:
  - MIR->LLVM control-flow lowering
  - monomorphization (multi-instantiation + uninferred failure)
  - vtable generation and dyn dispatch
  - devirtualization known-concrete path
  - enum layout/accessor runtime behavior
  - LLVM IR emission success/failure paths
- [ ] Add deterministic `ir` emission assertion for selected corpus entries.

## 10) Stage0 Parity Harness

- [ ] Add `scripts/run_wave10_codegen_parity.sh`.
- [ ] Build Stage0 and self-host binaries in harness setup.
- [ ] Run all Wave 10 corpus entries by declared mode (`check|ir|build|run`) on both compilers.
- [ ] Compare status, normalized primary diagnostics, and runtime output/exit status.
- [ ] Re-run self-host entries for determinism checks.
- [ ] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per entry.

## 11) Known Divergence Governance

- [ ] Reuse/extend `scripts/parity_states.sh` mode-aware validation for Wave 10.
- [ ] Require every `KNOWN_DIVERGENCE` entry to be exercised.
- [ ] Fail on stale/duplicate/malformed `KNOWN_DIVERGENCE` entries.
- [ ] Fail if declared known-divergence count differs from observed used count.

## 12) Coverage Closure

- [ ] Produce explicit Stage0-script -> Wave 10 evidence mapping table.
- [ ] Add `scripts/verify_wave10_coverage.sh` and fail parity harness on uncovered buckets.
- [ ] Keep accepted divergence list reviewable and small.
- [ ] Prevent silent corpus shrinkage.

## 13) Documentation and Status Updates

- [ ] Update `docs/with-selfhost-wave10.md` execution notes as work lands.
- [ ] Update `docs/with-selfhost-plan.md` Wave 10 status after exit gate passes.
- [ ] Update `docs/with-selfhost-detailed-plan.md` with Wave 10 completion notes.
- [ ] Record accepted Wave 10 divergences with rationale and test linkage.

---

## Validation Gates (Wave 10 Exit)

- [ ] `scripts/run_wave10_codegen_unit_tests.sh` passes.
- [ ] `scripts/run_wave10_codegen_parity.sh` passes.
- [ ] All Wave 10 corpus entries resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [ ] No unresolved `FAIL` entries remain.
- [ ] Coverage verification gate passes for required Stage0 buckets.
- [ ] No bootstrap changes were required for Wave 10 feature scope.
- [ ] Programs behave identically to Stage0 for Wave 10 scope.

## Execution Notes (Current)

- Wave 10 planning document initialized.
- Implementation intentionally deferred to execution phase.
