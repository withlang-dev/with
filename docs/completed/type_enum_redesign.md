# Enum & Type Syntax — Migration Plan

*Tracks the syntax redesign from §type-enum-syntax-redesign.md plus blocking bugs.*

**Status: COMPLETE** — All phases implemented, fixpoint verified.

---

## Blocking Bugs

### BUG-1: Match patterns don't support qualified enum variants (`Type.VARIANT`)

**Status:** Fixed — qualified patterns parse and validate correctly.

**Fix applied:** `parse_pattern` checks for `TK_DOT TK_IDENT` after an initial ident, emitting `NK_PAT_VARIANT` with qualifier metadata stored in `pattern_qualifiers`. Sema validates that the qualifying type matches the match subject.

---

## Phase 0: Bug Fixes

- [x] **P0-1.** Fix qualified enum variant match patterns (BUG-1).
- [x] **P0-2.** Test: qualified patterns with payloads (`Type.Variant(x, y) =>`).
- [x] **P0-3.** Test: qualified patterns in nested match and if-let.

## Phase 1: Add `enum` keyword (additive, no breaking changes)

- [x] **P1-1.** Add `TK_ENUM` to the lexer/token list.
- [x] **P1-2.** Add `parse_enum_decl` to the parser.
- [x] **P1-3.** Simple enum inline: `enum Direction { North, South, East, West }`.
- [x] **P1-4.** Simple enum block form.
- [x] **P1-5.** ADT enum inline: `enum Result[T, E] { Ok(T) | Err(E) }`.
- [x] **P1-6.** ADT enum block form.
- [x] **P1-7.** ADT enum block with optional leading `|`.
- [x] **P1-8.** Discriminant enum inline.
- [x] **P1-9.** Discriminant enum block with backing type (double colon).
- [x] **P1-10.** Auto-increment for omitted discriminants.
- [x] **P1-11.** `@[flags]` attribute works with `enum` keyword.
- [x] **P1-12.** Discriminant enum with payloads.
- [x] **P1-13.** Generic enums.
- [x] **P1-14.** Sema: `enum` declarations use same type-checking path.
- [x] **P1-15.** All existing tests still pass.
- [x] **P1-16.** Build, install as seed. Fixpoint.

## Phase 2: Add brace-less `type` block form (additive)

- [x] **P2-1.** Parse `type Name:` followed by indented field lines.
- [x] **P2-2.** Block struct form.
- [x] **P2-3.** Block form with default values.
- [x] **P2-4.** Drop `=` from inline form: `type Point { x: f64, y: f64 }`.
- [x] **P2-5.** Old `type Name = { }` deprecated then removed.
- [x] **P2-6.** All existing tests still pass.
- [x] **P2-7.** Build, install as seed. Fixpoint.

## Phase 3: Migrate compiler source

- [x] **P3-1.** Migrate disc enums in `src/Ast.w`:
  - `NodeKind` (NK_*), `TypeDeclKind` (TDK_*), `FnFlags` (FN_FLAG_*),
    `BinaryOp` (OP_*), `UnaryOp` (UOP_*), `Visibility` (VIS_*),
    `LiteralSuffix` (LIT_SUFFIX_*), `FStringSegmentKind` (FSTR_SEG_*)
- [x] **P3-2.** Migrate disc enums in `src/Mir.w`:
  - `MirIntrinsic` (MIR_INTRINSIC_*), `StmtKind` (SK_*),
    `TermKind` (TK_*), `RvalueKind` (RK_*)
- [x] **P3-3.** Migrate disc enums in `src/Sema.w`: `TypeKind` (TY_*).
- [x] **P3-4.** Migrate disc enums in `src/Token.w`: `TokenKind` (TK_*).
- [x] **P3-5.** Migrate struct types across all compiler sources.
- [x] **P3-6.** Convert remaining constant groups across all compiler sources:
  - `CharCode` (CH_*), `DriverMode`/`CompileResult`, `DiagSeverity`,
    `ValidateError`, `CfgNodeKind`, `AsyncBodyKind`/`AsyncSuspendKind`,
    `CallKind`/`AllocKind`, `PreludeMode`, `MigrateLang`/`MigrateMode`,
    plus Resolve.w scope/decl kinds
- [x] **P3-7.** Prefix removal deferred (separate follow-up).
- [x] **P3-8.** All tests pass. Build, fixpoint.

## Phase 4: Remove old syntax

- [x] **P4-1.** Remove `type Name = | Variant | ...` enum parsing.
- [x] **P4-2.** Remove `type Name: i32 = Variant = N` parsing.
- [x] **P4-3.** Remove `type Name = { }` with `=`.
- [x] **P4-4.** Old syntax produces compile error with migration hint.
- [x] **P4-5.** Spec §4.3, §4.4, §4.4a updated to new syntax.
- [x] **P4-6.** All tests pass. Build, fixpoint.

## Phase 5: Tests

- [x] **P5-1.** Test inline enum: simple, ADT, discriminant, flags, generic.
- [x] **P5-2.** Test block enum: all the above in block form.
- [x] **P5-3.** Test inline type: with and without defaults.
- [x] **P5-4.** Test block type: with and without defaults.
- [x] **P5-5.** Test mixed: block enum with inline type fields, etc.
- [x] **P5-6.** Test qualified match patterns: `Type.Variant =>`, `Type.Variant(x) =>`.
- [x] **P5-7.** Test error messages: old syntax gives helpful migration hints.
- [x] **P5-8.** Edge case coverage included in behavior and compile-error tests.

---

## Remaining Follow-Ups

- [~] Removing `TK_` / `NK_` / `OP_` / `SK_` style prefixes from variant names.
  Done for 19 enums. Blocked for MIR-path and large enums by codegen bugs
  (infinite loop in `run_mir_lower`, LLVM `InstCombine` O2 pathology).
- [x] Changing unrelated alias-style declarations (`type FileId = i32`, etc.).
  No change needed — type aliases use `=` correctly.
- [x] Updating spec document §4.3, §4.4, §4.4a.

---

*Enum & type syntax migration plan — v2.0 (completed 2026-03-24)*
