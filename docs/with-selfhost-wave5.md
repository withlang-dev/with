# Wave 5 Implementation Plan

## Types + Traits (Withc2)

## Goal

Implement Wave 5 type-system and trait-system foundations for the self-hosted compiler:

- canonical type representation
- deterministic type/value/symbol interning integration
- trait obligation solving
- coherence/orphan enforcement
- generic instantiation

Wave 5 exit gate:

- self-host `check <file> --dump-typed` matches Stage0 on the Wave 5 corpus.

---

## Inputs and Constraints

- Canonical wave definition:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle implementation:
  - `bootstrap/src/Sema.zig`
  - `bootstrap/src/Types.zig`
  - `bootstrap/src/Driver.zig` (`writeTyped`)
  - `bootstrap/src/main.zig` (`--dump-typed` dispatch)
- Typed dump format contract:
  - `docs/wave0-dump-spec.md` (typed section)
- Existing self-host architecture spine:
  - `src/compiler/Zcu.w`
  - `src/compiler/Frontend.w`
  - `src/Sema.w` (current semantic engine)
  - `src/compiler/foundation/InternPool.w`
  - `src/compiler/foundation/Types.w`
- Reference architecture:
  - Zig:
    - `.reference/zig/src/InternPool.zig`
    - `.reference/zig/src/Type.zig`
    - `.reference/zig/src/Sema.zig`
    - `.reference/zig/src/Zcu.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_type_ir/src`
    - `.reference/rust/compiler/rustc_infer/src`
    - `.reference/rust/compiler/rustc_trait_selection/src`
    - `.reference/rust/compiler/rustc_hir_analysis/src/coherence`

Constraints:

- Stage0 remains semantic oracle for Wave 5 parity checks.
- Determinism is mandatory (stable traversal/order, no pointer identity).
- Bootstrap stays frozen unless a documented Stage0 bug fix is explicitly approved.
- No MIR lowering changes in Wave 5.

---

## Scope

## In scope

- Type identity model (`TypeId`) as canonical handles.
- Canonical type interning for all Wave 5-relevant type forms.
- Trait definitions, impl tables, and obligation model.
- Coherence checks (duplicate impl + orphan rule parity with Stage0 behavior).
- Generic function/type instantiation and specialization cache behavior needed for typed parity.
- Typed expression/type attachment sufficient for `--dump-typed` parity.
- Deterministic typed dump emitter and parity harness.

## Out of scope

- Borrow/ephemeral analysis (Wave 8).
- MIR and async lowering (Wave 7/9).
- LLVM/codegen parity work (Wave 10).
- Language redesign or trait-system feature expansion beyond Stage0 behavior.

---

## Current Gaps (in this tree)

- Type truth is still largely embedded in `src/Sema.w`, not cleanly separated into reusable type/trait tables attached to `Zcu`.
- Existing foundation intern pool has minimal `TypeKey` coverage and does not yet model the full Wave 5 type surface.
- Trait solver behavior is not yet isolated as a dedicated obligation pipeline.
- No dedicated Wave 5 typed parity corpus/scripts exist yet.
- Typed dump path exists conceptually in Stage0, but self-host parity path for Wave 5 scope is not yet locked.

---

## Wave 5 Oracle Contract (Parity Target)

Primary oracle artifact:

- `check <file> --dump-typed`

Wave 5 parity contract:

1. Output line schema must follow `docs/wave0-dump-spec.md` typed section.
2. Declaration ordering must be deterministic and match Stage0 behavior.
3. Type-name rendering must match Stage0 semantic names.
4. Expression and binding typed lines must be deterministic and Stage0-aligned for corpus inputs.
5. Trait/impl/type summary rows must match Stage0 behavior for supported forms.

Note:

- If a Stage0 typed behavior is confirmed as incorrect, keep corpus case under parity with an explicit `KNOWN_DIVERGENCE` marker and linked bug doc; do not silently drop it.

---

## Target Deliverables

1. Canonical type table and full TypeId plumbing used by semantic checking.
2. Expanded interned `TypeKey`/value-key model for Stage0-parity type forms.
3. Trait tables:
   - trait declarations
   - impl declarations
   - method requirement metadata
4. Coherence/orphan checking pass aligned to Stage0 behavior.
5. Obligation/selection path for trait bounds and dyn-trait compatibility checks.
6. Generic instantiation cache and substitution pipeline.
7. Deterministic typed dump emitter in self-host.
8. Wave 5 unit + parity scripts and corpus.

---

## Target File Plan

Core implementation targets (exact final split may vary, but one canonical path only):

- `src/compiler/typeck/TypeSystem.w` (new)
- `src/compiler/typeck/TraitSolver.w` (new)
- `src/compiler/typeck/Coherence.w` (new)
- `src/compiler/typeck/Instantiate.w` (new)
- `src/compiler/typeck/TypedDump.w` (new)
- `src/compiler/Zcu.w` (type/trait state ownership)
- `src/compiler/Frontend.w` (typecheck stage wiring)
- `src/main.w` (`--dump-typed` path)
- `src/Sema.w` (shrink/bridge or migrate into `compiler/typeck` path)

Wave 5 tests/scripts:

- `test/wave5/typed_corpus.txt`
- `test/wave5/*` (types/traits/coherence/generic unit coverage)
- `scripts/run_wave5_type_trait_unit_tests.sh`
- `scripts/run_wave5_typed_parity.sh`

---

## Execution Plan (Ordered)

## 0. Freeze Wave 5 Typed Contract + Corpus

- Freeze the Wave 5 typed dump contract against Stage0 current output.
- Build `test/wave5/typed_corpus.txt` from Stage0 type/trait/generic-heavy cases:
  - trait declarations/impls
  - orphan/coherence checks
  - dyn trait object compatibility cases
  - generic bounds/where-clause cases
  - monomorphization-heavy samples
- Capture Stage0 typed baselines for corpus files.

## 1. Canonical Type Representation

- Define/lock internal type representation for Wave 5:
  - primitives
  - nominal types (struct/enum/alias)
  - pointers/references/slices/arrays/tuples
  - function signatures
  - trait objects
  - generic parameters/instantiations
- Ensure every typed node references canonical `TypeId`.
- Remove hidden ad-hoc type reconstruction from call sites in Wave 5 path.

## 2. Interning Expansion and Determinism

- Extend `TypeKey` coverage in foundation intern pool to represent Wave 5 forms.
- Ensure canonicalization keying is structural and deterministic.
- Add deterministic ordering guarantees for type/trait table iteration used by dumps.

## 3. Trait Definition and Impl Collection

- Implement deterministic trait declaration collection:
  - required methods
  - optional defaults
  - associated types (if represented in Stage0 behavior for corpus)
- Implement impl collection tables keyed by type/trait identity.
- Preserve stable insertion order for deterministic diagnostics and dump rendering.

## 4. Coherence + Orphan Checks

- Implement duplicate-impl detection parity with Stage0.
- Implement orphan rule checks parity with Stage0.
- Emit diagnostics via structured subsystem with stable spans/order.

## 5. Obligation Solver (Wave 5 Scope)

- Introduce obligation model for:
  - generic trait bounds
  - dyn parameter compatibility checks
  - trait method availability checks
- Implement selection cache for deterministic repeated resolution.
- Keep scope intentionally limited to Stage0-supported trait semantics.

## 6. Generic Instantiation

- Implement substitution map/build for generic parameters to concrete types.
- Implement specialization cache for instantiated generic functions/types.
- Enforce deterministic specialization key construction and lookup.

## 7. Typed Pass Wiring

- Wire type/trait passes into frontend pipeline after resolve/HIR and before later stages.
- Store canonical type/trait outputs in `Zcu`.
- Keep one typed-check path used by both normal checking and typed-dump emission.

## 8. Typed Dump Emitter Parity

- Implement/align deterministic typed dump emitter to Stage0 schema:
  - module header
  - decl rows
  - per-decl type summaries
  - expression/bind typed rows in deterministic preorder
- Verify escaping/spacing/newline behavior is byte-stable.

## 9. Unit Test Coverage

- Add focused tests for:
  - type interning/canonicalization
  - trait table construction
  - coherence/orphan checks
  - generic inference/instantiation keys
  - obligation solve outcomes
  - typed dump formatting primitives

## 10. Stage0 Parity Harness

- Add `scripts/run_wave5_typed_parity.sh`:
  - build Stage0 and self-host
  - run typed dump on Wave 5 corpus
  - strict diff Stage0 vs self-host outputs
  - rerun self-host to assert determinism
- Add explicit report bucket for `KNOWN_DIVERGENCE` entries.

## 11. Documentation + Status Updates

- Update Wave 5 progress in:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Document any accepted Stage0 divergences with rationale and test linkage.

---

## Validation Strategy

Wave 5 uses two gates:

1. Unit correctness:
   - `scripts/run_wave5_type_trait_unit_tests.sh`
2. Stage0 parity:
   - `scripts/run_wave5_typed_parity.sh`
   - strict textual diff of typed dump outputs

Corpus policy:

- explicit, versioned corpus file (`test/wave5/typed_corpus.txt`)
- deterministic iteration order (sorted in script)
- success and failure cases both included

---

## Acceptance Criteria (Wave 5 Exit)

1. Canonical type representation and interning are wired through self-host type checking.
2. Trait solver resolves Wave 5 corpus obligations with Stage0-equivalent outcomes.
3. Coherence/orphan checks match Stage0 behavior on corpus.
4. Generic instantiation behavior required for typed dumps matches Stage0.
5. `check --dump-typed` output matches Stage0 on Wave 5 corpus.
6. Wave 5 unit and parity scripts pass locally.

---

## Risks and Mitigations

- Risk: type identity drift from mixed old/new type tables.
  - Mitigation: define one canonical `TypeId` lane and adapter boundaries; no duplicate type truth.
- Risk: nondeterministic trait/impl iteration causes typed-dump churn.
  - Mitigation: stable insertion order + explicit sorted dump iteration where needed.
- Risk: obligation solver scope creep.
  - Mitigation: gate solver features to Stage0-observed behavior only for Wave 5 corpus.
- Risk: false parity failures from formatting differences.
  - Mitigation: lock dump schema first and unit-test formatting separately.
- Risk: masking true divergences by excluding tests.
  - Mitigation: use explicit `KNOWN_DIVERGENCE` tracking instead of silent exclusion.

---

## Implementation Checklist

- [ ] Freeze Wave 5 typed dump oracle contract against Stage0 current output.
- [ ] Create `test/wave5/typed_corpus.txt`.
- [ ] Inventory Stage0 type/trait/generic behaviors needed for Wave 5 corpus from `bootstrap/src/Sema.zig`.
- [ ] Define canonical Wave 5 type representation and `TypeId` usage rules.
- [ ] Expand `TypeKey`/interning coverage for Wave 5 type forms.
- [ ] Add deterministic type-name rendering helpers for typed dump output.
- [ ] Implement deterministic trait declaration collection tables.
- [ ] Implement deterministic impl collection tables.
- [ ] Implement coherence duplicate-impl checks with Stage0 parity.
- [ ] Implement orphan-rule checks with Stage0 parity.
- [ ] Implement trait obligation model and selection cache.
- [ ] Implement trait-bound checking for generic instantiation.
- [ ] Implement dyn-trait compatibility checks needed for typed parity corpus.
- [ ] Implement generic substitution map and specialization cache.
- [ ] Ensure canonical typed pass outputs are stored in `Zcu`.
- [ ] Wire Wave 5 type/trait pass into frontend pipeline.
- [ ] Add self-host `check --dump-typed` path if missing in current path.
- [ ] Implement Stage0-compatible deterministic typed dump emitter.
- [ ] Add `test/wave5/` unit tests for types/traits/coherence/generic instantiation.
- [ ] Add typed-dump formatting and determinism unit checks.
- [ ] Add `scripts/run_wave5_type_trait_unit_tests.sh`.
- [ ] Add `scripts/run_wave5_typed_parity.sh` (Stage0 diff + determinism rerun + divergence reporting).
- [ ] Verify Wave 5 unit and parity gates pass locally.
- [ ] Mark Wave 5 progress in top-level self-host plan docs.
