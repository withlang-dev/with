# More Language Rules Checklist

## Scope To Add Up Front
- [x] Numeric separators in literals (`3_000`, `1_000_000`, `0xFF_AA_22`, `0b1111_0000`, `3.141_592_653`)
- [x] Trailing commas are permitted (optional), never required, in all list-like grammar positions (params, args, fields, variants, tuple/array literals, match arms, imports)
- [x] Raw string literals (including delimiter variants, if adopted)
- [x] Multiline string indentation behavior (dedent/strip policy)
- [x] Byte literals (`b'A'`) and clear typing rules
- [x] Unused binding syntax (`_`) in all binding positions
- [x] String escapes parity (`\\xNN`, `\\0`, and existing escapes) across string kinds
- [x] `todo` and `unreachable` expressions with `Never` typing behavior
- [x] No-shadowing language rule (explicitly enforced)
- [x] Pipeline-first migration guidance for shadowing-heavy Rust patterns

## 1. Specification Updates (`docs/with-specification.md`)
- [x] Add numeric separator lexical grammar and invalid forms
- [x] Add trailing comma grammar rules and examples
- [x] Explicitly state trailing commas are optional/permitted and never required
- [x] Add raw string grammar, escaping semantics, and delimiter rules
- [x] Add multiline string indentation/dedent semantics with examples
- [x] Add byte literal grammar and type rules
- [x] Add unused binding rule (`_`) for let, params, patterns, loops, match
- [x] Add/clarify string escape table including hex/null escapes
- [x] Add `todo`/`unreachable` semantics and type-checking rules
- [x] Add explicit no-shadowing rule and diagnostics expectations
- [x] Add spec examples for pipeline replacements where shadowing is disallowed

## 2. Idiomatic Guide Updates (`docs/with-idiomatic-guide.md`)
- [x] Add style guidance for numeric separators
- [x] Add trailing-comma style guidance
- [x] Add raw/multiline string best practices
- [x] Add byte-literal usage examples
- [x] Add unused-binding (`_`) idioms
- [x] Add `todo`/`unreachable` development guidance
- [x] Add no-shadowing coding patterns with pipeline-first style

## 3. Migration Guide Updates (`docs/with-migration-guide.md`)
- [x] Add Rust-to-With numeric separator examples
- [x] Add Rust-to-With trailing comma expectations
- [x] Add Rust-to-With raw string and multiline string examples
- [x] Add Rust-to-With byte literal examples
- [x] Add Rust-to-With unused variable mappings (`_`)
- [x] Add Rust shadowing -> With pipeline cookbook section
- [x] Add diagnostics mapping for no-shadowing migration errors

## 4. Bootstrap Compiler Implementation (`bootstrap/`)
- [x] Lexer: accept numeric separators for integer/float/radix literals
- [x] Lexer: add raw string tokenization
- [x] Lexer: add byte literal tokenization and validation
- [x] Parser: accept optional trailing commas across all targeted productions (no trailing comma must still parse)
- [x] Parser/Sema: `_` binding handling across binding contexts
- [x] Parser/Sema: enforce no-shadowing rule with clear diagnostics
- [x] Sema: `todo`/`unreachable` expression typing (`Never`) and propagation
- [x] String literal processing: add `\\xNN` and `\\0` behavior parity
- [x] Add/extend bootstrap tests for each new rule and failure mode
- [x] Ensure dump outputs remain deterministic after grammar/lexer changes

## 5. Self-Hosted Compiler Implementation (`src/`)
- [x] Mirror lexer support for numeric separators
- [x] Mirror lexer support for raw strings
- [x] Mirror lexer support for byte literals
- [x] Mirror parser support for optional trailing commas (no trailing comma must still parse)
- [x] Mirror parser/sema support for `_` unused bindings
- [x] Mirror no-shadowing diagnostics and enforcement
- [x] Mirror `todo`/`unreachable` typing behavior
- [x] Mirror string escape behavior (`\\xNN`, `\\0`, etc.)
- [x] Add/extend selfhost tests for each feature and error case
- [x] Confirm Stage0/Stage2 parity on new coverage corpus

## 6. Source Conformance Pass (Repo-Wide)
- [x] Compile all With source
- [x] Audit and replace shadowing-style code with pipeline patterns
- [x] Update existing examples/tests to follow new no-shadowing rule
- [x] Add migration notes for any nontrivial source rewrites

## 7. Validation Gates
- [x] Bootstrap test suite passes
- [x] Selfhost test suite passes
- [x] Wave parity scripts still pass
- [x] New language-rule corpus passes on both compilers
- [x] No unresolved known divergences for these features

## Conformance Run Notes (2026-03-03)
- Full source check sweep run over `find src lib -name '*.w'`:
- `./with check`: `65` checked, `0` failed.
- `./with-stage2 check`: `65` checked, `0` failed.
- Pipeline-style replacements applied in core self-host sources:
- `lib/std/collections.w`: `slotmap_insert` ID->string transform now uses `|>`.
- `src/main.w`: deterministic token dump lexeme escaping now uses `|>`.
- `src/Driver.w` and `src/compiler/Link.w`: linker command execution now uses `|>` in command->system-call transforms.
- Example/test no-shadowing migrations:
- `examples/service/src/service.w`: renamed post-insert `user` rebinding to `created_user`.
- `examples/service/src/tests.w`: renamed insert rebinding `user` -> `stored_user`; renamed `with` builder alias `ids` -> `out`.
- Static audit checks for direct self-shadowing patterns in `examples/` and `test/` now return no matches:
  - `let x = { x with ... }`
  - `let x = with ... as mut x:`
- Validation gate commands:
  - Bootstrap suite: `zig build test --build-file bootstrap/build.zig` (pass).
  - Selfhost suite: `scripts/run_wave1_unit_tests.sh` through `scripts/run_wave5_typed_parity.sh` (all pass).
- Divergence status for these language rules: no unresolved known divergences; Stage0/Stage2 parity scripts remain green.
