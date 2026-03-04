# Wave 11 Implementation Plan

## Driver + CLI (Pipeline Orchestration + Linking + c_import Finalization) for Withc2

## Goal

Implement Wave 11 driver/CLI behavior in the self-host compiler so Stage0 and
self-host are behaviorally identical for:

- full pipeline orchestration,
- link orchestration and runtime/object selection,
- `c_import` finalization (parsing, linking directives, cache behavior, diagnostics).

Wave 11 exit gate:

- driver/CLI/link/c_import behavior matches Stage0 across Wave 11 corpus and
  harnesses.

---

## Inputs and Constraints

- Canonical wave definitions:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle behavior:
  - `bootstrap/src/main.zig`
  - `bootstrap/src/Driver.zig`
  - `bootstrap/src/CImport.zig`
  - Stage0 test oracles:
    - `bootstrap/test/run_phase0_driver_commands_tests.sh`
    - `bootstrap/test/run_phase0_object_link_tests.sh`
    - `bootstrap/test/run_phase0_import_path_regression_tests.sh`
    - `bootstrap/test/run_phase0_c_import_tests.sh`
    - `bootstrap/test/run_phase0_c_import_link_tests.sh`
    - `bootstrap/test/run_phase0_c_import_cache_tests.sh`
    - `bootstrap/test/run_phase0_c_import_milestone_tests.sh`
    - `bootstrap/test/run_phase6_c_import_cache_invalidation_tests.sh`
    - `bootstrap/test/run_phase6_c_import_macro_diagnostics_tests.sh`
- Existing self-host implementation:
  - `src/main.w`
  - `src/Driver.w`
  - `src/Resolve.w`
  - `src/Parser.w`
  - `src/CImport.w`
  - `src/Compilation.w`
  - `scripts/parity_states.sh`
- Reference architecture:
  - Zig:
    - `.reference/zig/src/main.zig`
    - `.reference/zig/src/Driver.zig`
    - `.reference/zig/src/CImport.zig`
    - `.reference/zig/src/link.zig`
    - `.reference/zig/src/Compilation.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_driver/src/lib.rs`
    - `.reference/rust/compiler/rustc_interface/src/interface.rs`
    - `.reference/rust/compiler/rustc_interface/src/passes.rs`
    - `.reference/rust/compiler/rustc_session`

Constraints:

- Stage0 remains semantic/behavioral oracle for Wave 11.
- Bootstrap compiler is not changed for Wave 11 feature work.
- Implement in self-host compiler only.
- Keep self-host source in Stage0-safe subset.
- Deterministic status/output/diagnostics/artifact paths are mandatory.
- Existing accepted `KNOWN_DEBT` from Wave 8 remains explicit and untouched.

---

## Wave 11 Oracle Contract (Parity Target)

Primary parity artifacts:

- Command-level behavior for `check`, `build`, `run`, `test`, `clean`, `help`,
  `version`, and unknown command handling.
- Pipeline stage behavior and error boundaries (parse/resolve/sema/mir/async-mir/codegen/link).
- Link command composition and required runtime/object selection policy.
- `c_import` behavior:
  - header parsing/validation diagnostics,
  - link-lib propagation,
  - cache hit/miss behavior and invalidation,
  - macro/snippet diagnostic behavior.

Wave 11 parity contract:

1. Same pass/fail status as Stage0 for all Wave 11 corpus entries.
2. Same primary diagnostics/warnings class for driver/link/c_import failures.
3. Same runtime stdout/stderr + exit code for `run`/`test` parity entries.
4. Same artifact expectations for build outputs and cleanup policy.
5. Deterministic repeated self-host runs.
6. No silent test exclusions.

### Three Harness States (Required)

| State | Meaning |
| --- | --- |
| `PASS` | Stage0 and self-host behavior are equivalent for the entry. |
| `FAIL` | Unexpected divergence; actionable bug. |
| `KNOWN_DIVERGENCE` | Documented divergence with rationale and owner. |

`KNOWN_DIVERGENCE` format for Wave 11 corpus:

`KNOWN_DIVERGENCE|<mode>|<test>|<what_differs>|<correct_compiler>|<why>`

`<mode>` is one of: `check`, `build`, `run`, `test`, `cli`.

`<correct_compiler>` must be one of: `stage0`, `selfhost`, `neither`.

Each `KNOWN_DIVERGENCE` entry must include:

- which test,
- what differs,
- which compiler is correct,
- why the divergence is accepted.

---

## Scope

## In scope

- Command dispatch and option/flag handling parity in `main` + driver.
- End-to-end stage orchestration parity for `check/build/run/ir/test`.
- Deterministic artifact path policy and cleanup behavior.
- Link orchestration parity, including runtime object and `-l<name>` handling.
- Import path and module resolution behavior needed for driver command parity.
- `c_import` finalization:
  - parser-level argument validation parity,
  - resolve-level link-lib extraction parity,
  - c_import cache and invalidation parity,
  - macro/header diagnostics parity.
- Wave 11 unit/parity harnesses and coverage closure.

## Out of scope

- Bootstrap changes (except explicit user-approved fixes, not planned here).
- New language semantics.
- Non-driver subsystems unrelated to pipeline/link/c_import.
- Post-fixpoint architecture cleanups.

---

## Deliverables

- Wave 11 driver/CLI implementation parity in self-host.
- Deterministic Wave 11 parity harness with tri-state outcomes.
- Wave 11 unit harness for command/link/c_import regression buckets.
- Wave 11 coverage mapping against Stage0 phase0/phase6 driver+c_import scripts.
- Wave 11 documentation/status updates after exit gates pass.

---

## Target File Plan

Implementation (expected touch points):

- `src/main.w` (command surface, option parsing, command diagnostics)
- `src/Driver.w` (pipeline orchestration boundaries, linking, artifact policy)
- `src/Compilation.w` (driver-wrapper behavior exposed to CLI modes)
- `src/Resolve.w` (c_import link-lib extraction and deterministic ordering)
- `src/Parser.w` (c_import syntax/keyword diagnostics parity)
- `src/CImport.w` (cache behavior, macro/snippet diagnostics, finalization)

Tests/scripts (new):

- `test/wave11/cases/*.w`
- `test/wave11/driver_corpus.txt`
- `test/wave11/coverage_manifest.txt`
- `test/wave11/coverage_matrix.md`
- `scripts/run_wave11_driver_unit_tests.sh`
- `scripts/run_wave11_driver_parity.sh`
- `scripts/verify_wave11_coverage.sh`

---

## Full Coverage Matrix (Stage0 Driver/c_import Oracle)

Wave 11 corpus/harness must explicitly cover:

- `run_phase0_driver_commands_tests.sh`
- `run_phase0_object_link_tests.sh`
- `run_phase0_import_path_regression_tests.sh`
- `run_phase0_c_import_tests.sh`
- `run_phase0_c_import_link_tests.sh`
- `run_phase0_c_import_cache_tests.sh`
- `run_phase0_c_import_milestone_tests.sh`
- `run_phase6_c_import_cache_invalidation_tests.sh`
- `run_phase6_c_import_macro_diagnostics_tests.sh`

Any uncovered behavior requires either:

- equivalent Wave 11 corpus entries, or
- explicit `KNOWN_DIVERGENCE` entries.

---

## Execution Checklist

## 0) Freeze Wave 11 Contract and Corpus

- [x] Freeze exact Wave 11 parity target against current Stage0 behavior.
- [x] Create `test/wave11/driver_corpus.txt` with explicit `check|build|run|test|cli` entries.
- [x] Map each Stage0 driver/c_import script bucket to Wave 11 corpus evidence.
- [x] Require explicit `KNOWN_DIVERGENCE` for any excluded behavior.

## 1) CLI Surface and Command Parsing

- [x] Align command set parity (`build`, `run`, `check`, `ir`, `test`, `clean`, `help`, `version`).
- [x] Align missing-arg/unknown-flag/unknown-command diagnostics classes.
- [x] Align mode-specific flag acceptance/rejection behavior.
- [x] Keep command parsing deterministic and side-effect free before execution.

## 2) Pipeline Orchestration Boundaries

- [x] Make `check` stage boundaries parity-clean (parse/resolve/sema/mir/async-mir failure edges).
- [x] Align `build` orchestration (compile -> object -> link -> cleanup) to Stage0 behavior.
- [x] Align `run` orchestration (`build` reuse + process execution status propagation).
- [x] Align `test` command orchestration behavior for package/file filters and status mapping.

## 3) Link Orchestration and Artifact Policy

- [x] Align link command assembly for base object + extras + `-l<name>` ordering.
- [x] Align runtime object selection policy (`helpers.o`, `fiber.o`, `fiber_asm.o`) by symbol/use.
- [x] Align compiler-main bridge linkage policy without leaking to unrelated binaries.
- [x] Keep artifact paths and cleanup deterministic across repeated invocations.

## 4) Import Path and Module Resolution Parity

- [x] Align nested relative and package-qualified import-path resolution behavior.
- [x] Align cycle handling and duplicate-import suppression behavior.
- [x] Align unresolved import diagnostics (primary class + command status).
- [x] Preserve deterministic import expansion order and module graph side effects.

## 5) `c_import` Parse/Resolve Finalization

- [x] Align `use c_import("...", link: "...")` parse acceptance/rejection behavior.
- [x] Align `link:` keyword handling and diagnostics for malformed link arguments.
- [x] Align resolve-side collection and de-duplication order for `link_libs`.
- [x] Align header snippet error reporting class/content to Stage0 parity expectations.

## 6) `c_import` Link and Runtime Behavior

- [x] Align symbol availability behavior for c_import-backed extern calls in `build`/`run`.
- [x] Align missing-link-library failure behavior and command exit status.
- [x] Align multi-library link behavior and deterministic ordering.
- [x] Ensure c_import behavior is parity-clean through imported-module paths.

## 7) `c_import` Cache and Invalidation

- [x] Implement deterministic cache key semantics matching Stage0 behavior.
- [x] Align trace behavior under `WITH_TRACE_CIMPORT_CACHE=1` (hit/miss accounting).
- [x] Align invalidation behavior for link-lib changes and epoch overrides.
- [x] Prevent silent cache growth/regression across multi-module imports.

## 8) Macro and Diagnostics Finalization

- [x] Align simple object-like macro exposure behavior expected by Stage0 tests.
- [x] Align function-like macro handling behavior (skip/ignore semantics) to Stage0 parity.
- [x] Align malformed c_import header diagnostics with context snippet behavior.
- [x] Stabilize diagnostic ordering for multiple c_import diagnostics in one module.

## 9) Determinism and Output Stability

- [x] Re-run identical `check/build/run/test` entries and assert byte-identical stdout/stderr.
- [x] Assert deterministic artifact emission and cleanup paths.
- [x] Assert deterministic command exit-code mapping.
- [x] Guard against nondeterministic link-lib/runtime-object ordering.

## 10) Unit Test Harness

- [x] Add `scripts/run_wave11_driver_unit_tests.sh`.
- [x] Add focused positive/negative unit cases for:
  - CLI argument/flag diagnostics,
  - build/run/test command behavior,
  - object/link behavior,
  - import-path regression buckets,
  - c_import parse/link/cache/macro diagnostics buckets.
- [x] Add deterministic rerun checks for selected high-signal entries.

## 11) Stage0 Parity Harness

- [x] Add `scripts/run_wave11_driver_parity.sh`.
- [x] Build Stage0 and self-host binaries in harness setup.
- [x] Run all Wave 11 corpus entries by declared mode on both compilers.
- [x] Compare status, normalized primary diagnostics, runtime output, and artifact expectations.
- [x] Re-run self-host entries to enforce determinism checks.
- [x] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per entry.

## 12) Known Divergence Governance

- [x] Reuse/extend `scripts/parity_states.sh` for Wave 11 mode set (`check|build|run|test|cli`).
- [x] Require every `KNOWN_DIVERGENCE` entry to be exercised.
- [x] Fail on stale/duplicate/malformed `KNOWN_DIVERGENCE` entries.
- [x] Fail if declared known-divergence count differs from observed used count.

## 13) Coverage Closure

- [x] Produce explicit Stage0-script -> Wave 11 evidence mapping table.
- [x] Add `scripts/verify_wave11_coverage.sh` and fail parity harness on uncovered buckets.
- [x] Keep accepted divergence list reviewable and small.
- [x] Prevent silent corpus shrinkage.

## 14) Documentation and Status Updates

- [x] Update `docs/with-selfhost-wave11.md` execution notes as work lands.
- [x] Update `docs/with-selfhost-plan.md` Wave 11 status after exit gate passes.
- [x] Update `docs/with-selfhost-detailed-plan.md` with Wave 11 completion notes.
- [x] Record accepted Wave 11 divergences with rationale and test linkage.

---


## Execution Notes

- 2026-03-04: Wave 11 unit harness passes via `scripts/run_wave11_driver_unit_tests.sh`.
- 2026-03-04: Wave 11 parity harness passes via `scripts/run_wave11_driver_parity.sh` (`processed=30`, `failures=0`, `known_divergences=2`).
- Accepted Wave 11 known divergences are documented in `test/wave11/driver_corpus.txt`:
  - `check|test/wave11/cases/c_import_macro_constants_ok.w` (`correct_compiler=selfhost`)
  - `check|test/wave11/cases/c_import_macro_function_like_ok.w` (`correct_compiler=selfhost`)
- Coverage gate passes via `scripts/verify_wave11_coverage.sh` (`processed=9`).
- Wave 11 CLI parity harness now executes missing-arg/unknown-flag checks in isolated temp directories and applies CLI timeouts to avoid false hangs.

## Validation Gates (Wave 11 Exit)

- [x] `scripts/run_wave11_driver_unit_tests.sh` passes.
- [x] `scripts/run_wave11_driver_parity.sh` passes.
- [x] All Wave 11 corpus entries resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [x] No unresolved `FAIL` entries remain.
- [x] Coverage verification gate passes for required Stage0 buckets.
- [x] No bootstrap changes were required for Wave 11 feature scope.
- [x] Driver/CLI/link/c_import behavior is parity-clean for Wave 11 scope.
