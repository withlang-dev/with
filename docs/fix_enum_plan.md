# Enum and Type Redesign Implementation Checklist

This checklist turns the redesign in `docs/type_enum_redesign.md` into an implementation order that matches the current compiler architecture.

Primary strategy:
- Keep changes parser-first where possible.
- Lower new syntax into existing `NK_TYPE_DECL`, `TDK_*`, `NK_PAT_VARIANT`, and `NK_PAT_ENUM_SHORTHAND` forms.
- Avoid new AST kinds unless existing nodes cannot preserve behavior or diagnostics.
- Treat every phase as bootstrap-sensitive. Validate after each logical change.

Validation gate for every milestone:
- [ ] `make build`
- [ ] `make smoke`
- [ ] `./out/bin/with-stage2 check src/main.w`
- [ ] `make fixpoint`

## Phase 0: Fix Qualified Enum Variant Patterns

Goal:
- Accept `Type.Variant` and `Type.Variant(...)` in pattern position without changing enum semantics.

Tasks:
- [ ] Inspect the `TK_IDENT` branch in `Parser.parse_pattern` in `src/Parser.w`.
- [ ] Add parsing for `IDENT '.' IDENT` before falling through to `NK_PAT_IDENT`.
- [ ] Add parsing for `Type.Variant(...)` using recursive `parse_pattern` for payload entries.
- [ ] Lower qualified variants to existing `NK_PAT_VARIANT` for the first pass.
- [ ] Confirm existing sema pattern resolution in `src/Sema.w` can resolve the variant from the match subject type without needing a new AST node.
- [ ] Only if diagnostics are insufficient, design a follow-up for a dedicated qualified-variant pattern node.

Tests:
- [ ] `match x` with `Type.Variant =>`
- [ ] `match x` with `Type.Variant(a) =>`
- [ ] nested `match` using qualified variants
- [ ] `if let Type.Variant(a) = value`
- [ ] negative case where the qualified type does not match the subject type

Commit boundary:
- [ ] Commit parser fix and tests separately from all later syntax work.

## Phase 1: Add `enum` Keyword Without Breaking Old `type` Syntax

Goal:
- Accept `enum` as additive syntax while preserving current AST output and semantics.

### 1A. Token and parser entry plumbing

Tasks:
- [ ] Add `TK_KW_ENUM` to `src/Token.w`.
- [ ] Add `"enum"` to `tag_from_keyword`.
- [ ] Add `'enum'` to `tag_name`.
- [ ] Update parser keyword classification helpers in `src/Parser.w`.
- [ ] Update declaration-start logic so top-level `enum` declarations are recognized.

### 1B. Shared declaration parsing

Tasks:
- [ ] Refactor declaration parsing so `type` and `enum` share body-building helpers instead of duplicating logic.
- [ ] Keep emitted nodes as `NK_TYPE_DECL`.
- [ ] Lower `enum` ADTs to `TDK_ENUM`.
- [ ] Lower `enum` declarations with backing types to `TDK_DISC_ENUM`.
- [ ] Preserve existing storage for visibility, type params, and metadata extras.

### 1C. Minimal enum forms

Tasks:
- [ ] Parse `enum Direction { North, South, East, West }`.
- [ ] Parse block form:
  `enum Direction:`
  `    North`
  `    South`
- [ ] Reuse current enum extra layout from `src/Ast.w`.

Tests:
- [ ] inline unit enum
- [ ] block unit enum
- [ ] old `type ... = | ...` enum syntax still passes unchanged

### 1D. ADT enum forms

Tasks:
- [ ] Parse inline ADT enums like `enum Result[T, E] { Ok(T) | Err(E) }`.
- [ ] Parse block ADT enums like:
  `enum Shape:`
  `    Circle(radius: f64)`
  `    Rectangle(w: f64, h: f64)`
- [ ] Accept optional leading `|` in block enum bodies.
- [ ] Preserve type parameter and `where` clause behavior.

Tests:
- [ ] inline generic ADT enum
- [ ] block generic ADT enum
- [ ] block ADT enum with leading pipes
- [ ] payload matching still works

### 1E. Discriminant enum forms

Tasks:
- [ ] Parse inline discriminant enums like `enum Color: i32 { Red = 1, Green = 2 }`.
- [ ] Parse block discriminant enums like:
  `enum OpCode: u8:`
  `    Add = 0x01`
  `    Sub = 0x02`
- [ ] Implement auto-increment for omitted discriminants.
- [ ] Support `@[flags]` on `enum`.
- [ ] Support discriminant enums with payloads:
  `enum Msg: i32:`
  `    Quit = 0`
  `    Write(str) = 1`

Tests:
- [ ] explicit discriminants
- [ ] implicit increment after explicit discriminants
- [ ] flags enum
- [ ] discriminant enum with payloads

Commit boundaries:
- [ ] Commit token plumbing separately.
- [ ] Commit minimal `enum` parsing separately.
- [ ] Commit ADT and discriminant extensions in small follow-ups.

## Phase 2: Add New `type` Struct Forms Additively

Goal:
- Accept new struct declaration syntax while continuing to emit current struct AST layout.

### 2A. Block struct form

Tasks:
- [ ] Extend `Parser.parse_type_decl` in `src/Parser.w` to accept `type Name:` followed by an indented body.
- [ ] Reuse current struct extra layout from `src/Ast.w`.
- [ ] Support field defaults in the block form.
- [ ] Preserve generic parameter and `where` clause support.

Tests:
- [ ] block struct without defaults
- [ ] block struct with defaults
- [ ] generic block struct

### 2B. Inline struct form without `=`

Tasks:
- [ ] Accept `type Point { x: f64, y: f64 }`.
- [ ] Keep `type Point = { x: f64, y: f64 }` working during migration.
- [ ] Normalize both inline forms through the same parser helper.

Tests:
- [ ] inline struct without `=`
- [ ] legacy inline struct with `=`
- [ ] both forms type-check identically

Commit boundary:
- [ ] Commit `type Name:` support separately from inline no-`=` support.

## Phase 3: Migrate Compiler Source to the New Surface Syntax

Goal:
- Move compiler sources to the new syntax only after additive support is stable and fixpoint-clean.

Rules:
- [ ] Do not change enum or struct semantics during migration.
- [ ] Keep discriminant values identical when replacing constant groups with enums.
- [ ] Keep changes in small, subsystem-scoped commits.

### 3A. Token and AST constant groups

Tasks:
- [ ] Migrate token declarations in `src/Token.w` to the new enum syntax.
- [ ] Migrate AST node/tag groups in `src/Ast.w`.
- [ ] Preserve all existing integer values.

### 3B. MIR and sema constant groups

Tasks:
- [ ] Migrate enum-like constant groups in `src/Mir.w`.
- [ ] Migrate sema type-kind groups in `src/Sema.w`.
- [ ] Preserve all existing integer values and switching behavior.

### 3C. Struct declarations across the compiler

Tasks:
- [ ] Replace `type Name = { ... }` with `type Name { ... }` or `type Name:`.
- [ ] Prefer one canonical style and apply it consistently.
- [ ] Keep each commit narrow enough to isolate parser regressions quickly.

### 3D. Control-flow cleanup after qualified patterns land

Tasks:
- [ ] Convert eligible discriminant enum `if`/`else if` chains to `match`.
- [ ] Only do this after Phase 0 is complete and stable.
- [ ] Keep control-flow rewrites separate from declaration syntax rewrites.

### 3E. Prefix cleanup

Tasks:
- [ ] Plan a separate pass for removing `NK_`, `TK_`, `OP_`, `SK_` prefixes from variant names.
- [ ] Do not combine prefix removal with the initial syntax migration.

Validation:
- [ ] Validate after each migrated subsystem.
- [ ] Run full fixpoint after each larger migration batch.

## Phase 4: Remove Old Syntax and Add Migration Diagnostics

Goal:
- Retire legacy forms only after the compiler source no longer depends on them.

Tasks:
- [ ] Remove legacy enum parsing under `type`.
- [ ] Remove legacy discriminant-enum parsing under `type`.
- [ ] Remove legacy `type Name = { ... }` struct parsing.
- [ ] Add migration diagnostics for old enum forms:
  - `use 'enum' for enum declarations`
- [ ] Add migration diagnostics for old struct forms:
  - `drop '=' in struct type declarations`
- [ ] Make diagnostics include concrete replacement examples where possible.
- [ ] Update relevant spec and docs sections to make the new syntax canonical.

Tests:
- [ ] legacy enum syntax now errors with a migration hint
- [ ] legacy discriminant enum syntax now errors with a migration hint
- [ ] legacy struct `=` syntax now errors with a migration hint
- [ ] new syntax still passes in all equivalent cases

Commit boundary:
- [ ] Commit parser removals separately from doc updates if possible.

## Phase 5: Test Matrix and Cleanup

Goal:
- Lock in parser, sema, runtime, and migration behavior with a stable matrix of tests.

### 5A. Parser acceptance tests

Tasks:
- [ ] inline unit enum
- [ ] block unit enum
- [ ] inline ADT enum
- [ ] block ADT enum
- [ ] discriminant enum inline
- [ ] discriminant enum block
- [ ] generic enum
- [ ] inline struct without `=`
- [ ] block struct
- [ ] qualified variant pattern

### 5B. Semantic equivalence tests

Tasks:
- [ ] new enum syntax and old enum syntax behave identically during additive phases
- [ ] new struct syntax and old struct syntax behave identically during additive phases
- [ ] discriminant values are preserved
- [ ] payload typing is preserved

### 5C. Runtime behavior tests

Tasks:
- [ ] payload matching returns correct values
- [ ] block structs initialize correctly
- [ ] default field values behave correctly
- [ ] flags and discriminant comparisons behave correctly

### 5D. Migration diagnostics tests

Tasks:
- [ ] old enum syntax gets the intended error and help text
- [ ] old struct syntax gets the intended error and help text
- [ ] source spans and line numbers are correct

### 5E. Edge cases

Tasks:
- [ ] single-variant enum
- [ ] empty enum if allowed, or confirm parser rejection if not allowed
- [ ] empty struct if allowed, or confirm parser rejection if not allowed
- [ ] trailing commas in inline forms
- [ ] generics plus backing type
- [ ] `pub`, `ephemeral`, derives, and `where` interactions

## Recommended Commit Sequence

- [ ] Commit 1: qualified pattern fix plus tests
- [ ] Commit 2: `TK_KW_ENUM` token plumbing
- [ ] Commit 3: minimal `enum` parsing for unit enums
- [ ] Commit 4: ADT enum parsing
- [ ] Commit 5: discriminant enum parsing and auto-increment
- [ ] Commit 6: `type Name:` block structs
- [ ] Commit 7: `type Name { ... }` inline structs without `=`
- [ ] Commit 8+: source migration by subsystem
- [ ] Final removal commits: legacy syntax deletion plus migration diagnostics

## Non-Negotiable Invariants

- [ ] Do not break `stage2 == stage3`.
- [ ] Do not introduce source-directory build artifacts.
- [ ] Do not change enum discriminant values during migration.
- [ ] Do not introduce new AST kinds unless existing nodes are proven insufficient.
- [ ] Do not start source migration before additive syntax support is stable.
- [ ] If any build step breaks, stop and debug the root cause before continuing.
