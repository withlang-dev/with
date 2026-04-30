# §20.0 API Inventory — Remaining `&mut` Sites

Written inventory per docs/mut.md Rev 8 §20.0. Every remaining `&mut` site
in `src/` and `lib/std/` is listed with its old pattern, target shape, and
planned disposition.

**Summary counts** (at commit 0469cf9):

| Category | Sites | Target | Effort |
|---|---|---|---|
| Secondary `&mut Pool` params (CImport.w) | 56 | Handle-type refactoring or context struct | **Structural** |
| Call-site `&mut` expressions (CImport.w) | 11 | Resolve when params converted | Automatic |
| Free functions with `&mut` (CImport.w) | 3 | Return-value or method extraction | Mechanical |
| Multi-`&mut` free functions (ComptimeTransform.w) | 19 | Handle-type or context struct | **Structural** |
| Single-`&mut` free functions (ComptimeTransform.w) | 10 | Method extraction or by-value | Mechanical |
| `&mut DiagnosticList` params (ComptimeEval.w) | 5 | By-value (Vec interior mut) | Mechanical |
| Comment/string-literal references to `&mut` | 19 | Update text at P12 lockdown | Trivial |
| Render/diagnostic output of `&mut T` types | 4 | Keep until UOP_MUT_REF deleted at P12 | Trivial |
| `MultiIndex.multi_index_set(self: &mut Self, ...)` | 1 | Delete at P12 (deprecated alias) | Trivial |

Total: 128 sites in src/, 1 in lib/std/. Runtime and stdlib clean.

**Critical correction:** The initial inventory classified all pool-parameter
conversions as "mechanical: `&mut Pool` → `Pool` (interior mut)." This was
wrong. CiExprPool, CiStmtPool, and CiTypePool are regular structs with Vec
fields — they do NOT use pointer-indirected interior mutability like InternPool.
Passing by value would break mutation visibility (Vec len/cap updates in the
callee would not propagate to the caller).

56 of 67 CImport.w sites and 19 of 29 ComptimeTransform.w sites are
**secondary `&mut` parameters** on methods whose receiver slot is already
occupied by a different type's `mut self`. Method extraction cannot solve
these because you can only have one receiver per method.

**Migration pattern for the 75 secondary-param sites:**

The spec-prescribed migration (§16) for `fn(&mut T, ...)` is: mutating receiver
method on T, or — when the function is already a method on a different type —
handle-type wrapping `*mut State` so by-value passing shares state. This is the
InternPool pattern, already proven in the codebase. Context-struct bundling would
be an architectural change beyond migration scope and is out of band for this work.

Implementation order is determined by call-graph frequency: pools that appear
most often as secondary `&mut` params convert first, removing the most sites
per commit. See `docs/p10-structural-sites-audit.md` "Handle-Type Conversion
Plan" section for the per-pool plan.

---

## 1. CImport.w — 67 sites

### 1a. Secondary `&mut` pool parameters (56 sites) — STRUCTURAL

These are `&mut CiExprPool`, `&mut CiTypePool`, or `&mut CiStmtPool` parameters
on methods whose receiver is already a DIFFERENT pool type's `mut self`.

| Receiver type | Secondary `&mut` param | Count |
|---|---|---|
| `mut self: CiStmtPool` | `&mut CiExprPool` | 16 |
| `mut self: CiExprPool` | `&mut CiTypePool` | 17 |
| `mut self: CiStmtPool` | `&mut CiTypePool` | 7 |
| `mut self: CiGotoCfgContext` | `&mut CiStmtPool` | 11 |
| `mut self: CiStackEmitContext` | `&mut CiStmtPool` | 5 |

Method extraction cannot solve these — the receiver slot is taken.

**Why `&mut Pool` → `Pool` (by-value) does NOT work:** CiExprPool/CiStmtPool/CiTypePool
are regular structs with Vec fields (`kinds: Vec[i32]`, `data0: Vec[i32]`, etc.).
They do NOT use pointer-indirected state like InternPool. Passing by value would
create a copy; Vec length/capacity updates in the callee would not propagate to
the caller. The p10.14-p10.22 conversions worked by making the pool the `self`
receiver (pointer-passing), not by downgrading `&mut` to by-value.

**Target shape:** Handle-type (§16, InternPool pattern). Convert each pool to a
handle wrapping `*mut PoolState`. By-value passing then shares state. One pool
at a time, each conversion independently passes fixpoint.

**Disposition:** P10 finish. CiTypePool first (24 secondary-param sites across
CImport.w + ComptimeTransform.w — highest per-commit yield), then CiExprPool,
then CiStmtPool.

### 1b. Free functions with single `&mut` (3 sites) — MECHANICAL

- `ci_collect_var_decls(session, cursor, decls: &mut Vec[CiHoistedVarDecl])` (line 9751)
  → return `Vec[CiHoistedVarDecl]` (§16.1 out-param → return value)
- `ci_goto_switch_record_case(cases: &mut CiGotoSwitchCase, ...)` (line 10214)
  → `CiGotoSwitchCase.record_case(mut self, ...)` (§16.2 method extraction)
- `ci_native_goto_collect_leaf_ids(cfg, block, out: &mut Vec[i32])` (line 10634)
  → return `Vec[i32]` (§16.1 out-param → return value)

**Disposition:** Convert in P10 finish. Genuinely mechanical.

### 1c. Call-site `&mut` expressions (11 sites) — AUTOMATIC

Lines 5822, 5825, 6229, 7689, 9423, 9426, 10344, 10360, 10613, 10786, 10806.
These are `&mut exprs`, `&mut types`, `&mut self` at call sites. They resolve
automatically when the corresponding parameter types are converted.

**Disposition:** Automatic.

### 1d. Comment reference (1 site)

- Line 11283: `// Push args into the &mut self pool's extra vec.`

**Disposition:** Update comment text at P12 lockdown.

---

## 2. ComptimeTransform.w — 29 sites

### 2a. Multi-`&mut` free functions (19 sites) — STRUCTURAL

19 functions take `pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema`
(or subsets). Example:

```
fn ct_build_type_expr(pool: &mut AstPool, intern: &mut InternPool, sema: &Sema, type_id: i32, node: i32) -> i32
```

AstPool and Sema are regular structs with Vec fields — NOT handle types.
`&mut AstPool` → `AstPool` by-value would break mutation visibility (same
analysis as CImport.w pool types: Vec len/cap updates in callee don't propagate).

InternPool IS a handle type (`*mut InternPoolState`), so `&mut InternPool` →
`InternPool` is safe for that parameter specifically.

**Target shape:** Handle-type (§16, InternPool pattern). AstPool wraps state in
`*mut AstPoolState`. Sema wraps state in `*mut SemaState` (or leverages existing
`*mut Sema` raw-pointer usage pattern — see section 3a analysis). InternPool params
are already mechanical (`&mut InternPool` → `InternPool`, handle type).

**Disposition:** P10 finish. InternPool params first (mechanical), then AstPool
handle-type, then Sema handle-type (most complex — see Sema sub-analysis).

### 2b. Single-`&mut` free functions (4 sites)

- `ct_fresh_sym(intern: &mut InternPool, ...)` — InternPool is handle type,
  `&mut` → by-value is mechanical.
- `ct_emit_error(sema: &mut Sema, ...)` — only calls `sema.diags.emit()`.
  Could become a Sema method: `Sema.ct_emit_error(mut self, ...)`.
- `ct_sync_sema_ast(sema: &mut Sema, pool: &AstPool)` — sets `sema.ast`.
  Could become a Sema method.
- `comptime_transform_module(source_ast, sema: &mut Sema, intern: &mut InternPool)` —
  entry point. InternPool is mechanical; Sema needs method extraction or handle type.

**Disposition:** Partially mechanical (InternPool), partially structural (Sema/AstPool).

### 2c. Call-site `&mut sema.diags` expressions (5 sites)

Lines 431, 527, 846, 892, 949: `comptime_*_eval_expr(..., &mut sema.diags, ...)`

These pass DiagnosticList by mutable reference. DiagnosticList is a regular struct
(`items: Vec[Diagnostic]`) — NOT a handle type. By-value would lose emitted diagnostics.

However, these call sites are redundant: the functions also take `sema_ptr: *mut Sema`,
and `sema_ptr.diags` gives the same access. The fix is to remove the `diags` parameter
and access through `sema_ptr` (see section 3a).

**Disposition:** Resolves when ComptimeEval.w params are fixed (section 3a).

---

## 3. ComptimeEval.w — 5 sites

### 3a. `diags: &mut DiagnosticList` parameter (4 function signatures) — MECHANICAL

- `comptime_try_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`
- `comptime_force_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`
- `comptime_try_eval_expr(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`
- `comptime_force_eval_expr(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ...)`

**Old pattern:** Free function taking both `sema_ptr: *mut Sema` and
`diags: &mut DiagnosticList` — but `diags` IS `sema_ptr.diags`. The
parameter is redundant.

**Target shape:** Remove the `diags` parameter. Access `sema_ptr.diags` directly
through the raw pointer (§13.1: `*mut` deref is a mutable unsafe place).
Change `diags.emit(...)` to `sema_ptr.diags.emit(...)`.

DiagnosticList is a regular struct (`items: Vec[Diagnostic]`), NOT a handle type.
`&mut DiagnosticList` → `DiagnosticList` by-value would break mutation visibility
(caller wouldn't see emitted diagnostics). But removing the redundant parameter
and accessing through `sema_ptr` sidesteps the issue entirely.

**Disposition:** Mechanical. Remove redundant parameter, access through `sema_ptr`.

### 3b. `&mut self.diags` call-sites (6 sites)

- Line 1525 in SemaCheck.w: `comptime_force_eval_expr(self as *mut Sema, &mut self.diags, ...)`
- Lines 431, 527, 846, 892, 949 in ComptimeTransform.w (section 2c above)

These call-site `&mut self.diags` / `&mut sema.diags` expressions disappear
when the `diags` parameter is removed from the function signatures.

**Disposition:** Automatic — resolves when 3a parameters are removed.

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
| P10 mechanical: CImport.w free functions | 3 | Return-value / method extraction | 1 commit |
| P10 mechanical: ComptimeEval.w redundant params | 5+6 | Remove param, access through `sema_ptr` | 1 commit |
| P10 mechanical: InternPool `&mut` params | ~20 | `&mut InternPool` → `InternPool` (handle type) | 1 commit |
| P10 structural: CImport.w secondary pool params | 56 | Handle-type refactoring for CiTypePool/CiExprPool/CiStmtPool | 3-6 commits |
| P10 structural: ComptimeTransform.w AstPool/Sema | ~19 | Handle-type or context-struct refactoring | 2-4 commits |
| P12 lockdown: Delete UOP_MUT_REF | — | Parser/sema/render/help text | Coordinated, 1 commit |
| P12 lockdown: Delete MultiIndex.multi_index_set | 1 | Remove deprecated alias | Part of P12 commit |
| P12 lockdown: Update comments | 19 | Text-only changes | Part of P12 commit |

**Migration path:** The 29 mechanical sites convert now. The 75 structural
sites use the spec-prescribed handle-type pattern (§16, InternPool as
existing reference). One pool at a time, ordered by secondary-param
frequency: CiTypePool (24), CiExprPool (16), CiStmtPool (16), AstPool,
Sema. Each conversion independently passes fixpoint.
