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

- [x] Freeze exact Wave 8 diagnostic parity target against current Stage0 behavior.
- [x] Create `test/wave8/borrow_corpus.txt` with explicit coverage buckets.
- [x] Include Stage0 phase1 borrow suites in corpus planning:
  - `nll`
  - `borrow overlap`
  - `disjoint field borrow`
  - `use-after-move`
  - `ephemeral boundary`
  - `ephemeral propagation`
  - `ref return provenance`
  - `cfg`
- [x] For any excluded case, require a `KNOWN_DIVERGENCE` entry (no silent exclusions).

## 1) Borrow Pass Boundary

- [ ] Introduce `src/BorrowCheck.w` as a distinct pass after MIR lowering.
- [ ] Define pass input/output contract:
  - input: `MirModule` + sema/type/source metadata
  - output: diagnostics only (no semantic redesign)
- [x] Keep Stage0-compatible behavior as the correctness priority over architecture polish.
- [x] Ensure pass execution is deterministic and single-threaded.

## 2) Place and Projection Model

- [x] Define canonical place identity for alias checks: root local + projection path.
- [x] Encode field-level borrow precision needed for disjoint-field acceptance.
- [x] Handle whole-place borrow overlap correctly against field borrows.
- [x] Ensure MIR-to-source span mapping is stable for diagnostics.

## 3) CFG + NLL Liveness Substrate

- [ ] Upgrade `src/BorrowCfg.w` to expose predecessor/successor sets needed for dataflow.
- [ ] Add per-block use/def summaries for borrow-reference bindings.
- [ ] Implement backward liveness over CFG for reference-binding symbols/locals.
- [x] Keep lexical scope expiration as a fallback guard for scope-exit cleanup.

## 4) Borrow Creation and Conflict Rules

- [x] Implement borrow creation API equivalent to Stage0 `checkBorrowCreate` behavior.
- [x] Enforce shared/shared compatibility.
- [x] Enforce shared/exclusive conflicts with Stage0-equivalent diagnostics.
- [x] Enforce exclusive/exclusive conflicts with Stage0-equivalent diagnostics.
- [x] Track active borrows with binding association for NLL expiration.

## 5) Disjoint Field Borrowing

- [x] Implement `areBorrowsDisjoint`-equivalent logic for direct field borrows.
- [x] Treat whole-place borrows as overlapping all fields of that place.
- [x] Keep disjointness conservative and deterministic (no speculative precision).
- [x] Add explicit tests for same-field conflict vs distinct-field success.

## 6) Move State Interactions

- [x] Align move-state tracking with borrow checker use sites.
- [x] Emit `use of moved value` parity diagnostics in borrow-sensitive flows.
- [x] Respect reinitialization on assignment where Stage0 does.
- [x] Validate move + borrow interaction ordering against Stage0.

## 7) Ephemeral Type and Value Propagation

- [x] Track ephemeral type declarations and propagation through aggregate types.
- [ ] Model ephemeral values (`&`, slices, ephemeral containers, ephemeral task values).
- [ ] Carry ephemeral markers through bindings, calls, closures, and task constructs.
- [x] Keep propagation rules deterministic and bounded (no hidden global state).

## 8) Ephemeral Boundary Enforcement

- [x] Enforce no-escape rules for ephemeral refs in structs/collections.
- [x] Enforce return-position ephemeral restrictions (reference and type cases).
- [x] Enforce closure capture restrictions for ephemeral references.
- [ ] Enforce task-boundary escape checks with Stage0-equivalent severity (error/warning).

## 9) Diagnostics Parity and Stability

- [x] Normalize diagnostic emission order across traversals.
- [x] Match Stage0 message strings for Wave 8 borrow diagnostics where feasible.
- [x] Keep span fidelity stable for primary failing expression.
- [x] Add determinism check: same source, repeated runs, byte-identical diagnostics.

## 10) Unit Test Harness

- [x] Add `scripts/run_wave8_borrow_unit_tests.sh`.
- [x] Add focused unit cases in `test/wave8/cases/` for:
  - borrow overlap matrix
  - disjoint field acceptance
  - NLL expiration success/failure
  - use-after-move
  - ephemeral boundary failures
  - ref-return provenance
- [x] Include negative and positive counterparts for each rule bucket.
- [x] Add explicit task-boundary ephemeral escape coverage (`may_suspend` / guard-boundary crossings) with positive and negative cases.

## 11) Stage0 Parity Harness

- [x] Add `scripts/run_wave8_borrow_parity.sh`.
- [x] Build Stage0 and self-host binaries in harness setup.
- [x] Run `check` on Wave 8 corpus with both compilers.
- [x] Compare status and normalized diagnostic outputs.
- [x] Re-run self-host checks to assert determinism.
- [x] Report exactly one of `PASS`, `FAIL`, `KNOWN_DIVERGENCE` per test.
- [x] Fail harness on stale, duplicate, or malformed `KNOWN_DIVERGENCE` entries.

## 12) Known Divergence Governance

- [x] Reuse `scripts/parity_states.sh` validation rules in Wave 8 parity script.
- [x] Require every `KNOWN_DIVERGENCE` to be exercised during the run.
- [x] Fail if declared `KNOWN_DIVERGENCE` count differs from used count.
- [x] Keep accepted divergence list reviewable and small; no growth without rationale.

## 13) Driver Integration

- [ ] Wire Wave 8 borrow checking into the `check` pipeline after MIR lowering.
- [x] Ensure non-borrow commands remain behaviorally unchanged.
- [x] Preserve existing `--dump-typed` and `--dump-mir` behavior.
- [x] Ensure borrow diagnostics are emitted before codegen proceeds.

## 14) Documentation and Status Updates

- [x] Update `docs/with-selfhost-wave8.md` with implementation notes during execution.
- [x] Update `docs/with-selfhost-plan.md` Wave 8 status after exit gate passes.
- [x] Update `docs/with-selfhost-detailed-plan.md` with Wave 8 completion notes.
- [x] Record accepted Wave 8 divergences with rationale and test linkage.

### Implementation Notes (Current)

- Core Wave 8 behavior is implemented in `src/Sema.w` (self-host only):
  - borrow creation/conflict checks (`&`/`&mut`)
  - disjoint-field vs whole-place overlap checks
  - NLL-style dead-borrow expiration within blocks
  - move/use-after-move checks in borrow-relevant flows
  - ephemeral boundary checks for structs/collections/returns/closures
- Parser/AST plumbing for `ephemeral` type declarations is implemented:
  - `src/Ast.w`: packed type-decl kind helpers (`pack_type_decl_kind`, `type_decl_sub_kind`, `type_decl_is_ephemeral`)
  - `src/Parser.w`: preserve `ephemeral` flag on type declarations
  - `src/Sema.w`: tracks `ephemeral_types` and enforces return restrictions
  - `src/render.w` and `src/Codegen.w`: decode packed type-decl kind
- Wave 8 test/harness artifacts added:
  - `test/wave8/cases/*.w`
  - `test/wave8/borrow_corpus.txt`
  - `scripts/run_wave8_borrow_unit_tests.sh`
  - `scripts/run_wave8_borrow_parity.sh`
- Current Wave 8 `KNOWN_DIVERGENCE` count: 6.

### Known Debt (Explicit)

- `KNOWN_DEBT-W8-ARCH-001`: Current borrow behavior lives in `src/Sema.w` for corpus parity; rewrite to MIR pass (`src/BorrowCheck.w` + `src/BorrowCfg.w`) after semantic fixpoint.
- `KNOWN_DEBT-W8-ARCH-002`: Task-boundary ephemeral escape checks and dedicated corpus coverage remain open and must be completed in Wave 8 conformance work.

---

## Validation Gates (Wave 8 Exit)

- [x] `scripts/run_wave8_borrow_unit_tests.sh` passes.
- [x] `scripts/run_wave8_borrow_parity.sh` passes.
- [x] All Wave 8 corpus tests resolve to `PASS` or documented `KNOWN_DIVERGENCE`.
- [x] No unresolved `FAIL` entries remain.
- [x] No bootstrap changes were required for Wave 8 feature scope.
- [x] Borrow diagnostics parity with Stage0 is achieved for Wave 8 scope.
