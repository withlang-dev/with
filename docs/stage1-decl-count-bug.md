# Stage1 Declaration-Count Sensitivity Bug

Status: root-caused to `decl_source_paths` corruption, fix pending.
Date: 2026-04-29
Updated: 2026-04-29 (session 2)

## Symptom

Stage1 (and stage2, and any compiler built from recent commits) produces
bogus **"unknown type X"** errors at unrelated source locations when the
top-level declaration count in certain compiler source modules changes by
even one. The bogus type name varies depending on which module is touched:

| Module touched | Bogus type in error |
|---|---|
| src/CImport.w | "Parser", "Sema" |
| src/Token.w | "TokenList" |
| src/Parser.w | "CK_STRUCT" (or similar) |

The error message includes `did you mean 'X'?` where the suggestion is
the *exact same name* as the "unknown" type — the name is in scope, but
the primary lookup returns wrong results while the suggestion system
(which does a text search) finds the correct match.

## Reproducer

Starting from a clean build at commit 7fd7d0f (or any commit after the
introduction point):

```bash
# Add one trivial top-level function to Token.w
echo -e '\nfn dummy_test_end_Token(x: i32) -> i32:\n    x' >> src/Token.w

# Build (or just check — the error appears in sema, not codegen)
./out/bin/with-stage2 check src/main.w
# → error: unknown type 'TokenList' ... did you mean 'TokenList'?
```

**Position within the file matters**: adding the dummy at the TOP of
Token.w does NOT trigger the bug; adding at the END does. This suggests
the stale index is off-by-one relative to the end of a module's
declaration range.

## Bisect Result

The bug was introduced by commit **365e5ab** (p7.13: §15.8 closure
capture conflict via iterator). Confirmed by testing the parent commit
f2e202c, which passes the Token.w reproducer cleanly.

365e5ab adds ~129 lines, mostly in SemaCheck.w, plus new AstPool fields
(`iter_of_self_fn_nodes: Vec[i32]`, `iter_of_self_fn_set: HashMap[i32, i32]`)
and `@[iter_of_self]` attribute handling in Parser.w.

## Findings (Session 2)

### Module graph is identical between runs

Module IDs, paths, import_start, import_count, and decl_count all match
between working (no dummy) and broken (with dummy) runs — except Token.w's
decl_count differs by 1 (14 vs 15). The prelude DFS traversal produces
identical results: 9 globally-visible std modules in both cases. Import
edges are byte-for-byte identical.

**The prelude-DFS-terminates-early theory from session 1 is ruled out.**

### Working run has 3 Sema passes; broken run has 2

Working case: pre_sema, transform_sema, main_sema — all succeed.
Broken case: pre_sema succeeds, transform_sema fails with "unknown type
TokenList", main_sema never runs.

Pre_sema and transform_sema register TokenList identically in both runs
(`record_named_type`: idx=37 sym=161 name=TokenList tid=58 path=src/Token.w).

### Error span is misattributed

The error points to `src/Diagnostic.w:146:1`, but:
- Diagnostic.w is exactly 146 lines; line 146 is empty/past-EOF.
- Diagnostic.w never references TokenList (it uses Span, Source, DiagnosticRender).
- Diagnostic.w does not import Token.w.

The 8 failed lookups are attributed to "current_module=src/Diagnostic.w"
because `update_module_context(di)` reads `decl_source_paths[di]` and
gets the wrong path.

### `lookup_named_type_visible` is never called in the working run

In the working run, `lookup_named_type_visible("TokenList")` is never
called from any module — not even once. In the broken run, it's called
8 times from "src/Diagnostic.w" (which is itself wrong, see above).

This means the working run resolves TokenList via `type_decl_tids`
(a cache mapping decl node → type ID, populated during Pass 1 of
`collect_declarations`). The broken run misses this cache and falls
through to the name-based lookup, which then fails the visibility check
because Token.w is not reachable from (the incorrectly attributed)
Diagnostic.w.

### `module_is_visible_from_current` is correct

Token.w is genuinely not visible from Diagnostic.w (Diagnostic.w imports
only Span, Source, DiagnosticRender — none of which transitively import
Token.w). The visibility check is doing its job correctly. The bug is
that the wrong module path is being checked.

## Root Cause: `decl_source_paths` Corruption

This is a `decl_source_paths` corruption bug. The per-declaration
module-path vector goes out of sync with the AST's declaration list
after the comptime transform.

The mechanism:
1. `process_imports_frontend` builds `decl_source_paths` aligned to
   the merged AST pool's declaration list.
2. The comptime transform (ComptimeTransform.w) creates a transform
   pool, potentially rewriting or reordering declarations.
3. The transform_sema receives `decl_source_paths` from pre_sema.
4. When transform_sema walks declarations via `update_decl_source_context(di)`,
   `decl_source_paths[di]` returns the wrong module path for some
   declarations — the indices are shifted.
5. `current_module_path` is set to the wrong module, causing visibility
   checks to fail for types that are perfectly valid.

Whatever 365e5ab added that touches AST declaration shape, indexing, or
post-transform pool structure is the culprit. The new AstPool fields or
the `@[iter_of_self]` attribute handling may change declaration count or
ordering in a way that desynchronizes `decl_source_paths`.

## Verification Path for Next Session

1. **Read the 365e5ab diff carefully.** Look for:
   - Anything that changes declaration count or ordering in the
     post-transform pool
   - Anything that consumes `decl_source_paths` with an index that
     could go stale
   - Anything that adds declarations during transform without updating
     `decl_source_paths`

2. **Add assertion.** At the top of each sema declaration loop iteration:
   `assert(decl_source_paths.len() == ast.decl_count())`. If lengths
   diverge, the rebuild is missing. If lengths match, the indexing logic
   is wrong.

3. **Trace `decl_source_paths` around Token.w boundary.** In both runs,
   dump `(di, decl_source_paths[di], ast.kind(ast.get_decl(di)))` for
   declarations near the Token.w → Diagnostic.w boundary. The shift
   should be visible as a one-off alignment error.

4. **Test the 5 pre-existing test failures**: `behav_comptime_*_freeze`,
   `behav_derive_clone`, `behav_large_int_literals`. If these share
   root cause, fixing this bug fixes them too.

## False Trails Ruled Out

- **Prelude DFS terminating early**: module graph is byte-identical
  between runs. Ruled out (session 2).
- **Module-ID instability**: module IDs are stable across runs. Same
  paths get same IDs regardless of Token.w's decl_count. Ruled out.
- **Type registration difference**: TokenList is registered identically
  (idx=37, sym=161, tid=58, path=src/Token.w) in both runs. Ruled out.
- **`ci_strip_trailing_break_ir` method shape**: original false trail
  from session 1. The real variable is declaration count, not method
  body shape.

## Affected vs Unaffected Modules

Modules that trigger the bug when a function is added at the end:
- `src/CImport.w`
- `src/Parser.w`
- `src/Token.w`
- `src/Lexer.w`
- `src/InternPool.w`
- `src/Source.w`

The affected set appears to be modules parsed early in the import chain
(prelude-transitive imports). The exact boundary needs re-verification.

## Blocked Work

- **P10.x `&mut` migration sweep** — converting remaining free functions
  to methods changes declaration counts, which triggers this bug.
  Currently at p10.11b (CImport.w pool methods).
- **§15.8 ephemeral-iterator typing** (p7.13) — the commit implementing
  it (365e5ab) introduced this bug.
- **P11 second seed reinstall** — blocked on completing P10.x.
- **P12 lockdown** — blocked on P11.
