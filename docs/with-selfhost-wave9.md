# Wave 9 Implementation Plan

## Async-MIR (Suspend-Aware Lowering + Generator/Async Split + Select Lowering) for Withc2

## Goal

Implement Wave 9 Async-MIR in the self-host compiler so Stage0 and self-host are
behaviorally identical for async semantics and runtime behavior:

- suspend-aware lowering,
- generator vs async split,
- `select await` lowering,
- full async test coverage.

Wave 9 exit gate:

- async tests pass identically to Stage0 across `check`, `build`, and `run`
  parity suites.

---

## Inputs and Constraints

- Canonical wave definitions:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle behavior:
  - `bootstrap/src/Sema.zig` (async/task semantic checks and diagnostics)
  - `bootstrap/src/Codegen.zig` (await/spawn/async-scope/select lowering)
  - `bootstrap/src/Driver.zig` (async runtime linkage decisions)
  - `bootstrap/test/run_phase4_*.sh` async/runtime suites
  - `bootstrap/test/run_phase2_denied_patterns_tests.sh` (`E0701` may_suspend guard)
- Existing self-host implementation:
  - `src/Mir.w`
  - `src/MirLower.w`
  - `src/Sema.w`
  - `src/Codegen.w`
  - `src/Driver.w`
  - `scripts/parity_states.sh`
- Reference architecture:
  - Zig:
    - `.reference/zig/src/Sema.zig`
    - `.reference/zig/src/Air.zig`
    - `.reference/zig/src/Air/Liveness.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_mir_transform/src/coroutine.rs`
    - `.reference/rust/compiler/rustc_mir_transform/src/coroutine/drop.rs`
    - `.reference/rust/compiler/rustc_mir_transform/src/coroutine/by_move_body.rs`
    - `.reference/rust/compiler/rustc_mir_dataflow/src/impls/liveness.rs`

Constraints:

- Stage0 remains semantic oracle for Wave 9.
- Bootstrap compiler is not changed for Wave 9 feature work.
- Implement in self-host compiler only.
- Keep self-host source in Stage0-safe subset (no bootstrap feature requests).
- Deterministic diagnostics and runtime output are mandatory.
- Wave 8 `KNOWN_DEBT` remains explicit; no silent carry-forward into Wave 9.

---

## Wave 9 Oracle Contract (Parity Target)

Primary parity artifacts:

- `check <file.w>` diagnostics for async semantics.
- `build <file.w>` warnings/errors and runtime-linkage behavior.
- `run <file.w>` output and exit status for async programs.

Wave 9 parity contract:

1. Same pass/fail status as Stage0 for all Wave 9 corpus entries.
2. Same primary error/warning class/message for async diagnostics.
3. Same runtime stdout/stderr + exit code for run-parity entries.
4. Deterministic self-host behavior on repeated runs.
5. No silent test exclusions.

### Three Harness States (Required)

| State | Meaning |
| --- | --- |
| `PASS` | Stage0 and self-host behavior are equivalent for the test. |
| `FAIL` | Unexpected divergence; actionable bug. |
| `KNOWN_DIVERGENCE` | Documented divergence with rationale and owner. |

`KNOWN_DIVERGENCE` entry format for Wave 9 corpus:

`KNOWN_DIVERGENCE|<mode>|<test>|<what_differs>|<correct_compiler>|<why>`

`<mode>` is one of: `check`, `build`, `run`.

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

- Async-MIR pass boundary after MIR + borrow phases.
- Suspend-aware lowering and explicit suspension points.
- Generator vs async lowering split.
- `await` lowering parity (single, tuple, container/task flows).
- `async` block and `async fn` lowering parity.
- `select await` lowering parity (arm semantics + diagnostics).
- `spawn` and `async scope` lowering parity.
- Async runtime linkage parity for async vs sync binaries.
- Wave 9 unit tests and Stage0 parity harness with tri-state outcomes.
- Full Wave 9 coverage map against Stage0 phase4 async suites.

## Out of scope

- Bootstrap changes (except explicit user-approved bug fixes, not planned here).
- Runtime performance tuning.
- New language semantics.
- Non-async feature work.

---

## Deliverables

- Wave 9 Async-MIR implementation in self-host.
- Deterministic Wave 9 `check`/`build`/`run` parity harness.
- Wave 9 unit test harness and full-coverage corpus.
- Explicit `KNOWN_DIVERGENCE` tracking and accounting.
- Wave 9 documentation updates when exit gate is green.

---

## Target File Plan

Implementation (expected touch points):

- `src/AsyncMir.w` (new; Async-MIR data model)
- `src/AsyncLower.w` (new; MIR -> Async-MIR lowering)
- `src/Mir.w` (metadata needed for suspend-aware lowering)
- `src/MirLower.w` (ensure async nodes preserved as Wave 9 input)
- `src/Sema.w` (async diagnostic parity checkpoints where needed)
- `src/Codegen.w` (consume Async-MIR instead of AST-level async stubs)
- `src/Driver.w` (wire Async-MIR pass and optional dump flow)
- `src/main.w` (CLI flag wiring if adding `--dump-async-mir`)

Tests/scripts (new):

- `test/wave9/cases/*.w`
- `test/wave9/async_corpus.txt`
- `scripts/run_wave9_async_unit_tests.sh`
- `scripts/run_wave9_async_parity.sh`

---

## Full Coverage Matrix (Stage0 Phase4 Oracle)

Wave 9 corpus/harness must explicitly cover all relevant Stage0 async suites:

- `run_phase4_async_fn_lowering_tests.sh`
- `run_phase4_await_lowering_tests.sh`
- `run_phase4_async_block_tests.sh`
- `run_phase4_async_scope_tests.sh`
- `run_phase4_select_await_tests.sh`
- `run_phase4_spawn_tests.sh`
- `run_phase4_task_must_use_tests.sh`
- `run_phase4_task_ephemerality_tests.sh`
- `run_phase4_runtime_linkage_tests.sh`
- `run_phase4_channel_tests.sh`
- `run_phase4_task_cancel_tests.sh`
- `run_phase4_send_sync_scopedsend_tests.sh`
- `run_phase4_fiber_context_switch_tests.sh`
- `run_phase4_fiber_pool_reuse_tests.sh`
- `run_phase4_scheduler_work_steal_tests.sh`
- `run_phase4_stack_limits_tests.sh`
- `run_phase4_std_net_scheduler_tests.sh`
- `run_phase4_std_signal_tests.sh`
- `run_phase4_milestone_25_17_25_18_tests.sh`

Cross-phase async safety coverage also required:

- `run_phase2_denied_patterns_tests.sh` (`E0701` may_suspend/no_await_guard)

Any uncovered script behavior requires either:

- equivalent Wave 9 test entries, or
- explicit `KNOWN_DIVERGENCE` entries.

---

## Execution Checklist

## 0) Freeze Wave 9 Contract and Corpus

- [ ] Freeze exact Wave 9 parity target against current Stage0 behavior.
- [ ] Create `test/wave9/async_corpus.txt` with explicit `check`/`build`/`run` mode entries.
- [ ] Map every Stage0 phase4 async script to at least one Wave 9 coverage bucket.
- [ ] Require explicit `KNOWN_DIVERGENCE` for any excluded behavior (no silent exclusions).

## 1) Async-MIR Pass Boundary

- [ ] Introduce `src/AsyncMir.w` as a distinct IR after MIR + borrow phases.
- [ ] Introduce `src/AsyncLower.w` as the sole Wave 9 lowering pass.
- [ ] Define input/output contract:
  - input: borrow-validated `MirModule` + sema/type/source metadata
  - output: `AsyncMirModule` + diagnostics only
- [ ] Keep pass execution deterministic and single-threaded.

## 2) Suspend-Aware IR Model

- [ ] Model suspension points explicitly (await/select/yield boundaries).
- [ ] Model resume targets and state transitions explicitly.
- [ ] Preserve source-span mapping for diagnostics through lowering.
- [ ] Encode storage/drop state required across suspend points.

## 3) Generator vs Async Split

- [ ] Define distinct lowering tracks for generator bodies vs async task bodies.
- [ ] Enforce `yield` legality in generator context only.
- [ ] Ensure async tasks and generator iterators do not share ambiguous runtime shape.
- [ ] Add explicit diagnostics parity tests for misuse cases.

## 4) Await Lowering

- [ ] Lower single-task `.await` to explicit async runtime operations.
- [ ] Lower tuple-await forms (2..12) with Stage0-compatible constraints.
- [ ] Preserve `await?`/Result-flow behavior.
- [ ] Support task-container await paths (`tasks[i].await`, loop-bound task awaits).
- [ ] Match non-task await diagnostics.

## 5) Async Function and Async Block Lowering

- [ ] Lower `async fn` calls to task-handle-producing form.
- [ ] Lower `async: ...` blocks with explicit capture payload semantics.
- [ ] Preserve capture-mode parity (owned vs borrowed) with Stage0 behavior.
- [ ] Match diagnostics for invalid async-block capture/scope cases.

## 6) Spawn and Task Lifecycle Lowering

- [ ] Lower `spawn expr` with task-type validation parity.
- [ ] Ensure spawned tasks are treated as consumed for task-must-use diagnostics.
- [ ] Preserve detach semantics and no-spurious-warning behavior.
- [ ] Add cancel/await lifecycle parity tests where Stage0 performs cleanup.

## 7) Async Scope Lowering

- [ ] Lower `async scope |s|:` with explicit scope-frame tracking.
- [ ] Lower `s.track(task)` semantics with Stage0-compatible restrictions.
- [ ] Enforce `track()` availability only inside active async scope.
- [ ] Preserve scoped-task cleanup semantics on scope exit.

## 8) Select Await Lowering

- [ ] Lower `select await` arms to explicit race/select runtime operations.
- [ ] Preserve arm-binding scope behavior and winner-value flow.
- [ ] Enforce non-empty arm list and task-typed arm diagnostics.
- [ ] Ensure deterministic arm-order behavior where required by Stage0.

## 9) Diagnostics and Warning Parity

- [ ] Match Stage0 async diagnostics for `await`/`spawn`/`select await`/`track`.
- [ ] Match `E0801` task-must-use warning behavior.
- [ ] Match `E0701` may_suspend/no_await_guard behavior.
- [ ] Stabilize diagnostic/warning emission ordering.

## 10) Runtime Linkage and Driver Integration

- [ ] Wire Async-MIR pass into `check`/`build`/`run` pipeline after borrow pass.
- [ ] Ensure async binaries link required runtime objects exactly when needed.
- [ ] Ensure sync binaries do not pull async runtime symbols.
- [ ] Preserve existing `--dump-mir` behavior.
- [ ] Add `--dump-async-mir` (or equivalent) deterministic dump path.

## 11) Unit Test Harness

- [ ] Add `scripts/run_wave9_async_unit_tests.sh`.
- [ ] Add positive/negative unit cases for:
  - await lowering (single + tuple + container)
  - async fn lowering
  - async block capture behavior
  - async scope track semantics
  - spawn validation
  - select await validation
  - task-must-use and task-ephemerality warnings
  - `E0701` may_suspend guard behavior

## 12) Stage0 Parity Harness

- [ ] Add `scripts/run_wave9_async_parity.sh`.
- [ ] Build Stage0 and self-host binaries in harness setup.
- [ ] Run all Wave 9 corpus entries in declared mode (`check`/`build`/`run`) for both compilers.
- [ ] Compare:
  - status codes,
  - normalized primary diagnostics/warnings,
  - runtime stdout/stderr and exit code for run-mode entries.
- [ ] Re-run self-host to assert determinism.
- [ ] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per entry.
- [ ] Fail harness on stale, duplicate, or malformed `KNOWN_DIVERGENCE` entries.

## 13) Known Divergence Governance

- [ ] Extend/reuse `scripts/parity_states.sh` for mode-aware Wave 9 entries.
- [ ] Require every `KNOWN_DIVERGENCE` to be exercised during the run.
- [ ] Fail if declared `KNOWN_DIVERGENCE` count differs from used count.
- [ ] Keep accepted divergence list reviewable and small; no growth without rationale.

## 14) Coverage Closure (Full Coverage Requirement)

- [ ] Produce explicit Stage0 script -> Wave 9 case mapping table.
- [ ] Confirm all Phase4 async scripts are covered by Wave 9 unit/parity entries.
- [ ] Confirm `run_phase2_denied_patterns_tests.sh` `E0701` scenario is covered.
- [ ] Fail Wave 9 harness when mapping has uncovered Stage0 behaviors.

## 15) Documentation and Status Updates

- [ ] Update `docs/with-selfhost-wave9.md` with execution notes as work lands.
- [ ] Update `docs/with-selfhost-plan.md` Wave 9 status after exit gate passes.
- [ ] Update `docs/with-selfhost-detailed-plan.md` with Wave 9 completion notes.
- [ ] Record accepted Wave 9 divergences with rationale and test linkage.

---

## Validation Gates (Wave 9 Exit)

- [ ] `scripts/run_wave9_async_unit_tests.sh` passes.
- [ ] `scripts/run_wave9_async_parity.sh` passes.
- [ ] All Wave 9 corpus entries resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [ ] No unresolved `FAIL` entries remain.
- [ ] Full Stage0 phase4 async coverage is demonstrated and reviewable.
- [ ] No bootstrap changes were required for Wave 9 feature scope.
- [ ] Async behavior parity with Stage0 is achieved for Wave 9 scope.

