# Systems Programming Features — Specification & Implementation Notes

*Proposed additions to the With Language Specification*

---

## 1. Saturating Arithmetic Operators

### 1.1 Specification

With provides saturating arithmetic operators that clamp the result to the type's representable range instead of panicking on overflow or wrapping.

```
+|    saturating add
-|    saturating subtract
*|    saturating multiply
```

When the mathematical result exceeds the type's maximum, the result is the maximum. When it falls below the minimum, the result is the minimum.

```
let x: u8 = 250
let y: u8 = x +| 20        // 255 (clamped, not 14 or panic)

let a: i8 = 120
let b: i8 = a +| 20        // 127 (clamped)

let c: i8 = -120
let d: i8 = c -| 20        // -128 (clamped)

let e: u8 = 5
let f: u8 = e -| 10        // 0 (clamped, not 251 or panic)
```

Saturating operators are defined for all integer types: `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`. They are not defined for floating-point types (floats already saturate to ±infinity per IEEE 754).

**Operator precedence:** Saturating operators have the same precedence as their non-saturating counterparts. `a +| b * c` is `a +| (b * c)`.

**Assignment variants:** Compound assignment forms are supported.

```
var hp: u8 = 200
hp +|= 100      // 255
hp -|= 50       // 205
```

**Interaction with wrapping operators:** All three overflow modes can coexist.

```
x + y       // checked: panic on overflow (default)
x +% y      // wrapping: two's complement wrap
x +| y      // saturating: clamp to min/max
```

### 1.2 Implementation Notes

**Parser:** Add `TK_PLUS_SAT`, `TK_MINUS_SAT`, `TK_STAR_SAT` token kinds for `+|`, `-|`, `*|`. Map to `OP_ADD_SAT`, `OP_SUB_SAT`, `OP_MUL_SAT` in the binary operator table. Same precedence as `+`/`-`/`*` respectively. Add `TK_PLUS_SAT_EQ`, `TK_MINUS_SAT_EQ`, `TK_STAR_SAT_EQ` for compound assignment.

**Lexer:** Two-character tokens. `+` followed by `|` produces `TK_PLUS_SAT`. Ambiguity with bitwise OR: the lexer must check whether `|` follows `+`, `-`, or `*` specifically. There is no standalone `|` in With (bitwise OR is `bitor` or a function), so no conflict.

**Sema:** Type-check identically to regular arithmetic. Both operands must be the same integer type (or implicitly widenable). Result type matches operands. Reject float operands with error: "saturating arithmetic is not defined for floating-point types."

**MIR:** Add `OP_ADD_SAT`, `OP_SUB_SAT`, `OP_MUL_SAT` to the operator enum. Lower as `RK_BIN_OP` with the saturating op code.

**Codegen:** Map to LLVM intrinsics:

| With op | Signed LLVM intrinsic | Unsigned LLVM intrinsic |
|---------|-----------------------|-------------------------|
| `+\|` | `llvm.sadd.sat.iN` | `llvm.uadd.sat.iN` |
| `-\|` | `llvm.ssub.sat.iN` | `llvm.usub.sat.iN` |
| `*\|` | `llvm.smul.fix.sat.iN` (scale=0) | `llvm.umul.fix.sat.iN` (scale=0) |

For multiply, LLVM's fixed-point saturating multiply with scale=0 gives integer saturating behavior. Alternatively, codegen can emit a widening multiply followed by a clamp: multiply in double-width, then clamp to the target range. The widening approach avoids the less common `llvm.smul.fix.sat` intrinsic.

**Runtime:** No runtime functions needed. Everything is LLVM IR.

**Bootstrap:** Single-step. Add the operators and their codegen in one build. The compiler source doesn't use saturating arithmetic, so no bootstrap dependency.

---

## 2. Bit Manipulation Builtins

### 2.1 Specification

With provides built-in functions for common bit manipulation operations. These map to single hardware instructions on most architectures.

```
popcount(x)       // count set bits
byteswap(x)       // reverse byte order (endian swap)
bitreverse(x)     // reverse all bits
clz(x)            // count leading zeros
ctz(x)            // count trailing zeros
```

All operate on integer types only. The argument type determines the operation width.

**`popcount`** — Returns the number of 1-bits in the value.

```
popcount(0b10110100u8)     // 4
popcount(0u32)             // 0
popcount(0xFFFF_FFFFu32)   // 32
```

Return type: `i32` regardless of input width.

**`byteswap`** — Reverses the byte order of a multi-byte integer. Converts between big-endian and little-endian representations.

```
byteswap(0x1234u16)             // 0x3412
byteswap(0x12345678u32)         // 0x78563412
byteswap(0x0102030405060708u64) // 0x0807060504030201
```

Return type: same as input type. Not defined for `u8`/`i8` (single byte has no byte order). Compile-time error for 8-bit types.

**`bitreverse`** — Reverses the order of all bits. Bit 0 becomes the MSB, bit 1 becomes MSB-1, etc.

```
bitreverse(0b10110000u8)   // 0b00001101
bitreverse(0x80000000u32)  // 0x00000001
```

Return type: same as input type.

**`clz`** — Counts the number of leading zero bits (from the MSB). Returns the type's bit width if the value is zero.

```
clz(0b00010000u8)    // 3
clz(1u32)            // 31
clz(0u32)            // 32
```

Return type: `i32`.

**`ctz`** — Counts the number of trailing zero bits (from the LSB). Returns the type's bit width if the value is zero.

```
ctz(0b00010000u8)    // 4
ctz(1u32)            // 0
ctz(0u32)            // 32
```

Return type: `i32`.

**Compile-time evaluation:** All bit manipulation builtins can be evaluated at compile time when the argument is a constant. The compiler folds them to integer literals.

### 2.2 Implementation Notes

**Parser/Sema:** These are built-in functions, not operators. They are recognized by name during sema's function resolution, similar to `sizeof` and `alignof`. No special parser support needed — they parse as regular function calls.

**Sema:** Validate that the argument is an integer type. For `byteswap`, reject 8-bit types. Return type is `i32` for `popcount`/`clz`/`ctz`, same-as-input for `byteswap`/`bitreverse`.

**MIR:** Add `MIR_INTRINSIC_POPCOUNT`, `MIR_INTRINSIC_BYTESWAP`, `MIR_INTRINSIC_BITREVERSE`, `MIR_INTRINSIC_CLZ`, `MIR_INTRINSIC_CTZ` to the intrinsic enum.

**Codegen:** Direct LLVM intrinsic calls:

| With builtin | LLVM intrinsic |
|-------------|----------------|
| `popcount(x)` | `llvm.ctpop.iN` |
| `byteswap(x)` | `llvm.bswap.iN` |
| `bitreverse(x)` | `llvm.bitreverse.iN` |
| `clz(x)` | `llvm.ctlz.iN(x, false)` |
| `ctz(x)` | `llvm.cttz.iN(x, false)` |

The `false` argument to `ctlz`/`cttz` means "the result is defined when input is zero" (returns bit width). This is safer than the `true` variant which is UB on zero.

**LLVM wrapper:** Add `wl_build_ctpop`, `wl_build_bswap`, `wl_build_bitreverse`, `wl_build_ctlz`, `wl_build_cttz` to the LLVM bridge. Each is a thin wrapper around `LLVMBuildCall` with the appropriate intrinsic function.

**Bootstrap:** Single-step. The compiler source doesn't use these builtins.

---

## 3. Min, Max, Abs Builtins

### 3.1 Specification

```
min(a, b)     // smaller of two values
max(a, b)     // larger of two values
abs(x)        // absolute value
```

**`min` and `max`** — Return the smaller or larger of two values. Both arguments must be the same type. Defined for all integer and floating-point types.

```
min(3, 7)          // 3
max(3, 7)          // 7
min(3.14, 2.71)    // 2.71
max(-1, 0)         // 0
```

For floats, `min` and `max` follow IEEE 754-2019 minimum/maximum semantics: NaN is never selected unless both operands are NaN.

Return type: same as the input type.

**`abs`** — Returns the absolute value. For signed integers, the return type is the corresponding unsigned type to avoid the classic `abs(INT_MIN)` undefined behavior.

```
abs(-42)           // 42     (i32 → u32)
abs(42)            // 42     (i32 → u32)
abs(-3.14)         // 3.14   (f64 → f64)
```

For signed integers: the return type is the unsigned type of the same width. `abs(x: i32) → u32`, `abs(x: i8) → u8`. This means `abs(i32.min)` returns `2147483648u32` instead of being undefined.

For unsigned integers: identity function. `abs(x: u32) → u32`.

For floats: return type is the same float type. `abs(x: f64) → f64`. Clears the sign bit per IEEE 754.

### 3.2 Implementation Notes

**Codegen — min/max for integers:** Use LLVM `icmp` + `select`:

```llvm
%cmp = icmp slt i32 %a, %b     ; or ult for unsigned
%result = select i1 %cmp, i32 %a, i32 %b
```

**Codegen — min/max for floats:** Use LLVM `llvm.minnum` / `llvm.maxnum` intrinsics. These implement IEEE 754 minNum/maxNum which propagate NaN correctly.

**Codegen — abs for integers:** Use LLVM's `llvm.abs.iN(x, false)` intrinsic. The `false` flag means "return is defined for INT_MIN" (returns the unsigned representation). Then zero-extend or bitcast to unsigned return type.

**Codegen — abs for floats:** Use LLVM `llvm.fabs` intrinsic.

**Bootstrap:** Single-step.

---

## 4. Packed Structs with Bit-Level Fields

### 4.1 Specification

The existing `@[repr(packed)]` attribute removes padding but still aligns fields to byte boundaries. A new `@[bitpacked]` attribute provides bit-level packing where fields occupy exactly their declared bit width with no padding at any level.

Bit-packed structs require that field types have a known bit width. Standard integer types (`u8`, `i32`, etc.) use their full width. Non-byte-sized integer types provide sub-byte fields.

```
@[bitpacked]
type Flags = {
    enabled: bool,         // 1 bit
    priority: u3,          // 3 bits
    mode: u4,              // 4 bits
}
// Total: 8 bits = 1 byte. sizeof[Flags]() == 1
```

```
@[bitpacked]
type IpHeader = {
    version: u4,           // 4 bits
    ihl: u4,               // 4 bits
    dscp: u6,              // 6 bits
    ecn: u2,               // 2 bits
    total_length: u16,     // 16 bits
    identification: u16,   // 16 bits
    flags_frag: u16,       // 16 bits
    ttl: u8,               // 8 bits
    protocol: u8,          // 8 bits
    checksum: u16,         // 16 bits
    src_addr: u32,         // 32 bits
    dst_addr: u32,         // 32 bits
}
// Total: 160 bits = 20 bytes
```

**Rules:**

1. Fields are laid out MSB-first (network byte order) from first field to last, with no gaps.
2. The total size is `ceil(sum_of_field_bits / 8)` bytes.
3. All field types must have a known bit width. Pointers, slices, strings, structs (except nested bitpacked), and Vecs are not allowed as fields. Compile-time error: "bitpacked fields must be integer, bool, or bitpacked struct type."
4. `bool` occupies 1 bit. `true` is `1`, `false` is `0`.
5. Non-byte-sized integer types (`u1` through `u7`, `u3`, `u5`, etc.) are valid field types.
6. Nested `@[bitpacked]` structs are allowed and their bits are inlined.

**Field access:** Reading and writing bitpacked fields uses the same dot syntax as regular structs. The compiler generates the necessary shift-and-mask operations.

```
var flags = Flags { enabled: true, priority: 5, mode: 12 }
let p = flags.priority        // extracts bits, returns u3
flags.mode = 3                // inserts bits
```

**Pointers to bitpacked fields:** Taking a pointer to a bitpacked field is a compile-time error. The field may not be byte-aligned, so a regular pointer cannot represent its address.

```
let f = Flags { enabled: true, priority: 5, mode: 12 }
let p = &f.priority     // error: cannot take address of bitpacked field
```

**Casting:** A bitpacked struct can be cast to its backing integer type with `as`:

```
let flags = Flags { enabled: true, priority: 5, mode: 12 }
let byte = flags as u8    // 0b_1_101_1100 = 0xBC
```

The backing integer type is the smallest unsigned integer that holds all bits: `u8` for 1-8 bits, `u16` for 9-16, `u32` for 17-32, `u64` for 33-64.

Casting the other direction (integer to bitpacked struct) is also valid:

```
let flags = 0xBCu8 as Flags
// flags.enabled == true, flags.priority == 5, flags.mode == 12
```

### 4.2 Non-Byte-Sized Integer Types

To support bitpacked structs, With adds integer types with non-standard widths:

```
u1, u2, u3, u4, u5, u6, u7     // unsigned sub-byte
i1, i2, i3, i4, i5, i6, i7     // signed sub-byte (rarely useful)
u12, u21, u24                    // selected wider non-standard widths
```

Non-byte-sized integers are primarily useful as bitpacked struct fields. When used as local variables, they are stored in the next larger standard-width register (e.g., `u3` occupies an `i32` register with the upper bits zeroed).

Arithmetic on non-byte-sized integers works normally. The result is masked to the type's range:

```
let x: u3 = 7
let y: u3 = x + 1    // panic in debug (overflow), wraps to 0 with +%
```

**Supported widths for launch:** `u1` through `u7`, `u12`, `u21`, `u24`. Other widths can be added post-launch. Full arbitrary-width integers (Zig-style `u0` through `u65535`) are not planned — the complexity isn't worth it for the use cases With targets.

### 4.3 Implementation Notes

**Type system:** Add `TY_INT_NONSTANDARD` or extend `TY_INT` to accept arbitrary bit widths in `d0`. Store the bit width directly. In sema, validate that bitpacked fields only use types with known bit widths.

**Codegen — field access:** For a bitpacked struct stored as its backing integer:

```
// Read field at bit_offset with bit_width:
%shifted = lshr i32 %backing, bit_offset
%masked = and i32 %shifted, (1 << bit_width) - 1

// Write field:
%cleared = and i32 %backing, ~(((1 << bit_width) - 1) << bit_offset)
%value_shifted = shl i32 %value, bit_offset
%result = or i32 %cleared, %value_shifted
```

**Codegen — struct literal:** Construct the backing integer by OR-ing shifted field values:

```
%f0 = shl i8 %enabled, 7       // bit 7
%f1 = shl i8 %priority, 4      // bits 6-4
%f2 = and i8 %mode, 0x0F       // bits 3-0
%backing = or i8 (or i8 %f0, %f1), %f2
```

**LLVM representation:** Store bitpacked structs as `iN` where N is the total bit count. For `Flags` (8 bits), use `i8`. For `IpHeader` (160 bits), use `i160` — LLVM supports arbitrary-width integers.

**Bootstrap:** Two-step. Step 1: add `@[bitpacked]` attribute parsing and the non-standard integer types to sema (reject in codegen with a stub error). Step 2: add codegen for field access, struct literal construction, and integer casting.

---

## 5. Atomic Operations

### 5.1 Specification

The `Atomic[T]` type provides lock-free atomic operations on integer and pointer types. `T` must be an integer type (`i32`, `i64`, `u32`, `u64`, etc.) or a pointer type.

```
use std.sync.Atomic

var counter: Atomic[i32] = Atomic.new(0)

counter.store(42, .release)
let val = counter.load(.acquire)

let old = counter.fetch_add(1, .seq_cst)        // returns old value
let swapped = counter.compare_exchange(
    expected: 42,
    desired: 43,
    success: .seq_cst,
    failure: .acquire,
)
```

**Memory orderings:**

```
.relaxed       // no ordering guarantees (fastest)
.acquire       // reads after this see writes before a paired release
.release       // writes before this are visible after a paired acquire
.acq_rel       // both acquire and release
.seq_cst       // total order across all threads (strongest, default)
```

**Operations:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `Atomic.new(val)` | `fn(T) -> Atomic[T]` | Create with initial value |
| `.load(order)` | `fn(Order) -> T` | Atomic read |
| `.store(val, order)` | `fn(T, Order) -> void` | Atomic write |
| `.swap(val, order)` | `fn(T, Order) -> T` | Exchange, return old |
| `.fetch_add(val, order)` | `fn(T, Order) -> T` | Add, return old |
| `.fetch_sub(val, order)` | `fn(T, Order) -> T` | Subtract, return old |
| `.fetch_and(val, order)` | `fn(T, Order) -> T` | Bitwise AND, return old |
| `.fetch_or(val, order)` | `fn(T, Order) -> T` | Bitwise OR, return old |
| `.fetch_xor(val, order)` | `fn(T, Order) -> T` | Bitwise XOR, return old |
| `.fetch_min(val, order)` | `fn(T, Order) -> T` | Min, return old |
| `.fetch_max(val, order)` | `fn(T, Order) -> T` | Max, return old |
| `.compare_exchange(expected, desired, success, failure)` | `fn(T, T, Order, Order) -> Result[T, T]` | CAS, strong |
| `.compare_exchange_weak(expected, desired, success, failure)` | `fn(T, T, Order, Order) -> Result[T, T]` | CAS, weak (may spuriously fail) |

`compare_exchange` returns `Ok(old_value)` on success (the value was `expected` and has been replaced with `desired`) or `Err(actual_value)` on failure (the value was not `expected`).

**Atomic fences:**

```
use std.sync.fence

fence(.acquire)
fence(.release)
fence(.acq_rel)
fence(.seq_cst)
```

### 5.2 Implementation Notes

**Type representation:** `Atomic[T]` is a generic struct containing a single field of type `T`. It is `@[repr(C)]` with the same alignment as `T`. In LLVM IR, it is simply `T` — atomicity is a property of the operations, not the storage.

**Codegen:** Each method maps to an LLVM atomic instruction:

| Method | LLVM instruction |
|--------|-----------------|
| `.load(order)` | `load atomic T, ptr %p <order>` |
| `.store(val, order)` | `store atomic T %val, ptr %p <order>` |
| `.swap(val, order)` | `atomicrmw xchg ptr %p, T %val <order>` |
| `.fetch_add(val, order)` | `atomicrmw add ptr %p, T %val <order>` |
| `.fetch_sub(val, order)` | `atomicrmw sub ptr %p, T %val <order>` |
| `.fetch_and(val, order)` | `atomicrmw and ptr %p, T %val <order>` |
| `.fetch_or(val, order)` | `atomicrmw or ptr %p, T %val <order>` |
| `.fetch_xor(val, order)` | `atomicrmw xor ptr %p, T %val <order>` |
| `.fetch_min(val, order)` | `atomicrmw min/umin ptr %p, T %val <order>` |
| `.fetch_max(val, order)` | `atomicrmw max/umax ptr %p, T %val <order>` |
| `.compare_exchange(e, d, s, f)` | `cmpxchg ptr %p, T %e, T %d <s> <f>` |
| `fence(order)` | `fence <order>` |

The LLVM memory ordering enum values: `monotonic` = relaxed, `acquire`, `release`, `acq_rel`, `seq_cst`.

**LLVM wrapper additions:** `wl_build_atomic_load`, `wl_build_atomic_store`, `wl_build_atomic_rmw`, `wl_build_cmpxchg`, `wl_build_fence`.

**Sema:** Validate that `T` is an integer or pointer type. Validate ordering constraints: `.store` cannot use `.acquire` or `.acq_rel`. `.load` cannot use `.release` or `.acq_rel`. `compare_exchange` failure ordering cannot be stronger than success ordering, and cannot be `.release` or `.acq_rel`.

**MIR:** Treat `Atomic[T]` methods as intrinsics, similar to `Vec` methods. Add `MIR_INTRINSIC_ATOMIC_LOAD` through `MIR_INTRINSIC_ATOMIC_CMPXCHG`.

---

## 6. Custom Alignment

### 6.1 Specification

Variables, struct fields, and function parameters can specify custom alignment using the `align` attribute.

**On struct fields:**

```
type CacheLine = {
    @[align(64)]
    data: [64]u8,
}
```

**On variables:**

```
@[align(16)]
var buffer: [256]u8 = [0; 256]
```

**On function parameters (rare, for SIMD):**

```
fn process(@[align(16)] data: *[4]f32):
    // data is guaranteed 16-byte aligned
```

**Rules:**

1. Alignment must be a power of two.
2. Alignment must be at least the natural alignment of the type.
3. Alignment cannot exceed a platform-defined maximum (typically 4096 or 65536).
4. Violations are compile-time errors.

**`alignof` builtin:** Already exists in the spec as `align_of[T]()`. No changes needed.

**Aligned allocation:** When a local variable has custom alignment, the compiler emits an aligned alloca. When a heap-allocated struct has an aligned field, the allocator must respect it. The `Allocator` trait already has an `alloc_aligned` method.

### 6.2 Implementation Notes

**Parser:** `@[align(N)]` is an attribute, parsed using the existing attribute system. The attribute takes a single integer constant argument.

**Sema:** Validate the alignment value: must be a compile-time integer constant, must be a power of two, must be >= natural alignment of the annotated type.

**AST:** Store alignment as an attribute on the field/variable/parameter node. The attribute system already supports key-value attributes.

**Codegen — local variables:** Use `wl_build_alloca_aligned(builder, type, alignment)` or set alignment after alloca:

```llvm
%buf = alloca [256 x i8], align 16
```

**Codegen — struct fields:** When laying out structs in `create_struct_type`, insert padding before aligned fields to satisfy the alignment requirement. The struct's own alignment becomes the max of all field alignments.

**Codegen — function parameters:** Emit LLVM's `align` attribute on the parameter:

```llvm
define void @process(ptr align 16 %data) {
```

---

## 7. Inline Assembly

### 7.1 Specification

The `asm` expression embeds target-specific assembly instructions. It requires `unsafe` context.

```
let sp: u64 = unsafe:
    asm("mov %sp, {out}" : out("x0") -> u64)

unsafe:
    asm("dmb sy" ::: "memory")
```

**Full syntax:**

```
asm(template : outputs : inputs : clobbers)
```

Each section is optional. A trailing `:` section can be omitted. The `volatile` modifier prevents the optimizer from eliminating or reordering the assembly.

**Template:** A string literal containing assembly instructions. Register placeholders use `{name}` syntax, where `name` matches an output or input binding.

**Outputs:** Comma-separated list of `name(constraint) -> type`. The assembly writes to these.

```
asm("mrs {out}, CNTPCT_EL0" : out("x0") -> u64)
```

**Inputs:** Comma-separated list of `name(constraint) value`. The assembly reads these.

```
asm("add {out}, {a}, {b}"
    : out("x0") -> i32
    : a("x1") val_a, b("x2") val_b)
```

**Clobbers:** Comma-separated list of registers or `"memory"` / `"cc"` that the assembly modifies but that are not outputs. The compiler avoids using clobbered registers for other values.

```
asm("syscall"
    : out("rax") -> i64
    : a("rax") syscall_num, b("rdi") arg1
    : "rcx", "r11", "memory")
```

**Volatile:** Marks the assembly as having side effects that the optimizer must not eliminate.

```
asm volatile("wfe" :::)    // wait-for-event; must not be optimized away
```

### 7.2 Implementation Notes

**Parser:** `asm` is a keyword that starts an expression. Parse the template string, then optional colon-separated sections for outputs, inputs, and clobbers.

**Sema:** Validate that the `asm` expression is inside an `unsafe` context. Validate that output types are integer or pointer types. No type checking of the assembly itself — that's the assembler's job.

**Codegen:** Emit LLVM inline assembly:

```llvm
%result = call i64 asm "mrs $0, CNTPCT_EL0", "=r"()
```

LLVM's inline assembly uses a different constraint syntax from GCC. The codegen must translate With's named constraints to LLVM's positional constraints. LLVM bridge addition: `wl_build_inline_asm(builder, asm_string, constraint_string, type, args, is_volatile)`.

**Target-specific concerns:** Assembly is inherently non-portable. The compiler should emit a warning (not error) when assembly is used, noting that it targets a specific architecture. The `@[target("aarch64")]` or `@[target("x86_64")]` attribute can guard architecture-specific blocks — code inside a mismatched target block is not compiled.

**Bootstrap:** Not needed in the compiler source. Add as a new feature with no bootstrap dependency.

---

## 8. Fused Multiply-Add

### 8.1 Specification

```
fma(a, b, c)      // a * b + c with single rounding
```

Computes `a * b + c` as a single floating-point operation with one rounding step, giving more precise results than separate multiply and add. Available for `f32` and `f64`.

```
let result = fma(3.0, 4.0, 5.0)    // 17.0, but more precise for non-trivial values
```

This is critical for numerical algorithms where accumulated rounding error matters: dot products, matrix multiplication, polynomial evaluation, Newton-Raphson iteration.

When hardware FMA is available (all modern x86 with FMA3, all ARM64), this maps to a single instruction. On older hardware without FMA, the compiler emits a library call that provides the same semantics via software.

### 8.2 Implementation Notes

**Codegen:** Use LLVM intrinsic `llvm.fma.f32` / `llvm.fma.f64`.

```llvm
%result = call double @llvm.fma.f64(double %a, double %b, double %c)
```

LLVM handles the hardware detection — it emits `vfmadd213sd` on x86 with FMA3, `fmadd` on ARM64, or a libcall on older targets.

**Sema:** Both arguments and return type must be the same float type. `fma(f32, f32, f32) → f32` and `fma(f64, f64, f64) → f64`. Mixed types are a compile error.

---

## 9. Summary — Implementation Order

Features are ordered by effort and impact. Each can be implemented independently.

| # | Feature | Effort | Files changed | Bootstrap steps |
|---|---------|--------|---------------|-----------------|
| 1 | `popcount`, `clz`, `ctz` | Tiny | Sema, MirLower, Codegen, llvm_bridge | 1 |
| 2 | `byteswap`, `bitreverse` | Tiny | Same as above | 1 |
| 3 | `min`, `max`, `abs` | Tiny | Same as above | 1 |
| 4 | `fma` | Tiny | Same as above | 1 |
| 5 | Saturating operators | Small | Lexer, Parser, Sema, MirLower, Codegen | 1 |
| 6 | Custom alignment | Small | Parser (attrs), Sema, Codegen | 1 |
| 7 | Atomic operations | Medium | Sema, MirLower, Codegen, llvm_bridge, std lib | 1-2 |
| 8 | Bitpacked structs + sub-byte ints | Large | Lexer, Parser, Sema, MirLower, Codegen | 2 |
| 9 | Inline assembly | Medium | Lexer, Parser, Sema, Codegen, llvm_bridge | 1 |

**Recommended implementation order for launch:**

Items 1-4 are one-afternoon additions. Each is a single LLVM intrinsic wrapped in a sema check and codegen call. Do all four in one session.

Item 5 (saturating operators) takes a day — new tokens, new ops through the pipeline. But it's high-value for the game demo.

Item 6 (custom alignment) is a day. Useful for SIMD buffers in the game.

Items 7-9 are post-launch. They're important but not launch blockers.

---

*Systems programming features — v1.0*