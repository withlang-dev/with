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

- [x] Freeze exact Wave 10 parity target against current Stage0 behavior.
- [x] Create `test/wave10/codegen_corpus.txt` with explicit `check|ir|build|run` entries.
- [x] Map each Stage0 coverage bucket to Wave 10 corpus evidence.
- [x] Require explicit `KNOWN_DIVERGENCE` for any excluded behavior.

## 1) Backend Boundary (MIR -> LLVM)

- [x] Define Wave 10 backend boundary as MIR (not AST) input contract.
- [x] Ensure MIR invariants needed by backend are explicit and validated.
- [x] Keep backend execution deterministic and single-threaded.
- [x] Preserve existing `ir/build/run` UX behavior while switching internals.

## 2) MIR Instruction Lowering

- [x] Lower MIR statements (`assign`, storage live/dead, drop) to LLVM operations.
- [x] Lower MIR terminators (`goto`, `switch`, `call`, `return`, cleanup edges) to LLVM CFG.
- [x] Preserve evaluation order and side-effect ordering parity with Stage0.
- [x] Ensure block/phi wiring is deterministic and verifier-clean.

## 3) LLVM Type + ABI Lowering

- [x] Centralize With type -> LLVM type mapping used by backend.
- [x] Align primitive/integer cast and width behavior to Stage0.
- [x] Align aggregate passing/return strategy to Stage0-visible behavior.
- [x] Keep object emission verifier-clean across all Wave 10 corpus entries.

## 4) Monomorphization

- [x] Ensure generic function instantiation keys are deterministic and stable.
- [x] Ensure only used instantiations are emitted (no missing and no accidental duplication).
- [x] Preserve mangling parity expectations for `ir` corpus checks.
- [x] Match Stage0 behavior for uninferred/invalid generic use diagnostics.

## 5) Vtable Generation + Dyn Dispatch

- [x] Generate trait vtable globals with deterministic method slot ordering.
- [x] Lower `dyn` coercions to concrete `{data_ptr, vtable_ptr}` representation parity.
- [x] Lower dyn method dispatch via vtable call path with Stage0-compatible behavior.
- [x] Preserve devirtualization behavior for known-concrete dyn values where Stage0 does.

## 6) Enum Layout + Discriminants

- [x] Define deterministic enum layout contract (tag + payload strategy) for self-host.
- [x] Align discriminant/tag semantics with Stage0 runtime behavior.
- [x] Align payload storage/reads/writes and variant accessor behavior.
- [x] Add explicit tests for unit/payload/multi-payload enum runtime correctness.

## 7) Runtime and Link Integration

- [x] Ensure codegen-required runtime symbols are linked exactly when needed.
- [x] Keep sync and async runtime linkage policies consistent with Wave 9 behavior.
- [x] Ensure no spurious LLVM bridge/runtime dependencies in unrelated binaries.
- [x] Keep object cleanup and deterministic artifact paths stable.

## 8) Diagnostics + Determinism

- [x] Match Stage0 primary diagnostics for codegen-time rejects.
- [x] Stabilize codegen error detail ordering and text normalization for parity harness.
- [x] Re-run self-host `ir/build/run` to enforce deterministic outputs/status.
- [x] Guard against nondeterministic symbol emission order.

## 9) Unit Test Harness

- [x] Add `scripts/run_wave10_codegen_unit_tests.sh`.
- [x] Add focused positive/negative unit cases for:
  - MIR->LLVM control-flow lowering
  - monomorphization (multi-instantiation + uninferred failure)
  - vtable generation and dyn dispatch
  - devirtualization known-concrete path
  - enum layout/accessor runtime behavior
  - LLVM IR emission success/failure paths
- [x] Add deterministic `ir` emission assertion for selected corpus entries.

## 10) Stage0 Parity Harness

- [x] Add `scripts/run_wave10_codegen_parity.sh`.
- [x] Build Stage0 and self-host binaries in harness setup.
- [x] Run all Wave 10 corpus entries by declared mode (`check|ir|build|run`) on both compilers.
- [x] Compare status, normalized primary diagnostics, and runtime output/exit status.
- [x] Re-run self-host entries for determinism checks.
- [x] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per entry.

## 11) Known Divergence Governance

- [x] Reuse/extend `scripts/parity_states.sh` mode-aware validation for Wave 10.
- [x] Require every `KNOWN_DIVERGENCE` entry to be exercised.
- [x] Fail on stale/duplicate/malformed `KNOWN_DIVERGENCE` entries.
- [x] Fail if declared known-divergence count differs from observed used count.

## 12) Coverage Closure

- [x] Produce explicit Stage0-script -> Wave 10 evidence mapping table.
- [x] Add `scripts/verify_wave10_coverage.sh` and fail parity harness on uncovered buckets.
- [x] Keep accepted divergence list reviewable and small.
- [x] Prevent silent corpus shrinkage.

## 13) Documentation and Status Updates

- [x] Update `docs/with-selfhost-wave10.md` execution notes as work lands.
- [x] Update `docs/with-selfhost-plan.md` Wave 10 status after exit gate passes.
- [x] Update `docs/with-selfhost-detailed-plan.md` with Wave 10 completion notes.
- [x] Record accepted Wave 10 divergences with rationale and test linkage.

---

## Validation Gates (Wave 10 Exit)

- [x] `scripts/run_wave10_codegen_unit_tests.sh` passes.
- [x] `scripts/run_wave10_codegen_parity.sh` passes.
- [x] All Wave 10 corpus entries resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [x] No unresolved `FAIL` entries remain.
- [x] Coverage verification gate passes for required Stage0 buckets.
- [x] No bootstrap changes were required for Wave 10 feature scope.
- [x] Programs behave identically to Stage0 for Wave 10 scope.

## Execution Notes (Current)

- Added Wave 10 harness artifacts:
  - `scripts/run_wave10_codegen_unit_tests.sh`
  - `scripts/run_wave10_codegen_parity.sh`
  - `scripts/verify_wave10_coverage.sh`
  - `test/wave10/coverage_manifest.txt`
  - `test/wave10/coverage_matrix.md`
- Expanded `test/wave10/codegen_corpus.txt` to include explicit `check|ir|build|run` coverage across LLVM/codegen, generics/monomorphization, enum accessors/shorthand, dyn/vtable, devirtualization, and object-safety diagnostics.
- Parity state governance was extended to support `ir` mode entries in `scripts/parity_states.sh`.
- Added Wave 10 regression cases for dyn missing-impl diagnostics:
  - `test/wave10/cases/dyn_missing_impl_fail.w`
  - `test/wave10/cases/ref_dyn_missing_impl_fail.w`
  - `test/wave10/cases/box_dyn_missing_impl_fail.w`
- Self-host codegen now emits unresolved `printf` calls from `c_import`-style programs (`src/Codegen.w`) via a minimal variadic fallback declaration path, restoring `llvm_extern` run parity.
- Backend entry for `ir/build/run` now consumes MIR first (`Driver.ensure_codegen_mir` + `Codegen.gen_module_from_mir`) and validates MIR invariants through `validate_mir_module` before LLVM emission.
- MIR validation now enforces explicit backend invariants (table length coherence, index/span bounds, terminator/statement/reference integrity, and deterministic body symbol mapping) in `src/Mir.w`.
- Section 3 LLVM type/ABI lowering updates landed in `src/Codegen.w`:
  - centralized primitive/user type lookup (`resolve_primitive_named_type` + `resolve_user_named_type`),
  - Stage0-style integer-width coercion only for implicit type adaptation,
  - aggregate autoref for call arguments to `&T`/pointer params,
  - shared coercion enforcement in AST+MIR call lowering to prevent verifier-invalid calls.
- Added Wave 10 ABI regression corpus case:
  - `test/wave10/cases/abi_ref_param_autoref.w`
  - wired into unit harness and parity corpus (`check|ir|build|run`).
- Section 4 monomorphization hardening landed in `src/Codegen.w`:
  - removed implicit `i32` fallback for unbound generic params in function monomorphization,
  - require full type-parameter binding before mangling/emission (`unknown type` failure parity),
  - aligned fallback mangling tokens with Stage0 (`int`/`unknown`),
  - added dedicated monomorphized-function cache tracking (`mono_values`/`mono_types`) to keep specialization emission deterministic and non-duplicated.
- Added Wave 10 monomorphization regression cases:
  - `test/wave10/cases/generic_instantiation_key_order.w`
  - `test/wave10/cases/generic_instantiation_reuse.w`
  - wired into unit harness + parity corpus (`check|ir|build|run`) with explicit IR symbol-count assertions.
- Section 6 enum/discriminant alignment landed in `src/Codegen.w`:
  - deterministic enum-type selection by LLVM type + variant symbol (avoids map-collision ambiguity),
  - Stage0-compatible enum accessor lowering for `.is_*()` and `.as_*[_ref|_mut]()` on enum values,
  - unit-variant `as_*` now rejects at codegen time (`unsupported call`) to match Stage0 `ir/build` behavior.
- Added explicit Wave 10 enum runtime correctness cases:
  - `test/wave10/cases/enum_layout_unit_runtime.w`
  - `test/wave10/cases/enum_layout_payload_runtime.w`
  - `test/wave10/cases/enum_layout_multi_payload_runtime.w`
  - wired into parity corpus for `check|ir|build|run`.
- Section 7 runtime/link integration landed in `src/Driver.w`:
  - helpers runtime object linking is now symbol-driven (`nm -u` probe over emitted object) with conservative fallback when probing is unavailable,
  - async runtime linkage remains Wave 9-consistent (`AsyncMirModule.requires_async_runtime()` gates `fiber.o` + `fiber_asm.o`),
  - missing required runtime objects now fail with explicit diagnostics (`runtime/helpers.o`, `runtime/fiber.o`, `runtime/fiber_asm.o`),
  - `c_import` link libraries collected during resolve are now propagated into linker invocation (`-l<name>`),
  - LLVM bridge runtime remains scoped to compiler-main builds only (no unrelated binary dependency).
- Added runtime-linkage parity coverage entries:
  - `test/wave9/cases/runtime_linkage_sync_ok.w`
  - `test/wave9/cases/runtime_linkage_async_ok.w`
  - wired into Wave 10 corpus for `check|build|run`.
- Current gate status:
  - `./scripts/run_wave10_codegen_unit_tests.sh` -> PASS
  - `./scripts/verify_wave10_coverage.sh` -> PASS (`processed=13`)
  - `./scripts/run_wave10_codegen_parity.sh` -> PASS (`processed=104`, `failures=0`, `known_divergences=1`)
- Resolved Wave 10 parity gaps in self-host (`src/Sema.w`, `src/Codegen.w`):
  - enum shorthand typed-context flow now matches Stage0 in `check` and `run`,
  - enum accessor runtime output now matches Stage0 for `run|bootstrap/test/cases/enum_accessor.w`,
  - aggregate enum equality lowering is verifier-clean under MIR->LLVM (no struct `icmp` invalid IR).
- Wave 10 accepted `KNOWN_DIVERGENCE` set is now:
  - `ir|bootstrap/test/cases/enum_accessor_ref.w` (`selfhost` correct; Stage0 IR path still lacks accessor-ref lowering).
