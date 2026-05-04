# c_import Full Zig Parity — Implementation Plan

**Principle:** Follow Zig's design unless there is a major reason to depart.
**Nothing is blocked. We are the actor.**

---

## Phase 0: Immediate Correctness Fix (do first, 20 minutes)

### 0a. Opaque demotion cascade

**Problem:** A struct containing a field whose type was demoted to opaque
(e.g., because it has bitfields) is not itself demoted. The parent struct
gets compiled with a field of opaque type, producing wrong layout.

**Zig's approach:** Track all demoted types. Before emitting any struct,
check every field's type against the demoted set. If any field is opaque,
demote the entire parent struct. Repeat until no new demotions.

**Implementation:**

In `ci_translate_struct`, after building the field list:
1. Maintain a module-level `demoted_types: str` (pipe-delimited, like
   `translated_structs`) across all declarations
2. When a struct is demoted (bitfield, forward decl), add its name to
   `demoted_types`
3. Before emitting a struct body, scan all field types. If any field's
   type name appears in `demoted_types`, demote the parent and add it
   to `demoted_types`
4. Run in a fixpoint loop (demoting a parent may trigger further demotions)

**Files:** `src/CImport.w`
**Verify:** Import a header with nested bitfield structs. Parent struct
should become opaque.

---

## Phase 1: Built-in Types (2 sessions)

### 1a. `usize` / `isize` pointer-width integer types

**Zig:** `usize` and `isize` are fundamental types that adapt to pointer
width. `size_t → usize`, `ssize_t → isize`, `ptrdiff_t → isize`.

**Implementation:**

**Lexer (src/Lexer.w):**
- Add `usize` and `isize` as keywords (alongside `i32`, `i64`, etc.)
- They tokenize as `TK_IDENT` — no new token kind needed

**Sema (src/Sema.w):**
- Add `ty_usize` and `ty_isize` fields to Sema, initialized in `init`
- Register via `add_type(TY_INT, ...)` with pointer-width size
- Add to `primitive_type_by_sym`: `"usize" → ty_usize`, `"isize" → ty_isize`
- Size determined from target: 8 bytes on 64-bit, 4 bytes on 32-bit
- `usize` is unsigned, `isize` is signed
- Implicit conversions: `usize` widens to `u64`, narrows to `u32`;
  `isize` widens to `i64`, narrows to `i32`

**Codegen (src/Codegen.w):**
- Map `ty_usize` → `wl_i64_type(ctx)` on 64-bit, `wl_i32_type(ctx)` on 32-bit
- Query pointer size: `LLVMPointerSize(data_layout)` or hardcode per target triple
- All array indexing, slice length, Vec.len() return `usize`

**CImport (src/CImport.w):**
- Update `ci_map_builtin_typedef`: `size_t → usize`, `ssize_t → isize`,
  `ptrdiff_t → isize`, `intptr_t → isize`, `uintptr_t → usize`

**Verify:** `sizeof[*const i8]() == sizeof[usize]()`

### 1b. `i128` / `u128` types

**Zig:** Native 128-bit integer support.

**Implementation:**

**Sema:** Add `ty_i128`, `ty_u128` as primitive types.
**Codegen:** Map to `LLVMInt128TypeInContext(ctx)`.
**CImport:** Map `__int128 → i128`, `unsigned __int128 → u128`.

Small change — LLVM handles i128 natively. Arithmetic, comparison,
load/store all work without special codegen.

**Verify:** `let x: i128 = 1; let y = x + 1; assert y == 2`

---

## Phase 2: Pointer & Nullability (2 sessions)

### 2a. `Option[*mut T]` — nullable pointers

**Zig:** C pointers are `[*c]T` which is implicitly nullable. Function
pointers are `?*const fn(...)`.

**With approach:** Use `Option[*mut T]` and `Option[*const T]` for
nullable C pointers. This reuses the existing Option type without
inventing a new pointer kind.

**Implementation:**

**Sema (src/Sema.w):**
- Allow `TY_PTR` as a type argument to `Option` generic instantiation
- Currently Option works with struct/enum types; extend to pointers
- `Option[*mut T]` has representation: `{ tag: i32, payload: *mut T }`
- Optimize: null pointer = None, non-null = Some (same as Zig's
  optional pointer optimization — a null pointer IS None)

**Codegen (src/Codegen.w):**
- For `Option[*mut T]`, use bare pointer representation (no tag field)
- `None` → null pointer
- `Some(ptr)` → the pointer value
- `is_some()` → `ptr != null`
- `unwrap()` → the pointer value (with null check in debug mode)
- This matches Zig's optional pointer optimization exactly

**CImport (src/CImport.w):**
- C `T*` parameter/return → `Option[*mut T]`
- C `const T*` → `Option[*const T]`
- C `void*` → `Option[*mut c_void]`
- C function pointers → `Option[*const fn(...) -> R]`
- Exception: `self` parameters in known patterns stay non-optional

**Verify:** `let p: Option[*mut i32] = null; assert p.is_none()`

### 2b. `restrict` → `@[noalias]`

**Zig:** `restrict` → `noalias` on pointer parameters.

**Implementation:**

**Parser (src/Parser.w):**
- Add `@[noalias]` as a parameter attribute
- Store as a flag bit in the parameter's extra data

**Codegen (src/Codegen.w):**
- When declaring a function, if a parameter has the noalias flag,
  call `LLVMAddAttributeAtIndex(fn, param_idx+1, noalias_attr)`

**CImport (src/CImport.w):**
- Detect `restrict` in parameter type spelling (libclang includes it)
- Emit `@[noalias]` prefix on the parameter

**clang_bridge.c:**
- Add `with_cimport_param_is_restrict(session, fn_idx, param_idx) → i32`
  using `clang_Cursor_isRestricted` or type spelling check

**Verify:** Generated LLVM IR shows `noalias` on restricted params.

---

## Phase 3: Unsigned Wrapping Semantics (2 sessions)

### 3a. Wrapping arithmetic operators `+%`, `-%`, `*%`

**Zig:** `+%`, `-%`, `*%` perform wrapping arithmetic. Unsigned types
use wrapping by default in translated C code.

**With approach:** Add wrapping operator variants. These emit LLVM `add`,
`sub`, `mul` without `nsw`/`nuw` flags (allowing wrap).

**Implementation:**

**Lexer (src/Lexer.w):**
- Add `TK_PLUS_PERCENT`, `TK_MINUS_PERCENT`, `TK_STAR_PERCENT`
- Lex `+%`, `-%`, `*%` as new token kinds

**Parser (src/Parser.w):**
- Parse wrapping ops at same precedence as their non-wrapping equivalents
- Emit `OP_ADD_WRAP`, `OP_SUB_WRAP`, `OP_MUL_WRAP` (already defined in Ast.w)

**Codegen (src/Codegen.w):**
- `OP_ADD_WRAP` → `LLVMBuildAdd` (no nsw)
- `OP_SUB_WRAP` → `LLVMBuildSub` (no nsw)
- `OP_MUL_WRAP` → `LLVMBuildMul` (no nsw)
- Regular `OP_ADD` on signed → `LLVMBuildNSWAdd`
- Regular `OP_ADD` on unsigned → `LLVMBuildAdd` (wrapping by default)

### 3b. Unsigned type default wrapping behavior

**Zig:** All arithmetic on unsigned types wraps by default.

**Implementation:**

**Sema (src/Sema.w):**
- Track signedness in type metadata (already exists via `u8`/`u16`/`u32`/`u64`)
- In `check_binary_op`, when both operands are unsigned, silently
  convert `OP_ADD` to `OP_ADD_WRAP` (etc.)
- Signed overflow remains undefined behavior (matches C)

**CImport (src/CImport.w):**
- When emitting expressions on unsigned C types, use `+%`, `-%`, `*%`
  in macro translations
- For regular declarations, the type system handles it automatically
  (unsigned types wrap by default per 3b above)

**Verify:** `let x: u32 = 4294967295; let y = x + 1; assert y == 0`

---

## Phase 4: Function-like Macro Translation (3 sessions)

### 4a. Macro parameter detection

**Implementation:**

**clang_bridge.c / CImport.w:**
- `cc -E -dM` output for function-like macros looks like:
  `#define MAX(a,b) ((a) > (b) ? (a) : (b))`
- Parse the parameter list from the `#define NAME(params)` prefix
- Extract parameter names as a list: `["a", "b"]`
- Each unique parameter becomes a generic type parameter

### 4b. Expression-to-source emitter

**Currently:** `ci_eval_const_expr` evaluates C expressions to integer values.

**New:** Add `ci_translate_macro_body(body: str, params: Vec[str]) -> str`
that translates a C expression to With source code.

**Supported patterns:**
```
Binary ops:     (a) + (b)      → a + b
Comparison:     (a) > (b)      → a > b
Ternary:        c ? t : f      → if c: t else: f
Unary:          -(x)           → 0 - x
Cast:           (int)(x)       → x as i32
Sizeof:         sizeof(T)      → sizeof[T]()
Parens:         ((x))          → x
Identifier:     KNOWN_CONST    → KNOWN_CONST
Literal:        42             → 42
```

**Emission rules:**
- Parameter references emit the With parameter name
- Known macro constants emit the With constant name
- Casts emit `as target_type` with mapped type
- Ternary emits `if cond: then_expr else: else_expr`
- Unknown patterns → return empty string → `comptime_error` fallback

### 4c. Generic function emission

**For each function-like macro with translatable body:**
```
#define MAX(a, b) ((a) > (b) ? (a) : (b))
```
Emit:
```
fn MAX[T](a: T, b: T) -> T:
    if a > b: a else: b
```

**Type parameter assignment:**
- All parameters get type `T` if the macro treats them uniformly
- If the macro compares parameters of different "kinds" (e.g., one is
  always an integer literal), use `T`, `U`, etc.
- Simple heuristic: all params → `T` (works for 90% of macros)

**Files:** `src/CImport.w`, `runtime/clang_bridge.c` (macro param extraction)

---

## Phase 5: Type Reflection Intrinsics (1 session)

### 5a. `@TypeOf(expr)`

**Zig:** `@TypeOf(expr)` returns the compile-time type of an expression.

**Implementation:**

**Parser (src/Parser.w):**
- Parse `@TypeOf(expr)` in type position
- Emit `NK_TYPEOF` node, data0 = inner expression node

**Sema (src/Sema.w):**
- In `resolve_type_expr`, handle `NK_TYPEOF`:
  1. Type-check the inner expression
  2. Return its resolved type
  3. The inner expression is never compiled (type-only evaluation)

**Codegen:** No codegen needed — `@TypeOf` is fully erased at compile time.

**Use in c_import:** Function-like macro return types:
```
fn MACRO[T](x: T) -> @TypeOf(x):
    ...
```

---

## Phase 6: Struct Layout Fidelity (2 sessions)

### 6a. `@[repr(C)]` on all c_import structs

**Zig:** All translated structs use `extern` layout (C ABI).

**Implementation:**

All c_import structs already go through `declare_struct_type` in Codegen.
Verify that field ordering matches C (no reordering for alignment).
LLVM's `LLVMStructSetBody` with `packed=0` uses C-compatible layout
when field types match. Add explicit `@[repr(C)]` attribute for
documentation and to prevent future reordering optimizations.

**Parser/Codegen:**
- Add `TDK_FLAG_REPR_C = 32` to Ast.w
- c_import sets this flag on all emitted structs
- Codegen reads the flag (currently a no-op since LLVM default is C layout,
  but reserves the bit for when With adds layout optimizations)

### 6b. `@[align(N)]` field attribute

**Zig:** Per-field `align(N)` from C's `__attribute__((aligned(N)))`.

**Implementation:**

**Parser (src/Parser.w):**
- Parse `@[align(N)]` before a struct field declaration
- Store alignment value in the field's extra data (add a 4th field slot:
  `name, type_node, default, alignment`)

**Sema (src/Sema.w):**
- Store per-field alignment in type_extra alongside field name and type

**Codegen (src/Codegen.w):**
- When emitting struct body, if a field has explicit alignment,
  insert padding bytes before the field to achieve the alignment
- Or: use LLVM's `LLVMSetAlignment` on loads/stores to aligned fields

**clang_bridge.c:**
- Add `with_cimport_field_alignment(session, struct_idx, field_idx) → i32`
- Uses `clang_Type_getAlignOf(field_type)` and compares to natural alignment
- Only emit `@[align(N)]` when alignment differs from natural

**CImport (src/CImport.w):**
- Query field alignment for each field
- Emit `@[align(N)]` when non-natural

### 6c. Packed struct detection from `__attribute__` and `#pragma pack`

**Current:** Detects alignment-1 structs via `clang_Type_getAlignOf`.

**Extend:**
- Also detect `__attribute__((packed))` directly via
  `clang_Cursor_getAttrs` or by checking if struct alignment < max
  field alignment
- Handle `#pragma pack(push, N)` — libclang includes the effect in
  type layout, so `clang_Type_getAlignOf` already captures it

**Verify:** Import a header with `#pragma pack(push, 1)` struct.
Check that With emits `@[packed]`.

---

## Phase 7: Calling Conventions (1 session)

### 7a. `@[callconv("X")]` on extern functions

**Zig:** Preserves calling convention from C declarations.

**Implementation:**

**Parser (src/Parser.w):**
- Add `@[callconv("stdcall")]` etc. as function attribute
- Store as a string sym in the function declaration's extra data

**Ast.w:**
- Add `FN_FLAG_CALLCONV = 64` or store callconv separately

**Codegen (src/Codegen.w):**
- In `declare_extern_fn`, if callconv is set:
  ```
  LLVMSetFunctionCallConv(function, conv_id)
  ```
- Mapping: `"c" → LLVMCCallConv`, `"stdcall" → LLVMX86StdcallCallConv`,
  `"fastcall" → LLVMX86FastcallCallConv`, `"thiscall" → LLVMX86ThisCallCallConv`,
  `"win64" → LLVMWin64CallConv`

**clang_bridge.c:**
- Add `with_cimport_fn_calling_conv(session, idx) → str`
- Uses `clang_getFunctionTypeCallingConv(fn_type)`
- Returns `"c"` for default, `"stdcall"`, `"fastcall"`, etc.

**CImport (src/CImport.w):**
- Query calling convention for each function
- Emit `@[callconv("stdcall")]` when non-default

---

## Phase 8: Builtin Function Mapping (2 sessions)

### 8a. Top 20 GCC/Clang builtins

**Zig:** Maps 76+ builtins via `src/zig_clang_builtins.zig`.

**Implementation approach:** Add a mapping table in CImport.w. When a
`static inline` function body (Phase 4 of the previous plan) or macro
references a `__builtin_X`, replace with the With equivalent.

**Tier 1 (essential — appear in common headers):**
```
__builtin_expect(x, v)        → x  (hint only, no semantic effect)
__builtin_unreachable()       → unreachable
__builtin_trap()              → abort()
__builtin_offsetof(T, field)  → offsetof[T]("field")
__builtin_memcpy(d, s, n)     → memcpy(d, s, n)
__builtin_memset(d, c, n)     → memset(d, c, n)
__builtin_memmove(d, s, n)    → memmove(d, s, n)
__builtin_strlen(s)           → strlen(s)
```

**Tier 2 (bit manipulation — appear in crypto/hash headers):**
```
__builtin_clz(x)              → LLVM intrinsic @llvm.ctlz.i32
__builtin_ctz(x)              → LLVM intrinsic @llvm.cttz.i32
__builtin_popcount(x)         → LLVM intrinsic @llvm.ctpop.i32
__builtin_bswap16(x)          → LLVM intrinsic @llvm.bswap.i16
__builtin_bswap32(x)          → LLVM intrinsic @llvm.bswap.i32
__builtin_bswap64(x)          → LLVM intrinsic @llvm.bswap.i64
```

**Tier 3 (variadic — needed for va_list headers):**
```
__builtin_va_list             → type va_list = opaque
__builtin_va_start(ap, last)  → va_start(ap, last)
__builtin_va_end(ap)          → va_end(ap)
__builtin_va_arg(ap, T)       → va_arg[T](ap)
__builtin_va_copy(d, s)       → va_copy(d, s)
```

**For Tier 2:** Add LLVM intrinsic wrappers to the runtime:
```c
// runtime/helpers.c
int32_t with_builtin_clz(int32_t x) { return __builtin_clz(x); }
int32_t with_builtin_ctz(int32_t x) { return __builtin_ctz(x); }
// etc.
```

Or emit LLVM intrinsic calls directly from Codegen (cleaner).

### 8b. `offsetof[T]("field")` intrinsic

**Zig:** `@offsetOf(T, "field")` returns the byte offset of a field.

**Implementation:**
- Parser: `offsetof[T]("field")` parsed like `sizeof[T]()`
- Sema: Returns `usize`
- Codegen: Use `LLVMOffsetOfElement(data_layout, struct_type, field_idx)`

---

## Phase 9: Complex Numbers and Edge Cases (1 session)

### 9a. `_Complex` → repr(C) struct

**Zig:** Complex types are TODO (not fully supported).

**With advantage:** We can do better. Emit:
```
@[repr(C)]
type Complex32 = { real: f32, imag: f32 }

@[repr(C)]
type Complex64 = { real: f64, imag: f64 }
```

**CImport:** Map `_Complex float → Complex32`, `_Complex double → Complex64`.
Add to prelude.

### 9b. Scope-aware anonymous type naming

**Current:** Flat namespace with `parent_field` naming.

**Extend:** Track nesting depth for anonymous structs/unions:
```c
struct Outer {
    union {
        struct { int x; int y; } point;
        struct { float r; float g; } color;
    };
};
```
→
```
type Outer_anon_0_point = { x: i32, y: i32 }
type Outer_anon_0_color = { r: f32, g: f32 }
type Outer_anon_0 = union { point: Outer_anon_0_point, color: Outer_anon_0_color }
type Outer = { anon_0: Outer_anon_0 }
```

Track: `parent_name_stack: Vec[str]` during recursive translation.

### 9c. Name pre-population (two-pass)

**Zig:** Pre-populates all names before translating any declarations.

**Implementation:**
1. First pass over all declarations: register names in dedup table
   - Functions, variables → strong names
   - Structs, unions, enums → weak names (allow typedef override)
   - Typedefs → strong names, override weak struct names
2. Second pass: translate declarations using pre-populated names

This prevents name collisions between a struct and its typedef alias
(a common C pattern: `typedef struct Foo { ... } Foo;`).

**Files:** `src/CImport.w` — restructure `process_c_import` into two passes.

---

## Phase 10: FAM Getter and Final Polish (1 session)

### 10a. Flexible Array Member getter

**Zig:** Generates `pub fn items(self: *T) [*]T` for FAM fields.

**With:** Generate a method that returns a pointer past the fixed fields:
```
fn StructName.items(self: *mut StructName) -> *mut ElemType:
    unsafe:
        let base = self as *mut u8
        let offset = sizeof[StructName]()
        (base + offset) as *mut ElemType
```

Detect FAM: last field with array size 0 or 1 (both are C FAM patterns).

### 10b. Nullable pointer optimization verification

Verify that `Option[*mut T]` uses the null-pointer representation
(no tag field needed — null IS None). This should fall out naturally
from the Phase 2 implementation but needs explicit testing.

### 10c. Final verification against real headers

Test suite:
```
use c_import("stdio.h")           // FILE*, printf, scanf
use c_import("stdlib.h")          // malloc, free, qsort
use c_import("string.h")         // memcpy, strlen
use c_import("math.h", link: "m") // sin, cos, M_PI
use c_import("unistd.h")         // read, write, fork
use c_import("fcntl.h")          // open, O_RDONLY
use c_import("sys/stat.h")       // stat, fstat
use c_import("errno.h")          // errno
use c_import("signal.h")         // signal, SIGINT
use c_import("pthread.h", link: "pthread")  // threads
use c_import("dirent.h")         // opendir, readdir
use c_import("sys/socket.h")     // socket, bind, listen
use c_import("netinet/in.h")     // sockaddr_in
use c_import("arpa/inet.h")      // inet_pton
```

Each must compile without errors. Write a smoke test that calls
at least one function from each header.

---

## Implementation Order

```
Session  Item                                 Files
──────── ──────────────────────────────────── ─────────────────────────────────────
   1     0a. Opaque demotion cascade          CImport.w
         1a. usize/isize types               Lexer.w, Sema.w, Codegen.w, CImport.w

   2     1b. i128/u128 types                 Sema.w, Codegen.w, CImport.w
         2b. restrict → @[noalias]           Parser.w, Codegen.w, clang_bridge.c, CImport.w

   3     2a. Option[*mut T] nullable ptrs    Sema.w, Codegen.w, CImport.w
         10b. Null pointer optimization      Codegen.w (verify)

   4     3a. Wrapping operators +% -% *%     Lexer.w, Parser.w, Codegen.w
         3b. Unsigned default wrapping       Sema.w, Codegen.w

   5     4a. Macro parameter detection       CImport.w, clang_bridge.c
         4b. Expression-to-source emitter    CImport.w

   6     4c. Generic function emission       CImport.w
         5a. @TypeOf intrinsic               Parser.w, Sema.w

   7     6a. @[repr(C)] on c_import structs  Ast.w, Parser.w, CImport.w
         6b. @[align(N)] field attribute     Parser.w, Sema.w, Codegen.w, clang_bridge.c

   8     6c. Packed struct detection extend  clang_bridge.c, CImport.w
         7a. @[callconv] attribute           Parser.w, Codegen.w, clang_bridge.c, CImport.w

   9     8a. Builtin mapping (Tier 1+2)     CImport.w, runtime/helpers.c, Codegen.w
         8b. offsetof intrinsic             Parser.w, Sema.w, Codegen.w

  10     9a. _Complex as struct             CImport.w, prelude
         9b. Scope-aware anon naming        CImport.w, clang_bridge.c

  11     9c. Name pre-population two-pass   CImport.w
         10a. FAM getter generation         CImport.w

  12     10c. Final header verification     test suite
         Release and publish
```

**Each session:** build, fixpoint, test, commit, push.
**Total: 12 sessions to full Zig parity.**