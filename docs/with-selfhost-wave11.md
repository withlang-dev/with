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

- [ ] Freeze exact Wave 11 parity target against current Stage0 behavior.
- [ ] Create `test/wave11/driver_corpus.txt` with explicit `check|build|run|test|cli` entries.
- [ ] Map each Stage0 driver/c_import script bucket to Wave 11 corpus evidence.
- [ ] Require explicit `KNOWN_DIVERGENCE` for any excluded behavior.

## 1) CLI Surface and Command Parsing

- [ ] Align command set parity (`build`, `run`, `check`, `ir`, `test`, `clean`, `help`, `version`).
- [ ] Align missing-arg/unknown-flag/unknown-command diagnostics classes.
- [ ] Align mode-specific flag acceptance/rejection behavior.
- [ ] Keep command parsing deterministic and side-effect free before execution.

## 2) Pipeline Orchestration Boundaries

- [ ] Make `check` stage boundaries parity-clean (parse/resolve/sema/mir/async-mir failure edges).
- [ ] Align `build` orchestration (compile -> object -> link -> cleanup) to Stage0 behavior.
- [ ] Align `run` orchestration (`build` reuse + process execution status propagation).
- [ ] Align `test` command orchestration behavior for package/file filters and status mapping.

## 3) Link Orchestration and Artifact Policy

- [ ] Align link command assembly for base object + extras + `-l<name>` ordering.
- [ ] Align runtime object selection policy (`helpers.o`, `fiber.o`, `fiber_asm.o`) by symbol/use.
- [ ] Align compiler-main bridge linkage policy without leaking to unrelated binaries.
- [ ] Keep artifact paths and cleanup deterministic across repeated invocations.

## 4) Import Path and Module Resolution Parity

- [ ] Align nested relative and package-qualified import-path resolution behavior.
- [ ] Align cycle handling and duplicate-import suppression behavior.
- [ ] Align unresolved import diagnostics (primary class + command status).
- [ ] Preserve deterministic import expansion order and module graph side effects.

## 5) `c_import` Parse/Resolve Finalization

- [ ] Align `use c_import("...", link: "...")` parse acceptance/rejection behavior.
- [ ] Align `link:` keyword handling and diagnostics for malformed link arguments.
- [ ] Align resolve-side collection and de-duplication order for `link_libs`.
- [ ] Align header snippet error reporting class/content to Stage0 parity expectations.

## 6) `c_import` Link and Runtime Behavior

- [ ] Align symbol availability behavior for c_import-backed extern calls in `build`/`run`.
- [ ] Align missing-link-library failure behavior and command exit status.
- [ ] Align multi-library link behavior and deterministic ordering.
- [ ] Ensure c_import behavior is parity-clean through imported-module paths.

## 7) `c_import` Cache and Invalidation

- [ ] Implement deterministic cache key semantics matching Stage0 behavior.
- [ ] Align trace behavior under `WITH_TRACE_CIMPORT_CACHE=1` (hit/miss accounting).
- [ ] Align invalidation behavior for link-lib changes and epoch overrides.
- [ ] Prevent silent cache growth/regression across multi-module imports.

## 8) Macro and Diagnostics Finalization

- [ ] Align simple object-like macro exposure behavior expected by Stage0 tests.
- [ ] Align function-like macro handling behavior (skip/ignore semantics) to Stage0 parity.
- [ ] Align malformed c_import header diagnostics with context snippet behavior.
- [ ] Stabilize diagnostic ordering for multiple c_import diagnostics in one module.

## 9) Determinism and Output Stability

- [ ] Re-run identical `check/build/run/test` entries and assert byte-identical stdout/stderr.
- [ ] Assert deterministic artifact emission and cleanup paths.
- [ ] Assert deterministic command exit-code mapping.
- [ ] Guard against nondeterministic link-lib/runtime-object ordering.

## 10) Unit Test Harness

- [ ] Add `scripts/run_wave11_driver_unit_tests.sh`.
- [ ] Add focused positive/negative unit cases for:
  - CLI argument/flag diagnostics,
  - build/run/test command behavior,
  - object/link behavior,
  - import-path regression buckets,
  - c_import parse/link/cache/macro diagnostics buckets.
- [ ] Add deterministic rerun checks for selected high-signal entries.

## 11) Stage0 Parity Harness

- [ ] Add `scripts/run_wave11_driver_parity.sh`.
- [ ] Build Stage0 and self-host binaries in harness setup.
- [ ] Run all Wave 11 corpus entries by declared mode on both compilers.
- [ ] Compare status, normalized primary diagnostics, runtime output, and artifact expectations.
- [ ] Re-run self-host entries to enforce determinism checks.
- [ ] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per entry.

## 12) Known Divergence Governance

- [ ] Reuse/extend `scripts/parity_states.sh` for Wave 11 mode set (`check|build|run|test|cli`).
- [ ] Require every `KNOWN_DIVERGENCE` entry to be exercised.
- [ ] Fail on stale/duplicate/malformed `KNOWN_DIVERGENCE` entries.
- [ ] Fail if declared known-divergence count differs from observed used count.

## 13) Coverage Closure

- [ ] Produce explicit Stage0-script -> Wave 11 evidence mapping table.
- [ ] Add `scripts/verify_wave11_coverage.sh` and fail parity harness on uncovered buckets.
- [ ] Keep accepted divergence list reviewable and small.
- [ ] Prevent silent corpus shrinkage.

## 14) Documentation and Status Updates

- [ ] Update `docs/with-selfhost-wave11.md` execution notes as work lands.
- [ ] Update `docs/with-selfhost-plan.md` Wave 11 status after exit gate passes.
- [ ] Update `docs/with-selfhost-detailed-plan.md` with Wave 11 completion notes.
- [ ] Record accepted Wave 11 divergences with rationale and test linkage.

---

## Validation Gates (Wave 11 Exit)

- [ ] `scripts/run_wave11_driver_unit_tests.sh` passes.
- [ ] `scripts/run_wave11_driver_parity.sh` passes.
- [ ] All Wave 11 corpus entries resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [ ] No unresolved `FAIL` entries remain.
- [ ] Coverage verification gate passes for required Stage0 buckets.
- [ ] No bootstrap changes were required for Wave 11 feature scope.
- [ ] Driver/CLI/link/c_import behavior is parity-clean for Wave 11 scope.
