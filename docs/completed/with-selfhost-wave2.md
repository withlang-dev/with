# Wave 2 Implementation Plan

## Lexer (Withc2)

## Goal

Implement Wave 2 lexer foundations for the self-hosted compiler:

- token definitions
- scanner/lexer implementation
- deterministic token dump output

Wave 2 exit gate:

- `--dump-tokens` output from self-host matches Stage0 byte-for-byte on the Wave 2 corpus.

---

## Inputs and Constraints

- Canonical wave definition:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle lexer implementation:
  - `bootstrap/src/Token.zig`
  - `bootstrap/src/Lexer.zig`
  - `bootstrap/src/main.zig` (`collectTokensDump`, `--dump-tokens` behavior)
- Dump format contract:
  - `docs/wave0-dump-spec.md` (tokens section)
- Reference architecture influences:
  - `.reference/zig/src/link/tapi/Tokenizer.zig` (simple state-machine tokenizer structure)
  - `.reference/rust/compiler/rustc_lexer/src/lib.rs` (clean lexer/parser separation and deterministic token model)

Stage0 remains the oracle. No semantics changes are allowed in Wave 2.

---

## Scope

## In scope

- Token/tag model parity with Stage0.
- Lexer scanning parity with Stage0 tokenization behavior.
- Self-host CLI support for `check <file> --dump-tokens`.
- Deterministic token dump formatter in self-host matching Stage0 format and escaping.
- Wave 2 unit and parity tests.

## Out of scope

- Parser/AST parity (`--dump-ast`) work (Wave 3).
- Resolve/HIR, typing, borrow, MIR, codegen changes.
- New language features.

---

## Current Gaps (in this tree)

- Self-host `check` command does not support Stage0 dump flags yet.
- Self-host `tokens` output format is debug numeric (`<tag-int> <lexeme>`) and does not match Stage0 dump schema.
- Lexer/token drift exists vs Stage0 behavior and naming (example: Stage0 has explicit `bang` token handling and canonical tag names used by dump output).
- No Wave 2 parity harness yet for Stage0 vs self-host token dump diffs.

---

## Target Deliverables

1. Stage0-parity token model in self-host:
   - complete token tag set
   - keyword mapping parity
   - canonical tag name mapping used in dumps
2. Stage0-parity scanner in self-host:
   - operator, literal, identifier, comment, newline, and EOF behavior
   - matching diagnostics-triggering cases where tokenization returns `invalid`
3. Stage0-parity token dump path in self-host:
   - `check <file> --dump-tokens`
   - deterministic line format:
     - `tokens file=<path> count=<N>`
     - `tok[<i>] tag=<TAG> span=<start>..<end> lex="<escaped_lexeme>"`
4. Wave 2 validation harness:
   - lexer-focused unit tests
   - Stage0-vs-selfhost token dump parity script
   - deterministic re-run check (same compiler, same input, same bytes)

---

## Target File Plan

Primary implementation files:

- `src/Token.w`
- `src/Lexer.w`
- `src/main.w` (CLI dump flag plumbing and token dump emitter)

New Wave 2 tests/scripts:

- `test/wave2/*` (lexer unit coverage)
- `scripts/run_wave2_lexer_unit_tests.sh`
- `scripts/run_wave2_token_parity.sh`

Potential helper file (if needed):

- `src/compiler/frontend/LexDump.w` (shared deterministic dump formatter)

If helper files are added, keep a single implementation path and avoid duplicate lexer logic.

---

## Execution Plan (Ordered)

## 0. Lock Wave 2 Oracle Contract

- Freeze the token dump contract for Wave 2 to Stage0 current behavior.
- Record exact Stage0 outputs for Wave 2 corpus cases.
- Define the Wave 2 corpus list (start from Wave 0 corpus and add lexer edge-case files).

## 1. Token Model Parity

- Align `src/Token.w` tag set with `bootstrap/src/Token.zig`.
- Align keyword lookup behavior (`fromKeyword` equivalent).
- Align tag-name mapping used by deterministic dumps.
- Keep token list API deterministic and stable for parser consumers.

## 2. Lexer Scanner Parity

- Align whitespace/newline rules (newline significant, horizontal whitespace skipped).
- Align operators and compound tokenization rules.
- Align identifiers, keywords, labels, and dot-identifiers.
- Align numeric literal scanning and suffix handling.
- Align string scanning:
  - normal strings
  - triple-quoted strings
  - interpolation-safe string traversal behavior
  - c-string form (`c"..."`)
- Align comment handling (`//` scanned then filtered in final token stream).
- Align EOF and invalid token emission behavior.

## 3. Self-Host Dump Flag Plumbing

- Add `--dump-tokens` support to self-host `check` command.
- Implement deterministic token dump output in self-host matching Stage0 escape rules.
- Keep `tokens <file.w>` as compatibility command; route through shared dump path where possible.

## 4. Wave 2 Tests

- Add unit tests in `test/wave2/` mirroring Stage0 lexer behavior coverage:
  - keyword set
  - keyword-like identifiers
  - operator set
  - operator edge/invalids
  - punctuation and delimiters
  - newline significance
  - literals
  - unterminated string
  - dot-identifier shorthand
  - comments
- Add deterministic dump formatting unit checks (escaping and span formatting).

## 5. Stage0 Parity Harness

- Add `scripts/run_wave2_token_parity.sh`:
  - builds Stage0 compiler
  - builds/reuses self-host compiler
  - runs token dumps for each corpus case on both compilers
  - checks self-host determinism by repeated run
  - diffs Stage0 vs self-host output byte-for-byte
- Provide `--update` mode only for self-host expected snapshots if needed, never for Stage0 oracle artifacts.

## 6. Integration and Documentation

- Wire Wave 2 scripts into the developer workflow docs.
- Update Wave progress docs when Wave 2 gate is green.

---

## Validation Strategy

Wave 2 validation has two layers:

1. Unit correctness:
   - `scripts/run_wave2_lexer_unit_tests.sh`
2. Oracle parity:
   - `scripts/run_wave2_token_parity.sh`
   - strict diff of `check <file> --dump-tokens` output between Stage0 and self-host

Minimum corpus baseline:

- `bootstrap/test/golden/wave0/corpus.txt`

Wave 2 should extend this with lexer-focused edge cases (especially literals/operators/comments).

---

## Acceptance Criteria (Wave 2 Exit)

1. Self-host supports `check <file> --dump-tokens`.
2. Self-host deterministic token dump format matches `docs/wave0-dump-spec.md`.
3. Stage0 and self-host token dumps are byte-identical across the Wave 2 corpus.
4. Lexer unit tests pass for all Stage0 behavior buckets listed above.
5. No parser or later-pass semantic changes are introduced by Wave 2 work.

---

## Risks and Mitigations

- Risk: hidden lexer behavior drift from Stage0 in corner cases.
  - Mitigation: port Stage0 lexer test categories and add parity diff harness early.
- Risk: dump output churn from formatting differences, not lexical semantics.
  - Mitigation: share one deterministic dump formatter path and lock escape rules.
- Risk: accidental scope creep into parser/AST while wiring flags.
  - Mitigation: enforce Wave 2 boundary in review and keep changes isolated to token/lexer/dump paths.
- Risk: bootstrap constraints blocking self-host rebuild in dirty trees.
  - Mitigation: keep Wave 2 tests runnable directly with bootstrap binary and isolated test files.

---

## Implementation Checklist

- [x] Freeze Wave 2 token oracle contract against Stage0 current output.
- [x] Define Wave 2 token parity corpus file.
- [x] Align `src/Token.w` tag set with `bootstrap/src/Token.zig`.
- [x] Align keyword lookup behavior with Stage0.
- [x] Align tag-name mapping used by dump output.
- [x] Align `src/Lexer.w` whitespace and newline behavior.
- [x] Align operator and compound token scanning behavior.
- [x] Align identifier/keyword/label/dot-identifier behavior.
- [x] Align number literal scanning and suffix handling.
- [x] Align string/c-string/triple-string scanning behavior.
- [x] Align comment scanning/filtering behavior.
- [x] Align invalid token behavior and lexer diagnostics behavior.
- [x] Add self-host `check --dump-tokens` support in `src/main.w`.
- [x] Implement Stage0-compatible deterministic token dump formatting and escaping.
- [x] Keep/update `tokens <file.w>` compatibility path to use the same dump logic.
- [x] Add `test/wave2/` lexer unit tests for all Stage0 lexer categories.
- [x] Add deterministic dump-format unit checks.
- [x] Add `scripts/run_wave2_lexer_unit_tests.sh`.
- [x] Add `scripts/run_wave2_token_parity.sh` (Stage0 vs self-host diff + determinism re-run).
- [x] Verify Wave 2 gate passes locally.
- [x] Mark Wave 2 progress in `docs/with-selfhost-plan.md` and `docs/with-selfhost-detailed-plan.md`.
