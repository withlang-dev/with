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

```
LspDocument = {
    text: str,
    // Fast tier — always current
    parsed_pool: AstPool,
    parsed_intern: InternPool,
    // Slow tier — may be stale
    compiled_pool: AstPool,
    compiled_intern: InternPool,
    compiled_diags: DiagnosticList,
    compiled_version: i32,      // text version when last compiled
}
```

---

## Phase 1: Cached Per-File Analysis

**Status: DONE**

LspDocument caches compiled results. `ensure_analyzed()` skips
recompilation when text hasn't changed. All handlers use the cache.

- [x] LspDocument with cached pool/intern/diags
- [x] Invalidation on didChange
- [x] All handlers read from cache

---

## Phase 2: Error-Tolerant Parser — DONE

**Goal:** The parser produces a useful AST for broken code.

- [x] Converted all 59 `return (0) as NodeId` sites to return
      `self.poisoned_expr()` with correct spans. The parser never
      returns a null node for a construct it attempted to parse.
- [x] Added `Parser.poisoned_decl()` helper alongside existing
      `poisoned_expr()`.
- [x] Added `Parser.recover_to_statement()` — skips to next
      statement keyword at line start, for statement-level recovery.
- [x] Sema already propagates TY_ERR through NK_POISONED_EXPR
      (SemaCheck.w:878) and MirLower handles it (MirLower.w:3354).
- [x] Test suite: 5 broken file tests (missing colon, unclosed
      paren, incomplete match, truncated body, incomplete dot
      expression). Parser produces walkable AST with correct spans
      for non-broken declarations.
- [x] Verified: parse of broken file produces all 3 declarations
      with correct spans, despite parse error in first function.
- [x] Fixed `lsp_parse_int` bug: was reading all digits in string
      (not stopping at first non-digit), causing `{"line":3,"character":4}`
      to parse line as 34.
- [x] Fixed `json_get_string` to unescape `\n`, `\t`, `\"`, `\\`
      in JSON string values (LSP sends escaped text in didOpen).

---

## Phase 3: Scope-Aware Completion — DONE

**Goal:** When typing inside a function body, suggest locals,
parameters, and imported names — not just top-level declarations.

Uses the fast tier (parse-only AST). No sema needed.

- [x] `lsp_parse_file(text) -> LspParseResult` — parse-only, no
      imports, no prelude, no sema. Returns pool + intern together.
- [x] `lsp_find_enclosing_fn(pool, offset) -> NodeId` — finds
      NK_FN_DECL whose span contains cursor.
- [x] `lsp_collect_fn_params(pool, intern, fn_node) -> Vec[str]`
      — reads fn_meta for parameter names. Verified fn_meta is
      populated by the parser.
- [x] Inline binding collection walks the function body block for
      NK_LET_BINDING and NK_FOR nodes before cursor offset.
      (Vec pass-by-value prevents recursive helper from persisting
      pushes — inlined into caller instead.)
- [x] Completion order: scope names (kind=6) → keywords (kind=14)
      → top-level declarations (kind=3/22).
- [x] Tested: params (name, age) + bindings (x, y) appear before
      keywords and declarations.

---

## Phase 4: Cross-File Go-to-Definition — DONE

**Goal:** Click on a symbol from an imported module, jump to its
definition in the source file.

Uses the slow tier (full compilation with imports resolved).

- [x] `cached_decl_paths: Vec[str]` added to LspDocument, populated
      from `comp.zcu.decl_source_paths` during `ensure_analyzed()`.
- [x] Definition handler checks `decl_source_paths[di]` — if the
      declaration's source file differs from the current file, reads
      the source file and computes line/col from the offset there.
- [x] Falls back to fast-tier same-file lookup (parse-only) when
      slow tier is unavailable.
- [x] Same-file definition tested and working.
- [x] Cross-file plumbing in place — when slow tier compilation
      succeeds with imports, declarations from imported files will
      navigate to the correct source location.

---

## Phase 5: Signature Help — DONE

**Goal:** While typing function arguments, show parameter names
and types.

- [x] Walk tokens backward from cursor to find opening `(` and
      function name. Count commas for active parameter index.
- [x] Look up function in fast-tier parse, read fn_meta for
      parameter names + types (NK_TYPE_NAMED, NK_TYPE_REF).
- [x] Return SignatureHelp with label, parameters, activeParameter.
- [x] Registered `(` and `,` as trigger characters.
- [x] Tested: `greet("hi", |)` shows activeParameter=1,
      `greet(|)` shows activeParameter=0. Full signature label
      includes parameter types.

---

## Phase 6: Type-Aware Dot Completion — DONE

**Goal:** `foo.` suggests fields and methods based on `foo`'s
resolved type.

Uses the fast tier with AST-based type inference.

- [x] Dot context detection: char before cursor is `.`, extract
      receiver identifier.
- [x] Type resolution via fast-tier parse:
      - Parameter type annotations: `fn f(x: MyType)` → MyType
      - Struct literal bindings: `let p = Point { ... }` → Point
      - String literals: `let s = "hi"` → str
      - Constructor calls: `let v = Vec.new()` → Vec
- [x] Struct fields: walk type declaration's extra data for field names.
- [x] Builtin methods: str (13 methods), Vec (7), HashMap (7).
- [x] Module completion (`use std.`) checked before dot detection
      to avoid false triggering.
- [x] Tests: str dot (len/slice/contains), struct fields (x/y/name),
      Vec methods (push/len/get), parameter type (User.name/age).
      39 total tests, all passing.

---

## Phase 7: Find All References

**Goal:** "Where is this function/type/variable used?"

Uses the slow tier (requires symbol resolution across files).

- [ ] Build a reverse index: for every identifier node in the
      project AST, record which symbol_id it resolves to and
      where it appears (file + offset + span).
- [ ] On find-references request: resolve the symbol at cursor,
      look up all locations in the reverse index, return them.
- [ ] Include the definition site in the results (with a flag
      distinguishing definition from reference).
- [ ] Handle multi-file projects: the reverse index must cover
      all files in the project, not just the current file.
- [ ] Test: function used in 3 files, find-references returns
      all 3 locations plus the definition.

---

## Phase 8: Rename Symbol

**Goal:** Rename a symbol across all files.

Depends on Phase 7 (find all references).

- [ ] Collect all reference locations from find-references.
- [ ] Return a `WorkspaceEdit` with `TextEdit` entries for each
      location, replacing the old name with the new name.
- [ ] Validate: the new name must be a valid identifier.
- [ ] Validate: the new name must not conflict with an existing
      name in any scope where the symbol is used.
- [ ] Test: rename a function used across files, verify all
      references updated.

---

## Phase 9: Incremental Analysis

**Goal:** Only re-analyze what changed, not the whole project.

Only pursue if the slow tier's full recompilation becomes a
bottleneck (>500ms for typical projects).

- [ ] Track file dependency graph from `use` declarations.
- [ ] On file change: re-analyze that file, then re-analyze files
      that import it (transitively).
- [ ] Cache intermediate results (parse tree, resolved names,
      typed AST) per file. Invalidate only affected caches.

---

## Phase 10: Background Analysis + Cancellation

**Goal:** Analysis runs off the main thread. Main thread handles
JSON-RPC I/O without blocking.

Only pursue if synchronous analysis causes visible UI lag.

- [ ] Main thread: read JSON-RPC, dispatch requests, write
      responses.
- [ ] Worker thread: runs slow-tier compilation, produces results.
- [ ] On new didChange: cancel in-flight analysis, restart after
      debounce timer (200ms).
- [ ] Fast-tier parse runs synchronously on the main thread
      (it's fast enough). Only the slow tier moves to the worker.