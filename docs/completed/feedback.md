# Feedback — Detailed Blockers and Open Issues

This document provides full evidence and analysis for every remaining
open item in `docs/finalize.md`.

---

## 1. `distinct` Keyword (Phase 2)

**Status: IMPLEMENTED. Transparent LLVM lowering. BlockId migrated.**

`distinct` is fully functional with transparent LLVM lowering (no
wrapper struct — distinct types are bare integers at LLVM level).
21-test compatibility suite at `test/behavior/behav_distinct_compat.w`.

`type BlockId = distinct i32` migrated in Mir.w + MirLower.w (15
boundary casts). NodeId and TypeId deferred (450+ and 300+ sites
respectively — very large mechanical changes).

### How to use:
```
type NodeId = distinct i32
type TypeId = distinct i32

fn lookup(id: NodeId) -> ...:
    // id is NodeId, not raw i32
    // id as i32 extracts the underlying value
```

---

## 2. Generic Type Erasure Bug (Phase 3.5 + Phase II-2) — FIXED ✓

**Root cause was: Codegen caches Vec types by LLVM element type pointer,
not by sema type identity. Fixed: cache by sema_tid.**

### Five Whys:

1. **Why does `Vec[str].get()` return `i32`?**
   Because sema resolves `Vec[str]` to the same codegen Vec type as
   `Vec[i32]`, so the element type is wrong.

2. **Why does codegen use the same Vec type?**
   Because `Codegen.get_or_create_vec_type(elem_ty)` at line 3239
   caches by LLVM element type pointer value. If the same LLVM type
   pointer is reused (or if registration order changes), the wrong
   cached entry is returned.

3. **Why does registration order change?**
   When `generic_inst_cache_key` uses f-strings instead of
   `int_to_string`, the MIR lowering generates different code (extra
   basic blocks for MIR_INTRINSIC_FMT_TO_STR). This changes the order
   in which generic types are encountered during sema's type collection
   phase, which changes which Vec specialization is registered first.

4. **Why does registration order matter?**
   Because `sema_type_to_llvm` (Codegen.w line 2122) converts sema
   types to LLVM types, and `get_or_create_vec_type` caches the first
   one it sees. All subsequent Vec instantiations with the same LLVM
   element type share that cached entry.

5. **Why isn't the sema type identity preserved?**
   Because codegen's caching is keyed on derived LLVM types (raw
   pointers), not on the original sema type identity. The sema system
   correctly tracks `Vec[i32]` ≠ `Vec[str]` via `TY_GENERIC_INST`
   with distinct `type_extra` entries, but codegen throws this away.

### The fix:

In `Codegen.get_or_create_vec_type` (line 3239), change the cache key
from the LLVM element type pointer to the **sema type ID** of the
generic instance. This preserves the full identity:

```
// Current (broken):
fn get_or_create_vec_type(elem_ty: i64) -> i64:
    let cached = self.vec_cache_map.get(elem_ty)

// Fixed:
fn get_or_create_vec_type(sema_tid: i32, elem_ty: i64) -> i64:
    let cached = self.vec_cache_map.get(sema_tid)
```

Same fix needed for `get_or_create_hashmap_type`,
`get_or_create_option_type`, `get_or_create_result_type`.

**Files:** `src/Codegen.w` — `get_or_create_vec_type` (line 3239),
`sema_type_to_llvm` (line 2122+), and all callers.

---

## 3. Builtin Trait Names (Phase 6.1) — FIXED ✓

Deleted `sema_is_builtin_trait_name`. Replaced with `lang_trait_syms`
HashMap containing 4 language-level traits (Copy, Drop, Send,
ScopedSend). Other 13 traits resolve from prelude imports. Orphan rule
now only enforced for local (user) impl decls, not prelude impls.
Commit: `392de03`.

---

## 4. String-Based Dispatch in Codegen (Phase 6.2) — DONE ✓

36 symbols pre-interned at codegen init. All 59 dispatch sites
converted to O(1) symbol ID comparisons. 34 string comparisons
remain intentionally (primitive types, ABI names, runtime C functions).

---

## 5. C Backend (Phase II-5) — Intrinsics DONE ✓

### Current state:
CCodegen.w (4,440 lines) handles all 54 MIR intrinsics (commit
`f434b08`). All 37 previously missing intrinsics implemented.

### Remaining path to self-compile:
1. ~~Handle all intrinsics~~ — DONE
2. Attempt `--emit-c` on compiler source, fix remaining gaps
3. Compile emitted C to working binary
4. Cross-compile for 4 targets

---

## 6. Tooling (Phase II-6) — DONE ✓

### `with fmt` — Code Formatter — DONE ✓
Implemented in main.w (commit `e72847c`). Supports `-w` (write)
and `-l` (list) modes. AST round-trip formatting.

### `with test` — Test Runner — DONE ✓
`@[test]` attribute discovery and `--filter` implemented
(commit `cbcfa85`).

### `with bench` — Benchmarking — DONE ✓
`@[bench]` attribute + `bench_*` naming. Go-style auto-calibration.
Reports name, N, ns/op. `--filter` support. `lib/test/bench.w`.
Commit: `6ef5b8b`.

### Error Messages with Suggestions — Partially DONE
"Did you mean?" for undefined variables/types implemented with
Levenshtein distance (commit `169dac7`).
**Remaining:**
- Show function signature when wrong argument count
- Audit errors for missing source locations

---

## 8. MIR Verification and Regression Testing

### Typed MIR Verifier — DONE ✓
408-line verifier in `src/Mir.w` runs before codegen (commit `99ceb09`).
Validates type consistency across MIR.

### Bug Fixes (5 with regression tests)
- Generic option match inference (`4b69f1d`)
- Nested Vec field string comparisons (`bd1021a`)
- MIR aggregate destination typing (`47240f3`)
- Semantic comparison dispatch (`13003db`)
- Nested projection typing (`6411c91`)

### Regression Matrix — DONE ✓
Comprehensive regression suites (commit `c1c302d`):
`regression_aggregate_flow_matrix.w`, `regression_projection_import_matrix.w`.

---

## 7. Principle Enforcement

### P2: Eliminate i32 Fallbacks — DONE ✓
21 fallback sites converted to use `Codegen.type_fallback()` (sets
`had_error = 1`). 2 sites intentionally kept (resolved during mono).
Remaining ~80 `wl_i32_type` uses are legitimate.

### P5: HashMap Determinism — DONE ✓
Audit complete: all 160 HashMaps are lookup-only, no iteration found.
Fixpoint proves determinism.

### P8: Poisoned Nodes — DONE ✓
`NK_POISONED_EXPR` (69) already defined in Ast.w. Added
`Parser.poisoned_expr()` helper. Converted 15 expression-level
error sites. Added MirLower handler. 4 new tests. Commit: `73c6116`.

### P11: File Complexity Budget — DONE ✓
Codegen.w: 10,494 → 3,974 lines (split into CodegenDispatch.w +
CodegenTraits.w). Sema.w: 9,112 → 1,997 lines (split into
SemaCheck.w + SemaDecl.w + SemaDiag.w). Commit: `c694460`.

### P13: Phase Boundary Tests — DONE ✓
13 tests covering --dump-tokens, --dump-ast, --dump-mir. Added
`expect-check-stdout` directive to test runner. Commit: `a7f22d8`.

### P14: Reserved Syntax — DONE ✓
11 tests verify all reserved keywords work or emit proper errors.
Commit: `3e1ef15`.
