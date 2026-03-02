# Wave 1 Implementation Plan

## Foundations (Withc2)

## Goal

Build the foundation layer for the self-hosted compiler with no compiler-pass logic yet:

- ID types
- InternPool (strings + types + values)
- Arena
- Diagnostics subsystem
- Span / Source

Wave 1 output is reusable infrastructure only. Lexer/parser/resolve/typecheck/codegen are out of scope.

Validation for Wave 1 is unit tests only.

---

## Inputs and Constraints

- Canonical wave definition from:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle reference implementation:
  - `bootstrap/src/InternPool.zig`
  - `bootstrap/src/Span.zig`
  - `bootstrap/src/Source.zig`
  - `bootstrap/src/Diagnostic.zig`
- Architecture influence:
  - Zig shape: `.reference/zig/src/InternPool.zig`
  - Rust discipline:
    - `.reference/rust/compiler/rustc_span/src/def_id.rs`
    - `.reference/rust/compiler/rustc_span/src/symbol.rs`
    - `.reference/rust/compiler/rustc_span/src/source_map.rs`
    - `.reference/rust/compiler/rustc_arena/src/lib.rs`
    - `.reference/rust/compiler/rustc_errors/src/diagnostic.rs`
    - `.reference/rust/compiler/rustc_data_structures/src/intern.rs`

---

## Scope

## In scope

- New foundation modules in `src/compiler/foundation/`.
- Stable typed IDs and handle discipline.
- Unified interning API for symbols, types, and values.
- Region-style arena allocation primitives.
- Source storage + span mapping + line/column/snippet lookup.
- Structured diagnostics model and deterministic rendering utilities.
- Unit tests for all above components.

## Out of scope

- Lexer/parser changes.
- Resolve/HIR changes.
- Sema/type inference logic.
- MIR/borrow/async/codegen/driver behavior changes.
- Golden/oracle diffing for higher IRs (already Wave 0/next waves).

---

## Wave 1 Architecture Decisions

1. IDs are first-class distinct handle types, not raw `i32` in public APIs.
2. Foundation stores data in tables indexed by IDs, not graph pointers.
3. Interning is canonical and deterministic.
4. Source/Span is centralized in one source map layer.
5. Diagnostics are structured data first, rendering second.
6. Foundation must be testable in isolation from compiler passes.

---

## Target Module Layout

Planned new files (exact names can vary slightly, but the split should hold):

```text
src/compiler/foundation/
  Ids.w
  Arena.w
  InternPool.w
  Types.w              # interned type keys for foundation only
  Values.w             # interned value keys for foundation only
  Span.w
  Source.w
  SourceMap.w
  Diagnostic.w
  DiagnosticRender.w
  Mod.w                # convenience re-export
```

Planned unit test files:

```text
test/wave1/
  ids_test.w
  arena_test.w
  intern_strings_test.w
  intern_types_test.w
  intern_values_test.w
  span_source_test.w
  source_map_test.w
  diag_model_test.w
  diag_render_test.w
```

Compatibility shims (optional but recommended for incremental migration):

- Keep existing root modules (`src/InternPool.w`, `src/Span.w`, `src/Source.w`, `src/Diagnostic.w`) as thin forwarding layers once foundation modules exist.

---

## Execution Plan (Ordered)

## 0. Contracts First

- Write short contracts inside each new module header:
  - ownership model
  - ID invalid/sentinel policy
  - complexity expectations for hot APIs
  - determinism guarantees
- Define naming conventions (`FooId`, `InvalidFooId`, `is_valid`, `to_i32`/`from_i32`).

## 1. ID Types

Deliverables:

- Distinct ID types for:
  - `FileId`
  - `ModuleId`
  - `DefId`
  - `ItemId`
  - `TypeId`
  - `ValueId`
  - `Symbol`
  - additional Wave 1-local IDs needed by foundation tables
- Helpers:
  - constructors
  - invalid sentinel
  - equality/order/hash
  - debug formatting

Rules:

- No public API should accept plain `i32` where an ID type is intended.
- Conversions to/from raw ints are explicit and isolated.

## 2. Arena

Deliverables:

- Arena supporting bump/append-style allocation.
- Handle-based access API (index IDs), no escaping raw references in public API.
- Bulk reset/free semantics.
- Optional typed lanes if needed (`Arena[T]` or equivalent table wrappers).

Rules:

- Deterministic allocation order.
- O(1) append path.
- Clear behavior for invalid handles.

## 3. Unified InternPool

Deliverables:

- String interning:
  - `intern_str`
  - `resolve_symbol`
- Type interning:
  - canonical `TypeKey`
  - `intern_type`
  - `resolve_type`
- Value interning:
  - canonical `ValueKey`
  - `intern_value`
  - `resolve_value`

Rules:

- Canonicalization by structural key (not pointer identity).
- Same key always maps to same ID in a compilation.
- Stable behavior across repeated runs with identical insertion order.

## 4. Span / Source / SourceMap

Deliverables:

- `Span` with file + byte range.
- `Source` model with text + line starts.
- `SourceMap` registry keyed by `FileId`.
- APIs:
  - add/load source
  - offset -> line/column
  - line text/snippet extraction
  - span merge/len helpers

Rules:

- Byte positions are authoritative.
- Out-of-range queries must fail predictably.
- No hidden path mutation in Wave 1.

## 5. Diagnostics Subsystem

Deliverables:

- Diagnostic data model:
  - severity
  - message
  - primary span
  - secondary labels
  - notes/help
  - optional error code
- `DiagnosticStore` / accumulator APIs:
  - emit
  - has_errors
  - count by severity
- Rendering helper(s) using `SourceMap`:
  - deterministic text format
  - stable label ordering

Rules:

- No diagnostics printed directly from random modules in Wave 1 foundation.
- Foundation returns structured diagnostics; render/emit happens explicitly.

## 6. Wiring and Adapters

Deliverables:

- `src/compiler/foundation/Mod.w` exports stable API surface.
- Optional thin adapters in legacy root modules to reduce churn for later waves.
- No behavior changes to compiler passes in this wave beyond import-path updates required for compilation.

## 7. Unit Test Suite

Deliverables:

- Add focused unit tests for each foundation module.
- Add deterministic edge-case tests:
  - duplicate interning
  - invalid ID handling
  - span boundary math
  - diagnostics ordering and rendering stability
- Add one aggregate foundation smoke test combining IDs + interning + source map + diagnostics.

Validation command policy:

- Unit tests only for Wave 1 gate.
- No e2e/golden/full compiler parity requirement in this wave.

---

## Acceptance Criteria (Wave 1 Exit)

1. All foundation modules compile in self-host tree.
2. IDs are distinct in API boundaries (no accidental raw-int usage in public interfaces).
3. InternPool supports string/type/value interning with deterministic behavior.
4. Source/Span/SourceMap APIs are complete enough for Wave 2 lexer and Wave 3 parser.
5. Diagnostics model supports structured errors without depending on later passes.
6. Wave 1 unit suite passes cleanly.
7. No compiler-pass logic added beyond minimal wiring needed to compile tests.

---

## Risks and Mitigations

- Risk: over-designing Arena/InternPool before real pass usage.
  - Mitigation: keep APIs minimal, table-based, and add only Wave 2/3 required hooks.
- Risk: mixing old root modules and new foundation modules causes drift.
  - Mitigation: enforce one canonical module path and keep adapters tiny.
- Risk: diagnostics text churn later.
  - Mitigation: separate data model from renderer; lock deterministic ordering now.
- Risk: ID sprawl without conventions.
  - Mitigation: centralize ID declarations in one file and enforce naming/constructor patterns.

---

## Implementation Checklist

- [ ] Create `src/compiler/foundation/` module skeleton and `Mod.w` exports.
- [ ] Define all Wave 1 ID types in `Ids.w` with explicit invalid sentinels.
- [ ] Add ID helper APIs (construct/compare/format/raw conversion) and tests.
- [ ] Implement `Arena.w` with deterministic handle allocation and reset semantics.
- [ ] Add arena unit tests (allocation order, reset, invalid handle behavior).
- [ ] Implement string interning in `InternPool.w`.
- [ ] Implement type-key definitions in `Types.w`.
- [ ] Implement value-key definitions in `Values.w`.
- [ ] Implement type/value interning in `InternPool.w`.
- [ ] Add intern tests for string/type/value canonicalization.
- [ ] Implement `Span.w` and span utilities (`len`, `merge`, validation).
- [ ] Implement `Source.w` (line starts + location mapping).
- [ ] Implement `SourceMap.w` (`FileId` registry + lookup APIs).
- [ ] Add span/source/source_map boundary and lookup tests.
- [ ] Implement `Diagnostic.w` structured model and store.
- [ ] Implement `DiagnosticRender.w` deterministic text renderer.
- [ ] Add diagnostics model/render tests.
- [ ] Add optional root-module adapters (`src/InternPool.w`, `src/Span.w`, `src/Source.w`, `src/Diagnostic.w`) to point at foundation modules.
- [ ] Add Wave 1 test runner script and document commands.
- [ ] Verify Wave 1 gate: unit tests only, all passing.
- [ ] Mark Wave 1 complete in `docs/with-selfhost-plan.md` and `docs/with-selfhost-detailed-plan.md`.

