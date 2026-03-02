# More Language Rules Checklist

## Scope To Add Up Front
- [ ] Numeric separators in literals (`3_000`, `1_000_000`, `0xFF_AA_22`, `0b1111_0000`, `3.141_592_653`)
- [ ] Trailing commas are permitted (optional), never required, in all list-like grammar positions (params, args, fields, variants, tuple/array literals, match arms, imports)
- [ ] Raw string literals (including delimiter variants, if adopted)
- [ ] Multiline string indentation behavior (dedent/strip policy)
- [ ] Byte literals (`b'A'`) and clear typing rules
- [ ] Unused binding syntax (`_`) in all binding positions
- [ ] String escapes parity (`\\xNN`, `\\0`, and existing escapes) across string kinds
- [ ] `todo` and `unreachable` expressions with `Never` typing behavior
- [ ] No-shadowing language rule (explicitly enforced)
- [ ] Pipeline-first migration guidance for shadowing-heavy Rust patterns

## 1. Specification Updates (`docs/with-specification.md`)
- [ ] Add numeric separator lexical grammar and invalid forms
- [ ] Add trailing comma grammar rules and examples
- [ ] Explicitly state trailing commas are optional/permitted and never required
- [ ] Add raw string grammar, escaping semantics, and delimiter rules
- [ ] Add multiline string indentation/dedent semantics with examples
- [ ] Add byte literal grammar and type rules
- [ ] Add unused binding rule (`_`) for let, params, patterns, loops, match
- [ ] Add/clarify string escape table including hex/null escapes
- [ ] Add `todo`/`unreachable` semantics and type-checking rules
- [ ] Add explicit no-shadowing rule and diagnostics expectations
- [ ] Add spec examples for pipeline replacements where shadowing is disallowed

## 2. Idiomatic Guide Updates (`docs/with-idiomatic-guide.md`)
- [ ] Add style guidance for numeric separators
- [ ] Add trailing-comma style guidance
- [ ] Add raw/multiline string best practices
- [ ] Add byte-literal usage examples
- [ ] Add unused-binding (`_`) idioms
- [ ] Add `todo`/`unreachable` development guidance
- [ ] Add no-shadowing coding patterns with pipeline-first style

## 3. Migration Guide Updates (`docs/with-migration-guide.md`)
- [ ] Add Rust-to-With numeric separator examples
- [ ] Add Rust-to-With trailing comma expectations
- [ ] Add Rust-to-With raw string and multiline string examples
- [ ] Add Rust-to-With byte literal examples
- [ ] Add Rust-to-With unused variable mappings (`_`)
- [ ] Add Rust shadowing -> With pipeline cookbook section
- [ ] Add diagnostics mapping for no-shadowing migration errors

## 4. Bootstrap Compiler Implementation (`bootstrap/`)
- [ ] Lexer: accept numeric separators for integer/float/radix literals
- [ ] Lexer: add raw string tokenization
- [ ] Lexer: add byte literal tokenization and validation
- [ ] Parser: accept optional trailing commas across all targeted productions (no trailing comma must still parse)
- [ ] Parser/Sema: `_` binding handling across binding contexts
- [ ] Parser/Sema: enforce no-shadowing rule with clear diagnostics
- [ ] Sema: `todo`/`unreachable` expression typing (`Never`) and propagation
- [ ] String literal processing: add `\\xNN` and `\\0` behavior parity
- [ ] Add/extend bootstrap tests for each new rule and failure mode
- [ ] Ensure dump outputs remain deterministic after grammar/lexer changes

## 5. Self-Hosted Compiler Implementation (`src/`)
- [ ] Mirror lexer support for numeric separators
- [ ] Mirror lexer support for raw strings
- [ ] Mirror lexer support for byte literals
- [ ] Mirror parser support for optional trailing commas (no trailing comma must still parse)
- [ ] Mirror parser/sema support for `_` unused bindings
- [ ] Mirror no-shadowing diagnostics and enforcement
- [ ] Mirror `todo`/`unreachable` typing behavior
- [ ] Mirror string escape behavior (`\\xNN`, `\\0`, etc.)
- [ ] Add/extend selfhost tests for each feature and error case
- [ ] Confirm Stage0/Stage2 parity on new coverage corpus

## 6. Source Conformance Pass (Repo-Wide)
- [ ] Run formatter/lint and compile all With source
- [ ] Audit and replace shadowing-style code with pipeline patterns
- [ ] Update existing examples/tests to follow new no-shadowing rule
- [ ] Add migration notes for any nontrivial source rewrites

## 7. Validation Gates
- [ ] Bootstrap test suite passes
- [ ] Selfhost test suite passes
- [ ] Wave parity scripts still pass
- [ ] New language-rule corpus passes on both compilers
- [ ] No unresolved known divergences for these features
