# §20.0 API Inventory — Remaining `&mut` Sites

Written inventory per docs/mut.md Rev 8 §20.0. Every remaining `&mut` site
in `src/` and `lib/std/` is listed with its old pattern, target shape, and
planned disposition.

**Summary counts** (at commit f40dcc9):

| Category | Sites | Target |
|---|---|---|
| `&mut Pool` free-fn params (CImport.w) | 67 | `mut self: Pool` method receivers |
| `&mut AstPool/Sema/InternPool` free-fn params (ComptimeTransform.w) | 53 | `mut self` method or owned-value param |
| `&mut DiagnosticList` params (ComptimeEval.w) | 5 | Owned-value param or `mut self` method |
| `&mut self` call-site expressions | 9 | Remove when receiver becomes `mut self` method |
| Comment/string-literal references to `&mut` | 19 | Update text at P12 lockdown |
| Render/diagnostic output of `&mut T` types | 4 | Keep until UOP_MUT_REF deleted at P12 |
| `MultiIndex.multi_index_set(self: &mut Self, ...)` | 1 | Delete at P12 (deprecated alias) |

Total: 129 sites in src/, 1 site in lib/std/. Runtime (rt/) and stdlib
(lib/std/ minus traits.w) are clean.

---

## 1. CImport.w — 67 sites

### 1a. `&mut CiExprPool` parameters (20 sites)

**Old pattern:** `fn CiStmtPool.method(mut self: CiStmtPool, ..., exprs: &mut CiExprPool, ...) -> T`

**Target shape:** Two options, depending on call pattern:

- If the method only passes `exprs` through to sub-calls: **owned-value parameter**
  `fn CiStmtPool.method(mut self: CiStmtPool, ..., exprs: CiExprPool, ...) -> T`
  Works because CiExprPool uses pointer-indirected interior mutability (like InternPool).

- If the method takes `&mut self` at a call site (e.g., `stmts.method(..., &mut exprs, ...)`):
  Convert the call-site expression from `&mut exprs` to `exprs` (by-value, interior mut).

**Conversion pattern:** Same as p10.18 (read-only downgrade) but for mutating access.
CiExprPool, CiStmtPool, CiTypePool all use Vec-backed interior state through
pointer indirection. The `&mut` is unnecessary — the mutation flows through
the internal pointer regardless.

**Disposition:** Convert in P10 finish. Mechanical: `&mut CiExprPool` → `CiExprPool`
in parameter types, `&mut exprs` → `exprs` at call sites.

**Risk:** Low. Same pattern proven in p10.18 for read-only downgrades.

### 1b. `&mut CiTypePool` parameters (25 sites)

Same analysis as 1a. 25 parameters across lower_expr_ir, lower_stmt_ir, and
related functions take `&mut CiTypePool` but the pool uses interior mutability.

**Disposition:** Convert in P10 finish alongside 1a. Same mechanical pattern.

### 1c. `&mut CiStmtPool` parameters (16 sites)

Same analysis. 16 sites where CiStmtPool is passed as `&mut` parameter.

Special case: `stmts.lower_compound(session, body_cursor, &mut self, exprs, types, scope)`
at line 10806 — the method passes itself by `&mut`. This becomes `self` (by-value,
interior mut) when the parameter type changes.

**Disposition:** Convert in P10 finish.

### 1d. `&mut Vec[T]` parameters (2 sites)

- `ci_collect_var_decls(session, cursor, decls: &mut Vec[CiHoistedVarDecl])` (line 9751)
- `ci_native_goto_collect_leaf_ids(cfg, block, out: &mut Vec[i32])` (line 10634)

**Old pattern:** Free function taking mutable Vec out-param.

**Target shape:** Return value from function.
- `ci_collect_var_decls` → return `Vec[CiHoistedVarDecl]`
- `ci_native_goto_collect_leaf_ids` → return `Vec[i32]` or accept `Vec` by value (interior mut)

**Disposition:** Convert in P10 finish. Return-value pattern preferred per §20.0 table.

### 1e. `&mut CiGotoSwitchCase` parameters (4 sites)

- `ci_goto_switch_record_case(cases: &mut CiGotoSwitchCase, ...)` (line 10214)
- Three methods taking `cases: &mut CiGotoSwitchCase` (lines 10218, 10247, 10272)

**Old pattern:** Mutable out-accumulator passed by reference.

**Target shape:** `mut self: CiGotoSwitchCase` method receiver (for the methods),
or return-value (for the free function). Since CiGotoSwitchCase is a simple accumulator,
making it a method receiver is most natural.

**Disposition:** Convert in P10 finish.

### 1f. `&mut self` call-site expressions (4 sites)

- `&mut self` at line 10613 (CiStackEmitContext passing self to CiStmtPool method)
- `&mut self` at line 10806 (CiGotoCfgContext passing self)
- `&mut exprs` / `&mut types` at lines 5822, 5825, 6229, 7689, 9423, 9426, 10786, 10344, 10360

These are call-site expressions, not parameter declarations. They disappear automatically
when the corresponding parameter types are converted in 1a–1e.

**Disposition:** Automatic — resolved when parameters are converted.

### 1g. Comment reference (1 site)

- Line 11283: `// Push args into the &mut self pool's extra vec.`

**Disposition:** Update comment text at P12 lockdown.

---

## 2. ComptimeTransform.w — 29 sites

### 2a. `&mut AstPool` parameters (18 sites)

All ct_* functions take `pool: &mut AstPool` to build new AST nodes.

**Old pattern:** Free function taking mutable AstPool.

**Target shape:** AstPool is already a struct with Vec-backed fields (`nodes`, `extra`,
`strings`, `decls`). Its mutating methods already use `mut self: AstPool`.
The free functions should become AstPool methods, or accept AstPool by value
(interior mutability via Vec).

**Conversion pattern:** Change `pool: &mut AstPool` to `pool: AstPool` in parameter types.
AstPool's add_node/add_extra/add_string already work through Vec interior mutability.
Call sites change from `&mut pool` / `&mut out` to `pool` / `out`.

**Disposition:** Convert in P10 finish. Same mechanical pattern as CImport.w pools.

### 2b. `&mut Sema` parameters (15 sites)

Functions like `ct_emit_error(sema: &mut Sema, ...)`, `ct_eval_truthy(source_ast, sema: &mut Sema, ...)`,
`ct_transform_decl(source_ast, pool, sema: &mut Sema, ...)`.

**Old pattern:** Free function taking mutable Sema to emit diagnostics or read sema state.

**Target shape:** Two sub-categories:

- **Read + emit diagnostics** (e.g., ct_emit_error): Sema.diags is a DiagnosticList
  which uses Vec interior mutability. Can accept `sema: Sema` (by-value, interior mut).

- **Transform functions** (e.g., ct_transform_decl): These read sema state and build
  AST output. The `&mut` is for diagnostic emission. Same downgrade to by-value.

**Disposition:** Convert in P10 finish. `&mut Sema` → `Sema`.

### 2c. `&mut InternPool` parameters (20 sites — some shared with 2a/2b)

Functions take `intern: &mut InternPool` to intern strings during AST construction.

**Old pattern:** Free function taking mutable InternPool for string interning.

**Target shape:** InternPool uses pointer-indirected state (`*mut InternPoolState`).
Already works with `self: InternPool` (by-value). Change to `intern: InternPool`.

**Disposition:** Convert in P10 finish. Mechanical.

### 2d. `&mut sema.diags` call-site expressions (5 sites)

- Lines 431, 527, 846, 892, 949: `comptime_*_eval_expr(..., &mut sema.diags, ...)`

These pass DiagnosticList by mutable reference to the comptime evaluator.

**Target shape:** Once DiagnosticList.emit is `mut self` (done in this session),
the evaluator can accept `diags: DiagnosticList` by value (interior mutability
via Vec). Call sites change to `sema.diags`.

**Disposition:** Convert in P10 finish alongside 3a.

---

## 3. ComptimeEval.w — 5 sites

### 3a. `diags: &mut DiagnosticList` parameter (4 function signatures)

- `comptime_try_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`
- `comptime_force_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`
- `comptime_try_eval_expr(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`
- `comptime_force_eval_expr(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`

**Old pattern:** Free function taking mutable DiagnosticList for error emission.

**Target shape:** `diags: DiagnosticList` (by-value, interior mut through Vec).

**Disposition:** Convert in P10 finish.

### 3b. `&mut self.diags` call-site (1 site)

- Line 1525 in SemaCheck.w: `comptime_force_eval_expr(self as *mut Sema, &mut self.diags, ...)`

Resolves automatically when 3a parameters are converted.

**Disposition:** Automatic.

---

## 4. SemaCheck.w — 16 sites

### 4a. §15.1 lockdown diagnostic strings (2 sites)

- Line 141: `self.emit_error("&mut T is not part of safe With (§15.1)...")`
- Line 2167: `self.emit_error("&mut T is not part of safe With (§15.1)...")`

These are error message *text* that mentions `&mut T`. They're the diagnostics
that P12 activates.

**Disposition:** Keep as-is. These are the lockdown error messages.

### 4b. Bridge implementation comments (11 sites)

Lines 20–22, 137, 2164, 6806, 7087, 7099, 7279, 7283, 7436, 7545, 7612:
Comments documenting how `&mut` is handled during the bridge period.

**Disposition:** Update or remove at P12 lockdown when bridge code is deleted.

### 4c. `&mut self.diags` call-site (1 site)

Line 6394: `comptime_force_eval_expr(self as *mut Sema, &mut self.diags, ...)`

**Disposition:** Automatic — resolves when ComptimeEval.w parameter types change (3a).

### 4d. `&mut` in comment describing legacy borrow semantics (2 sites)

Lines 7283, 7612: Comments about legacy `&mut T` (TY_REF with d1=1) semantics.

**Disposition:** Update at P12 when TY_REF mut bit is removed.

---

## 5. Render/diagnostic output — 4 sites

### 5a. Type rendering (2 sites in render.w)

- Line 911: `return "&mut " ++ render_type_expr(...)` — renders `&mut T` type for display
- Line 1079: `if op == UnaryOp.UOP_MUT_REF: return "&mut "` — renders `&mut` unary op

**Old pattern:** Renders `&mut T` type syntax in error messages and debug output.

**Target shape:** Delete when `UOP_MUT_REF` and `NK_TYPE_REF` mut variants are removed at P12.

**Disposition:** Delete at P12 lockdown.

### 5b. CiPrint.w (1 site)

- Line 471: `let kw = if is_mut != 0: "&mut " else: "&"` — renders C import reference types.

**Target shape:** C import references can be `&mut` (C code being imported has mutable
references in its interface). This rendering is for C-originated types, not With types.
May need to keep for c_import display, or change to `*mut`/`*const`.

**Disposition:** Evaluate at P12. Likely keep for c_import rendering accuracy.

### 5c. SemaDiag.w (1 site)

- Line 1134: `return "&mut " ++ pointee` — renders `&mut T` in type-mismatch diagnostics.

**Disposition:** Delete at P12 when `&mut T` type is removed.

---

## 6. Help text — 3 sites

### 6a. CLI help strings

- `src/main.w:1382`: `" 12. unary: not - & &mut\n"` — grammar help
- `src/main_emit_temp.w:732`: Same help text in temp emitter
- `src/bootstrap_main.w:239`: Same help text in bootstrap

**Disposition:** Update at P12 to `" 12. unary: not - & &raw\n"` (removing `&mut`,
adding `&raw const` / `&raw mut`).

---

## 7. Enum constants / IR representation — 2 sites

### 7a. CiIR.w

- Line 188: `CIE_ADDR_OF = 35  // d0 = operand, d1 = is_mut (0 = '&', 1 = '&mut')`

This is the C import IR representation. C code being imported genuinely has mutable
references (`&mut` in C = pointer to non-const). The d1=is_mut field maps C's
`const`/non-`const` distinction, not With's `&mut`.

**Disposition:** Keep. Rename comment to reference `*const`/`*mut` at P12.

### 7b. Sema.w comment

- Line 449: Comment about `&mut HashMap params` in comptime error checking.

**Disposition:** Update comment text at P12.

---

## 8. lib/std/traits.w — 1 site

- Line 141: `fn multi_index_set(self: &mut Self, specs: &[IndexSpec], count: i32, value: Self)`

**Old pattern:** MultiIndex deprecated mutable accessor.

**Target shape:** Delete. IndexPlace (lines 158-160) replaces this.

**Disposition:** Delete at P12 lockdown.

---

## 9. CodegenDispatch.w — 1 site (comment)

- Line 5422: `// When the receiver is &mut Vec[T], we need to dispatch on Vec[T].`

**Disposition:** Update comment text at P12.

---

## 10. MirLower.w — 1 site (comment)

- Line 2048: `// Indexing through '&Vec[T]' / '&mut Vec[T]' should index the container,`

**Disposition:** Update comment text at P12.

---

## 11. CCodegen.w — 1 site (comment)

- Line 4657: `// separate '&mut' accumulators.`

**Disposition:** Update comment text at P12.

---

## Verification status of completed phases

### P3 — Seed reinstall

**Status: Stale.** Seed at `9da3c5bae` (10 commits behind HEAD at `f40dcc9`).
Functionally complete — seed accepts both `&mut` and `mut self` syntax.
Binary needs reinstall via `make install-user` after current work stabilizes.

### P5 — Stdlib leaf migrations

**Status: Verified complete.** API shape checked for all four files:
- `hash.w` — Mutating methods use `mut self: Hasher`. Read-only use `self: Hasher`.
  No out-params. Correct §16 shape.
- `sync.w` — `Mutex.set`, `RwLock.write`, `AtomicI64.store/add` use `mut self`.
  `enter`/`enter_mut` return guard values. Correct §16 shape.
- `tls.w` — All unsafe code, `*mut TlsConn` raw pointers. Correct for unsafe/FFI.
  Public API `tls_connect` returns by value.
- `http.w` — Fixed in this session: `http_parse_url` converted from `*mut` out-params
  to `HttpUrl` return struct (commit f40dcc9). Now correct §16 shape.

### P8 — Compiler leaf modules

**Status: Verified complete.** API shape checked for all nine files:
- `Ast.w` — Mutating methods use `mut self: AstPool`. Read methods use `self: &AstPool`. Correct.
- `Token.w` — `TokenList.append` uses `mut self: TokenList`. Reads use `self: TokenList`. Correct.
- `Lexer.w` — Fixed in this session: all lex/tokenize methods converted to `mut self: Lexer`
  (commit e2daccd). Now correct.
- `Diagnostic.w` — Fixed in this session: `set_code`, `add_label`, `add_note`, `add_help`,
  `DiagnosticList.emit` converted to `mut self` (commit 2507b11). Now correct.
- `InternPool.w` — Two layers verified separately:
  - `InternPool` handle type: `self: InternPool` is correct — InternPool is a thin
    handle wrapping `*mut InternPoolState`. Copies share state. The handle doesn't
    mutate; mutations flow through the raw pointer. §16 doesn't require `mut self`
    on handle types because the handle value itself is unchanged.
  - `InternStringArena.store`: Fixed (commit 2ec3179). Was `self: InternStringArena`
    but mutates `self.offset` and `self.pages.push()`. The mutation worked at runtime
    because callers access it through `*mut InternPoolState` → field dereference, but
    the API shape violated §16.2. Now `mut self: InternStringArena`.
- `Span.w` — All read-only value methods. Correct.
- `Source.w` — All read-only or destructor. Correct.
- `Diag.w` — Re-export facade, no methods. Correct.
- `TypeLayout.w` — All read-only `self: Sema` methods. Correct.

---

## Conversion plan summary

| Step | Sites | Pattern | Effort |
|---|---|---|---|
| P10 finish: CImport.w pool params | 67 | `&mut Pool` → `Pool` (interior mut) | Mechanical, 2-3 commits |
| P10 finish: ComptimeTransform.w params | 29 | `&mut T` → `T` (interior mut or by-value) | Mechanical, 1-2 commits |
| P10 finish: ComptimeEval.w params | 5 | `&mut DiagnosticList` → `DiagnosticList` | Mechanical, 1 commit |
| P12 lockdown: Delete UOP_MUT_REF | — | Parser/sema/render/help text | Coordinated, 1 commit |
| P12 lockdown: Delete MultiIndex.multi_index_set | 1 | Remove deprecated alias | Part of P12 commit |
| P12 lockdown: Update comments | 19 | Text-only changes | Part of P12 commit |
