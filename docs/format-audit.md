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

## 7. Migration Scope

`str ++ non-str` sites using `int_to_string()` in compiler source: **~367 call sites**
across `src/compiler/Backend.w`, `src/Sema.w`, `src/Codegen.w`, `src/Parser.w`,
`src/main_emit_temp.w`, and other files. These will all need conversion to f-strings
in Phase 6.
