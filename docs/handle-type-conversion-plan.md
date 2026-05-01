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

**Note on CiStmtPool methods in CImport.w:** CiStmtPool has many methods
defined in CImport.w (goto lowering, stackify emit, native goto emit — ~40
methods). These already use `mut self: CiStmtPool`. After conversion, they
access state through `self.state`. Large surface area but mechanical: every
`self.kinds` becomes `self.state.kinds`, etc.

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

**Method dispatch:** 101 methods across Ast.w. Same pattern — all field
accesses route through `self.state`. Large but mechanical.

**Allocation size:** ~45 fields. ~30 Vecs × 32 + ~20 HashMaps × 48 +
~3 scalars = ~1920 bytes. Allocate 2048.

**Construction sites:** 25+ (Ast.w, Parser.w, Codegen.w, Frontend.w,
ComptimeTransform.w, Lsp.w, Zcu.w). All call `AstPool.new()` — the return
type stays the same, so call sites don't change.

**All 18 `&mut AstPool` sites are in ComptimeTransform.w.** After AstPool is a
handle type, these become `pool: AstPool`. The `unsafe: *pool` dereference
pattern (4 sites in ComptimeTransform.w: lines 511, 526, 872, 948) currently
dereferences `&mut AstPool` → `AstPool`. After conversion, `pool` is already
an `AstPool` handle — the dereference becomes unnecessary; replace with
`let eval_ast = pool` (copy the handle).

**Files using AstPool:** 21 files. But only ComptimeTransform.w has `&mut`
params. All other files pass AstPool by value or `&AstPool`. The `&AstPool`
references (read-only) change to by-value (handle copy), which is a broader
change but purely mechanical — grep for `&AstPool` and remove the `&`.

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

### 5d. The Deferral Question

**Should Sema's conversion be deferred?**

Arguments for deferring:
- Only 16 `&mut Sema` sites (15 in ComptimeTransform.w, 1 in Frontend.w).
  After CiTypePool/CiExprPool/CiStmtPool/AstPool are done, these are the only
  remaining structural `&mut` sites outside P12 lockdown items.
- 333 methods need `self.field` → `self.state.field` rewriting. That's a
  massive mechanical edit with high risk of typos.
- The existing `*mut Sema` raw-pointer pattern would need updating (7 cast
  sites, 2 unsafe deref sites, 4 function signatures).
- 10 construction sites need updating.
- The 16 sites are acceptable bridge-state debt that resolves cleanly at P12
  lockdown when `&mut` is banned and the migration is mandatory.

Arguments against deferring:
- §16 says `&mut Sema` must go. Deferring to P12 means the migration isn't
  "complete" until lockdown.
- The 15 ComptimeTransform.w sites could be cleaned up at the same time as
  AstPool conversion (they share the same function signatures).
- Leaving `&mut Sema` in place while everything else is handle-typed creates
  an inconsistency in the codebase.

**Recommendation:** Defer Sema's handle-type conversion. The cost/benefit
ratio is unfavorable — 333 methods × `self.state.` rewriting for 16 sites.
The CI pools (61 sites) and AstPool (18 sites) deliver 79 site reductions
with far less risk. The remaining 16 Sema sites resolve at P12 lockdown
as part of the mandatory `&mut` elimination.

An alternative middle ground: convert the 15 ComptimeTransform.w functions
to take `sema: Sema` by value (keeping Sema as a value type) by restructuring
them as Sema methods or passing `*mut Sema` explicitly. This eliminates
`&mut Sema` without the handle-type rewrite. The 1 Frontend.w site
(`seed_sema_module_graph_frontend`) similarly could become a Sema method.
This is a smaller, safer change than full handle-type conversion.

**This is a real decision for friend review.** The spec doesn't prescribe
*when* in the migration Sema converts — only that `&mut Sema` must eventually
go. The question is whether the handle-type pattern (high cost, high
consistency) or the targeted method-extraction (low cost, leaves Sema as
value type) is the right call.

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
| Sema | 16 | — | 333 | 127 | **High** (recommend defer) |

Total after CI + AstPool: 79 `&mut` sites removed. Remaining: ~41 sites
(16 Sema + ~25 comments/diagnostics/lockdown items).

**Decision points for friend review:**
1. Is the per-pool commit shape correct, or should state-struct + handle be
   a separate commit from method updates?
2. Should Sema be deferred, or should we do targeted method-extraction for
   the 16 sites instead of full handle-type conversion?
3. Is the allocation size estimation adequate, or should we add a runtime
   size check?
