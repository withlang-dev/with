# P10 Structural `&mut` Sites Audit

Comprehensive audit of all `&mut` code sites (lines containing `&mut`)
remaining after p10.12–p10.22. Started at 221 sites; reduced to 138 via
p10.17–p10.22.

## Codebase-Wide Summary

| File | Sites | Category |
|------|-------|----------|
| src/CImport.w | 66 | multi-pool params, genuine coercions, free fns |
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
| **Total** | **138** | |

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

## CImport.w 66-site Audit

After p10.22 coercion downgrades. 54 in function declarations, 11 in call
sites, 1 comment.

**Function declarations (54):** All are methods on pool types (CiStmtPool,
CiExprPool, CiGotoCfgContext, CiStackEmitContext) or free utility functions.
Every `&mut Pool` param was verified by the p10.18 build-driven oracle as
genuinely needing mutability. The remaining pattern is multi-pool threading:
methods that operate on one pool (`mut self`) while passing another pool
(`&mut OtherPool`) to sub-calls. No further read-only downgrades are available.

**Call-site coercions (11):** `&mut exprs`/`&mut types` passed to methods
that genuinely mutate them (6 sites), `&mut self` to mutating methods (3),
`&mut cases`/`&mut hoisted_decls` to functions that push to Vec/struct (2).

**Comment (1):** Line 11283 describes `&mut self` in a comment.

**Free functions (3):** `ci_collect_var_decls` (pushes to `&mut Vec`),
`ci_goto_switch_record_case` (writes to `&mut CiGotoSwitchCase`),
`ci_native_goto_collect_leaf_ids` (pushes to `&mut Vec`). All genuine
mutations. Method extraction possible but marginal gain.

**p10.22 eliminated 18 call-site coercions** where `&mut self` was passed to
free functions that only needed `&Pool`. Changed to `&self` at call sites.

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
| 6 | CImport.w call-site coercion downgrades | 16 lines | **DONE** (p10.22) |
| — | E,G,H,I: exempt or deferred to P12 | ~30 | — |

## P4 Status

### P4.1 Verification (2026-04-30)

**Trait definition:** `lib/std/traits.w:58-59` defines
`fn next(mut self: Self) -> Option[T]`. Correct shape. ✓

**Check 1 — For-loop desugaring calling convention:**

`src/MirLower.w:2582` (`lower_for`) has hardcoded paths for:
- Range literals (NK_RANGE) → `lower_for_range`
- Range variables (TY_RANGE) → `lower_for_range_var`
- Slice/Array (TY_SLICE, TY_ARRAY) → `lower_for_slice`
- Vec (name == "Vec") → `lower_for_vec`
- `vec.iter()` (method name == "iter" on Vec receiver) → `lower_for_vec`

Generic iterator fallback (line 2630-2675): calls `self.mark_unsupported()`
at line 2632. AST codegen has been removed — functions that hit this path
get a hard error: "MIR lowering failed for function ... AST codegen was
removed, so this function cannot be compiled."

**`for x in custom_iter` is a compile-time error for any non-builtin type.**

VecIter.next() (line 3921-3922): dispatched as `MIR_INTRINSIC_VECITER_NEXT`,
entirely compiler-intrinsic. CodegenDispatch.w:3595 takes receiver as pointer
via `mir_intrinsic_recv_ptr` and mutates `idx` field in place (line 3644:
`wl_build_store(self.builder, next_idx, idx_ptr)`). This is ABI-compatible
with `mut self: Self` (struct self is passed as pointer, mutations visible
to caller).

Sema check_for (`src/SemaCheck.w:2554`) delegates to `infer_for_element_type`
(line 7666), which is hardcoded for Range, Array, Slice, Vec — no trait
dispatch. No `&mut` shape anywhere in the for-loop pipeline.

**Check 2 — Iterator impl enumeration:**

Types implementing `Iter[T]` in stdlib: **zero**. No `impl Iter[T] for X`
blocks exist anywhere in `lib/std/`. `VecIter[T]` (defined in
`lib/std/collections.w:52`) has no source-level `next()` method — its
`next()` is a compiler intrinsic.

`IntoIter[T]` (traits.w:62-63) returns `VecIter[T]`, not a generic
iterator. Only impl is `Vec[T]` (traits.w:69-71).

No range iterators, string char/byte iterators, or HashMap iterators exist
as types with `next()`. All for-loop iteration for these types goes through
hardcoded MIR lowering paths, not trait dispatch.

**Check 3 — Behavioral test:**

Test: `test/behavior/behav_iter_mut_self.w` — defines `CountUp` struct
implementing `impl Iter[i32] for CountUp` with `fn next(mut self: Self)`.

- **Manual while-loop** calling `iter.next()`: **passes.** Output: `10`. ✓
  The `mut self: Self` shape works — `self.current` is mutated and visible
  across successive calls.
- **For-loop** (`for x in iter`): **compile error.** ✗
  ```
  error: MIR lowering failed for function 'main' in
  test/behavior/behav_iter_mut_self.w; AST codegen was removed,
  so this function cannot be compiled
  ```
  MIR lowering hits the generic iterator fallback at MirLower.w:2632
  (`mark_unsupported()`), which used to fall back to AST codegen. AST
  codegen has been removed, so this is now a hard error.

**Conclusion — COMPLETE (2026-04-30):**

P4.1 is **complete**:
- ✓ Trait definition has correct `mut self: Self` shape
- ✓ `VecIter.next()` intrinsic is ABI-compatible with `mut self: Self`
- ✓ Manual `.next()` calls on custom iterators work correctly
- ✓ `for x in custom_iter` works — generic iterator protocol implemented
- ✓ `VecIter[T]` formally implements `Iter[T]` via trait dispatch

**Fixes applied:**
- `src/MirLower.w`: generic iterator fallback resolves `next` callee via
  `resolve_method_callee_sym`, looks up return type from method signature,
  uses `success_variant_index()` for discriminant, extracts payload via
  downcast+field projection. `mark_unsupported()` only fires if method
  resolution fails.
- `src/SemaCheck.w`: `infer_for_element_type` has trait-based fallback that
  looks up `next()` method return type and extracts T from Option[T].
- `lib/std/collections.w`: `impl[T] Iter[T] for VecIter[T]` added.
- `src/SemaDecl.w`: overlap detection fixed to consult `blanket_target_base_syms`
  for targeted blankets like `impl[T] Trait for SpecificType[T]`.

**Remaining stdlib Iter impls — structural blockers:**

1. **Range**: `TY_RANGE` is a compiler primitive, not a named struct. Can't
   write `impl Iter for Range` — there's no type to impl on. For-loop
   iteration is handled by efficient counter-based MIR lowering. Adding Iter
   support requires either making Range a named type or adding compiler-level
   trait impl support for primitives.

2. **String char/byte iteration**: No char type exists. `byte_at(i)` intrinsic
   exists but no `str.len()` MIR intrinsic. A `ByteIter` type would need new
   runtime infrastructure (string length, byte access by index). Character
   iteration would additionally require UTF-8 decoding.

3. **HashMap**: Opaque pointer type (`ptr: *const i8`). `keys()` copies all
   keys to a Vec. No cursor-based iteration support. Would need new runtime
   functions for hash table traversal.

### MIR Generic Iterator Protocol — Design

**What does `mark_unsupported()` do?** Sets `self.body.lowering_failed = 1`
(MirLower.w:1404). This is just a flag. The MIR generation after line 2632
executes fully — blocks, terminators, operands are all created. But
CodegenDispatch.w:49 checks `body.lowering_failed == 0` and rejects the
whole function if the flag is set. So the MIR IS generated but never consumed.

**What MIR does the stub generate?** (lines 2633-2675):
1. Lower iter_expr, materialize into iter_place (line 2633-2634)
2. Infer elem_ty via `infer_for_element_type` (line 2635)
3. Create header_bb, body_bb, exit_bb (lines 2637-2639)
4. In header: push OK_COPY of iter_place as arg, emit TK_CALL with
   `unit_operand()` as callee, store result in next_local (lines 2645-2651)
5. After call: extract discriminant, switch disc==1 → body, else exit
6. In body: copy next_place to item_place, bind element, lower body, goto header

**Three bugs in the stub:**

1. **No callee resolution.** Line 2651 uses `unit_operand()` as the
   callee — codegen doesn't know what function to call. Normal method
   calls use `resolve_method_callee_sym` to get a fn symbol, or
   `set_call_intrinsic` for intrinsics. The generic path does neither.
   **Fix:** resolve `next` method on the iterator type via
   `resolve_method_callee_sym` or the GENERIC_CALL intrinsic path.

2. **Wrong result type.** Line 2648 allocates `next_local` with type
   `iter_ty` (the iterator type itself). But `next()` returns
   `Option[T]`, not the iterator. **Fix:** look up the return type of
   `next()` or construct `Option[elem_ty]`.

3. **Hardcoded element type inference.** `infer_for_element_type`
   (SemaCheck.w:7666-7681) only handles Range/Array/Slice/Vec, falling
   back to `ty_i32`. For custom iterators, it must look up the Iter[T]
   trait impl and extract T. **Fix:** add trait lookup fallback.

**What's the fix shape?** Medium fix. Three changes:
- `infer_for_element_type`: add fallback that looks up Iter[T] impl for
  the iterator type and extracts T from the generic args.
- Generic iterator path in `lower_for`: resolve `next` callee via
  GENERIC_CALL intrinsic (same path used for unresolved method calls),
  fix result type to match next()'s return type.
- Remove `mark_unsupported()` call.

The GENERIC_CALL path (lines 4050-4090) handles exactly this case: method
calls where the callee can't be statically resolved to a fn symbol. It
passes the method sym + receiver + args to codegen, which dispatches via
the AST node's sema information. This is the same path used for disc enum
methods, Option methods, and concrete/generic struct methods.

### P4.2 — IndexPlace Implementation

**Status:** complete (v1 scope).

#### Spec references

- **§2.4**: IndexPlace is a syntax trait. `P[i]` is a place projection only
  when P's type implements IndexPlace. The compiler operates on the indexed
  slot directly — no get/set value copies.
- **§6.2**: Nested mutation (`xs[i].field = v`, `xs[i].method()`) operates on
  storage directly. Non-Copy elements can't be moved out and back.
- **§6.3**: Single-evaluation rule. `xs[f()] += g()` evaluates f() and g()
  exactly once. Read and write happen as place operations on the same
  projection.
- **§19.7**: v1 may restrict IndexPlace to stdlib types. User-defined impls
  are a follow-up design question.
- **§20.3**: v1 hardcodes for Vec, Array, similar. The compiler's place-
  projection machinery handles indexed projections alongside field projections.

#### v1 scope: stdlib-only, hardcoded recognition

Per §19.7 and §20.3, v1 restricts IndexPlace to stdlib types recognized by
the compiler: Vec, Array, Slice. These already have hardcoded fast paths in
both `check_index` (sema) and `lower_index` (MIR). The recognition mechanism
is existing name/type-kind matching — no attribute or whitelist needed because
the types are compiler-built-in.

Formal `impl IndexPlace` blocks are added to `lib/std/traits.w` so the type
system records the relationship. The compiler does NOT use trait lookup for
v1 dispatch — the hardcoded type checks are the dispatch mechanism.

#### Existing behavior (already correct for v1)

Testing confirms that the compiler's place-projection machinery already
handles IndexPlace semantics for Vec/Array/Slice:

- `xs[i] = value` — stores directly via PK_INDEX place projection ✓
- `xs[i].field = value` — chains PK_INDEX + PK_FIELD projections ✓
- `xs[i].method()` with `mut self: Self` — mutates element in place ✓
- `xs[i] += value` — reads/writes through place projection ✓

Codegen (CodegenDispatch.w:615-672) resolves PK_INDEX as:
- Array types → direct GEP
- Pointer types → load ptr, GEP
- Vec/Slice/str → load data ptr (field 0), GEP to element

This IS the place-projection behavior §2.4 specifies.

#### Bug: §6.3 single-evaluation rule violated

`xs[f()] += g()` calls f() **twice**. The parser desugars compound assignment:
```
xs[f()] += g()  →  NK_ASSIGN(target=xs[f()], value=NK_BINARY(ADD, xs[f()], g()))
```
Both `xs[f()]` in the ASSIGN and BINARY are the SAME AST node ID, but MIR
lowering evaluates it twice: once via `lower_expr_place(target)` and once
via `lower_expr(binary.d1)`.

**Fix in `lower_assign` (MirLower.w:2167):** Detect compound assignment on
indexed target (rhs is NK_BINARY with d1 == place_expr, and place_expr is
NK_INDEX). Pre-evaluate the index expression to a temp local, build the
index place using the temp, read the current value, evaluate only the
increment expression (binary.d2), apply the operation, write back.

Lowering shape for `xs[f()] += g()`:
```mir
_idx = f()                          // evaluate index once
_place = xs[_idx]                   // build index place with temp
_cur = copy _place                  // read current value
_inc = g()                          // evaluate increment once
_new = _cur + _inc                  // compute result
_place = _new                       // write back
```

#### Four implementation pieces

1. **p10.23 — §6.3 compound assignment single-evaluation fix** ✓
   (MirLower.w `lower_assign`): detect compound assignment (rhs is NK_BINARY
   with d1 == place_expr), lower as single read-modify-write through the
   place. Verified: `xs[f()] += g()` evaluates f() and g() exactly once.

2. **p10.24 — Formal IndexPlace impls** — blocked by generic type erasure.
   MIR validation rejects `self[index] = value` for unresolved T in generic
   impl bodies. The compiler's hardcoded PK_INDEX place projections provide
   correct IndexPlace semantics for Vec/Array/Slice. Formal impls can be
   added when the compiler supports generic trait method bodies. Comment
   added to `lib/std/traits.w` documenting the limitation.

3. **p10.25 — §15.11 diagnostic** ✓ — already implemented in check_assign
   (SemaCheck.w:2500-2504). When classify_place returns PK_NotPlace for an
   NK_INDEX target, emits "type does not support index assignment (no
   IndexPlace impl) (§15.11)" warning.

4. **p10.26 — §18 behavioral tests** ✓ — `test/behavior/behav_index_place.w`
   covers: direct assignment, nested field mutation, mutating method through
   index, compound assignment, single-evaluation rule. Array coverage in
   `test/behavior/behav_index_place_array.w`.

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
