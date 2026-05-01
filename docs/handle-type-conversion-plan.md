# Handle-Type Conversion Plan (Slice B)

Design document for converting CiTypePool, CiExprPool, CiStmtPool, AstPool,
and Sema from value types to handle types wrapping `*mut State`. This is the
spec-prescribed §16 migration pattern for multi-pool mutation, proven by
InternPool.

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

### 2e. Sema — see Section 5 below

---

## 3. Conversion Order

**Proposed:** CiTypePool → CiExprPool → CiStmtPool → AstPool → Sema (deferred?)

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

**Same pattern for AstPool ↔ Sema:** After AstPool is converted but Sema isn't:
```
fn ct_transform_expr(
    source_ast: AstPool,        // by-value handle (was AstPool, still AstPool)
    pool: AstPool,              // was &mut AstPool — now by-value handle
    sema: &mut Sema,            // still &mut — not yet converted (or deferred)
    intern: InternPool,         // already a handle
    node: i32,
) -> i32:
```

---

## 5. Sema-Specific Analysis

Sema is genuinely different from the other pools and deserves careful analysis
before committing to handle-type conversion.

### 5a. Scale

- **127 fields** (vs 7-9 for CI pools, 45 for AstPool)
- **333 methods** across Sema.w (103), SemaCheck.w (211), SemaDiag.w (19)
- **16 `&mut Sema` sites** — 15 in ComptimeTransform.w, 1 in Frontend.w

### 5b. Existing Raw Pointer Usage

The compiler already passes `*mut Sema` in several places:

**As function parameters (4 functions):**
- `comptime_try_eval_expr_result(sema_ptr: *mut Sema, ...)`
- `comptime_force_eval_expr_result(sema_ptr: *mut Sema, ...)`
- `comptime_try_eval_expr(sema_ptr: *mut Sema, ...)`
- `comptime_force_eval_expr(sema_ptr: *mut Sema, ...)`

**As cast expressions at call sites (7 sites):**
- `self as *mut Sema` in ComptimeEval.w:1525, SemaCheck.w:6394
- `sema as *mut Sema` in ComptimeTransform.w:431, 527, 846, 892, 949

**Unsafe dereferences (2 sites):**
- ComptimeEval.w:148: `var sema = unsafe: *sema_ptr` then `sema.ast = ast`
- ComptimeEval.w:161: same pattern

### 5c. Impact of Handle-Type Conversion on Existing Patterns

If Sema becomes a handle (`type Sema { state: *mut SemaState }`):

**Q: Does `self as *mut Sema` continue to work?**
A: It would create a pointer to the handle struct (8 bytes), not to the state.
The ComptimeEval functions expect `*mut Sema` to point at the state fields
(they dereference it and access `.ast`, `.diags`, etc.). After conversion,
`self as *mut Sema` gives a pointer to `{ state: *mut SemaState }`, and
`*sema_ptr` yields the handle, not the state.

**Fix required:** The 4 ComptimeEval functions need updating. Options:
1. Change parameter type to `*mut SemaState` and pass `self.state`.
2. Change to take `Sema` by value (handle) and access `sema.state.ast`.
3. Remove the raw-pointer indirection entirely — since Sema would be a handle,
   pass it by value and access fields through `sema.state`.

Option 3 is cleanest. The functions become:
```
fn comptime_try_eval_expr_result(sema: Sema, ast: AstPool, pool: InternPool, node: i32)
```
The `var sema = unsafe: *sema_ptr; sema.ast = ast` pattern becomes
`sema.state.ast = ast` (direct field write through handle). No `unsafe` needed.

**Impact on cast sites:** The 7 `as *mut Sema` casts disappear. The 2
`unsafe: *sema_ptr` dereferences disappear. Net reduction in unsafe code.

**Q: Are there places that allocate Sema on the stack as an owned value?**
A: Yes — 10 sites across 5 files:
- `Sema.init(pool, diags, ast)` in Codegen.w, ComptimeTransform.w,
  Frontend.w (×2), Compilation.w (×2)
- `Sema.placeholder(pool, diags, ast)` in Sema.w, Zcu.w (×2)
- Direct struct literal in `sema_empty_state()` (Sema.w:672)

After conversion, `Sema.init()` and `Sema.placeholder()` return handles.
Call sites don't change — they receive a `Sema` value either way.
The `sema_empty_state()` function builds the `SemaState` struct and wraps it:

```
fn sema_empty_state(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    let ptr = with_alloc(SEMA_STATE_SIZE) as *mut SemaState
    unsafe: *ptr = SemaState { ... all 127 fields ... }
    Sema { state: ptr }
```

**Q: Does existing `sema.field` access work?**
A: No. Every `sema.ast`, `sema.diags`, `sema.pool`, `sema.type_kinds`, etc.
becomes `sema.state.ast`, `sema.state.diags`, etc. With 333 methods across
3 files, this is a massive mechanical edit.

### 5d. Per-Site Analysis of the 16 `&mut Sema` Functions

**ComptimeTransform.w — 15 functions:**

| # | Function | Sema usage | Natural Sema method? |
|---|---|---|---|
| 1 | `ct_emit_error(sema: &mut Sema, ast, node, msg)` | `sema.diags.emit()`, `sema.local_file_id` | **YES** — `Sema.ct_emit_error(mut self, ast, node, msg)` |
| 2 | `ct_eval_truthy(source_ast, sema: &mut Sema, node)` | `sema as *mut Sema`, `sema.pool`, passes to ct_emit_error | Feasible — `Sema.ct_eval_truthy(mut self, source_ast, node)` |
| 3 | `ct_transform_fstring(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | Passed to ct_transform_expr only | **NO** — sema is transport |
| 4 | `ct_transform_match_arm(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | Passed to ct_transform_expr only | **NO** — sema is transport |
| 5 | `ct_rewrite_comptime_if(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, wrapper, inner)` | Passed to ct_eval_truthy, ct_transform_expr | **NO** — sema is transport |
| 6 | `ct_sync_sema_ast(sema: &mut Sema, pool: &AstPool)` | `sema.ast = live_ast` | **YES** — `Sema.sync_ast(mut self, pool)` |
| 7 | `ct_try_fold_type_call(pool: &mut AstPool, sema: &mut Sema, intern, node)` | `sema.static_receiver_type_is_known()`, `sema as *mut Sema`, `sema.pool` | Feasible but awkward |
| 8 | `ct_rewrite_comptime_for(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, wrapper, inner)` | `sema as *mut Sema`, `sema.pool`, `sema.ty_i64`, `ct_emit_error(sema, ...)` | **NO** — complex multi-concern |
| 9 | `ct_rewrite_comptime(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | `sema.diags.count()`, `sema as *mut Sema`, `sema.pool`, `ct_emit_error(sema, ...)` | **NO** — complex multi-concern |
| 10 | `ct_transform_expr(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | `ct_sync_sema_ast(sema, pool)`, recursive dispatch | **NO** — tree walker |
| 11 | `ct_transform_fn_param_defaults(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, fn_node)` | Passed to ct_transform_expr only | **NO** — sema is transport |
| 12 | `ct_transform_trait_decl(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | Passed to ct_transform_expr only | **NO** — sema is transport |
| 13 | `ct_transform_type_decl(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | Passed to ct_transform_expr only | **NO** — sema is transport |
| 14 | `ct_transform_decl(source_ast, pool: &mut AstPool, sema: &mut Sema, intern, node)` | Dispatches to ct_transform_* functions | **NO** — dispatch hub |
| 15 | `comptime_transform_module(source_ast, sema: &mut Sema, intern)` | Heavy: sema.diags, sema.pool, sema.source_text, sema.decl_source_paths, sema.module_*, sema.type_decl_has_derive(), sema.lookup_method_sig(), sema.select_trait_impl(), sema.prepare_for_comptime_transform() | Feasible — `Sema.transform_comptime_module(mut self, source_ast, intern)` |

**Frontend.w — 1 function:**

| 16 | `Zcu.seed_sema_module_graph_frontend(self: Zcu, sema: &mut Sema)` | `sema.module_paths = Vec.new()`, `sema.module_import_*`, `sema.module_index_by_path`, `sema.global_visible_*`, `sema.module_visibility_cache` — all field assignments | **YES** — `Sema.init_module_graph(mut self)` |

**Summary:** Of 16 functions, only 3-4 are natural Sema method candidates
(ct_emit_error, ct_sync_sema_ast, comptime_transform_module, seed_sema_module_graph_frontend).
The remaining 12 pass sema as a transport parameter through the ct_transform_*
call tree. Method extraction for those 12 would move tree-walking logic into
Sema methods, which is architecturally wrong — the comptime transform pipeline
is about AST rewriting, not semantic analysis.

### 5e. Three Options for Sema

**Option A: Handle-type Sema**

Convert Sema to `type Sema { state: *mut SemaState }` following the same
pattern as the other pools.

*Cost:*
- 333 method bodies need `self.field` → `self.state.field`
- 4 ComptimeEval function signatures change `sema_ptr: *mut Sema` → `sema: Sema`
- 7 cast sites (`as *mut Sema`) removed
- 2 unsafe dereference sites removed
- 10 construction sites updated (Sema.init/placeholder/sema_empty_state)
- **Total: ~350 mechanical changes across 5 files**

*Benefit:*
- All 16 `&mut Sema` sites removed
- Full migration complete in bridge phase — no P12 surprise
- Consistent handle-type pattern across all pool types
- Net reduction in unsafe code (7 casts + 2 derefs removed)

*Risk:*
- High volume of mechanical edits (333 methods) — typo risk despite
  compiler catching most errors
- Sema.w + SemaCheck.w + SemaDiag.w are 3 large files totaling ~8000 lines

**Option B: Targeted method extraction**

Extract the 3-4 natural Sema methods (ct_emit_error, ct_sync_sema_ast,
comptime_transform_module, seed_sema_module_graph_frontend). For the
remaining 12 transport-parameter functions, change `sema: &mut Sema` to
`sema: *mut Sema` (raw pointer) and update call sites to pass
`sema as *mut Sema`.

*Cost:*
- 3-4 method extractions (substantive, requires understanding each function)
- 12 parameter type changes (`&mut Sema` → `*mut Sema`) + corresponding
  call-site updates
- Bodies of the 12 functions need `sema.field` → `sema_ptr.field` or
  `(unsafe: *sema_ptr).field`
- **Total: ~16 substantive changes + ~50 mechanical in-body changes**

*Benefit:*
- All 16 `&mut Sema` sites removed
- No 333-method rewrite of Sema internals
- Sema stays as a value type (no handle-type indirection added)

*Cost / architectural concern:*
- Moves 3-4 comptime functions from ComptimeTransform.w to Sema methods.
  This changes which type "owns" the comptime pipeline — comptime transform
  logic becomes Sema-owned rather than free-function-organized. This is a
  directional architectural change, not just a migration.
- The 12 `*mut Sema` transport-parameter functions are uglier than `&mut Sema`.
  This trades one pre-lockdown pattern for another that's harder to read.
  Both go away at P12, but `*mut Sema` is a worse bridge-state than `&mut Sema`.

*Variant B': Instead of `*mut Sema` for the 12 transport functions, pass
Sema by value and accept that mutations through the copied value struct
may not propagate.* This only works if AstPool is already a handle type
(so `sema.ast` assignment through the copy is visible via the handle's
shared state). But other Sema field mutations (sema.diags.emit, etc.)
would still need to propagate. DiagnosticList is NOT a handle type, so
by-value Sema would lose emitted diagnostics. **Variant B' does not work.**

**Option C: Defer to P12**

Leave all 16 `&mut Sema` sites in place. They resolve at P12 lockdown
when `STRICT_NO_MUT_REF = 1` makes `&mut` a hard error and the migration
becomes mandatory.

*Cost:*
- Zero implementation cost in bridge phase
- P12 lockdown becomes larger by 16 sites (but P12 is already a large
  commit — it deletes UOP_MUT_REF, the bridge code, and promotes all
  warnings to errors)

*Benefit:*
- No bridge-phase Sema work at all
- §20.0 inventory carves these out with rationale: "deferred to P12 —
  Sema's 333-method surface makes bridge-phase handle-typing cost-
  prohibitive; the 16 sites are acceptable debt resolved at lockdown"

*Risk:*
- P12 must handle Sema alongside everything else. If P12 is already risky,
  adding 16 more sites (plus the Sema handle-type rewrite if that's the
  P12 resolution) makes it riskier.
- The 16 sites are the last `&mut` in non-lockdown code — they may cause
  confusion about whether the migration is "done" during the bridge phase.

**Factors for friend review:**
- How soon is P12 expected? If weeks away, deferral cost is low. If months
  away, bridge-state debt accumulates.
- Is ComptimeTransform.w stable? If it's being actively edited, `&mut Sema`
  parameters add friction to every change.
- Does moving ct_* logic to Sema methods make architectural sense independent
  of the migration? If so, Option B has value beyond `&mut` removal. If not,
  it's migration-driven architecture distortion.
- Is bridge-phase debt (16 sites) acceptable? The CI pools + AstPool reduce
  the total from 120 to ~41 (16 Sema + 25 comments/lockdown). The Sema sites
  are the only remaining *functional* `&mut` usage.

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

| Pool | `&mut` removed | `&` removed | Methods | State fields | Risk |
|---|---|---|---|---|---|
| CiTypePool | 25 | 34 | 21 + 1 ext | 7 | Low |
| CiExprPool | 20 | 23 | 22 | 8 | Low |
| CiStmtPool | 16 | 13 | 27 + ~40 ext | 9 | Medium |
| AstPool | 18 | 67 | 101 | 45 | Medium |
| Sema | 16 | — | 333 | 127 | **High** (see §5e options) |

Total after CI + AstPool: 79 `&mut` sites removed. Remaining: ~41 sites
(16 Sema + ~25 comments/diagnostics/lockdown items).

**Decision points for friend review:**

1. **Per-pool commit shape.** Is one commit per pool correct, or should
   state-struct + handle definition be a separate commit from method updates?
   (One commit is simpler but produces larger diffs.)

2. **Sema treatment.** Three options with documented tradeoffs (§5e):
   - **Option A** (handle-type): ~350 mechanical changes, full consistency,
     no P12 surprise
   - **Option B** (targeted method extraction): ~16 substantive changes,
     moves some ct_* logic to Sema ownership, `*mut Sema` transport params
     are uglier bridge state than `&mut Sema`
   - **Option C** (defer to P12): zero bridge-phase cost, 16 sites remain
     as bridge debt, P12 lockdown handles them alongside the spec change

3. **Allocation size.** Is over-allocating (256 for CI pools, 4096 for
   AstPool) adequate, or should we add a runtime size check?

**What this is not:** This is not "reconsider whether handle-type is the
right migration pattern." That's settled (§16). This is "given handle-type
is the pattern, what does the implementation look like, and what do we do
about Sema's unique cost profile?"
