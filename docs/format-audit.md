# F-String Code Path Audit

Audit of all current f-string and string-coercion code paths.
Completed as task 1 of `docs/format-plan.md`.

---

## 1. Lexer (`src/Lexer.w`)

- **Line ~568**: F-string token detection. The lexer recognizes `f"..."` prefix
  and lexes the entire f-string as a single `TK_STRING` token. No separate
  `TK_FSTRING` token kind exists.
- **Line ~386**: Brace depth tracking. The lexer tracks `{}`-depth so that `"`
  inside interpolation holes is not treated as the end of the string.
- **Line ~413**: Inside an interpolation hole, nested string literals are skipped
  (the lexer tracks quote nesting within braces).

**No format spec awareness.** The lexer treats the colon in `{x:08x}` as ordinary
content inside the interpolation hole. All spec parsing would happen later.

---

## 2. Parser (`src/Parser.w`)

### Entry point
- **Line 1913–1916**: In `parse_string_literal()`, `is_fstring_token_text(text)`
  checks for `f"` prefix (byte 102 = `f`, byte 34 = `"`). If true, dispatches to
  `desugar_interpolated_string`.

### Core functions

| Function | Line | Purpose |
|----------|------|---------|
| `desugar_interpolated_string` | 1922 | Main desugaring: scans content for `{...}` holes, builds `OP_CONCAT` chain |
| `interp_extract_segment` | 1974 | Creates `NK_STRING_LIT` for text between holes |
| `interp_concat` | 1985 | Builds `NK_BINARY(OP_CONCAT)` tree. If left==0, returns right |
| `interp_to_string` | 1990 | **Placeholder** — returns expression as-is, no wrapping |
| `parse_interpolated_expr` | 1997 | Re-lexes and re-parses expression text via sub-parser |
| `is_fstring_token_text` | 2095 | Checks for `f"` prefix |
| `strip_string_token_text` | 2067 | Removes `f"` prefix and closing `"` |

### Current behavior
- F-strings are desugared entirely at parse time into `NK_BINARY(OP_CONCAT)` chains.
- No `NK_FSTRING` node exists. Format metadata is lost.
- The parser does **not** handle `:spec` — everything between `{` and `}` is treated
  as the expression.
- Escaped braces: `{{` → `{`, `}}` → `}`, `\{` → `{` (lines 1929–1937).
- Brace depth tracking for nested `{}` inside expressions (lines 1943–1949).

### What must change
- Replace `interp_concat`-based desugaring with structured `NK_FSTRING` emission.
- Add `:` splitting inside holes (top-level only, respecting nested delimiters).
- Add `parse_format_spec` to parse the spec grammar into `NK_FSTRING_SPEC`.
- Remove `interp_to_string` (type coercion moves to codegen).

---

## 3. AST (`src/Ast.w`)

- **Line 208**: `const OP_CONCAT: i32 = 19` — binary operator for string concat.
- No `NK_FSTRING` or `NK_FSTRING_SPEC` node kinds exist yet.
- Node kind constants are sequential integers; new kinds can be appended.
- Node name table and debug printer must be updated when new kinds are added.

---

## 4. Sema (`src/Sema.w`)

- **Line 3801**: `NK_BINARY` dispatches to `check_binary()`.
- **Line 4107**: `check_binary()` — type-checks binary operations.
- **Line 4186–4187**: `OP_ADD` with `str + str` → returns `ty_str`.
- **Line 4225**: `OP_CONCAT` → always returns `ty_str` (no operand type checking).

### What must change
- Add `check_fstring` handler for `NK_FSTRING`.
- Type-check each expression segment.
- Validate format spec against expression type (mode/type matrix).
- Set result type to `ty_str`.

---

## 5. Codegen (`src/Codegen.w`)

### String concatenation
- **Line 5829**: Binary `OP_CONCAT` dispatches to `mir_str_concat()`.
- **Line 5833**: `mir_str_concat(lhs, rhs)` — coerces both operands to str, calls
  `with_str_concat` runtime function.

### String coercion
- **Line 5861**: `coerce_val_to_str(val, str_ty)`:
  - i32 or narrower → calls `int_to_string()`
  - i64 → calls `i64_to_string()`
  - f32 → fpcast to f64, calls `with_f64_to_string()`
  - f64 → calls `with_f64_to_string()`
  - Other → returns unchanged
- **Line 1261**: `enforce_coerced_type(value, expected_ty, context)`:
  - Lines 1274–1279: Auto-coerces numeric to str when expected type is str.
  - Calls `coerce_val_to_str` for the conversion.
- **Line 10000**: `coerce_ptr_to_str(ptr_val)` — C pointer to With str via
  `with_str_from_cstr()`.

### Compile-time string eval
- **Line 4574**: `try_eval_const_string()` handles `NK_BINARY` with `OP_CONCAT`
  or `OP_ADD` — recursively evaluates and concatenates at compile time.

### What must change
- Add `NK_FSTRING` handler (initially: interim fallback desugaring to `OP_CONCAT`).
- Later: emit `with_fmt_*` runtime calls per segment.
- Eventually: remove `coerce_val_to_str` once f-strings handle all formatting.

---

## 6. Runtime (`runtime/helpers.c`)

### Current formatting functions

| Function | Line | Signature | Behavior |
|----------|------|-----------|----------|
| `with_i32_to_str` | 352 | `(int32_t) → with_str` | `snprintf("%d")` |
| `i32_to_str` | 370 | alias | → `with_i32_to_str` |
| `int_to_string` | 375 | alias | → `with_i32_to_str` |
| `i64_to_string` | 380 | `(int64_t) → with_str` | `snprintf("%lld")` |
| `with_f64_to_string` | 397 | `(double) → with_str` | `snprintf("%g")` |
| `with_str_concat` | 661 | `(with_str, with_str) → with_str` | malloc + memcpy both |

### Other runtime files
- `runtime/with_runtime.c`: `with_str_from_cstr`, `with_i64_to_str`, `with_bool_to_str`
- `runtime/with_runtime.h`: extern declarations (lines 23–40)
- `runtime/support_runtime.c`: additional `with_bool_to_str`

### What must change
- Add `with_fmt_*` family: `with_fmt_i32`, `with_fmt_i64`, `with_fmt_u32`,
  `with_fmt_u64`, `with_fmt_f64`, `with_fmt_bool`, `with_fmt_str`.
- Add spec variants: `with_fmt_int_spec`, `with_fmt_f64_spec`, `with_fmt_str_spec`.
- Add shared utilities: `fmt_buf_to_str`, `fmt_pad`.
- Eventually remove `int_to_string`, `i64_to_string`, `with_f64_to_string` aliases
  (after migration).

---

## 7. Locations That Must Learn About NK_FSTRING / NK_FSTRING_SPEC

(Task 2 of format-plan.md)

### AST node kind list
- `src/Ast.w` — add constants after NK_COMPTIME_ERROR (71). Next available: 72, 73.

### AST name/debug tables
- `src/main_emit_temp.w:324` — `ast_decl_kind_name()` — only handles decl kinds,
  f-string is an expression kind so no change needed here.
- `src/main_emit_temp.w:432` — `dump_tag_name()` — token tags only, no change.

### Sema expression dispatch
- `src/Sema.w:3783` — after `NK_STRING_LIT → ty_str`, add `NK_FSTRING → check_fstring()`.
- `src/Sema.w:7884` — `kind_to_str` helper for error messages — add `NK_FSTRING → "f_string"`.

### MirLower expression dispatch
- `src/MirLower.w:651` — after `NK_STRING_LIT` handling, add `NK_FSTRING`.
- `src/MirLower.w:3176` — second dispatch site (likely async MIR), same treatment.

### Codegen expression dispatch
- `src/Codegen.w:2103` — after `NK_STRING_LIT` handling, add `NK_FSTRING`.
- `src/Codegen.w:4579` — `try_eval_const_string` — may need to handle `NK_FSTRING`
  for compile-time f-string evaluation (or skip initially).

### Driver / dump utilities
- `src/Driver.w:101` — `dump_typed()` — generic dump, no node-kind switch.
- `src/compiler/Backend.w:83` — `backend_dump_struct_extras` — struct-specific, no change.

**Summary:** 6 dispatch sites need updating across Sema, MirLower, and Codegen.
No changes needed to dump/debug utilities (they don't switch on expression node kinds).

---

## 8. Migration Scope (str ++ non-str Inventory)

(Task 3 of format-plan.md)

Total `int_to_string` / `i64_to_string` / `with_f64_to_string` call sites:
- **437 in `src/`** (compiler source)
- **104 in `test/` and `lib/`** (tests and stdlib)
- **541 total**

### Breakdown by file (compiler source, top 20)

| Count | File |
|-------|------|
| 93 | `src/Mir.w` |
| 62 | `src/Codegen.w` |
| 62 | `src/CCodegen.w` |
| 41 | `src/Sema.w` |
| 32 | `src/CImport.w` |
| 27 | `src/compiler/foundation/Types.w` |
| 15 | `src/Resolve.w` |
| 15 | `src/compiler/Backend.w` |
| 14 | `src/AsyncMir.w` |
| 12 | `src/compiler/Compilation.w` |
| 11 | `src/compiler/Frontend.w` |
| 9 | `src/render.w` |
| 7 | `src/main.w` |
| 7 | `src/compiler/Zcu.w` |
| 6 | `src/Parser.w` |
| 6 | `src/compiler/foundation/DiagnosticRender.w` |
| 5 | `src/main_emit_temp.w` |
| 4 | `src/DiagnosticRender.w` |
| 4 | `src/compiler/foundation/Values.w` |
| 3 | `src/MirLower.w` |

Most uses are diagnostic/debug messages: `"error at " ++ int_to_string(line)`.
These all become `f"error at {line}"` after migration.

---

## 9. Debug Trait Inventory

(Task 4 of format-plan.md)

### Debug trait definition
- `lib/std/traits.w:17`: `pub trait Debug = fn debug_str(self) -> str`
- `lib/std/traits.w:20`: `pub trait Display = fn to_str(self) -> str`

### Existing Debug impls

| Type | File:Line | Implementation |
|------|-----------|----------------|
| `i32` | `lib/std/traits.w:74` | `int_to_string(self)` |
| `bool` | `lib/std/traits.w:78` | `if self: "true" else: "false"` |
| `str` | `lib/std/traits.w:85` | `"\"" ++ self ++ "\""` |

### Missing Debug impls needed for `:?`

| Type | Status |
|------|--------|
| `i64` | Missing |
| `u8`, `u16`, `u32`, `u64` | Missing |
| `i8`, `i16` | Missing |
| `f32`, `f64` | Missing |
| Enums (user-defined) | Missing — would need codegen-generated debug functions |
| Structs (user-defined) | Missing — would need codegen-generated debug functions |
| `Vec[T]` | Missing |
| `Option[T]` | Missing |
| `HashMap[K,V]` | Missing |

### `@[derive(Debug)]` support
- Parser tracks `pending_derive_start` / `pending_derive_count` (Parser.w:35–36).
- AST stores derive metadata via `AstPool.add_type_meta` (Ast.w:538).
- Sema recognizes `"Debug"` as a known trait name (Sema.w:2611).
- **No codegen implementation** for derive(Debug) — the parser and sema infrastructure
  exists but no code generation happens.

### Recommendation for `:?`
Per `format-design.md` §6.6, use **Option A**: codegen generates inline debug
functions per type rather than reflection. This avoids building a runtime reflection
system. The codegen already knows all field names and types at compile time.

---

## 10. Bootstrap Sequence

(Task 5 of format-plan.md)

The compiler source uses f-strings extensively (diagnostic messages). Changes to the
f-string AST node require careful bootstrapping.

### Step 1: AST + Parser + Interim Codegen Fallback

1. Add `NK_FSTRING`, `NK_FSTRING_SPEC` constants to `src/Ast.w`.
2. Replace parser `interp_concat` desugaring with `NK_FSTRING` emission.
3. Add format spec parsing (`parse_format_spec`).
4. Add `check_fstring` in Sema (returns `ty_str`).
5. Add interim codegen: when codegen sees `NK_FSTRING`, desugar it back to
   `OP_CONCAT` chain (same behavior as before, just from a different AST node).
6. Add interim MirLower: when MirLower sees `NK_FSTRING`, desugar similarly.
7. `make build` — the old seed compiler parses f-strings as `OP_CONCAT` chains
   (using old parser). The new stage1 compiler emits `NK_FSTRING` but the new
   codegen handles it via fallback. Stage2 understands `NK_FSTRING`.
8. `make fixpoint` — verify stage2 == stage3.
9. `make install-user` — install as new seed.

**Key constraint:** The compiler source does NOT use format specs (no `{x:08x}`
in compiler code — just bare `{x}`). So the interim fallback only needs to handle
bare holes, which it does by desugaring `NK_FSTRING` back to `OP_CONCAT` + coerce.

### Step 2: Runtime Helpers + Real Codegen

1. Add `with_fmt_*` runtime functions to `runtime/helpers.c`.
2. Replace interim codegen fallback with real `with_fmt_*` calls.
3. Replace interim MirLower fallback with real lowering.
4. `make build` — the seed from Step 1 understands `NK_FSTRING`, so it can
   compile the new codegen code.
5. `make fixpoint`.
6. `make install-user`.

### Step 3: Remove Concat Coercion Hack

1. Convert all ~437 compiler-source `int_to_string(x) ++ str` to `f"{x}"`.
2. Remove `coerce_val_to_str` from `mir_str_concat`.
3. Add sema error for `str ++ non-str`.
4. `make build` — the seed from Step 2 has the `with_fmt_*` runtime, so
   `f"{x}"` in compiler source works.
5. `make fixpoint`.
6. `make install-user`.

Each step produces a new seed that the next step depends on. Do NOT try to
combine steps — that's the bootstrap hell that burned us with `Vec.with_capacity`.
