# c_import: With vs Zig — Post-Fix Comparison

After closing all identified gaps, our c_import has reached full parity with Zig's translate-c for all applicable features.

---

## Closed Gaps

### 1. ~~`i32` vs `c_int` in type translator~~ — FIXED

`translate_type_recursive` now emits `c_char`, `c_int`, `c_long`, `c_uint`, `c_ulong`,
`c_longlong`, `c_ulonglong`, `c_longdouble` etc. matching Zig's platform-specific aliases.
All downstream consumers (`ci_default_for_type`, `ci_estimate_type_size`, `ci_map_base_type`)
updated for c_* types.

### 2. ~~Cast Translation Precision~~ — FIXED

Added `with_ci_implicit_cast_kind` to clang_bridge.c that classifies implicit casts:
- `NOOP/LVAL_TO_RVAL/FUNC_TO_PTR` → transparent unwrap
- `INT_TO_BOOL` → `(inner != 0)`
- `BOOL_TO_INT` → `(if inner: 1 else: 0)`
- `PTR_TO_BOOL` → `(inner != null)`
- `NULL_TO_PTR` → `null`
- `INT_TO_FLOAT` / `FLOAT_TO_INT` → `(inner as target_type)`
- `INT_TRUNC` → `(inner as target_type)`
- `TO_VOID` → unwrap

### 3. ~~Macro Parser Postfix Operators~~ — FIXED

Added postfix operator support in `ci_translate_c_expr`:
- `.field` and `->field` member access via `ci_translate_postfix`
- `[expr]` subscript access
- Bool coercion for `&&`/`||` operands (matching Zig's `macroIntToBool`)

### 4. ~~Struct Default Values~~ — FIXED

`ci_default_for_type` now returns `"0"` for enum type aliases (emitted as `type Foo = c_int`)
and `""` for array types (requiring explicit init), matching Zig's behavior.

### 5. ~~Scope System~~ — FIXED

Threaded `scope` parameter through `ci_trans_stmt` and `ci_trans_expr`:
- `ci_scope_mangle` handles variable name collisions across nested blocks
- `ci_trans_decl_stmt_scoped` registers declarations and returns updated scope
- `CXK_COMPOUND_STMT` creates new scope levels
- `CXK_DECL_REF` checks scope for mangled names
- `ci_try_translate_fn_body` initializes scope with parameter names

### 6. ~~Missing Expression/Statement Types~~ — FIXED

Added handlers for:
- `CXCursor_StaticAssert` (234) → `comptime_error("static_assert")`
- `CXCursor_GCCAsmStmt` (228) → `comptime_error("inline asm")`
- `__builtin_types_compatible_p` → explicit `comptime_error`
- `__builtin_choose_expr`, `__builtin_convertvector`, `__builtin_shufflevector` → `comptime_error`

### 7. ~~Exact Field Sizes in Padding~~ — FIXED

Added `with_cimport_struct_field_size` to clang_bridge.c using `clang_Type_getSizeOf`.
`ci_translate_struct` and `ci_struct_needs_explicit_layout` now use exact field sizes
from libclang instead of heuristic `ci_estimate_type_size`.

### 8. ~~Flexible Array Member Accessors~~ — FIXED

When last struct field is `[0]T`:
1. Field renamed from `name` to `_name`
2. Accessor function emitted: `fn name(self: *StructName) -> *ElemType`

### 9. Member Function Registration — N/A

Zig-specific feature. With doesn't have the same method-on-extern-struct concept.

### 10. ~~Variable Reference Detection in Macros~~ — FIXED

Object-like macros that reference extern vars are now emitted as `fn NAME() -> c_int`
instead of `let NAME = expr`. `ci_expr_references_var` checks translated expressions
against collected extern var names.

### 11. Self-Defined Macro Filtering — N/A

Works differently but functionally equivalent through circular reference detection.

### 12. ~~Error Reporting with Source Locations~~ — FIXED

Added `// file:line:col` comments before:
- Function unsupported-type `comptime_error` stubs
- Variable unsupported-type `comptime_error` stubs
- Forward-declared enum opaque stubs
- Untranslatable fn-like macro stubs

---

## Summary

| # | Gap | Status |
|---|-----|--------|
| 1 | `c_int` type aliases | FIXED |
| 2 | Cast translation precision | FIXED |
| 3 | Macro postfix operators | FIXED |
| 4 | Complex struct defaults | FIXED |
| 5 | Scope system | FIXED |
| 6 | Missing expr/stmt types | FIXED |
| 7 | Exact field sizes | FIXED |
| 8 | FAM accessors | FIXED |
| 9 | Member fn registration | N/A (Zig-specific) |
| 10 | Var ref detection in macros | FIXED |
| 11 | Self-defined macro filtering | N/A (works differently) |
| 12 | Error reporting quality | FIXED |

**All 10 applicable gaps are closed. 2 gaps (9, 11) are not applicable.**
