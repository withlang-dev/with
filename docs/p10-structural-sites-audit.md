# P10 Structural `&mut` Sites Audit

Comprehensive audit of all `&mut` code sites (lines containing `&mut`)
remaining after p10.12–p10.21. Started at 221 sites; reduced to 154 via
p10.17–p10.21. Note: ComptimeTransform.w diag-threading (p10.21) traded 13
`diags: &mut DiagnosticList` params for 5 `&mut sema.diags` call sites — net
line count went up but 13 threaded parameters were eliminated.

## Codebase-Wide Summary

| File | Sites | Category |
|------|-------|----------|
| src/CImport.w | 82 | multi-pool params, coercions, free fns |
| src/ComptimeEval.w | 5 | entry-point free fns (4 sigs + 1 call site) |
| src/ComptimeTransform.w | 29 | multi-pool params + `&mut sema.diags` call sites |
| src/compiler/Frontend.w | 6 | multi-pool params (Sema, HashMap, Vec) |
| src/compiler/Compilation.w | 1 | `&mut sema` passed to seed function |
| src/compiler/Link.w | 1 | `&mut out as *mut u8` (raw pointer cast) |
| src/SemaCheck.w | 16 | strings/comments, code, borrow checker comments |
| src/render.w | 2 | string output `"&mut "` |
| src/SemaDiag.w | 1 | string output `"&mut "` |
| src/CiPrint.w | 1 | string output `"&mut "` / `"&"` |
| src/CiIR.w | 1 | comment: `d1 = is_mut (0 = &, 1 = &mut)` |
| src/CCodegen.w | 1 | comment: separate `&mut` accumulators |
| src/CodegenDispatch.w | 1 | comment: receiver is &mut Vec[T] |
| src/MirLower.w | 1 | comment: indexing through &mut Vec[T] |
| src/Sema.w | 1 | comment: &mut HashMap params |
| src/main.w | 1 | help text string |
| src/main_emit_temp.w | 1 | help text string |
| src/bootstrap_main.w | 1 | help text string |
| lib/std/traits.w | 1 | `multi_index_set(self: &mut Self, ...)` (deprecated) |
| lib/std/cfg/stackify.w | 1 | comment |
| **Total** | **154** | |

## Actionable Sites by Category

### A. Diag-threading: ComptimeEval.w (44 sites)

Every method on `ComptimeEvaluator` takes `diags: &mut DiagnosticList` as a
separate parameter. The struct (line 28) has no `diags` field.

**Conversion:** Add `diags: DiagnosticList` field to `ComptimeEvaluator`.
Change all 40 methods from `self: ComptimeEvaluator, diags: &mut DiagnosticList`
to `mut self: ComptimeEvaluator`. Remove the `diags` parameter. Replace
`diags.emit(...)` with `self.diags.emit(...)`. Update the 4 entry-point
functions (lines 143, 154, 165, 168) to pass `diags` into the struct at
construction.

Caller in SemaCheck.w (line 6394) passes `&mut self.diags` — will need updating
to pass diags into the evaluator constructor instead.

**Eliminates:** 44 `&mut` sites (all of them in this file).

### B. Read-only `&mut` params: ComptimeTransform.w (8 params)

These parameters are `&mut` but never mutated (verified leaf-only, no transitive
mutation):

| Line | Function | Param → Downgrade |
|------|----------|-------------------|
| 10 | ct_emit_error | `sema: &mut Sema` → `sema: &Sema` |
| 181 | ct_build_type_expr | `sema: &mut Sema` → `sema: &Sema` |
| 273 | ct_build_collection_ctor | `sema: &mut Sema` → `sema: &Sema` |
| 510 | ct_sync_sema_ast | `pool: &mut AstPool` → `pool: &AstPool` |
| 1192 | ct_decl_source_path | `sema: &mut Sema` → `sema: &Sema` |
| 1197 | ct_decl_source_file_id | `sema: &mut Sema` → `sema: &Sema` |
| 1202 | ct_decl_is_c_import | `sema: &mut Sema` → `sema: &Sema` |
| 1236 | comptime_transform_module | `intern: &mut InternPool` → needs verification |

**Eliminates:** 7–8 `&mut` sites. Also eliminates `&mut` at call sites that
pass these params.

### C. CImport.w method params: `types: &mut CiTypePool` (leaf-only)

Many CiExprPool and CiStmtPool methods take `types: &mut CiTypePool` but only
call read-only CiTypePool methods (`kind()`, `name()`). However, some of these
pass `types` transitively to functions like `lower_implicit_cast` which DOES
mutate types (via `type_from_translated_text`).

**Safe to downgrade** (verified no transitive mutation of types):
- `prepare_stmt_condition_ir` (line 4427)
- `render_value_expr_ir` (line 4444)
- `stack_emit_tree` (line 10595) — already takes `types: &CiTypePool`

For `native_goto_emit_cfg` (line 10707) — already uses `types: &CiTypePool`.

The remaining `types: &mut CiTypePool` parameters are transitively needed because
call chains eventually reach `type_from_translated_text` or `type_from_libclang`.

**Eliminates:** 2–3 params.

### D. CImport.w call-site coercions (27 sites)

Patterns like `&mut self`, `&mut exprs`, `&mut types` passed to free functions:

- `ci_print_compact_stmt(&mut self, ...)` — 2 sites (lines 4453-4454)
- `ci_print_expr(&mut self, types, ...)` — 6 sites
- `ci_expr_is_zero_int_lit(&mut self, ...)` — 2 sites
- `ci_expr_is_string_lit(&mut self, ...)` — 1 site
- `ci_index_base_is_raw_pointer(..., &mut self, types)` — 1 site
- `ci_index_expr_element_type_is_small_int(&mut self, ...)` — 2 sites
- `ci_expr_tree_contains_small_int(&mut self, ...)` — 3 sites
- `stmts.method(session, cursor, &mut exprs, &mut types, ...)` — 7 sites
- `ci_stmt_collect_flat_ids(&mut self, ...)` — 1 site
- `ctx.method(..., &mut self, exprs, types, ...)` — 2 sites

These coercions are needed because the callee free functions take `&mut Pool`.
Some callees (`ci_print_expr`, `ci_expr_is_zero_int_lit`, etc.) never mutate
their pool argument. Converting those free functions to methods or downgrading
their params to `&` would eliminate these coercion sites.

### E. CImport.w free function declarations (5 functions)

| Line | Function | Param |
|------|----------|-------|
| 9751 | ci_collect_var_decls | `decls: &mut Vec[CiHoistedVarDecl]` |
| 9964 | ci_goto_cfg_push_target | `stack: &mut Vec[i32]` |
| 9967 | ci_goto_cfg_pop_target | `stack: &mut Vec[i32]` |
| 10207 | ci_goto_switch_record_case | `cases: &mut CiGotoSwitchCase` |
| 10627 | ci_native_goto_collect_leaf_ids | `out: &mut Vec[i32]` |

These take `&mut Vec` or `&mut` struct — genuine mutations (push/pop/set).
These are utility free functions, not methods on a pool. They could become
methods on their respective types (e.g., `Vec.push_target()`) but the gain is
minimal — they're not part of the pool method pattern.

### F. CImport.w field projections (14 sites)

All are `ci_goto_cfg_push_target(&mut self.break_targets, ...)` and
`ci_goto_cfg_pop_target(&mut self.continue_targets)` inside CiGotoCfgContext
methods. These pass `&mut self.field` to free functions that mutate Vec fields.

If `ci_goto_cfg_push_target`/`ci_goto_cfg_pop_target` were converted to methods
on CiGotoCfgContext (using `mut self`), these would become `self.push_target()`
calls, eliminating the `&mut self.field` pattern. But the push/pop operate on
different fields (break_targets vs continue_targets), so they'd need separate
methods or a discriminator.

### G. compiler/Frontend.w (8 sites)

| Line | Pattern |
|------|---------|
| 152 | `fn Zcu.seed_sema_module_graph_frontend(self: Zcu, sema: &mut Sema)` |
| 391 | `zcu.seed_sema_module_graph_frontend(&mut sema)` |
| 944 | `self.seed_sema_module_graph_frontend(&mut pre_sema)` |
| 950 | `comptime_transform_module(pool, &mut pre_sema, &mut self.pool)` |
| 976 | `self.seed_sema_module_graph_frontend(&mut sema)` |
| 1362 | `fn ... seen_paths: &mut HashMap[str, i32], out_paths: &mut Vec[str]` |
| 1380 | `fn ... out_decls: &mut Vec[i32], out_paths: &mut Vec[str], out_file_ids: &mut Vec[i32]` |

All genuinely mutating (populating Sema module graph, building output vectors).
Line 34 (`&mut out as *mut u8`) in Link.w is a raw pointer cast — permanent
exempt pattern (becomes `&raw mut out` at P12).

### H. Strings, comments, diagnostics (22 sites)

These are string literals or comments containing `"&mut"` — not code patterns.
They stay as-is (the text is describing syntax, not using it).

### I. lib/std/traits.w:141 (1 site)

`fn multi_index_set(self: &mut Self, ...)` — deprecated alias, removed at P12.

## Diag-Threading Pilot: ComptimeEval.w

### Design Decision

**Natural receiver:** `ComptimeEvaluator` — already `self` on all 39
diags-taking methods. Holds sema, ast, pool, eval state (slots/scopes/labels),
step counter, error state. Currently has no `diags` field.

**Diags usage:** `diags.emit()` is called in exactly ONE place — line 190 in
`fail()`. No method reads from `diags`. The evaluator is a pure diagnostic
producer. At most one diagnostic is emitted per evaluation (because `fail()`
checks `self.had_error == 0` before emitting).

**Pattern:** Store the pending diagnostic in the evaluator itself. Add
`has_pending_diag: i32` and `pending_diag: Diagnostic` fields. In `fail()`,
set these fields instead of calling `diags.emit()`. The 4 entry-point free
functions emit `evaluator.pending_diag` to the caller's `&mut DiagnosticList`
after eval completes. No raw pointers, no Vec handle divergence.

**Scope:** All 39 methods converted at once. The call graph is a tight mesh:
`eval_expr` dispatches to all eval methods, and all eval methods call back to
`eval_expr` for sub-expression evaluation. A partial 5-10 function pilot would
create fragile boundaries (some call sites pass `diags`, some don't; `eval_expr`
would need mixed dispatch). The conversion is purely mechanical — same transform
applied 39 times — so all-at-once is lower-risk than a partial boundary.

**Two-commit approach:**
1. Add `pending_diag` fields to struct, change `fail()` to store instead of
   emit, update entry-point copy-back. All signatures unchanged. Build+fixpoint
   verifies the pattern.
2. Mechanically remove `diags: &mut DiagnosticList` from all 39 method sigs
   and all internal call sites. Build+fixpoint verifies the payoff.

**Eliminates:** 39 `&mut` sites (39 method-sig params removed). 5 remain in
entry-point free functions (4 sigs + 1 call site) — genuine external API.

**Result:** Completed in single build+fixpoint cycle. Pattern generalized
cleanly: all 39 methods converted with zero surprises. The tight call graph
that made partial piloting risky also made all-at-once trivial — every method
got the same transform.

## Diag-Threading: ComptimeTransform.w

### Design Decision

**No natural receiver type.** Unlike ComptimeEval.w, all 13 diags-taking
functions are free functions with signature `ct_*(source_ast, pool, sema,
intern, diags, node)`. There is no `ComptimeTransformer` struct.

**diags is already `sema.diags`.** The entry point `comptime_transform_module`
creates `transform_sema = Sema.init(transform_pool, sema.diags, out)` and
passes `&mut transform_sema.diags` alongside `&mut transform_sema` to
`ct_transform_decl`. The `diags` parameter is redundant — every function
already has `sema: &mut Sema` which owns `sema.diags`.

**Multiple emit points.** `ct_emit_error` is called from 6 sites. Plus
`comptime_*_eval_*` functions receive `diags` directly (4 sites via
`comptime_force_eval_expr` / `comptime_try_eval_expr_result`).

**diags is read.** Line 891: `diags.count()` checks whether comptime eval
added a diagnostic. This becomes `sema.diags.count()`.

**Pattern:** Drop `diags: &mut DiagnosticList` from all 13 function sigs.
Use `sema.diags` everywhere: `sema.diags.emit(...)` in `ct_emit_error`,
`&mut sema.diags` when calling comptime entry-point functions,
`sema.diags.count()` for the read. Upgrade `ct_emit_error` from
`sema: &Sema` to `sema: &mut Sema` (needed for `sema.diags.emit()`; all
callers already hold `&mut Sema`). At the entry point, replace
`ct_transform_decl(..., &mut transform_sema.diags, ...)` with just
`ct_transform_decl(..., ...)`.

**Eliminates:** 13 `diags: &mut DiagnosticList` params + 1 call-site coercion
(`&mut transform_sema.diags`). `ct_emit_error` trades `sema: &Sema, diags:
&mut DiagnosticList` for `sema: &mut Sema` (1 `&mut` replaces 1 `&mut`).
Net: 13 `&mut` sites eliminated.

## Conversion Plan

| Priority | Category | Sites | Status |
|----------|----------|-------|--------|
| 1 | B: ComptimeTransform.w read-only downgrades | 12 | **DONE** (p10.17) |
| 2 | C: CImport.w read-only pool params | 55 | **DONE** (p10.18) |
| 3 | A: ComptimeEval.w diag-threading | 39 | **DONE** (p10.19) |
| 4 | F: CImport.w push/pop → CiGotoCfgContext methods | 16 | **DONE** (p10.20) |
| 5 | ComptimeTransform.w diag → sema.diags | 13 params | **DONE** (p10.21) |
| — | E,G,H,I: exempt or deferred to P12 | ~30 | — |

## Permanent Exemptions

1. **String/comment mentions** of `&mut` — not code. (22 sites)
2. **`&mut out as *mut u8`** (Link.w:34) — becomes `&raw mut out` at P12.
3. **`multi_index_set(self: &mut Self)`** (traits.w:141) — removed at P12.
4. **SemaCheck.w lockdown error messages** (lines 137-141, 2164-2167) — text
   of diagnostic messages about `&mut`.
5. **SemaCheck.w borrow checker comments** (lines 6806, 7087, 7099, etc.) —
   describing borrow semantics.
6. **Multi-pool threading** in CImport.w method signatures where pools are
   transitively mutated — these are the genuine `&mut Pool` pattern that
   remains until the pools are consolidated or the methods restructured.
7. **compiler/Frontend.w** `sema: &mut Sema` and output `&mut Vec` params —
   top-level pipeline plumbing, genuine mutations.
8. **Free utility functions** (`ci_collect_var_decls`, `ci_goto_cfg_push/pop_target`,
   etc.) — operate on `&mut Vec` fields, genuine mutations.
