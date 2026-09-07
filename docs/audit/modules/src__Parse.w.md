# Audit: src/Parse.w @ 450733e5

## Module summary
Facade (27 lines) coordinating lex + parse into a single call. Exports `ParseResult { pool, intern, diagnostics }`, `parse_module(source, file_id, intern, diagnostics) -> ParseResult`, `parse_source(source) -> AstPool`.

## Scope / targets
- T13 ownership/drop
- T15 migration fidelity (where applicable)
- T22 spec conformance

## Findings
None. Verdict basis below.

### T13 ownership/drop — CLEAN
- `parse_module` (Parse.w:18-23): takes `intern: InternPool`, `diagnostics: DiagnosticList` by value, moves both into `Parser.init(...)` (line 21). Returns `parser.intern` / `parser.diags` by move into `ParseResult` (line 23). No use-after-move (parser not touched after), no explicit drop, no double-move.
- `tokens` (line 20, `let tokens = lexer.tokenize()`) moved into `Parser.init`; `lexer`/`source` not used after — clean.
- `parse_source` (lines 25-27): builds fresh `InternPool.init()` / `DiagnosticList.init()`, returns only `result.pool`, implicitly dropping intern + diagnostics. Refutation attempt: searched in-repo callers (`grep -rn "parse_module|parse_source|use Parse" src/ lib/ tests/`) — zero imports of `use Parse`; all hits are `Parser.parse_module` method or `parse_source_arg` in bootstrap_main.w, i.e. a different symbol. Facade is currently uncalled, so the drop is unobservable dead-code behavior, not a live leak/corruption. If the facade gains callers expecting resolved symbols/diagnostics from `parse_source`, they would need the full `ParseResult`; as written the single-pool return matches its signature and header intent. Not filed as defect.
- Cross-check `src/Parser.w:110-125`: `Parser.init` forwards both pools by move to `init_with_pool`; symmetric with facade's moves.

### T15 migration fidelity — N/A / CLEAN
- No migration markers, no `compat` shims, no dual-implementation paths in this module. Nothing to compare for fidelity.

### T22 spec conformance — CLEAN
- Header comment (lines 1-3) promises "simplified parsing entry point... single call" — implementation does exactly lex-then-parse in one call. Signature/behavior consistent with sibling call sites' usage pattern (`Parser.init(tokens, source, file_id, intern, diagnostics)` + `parse_module()`), e.g. src/compiler/Frontend.w:432, src/main.w:2847.

## Probes
- EXECUTED (toolchain sanity): `printf 'fn main() -> i32:\n    0\n' > /tmp/parse_probe.w && ./out/bootstrap/bin/with-stage1 check /tmp/parse_probe.w` → `ok`, EXIT 0. Confirms seed compiler usable; does not exercise facade directly.
- HELD (direct facade probe): no harness binds `Parse.parse_module`/`parse_source` (zero `use Parse` in repo), and `with-stage1 check/run` has no flag to route through the facade; writing a dedicated With driver would require a new entry point — out of read-only scope. Reason recorded instead of a faked pass.
- Negative control: `grep -rn "use Parse" src/ lib/ tests/` → zero hits, confirming facade is dead code; no caller counterexample exists that would turn the `parse_source` pool-only return into an observable defect.

## Verdict
COMPLETE — no findings.
