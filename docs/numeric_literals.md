# Numeric Literals — Suffixes & Contextual Type Inference

## Problem

With's crypto and systems code is drowning in explicit `as` casts
on constants. Every integer literal that isn't `i32` requires a
cast, even when the target type is obvious from context:

```
// Current: 40% of the characters are casts
*(x + 0 as u64) = 0 as u32
let mask = 0x7FFFFFFF as u32
var acc: u64 = 0 as u64
carry = carry >> 31 as u64
acc = acc | ((w as u64) << acc_len as u64)
let diff = (ai as u64) -% (bi as u64) -% (borrow as u64)
```

This is worse than C.

## Solution: Two complementary features

### Feature 1: Numeric literal suffixes

Explicit type annotation on the literal itself:

```
*(x + 0u64) = 0u32
let mask = 0x7FFFFFFFu32
var acc = 0u64
carry = carry >> 31u64
```

### Feature 2: Contextual type inference

The compiler infers literal types from surrounding context,
eliminating most remaining casts:

```
var acc: u64 = 0               // 0 inferred as u64 from annotation
carry = carry >> 31            // 31 inferred as u64 from carry's type
*(x + 0u64) = 0               // 0 inferred as u32 from pointee type
let diff = ai - bi - borrow   // all u64 if any operand is u64
```

### Combined result

The crypto code becomes:

```
// Before (current):
var acc: u64 = 0 as u64
let b = *(src + byte_idx as u64) as u64
acc = acc | (b << acc_len as u64)
let w = acc as u32
*(x + word_idx as u64) = w & 0x7FFFFFFF as u32
acc = acc >> 31 as u64

// After:
var acc: u64 = 0
let b: u64 = *(src + byte_idx as u64)
acc = acc | (b << acc_len)
*(x + word_idx as u64) = acc as u32 & 0x7FFFFFFFu32
acc = acc >> 31
```

The only remaining `as` casts are genuine type conversions
(u64 → u32 truncation, pointer arithmetic), not constant typing.

---

## Feature 1: Numeric Literal Suffixes

### Spec (§4.1 addition)

Integer and float literals may have a type suffix:

```
// Integer suffixes
let a = 0u8          // u8
let b = 255u8        // u8
let c = 0xFFu8       // u8
let d = 1000u16      // u16
let e = 0u32         // u32
let f = 0x7FFFFFFFu32  // u32
let g = 0u64         // u64
let h = 42i8         // i8
let i = 0i16         // i16
let j = 0i32         // i32 (same as bare 0 default)
let k = 0i64         // i64

// Float suffixes
let x = 1.0f32       // f32
let y = 3.14f64      // f64 (same as bare 3.14 default)

// Binary and hex with suffixes
let mask = 0b1111_0000u8    // u8
let big = 0xDEAD_BEEFu32   // u32
```

**Suffix table:**

| Suffix | Type | Notes |
|--------|------|-------|
| `u8` | `u8` | |
| `u16` | `u16` | |
| `u32` | `u32` | |
| `u64` | `u64` | |
| `i8` | `i8` | |
| `i16` | `i16` | |
| `i32` | `i32` | default for unsuffixed integers |
| `i64` | `i64` | |
| `f32` | `f32` | |
| `f64` | `f64` | default for unsuffixed floats |

**Overflow:** If the literal value doesn't fit in the suffix
type, it's a compile error:

```
let x = 256u8    // error: 256 does not fit in u8
let y = -1u32    // error: negative value for unsigned type
```

**Underscore separators:** Allowed anywhere in the numeric
part (not in the suffix): `1_000_000u64`, `0xFF_FFu32`.
Already supported for the numeric part; no change needed.

### Implementation — Lexer (~40 lines)

After lexing a numeric literal (integer or float), check if
the remaining characters form a type suffix:

```
fn lex_number_suffix(self: Lexer) -> TokenType:
    // After lexing digits, check for suffix
    let pos = self.pos
    if self.match_suffix("u8"):  return TK_INT_LIT_U8
    if self.match_suffix("u16"): return TK_INT_LIT_U16
    if self.match_suffix("u32"): return TK_INT_LIT_U32
    if self.match_suffix("u64"): return TK_INT_LIT_U64
    if self.match_suffix("i8"):  return TK_INT_LIT_I8
    if self.match_suffix("i16"): return TK_INT_LIT_I16
    if self.match_suffix("i32"): return TK_INT_LIT_I32
    if self.match_suffix("i64"): return TK_INT_LIT_I64
    if self.match_suffix("f32"): return TK_FLOAT_LIT_F32
    if self.match_suffix("f64"): return TK_FLOAT_LIT_F64
    TK_INT_LIT  // no suffix, default
```

**Disambiguation:** The suffix must not be followed by an
alphanumeric character or underscore. `0u8x` is an error,
not `0u8` followed by identifier `x`. The suffix is greedy:
`0u64` is always a u64 literal, never `0u6` followed by `4`.

**Longest match:** Try longer suffixes first: `u64` before
`u6`, `i32` before `i3`, `f64` before `f6`. Since all valid
suffixes are 2-3 characters and form a closed set, this is
trivial.

**Ambiguity with hex digits:** In hex literals, `u` and `f`
are hex digits. The suffix only applies after the hex digit
sequence ends. `0xFFu32` — `FF` is hex, `u32` is suffix.
`0xFu8` — `F` is hex, `u8` is suffix. The lexer already
knows where the hex digits end (non-hex character), so the
suffix check happens after that boundary.

Edge case: `0xu8` — is this hex `0x` with invalid digit `u8`,
or `0x` missing digits with suffix `u8`? It's a lex error:
`0x` requires at least one hex digit.

### Implementation — Sema (~10 lines)

When checking a literal with a suffix, Sema uses the suffix
type directly instead of defaulting to i32/f64. In
`check_int_literal`:

```
if token_type == TK_INT_LIT_U8:
    return self.ty_u8
if token_type == TK_INT_LIT_U32:
    return self.ty_u32
// ... etc
```

Range checking: verify the literal value fits in the declared
type. Emit error if not.

### Implementation — Codegen (~5 lines)

`emit_int_literal` already handles different integer widths.
The suffix just determines which LLVM integer type to use.
`wl_const_int(wl_int_type(ctx, 8), value, 0)` for u8, etc.
The unsigned flag on `wl_const_int` is set based on the
suffix signedness.

---

## Feature 2: Contextual Type Inference for Literals

### Spec (§4.1 addition)

An unsuffixed integer literal is **polymorphic** — its type
is determined by context. The inference rules, in priority
order:

**Rule 1: Assignment target.** When a literal is assigned to
a typed binding, it adopts the target type:

```
var x: u64 = 0        // 0 is u64
let mask: u32 = 0xFF  // 0xFF is u32
```

**Rule 2: Function parameter.** When a literal is passed to
a function, it adopts the parameter type:

```
fn foo(x: u32): ...
foo(42)                // 42 is u32, not i32
```

**Rule 3: Binary operator peer.** When a literal appears in
a binary expression with a typed operand, it adopts the
peer's type:

```
let x: u64 = get_value()
let y = x + 1         // 1 is u64 (from x)
let z = x >> 31       // 31 is u64 (from x)
let w = x & 0xFF      // 0xFF is u64 (from x)
```

This applies to: `+`, `-`, `*`, `/`, `%`, `+%`, `-%`, `*%`,
`&`, `|`, `^`, `<<`, `>>`, `==`, `!=`, `<`, `>`, `<=`, `>=`.

For shifts (`<<`, `>>`), the shift amount adopts the type of
the value being shifted:

```
let x: u32 = get_value()
let y = x >> 31       // 31 is u32 (from x, the shifted value)
let z = x << 8        // 8 is u32
```

**Rule 4: Return type.** When a literal is a return value or
the last expression in a function, it adopts the function's
return type:

```
fn get_zero() -> u64:
    0                  // 0 is u64
```

**Rule 5: Array element type.** When a literal appears in an
array literal where the element type is known:

```
var buf: [u8; 16] = [0; 16]   // 0 is u8
let data = [1u8, 2, 3, 4]     // 2, 3, 4 are u8 (from first element)
```

**Rule 6: Struct field type.** When a literal is assigned to
a struct field with a known type:

```
type Point = { x: f64, y: f64 }
let p = Point { x: 0, y: 0 }  // 0 is f64
```

**Rule 7: Default.** If no context determines the type, an
unsuffixed integer literal is `i32` and an unsuffixed float
literal is `f64`. This matches current behavior.

### Inference does NOT apply across

- Separate statements (each statement infers independently)
- Through pointer casts (`p + 0` — the 0 needs to match the
  pointer arithmetic type, but this is already handled by the
  pointer addition rule)
- Through generic type parameters (generics instantiate
  separately)

### Implementation — Sema (~80 lines)

The core change is in `check_int_literal` and `check_expr`.
Currently, unsuffixed integer literals immediately get type
`i32`. Instead, they get a temporary "unresolved integer"
type that is resolved when context is available.

**Option A: Bidirectional type propagation (recommended)**

Add an `expected_type` parameter to `check_expr`. When
checking a literal, if `expected_type` is set and is a
numeric type, use it:

```
fn check_expr(self: Sema, node: i32, expected_type: i32) -> i32:
    if kind == NK_INT_LIT:
        if expected_type > 0 and self.is_numeric_type(expected_type):
            // Verify literal fits in expected type
            self.verify_literal_range(node, expected_type)
            return expected_type
        return self.ty_i32  // default

    if kind == NK_BINARY:
        let lhs_ty = self.check_expr(lhs, 0)
        let rhs_ty = self.check_expr(rhs, lhs_ty)  // propagate
        // ...
```

The expected_type flows:

- From `let x: T = expr` → `check_expr(expr, T)`
- From `fn(param: T)` call → `check_expr(arg, T)`
- From binary LHS → RHS: `check_expr(rhs, lhs_type)`
- From binary RHS → LHS: if RHS is typed and LHS is literal,
  re-check LHS with RHS type
- From function return type → tail expression
- From array element type → element expressions
- From struct field type → field value expressions

**Where expected_type is already available:**

- `check_let_binding`: the annotation type is known before
  checking the RHS expression
- `check_call`: each parameter type is known before checking
  the argument expression
- `check_binary`: after checking one side, the type is known
  for the other side
- `check_return`: the function's return type is known
- `check_array_lit`: the element type is known from annotation
  or first element
- `check_struct_lit`: field types are known from the type decl

These are the exact call sites that need `expected_type`
threaded through. Most of them already have the type available
in a local variable — the change is passing it to `check_expr`.

**Option B: Two-pass literal resolution**

First pass: check all expressions, leaving unsuffixed literals
as a special `TY_UNRESOLVED_INT` type. Second pass: resolve
`TY_UNRESOLVED_INT` based on usage context. This is more
complex and not necessary — Option A handles all cases.

### Implementation — Codegen (~10 lines)

Codegen already handles different integer widths via
`emit_int_literal(value, type)`. No change needed if Sema
resolves the type correctly. The literal value and its
resolved type flow through MIR to codegen unchanged.

### Interaction with suffixes

Suffixed literals override inference. If the user writes
`42u8`, the type is `u8` regardless of context. If context
expects `u32`, the suffix wins and Sema emits a type mismatch
error:

```
var x: u32 = 42u8   // error: expected u32, got u8
```

This is intentional — suffixes are explicit and should not be
silently widened. If the user wants a u32, they write `42u32`
or `42`.

---

## Combined Impact on Crypto Code

### Before (current):

```
unsafe fn i31_decode(x: *mut u32, src: *const u8, len: i32):
    var bitlen: u32 = 0 as u32
    var found = 0
    var si = 0
    while si < len:
        let b_raw = *(src + si as u64)
        let b = b_raw as u32
        if found == 0 and b != 0 as u32:
            found = 1
            var top = b
            var bits: u32 = 0 as u32
            while top != 0 as u32:
                bits +%= 1 as u32
                top = top >> 1 as u32
            bitlen = ((len - si - 1) as u32) * 8 as u32 + bits
```

### After (suffixes + inference):

```
unsafe fn i31_decode(x: *mut u32, src: *const u8, len: i32):
    var bitlen: u32 = 0
    var found = 0
    for si in 0..len:
        let b: u32 = *(src + si as u64)
        if found == 0 and b != 0:
            found = 1
            var top = b
            var bits: u32 = 0
            while top != 0:
                bits +%= 1
                top = top >> 1
            bitlen = (len - si - 1) as u32 * 8 + bits
```

The `as` casts that remain are genuine type conversions
(`i32` → `u32` for the length calculation). Everything else
is inferred.

### SHA-256 compress (inner loop):

```
// Before:
w[i] = ssig1(w[i - 2]) +% w[i - 7] +%
       ssig0(w[i - 15]) +% w[i - 16]
let t1 = h +% bsig1(e) +% ch(e, f, g) +%
         SHA256_K[i] +% w[i]

// After: identical — the wrapping ops already infer u32
// from the operands. No change needed here.
```

### Pointer arithmetic:

```
// Before:
*(x + word_idx as u64) = (acc as u32) & 0x7FFFFFFF as u32

// After:
*(x + word_idx as u64) = acc as u32 & 0x7FFFFFFFu32
```

The `word_idx as u64` remains because pointer arithmetic
requires the offset to match the pointer width. This is a
genuine conversion. The `0x7FFFFFFF` gets a suffix because
there's no u32 context to infer from (the `&` operator has
a u32 on the left and the literal on the right — inference
Rule 3 would handle this, but the suffix is clearer).

---

## Implementation Order

```
Phase 1: Suffixes in Lexer (~40 lines)
  - Add suffix detection after numeric literal lexing
  - New token types: TK_INT_LIT_U8, TK_INT_LIT_U16, etc.
  - Handle hex+suffix disambiguation

Phase 2: Suffixes in Sema (~10 lines)
  - Map suffixed token types to sema types
  - Add range checking for suffixed literals

Phase 3: Suffixes in Codegen (~5 lines)
  - Emit correct LLVM integer width from suffix type
  - Verify: crypto code compiles with suffixes, test vectors pass

Phase 4: Inference Rule 1-2 (~20 lines)
  - Thread expected_type through check_let_binding → check_expr
  - Thread expected_type through check_call → check_expr
  - Verify: `var x: u64 = 0` and `foo(42)` work without casts

Phase 5: Inference Rule 3 (~30 lines)
  - Thread peer type through check_binary → check_expr
  - Handle shifts specially (amount inherits value type)
  - Verify: `x + 1` and `x >> 31` work without casts

Phase 6: Inference Rules 4-6 (~20 lines)
  - Return type propagation
  - Array element type propagation
  - Struct field type propagation

Phase 7: Fixpoint and test suite
  - Rewrite crypto modules to remove unnecessary `as` casts
  - Verify all test vectors still pass
  - Fixpoint
```

Total: ~125 lines of compiler changes across Lexer, Sema,
Codegen. Phases 1-3 (suffixes) can ship independently.
Phases 4-6 (inference) can ship incrementally — each rule
is independently useful.

## Test Cases

```
// Suffixes
let a = 0u8
let b = 255u8
let c = 0xFFu32
let d = 0u64
let e = 3.14f32
assert(a == 0 as u8)
assert(c == 255 as u32)

// Suffix overflow errors
// let bad = 256u8          // error: 256 does not fit in u8
// let bad2 = -1u32         // error: negative value for unsigned

// Inference Rule 1: assignment target
var x: u64 = 0              // 0 is u64
var y: u8 = 255             // 255 is u8

// Inference Rule 2: function parameter
fn take_u64(v: u64): pass
take_u64(42)                 // 42 is u64

// Inference Rule 3: binary operator peer
let p: u64 = 100
let q = p + 1               // 1 is u64
let r = p >> 8              // 8 is u64
let s = p & 0xFF            // 0xFF is u64

// Inference Rule 4: return type
fn ret_u64() -> u64: 0      // 0 is u64

// Inference Rule 5: array element
var buf: [u8; 4] = [0; 4]   // 0 is u8

// Inference Rule 6: struct field
type Pair = { x: f64, y: f64 }
let p = Pair { x: 0, y: 0 } // 0 is f64

// Suffix overrides inference
var z: u32 = 42u32          // explicit, matches
// var w: u32 = 42u8        // error: u8 != u32

// Mixed: suffix + inference
let val: u64 = 0xFFu64 | (1 << 32)  // 1 inferred as u64 from |
```