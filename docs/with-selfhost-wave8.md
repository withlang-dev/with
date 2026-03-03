# Wave 8 Implementation Plan

## Borrow Checking (NLL + Aliasing + Ephemeral) for Withc2

## Goal

Implement Wave 8 borrow checking in the self-host compiler with a MIR/CFG-based
analysis that matches Stage0 diagnostics for:

- NLL borrow expiration on control-flow.
- aliasing enforcement (shared vs exclusive, including field disjointness).
- ephemeral value/reference rules.

Wave 8 exit gate:

- borrow-related diagnostics from self-host match Stage0 on the Wave 8 corpus.

---

## Inputs and Constraints

- Canonical wave definitions:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle behavior:
  - `bootstrap/src/Sema.zig`
    - `checkBorrowCreate`
    - `areBorrowsDisjoint`
    - `expireDeadBorrows`
    - `expireBorrowsInScope`
    - move diagnostics (`use of moved value`)
    - ephemeral diagnostics and boundary checks
  - `bootstrap/src/BorrowCfg.zig`
  - `bootstrap/test/run_phase1_*.sh` borrow/NLL/ephemeral suites
- Existing self-host implementation:
  - `src/Sema.w`
  - `src/BorrowCfg.w`
  - `src/Mir.w`
  - `src/MirLower.w`
  - `src/Driver.w`
  - `scripts/parity_states.sh`
- Reference architecture:
  - Zig:
    - `.reference/zig/src/Sema.zig`
    - `.reference/zig/src/Air/Liveness.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_borrowck/src/lib.rs`
    - `.reference/rust/compiler/rustc_borrowck/src/nll.rs`
    - `.reference/rust/compiler/rustc_borrowck/src/places_conflict.rs`
    - `.reference/rust/compiler/rustc_mir_dataflow/src/impls/liveness.rs`

Constraints:

- Stage0 remains semantic oracle for Wave 8.
- Bootstrap compiler is not changed for Wave 8 feature work.
- Implement in self-host compiler only.
- Keep self-host source in Stage0-safe subset (no bootstrap feature requests).
- Deterministic diagnostics ordering is mandatory.
- Async-MIR borrow semantics across suspension points are out of scope (Wave 9).

---

## Wave 8 Oracle Contract (Parity Target)

Primary parity artifact:

- `check <file.w>` diagnostic behavior for borrow/move/ephemeral failures.

Wave 8 parity contract:

1. Same pass/fail status as Stage0 for Wave 8 corpus files.
2. Same primary error class/message for borrow/move/ephemeral diagnostics.
3. Deterministic ordering when multiple diagnostics are emitted.
4. No silent test exclusions.

### Three Harness States (Required)

| State | Meaning |
| --- | --- |
| `PASS` | Stage0 and self-host behavior are equivalent for the test. |
| `FAIL` | Unexpected divergence; actionable bug. |
| `KNOWN_DIVERGENCE` | Documented divergence with rationale and owner. |

`KNOWN_DIVERGENCE` corpus line format:

`KNOWN_DIVERGENCE|<test>|<what_differs>|<correct_compiler>|<why>`

`<correct_compiler>` must be one of: `stage0`, `selfhost`, `neither`.

Each `KNOWN_DIVERGENCE` entry must include:

- which test,
- what differs,
- which compiler is correct,
- why the divergence is accepted.

---

## Scope

## In scope

- MIR/CFG-driven borrow checking pass in self-host.
- NLL expiration on CFG (not statement-local only).
- Borrow conflict detection parity with Stage0 messaging.
- Disjoint field borrow rules parity.
- Use-after-move and reinitialization interactions in borrow contexts.
- Ephemeral propagation and boundary diagnostics parity.
- Wave 8 unit tests and Stage0 parity harness with tri-state outcomes.

## Out of scope

- Bootstrap changes (except explicit user-approved bug fixes, not planned here).
- Async suspension-aware borrow model (Wave 9).
- Borrow checker optimizations or performance tuning.
- New language semantics.

---

## Deliverables

- Wave 8 borrow-checking implementation in self-host.
- Deterministic Wave 8 diagnostic parity harness.
- Wave 8 unit test harness and corpus.
- Explicit `KNOWN_DIVERGENCE` tracking and accounting.
- Wave 8 documentation updates when exit gate is green.

---

## Target File Plan

Implementation (expected touch points):

- `src/BorrowCheck.w` (new; primary Wave 8 pass)
- `src/BorrowCfg.w` (CFG/liveness support needed by Wave 8)
- `src/Mir.w` (place/projection metadata needed for alias checks)
- `src/MirLower.w` (if additional source-map metadata is required)
- `src/Sema.w` (handoff points; remove/align partial borrow logic)
- `src/Driver.w` (wire borrow pass into `check` pipeline)

Tests/scripts (new):

- `test/wave8/cases/*.w`
- `test/wave8/borrow_corpus.txt`
- `scripts/run_wave8_borrow_unit_tests.sh`
- `scripts/run_wave8_borrow_parity.sh`

---

## Execution Checklist

## 0) Freeze Wave 8 Contract and Corpus

- [ ] Freeze exact Wave 8 diagnostic parity target against current Stage0 behavior.
- [ ] Create `test/wave8/borrow_corpus.txt` with explicit coverage buckets.
- [ ] Include Stage0 phase1 borrow suites in corpus planning:
  - `nll`
  - `borrow overlap`
  - `disjoint field borrow`
  - `use-after-move`
  - `ephemeral boundary`
  - `ephemeral propagation`
  - `ref return provenance`
  - `cfg`
- [ ] For any excluded case, require a `KNOWN_DIVERGENCE` entry (no silent exclusions).

## 1) Borrow Pass Boundary

- [ ] Introduce `src/BorrowCheck.w` as a distinct pass after MIR lowering.
- [ ] Define pass input/output contract:
  - input: `MirModule` + sema/type/source metadata
  - output: diagnostics only (no semantic redesign)
- [ ] Keep Stage0-compatible behavior as the correctness priority over architecture polish.
- [ ] Ensure pass execution is deterministic and single-threaded.

## 2) Place and Projection Model

- [ ] Define canonical place identity for alias checks: root local + projection path.
- [ ] Encode field-level borrow precision needed for disjoint-field acceptance.
- [ ] Handle whole-place borrow overlap correctly against field borrows.
- [ ] Ensure MIR-to-source span mapping is stable for diagnostics.

## 3) CFG + NLL Liveness Substrate

- [ ] Upgrade `src/BorrowCfg.w` to expose predecessor/successor sets needed for dataflow.
- [ ] Add per-block use/def summaries for borrow-reference bindings.
- [ ] Implement backward liveness over CFG for reference-binding symbols/locals.
- [ ] Keep lexical scope expiration as a fallback guard for scope-exit cleanup.

## 4) Borrow Creation and Conflict Rules

- [ ] Implement borrow creation API equivalent to Stage0 `checkBorrowCreate` behavior.
- [ ] Enforce shared/shared compatibility.
- [ ] Enforce shared/exclusive conflicts with Stage0-equivalent diagnostics.
- [ ] Enforce exclusive/exclusive conflicts with Stage0-equivalent diagnostics.
- [ ] Track active borrows with binding association for NLL expiration.

## 5) Disjoint Field Borrowing

- [ ] Implement `areBorrowsDisjoint`-equivalent logic for direct field borrows.
- [ ] Treat whole-place borrows as overlapping all fields of that place.
- [ ] Keep disjointness conservative and deterministic (no speculative precision).
- [ ] Add explicit tests for same-field conflict vs distinct-field success.

## 6) Move State Interactions

- [ ] Align move-state tracking with borrow checker use sites.
- [ ] Emit `use of moved value` parity diagnostics in borrow-sensitive flows.
- [ ] Respect reinitialization on assignment where Stage0 does.
- [ ] Validate move + borrow interaction ordering against Stage0.

## 7) Ephemeral Type and Value Propagation

- [ ] Track ephemeral type declarations and propagation through aggregate types.
- [ ] Model ephemeral values (`&`, slices, ephemeral containers, ephemeral task values).
- [ ] Carry ephemeral markers through bindings, calls, closures, and task constructs.
- [ ] Keep propagation rules deterministic and bounded (no hidden global state).

## 8) Ephemeral Boundary Enforcement

- [ ] Enforce no-escape rules for ephemeral refs in structs/collections.
- [ ] Enforce return-position ephemeral restrictions (reference and type cases).
- [ ] Enforce closure capture restrictions for ephemeral references.
- [ ] Enforce task-boundary escape checks with Stage0-equivalent severity (error/warning).

## 9) Diagnostics Parity and Stability

- [ ] Normalize diagnostic emission order across traversals.
- [ ] Match Stage0 message strings for Wave 8 borrow diagnostics where feasible.
- [ ] Keep span fidelity stable for primary failing expression.
- [ ] Add determinism check: same source, repeated runs, byte-identical diagnostics.

## 10) Unit Test Harness

- [ ] Add `scripts/run_wave8_borrow_unit_tests.sh`.
- [ ] Add focused unit cases in `test/wave8/cases/` for:
  - borrow overlap matrix
  - disjoint field acceptance
  - NLL expiration success/failure
  - use-after-move
  - ephemeral boundary failures
  - ref-return provenance
- [ ] Include negative and positive counterparts for each rule bucket.

## 11) Stage0 Parity Harness

- [ ] Add `scripts/run_wave8_borrow_parity.sh`.
- [ ] Build Stage0 and self-host binaries in harness setup.
- [ ] Run `check` on Wave 8 corpus with both compilers.
- [ ] Compare status and normalized diagnostic outputs.
- [ ] Re-run self-host checks to assert determinism.
- [ ] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per test.
- [ ] Fail harness on stale, duplicate, or malformed `KNOWN_DIVERGENCE` entries.

## 12) Known Divergence Governance

- [ ] Reuse `scripts/parity_states.sh` validation rules in Wave 8 parity script.
- [ ] Require every `KNOWN_DIVERGENCE` to be exercised during the run.
- [ ] Fail if declared `KNOWN_DIVERGENCE` count differs from used count.
- [ ] Keep accepted divergence list reviewable and small; no growth without rationale.

## 13) Driver Integration

- [ ] Wire Wave 8 borrow checking into the `check` pipeline after MIR lowering.
- [ ] Ensure non-borrow commands remain behaviorally unchanged.
- [ ] Preserve existing `--dump-typed` and `--dump-mir` behavior.
- [ ] Ensure borrow diagnostics are emitted before codegen proceeds.

## 14) Documentation and Status Updates

- [ ] Update `docs/with-selfhost-wave8.md` with implementation notes during execution.
- [ ] Update `docs/with-selfhost-plan.md` Wave 8 status after exit gate passes.
- [ ] Update `docs/with-selfhost-detailed-plan.md` with Wave 8 completion notes.
- [ ] Record accepted Wave 8 divergences with rationale and test linkage.

---

## Validation Gates (Wave 8 Exit)

- [ ] `scripts/run_wave8_borrow_unit_tests.sh` passes.
- [ ] `scripts/run_wave8_borrow_parity.sh` passes.
- [ ] All Wave 8 corpus tests resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [ ] No unresolved `FAIL` entries remain.
- [ ] No bootstrap changes were required for Wave 8 feature scope.
- [ ] Borrow diagnostics parity with Stage0 is achieved for Wave 8 scope.
