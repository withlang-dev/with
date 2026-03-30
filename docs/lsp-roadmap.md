# LSP Roadmap

## Architecture

The LSP maintains two analysis tiers:

**Fast tier (parse-only).** On every keystroke, the LSP re-parses
the current file with no imports, no prelude, no sema. This produces
an AST with correct spans in under 50ms. Used for completion,
scope-aware suggestions, structural navigation, signature help,
and document symbols.

**Slow tier (full compilation).** On save or after a debounce timer
(200ms after last edit), the LSP runs the full compilation pipeline
with PRELUDE_NONE mode (no c_import, no prelude builtins). Used for
cross-file go-to-definition, hover with type info, and diagnostics.

Every handler knows which tier it needs. Most requests use the fast
tier. The slow tier result is opportunistic — if it's available and
fresh, use it. If not, degrade gracefully to fast-tier results.

**JSON parsing** uses a jsmn-based tokenizer (same algorithm as
`lib/std/json.w`). Messages are parsed once per request into a token
array; fields are navigated by token index.

---

## Phase 1: Cached Per-File Analysis — DONE

- [x] LspDocument with cached pool/intern/diags/decl_paths
- [x] Invalidation on didChange
- [x] All handlers read from cache

---

## Phase 2: Error-Tolerant Parser — DONE

- [x] All 59 `return (0) as NodeId` sites converted to `poisoned_expr()`
- [x] `Parser.recover_to_statement()` — skips to next statement keyword
- [x] `parse_primary` calls `recover_to_statement` on unrecognized tokens
- [x] `parse_block_or_expr` continues block after recovery
- [x] Sema propagates TY_ERR through poisoned nodes, no secondary type errors
- [x] 12 error recovery test files pass

---

## Phase 3: Scope-Aware Completion — DONE

- [x] `lsp_parse_file(text) -> LspParseResult` — fast tier entry point
- [x] `lsp_find_enclosing_fn`, `lsp_collect_fn_params`, `lsp_collect_bindings_rec`
- [x] Scope boundaries: let inside if-block NOT visible after the block
- [x] For-loop bindings visible inside loop body
- [x] Prelude builtins in completion list (print, assert, Vec, HashMap, Option, Result, etc.)
- [x] 13 tests pass

---

## Phase 4: Cross-File Go-to-Definition — DONE

- [x] `cached_decl_paths` stored on LspDocument from slow tier
- [x] Definition handler checks decl_source_paths for cross-file navigation
- [x] Fast-tier fallback for same-file definitions
- [x] Slow tier uses PRELUDE_NONE to avoid c_import failures
- [x] 3 tests pass

---

## Phase 5: Signature Help — DONE

- [x] Token walk backward to find opening `(` and function name
- [x] Comma counting for active parameter index
- [x] Function lookup via fast-tier parse
- [x] 6 tests pass

---

## Phase 6: Type-Aware Dot Completion — DONE

- [x] Dot context detection (char before cursor is `.`)
- [x] Type resolution via fast-tier heuristics
- [x] Struct fields from type declaration AST walk
- [x] Builtin methods: str (13), Vec (7), HashMap (7)
- [x] Extend block methods: scans NK_FN_DECL with mangled `TypeName.method` names
- [x] Trait methods: walks NK_IMPL_DECL to find trait, extracts method names from NK_TRAIT_DECL extra data
- [x] Module completion (`use std.`)
- [x] 15 tests pass (str, Vec, struct, params, extend, trait)

---

## Phase 7: Find All References — DONE

- [x] Same-file token scan for matching identifiers
- [x] Cross-file scanning via cached_decl_paths
- [x] 3 tests pass

Note: references use text-based token matching. A future improvement
would use sema-based symbol resolution to avoid false positives on
common names like `get`.

---

## Phase 8: Rename Symbol — DONE

- [x] `lsp_rename` handler with WorkspaceEdit response
- [x] Same-file lexical rename
- [x] Cross-file rename via cached_decl_paths (same scanning as find-references)
- [x] Identifier validation (rejects invalid names like `123bad`)
- [x] `renameProvider` capability advertised
- [x] 3 tests pass

---

## Phase 9: Doc Comments on Hover — DONE

- [x] `lsp_extract_doc_comment(text, decl_start)` extracts `///` lines above declarations
- [x] Hover popup shows declaration signature + doc comment separated by `---`
- [x] Supports fn, type, trait, let declarations
- [x] 2 tests pass
- [ ] Doc comments need to be added to stdlib — see `docs/add_doc_comments.md`

---

## Phase 10: Incremental Analysis — DONE

- [x] Fast-tier parse cache on LspDocument (`fast_pool`, `fast_intern`)
- [x] `ensure_parsed()` — re-parses only when text changes (checks `fast_text_len`)
- [x] `LspState.get_parsed(uri, text)` — returns cached fast-tier result, falls back to fresh parse
- [x] All request handlers use cached parse results (no re-lex + re-parse per request)
- [x] Cache invalidated on `didChange` (both fast and slow tiers)

---

## Phase 11: Proactive Analysis — DONE

- [x] `ensure_parsed()` + `ensure_analyzed()` triggered on `didOpen` — both tiers pre-cached before first request
- [x] `ensure_analyzed()` triggered on `didSave` — slow tier refreshed with latest saved content
- [x] Request handlers read from cache without triggering analysis
- [x] If cache is stale (mid-edit), `get_parsed` falls back to fresh fast-tier parse
- [x] Slow-tier cache checked but not re-triggered from request handlers

---

## Summary

| Phase | Status | Tests |
|-------|--------|-------|
| 1. Cached analysis | Done | — |
| 2. Error-tolerant parser | Done | 12 |
| 3. Scope-aware completion | Done | 13 |
| 4. Cross-file go-to-def | Done | 3 |
| 5. Signature help | Done | 6 |
| 6. Dot completion | Done | 15 |
| 7. Find references | Done | 3 |
| 8. Rename symbol | Done | 3 |
| 9. Doc comments on hover | Done | 2 |
| 10. Incremental analysis | Done | — |
| 11. Proactive analysis | Done | — |

64 automated tests pass (test/lsp/run_lsp_tests.sh).
