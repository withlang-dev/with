# Slice B Conversion Plan

Design document for removing `&mut` from CiTypePool, CiExprPool, CiStmtPool,
AstPool, and Sema. Pools convert to handle types wrapping `*mut State` (proven
by InternPool). Sema converts via §16.2 method extraction — free functions
taking `&mut Sema` become `mut self: Self` methods on Sema.

**Status:** Awaiting friend review before implementation.

---

## 1. The Pattern

InternPool is the reference implementation:

```
type InternPoolState {
    symbol_texts: Vec[str],
    symbol_map: HashMap[str, i32],
    strings: InternStringArena,
    // ...
}

type InternPool {
    state: *mut InternPoolState,
}

fn InternPool.init -> InternPool:
    let ptr = with_alloc(SIZE) as *mut InternPoolState
    unsafe: *ptr = InternPoolState { ... }
    InternPool { state: ptr }
```

Copies of the handle share the same underlying state. By-value passing works
because mutations flow through the shared `*mut` pointer. Methods access fields
via `self.state.field_name` (the compiler generates GEP through the pointer).

Each pool conversion follows this pattern exactly. No design variation needed.

### Shared references also convert to by-value

Handle-typing converts BOTH `&mut Pool` and `&Pool` parameters to by-value
`Pool`. The handle is 8 bytes (one pointer); passing `&Handle` adds a
needless indirection through a pointer-to-a-pointer. After conversion, all
parameter positions use `Pool` by value.

This is a significant additional surface: CiTypePool has 34 `&CiTypePool`
sites, CiExprPool 23, CiStmtPool 13, AstPool 67. These are mostly reader
method `self` parameters (`self: &CiTypePool`) and read-only function
parameters. All convert to by-value.

**Semantics verification:** In With, `&T` and `T` differ in that `&T` is a
reference (pointer to the value) while `T` is an owned copy. For handle types,
this distinction is irrelevant: copying the handle copies the pointer, and
both the reference-to-handle and the copied-handle access the same underlying
`*mut State`. Specifically:

- **No trait dispatch differences.** None of these pool types implement traits
  where `&Self` vs `Self` matters. All methods are inherent (no trait impls
  on any pool type).
- **No auto-ref behavior.** With's method dispatch doesn't distinguish
  `&self` from `self` for method resolution — both resolve to the same
  method. The `self: &CiTypePool` annotation is a calling convention, not a
  dispatch discriminator.
- **No lifetime tracking impact.** With's borrow checker tracks references
  for conflict detection, but the conversion eliminates references entirely —
  by-value handles don't create borrows, which is strictly simpler.
- **InternPool precedent.** InternPool has zero `&InternPool` references
  anywhere in the codebase. It has always been by-value only, and this works
  correctly. The other pools will follow the same pattern.

**Conclusion:** The `&Pool` → `Pool` conversion is semantics-preserving for
handle types. No behavioral difference.

---

## 2. Per-Pool Plans

### 2a. CiTypePool (25 `&mut` sites in CImport.w)

**State struct fields** (7 fields, from CiIR.w:53-61):
```
type CiTypePoolState {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    frozen: i32,
}
```

**Handle struct:**
```
type CiTypePool {
    state: *mut CiTypePoolState,
}
```

**Method dispatch:** CiTypePool has 21 methods (CiIR.w). All use either
`mut self: CiTypePool` or `self: &CiTypePool`. After conversion:

- `mut self: CiTypePool` methods: access fields via `self.state.kinds.push(...)`.
  No change to `mut self` annotation — the handle itself isn't mutated, but
  the compiler already accepts this pattern (InternPool precedent).
- `self: &CiTypePool` reader methods: change to `self: CiTypePool`. Read through
  `self.state.kinds.get(...)`. Callers passing `&types` change to `types`.

One method defined outside CiIR.w: `CiTypePool.named_type_from_text` in
CImport.w:5928, takes `mut self: CiTypePool`. Same conversion.

**Direct field access:** Only in `CiTypePool.new` constructor (CiIR.w:74-77).
Moves into `CiTypePoolState` initialization inside the new constructor.

**Allocation:** `CiTypePool.new` allocates the state:
```
fn CiTypePool.new -> CiTypePool:
    let ptr = with_alloc(CITYPEPOOL_STATE_SIZE) as *mut CiTypePoolState
    unsafe: *ptr = CiTypePoolState {
        kinds: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        strings: Vec.new(),
        frozen: 0,
    }
    ptr.kinds.push(0)
    ptr.data0.push(0)
    ptr.data1.push(0)
    ptr.data2.push(0)
    CiTypePool { state: ptr }
```

**Deallocation:** None. Current pools have no deallocation (compiler is
short-lived process). No change.

**Allocation size:** CiTypePoolState has 7 fields. Vec is 4×i64 = 32 bytes.
6 Vecs × 32 + 1 i32 = 196 bytes. Allocate 256 (same as InternPool, round up).

**Construction sites** (9 total): CiIR.w (2, inside CiModule.new), CiPrint.w (3,
test helpers), CImport.w (4, IR lowering helpers). All change transparently
because `CiTypePool.new` returns the same type name.

**CiModule impact:** CiModule holds `types: CiTypePool`. After conversion,
CiModule stores the handle (8 bytes instead of the full struct). CiModule.new
calls `CiTypePool.new()` — no change needed at the call site.

**Conversion within CImport.w:** After CiTypePool is a handle, all 25
`types: &mut CiTypePool` parameters become `types: CiTypePool`. The 8
`types: &CiTypePool` read-only parameters also become `types: CiTypePool`.
All call-site `&mut types` expressions become `types`. One commit.

### 2b. CiExprPool (20 `&mut` sites in CImport.w)

**State struct fields** (8 fields, from CiIR.w:248-257):
```
type CiExprPoolState {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    types: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    frozen: i32,
}
```

**Handle struct:**
```
type CiExprPool {
    state: *mut CiExprPoolState,
}
```

**Method dispatch:** 22 methods. Same pattern as CiTypePool — `mut self` and
`self: &CiExprPool` methods update to access through `self.state`.

**Allocation size:** 7 Vecs × 32 + 1 i32 = 228 bytes. Allocate 256.

**Construction sites:** CiIR.w (1, CiModule.new), CImport.w (4), CiPrint.w (2).

**CiModule impact:** Same as CiTypePool — stores handle instead of full struct.

### 2c. CiStmtPool (16 `&mut` sites in CImport.w)

**State struct fields** (9 fields, from CiIR.w:399-409):
```
type CiStmtPoolState {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    flags: Vec[i32],
    frozen: i32,
}
```

**Handle struct:**
```
type CiStmtPool {
    state: *mut CiStmtPoolState,
}
```

**Method dispatch:** 27 methods. Same pattern.

**Allocation size:** 7 Vecs × 32 + 1 i32 = 228 bytes. Allocate 256.

**Construction sites:** CiIR.w (1), CImport.w (4), CiPrint.w (1).

**Method distribution:** 57 total methods across 2 files:
- CiIR.w: 27 methods (core: new, add, freeze, accessors, statement constructors)
- CImport.w: 30 methods (IR lowering: lower_stmt_ir, lower_switch_stmt_ir,
  stack_emit_tree, native_goto_emit_cfg, lower_goto_body_stackify, etc.)

All 57 methods are in CiIR.w or CImport.w. No other files define CiStmtPool
methods. After conversion, each method's `self.field` → `self.state.field`.

**Reference site distribution:**
- `&mut CiStmtPool`: 16 sites, all in CImport.w (secondary params on
  CiGotoCfgContext and CiStackEmitContext methods)
- `&CiStmtPool` (read-only): 14 sites — CiIR.w (7), CImport.w (4), CiPrint.w (3)

**Risk is contained:** All method definitions and all `&mut` sites are in 2
files (CiIR.w, CImport.w) that are already well-understood from Slice A work.
The 30 CImport.w method definitions are large in count but mechanical — each
needs `self.field` → `self.state.field` for field accesses within the body.

### 2d. AstPool (18 `&mut` sites in ComptimeTransform.w)

**State struct fields** (45 fields, from Ast.w:332-449):

AstPool is substantially larger than the CI pools. Fields include:
- 9 parallel node arrays (kinds, starts, ends, data0-2, literal_suffixes, etc.)
- 1 extra Vec, 1 strings Vec, 1 decls Vec
- 16 metadata Vecs (fn_meta, type_meta, pattern_qualifiers, etc.)
- 20 HashMap lookup tables (fn_meta_map, type_meta_map, etc.)
- 3 scalar fields (local_decl_count, prelude_decl_count, frozen)

```
type AstPoolState {
    // All 45 fields from current AstPool definition
    kinds: Vec[i32],
    starts: Vec[i32],
    // ... (full list in Ast.w:332-449)
    frozen: i32,
}

type AstPool {
    state: *mut AstPoolState,
}
```

**Method distribution:** 107 total methods across 2 files:
- Ast.w: 101 methods (core pool implementation)
- ComptimeTransform.w: 6 methods (ct_new_node_copy, ct_clone_leaf,
  ct_empty_block, ct_build_call, ct_struct_lit_field_value,
  ct_clone_tree_with_subst)

All method definitions are in 2 files. No other files define AstPool methods.

**Allocation size:** ~45 fields. ~30 Vecs × 32 + ~20 HashMaps × 48 +
~3 scalars = ~1920 bytes. Allocate 4096 to be safe.

**Construction sites:** 25+ (Ast.w, Parser.w, Codegen.w, Frontend.w,
ComptimeTransform.w, Lsp.w, Zcu.w). All call `AstPool.new()` — the return
type stays the same, so call sites don't change.

**`&mut AstPool` sites:** All 18 are in ComptimeTransform.w. After AstPool is
a handle type, these become `pool: AstPool`. The `unsafe: *pool` dereference
pattern (4 sites in ComptimeTransform.w: lines 511, 526, 872, 948) currently
dereferences `&mut AstPool` → `AstPool`. After conversion, `pool` is already
an `AstPool` handle — the dereference becomes unnecessary; replace with
`let eval_ast = pool` (copy the handle).

**`&AstPool` reference distribution** (67 sites across 2 files):
- Ast.w: 67 sites (reader method `self: &AstPool` parameters)
- ComptimeTransform.w: 1 site (`ct_sync_sema_ast(sema, pool: &AstPool)`)

The 67 Ast.w sites are all method `self` parameters — mechanical conversion
to `self: AstPool`. The 1 ComptimeTransform.w site resolves alongside `&mut`.

**Files that USE AstPool** (21 files, by parameter-site count):
- Ast.w: 104, Frontend.w: 19, Compilation.w: 18, ComptimeTransform.w: 22,
  Lsp.w: 16, Resolve.w: 13, render.w: 12, AsyncLower.w: 12, Zcu.w: 7,
  ComptimeEval.w: 6, Parser.w: 6, BorrowCfg.w: 6, Sema.w: 5, Codegen.w: 5,
  MirLower.w: 4, Backend.w: 3, SemaCheck.w: 2, CCodegen.w: 2, Parse.w: 2,
  Mir.w: 1, CodegenDispatch.w: 1

These files pass AstPool by value or `&AstPool`. After conversion, `&AstPool`
parameters and call-site `&pool` expressions become by-value `AstPool`. The
bulk of the work is in Ast.w (67 `self: &AstPool` → `self: AstPool`); the
remaining files have scattered `&AstPool` parameters that convert mechanically.

**Risk reassessment:** Medium, but concentrated. 94% of method definitions are
in one file (Ast.w). The `self: &AstPool` → `self: AstPool` conversion is
pure search-and-replace within Ast.w. The cross-file `&AstPool` parameter
sites are lower count and spread across 21 files, but each is a one-line
edit. The main risk is the sheer count (67 + 18 = 85 parameter changes plus
corresponding call-site `&pool` → `pool` edits), not complexity.

### 2e. Sema — see Section 5 below (§16.2 method conversion, not handle-type)

---

## 3. Conversion Order

**Proposed:** CiTypePool → CiExprPool → CiStmtPool → AstPool → Sema §16.2

**Rationale:** Descending by secondary-param count (25, 20, 16, 18). CI pools
first because they're self-contained in CImport.w/CiIR.w. AstPool next because
it's self-contained in ComptimeTransform.w for `&mut` sites.

**Call-graph verification:** No cross-dependencies between pool conversions.
CiTypePool methods are called from CiExprPool and CiStmtPool methods (as
secondary `&mut CiTypePool` params), but converting CiTypePool to a handle
doesn't affect CiExprPool's own conversion — it just means CiExprPool methods
that took `types: &mut CiTypePool` now take `types: CiTypePool`.

Converting CiExprPool doesn't affect CiStmtPool's conversion. CiStmtPool
methods that take `exprs: &mut CiExprPool` become `exprs: CiExprPool` after
CiExprPool's conversion, regardless of CiStmtPool's own state.

**Conclusion:** Order is correct. Each conversion is independent.

---

## 4. Intermediate State Analysis

After CiTypePool is converted but before CiExprPool:

```
fn CiStmtPool.lower_decl_stmt_structural(
    mut self: CiStmtPool,       // CiStmtPool: still value type
    session: i64,
    cursor: i32,
    scope: str,
    from_goto: bool,
    exprs: &mut CiExprPool,     // still &mut — not yet converted
    types: CiTypePool,          // was &mut CiTypePool — now by-value handle
) -> CiDeclResult:
```

**This is fine.** The signature has mixed old (`&mut CiExprPool`) and new
(`CiTypePool` by-value handle) parameter styles. The build passes because:
- `CiTypePool` by-value is a handle; caller passes the handle; mutations
  flow through `*mut CiTypePoolState`.
- `&mut CiExprPool` is the old style; caller passes `&mut exprs`; mutations
  flow through the mutable reference.

Each subsequent commit converts one more pool, removing one more `&mut` param
type from these mixed signatures. Build + fixpoint pass at every intermediate
state.

**AstPool → Sema transition:** After AstPool is converted but before Sema's
§16.2 method conversions:
```
fn ct_transform_expr(
    source_ast: AstPool,        // by-value handle (was AstPool, still AstPool)
    pool: AstPool,              // was &mut AstPool — now by-value handle
    sema: &mut Sema,            // still &mut — converted in next slice
    intern: InternPool,         // already a handle
    node: i32,
) -> i32:
```

After Sema's §16.2 conversion, `ct_transform_expr` becomes a Sema method:
```
fn Sema.ct_transform_expr(
    mut self: Self,              // was sema: &mut Sema
    source_ast: AstPool,
    pool: AstPool,               // by-value handle
    intern: InternPool,
    node: i32,
) -> i32:
```

---

## 5. Sema Treatment per §16

Per docs/mut.md §16.2 and §20.0:

> `fn(&mut T, ...)` free fn → Mutating receiver method on T

All 16 `&mut Sema` sites convert to `mut self: Self` methods on Sema.
No handle-type wrapper. No deferral. Sema stays as a value type.

`mut self: Self` is a **receiver-place mode** (§5.1): the method has scoped
in-place access to the caller's place. Mutations propagate because the method
operates on the original, not a copy. This is why handle-type wrapping is
unnecessary — `mut self: Self` provides mutation visibility natively.

### 5a. The 16 Conversions

**ComptimeTransform.w — 15 functions:**

| # | Current signature | New signature | Body changes |
|---|---|---|---|
| 1 | `ct_emit_error(sema: &mut Sema, ast, node, msg)` | `Sema.ct_emit_error(mut self: Self, ast, node, msg)` | `sema.field` → `self.field` (2 refs) |
| 2 | `ct_eval_truthy(source_ast, sema: &mut Sema, node)` | `Sema.ct_eval_truthy(mut self: Self, source_ast, node)` | 1 `as *mut Sema` cast, 2 internal calls |
| 3 | `ct_transform_fstring(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_transform_fstring(mut self: Self, source_ast, pool, intern, node)` | 3 internal calls |
| 4 | `ct_transform_match_arm(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_transform_match_arm(mut self: Self, source_ast, pool, intern, node)` | 3 internal calls |
| 5 | `ct_rewrite_comptime_if(source_ast, pool, sema: &mut Sema, intern, wrapper, inner)` | `Sema.ct_rewrite_comptime_if(mut self: Self, source_ast, pool, intern, wrapper, inner)` | 4 internal calls |
| 6 | `ct_sync_sema_ast(sema: &mut Sema, pool)` | `Sema.ct_sync_sema_ast(mut self: Self, pool)` | `sema.ast` → `self.ast` |
| 7 | `ct_try_fold_type_call(pool, sema: &mut Sema, intern, node)` | `Sema.ct_try_fold_type_call(mut self: Self, pool, intern, node)` | 1 `as *mut Sema` cast, 3 internal calls |
| 8 | `ct_rewrite_comptime_for(source_ast, pool, sema: &mut Sema, intern, wrapper, inner)` | `Sema.ct_rewrite_comptime_for(mut self: Self, source_ast, pool, intern, wrapper, inner)` | 1 `as *mut Sema` cast, 7 internal calls |
| 9 | `ct_rewrite_comptime(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_rewrite_comptime(mut self: Self, source_ast, pool, intern, node)` | 1 `as *mut Sema` cast, 2 `sema.field` refs, 6 internal calls |
| 10 | `ct_transform_expr(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_transform_expr(mut self: Self, source_ast, pool, intern, node)` | 1 `as *mut Sema` cast, ~62 internal calls |
| 11 | `ct_transform_fn_param_defaults(source_ast, pool, sema: &mut Sema, intern, fn_node)` | `Sema.ct_transform_fn_param_defaults(mut self: Self, source_ast, pool, intern, fn_node)` | 2 internal calls |
| 12 | `ct_transform_trait_decl(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_transform_trait_decl(mut self: Self, source_ast, pool, intern, node)` | 3 internal calls |
| 13 | `ct_transform_type_decl(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_transform_type_decl(mut self: Self, source_ast, pool, intern, node)` | 2 internal calls |
| 14 | `ct_transform_decl(source_ast, pool, sema: &mut Sema, intern, node)` | `Sema.ct_transform_decl(mut self: Self, source_ast, pool, intern, node)` | 6 internal calls |
| 15 | `comptime_transform_module(source_ast, sema: &mut Sema, intern)` | `Sema.comptime_transform_module(mut self: Self, source_ast, intern)` | 34 `sema.field` refs, 4 internal calls |

**Frontend.w — 1 function:**

| 16 | `Zcu.seed_sema_module_graph_frontend(self: Zcu, sema: &mut Sema)` | `Sema.init_module_graph(mut self: Self, zcu: Zcu)` | 13 `sema.field` → `self.field`, 8 `self.` (Zcu) → `zcu.` |

### 5b. Call-Site Changes

**Internal calls between the 16 functions.** These are the bulk of the
mechanical work. Currently:
```
ct_transform_expr(source_ast, pool, sema, intern, node)
ct_emit_error(sema, ast, node, msg)
ct_sync_sema_ast(sema, pool)
```

After conversion (all are now Sema methods; `sema` is now `self`):
```
self.ct_transform_expr(source_ast, pool, intern, node)
self.ct_emit_error(ast, node, msg)
self.ct_sync_sema_ast(pool)
```

**External call sites.** The 16 functions are called from outside:

- `comptime_transform_module` is called from Frontend.w (2 sites):
  `comptime_transform_module(source_ast, &mut sema, intern)`
  → `sema.comptime_transform_module(source_ast, intern)`

- `seed_sema_module_graph_frontend` is called from Frontend.w (2 sites):
  `self.seed_sema_module_graph_frontend(&mut sema)`
  → `sema.init_module_graph(self)`

**Calls to `sema: &Sema` (read-only) free functions.** ComptimeTransform.w
has 10 functions taking `sema: &Sema` (ct_build_type_expr, ct_build_value_tree,
ct_decl_source_path, etc.). These are NOT in the 16 `&mut Sema` sites and
stay as free functions. After conversion, calls from inside a `mut self: Self`
method body pass `&self` where they previously passed `sema`:
```
ct_build_value_tree(pool, intern, &self, value, node, extras)
ct_decl_source_path(&self, di)
```

### 5c. The `*mut Sema` Raw Pointer Paths

5 of the 16 functions cast `sema as *mut Sema` to call ComptimeEval functions:

```
// Current pattern (in ct_eval_truthy, ct_try_fold_type_call,
// ct_rewrite_comptime_for, ct_rewrite_comptime, ct_transform_expr):
let value = comptime_force_eval_expr(sema as *mut Sema, source_ast, sema.pool, node)
```

ComptimeEval.w has 4 functions taking `sema_ptr: *mut Sema`:
```
fn comptime_try_eval_expr_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    var sema = unsafe: *sema_ptr     // creates a local copy with different ast
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 0)
    ...
    sema_ptr.diags.emit(evaluator.pending_diag)  // writes back to original
```

The pattern: copy Sema to set a different `ast`, run the evaluator, write
diagnostics back through the raw pointer. After conversion, `sema` is `self`
(receiver-place mode), so the cast becomes `self as *mut Sema`.

**Investigation needed before implementation:**

Option 1: Keep `*mut Sema` cast. `self as *mut Sema` gives a pointer to the
caller's place. The ComptimeEval functions dereference it to create a modified
copy (`var sema = unsafe: *sema_ptr; sema.ast = ast`). This works but keeps
the unsafe indirection.

Option 2: Convert ComptimeEval functions to Sema methods. The "copy Sema with
different ast" pattern becomes unclear — a `mut self: Self` method operates on
the original place, but the evaluator needs a separate Sema with a different
`ast`. This may require the evaluator to take `ast` as a separate parameter
rather than embedding it in the Sema copy.

Option 3: Pass Sema by value to ComptimeEval functions (change `sema_ptr: *mut
Sema` → `sema: Sema`). The copy semantics match the current `var sema = unsafe:
*sema_ptr` pattern. The `sema_ptr.diags.emit(...)` write-back changes to
returning diagnostics or using DiagnosticList as a handle. Requires
DiagnosticList investigation.

**Decision:** investigate during implementation. The 5 cast sites are localized
in ComptimeTransform.w; any of the 3 options works mechanically. Document
what's left after the 16 method conversions.

### 5d. Work Summary

| Item | Count |
|---|---|
| Functions converted to Sema methods | 16 |
| `sema.field` → `self.field` in bodies | ~55 refs |
| Internal call-site rewrites (`ct_fn(args, sema)` → `self.ct_fn(args)`) | ~100 calls |
| External call-site rewrites | 4 |
| `as *mut Sema` casts (may stay or simplify) | 5 |
| `sema: &Sema` free functions (unchanged) | 10 |
| Existing Sema methods (unchanged) | 384 |

Sema stays as a value type. Existing 384 methods are unaffected — no
`self.field` → `self.state.field` rewrite. The work is confined to
ComptimeTransform.w (15 functions + their internal call sites) and
Frontend.w (1 function + 2 call sites)

---

## 6. Per-Pool Commit Shape

Each pool conversion is one commit with this internal order:

1. **Define State struct.** Add `type CiTypePoolState { ... }` with all fields
   moved from the current `CiTypePool` definition. Keep the old type definition
   temporarily.

2. **Redefine handle.** Change `type CiTypePool { state: *mut CiTypePoolState }`.

3. **Update constructor.** `CiTypePool.new` allocates state, initializes via
   `unsafe: *ptr = CiTypePoolState { ... }`, returns handle.

4. **Update methods.** All `self.field` → `self.state.field` in method bodies.
   For `self: &CiTypePool` reader methods, change to `self: CiTypePool`.

5. **Update callers.** All `types: &mut CiTypePool` → `types: CiTypePool`.
   All `types: &CiTypePool` → `types: CiTypePool`. All `&mut types` and
   `&types` at call sites → `types`.

6. **Build + fixpoint.**

Steps 1-3 happen in the type definition file (CiIR.w for CI pools, Ast.w for
AstPool). Steps 4-5 happen across CImport.w / ComptimeTransform.w / etc.
All in one commit per pool.

---

## 7. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `self.state.field` typo in 27-101 method bodies | Medium | Compiler catches at build; grep for orphan `self.kinds` etc. |
| `with_alloc` size too small for state struct | High | Over-allocate (2× estimate); add assert in debug build |
| CiModule struct layout change breaks fixpoint | Low | CiModule stores handle (8 bytes); layout changes but fixpoint tests new layout |
| Reader methods still using `self: &Pool` after conversion | Medium | grep for `&CiTypePool` etc. after each commit |
| HashMap field in state struct needs special init | Low | Use same `HashMap.new()` pattern as InternPool |
| AstPool's 45 fields → large state struct alloc | Medium | Allocate 4096 to be safe; measure actual size later |

---

## 8. Verification

Per commit:
1. `make build` — must pass
2. `make fixpoint` — must pass
3. `make test` — no new failures
4. `grep -rn '&mut CiTypePool' src/` — must return 0 after CiTypePool commit
5. `grep -rn '&CiTypePool' src/` — must return 0 (all converted to by-value)

After all CI pool conversions:
- `grep -rn '&mut Ci.*Pool' src/` — must return 0
- Total `&mut` count in src/ should drop by ~61

After AstPool conversion:
- `grep -rn '&mut AstPool' src/` — must return 0
- `grep -rn '&AstPool' src/` — must return 0 (all by-value)
- Total `&mut` count drops by ~18 more

---

## 9. Summary

| Pool | `&mut` removed | `&` removed | Pattern | Risk |
|---|---|---|---|---|
| CiTypePool | 25 | 34 | Handle-type | Low |
| CiExprPool | 20 | 23 | Handle-type | Low |
| CiStmtPool | 16 | 13 | Handle-type | Medium |
| AstPool | 18 | 67 | Handle-type | Medium |
| Sema | 16 | — | §16.2 method conversion | Low |

Total: 95 `&mut` sites removed. Remaining: ~25 comments/diagnostics/lockdown
items.

**Implementation order within Slice B:**

1. CiTypePool handle-type conversion (one commit)
2. CiExprPool handle-type conversion (one commit)
3. CiStmtPool handle-type conversion (one commit)
4. AstPool handle-type conversion (one commit)
5. Sema 16 method conversions per §16.2 (one commit)

Build + fixpoint after each. Push individually.

Sema is ordered last because some ComptimeTransform.w functions have both
`pool: &mut AstPool` and `sema: &mut Sema` parameters. Converting AstPool to
handle-type first means those signatures already have `pool: AstPool` when
the Sema method conversion replaces the function with a `mut self: Self`
method.

**Decision points for friend review:**

1. **Per-pool commit shape.** Is one commit per pool correct, or should
   state-struct + handle definition be a separate commit from method updates?
   (One commit is simpler but produces larger diffs.)

2. **Allocation size.** Is over-allocating (256 for CI pools, 4096 for
   AstPool) adequate, or should we add a runtime size check?
