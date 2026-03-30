# LSP Roadmap — Full Implementation Plan

Based on analysis of rust-analyzer, gopls, and ZLS architectures.

## Current State (v0.1)

- Single-threaded, synchronous main loop
- Re-compiles from scratch on every request (no caching)
- Completion: keyword list + top-level declarations + embedded module names
- Go-to-definition: top-level declaration name matching only
- Hover: declaration kind + name only
- No cross-file navigation
- No scope-aware completion
- No type-aware dot completion

## Phase 1: Cached Per-File Analysis

**Goal:** Don't re-compile on every keystroke.

Store per-file: `{ text_hash, ast_pool, intern_pool, sema, diagnostics }`.
Only re-analyze when text actually changes (compare hash).

This alone will make diagnostics, hover, and go-to-definition near-instant
for repeated queries on unchanged files.

**Implementation:**
- Add `LspFileCache` type with text hash + cached compilation result
- In `lsp_publish_diagnostics`, `lsp_hover`, `lsp_definition`: check
  cache before compiling. Reuse if hash matches.
- Invalidate on `didChange` / `didSave`.

## Phase 2: Scope-Aware Completion

**Goal:** When typing inside a function body, suggest locals, parameters,
and imported names — not just top-level declarations.

**rust-analyzer approach (fake identifier):**
1. Insert `__COMPLETION_MARKER__` at cursor position
2. Re-parse the modified text
3. Find the marker in the AST
4. Walk up from the marker to determine context:
   - Inside a function body → suggest locals + params + imported names
   - After a dot → suggest fields + methods of the receiver type
   - After `use` → suggest modules
   - At top level → suggest keywords + declaration starts

**Implementation:**
- Add `lsp_completion_with_context()` that inserts marker + re-parses
- For function body context: walk sema's scope to collect in-scope names
- For dot context: resolve receiver type, list fields + methods

## Phase 3: Type-Aware Dot Completion

**Goal:** `foo.` suggests fields and methods based on `foo`'s resolved type.

**Requires:** Phase 2 (context detection) + sema type information.

**Implementation:**
- After resolving receiver type from sema, query:
  - Struct fields (from type declaration)
  - Methods defined in `extend` blocks
  - Trait methods for implemented traits
  - Builtin methods (Vec.push, str.len, etc.)
- Score by relevance: exact type match > compatible > trait method

## Phase 4: Cross-File Go-to-Definition

**Goal:** Click on a symbol from an imported module, jump to its definition
in the imported file.

**Implementation:**
- During compilation, record a `symbol → definition_location` map
  where location includes file path + byte offset
- The compiler already resolves imports in `Frontend.w` →
  `process_imports_frontend`. Each imported declaration knows its
  source file via `decl_source_paths`.
- On go-to-definition request: look up the symbol in the resolution
  map, return the source file + position.

## Phase 5: Error-Tolerant Parser Improvements

**Goal:** The parser produces a useful AST even when code is broken
mid-keystroke.

**Current state:** NK_POISONED_EXPR nodes exist but are used in only
15 sites. Many error paths still return 0 (null node).

**Go approach:** `BadExpr`, `BadStmt`, `BadDecl` placeholder nodes with
position ranges. Parser never aborts — always returns a tree.

**rust-analyzer approach:** Lossless parser captures every byte. ERROR
nodes wrap problematic tokens. Tree is always complete.

**Implementation for With:**
- Convert remaining `return 0` after `emit_error` to return
  `NK_POISONED_EXPR` / `NK_POISONED_DECL`
- Add statement-level recovery: on unexpected token at statement
  position, skip to next line at same/lower indentation, insert
  error node, continue parsing
- Ensure sema handles all poisoned nodes (returns TY_ERR, no
  secondary errors)
- Test with deliberately broken files to verify recovery quality

## Phase 6: Find All References

**Goal:** "Where is this function/type/variable used?"

**Implementation:**
- Walk the entire project AST looking for identifier nodes that
  resolve to the target symbol
- Requires the symbol resolution map from Phase 4
- For each reference, return file + range

## Phase 7: Rename Symbol

**Goal:** Rename a symbol across all files.

**Requires:** Find All References (Phase 6).
- Collect all reference locations
- Return a `WorkspaceEdit` with text edits for each location

## Phase 8: Signature Help

**Goal:** While typing function arguments, show parameter names + types.

**Triggered by:** `(` and `,` characters.

**Implementation:**
- Determine which function call the cursor is inside
- Look up the function's signature (parameter names + types)
- Determine which parameter position the cursor is at
- Return `SignatureHelp` with active parameter highlighted

## Phase 9: Incremental Analysis (salsa-style)

**Goal:** Only re-analyze what changed, not the whole project.

**Only pursue if Phase 1 caching proves insufficient.**

**Architecture:**
- Track file dependency graph (from `use` declarations)
- When file A changes: re-analyze A, then re-analyze any file that
  imports A (transitively)
- Cache intermediate results (parse tree, resolved AST, typed AST)
  at each stage boundary
- Invalidation is per-file, not per-project

## Phase 10: Background Analysis + Cancellation

**Goal:** Analysis runs on a background thread; main thread handles I/O.

**Implementation:**
- Main thread: read JSON-RPC, dispatch requests, write responses
- Worker thread: runs compilation, produces results
- On new `didChange`: cancel in-flight analysis, start fresh
- Debounce: wait 100-200ms after last edit before starting analysis

## Priority Order

| Phase | Impact | Effort | Prerequisite |
|-------|--------|--------|--------------|
| 1. Cached analysis | High | Small | None |
| 2. Scope-aware completion | High | Medium | Phase 1 |
| 3. Dot completion | High | Medium | Phase 2 |
| 4. Cross-file go-to-def | Medium | Medium | Phase 1 |
| 5. Error-tolerant parser | High | Large | None |
| 6. Find references | Medium | Medium | Phase 4 |
| 7. Rename | Medium | Small | Phase 6 |
| 8. Signature help | Medium | Small | Phase 2 |
| 9. Incremental analysis | Low | Large | Phase 4 |
| 10. Background thread | Low | Large | Phase 9 |

Phases 1-4 make the LSP genuinely useful. Phase 5 makes it robust.
Phases 6-8 are polish. Phases 9-10 are optimization.
