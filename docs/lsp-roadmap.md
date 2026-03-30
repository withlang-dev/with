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
with imports and sema. Used for type-aware dot completion, cross-file
go-to-definition, hover with type info, and diagnostics.

Every handler knows which tier it needs. Most requests use the fast
tier. The slow tier result is opportunistic — if it's available and
fresh, use it. If not, degrade gracefully to fast-tier results.

**KNOWN BLOCKER: The slow tier currently fails for most files.**
`ensure_analyzed()` runs `Compilation.compile_source_text` with
`PRELUDE_CORE` mode, which imports `std.math`, which uses
`c_import("math.h")`. The c_import processing fails in the LSP
context, producing an empty compiled pool. This means:
- `cached_decl_paths` is empty (no cross-file data)
- `cached_pool` has no user declarations (only prelude fragments)
- Diagnostics, hover, and cross-file go-to-definition degrade to
  fast-tier fallbacks

**Fixing this requires either:**
1. Making `std.prelude_core` not import `std.math` (which uses c_import), or
2. Making c_import errors non-fatal so user declarations survive, or
3. Using `PRELUDE_NONE` mode for the slow tier (no c_import, but also no
   prelude builtins — print, assert, etc. show as undefined)

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
- [x] `parse_block_or_expr` continues block after recovery (checks column
      to decide if recovered statement is still in the same block)
- [x] Sema propagates TY_ERR through poisoned nodes, no secondary type errors
- [x] 12 error recovery test files, all produce errors without crashes
- [x] Broken `let x = !!!` produces ONE error; subsequent `let y = 10`
      and `print(y)` parse and type-check correctly

---

## Phase 3: Scope-Aware Completion — DONE

- [x] `lsp_parse_file(text) -> LspParseResult` — fast tier entry point
- [x] `lsp_find_enclosing_fn(pool, offset)` — uses next decl start as
      upper bound (not just get_end, which misses trailing blank lines)
- [x] `lsp_collect_fn_params(pool, intern, fn_node) -> Vec[str]`
- [x] `lsp_collect_bindings_rec(pool, intern, node, offset) -> Vec[str]`
      — recursive walk returning Vec (not mutating a passed-in Vec, not
      encoding as comma-separated strings). Handles NK_BLOCK, NK_FOR,
      NK_IF_EXPR, NK_WHILE, NK_LOOP, NK_MATCH, NK_LET_BINDING.
- [x] Scope boundaries: let inside if-block NOT visible after the block
- [x] For-loop bindings visible inside the loop body
- [x] Tested: params, bindings, no cross-function leak, for-loop bindings,
      scope boundaries, use std. module completion

---

## Phase 4: Cross-File Go-to-Definition — PARTIALLY DONE

**What works:**
- [x] `cached_decl_paths` stored on LspDocument from slow tier
- [x] Definition handler checks decl_source_paths for cross-file navigation
- [x] Fast-tier fallback for same-file definitions
- [x] Same-file go-to-definition tested and working

**What does NOT work (was marked done but wasn't):**
- [ ] **Cross-file go-to-definition is untested and non-functional.**
      The slow tier fails due to c_import errors (see KNOWN BLOCKER above),
      so `cached_decl_paths` is always empty. The cross-file code path
      exists but has never successfully resolved a cross-file definition.
- [ ] Need test: file A imports file B, go-to-definition on a function
      from B returns the correct location in B.

---

## Phase 5: Signature Help — DONE

- [x] Token walk backward to find opening `(` and function name
- [x] Comma counting for active parameter index
- [x] Function lookup via fast-tier parse, fn_meta for param names/types
- [x] Tested at param positions 0, 1, 2 and outside call (null)

---

## Phase 6: Type-Aware Dot Completion — PARTIALLY DONE

**What works:**
- [x] Dot context detection (char before cursor is `.`)
- [x] Type resolution via fast-tier heuristics:
      - Parameter type annotations: `fn f(x: MyType)` → MyType
      - Struct literal bindings: `let p = Point {...}` → Point
      - String literals → str
      - Constructor calls: `Vec.new()` → Vec
- [x] Struct fields from type declaration AST walk
- [x] Builtin methods: str (13), Vec (7), HashMap (7)
- [x] Module completion (`use std.`) checked before dot detection
- [x] Tested: str, Vec, struct fields, parameter types

**What does NOT work (was marked done but wasn't):**
- [ ] **Slow tier `typed_expr_types` path not implemented.** The plan
      says "Resolve the receiver expression's type from the slow tier's
      typed_expr_types map." This was never attempted. All type resolution
      uses fast-tier AST heuristics which fail for non-trivial cases
      (return values of function calls, chained method calls, etc.)
- [ ] **extend block methods not implemented.** The plan says "For types
      with extend blocks: list methods defined in extend blocks for that
      type." The code has a comment "for now, skip" and does nothing.
- [ ] **Trait methods not implemented.** The plan says "For types with
      trait implementations: list trait methods." Not attempted.
- [ ] **Stale slow tier handling not implemented.** The plan says "Handle
      the case where the slow tier result is stale — show no dot
      completions rather than wrong completions." Not attempted because
      the slow tier is never used for dot completion.

---

## Phase 7: Find All References — PARTIALLY DONE

**What works:**
- [x] Same-file token scan for matching identifiers
- [x] Cross-file scanning via cached_decl_paths (reads and tokenizes
      imported files)
- [x] Tested: 4 references for `helper`, 2 for `x`, empty for non-ident

**What does NOT work (was marked done but wasn't):**
- [ ] **Not sema-based symbol resolution.** The plan says "Build a reverse
      index: for every identifier node in the project AST, record which
      symbol_id it resolves to." The implementation is text-based token
      matching. A function named `get` in one file will match every `get`
      in every imported file, including HashMap.get, Vec.get, etc.
- [ ] **No flag distinguishing definition from reference.** The plan says
      "Include the definition site in the results (with a flag
      distinguishing definition from reference)." Not implemented.
- [ ] **Cross-file scanning is blocked by the slow tier failure.**
      `cached_decl_paths` is empty when c_import fails, so no imported
      files are scanned.

---

## Phase 8: Rename Symbol — NOT STARTED

- [ ] Depends on Phase 7 (find all references)
- [ ] Return WorkspaceEdit with TextEdit entries
- [ ] Validate new name is a valid identifier
- [ ] Validate no name conflicts in scope
- [ ] Test across files

---

## Phase 9: Incremental Analysis — NOT STARTED

Only pursue if slow tier latency is a problem.

---

## Phase 10: Background Analysis + Cancellation — NOT STARTED

Only pursue if synchronous analysis causes UI lag.

---

## Summary of Honest Status

| Phase | Status | Key Gap |
|-------|--------|---------|
| 1 | Done | — |
| 2 | Done | — |
| 3 | Done | — |
| 4 | Partial | Cross-file untested, blocked by slow tier c_import failure |
| 5 | Done | — |
| 6 | Partial | No extend methods, no trait methods, no slow tier type resolution |
| 7 | Partial | Text matching not symbol resolution, cross-file blocked by slow tier |
| 8 | Not started | — |
| 9 | Not started | — |
| 10 | Not started | — |

**The single biggest blocker across phases 4, 6, and 7 is the slow tier
c_import failure.** Fixing this would unblock cross-file go-to-definition,
enable sema-based type resolution for dot completion, and provide actual
cross-file reference scanning.

48 automated tests pass (test/lsp/run_lsp_tests.sh).
