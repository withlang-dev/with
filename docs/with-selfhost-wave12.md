# Wave 12 Implementation Plan

## Self-Host (Stage1 -> Stage2 -> Stage3 Fixpoint) for Withc2

## Goal

Establish self-host fixpoint and handoff from bootstrap-oracle development to
canonical self-host development:

- Stage1 = Withc2 built by Stage0.
- Stage2 = Withc2 built by Stage1.
- Stage3 = Withc2 built by Stage2.

Wave 12 exit gate:

- Validation Level 1: full test suite passes with self-host.
- Validation Level 2: Stage2 IR is structurally equal to Stage3 IR.
- Validation Level 3 (optional): Stage2 and Stage3 binaries are equal under a
  deterministic build profile.

---

## Inputs and Constraints

- Canonical wave definitions:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle and bootstrap artifacts:
  - `bootstrap/`
  - `scripts/rebuild_selfhost.sh`
  - existing wave harnesses (`scripts/run_wave*_unit_tests.sh`,
    `scripts/run_wave*_parity.sh`)
- Reference architecture and behavior guidance:
  - `.reference/zig`
  - `.reference/rust`
- Existing self-host compiler implementation:
  - `src/`
  - `.with/build/`

Constraints:

- Stage0 remains frozen as semantic oracle in `/bootstrap`.
- Wave 12 does not add language semantics; it validates fixpoint behavior.
- All expected divergences must remain explicit `KNOWN_DIVERGENCE` entries.
- Determinism is mandatory for build, diagnostics, and IR comparison.
- Bootstrap is not extended for self-host convenience during Wave 12.

---

## Wave 12 Oracle Contract (Fixpoint Target)

Primary contract:

1. Stage1/Stage2/Stage3 chain is reproducible.
2. Self-host passes the complete test suite.
3. Stage2 and Stage3 produce structurally equivalent IR outputs for the corpus.
4. Optional binary equality check is stable when deterministic mode is enabled.

Tri-state result policy remains mandatory for parity harnesses:

- `PASS`: behavior matches expected oracle/contract.
- `FAIL`: unexpected regression.
- `KNOWN_DIVERGENCE`: explicit documented divergence with rationale.

---

## Scope

## In scope

- End-to-end self-host chain automation (`stage1`, `stage2`, `stage3`).
- Full-suite execution with Stage2 as canonical self-host candidate.
- Stage2 vs Stage3 IR structural comparison harness and normalization rules.
- Deterministic diagnostics comparison (structured, not raw-text brittle checks).
- Optional deterministic binary equality mode.
- Regression-lock workflow for discovered fixpoint bugs.
- CI policy updates for post-fixpoint development.

## Out of scope

- New language features or semantics changes.
- Bootstrap redesign or bootstrap feature work.
- Performance tuning not required for determinism/fixpoint correctness.

---

## Deliverables

- Wave 12 fixpoint harness script(s) and documentation.
- Stage-chain reproducibility checks wired into local and CI workflows.
- Full-suite aggregate runner with structured result summary.
- IR structural comparator for Stage2 vs Stage3 outputs.
- Optional binary equality gate (opt-in strict mode).
- Post-fixpoint policy rollout in docs/CI.

---

## Target File Plan

Implementation (expected touch points):

- `scripts/rebuild_selfhost.sh` (stage-chain hardening if needed)
- `scripts/run_all_wave_tests.sh` (authoritative full-suite entrypoint)
- `scripts/report_wave_parity_counts.sh` (global PASS/FAIL/KNOWN_DIVERGENCE rollup)
- `scripts/parity_states.sh` (shared tri-state governance)
- `src/main.w`, `src/Driver.w` (only if fixpoint bugs require compiler-side fixes)

New Wave 12 artifacts (planned):

- `scripts/run_wave12_selfhost_fixpoint.sh`
- `scripts/compare_structured_diagnostics.sh`
- `scripts/compare_ir_structural.sh`
- `scripts/compare_binaries_optional.sh`
- `test/wave12/fixpoint_corpus.txt`
- `test/wave12/diagnostic_schema.md`

---

## Execution Checklist

## 0) Freeze Wave 12 Contract

- [ ] Freeze exact Stage1/Stage2/Stage3 definitions and artifact names.
- [ ] Freeze required validation levels and pass criteria.
- [ ] Freeze tri-state parity policy (`PASS`/`FAIL`/`KNOWN_DIVERGENCE`) for all wave harnesses.
- [ ] Record deterministic build environment requirements (flags, env, toolchain assumptions).

## 1) Stage Chain Orchestration

- [ ] Harden `stage1 -> stage2 -> stage3` build chain for reproducible local runs.
- [ ] Ensure runtime bridge/runtime object selection is stable across all three stages.
- [ ] Ensure stage artifacts are written to deterministic paths and cleaned safely.
- [ ] Add explicit failure-mode diagnostics for silent stage build failures.

## 2) Validation Level 1: Full Test Suite Pass

- [ ] Run the complete unit/parity harness set with Stage2 as primary compiler.
- [ ] Verify all wave suites (1..11) are green with no unresolved `FAIL` states.
- [ ] Ensure any remaining expected non-parity behavior is encoded as `KNOWN_DIVERGENCE` only.
- [ ] Produce a single consolidated summary artifact for suite status.

## 3) Validation Level 2: Stage2 vs Stage3 IR Structural Equality

- [ ] Define structural IR equality contract (ignore non-semantic IDs/order noise only when justified).
- [ ] Generate Stage2 and Stage3 IR dumps for a fixed corpus.
- [ ] Compare IR using structural normalizer + comparator (not raw textual diff only).
- [ ] Fail on structural mismatches and emit minimal, actionable diff output.

## 4) Validation Level 3 (Optional): Binary Equality

- [ ] Define deterministic binary-build profile (strip timestamps/path entropy where possible).
- [ ] Build Stage2 and Stage3 binaries under strict deterministic mode.
- [ ] Compare binary hashes and/or bytes.
- [ ] If unequal, classify root cause as nondeterminism vs acceptable platform/toolchain variance.

## 5) Testing Strategy: Unit Tests Per Module

- [ ] Ensure every core compiler module is covered by at least one dedicated unit harness.
- [ ] Add missing module-level tests discovered during Wave 12 audit.
- [ ] Keep module tests fast and deterministic for pre-merge execution.
- [ ] Gate Wave 12 completion on module-test green status.

## 6) Testing Strategy: Golden Diff Tests Per Wave

- [ ] Ensure each wave has a maintained golden/parity corpus.
- [ ] Ensure corpus updates require explicit rationale and review.
- [ ] Detect stale golden fixtures automatically.
- [ ] Prevent silent corpus shrinkage.

## 7) Testing Strategy: Structured Diagnostic Comparison

- [ ] Define normalized diagnostic schema (code, severity, span, primary message, key labels).
- [ ] Compare diagnostics by structure instead of brittle raw text.
- [ ] Keep deterministic ordering checks for equal-priority diagnostics.
- [ ] Integrate structured diagnostic comparison into parity harnesses.

## 8) Testing Strategy: End-to-End Integration

- [ ] Add/maintain end-to-end integration programs covering sync, async, generics, trait objects, and c_import.
- [ ] Run E2E programs through `check`, `build`, and `run` with Stage2.
- [ ] Verify runtime outputs and exit codes against Stage0-oracle expectations.
- [ ] Keep integration corpus stable and reviewable.

## 9) Testing Strategy: Regression Tests Per Bug

- [ ] Require a regression test for every discovered Wave 12 fixpoint bug.
- [ ] Tag regression tests with bug context in comments/docs.
- [ ] Ensure regressions are wired into the appropriate wave harness, not ad-hoc scripts.
- [ ] Track closure of all Wave 12-found regressions before sign-off.

## 10) Known Divergence Governance

- [ ] Ensure every `KNOWN_DIVERGENCE` includes test, what differs, correct compiler, and why.
- [ ] Fail on malformed, duplicate, stale, or unexercised divergence entries.
- [ ] Prevent divergence growth without explicit review notes.
- [ ] Keep divergence accounting visible in final Wave 12 report.

## 11) Fixpoint Decision and Promotion

- [ ] Define objective criteria for declaring Stage2 canonical.
- [ ] Record Stage2 -> Stage3 fixpoint evidence artifacts (suite summary + IR comparison).
- [ ] Produce final Wave 12 readiness report.
- [ ] Approve canonical-stage promotion only when all required gates are green.

## 12) Post-Fixpoint Policy Rollout

- [ ] Set Stage2 as canonical compiler in docs and default workflows.
- [ ] Freeze Stage0 in `/bootstrap` as recovery/oracle path.
- [ ] Ensure all future compiler feature work targets self-host only.
- [ ] Keep CI building bootstrap as a recovery path, not primary dev path.

## 13) CI and Developer Workflow Integration

- [ ] Add Wave 12 fixpoint job(s) to CI (or document exact CI follow-up tasks).
- [ ] Gate merges on full-suite status + divergence accounting sanity.
- [ ] Publish reproducible local commands for Wave 12 verification.
- [ ] Document failure triage playbook for fixpoint regressions.

## 14) Documentation Closure

- [ ] Update `docs/with-selfhost-plan.md` with Wave 12 completion status.
- [ ] Update `docs/with-selfhost-detailed-plan.md` with fixpoint results and canonical-stage decision.
- [ ] Record optional binary-equality outcome and caveats.
- [ ] Archive Wave 12 evidence paths (logs/reports/scripts) for future audits.

---

## Validation Gates (Wave 12 Exit)

- [ ] Validation Level 1 passed: full test suite green on self-host.
- [ ] Validation Level 2 passed: Stage2 IR structurally equals Stage3 IR.
- [ ] Validation Level 3 decision recorded: binary equality pass or justified defer.
- [ ] Stage2 declared canonical and post-fixpoint policy applied.
