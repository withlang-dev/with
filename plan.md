# Self-Host Compiler Quality Fix Plan

Each task: (1) verify spec behavior, (2) add/update test, (3) fix implementation.

Tests run via `./bootstrap/zig-out/bin/with run test/wave<N>/<file>.w` or `./with-stage1 run test/wave<N>/<file>.w`.

---

## 1. Fix `main.w` flag parsing: `if` → `else if`

**Spec ref:** N/A (CLI behavior, not language spec). Flags are mutually exclusive per arg — once matched, skip remaining checks.

**Test:** `test/wave11/cases/cli_flag_parsing_test.w` — not directly testable as a unit test (requires CLI invocation). Instead, validate by code inspection that `else if` chains prevent redundant matching.

**Implementation:**
- [ ] In `src/main.w` lines 46–76, change the chain of independent `if` statements to `if`/`else if` so each arg is matched at most once.

---

## 2. Replace O(n) linear scans in AstPool metadata lookups with HashMaps

**Spec ref:** §29 (Implementation Notes) — no specific requirement, but the spec implies efficient compilation. The AST pool is the central data structure; O(n²) scaling violates the "stay out of your way" principle.

**Test:** `test/wave3/ast_meta_lookup_test.w` — create an AstPool with many fn/type/for nodes, verify that `find_fn_meta`, `find_type_meta`, `find_for_meta`, `find_fn_param_pattern_meta` return correct results after the change.

**Implementation:**
- [ ] Add `fn_meta_map: HashMap[i32, i32]` to `AstPool` (node → record offset in `fn_meta`).
- [ ] Add `type_meta_map: HashMap[i32, i32]` to `AstPool`.
- [ ] Add `for_meta_map: HashMap[i32, i32]` to `AstPool`.
- [ ] Add `fn_param_pattern_meta_map: HashMap[i32, i32]` to `AstPool`.
- [ ] Populate each map in the corresponding `add_*_meta` functions.
- [ ] Rewrite each `find_*_meta` to do a HashMap lookup with fallback to -1.
- [ ] Verify all existing wave3 parser tests still pass.

---

## 3. Extract duplicated Sema creation boilerplate in Driver.w

**Spec ref:** N/A (internal refactor). The compilation pipeline (§ implementation notes) specifies Lex→Parse→Resolve→Sema→MIR→Codegen, but doesn't mandate internal factoring.

**Test:** Existing wave11 driver tests + `with check` and `with build` commands must still work. Run `test/wave11/cases/driver_simple.w` and the `with check` path on a sample file.

**Implementation:**
- [ ] Create `Driver.create_sema(self, pool: AstPool) -> Sema` helper that handles: init, source_text, no_std, alloc, check_module, and propagation of pool/diags/typed maps back to Driver.
- [ ] Replace the duplicated boilerplate in `dump_typed`, `emit_typed`, `run_mir_lower`, and `compile_source` with calls to the new helper.
- [ ] Verify all existing tests pass (wave6, wave7, wave10, wave11).

---

## 4. Flatten deeply nested suffix parsing in Lexer.lex_number

**Spec ref:** §4.1 (Primitive Types), §29.5 (Byte literals). The spec defines numeric suffixes `_i8`, `_i16`, `_i32`, `_i64`, `_u8`, `_u16`, `_u32`, `_u64`, `_f32`, `_f64`. The lexer must accept all of these after integer or float literals.

**Test:** `test/wave2/lexer_numeric_edges_test.w` already exists — extend it with explicit suffix coverage for all 10 suffix types. Verify `100_i8` → TK_INT_LIT, `3.14_f32` → TK_FLOAT_LIT, etc.

**Implementation:**
- [ ] Replace the 10-level nested if/else chain in `Lexer.lex_number` (lines 401–431) with a sequential loop over suffix candidates, breaking on first match.
- [ ] Verify all wave2 lexer tests still pass.

---

## 5. Fix O(n²) string building in `escape_dump_lexeme`

**Spec ref:** N/A (debug output utility). No spec requirement, but this is a correctness/performance issue for `with tokens` and `with check --dump-tokens`.

**Test:** `test/wave2/lexer_escape_dump_test.w` — tokenize a source string with special characters, call the escape function on the lexeme, and verify output correctness.

**Implementation:**
- [ ] Rewrite `escape_dump_lexeme` in `src/main.w` to avoid repeated `out = out ++ char` pattern. Use a strategy that builds the result more efficiently (e.g., only use `++` for multi-char escape sequences, and use `slice` to copy non-special runs in bulk).
- [ ] Verify `with tokens` and `with check --dump-tokens` produce identical output.

---

## 6. Fix escaped brace handling in string interpolation lexing

**Spec ref:** §29.7 (String escape parity) — `\\` is a standard escape. Per the spec, `\\{` should be a literal backslash followed by an interpolation opening brace. The current lexer incorrectly treats `\\{` as an escaped brace (no interpolation).

**Test:** `test/wave2/lexer_string_interp_brace_test.w` — lex `"\\\\{x}"` and verify it produces a single `TK_STRING_LIT` that contains both the escaped backslash and the interpolation. Also test `"\\{"` (escaped brace, no interpolation) and `"\\\\{"` (escaped backslash + interpolation).

**Implementation:**
- [ ] In `Lexer.lex_string` (line 329), replace the single-char backslash check with a count of consecutive preceding backslashes. An opening brace is escaped only if preceded by an odd number of backslashes.
- [ ] Verify all wave2 lexer tests and `test/cases/behav_string.w` still pass.

---

## 7. Emit error for unterminated string literals

**Spec ref:** §29.7 (String escape parity) defines valid string escapes. An unterminated string is not in the spec's grammar — it should be a lexer error. The spec's error philosophy (§1.1) says the compiler should "catch real bugs."

**Test:** Extend `test/wave2/lexer_invalid_test.w` — add a case for `"unterminated` (no closing quote) and verify the token is `TK_INVALID` (not `TK_STRING_LIT`). Note: existing test at line 19 asserts unterminated raw strings produce `TK_STRING_LIT` for recovery — we should preserve that for raw strings but fix regular strings.

**Implementation:**
- [ ] In `Lexer.lex_string`, when the loop falls through without finding a closing `"`, return `TK_INVALID()` instead of `TK_STRING_LIT()` (line 358). Keep the raw string and triple-quote paths returning `TK_STRING_LIT` for error recovery.
- [ ] Update any existing tests that expect `TK_STRING_LIT` for unterminated regular strings.
- [ ] Verify all wave2 and wave3 tests pass.

---

## 8. Add HashMap overlay for Sema scope lookups

**Spec ref:** §29.8 (No-shadowing) — shadowing is disallowed. This means each scope has at most one binding per name, which makes a HashMap a natural fit.

**Test:** `test/wave6/cases/scope_binding_pass.w` already tests scope binding. Add `test/wave6/cases/scope_lookup_perf_test.w` with a function containing 50+ let bindings, verifying all are resolvable and type-correct.

**Implementation:**
- [ ] Add `scope_map: HashMap[i32, i32]` (sym → index in bind_names) to `Sema`.
- [ ] Update `scope_put_at` to insert into `scope_map`.
- [ ] Update `scope_lookup` to check `scope_map` first before falling back to linear scan.
- [ ] Update `pop_scope` to remove entries from `scope_map` for bindings being popped.
- [ ] Verify all wave6 sema tests pass.

---

## 9. Add named character constants to Lexer.w

**Spec ref:** §29.7 (String escape parity) — the spec defines `\\`, `\"`, `\n`, `\r`, `\t`, `\0`, `\xNN`. The lexer should use readable names for these code points.

**Test:** No new test needed — this is a readability refactor. All existing wave2 tests must pass unchanged.

**Implementation:**
- [ ] Add named constants at the top of `Lexer.w`: `fn CH_NEWLINE -> i32: 10`, `fn CH_TAB -> i32: 9`, `fn CH_SPACE -> i32: 32`, `fn CH_CR -> i32: 13`, `fn CH_DQUOTE -> i32: 34`, `fn CH_SQUOTE -> i32: 39`, `fn CH_BACKSLASH -> i32: 92`, `fn CH_LBRACE -> i32: 123`, `fn CH_RBRACE -> i32: 125`, `fn CH_LPAREN -> i32: 40`, `fn CH_RPAREN -> i32: 41`, `fn CH_LBRACKET -> i32: 91`, `fn CH_RBRACKET -> i32: 93`, `fn CH_DOT -> i32: 46`, `fn CH_SLASH -> i32: 47`, `fn CH_DASH -> i32: 45`, `fn CH_PLUS -> i32: 43`, `fn CH_STAR -> i32: 42`, `fn CH_EQ -> i32: 61`, `fn CH_BANG -> i32: 33`, `fn CH_QUESTION -> i32: 63`, `fn CH_LT -> i32: 60`, `fn CH_GT -> i32: 62`, `fn CH_PIPE -> i32: 124`, `fn CH_AMP -> i32: 38`, `fn CH_PERCENT -> i32: 37`, `fn CH_CARET -> i32: 94`, `fn CH_TILDE -> i32: 126`, `fn CH_AT -> i32: 64`, `fn CH_COLON -> i32: 58`, `fn CH_COMMA -> i32: 44`, `fn CH_SEMI -> i32: 59`, `fn CH_HASH -> i32: 35`, `fn CH_ZERO -> i32: 48`, `fn CH_NINE -> i32: 57`.
- [ ] Replace magic numbers in `Lexer.next_token`, `skip_whitespace`, `lex_string`, `lex_number`, `lex_ident`, `lex_dot_ident`, `lex_raw_string_prefixed`, `lex_byte_char_prefixed`, and helper functions with the named constants.
- [ ] Verify all wave2 lexer tests pass.

---

## 10. Mark MirOpt and BorrowCfg as stubs

**Spec ref:** The spec defines borrow checking (§3), MIR optimizations are implied by the compilation pipeline. These modules are placeholders for future work.

**Test:** No new tests needed — these are documentation-only changes.

**Implementation:**
- [ ] Add `// STUB: ...` header comments to `MirOpt.w` and `BorrowCfg.w` explaining they are scaffolding and do not yet perform real optimizations/analysis.
- [ ] In `MirOpt.w`, add a comment to `devirtualize`, `promote_non_escaping_boxes`, `eliminate_dead_fields`, and `elide_redundant_moves` noting they are counting-only stubs.

---

## 11. Remove or document no-op `deinit` functions

**Spec ref:** §2.4 (Destructors and `defer`) — Drop is deterministic. These no-op deinits suggest future cleanup but currently do nothing.

**Test:** No new tests — documentation/cleanup only.

**Implementation:**
- [ ] Add `// No-op: runtime handles cleanup. Reserved for future manual memory management.` to each no-op deinit in `Token.w`, `InternPool.w`, `BorrowCfg.w`, `Source.w`, `Mir.w`, `MirOpt.w`, `Diagnostic.w`, `Driver.w`.

---

## 12. Fix `find_source_arg` to handle `--long-flags`

**Spec ref:** N/A (CLI behavior). The current implementation checks `arg[0] != 45` (not `-`), which correctly skips single-dash flags but should also handle `--` flags — which it does, since `--` starts with `-`. However, there's a fragility: it doesn't skip flags with values like `--output foo.w`.

**Test:** Verify by code inspection. The current CLI doesn't have value-carrying flags, so this is future-proofing documentation only.

**Implementation:**
- [ ] Add a comment to `find_source_arg` documenting the assumption that all flags start with `-` and no flags take separate value arguments.
