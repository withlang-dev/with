# Enum and Type Redesign Completion Checklist

This file records the implementation status of the syntax redesign from
`docs/type_enum_redesign.md` as it exists in the main workspace.

Status:
- [x] Complete for the strict enum/type syntax migration.

Validation gate:
- [x] `make build`
- [x] `make smoke`
- [x] `./out/bin/with-stage2 check src/main.w`
- [x] `make fixpoint`

## Completed Work

### Phase 0: Qualified enum patterns

- [x] `Type.Variant` patterns parse in `match` and `if let`.
- [x] `Type.Variant(...)` payload patterns parse recursively.
- [x] Qualified patterns lower to existing `NK_PAT_VARIANT` nodes.
- [x] Pattern qualifiers are preserved via AST side metadata instead of a new node kind.
- [x] Sema validates that a qualified pattern's enum type matches the subject type.
- [x] Nested qualified-pattern coverage exists in behavior tests.
- [x] Wrong-type qualified patterns fail with a dedicated compile error.

### Phase 1: `enum` syntax

- [x] `enum` is a real keyword in the lexer and parser.
- [x] Inline unit enums parse: `enum Direction { North | South }`.
- [x] Block unit enums parse:
  ```
  enum Direction:
      North
      South
  ```
- [x] Inline ADT enums parse.
- [x] Block ADT enums parse.
- [x] Optional leading `|` in block enum bodies parses.
- [x] Inline discriminant enums parse.
- [x] Block discriminant enums parse.
- [x] Auto-increment for omitted discriminants works.
- [x] `@[flags]` works with `enum`.
- [x] Discriminant enums with payloads work.
- [x] Generic enums work.

### Phase 2: strict `type` syntax

- [x] Block struct form parses:
  ```
  type Config:
      host: str
      port: i32
  ```
- [x] Inline struct form parses without `=`:
  `type Point { x: i32, y: i32 }`
- [x] Field defaults work in block and inline struct forms.
- [x] Generic `type` declarations work in the strict forms.

### Phase 3: compiler and test migration

- [x] Compiler sources were migrated broadly to `enum ...`, `type Name { ... }`, and `type Name:`.
- [x] Standard library sources were migrated to the strict forms where applicable.
- [x] Behavior, codegen, lexer, and compile-error tests were migrated to the strict forms.
- [x] CLI help text was updated so examples no longer advertise rejected enum syntax.
- [x] A strict-syntax bridge compiler path was used to re-bootstrap the tree from the older seed.

### Phase 4: old syntax removal

- [x] Old top-level enum syntax under `type` is a syntax error.
- [x] Old top-level discriminant-enum syntax under `type` is a syntax error.
- [x] Old top-level struct `type Name = { ... }` syntax is a syntax error.
- [x] `enum` and `type` are no longer interchangeable for top-level struct/enum declarations.
- [x] The accepted declaration forms for these constructs are now colon or braces, not `=`.
- [x] Dedicated compile-error fixtures lock the old spellings out.

Current migration diagnostics:
- [x] `use 'enum' for enum declarations`
- [x] `drop '=' in struct type declarations`

### Phase 5: semantic/bootstrap fixes discovered during migration

- [x] Static enum variant constructors on field-access calls are typed correctly.
- [x] Discriminant enum field access remains enum-typed for matching and constructors.
- [x] Discriminant enums with repr types participate correctly in numeric contexts.
- [x] Numeric literal expectation uses the enum repr type in discriminant comparisons.
- [x] Qualified pattern rendering preserves `Type.Variant(...)` spelling when qualifier metadata exists.

### Phase 6: regression coverage

- [x] Qualified enum pattern behavior coverage exists.
- [x] Qualified enum wrong-type compile-error coverage exists.
- [x] Legacy struct `=` compile-error coverage exists.
- [x] Legacy enum-under-`type` compile-error coverage exists.
- [x] Legacy discriminant-enum-under-`type` compile-error coverage exists.
- [x] Discriminant enum arithmetic, flags, auto-increment, match, and payload coverage pass on the rebuilt compiler.

### Phase 7: deferred enumification follow-ups started

- [x] `MIR_INTRINSIC_*` was converted from a flat constant block to `enum MirIntrinsic: i32:` in `src/Mir.w`.
- [x] MIR lowering and both backends now reference intrinsic tags through `MirIntrinsic.MIR_INTRINSIC_*`.
- [x] The `MirIntrinsic` enumification slice passes `make build`, `make smoke`, and `make fixpoint`.
- [x] `OP_*` was converted from a flat constant block to `enum BinaryOp: i32:` in `src/Ast.w`.
- [x] Parser, sema, MIR lowering, renderer, and both backends now reference binary operators through `BinaryOp.OP_*`.
- [x] The `BinaryOp` enumification slice passes `make build`, `make smoke`, and `make fixpoint`.
- [x] `UOP_*` was converted from a flat constant block to `enum UnaryOp: i32:` in `src/Ast.w`.
- [x] Parser, sema, MIR lowering, renderer, and both backends now reference unary operators through `UnaryOp.UOP_*`.
- [x] The `UnaryOp` enumification slice passes `make build`, `make smoke`, and `make fixpoint`.
- [x] `VIS_*` was converted from a flat constant block to `enum Visibility: i32:` in `src/Ast.w`.
- [x] Parser and renderer helpers now reference declaration visibility through `Visibility.VIS_*`.
- [x] The `Visibility` enumification slice passes `make build`, `make smoke`, and `make fixpoint`.
- [x] `LIT_SUFFIX_*` was converted from a flat constant block to `enum LiteralSuffix: i32:` in `src/Ast.w`.
- [x] AST storage, parser suffix decoding, and sema suffix typing now reference literal suffix tags through `LiteralSuffix.LIT_SUFFIX_*`.
- [x] The `LiteralSuffix` enumification slice passes `make build`, `make smoke`, and `make fixpoint`.

## Superseded Items From The Original Staging Plan

These are not open bugs; they were staging tactics or optional cleanup items in the original checklist.

- [x] Additive compatibility for old top-level struct/enum syntax was intentionally not preserved.
  The final language now rejects the old spellings, per the stricter design requirement.
- [x] The bridge-compiler step is no longer an open task.
  The main workspace now self-hosts and passes fixpoint with the strict syntax tree.
- [x] Parser-first migration without a new qualified-pattern AST kind was sufficient.
  No dedicated `NK_PAT_QUALIFIED_VARIANT` node was needed.

## Remaining Follow-Ups

These are separate refactors, not remaining blockers for the enum/type syntax redesign itself.

- [x] Converting the remaining token/AST constant groups such as `TK_*`, `NK_*`, `SK_*`, and other small flat tag sets into enum declarations.
  All constant groups are now converted:
  - `NodeKind` (NK_*), `TokenKind` (TK_*), `TypeDeclKind` (TDK_*), `FnFlags` (FN_FLAG_*)
  - `CharCode` (CH_*), `DriverMode`/`CompileResult`, `DiagSeverity`, `ValidateError`
  - `CfgNodeKind`, `AsyncBodyKind`/`AsyncSuspendKind`, `CallKind`/`AllocKind`
  - `PreludeMode`, `MigrateLang`/`MigrateMode`
- [x] Root-cause the imported-enum regression exposed by additional `src/Ast.w` enumification slices.
  Root cause was a HashMap tombstone reuse bug in `runtime/helpers.c` (`with_hashmap_insert`).
  After enough insert/remove churn, the function could fail to insert because it only checked
  state==0 slots and ignored tombstone slots (state==2). Fixed and all previously-failing
  conversions (`FSTR_SEG_*`, `TDK_*`) now work.
- [~] Removing `TK_` / `NK_` / `OP_` / `SK_` style prefixes from variant names.
  Partial: prefixes stripped from 15 small/medium enums (ValidateError, DiagSeverity,
  CompileResult, DriverMode, CfgNodeKind, AsyncBodyKind, AsyncSuspendKind, CallKind,
  AllocKind, PreludeMode, MigrateLang, MigrateMode, Visibility, TypeDeclKind,
  LiteralSuffix, FStringSegmentKind, CharCode, FnFlags, StmtKind).
  Blocked: renaming MIR-path enums (RvalueKind, TermKind, ConstKind, MirIntrinsic)
  triggers an infinite loop in `run_mir_lower` during self-compilation. Renaming
  large enums (NodeKind, TokenKind, BinaryOp, UnaryOp, TypeKind) triggers LLVM
  `InstCombine::visitAllocSite` going quadratic at O2. Both are codegen bugs that
  need investigation before these renames can proceed.
- [x] Changing unrelated alias-style declarations such as `type FileId = i32`, `type Handle = opaque`, or `type Name = distinct(...)`.
  No change needed — these are type aliases and distinct types, not struct/enum
  declarations. The `=` syntax is correct for aliases.

All constant-group enumification is complete and fixpoint-verified. Prefix removal is partially done; the remaining large enums are blocked by codegen bugs.
