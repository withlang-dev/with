# Wave 3 Implementation Plan

## AST + Parser (Withc2)

## Goal

Implement Wave 3 parser and AST parity for the self-hosted compiler:

- recursive-descent parser parity with Stage0
- AST representation/rendering parity for dump output
- deterministic self-host `--dump-ast` output

Wave 3 exit gate:

- self-host `check <file> --dump-ast` matches Stage0 byte-for-byte on the Wave 3 corpus.

---

## Inputs and Constraints

- Canonical wave definition:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 parser/AST oracle implementation:
  - `bootstrap/src/Ast.zig`
  - `bootstrap/src/Parser.zig`
  - `bootstrap/src/Parse.zig`
  - `bootstrap/src/render.zig`
  - `bootstrap/src/Driver.zig` (`writeAst`)
  - `bootstrap/src/main.zig` (`collectDumpArtifact` for AST)
- Dump format contract:
  - `docs/wave0-dump-spec.md` (AST section)
- Architecture references:
  - `.reference/rust/compiler/rustc_parse/src/parser/mod.rs`
  - `.reference/rust/compiler/rustc_parse/src/parser/item.rs`
  - `.reference/rust/compiler/rustc_parse/src/parser/expr.rs`
  - `.reference/rust/compiler/rustc_parse/src/parser/stmt.rs`
  - `.reference/zig/src/link/tapi/parse.zig` (small recursive-descent shape reference)

Stage0 remains the semantic/output oracle. No language redesign in Wave 3.

---

## Scope

## In scope

- AST node coverage needed to parse Stage0 Wave 3 corpus.
- Recursive-descent parser behavior parity (declarations, statements, expressions, types, patterns).
- Parser recovery behavior sufficient for deterministic dumps on valid inputs.
- Deterministic AST dump formatting parity with Stage0:
  - header lines
  - declaration index table
  - `---` separator
  - rendered module body text
- Self-host CLI support for `check --dump-ast`.
- Wave 3 parser unit tests and Stage0 parity scripts.

## Out of scope

- Resolve/HIR, typing, borrow, MIR, async lowering, codegen changes.
- Diagnostic text parity as a primary gate (except parse/dump stability requirements).
- New syntax/features not already in Stage0.

---

## Current Gaps (in this tree)

- Self-host `check` currently ignores `--dump-ast`.
- Self-host `ast` command output is not Stage0 dump format:
  - missing deterministic header/index table
  - different rendering details
- Parser/AST behavior drift still exists relative to Stage0 for non-trivial constructs.
- No dedicated Wave 3 parser unit gate or AST parity harness exists yet.

---

## Stage0 AST Dump Contract (Parity Target)

For `check --dump-ast`, Stage0 emits:

1. `module span=<start>..<end> decls=<N>`
2. one line per declaration:
   - `decl[<i>] kind=<DECL_KIND> span=<start>..<end>`
3. separator line:
   - `---`
4. canonical rendered module text from `render.renderModule(...)`

Wave 3 must match this contract exactly (including spacing/newlines/order).

---

## Target Deliverables

1. Parser parity core:
   - declaration parsing parity
   - expression precedence/associativity parity
   - type-expression and pattern parsing parity
2. AST representation parity (or equivalent mapping) sufficient to render Stage0-compatible AST dumps.
3. Stage0-compatible AST renderer and dump entry path in self-host.
4. Wave 3 validation suite:
   - parser unit tests
   - Stage0-vs-selfhost AST dump parity script
   - determinism re-run checks for self-host output

---

## Target File Plan

Primary implementation files:

- `src/Ast.w`
- `src/Parser.w`
- `src/Parse.w`
- `src/render.w`
- `src/main.w` (`check --dump-ast` plumbing)
- optional: `src/compiler/Frontend.w` if AST dump path needs frontend coordination

New Wave 3 tests/scripts:

- `test/wave3/*` parser/AST unit tests
- `test/wave3/ast_corpus.txt`
- `scripts/run_wave3_parser_unit_tests.sh`
- `scripts/run_wave3_ast_parity.sh`

If helper modules are introduced, keep one canonical parser/render path (no duplicate parser implementations).

---

## Execution Plan (Ordered)

## 0. Lock Wave 3 Oracle Contract + Corpus

- Freeze AST dump contract from Stage0 current behavior.
- Create Wave 3 AST corpus list:
  - start from Wave 0 corpus
  - add parser-heavy cases (traits, impls, pattern/with/match, async forms, generics, imports)
- Record Stage0 baseline AST dumps for corpus.

## 1. Parser Surface Inventory vs Stage0

- Map Stage0 parser capabilities from `bootstrap/src/Parser.zig` and `bootstrap/src/Parse.zig` tests:
  - top-level declarations
  - attributes/annotations
  - blocks/statements
  - expression forms and postfix chains
  - type syntax
  - pattern syntax
  - recovery points
- Generate explicit gap list against `src/Parser.w`.

## 2. AST Shape and Span Parity

- Align AST node encoding/fields in `src/Ast.w` with Stage0 semantics as needed for dump parity.
- Ensure span start/end rules match Stage0 for module and declarations.
- Ensure declaration ordering and stored kinds match Stage0 dump expectations.

## 3. Declaration Parser Parity

- Implement/align top-level parsing for:
  - `fn`, `async fn`, `gen fn`, `comptime fn`
  - `type` (alias/struct/enum/distinct)
  - `use`
  - `let`/`var` top-level
  - `extern fn`, `c_import`
  - `trait`, `impl`, `extend`
  - attribute-bearing declarations (`@[...]`)
- Align public/private and flag handling behavior with Stage0.

## 4. Statement + Expression Parser Parity

- Align recursive-descent expression parser:
  - precedence and associativity
  - unary/binary/call/field/index chains
  - control expressions (`if`, `match`, loops, `with`, `defer`, `await`, `spawn`)
  - literals and grouped forms
- Add/align missing literal parsing now required by Wave 2 lexer parity (notably `char` literal expression support).

## 5. Type + Pattern Parser Parity

- Align parsing of type expressions used in signatures, bindings, payloads.
- Align parsing of pattern forms used by `match`, `if let`, `while let`, destructuring.
- Ensure parser recovery remains deterministic on malformed inputs.

## 6. AST Renderer + Dump Formatting Parity

- Align `src/render.w` text output to Stage0 canonical AST rendering.
- Implement deterministic AST dump wrapper in self-host:
  - header
  - decl table
  - separator
  - rendered body
- Ensure output newline behavior matches Stage0 exactly.

## 7. CLI + Pipeline Plumbing

- Add `--dump-ast` handling to self-host `check` command.
- Ensure dump path uses the same frontend import/c_import expansion semantics expected by Stage0 AST dump behavior.
- Keep `ast <file.w>` command as compatibility alias/wrapper to shared AST dump path where possible.

## 8. Wave 3 Tests

- Add parser unit tests by category:
  - declarations/imports/attributes
  - statements/expressions/precedence
  - types/patterns
  - parser recovery
  - render format fragments
- Add deterministic AST dump format tests (header/table/separator/body shape).

## 9. Stage0 Parity Harness

- Add `scripts/run_wave3_ast_parity.sh`:
  - build Stage0
  - build/reuse self-host
  - run AST dumps over corpus for both
  - verify self-host deterministic repeat output
  - diff Stage0 vs self-host outputs byte-for-byte

## 10. Integration + Documentation

- Document Wave 3 commands and expected gate outputs.
- Update Wave status docs when parity gate is green.

---

## Validation Strategy

Wave 3 uses two gates:

1. Parser/AST unit correctness:
   - `scripts/run_wave3_parser_unit_tests.sh`
2. Oracle parity:
   - `scripts/run_wave3_ast_parity.sh`
   - strict byte diff: Stage0 vs self-host `check --dump-ast`

Corpus policy:

- stable, explicit file list in `test/wave3/ast_corpus.txt`
- sorted iteration for deterministic script behavior

---

## Acceptance Criteria (Wave 3 Exit)

1. Self-host supports `check <file> --dump-ast`.
2. Self-host AST dump format matches `docs/wave0-dump-spec.md` AST section and Stage0 behavior.
3. Stage0 and self-host AST dumps are byte-identical on Wave 3 corpus.
4. Parser unit suite passes across declaration/expression/type/pattern/recovery buckets.
5. No non-parser compiler-phase behavior changes are required to pass Wave 3 gate.

---

## Risks and Mitigations

- Risk: AST render drift causes false parity failures.
  - Mitigation: lock render contract first and use strict golden diffs early.
- Risk: parser recovery differences create unstable outputs on malformed sources.
  - Mitigation: keep parity corpus to valid programs for gate; unit-test recovery separately.
- Risk: import expansion differences between Stage0 and self-host affect AST dump even when parser is correct.
  - Mitigation: explicitly include import/c_import cases in corpus and align frontend dump path behavior.
- Risk: Wave 3 scope creep into Sema/typed behavior.
  - Mitigation: treat `--dump-ast` path as parser/AST-only objective and gate changes to parser/render/CLI plumbing.

---

## Implementation Checklist

- [x] Freeze Wave 3 AST oracle contract against Stage0 current output.
- [x] Define Wave 3 AST parity corpus file.
- [x] Inventory Stage0 parser feature buckets from `bootstrap/src/Parser.zig` + `bootstrap/src/Parse.zig` tests.
- [ ] Align `src/Ast.w` node coverage/flags/spans needed for Stage0 dump parity.
- [x] Align module span + decl span computation with Stage0 behavior.
- [ ] Align top-level declaration parsing parity (`fn/type/use/let/extern/trait/impl/extend/c_import`).
- [ ] Align attribute parsing parity (`@[...]` forms used in Stage0).
- [ ] Align expression parser precedence/associativity with Stage0.
- [x] Add/align missing literal expression parsing (including `char` literal expressions).
- [ ] Align type-expression parsing parity.
- [ ] Align pattern parsing parity.
- [ ] Align parser recovery behavior for deterministic outputs.
- [x] Align `src/render.w` with Stage0 AST render format.
- [x] Add self-host `check --dump-ast` support in `src/main.w`.
- [x] Route `ast` command through shared dump formatting path where practical.
- [x] Add `test/wave3/` parser and render unit tests.
- [x] Add deterministic AST dump format checks.
- [x] Add `scripts/run_wave3_parser_unit_tests.sh`.
- [x] Add `scripts/run_wave3_ast_parity.sh` (Stage0 vs self-host diff + determinism re-run).
- [x] Verify Wave 3 gates pass locally.
- [x] Mark Wave 3 progress in `docs/with-selfhost-plan.md` and `docs/with-selfhost-detailed-plan.md`.

Current scope note:
- Wave 3 parity gate is green for the explicit Wave 3 corpus in `test/wave3/ast_corpus.txt`.
- Unchecked items above remain follow-up work to broaden parity coverage (notably full top-level declaration parity, attribute parity, and parser recovery parity).
