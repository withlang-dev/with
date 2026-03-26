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

## 4. String-Based Dispatch in Codegen (Phase 6.2)

### Problem:
Codegen.w has 47+ string comparisons for type/function dispatch.

### Categories:
- **Primitive type names** (18): `"i32"`, `"str"`, `"bool"`, etc.
  → MUST stay as strings (these are language primitives)
- **Container type names** (8): `"Vec"`, `"HashMap"`, `"Option"`, etc.
  → Could use pre-interned symbol IDs instead of string comparison
- **Builtin function names** (12): `"todo"`, `"transmute"`, `"sizeof"`, etc.
  → Could use a BuiltinFn enum
- **Runtime function names** (10): `"with_str_contains"`, etc.
  → These are C function names, strings are appropriate
- **Field names** (5): `"ptr"`, `"len"`, `"cap"`, etc.
  → Could pre-intern

### What's actually needed:
Pre-intern the ~30 container/builtin/field name symbols at codegen
initialization time and compare by symbol ID instead of string.
This is a straightforward mechanical change — no design decisions.
The primitive type names should stay as strings (they map 1:1 to
LLVM type builders and are self-documenting).

### Dependency on generics:
None. The string dispatch works correctly — this is a code quality
issue, not a correctness issue. It can be done incrementally at any
time.

---

## 5. C Backend (Phase II-5)

### Current state:
CCodegen.w handles 16 of 54 MIR intrinsics (~30%). The missing 38
intrinsics are:

**String operations (14):** STR_LEN, STR_BYTE_AT, STR_SLICE,
STR_CONTAINS, STR_STARTS_WITH, STR_ENDS_WITH, STR_FIND, STR_SPLIT,
STR_TRIM, STR_TO_UPPER, STR_TO_LOWER, STR_REPLACE, STR_INDEX_OF,
STR_REPEAT

**Advanced Vec (7):** VEC_MAP, VEC_FILTER, VEC_FOLD, VEC_CONTAINS,
VEC_ITER, VEC_WITH_CAPACITY, VEC_JOIN

**HashMap extensions (2):** MAP_CLEAR, MAP_INCREMENT

**Option extensions (2):** OPT_IS_NONE, OPT_FILTER

**Iterator (1):** VECITER_NEXT

**Array (1):** ARR_LEN

**Dynamic dispatch (2):** DYN_VTABLE_CMP, DYN_DOWNCAST

**Integer intrinsics (2):** ROTATE_LEFT, ROTATE_RIGHT

**Format intrinsics (4):** FMT_TO_STR, FMT_DEBUG_STR, FMT_DEBUG,
FMT_SPEC

**Other (3):** GENERIC_CALL, INT_SWAP_BYTES

### Path to self-compile via C backend:
1. Add missing string intrinsics (these are just calls to runtime
   functions like `with_str_contains()` — straightforward C emission)
2. Add ARR_LEN (trivial)
3. Add ROTATE_LEFT/RIGHT (single-line C: `(x << n) | (x >> (W-n))`)
4. Add FMT_TO_STR (call `with_fmt_i32`/`with_fmt_f64` etc.)
5. Add VEC_ITER/VECITER_NEXT, VEC_WITH_CAPACITY
6. Add DYN_VTABLE_CMP/DYN_DOWNCAST (pointer comparisons)
7. Add GENERIC_CALL (requires monomorphization in C backend)
8. Attempt `--emit-c` on compiler source, fix remaining gaps

### Constraint:
Each intrinsic handler is typically 5-30 lines of C emission code
(similar to existing handlers in CCodegen.w lines 2722-2956). The
runtime functions already exist in `runtime/helpers.c` — the C backend
just needs to emit calls to them.

---

## 6. Tooling (Phase II-6)

### `with fmt` — Code Formatter
**Current:** Stub in main.w (prints "not yet available").
**Approach:** AST round-trip. Parse source → walk AST → emit formatted
text. The parser and render.w already exist. The formatter needs:
- Indentation rules (4 spaces, like compiler source)
- Line width (80 columns)
- Blank line management
- Import grouping

### `with test` — Test Runner Improvements
**Current:** Basic test runner exists, discovers test files, compiles
and runs them. Reports pass/fail.
**Missing:** `@[test]` attribute discovery. Currently tests are
discovered by file convention (`test/behavior/*.w`), not by attribute.

### `with bench` — Benchmarking
**Current:** No command handler.
**Needed:** `@[bench]` attribute, iteration harness, timing.

### Error Messages with Suggestions
**Current:** Diagnostics support notes and help fields (src/Diagnostic.w).
Quality varies — some errors include suggestions, many don't.
**Key improvements:**
- "did you mean?" for undefined variables (Levenshtein distance)
- Show function signature when wrong argument count
- Every error must have a source location (some don't)

---

## 7. Principle Enforcement

### P2: Eliminate i32 Fallbacks
Codegen.w has 103 uses of `wl_i32_type`. Many are legitimate (building
i32 constants, parameter types). The problematic ones are fallbacks
where the actual type is unknown and i32 is used as a default. These
need to be audited individually — not all 103 are bugs.

### P5: HashMap Determinism — DONE ✓
Audit complete: all 160 HashMaps are lookup-only, no iteration found.
Fixpoint proves determinism.

### P8: Poisoned Nodes — DONE ✓
`NK_POISONED_EXPR` (69) was already defined in Ast.w but never emitted.
Added `Parser.poisoned_expr()` helper. Converted 15 expression-level
error sites to return poisoned nodes. Added MirLower handler (returns
unit_operand). Sema already handled it (returns TY_ERR). 4 new tests.
Commit: `73c6116`.

### P11: File Complexity Budget
- Codegen.w: 10,494 lines (2x the 5,000 line budget)
- Sema.w: 9,083 lines (1.8x budget)
The compiler supports methods on a type defined in separate files via
`use`. Splitting requires creating new files (e.g., CodegenMir.w) that
import Codegen and define `fn Codegen.method(...)` implementations.

### P13: Phase Boundary Tests — DONE ✓
13 tests covering --dump-tokens, --dump-ast, --dump-mir. Added
`expect-check-stdout` directive to test runner. Commit: `a7f22d8`.

### P14: Reserved Syntax — DONE ✓
11 tests verify all reserved keywords work or emit proper errors.
Commit: `3e1ef15`.
