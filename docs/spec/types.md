# 4. Types

### 4.1 Primitive Types

Signed integers: `i8`, `i16`, `i32`, `i64`
Unsigned integers: `u8`, `u16`, `u32`, `u64`
Size integers: `usize`, `isize`: the target's size width, C's `size_t`/`ptrdiff_t`,
wide enough for any length or offset into memory. They are not defined as
pointer-sized; an integer that holds a pointer is a separate FFI type if one
is ever needed. Supported targets today are 64-bit hosts and wasm32; nothing
in the language, stdlib or compiler may assume a particular `isize` width
(D114). Values not bounded by memory use a fixed width: timestamps, file
sizes and offsets, hashes, IDs, money, anything serialized or crossing into a
C struct layout. A serialized or C-layout struct with an `isize` field warns.
Floating point: `f32`, `f64`
Boolean: `bool`
Unit: `Unit` (zero-sized)

`Int` is an alias for `i64`. `UInt` is an alias for `u64`. Always
64-bit, never platform-dependent.

**Friendly aliases are prelude-scoped and shadowable.** `Int`, `UInt`,
`String` (= `str`), `StrView` (= `&str`), and `CStr` are convenience
aliases declared at prelude scope. A user `type` declaration of the same
name shadows the alias by ordinary scoping (the visible user declaration
wins), so `type StrView { … }` in your module means *your* `StrView`.
The core lexical primitives — `i8`…`i128`, `u8`…`u128`, `f32`/`f64`,
`bool`, `str`, `usize`, `isize` — and the core types `Unit` and `Never`
are compiler-reserved and are not shadowable (they are woven through
every function signature and the type system's foundations). See §29.8.
(BDFL ruling 2026-07-05, #627; `Unit`/`Never` deliberately excluded from
demotion — see `docs/meetings/2026-07-05-D3-friendly-aliases-are-shadowable-unit-never-stay-reserved.md` D3.)

**Compile-time types:** At compile time, `type` is a first-class
value (see §17.3). `comptime` functions can accept `T: type` as a
parameter, enabling type-generic metaprogramming. `type` is not a
runtime value — it exists only during compilation and is erased
before code generation.

### 4.2 Arithmetic and Operators

#### 4.2.1 Numeric Literals

```
42              // decimal integer
1_000_000       // underscores for readability (ignored)
0xFF            // hexadecimal (prefix 0x or 0X)
0b1010          // binary (prefix 0b or 0B)
0o77            // octal (prefix 0o or 0O)
0u8             // suffixed integer literal
0x7FFF_FFFFu32  // suffixed hexadecimal integer literal
3.14            // floating point
1.0e-5          // scientific notation
1.0f32          // suffixed float literal
0x1.0p10        // hex float (value: 1024.0)
```

Underscores may appear between digits in any literal for
readability: `1_000_000`, `0xFF_FF`, `0b1111_0000`.

Integer and float literals may carry a type suffix directly on the
literal token:

- Integer suffixes: `u8`, `u16`, `u32`, `u64`, `i8`, `i16`, `i32`, `i64`, `usize`, `isize`
- Float suffixes: `f32`, `f64`

Examples:

```
255u8
0xDEAD_BEEFu32
42i64
3.14f32
```

The suffix is part of the literal. It is written without whitespace and
without a separator underscore. `0u64` is valid; `0_u64` is not part of
the language surface syntax.

**Default literal types:** if no suffix and no surrounding context forces
another numeric type:

- Unsuffixed integer literals default to `isize`, everywhere, including in
  bracket literals (`[1, 2, 3]` is a `Vec[isize]`, D113, D114)
- Unsuffixed float literals default to `f64`

Literals and comptime arithmetic are checked at the target's width, not the
host's (D114).

**Contextual numeric inference:** unsuffixed numeric literals are resolved
from surrounding type context before falling back to the defaults above.
The compiler may infer an unsuffixed literal's type from:

1. The target type of a typed binding or assignment
2. A function parameter type at the call site
3. The peer operand in a numeric binary operator
4. The enclosing function's declared return type for tail expressions
5. A known array element type
6. A known struct field type

Examples:

```
var acc: u64 = 0          // 0 is inferred as u64
take_u32(42)              // 42 is inferred as u32
let y = x + 1             // if x is u64, 1 is inferred as u64
let z = x >> 31           // shift amount defaults independently to u32
fn zero() -> u64: 0       // tail literal is inferred as u64
let p = Point { x: 0, y: 0 } // field literals infer from field types
```

Suffixed literals are explicit and do not participate in contextual
retyping. If a context expects `u32` and the literal is `42u8`, the
program is ill-typed unless an explicit conversion is written.

**Unsuffixed constants.** A `const` declared without a type, whose
initializer is made only of unsuffixed numeric literals, operators on them,
and other such constants, has no numeric type of its own. Each use of it is
typed as its initializer would be if written at that use: by the context of
the use, and by the defaults only where the use gives none. A `const` with a
declared type, or whose initializer has a suffixed literal or any other typed
operand, has that type at every use. A use whose type cannot hold the value is
an error at that use, never at the declaration: `const BIG = 5_000_000_000`
used as an `i32` is refused where it is so used.

```
const STEP = 1.0 / 120.0
const SPEED = 320.0
fn advance(dt: f32) -> f32: SPEED * dt   // SPEED is f32 here
let t: f64 = STEP                        // STEP is f64 here
let n = SPEED                            // no context: f64
```

**Range checking:** a suffixed literal must fit in its declared type. For
example, `256u8` is invalid.

#### 4.2.2 Arithmetic Operators

```
a + b       // addition
a - b       // subtraction
a * b       // multiplication
a / b       // division (integer: truncates toward zero)
a % b       // remainder (sign follows dividend, like C)
a @ b       // matrix multiplication / generalized matmul
-a          // unary negation
```

All arithmetic operators work on all integer types (`i8`–`i64`,
`u8`–`u64`) and floating point types (`f32`, `f64`).

`@` is a distinct infix operator at the same precedence level as
`*`, `/`, and `%`. It is intended for matrix multiplication and
generalized tensor products. Primitive numeric types do not provide
built-in `@`; user-defined types participate through the `MatMul`
operator trait (§11.7).

#### 4.2.3 Integer Overflow

Arithmetic is checked in safe code by default. Integer overflow
causes a panic in all builds unless the project explicitly configures
wrapping or saturating arithmetic; the default is panic.

```toml
# with.toml
[build]
overflow = "panic"      # default: panic on overflow
overflow = "wrap"       # two's complement wrapping
overflow = "saturate"   # clamp to min/max
```

**Explicit wrapping operators** bypass the overflow check:

```
a +% b      // wrapping addition
a -% b      // wrapping subtraction
a *% b      // wrapping multiplication
```

These always produce the two's complement result, regardless of
build mode. Use them for hash functions, checksums, and
cryptographic code.

**Explicit saturating operators** clamp to the type's representable range:

```
a +| b      // saturating addition
a -| b      // saturating subtraction
a *| b      // saturating multiplication
```

When the mathematical result exceeds the type's maximum, the result
is the maximum. When it falls below the minimum, the result is the
minimum. This is useful for audio processing, color blending, health
bars, and any domain where clamping is the correct overflow behavior.

```
let x: u8 = 250
let y: u8 = x +| 20        // 255 (clamped, not 14 or panic)

let a: i8 = 120
let b: i8 = a +| 20        // 127 (clamped)

let c: u8 = 5
let d: u8 = c -| 10        // 0 (clamped, not 251 or panic)
```

Saturating operators are defined for all integer types. They are not
defined for floating-point types (floats already saturate to ±infinity
per IEEE 754). Using them with floats is a compile error.

**All three overflow modes coexist:**

```
x + y       // checked: panic on overflow (default)
x +% y      // wrapping: two's complement wrap
x +| y      // saturating: clamp to min/max
```

#### 4.2.4 Bitwise Operators

```
a & b       // bitwise AND
a | b       // bitwise OR
a ^ b       // bitwise XOR
~a          // bitwise NOT (one's complement)
a << n      // left shift
a >> n      // right shift
```

All bitwise operators work on all integer types (`i8`–`i64`,
`u8`–`u64`).

For `&`, `|`, and `^`, the operation preserves bit patterns, not
numeric values. The operand rules are therefore narrower than
arithmetic promotion:

1. An untyped integer literal adopts the other operand's integer type.
   The literal is valid if its bit pattern fits that type's width, not
   if its signed numeric value fits the type's range.

   ```
   let flags: u32 = 0xf000
   let a = flags | 0xff           // 0xff is a 32-bit mask

   let byte: i8 = -1
   let b: i8 = byte & 0xff        // OK: 0xff is an 8-bit pattern
   let c: i8 = byte & 0x1ff       // ERROR: 9-bit pattern
   ```

2. Two typed operands with the same signedness and different widths
   widen to the wider type. Unsigned operands zero-extend; signed
   operands sign-extend.

   ```
   let a: u8 = 1
   let b: u32 = 0xff00
   let c = a | b                  // u32

   let x: i8 = -1
   let y: i32 = 0xff00
   let z = x & y                  // i32
   ```

3. Two typed operands with different signedness require an explicit
   `as` cast. There is no implicit third-type widening for bitwise
   operators.

   ```
   let u: u32 = 1
   let i: i32 = -1

   u | i                          // ERROR: mixed signedness
   (u as i32) | i                 // OK: caller chose signed bits
   u | (i as u32)                 // OK: caller chose unsigned bits
   (u as i64) | (i as i64)        // OK: caller chose 64-bit signed bits
   ```

The result type is the adopted operand type from rule 1, the wider
same-signedness type from rule 2, or the explicit cast type chosen by
the caller in rule 3.

Unary `~` preserves the operand type.

**Right shift semantics:**

- **Signed types** (`i8`–`i64`): arithmetic right shift
  (sign-extending — the sign bit is replicated into vacated bits).
- **Unsigned types** (`u8`–`u64`): logical right shift
  (zero-filling — vacated bits are filled with zeros).

```
let x: i32 = -8
x >> 1          // -4 (arithmetic: sign preserved)

let y: u32 = 0x80000000
y >> 1          // 0x40000000 (logical: zero-filled)
```

**Shift operations:** The shift operators `<<` (left shift) and `>>`
(right shift) take a left operand of any integer type and a right
operand of any unsigned integer type. A signed right operand is a type
error; callers must cast explicitly.

When the right operand is less than the bit width of the left operand,
the shift has its usual arithmetic meaning.

When the right operand is greater than or equal to the bit width of the
left operand, the result is defined as follows:

- Left shift (`<<`) produces `0`.
- Logical right shift (`>>` on an unsigned value) produces `0`.
- Arithmetic right shift (`>>` on a signed value) produces `0` for
  non-negative values and `-1` for negative values (the sign bit
  repeated).

Shift operations are defined for all well-typed inputs and cannot cause
undefined behavior.

**Rotation:**

```
x.rotate_left(n)    // bitwise left rotation
x.rotate_right(n)   // bitwise right rotation
```

Rotation is available as a method on all integer types. It wraps
bits that shift off one end back onto the other end. Compiles to
a single `ror`/`rol` instruction on all modern architectures
(via LLVM's `fshl`/`fshr` intrinsics).

```
let x: u32 = 0x12345678
x.rotate_right(8)       // 0x78123456
x.rotate_left(4)        // 0x23456781
```

**Byte swap:**

```
x.swap_bytes()      // reverse byte order of integer value
```

Available on all integer types ≥16 bits. Identity for `i8`/`u8`.
Compiles to LLVM's `@llvm.bswap` intrinsic (single `bswap`
instruction on x86/ARM).

```
let x: u32 = 0x12345678
x.swap_bytes()              // 0x78563412
x.swap_bytes().swap_bytes() // roundtrip: 0x12345678
```

**Byte-order encoding/decoding:**

The `std.crypto.endian` module provides functions for big-endian
and little-endian encoding/decoding from byte buffers:

```
use std.crypto.endian

// Decode from byte buffer at offset
u16_from_be(buf: *const u8, offset: i32) -> u16
u32_from_be(buf: *const u8, offset: i32) -> u32
u64_from_be(buf: *const u8, offset: i32) -> u64
u16_from_le(buf: *const u8, offset: i32) -> u16
u32_from_le(buf: *const u8, offset: i32) -> u32
u64_from_le(buf: *const u8, offset: i32) -> u64

// Encode to byte buffer at offset
u16_to_be(buf: *mut u8, offset: i32, val: u16)
u32_to_be(buf: *mut u8, offset: i32, val: u32)
u64_to_be(buf: *mut u8, offset: i32, val: u64)
u16_to_le(buf: *mut u8, offset: i32, val: u16)
u32_to_le(buf: *mut u8, offset: i32, val: u32)
u64_to_le(buf: *mut u8, offset: i32, val: u64)
```

Usage:

```
let word = u32_from_be(buf, 0)      // read big-endian u32
u32_to_le(out, 4, value)            // write little-endian u32
```

**Bit counting:**

```
x.popcount()        // count set bits (number of 1-bits)
x.clz()             // count leading zeros (from MSB)
x.ctz()             // count trailing zeros (from LSB)
```

Available on all integer types. Return type is `i32` regardless of
input width. Returns the type's bit width when the value is zero
(for `clz` and `ctz`).

```
let x: u32 = 0b00010000
x.popcount()        // 1
x.clz()             // 27
x.ctz()             // 4

let zero: u32 = 0
zero.clz()          // 32
zero.ctz()          // 32

0xFFu8.popcount()   // 8
```

Compiles to single hardware instructions on all modern architectures
(via LLVM's `ctpop`, `ctlz`, `cttz` intrinsics).

**Bit reversal:**

```
x.bitreverse()      // reverse the order of all bits
```

Available on all integer types. Return type matches the input type.
Bit 0 becomes the MSB, bit 1 becomes MSB-1, etc.

```
let x: u8 = 0b10110000
x.bitreverse()      // 0b00001101

let y: u32 = 0x80000000
y.bitreverse()      // 0x00000001
```

Compiles to LLVM's `llvm.bitreverse` intrinsic.

**Compile-time evaluation:** All bit manipulation methods can be
evaluated at compile time when the receiver is a constant.

#### 4.2.5 Compound Assignment Operators

```
a += b      // a = a + b
a -= b      // a = a - b
a *= b      // a = a * b
a /= b      // a = a / b
a %= b      // a = a % b
a &= b      // a = a & b
a |= b      // a = a | b
a ^= b      // a = a ^ b
a <<= n     // a = a << n
a >>= n     // a = a >> n
a +%= b     // a = a +% b (wrapping addition)
a -%= b     // a = a -% b (wrapping subtraction)
a *%= b     // a = a *% b (wrapping multiplication)
a +|= b     // a = a +| b (saturating addition)
a -|= b     // a = a -| b (saturating subtraction)
a *|= b     // a = a *| b (saturating multiplication)
```

Compound assignment requires `a` to be a mutable binding (`var`)
or a mutable reference. The operation and assignment are atomic
from the language's perspective (no intermediate observable state).

For Drop types, compound assignment is equivalent to: evaluate
`a op b`, drop the old value of `a`, store the result. This
ensures resources are properly released.

#### 4.2.6 Implicit Widening

Implicit widening is only allowed for lossless numeric conversions:
- Signed integers: `i8 -> i16 -> i32 -> i64`
- Unsigned integers: `u8 -> u16 -> u32 -> u64`
- Floats: `f32 -> f64`
- Unsigned to signed only when destination is strictly wider
  (`u8 -> i16`, `u16 -> i32`, `u32 -> i64`)

No other implicit numeric conversion is allowed.

**Implicit narrowing is a compile error:**

```
let big: i64 = 100000
let small: i32 = big          // ERROR: possible truncation
let small: i32 = big as i32   // OK: explicit intent

let x: u32 = 300
let y: u8 = x                 // ERROR: possible truncation
let y: u8 = x as u8           // OK: explicit intent

let f: f64 = 3.14
let g: f32 = f                // ERROR: possible precision loss
let g: f32 = f as f32         // OK: explicit intent
```

This catches a class of silent data corruption bugs inherited from
C. The `as` keyword signals that the programmer understands the
conversion may lose data. Signed-to-unsigned and unsigned-to-signed
conversions also require `as`, even at the same width.

#### 4.2.7 Comparison Operators and Chaining

```
a == b
a != b
a < b
a <= b
a > b
a >= b
```

Ordered comparisons (`<`, `<=`, `>`, `>=`) may be chained:

```
let valid = 0.0 < x < 1.0
let in_range = lo <= x <= hi
let sorted = a < b < c < d
```

`a < b < c` is equivalent to `(a < b) and (b < c)`, except each
interior operand is evaluated exactly once. When an interior operand
is non-trivial, the compiler introduces a hidden temporary:

```
left() < mid() < right()
// equivalent to:
let __cmp_tmp = mid()
left() < __cmp_tmp and __cmp_tmp < right()
```

Only ordered comparisons chain. Equality and membership operators do
not: `a == b == c` and `x in y in z` are compile errors. Chained
comparisons require each pairwise comparison to produce `bool`. If a
type wants elementwise or non-boolean comparison results, write the
pairwise comparisons explicitly and combine them yourself.

### 4.3 Structs

Structs are declared with `type` using either inline braces or an
indented block:

```
type Point { x: f64, y: f64 }

type Config:
    host: str
    port: i32
```

No methods, no constructors, no inheritance. Functions are associated
with types via extension blocks (Section 9.5).

**Struct literal forms:**

```
Point { x: 1.0, y: 2.0 }     // named inline
let p = Point:               // named block
    x: 1.0
    y: 2.0
Point { 1.0, 2.0 }           // positional inline
```

Named literals require all non-defaulted fields; fields may appear in
any order. Positional literals require all fields in declaration order.
Mixing named and positional fields in one literal is a compile error.
Positional form is inline only. Block form is named only. Field access
is always by name, regardless of construction form. Inline forms use
commas between fields; block form uses newlines.

**Record update syntax:**

```
let p1 = Point { x: 1.0, y: 2.0 }
let p2 = { p1 with x: 3.0 }        // p2 = Point { x: 3.0, y: 2.0 }
```

`{ base with field: value }` copies (or moves) all fields from `base`,
then overwrites the named fields. If the type is `Copy`, the base is
copied and remains valid. If not, the base is moved — non-overwritten
fields are moved into the new record, and **overwritten fields are
dropped** (the compiler emits `drop` calls for them). The base is
fully consumed.

Multiple fields may be updated:

```
let entity2 = { entity with
    position: new_pos,
    velocity: Vec3.zero(),
    health: entity.health - 10,
}
```

This is the primary mechanism for functional-style immutable updates.
It replaces the need for lenses or builder patterns. This is Form 4
of the `with` construct — see §7.4. Record update supports named
inline and named block fields only; positional record update is invalid.

**Field shorthand:**

When a variable has the same name as a struct field, the `: value`
part may be omitted:

```
let name = "Alice"
let email = "alice@example.com"
let active = true

// Shorthand: name, email, active inferred from variable names
let user = User { name, email, role: Role.Member, active }

// Equivalent to:
let user = User { name: name, email: email, role: Role.Member, active: active }
```

This applies in all struct construction contexts including record
update syntax:

```
let new_email = "new@example.com"
let updated = { user with email: new_email }

// Shorthand also works here:
let email = "new@example.com"
let updated = { user with email }
```

**Default field values:**

Struct fields may declare default values. Fields with defaults may
be omitted at construction sites:

```
type ServerConfig {
    host: str = "127.0.0.1",
    port: u16 = 8080,
    max_conns: usize = 1000,
    timeout: Duration = Duration.seconds(30),
}

// Omitted fields use their defaults
let config = ServerConfig { port: 9090 }
// Equivalent to:
let config = ServerConfig {
    host: "127.0.0.1",
    port: 9090,
    max_conns: 1000,
    timeout: Duration.seconds(30),
}

// All defaults (every field has a default)
let default_config = ServerConfig {}
```

The block form also supports defaults:

```
type ServerConfig:
    host: str = "127.0.0.1"
    port: u16 = 8080
    max_conns: usize = 1000
    timeout: Duration = Duration.seconds(30)
```

Default expressions are evaluated at the construction site, not at
type definition time. Each construction gets a fresh evaluation:

```
type Request {
    id: RequestId = RequestId.generate(),   // unique per construction
    created_at: Instant = Instant.now(),    // evaluated when constructed
    headers: Vec[Header] = Vec.new(),       // fresh Vec each time
}
```

**A field's type from its default.** A field with a default may omit its
type; the field then has the type of its default. When the default is an
unsuffixed numeric constant expression, the field's numeric type is decided
as a literal's is (§4.2.1): by what the field's uses in its module demand,
and by the default (`i32`, `f64`) when no use demands anything. Uses that
demand two different types are an error that asks for the type to be
written. A field without a default states its type.

```
type Ship { pos = Vector2 { x: 480.0, y: 300.0 }, radius = 10.0, ticks = 0, alive = true }
```

**Rules:**

1. Default expressions must be valid at any construction site (no
   capturing locals from the definition scope).
2. Fields without defaults must always be provided at construction.
3. Fields with defaults may be explicitly provided to override.
4. Default field values compose with field shorthand and record
   update syntax.
5. Defaults are a comptime transformation — the compiler inserts
   the default expressions for missing fields at the call site.

**Common pattern — config structs:**

```
type PoolConfig {
    min_conns: usize = 5,
    max_conns: usize = 20,
    idle_timeout: Duration = Duration.seconds(300),
    allocator: Allocator = std.heap.page_allocator(),
}

// Library function takes config with all-defaultable fields
fn connect(url: str, config: PoolConfig) -> Result[Pool, DbError]

// Usage: all defaults — just pass an empty struct literal
let pool = connect("postgres://localhost/mydb", PoolConfig {})?

// Usage: override what matters
let pool = connect("postgres://localhost/mydb", PoolConfig {
    max_conns: 50,
})?
```

### 4.3a Fixed-Size Arrays

Fixed-size arrays have a compile-time-known length and are
stack-allocated value types:

```
let a: [i32; 4] = [1, 2, 3, 4]
let x = a[0]                    // 1
let y = a[3]                    // 4

var b: [f32; 8] = [0.0; 8]     // fill with 0.0
b[2] = 3.14
```

**Syntax:**

```
[T; N]           // type: array of N elements of type T
[v0, v1, ..., vN] // literal: an array where `[T; N]` is demanded (§4.3c)
[value; N]       // repeat: N elements, value evaluated for each
arr[i]           // index: access element i
arr.len()        // length: returns N (compile-time constant)
```

`[value; N]` is N elements, `value` evaluated once for each element, in
order; `N` is a compile-time constant (§9.1b). Where a fixed array type is
demanded it builds that array; elsewhere it is a `Vec` (D113, §4.3c).

**Semantics:**

- Length `N` must be a compile-time constant (integer literal or `const`).
- `[T; N]` has size `N * sizeof(T)` and alignment `alignof(T)`.
- Fixed-size arrays are value types and follow normal ownership
  rules.
- `[T; N]` is `Copy` only when `T` is `Copy`; otherwise assignment
  moves the array.
- Argument passing follows the normal call-mode and effect rules for
  the callee. For large arrays, pass by reference unless by-value
  movement or copying is intended.
- Bounds checking in debug mode, unchecked in release.

#### 4.3a.1 Array-to-Pointer Decay
With has no implicit array-to-pointer decay. Use explicit decay:
`&arr[0] as *const T` (or `*mut T`). This applies in all contexts:
assignment, function arguments, and comparisons.

```
fn sum(arr: [i32; 4]) -> i32:
    var total = 0
    for i in 0..4:
        total = total + arr[i]
    total

// Fixed arrays in structs (inline, no pointer indirection):
type Shape { dims: [usize; 8], rank: i32 }
```

**Interaction with pattern matching:**

```
match items:
    []              => "empty"
    [only]          => "single"
    [first, ..rest] => "head: {first}, {rest.len()} more"
```

### 4.3b Bitpacked Structs

The `@[bitpacked]` attribute provides bit-level field packing where
fields occupy exactly their declared bit width with no padding.

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

1. Fields are laid out MSB-first (network byte order) from first
   field to last, with no gaps.
2. Total size is `ceil(sum_of_field_bits / 8)` bytes.
3. All field types must have a known bit width. Pointers, slices,
   strings, structs (except nested bitpacked), and Vecs are not
   allowed. Compile error: "bitpacked fields must be integer, bool,
   or bitpacked struct type."
4. `bool` occupies 1 bit. `true` is `1`, `false` is `0`.
5. Non-byte-sized integer types are valid field types (see below).
6. Nested `@[bitpacked]` structs are allowed; their bits are inlined.

**Field access** uses the same dot syntax as regular structs. The
compiler generates shift-and-mask operations:

```
var flags = Flags { enabled: true, priority: 5, mode: 12 }
let p = flags.priority        // extracts bits, returns u3
flags.mode = 3                // inserts bits
```

**Pointers to bitpacked fields** are a compile error. The field may
not be byte-aligned:

```
let f = Flags { enabled: true, priority: 5, mode: 12 }
let p = &f.priority     // error: cannot take address of bitpacked field
```

**Casting** to and from the backing integer type:

```
let flags = Flags { enabled: true, priority: 5, mode: 12 }
let byte = flags as u8    // 0b_1_101_1100 = 0xBC

let flags2 = 0xBCu8 as Flags
// flags2.enabled == true, flags2.priority == 5, flags2.mode == 12
```

The backing integer type is the smallest unsigned integer that holds
all bits: `u8` for 1-8 bits, `u16` for 9-16, `u32` for 17-32,
`u64` for 33-64.

**Non-byte-sized integer types:**

To support bitpacked structs, With provides integer types with
non-standard widths:

```
u1, u2, u3, u4, u5, u6, u7     // unsigned sub-byte
i1, i2, i3, i4, i5, i6, i7     // signed sub-byte
u12, u21, u24                    // selected wider non-standard widths
```

When used as local variables, non-byte-sized integers are stored in
the next larger standard-width register (e.g., `u3` occupies an `i32`
register with the upper bits zeroed). Arithmetic works normally; the
result is masked to the type's range.

### 4.3c Collection Literals

Bracket literals are With's one collection-literal family. The
element form builds sequences and sets; the `key: value` form builds
maps. Brackets make a `Vec` (D113); another collection is built where its
type is demanded, as with numeric literals (§4.2.1) and enum variant
shorthand (§4.4):

```
let a = [1, 2, 3]                      // Vec[isize]: brackets make a Vec
let v: Vec[i32] = [1, 2, 3]            // Vec[i32]: the demand types the elements
let t: [i32; 4] = [1, 2, 3, 4]         // fixed array: its type is demanded
for flag in ["-v", "-q"]: use(flag)    // Vec[str]; never grown or kept
print(total([1, 2, 3]))                // fn total(xs: &Vec[i32])
var ys = []                            // Vec: `push` says what it holds,
ys.push(big)                           // and `big: i64` its element type
let s: HashSet[str] = ["a", "b"]       // HashSet: a set is demanded
let o: BTreeSet[i32] = [3, 1, 2]       // BTreeSet: a set is demanded

let colors = ["red": 0xFF0000, "green": 0x00FF00]
// HashMap[str, isize] — the map-literal default

let ranks: BTreeMap[str, i32] = ["a": 1, "b": 2]

let empty: HashMap[str, i32] = [:]     // the empty map literal
let none: Vec[i32] = []                // empty sequence (type from context)
```

**Rules:**

1. A bracket literal is a `Vec[T]`, unless the demanded type is another
   collection that can be built from a list, such as a fixed array or a
   set. Then the literal builds that collection. The collections built
   from a list are `Vec[T]`, `HashSet[T]`, `BTreeSet[T]` and the fixed
   array `[T; N]` (§4.3a). An annotation may name the collection without
   its arguments, and the elements decide them: `let w: Vec = [1, 2, 3]` is
   a `Vec[isize]`.

   The element type comes from the elements, or from the demand: a
   parameter, a typed place assigned to or from, a return, or a method
   only one collection has (`push`). An empty literal waits for the first
   push or the first use to say what it holds. Uses that demand two
   different types are an error at the second, naming both. Demands are
   taken from the literal's own function only. A slice demand views the
   literal (a `Vec` coerces to `[]T`, §4.8a) and demands nothing. The repeat
   form `[value; N]` follows the same rule: a `Vec` of N elements unless a
   fixed array is demanded (D113).

   A literal that is never grown or retained needn't touch the heap: the
   compiler may place it on the stack, or in static data when its elements
   are constants. The program cannot tell the difference.

   Duplicate constants in a set literal warn: `["a", "a"]` demanded as a
   set is almost always a typo. A `Vec` keeps every element: `let v =
   ["a", "a"]` is a `Vec[str]` of length 2, and `v[0]` and `v[1]` are both
   `"a"`.

2. The map form `[k: v, ...]` defaults to `HashMap[K, V]`. When the
   expected type is `BTreeMap[K, V]`, it builds that instead. `[:]`
   is the empty map and requires an expected map type.
3. Set and map construction from literals follows insertion order;
   for duplicate keys/elements, later entries win (last-write,
   matching repeated `insert`).
4. Element and map forms cannot be mixed in one literal.
5. The map form requires the target's key type to satisfy the
   container's bound (`Key` for `HashMap`, `Ord` for
   `BTreeMap`), checked as for any construction.

There are no brace-delimited collection literals; `{ }` remains
blocks, struct literals, and record update. The colon key separator
is unambiguous inside brackets (array types and repeats use `;`,
§4.3a).

Enums are declared with the `enum` keyword using either an indented
block or inline braces:

```
enum Shape:
    Circle(radius: f64)
    Rectangle(w: f64, h: f64)
    Triangle(a: f64, b: f64, c: f64)

enum Direction { North | South | East | West }
```

An optional leading `|` is allowed in block form:

```
enum Shape:
    | Circle(radius: f64)
    | Rectangle(w: f64, h: f64)
    | Triangle(a: f64, b: f64, c: f64)
```

**Variant constructors are importable and usable unqualified:**

```
use Shape.{Circle, Rectangle, Triangle}

let s = Circle(5.0)            // idiomatic
let s = Shape.Circle(5.0)      // also valid, fully qualified
```

The standard library prelude automatically imports:
- `Option.{Some, None}`
- `Result.{Ok, Err}`

These never require qualification in normal code.

**Variant shorthand (`.Variant`):**

When the expected type is statically known from context, variant
names may be prefixed with `.` instead of the full type path:

```
enum Role { Admin | Member | Guest }

// Return type is known → .Member is unambiguous
fn default_role -> Role: .Member

// Match subject type is known → .Admin, .Member, .Guest work
fn describe(role: Role) -> str:
    match role:
        .Admin   => "Administrator"
        .Member  => "Member"
        .Guest   => "Guest"

// Parameter type is known → .Urgent works
fn send(msg: str, priority: Priority): ...
send("hello", .Urgent)

// Struct field type is known → .Member works
let user = User { name, email, role: .Member, active: true }
```

The compiler infers the type from: return type annotations, match
subject type, function parameter types, struct field types, variable
type annotations, and generic type arguments. If the type cannot be
inferred, the compiler requires the full path and suggests it:

```
// ERROR: cannot infer type for `.Member`
let x = .Member
//      ^^^^^^^ help: specify the type: `Role.Member`
```

**Qualified patterns in `match`:**

Match patterns may use qualified `Type.Variant` syntax:

```
fn describe(c: Color) -> str:
    match c:
        Color.Red   => "red"
        Color.Green => "green"
        _           => "other"
```

Qualified patterns also work with payloads:

```
fn area(s: Shape) -> f64:
    match s:
        Shape.Circle(r)       => 3.14159 * r * r
        Shape.Rectangle(w, h) => w * h
        _                     => 0.0
```

The compiler validates that the qualifying type matches the match
subject type, producing a compile error for mismatches.

**Auto-generated accessor methods:**

Every enum variant with data automatically generates accessor methods.
For a variant `Foo(T)`, the compiler generates:

```
fn is_foo(self: &MyEnum) -> bool
fn as_foo(self: MyEnum) -> Option[T]         // by value (moves)
fn as_foo_ref(self: &MyEnum) -> Option[&T]   // by shared ref
```

Method names are the variant name converted to `snake_case`.

```
enum Token:
    | TInt(i64)
    | TStr(str)
    | TBool(bool)
    | TNull

// Auto-generated:
// .is_tint() -> bool
// .as_tint() -> Option[i64]           .as_tint_ref() -> Option[&i64]
// .as_tstr() -> Option[str]           .as_tstr_ref() -> Option[&str]
// .as_tbool() -> Option[bool]         .as_tbool_ref() -> Option[&bool>
// (no .as_tnull — no data)
```

The `_ref` variants are essential for navigating tree structures
without cloning:

```
enum JsonValue:
    | Null | Bool(bool) | Number(f64) | Str(str)
    | Array(Vec[JsonValue]) | Object(HashMap[str, JsonValue])

// Navigate a JSON tree without cloning anything:
let stars = config
    .as_object_ref()?
    .get("meta")?
    .as_object_ref()?
    .get("stars")?
    .as_number_ref()
    ?? &0.0
```

These compose with optional chaining and `??`:

```
// Extract a value you know is there (test/prototype code)
let b = self.expect_token("bool")?.as_tbool() ?? unreachable()

// Safely check and extract by reference
let name = token.as_tstr_ref()?.to_upper()

// Filter a collection
let strings = tokens.iter()
    |> filter(t => t.is_tstr())
    |> map(t => t.as_tstr_ref().unwrap())
    |> collect()
```

For variants with multiple fields, `.as_variant()` returns
`Option[(A, B)]` (a tuple):

```
enum Shape:
    | Circle(radius: f64)
    | Rectangle(w: f64, h: f64)

shape.as_circle()       // Option[f64]
shape.as_rectangle()    // Option[(f64, f64)]
```

Unit variants (no data) generate only `.is_variant()`.

These methods are generated unconditionally for all enums — no
`@[derive]` needed. They are always available.

### 4.3d Vector Types

`Vector[N, T]` is a SIMD vector: `N` lanes of `T`, computed lane-wise.
`N ≥ 1` is a compile-time constant and `T` is a primitive integer or
floating type (§4.1). `Mask[N, W]` is `N` lanes of a lane-wide boolean
`W` bits wide (`W` ∈ 8, 16, 32, 64, 128); a lane-wise comparison of
`Vector[N, T]` yields `Mask[N, width(T)]`, which is what `m.select(a, b)`
and the hardware take.

**Aliases.** `f32x4`, `i32x8`, `u8x16`, … name `Vector[N, T]`, and
`m32x4`, `m8x16`, … name `Mask[N, W]`, for the native widths
(`N × width(T)` ∈ 128, 256, 512 bits). An alias is presentation: it
denotes the same type, it is what `c_import` prints for a C vector type
(§16.1), and it is the everyday spelling. Generic code spells the
parameterized form:

```
fn dot[N](a: Vector[N, f32], b: Vector[N, f32]) -> f32:
    (a * b).reduce_add()

let v = f32x4(1, 2, 3, 4)       // f32x4 is Vector[4, f32]
```

**Layout.** A vector has the target's representation for that shape,
recorded in the ABI document (`docs/spec/abi/with-abi.md`). On every
supported target `N × size(T)` rounds up to a power of two, so a
non-power-of-two `N` is legal in the generic (`Vector[3, f32]` is 16
bytes and 16-aligned, as clang's `ext_vector_type(3)` is) but has no
alias. A shape the target has no register for is still a value; the
compiler lowers it. `Vector` and `Mask` are `Copy`.

**Construction and splat.** `f32x4(1, 2, 3, 4)` and
`Vector[4, f32](1, 2, 3, 4)` take exactly `N` values of `T`. A scalar
broadcasts to every lane in the two places that have one meaning:

- a literal in a vector context: `let v: f32x4 = 0`;
- a scalar operand, literal or variable, on either side of a lane-wise
  operator with a vector — arithmetic, comparison, bitwise, or a shift
  amount: `v * 2.0`, `s * v`, `0.0 < v`, `0xff & v`, `v >> 2`.

A scalar variable bound alone as a vector is refused: `let v: f32x4 = s`
is spelled `f32x4.splat(s)`, because that is the one place where a type
mistake (a vector was meant) would silently become a broadcast.

**Lanes.** `v[i]` reads lane `i` and `v[i] = x` writes it (§4.3a's array
rules: a constant index is checked at compile time, a runtime index
panics out of range). For `N ≤ 4` the components are `.x .y .z .w`, and
a swizzle names lanes in any order and count: `v.xy`, `v.wzyx`, `v.xxxx`
yield `Vector[len, T]`. This is clang's `ext_vector_type` swizzle
(Clang Language Extensions, "Vectors and Extended Vectors"), which that
half of the C world already writes; it is not an invention.

**Operators.** `+ - * / %`, and for integer lanes `& | ^ << >>` and `~`,
are lane-wise and follow §4.2 per lane. `== != < <= > >=` are lane-wise
and yield a `Mask`. `m.select(a, b)` picks per lane: `a`'s lane where
`m` is true, `b`'s where it is false. `m.all()` and `m.any()` reduce a
mask; `reduce_add`, `reduce_mul`, `reduce_min`, `reduce_max`,
`reduce_and`, `reduce_or` and `reduce_xor` reduce a vector.

**Masks.** `m32x4(true, false, true, true)` and `m32x4.splat(true)`
construct a mask as a vector is constructed, and a `bool` literal in a
mask context broadcasts (`let m: m32x4 = true`). `m[i]` reads lane `i`
as a `bool`, and `m[i] = b` writes it. `&`, `|` and `^` combine masks of
the same shape lane-wise, a `bool` operand broadcasting as a scalar does
(#Construction and splat), and `not m` negates each lane; `not` is the
one spelling, so `~m` is refused. `and` and `or` are refused on a mask:
they short-circuit, and lanes cannot. Masks of different widths do not
combine; `m as Mask[4, 8]` converts the width. A scalar `a` or `b` of
`m.select(a, b)` broadcasts as an operator's scalar operand does. Each of
these has more than one meaning and is refused: `m == n` (a whole-mask
`bool`, or a lane-wise mask — spelled `(m ^ n).any()` or `not (m ^ n)`);
a cast between a mask and a vector, and `.bits()` or `.from_bits` on a
mask (a true lane as `1` or as `-1`); `.x`-style components on a mask
(its lanes are `m[i]`). The width is representation, not meaning: every
width holds the same lane booleans, which is why `W` reaches 128 for
128-bit lanes.

**Casts.** `v as i32x4` converts lane-wise, under §4.2.6 for each lane
(an implicit narrowing is refused as it is for a scalar). `v.bits()`
reinterprets the bytes as the unsigned integer vector of the same lane
width (`f32x4.bits(): u32x4`) and `Vector[N, T].from_bits(u)` reverses
it: a change of representation is a default, a change of meaning is
spelled (§2).

### 4.4a Discriminant Enums

Enums can specify an integer representation type and explicit discriminant
values for each variant. Discriminant enums use the `enum` keyword with a
representation type:

```
enum Color: i32:
    Red = 1
    Green = 2
    Blue = 4
```

Inline form is also supported:

```
enum Color: i32 { Red = 1, Green = 2, Blue = 4 }
```

The type after the first colon is the **representation type** — an integer type
(`i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`) that determines the
underlying storage. Each variant
is assigned an explicit integer value with `= N`.

An enum with no representation type and an explicit `= N` on any variant is a
discriminant enum in the default integer representation, payload variants or
not.

**Auto-incrementing:** If a variant omits the `= N`, it defaults to the previous
variant's value plus one (or zero for the first variant):

```
enum Status: i32:
    Pending = 0
    Active          // 1 (auto)
    Suspended = 10
    Archived        // 11 (auto)
```

**Discriminant enums with payloads:** Variants can carry associated data just
like regular enums, combined with explicit discriminant values:

```
enum Msg: i32:
    Quit = 0
    Move(i32, i32) = 1
    Write(str) = 2
```

When any variant has a payload, the LLVM representation is a tagged union
`{ repr_ty, [max_payload_size x i8] }` — the same layout as regular enums but
with the tag being the discriminant value. Pattern matching extracts payloads
the same way as regular enums.

**`@[flags]` attribute:** For bitflag enums, `@[flags]` changes auto-increment
to power-of-two doubling:

```
@[flags]
enum Perms: i32:
    Read         // 1 (default first)
    Write        // 2
    Execute      // 4
```

Bitwise operations work naturally since the enum **is** its integer value.
An `@[flags]` enum with no representation type doubles the same way in its
default integer representation; the attribute is never ignored.

**`@[specified]` attribute:** For boundary-facing discriminant enums,
`@[specified]` requires every variant to provide an explicit value.
It is intended for wire formats, file formats, FFI constants, protocol
messages, and other values where auto-increment would make source
ordering part of the external ABI.

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong = 2
    Data = 3
```

`@[specified]` requires an explicit integer representation type and
rejects any variant without `= value`:

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong       // ERROR: @[specified] requires explicit variant values
```

**Conversion:** `Type.from_int(n)` converts an integer to `Option[Type]`,
returning `.None` for values that don't match any defined discriminant:

```
let c = Color.from_int(2)    // Some(Color.Green)
let x = Color.from_int(99)   // None
```

`from_int` exists only on an enum whose variants are all unit variants. No
value of the enum exists for a payload variant's discriminant alone, so on an
enum with a payload variant a `from_int` call is a compile error naming that
variant.

**Casting:** `value as i32` extracts the underlying integer (identity cast).

### 4.5 Distinct Types

```
type UserId = distinct i64
type Meters = distinct f64
```

Zero-cost wrappers that prevent accidental mixing of semantically
different values.

Casting an owned value into or out of its distinct type (`s as Name`,
`n as str`) moves it: the distinct type has its underlying type's
destructor. A cast whose target is a view (`n as &str`), or any cast through
a reference, borrows and yields a view.

### 4.6 Type Inference

Bidirectional, local inference. Inside function bodies, types are
inferred. At module boundaries, types must be explicit. Inference does
not cross compilation unit boundaries.

### 4.7 Ranges

```
0..10       // exclusive: 0, 1, 2, ..., 9
0..=10      // inclusive: 0, 1, 2, ..., 10
```

Ranges are values of type `Range[T]` or `RangeInclusive[T]`. They
implement `Iter[T]` for integer types and `Contains[T]` for ordered
types, making them usable in `for` loops, slicing, pattern matching,
and membership tests.

Ranges are ordinary first-class values: they can be stored in
variables, passed to functions, and returned like any other value.

```
for i in 0..n:
    process(i)

let window = 100..200
publish_window(window)

let slice = data[2..5]         // elements at index 2, 3, 4

if x in 1..=100:               // membership test (§9.9)
    handle_valid(x)

match code:
    200..=299 => "success"
    400..=499 => "client error"
    _         => "other"
```

---

### 4.8 Tuples

Tuples are anonymous product types for quick groupings of values:

```
let pair: (i32, str) = (42, "hello")
let triple = (1.0, 2.0, 3.0)       // type inferred: (f64, f64, f64)
```

**Destructuring:**

```
let (x, y) = get_position()
let (first, _, third) = triple      // _ ignores a field
let (head, ..rest) = tuple5         // ..rest captures remaining
```

**Access by index:**

```
let x = pair.0                       // 42
let s = pair.1                       // "hello"
```

**Use in generics and containers:**

```
fn swap[A, B](pair: (A, B)) -> (B, A):
    (pair.1, pair.0)

// HashMap iteration yields (&K, &V) views
for (key, value) in map:
    print(f"{key}: {value}")

// Functions can return multiple values naturally
fn divmod(a: i32, b: i32) -> (i32, i32):
    (a / b, a % b)
```

**Ownership:** Tuples follow normal ownership rules. A tuple is
`Copy` if all elements are `Copy`. A tuple is `Send` if all elements
are `Send`. Ephemeral elements make the tuple ephemeral.

**Unit:** The unit type `Unit` is equivalent to the empty tuple `()`.

**Unit elision:** When a function, method, or variant constructor
expects a single argument of type `Unit`, the argument may be
omitted. The compiler inserts `()` automatically:

```
unwrap_or()   // desugars to .unwrap_or(())
Some()        // desugars to Some(())
```

In practice, `Ok()` is rarely needed because of implicit `Ok`
wrapping (§4.9). But Unit elision still helps with other types.

**Applicability:** Unit elision applies **only when the expected
parameter type is statically known to be `Unit`** at the call site
via bidirectional type inference. It does NOT apply to unconstrained
generics:

```
unwrap_or()          // OK: Option[Unit].unwrap_or → expected Unit

fn id[T](val: T) -> T: val
id()                 // ERROR: expected 1 argument, got 0
                     // T is unconstrained — elision does not apply
```

More examples:

```
// These patterns used to need Ok() — now just let the function end:
async fn send_email(to: &str, body: &str) -> Result[Unit, SmtpError]:
    transport.send(to, body).await?
    // implicit Ok(()) — just end the function

fn run_migrations -> Result[Unit, DbError]:
    for m in migrations:
        m.execute(&conn)?
    // implicit Ok(()) — no ceremony needed

// unwrap_or with Unit still uses elision
let _ = cache.set(key, value).await.unwrap_or()   // instead of .unwrap_or(())
```

### 4.8a Slices

Slices are borrowed views into contiguous memory (arrays, Vecs):

```
[]T         shared (immutable) slice
[]mut T     exclusive (mutable) slice
```

A slice is a fat pointer: `(ptr: *const T, len: usize)`. It does
not own the data — it borrows from an array, Vec, or other
contiguous storage.

```
fn sum(data: []f32) -> f32:
    var total: f32 = 0.0
    for i in 0..data.len():
        total = total + data[i]
    total

let arr: [f32; 4] = [1.0, 2.0, 3.0, 4.0]
let s = sum(arr[..])      // slice of entire array
let s2 = sum(arr[1..3])   // slice of elements 1, 2
```

Slices are ephemeral (§5) — they cannot be stored in structs (a
persistent relationship to elements is what handles, §6, are for).
Returning a slice from a function is checked by §21.1 Rule 6: the
result is tied to the intersection of its possible origin parameters'
lifetimes, and the program is rejected if any possible origin dies
before the view's last use. Bounds-checked in debug mode.

**String slices.** A range index on a `str` or `&str` — `s[a..b]`, `s[a..]`,
`s[..b]`, `s[..]` — is a `&str` view of the bytes from `a` to `b`, with the
origin and ephemerality of any view (§5, §21.1). Offsets are byte offsets. An
offset past the end, or one that falls inside a UTF-8 character, panics.

```
let s = "hello, world"
let head = s[..5]        // "hello"
let rest = s[7..]        // "world"
```

**Exclusivity rules for `[]mut T`:** a mutable slice is an exclusive
view of its range. While a `[]mut T` is live (NLL: until its last
use), the borrowed range may not be read or written through any other
path — creating one invalidates outstanding `&T` and `[]T` views of
the same place, and creating a second overlapping `[]mut T` is
rejected (§21.1 Rule 1). Disjoint mutable views are obtained
explicitly:

```
let (left, right) = data.split_at_mut(mid)
// left: []mut T over [0, mid)   right: []mut T over [mid, len)
```

The standard library must provide `split_at(i)` and `split_at_mut(i)`
on slices, arrays, and `Vec[T]`. As with array indices (§3.6), range
disjointness is not inferred at compile time — `split_at_mut` is the
safe primitive for simultaneous mutable access to disjoint ranges. In
parameter position, `[]T` and `[]mut T` follow §3.8's borrow mode:
the caller's collection coerces to the slice view, and the caller's
binding remains valid after the call (for `[]mut T`, the exclusive
borrow ends when the callee returns).

### 4.9 Implicit `Ok` Wrapping

When a function's return type is `Result[T, E]`, the compiler
automatically wraps the final expression:

- If the last expression has type `T` (not `Result`), it's wrapped
  in `Ok(...)`.
- If the function returns `Result[Unit, E]` and the block ends with
  a statement (no trailing expression), `Ok(())` is returned.
- `?` still early-returns `Err` as normal.

```
// Before: manual Ok wrapping
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    let user = User.from_row(row)
    Ok(user)

// After: implicit Ok wrapping
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    User.from_row(row)                   // auto-wrapped in Ok(...)

// Result[Unit, E] — no trailing expression needed
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
    // implicitly returns Ok(())

// Explicit Err still works normally
fn validate(age: i32) -> Result[Unit, ValidationError]:
    if age < 0: return Err(.InvalidAge)
    if age > 150: return Err(.InvalidAge)
    // implicitly returns Ok(())
```

**The rule is simple:** `?` handles the sad path. The happy path
just returns the value. No wrapping needed.

**When implicit wrapping does NOT apply:**

- If the last expression already has type `Result[T, E]`, no
  wrapping occurs (would produce `Result[Result[T, E], E]`).
- If the return type is not `Result`, implicit Ok wrapping doesn't
  apply (but see §4.10 for implicit default return).
- Explicit `Ok(...)` and `Err(...)` still work everywhere.

**Guideline:** Tuples above 3 elements should usually be replaced
with a named struct for readability. The compiler does not enforce
this, but `with fmt` may suggest it.

### 4.9a Value to Option

**Value to Option.** Where an `Option[T]` is demanded and the expression
has type `T`, the expression is `Some(expression)`. `None` and an
expression already of type `Option[T]` are taken as they are. The
conversion applies once, at the demand; it never applies where no type is
demanded. The conversion does not participate in inference; it applies
only once the demanded type is known.

Demand propagates into the arms of an `if` and a `match` and into a
block's tail the way demand already propagates there, so arms may mix `3`
and `None` under an `Option[i32]` demand. An operator's operands are not
demand sites: `opt == 3` is an error.

The conversion is the second of a demand's two phases (mission.md, law
2): a demand first binds the unknowns the expression's own signature
leaves open, then the conversion applies between two known types and
binds nothing; and an expression's own operands bind before the outer
demand fills what remains. `let x: Option[i32] = ident(3)` with
`fn ident[T](t: T) -> T` is `Some(ident(3))` at `T := i32`, never
`ident(Some(3))`.

```
fn first(x: Option[i32]) -> i32: x.unwrap_or(0)
first(3)                         // Some(3)
let slot: Option[&str] = name    // Some(name)
type Box { cb: Option[extern "C" fn(i32) -> i32] }
Box { cb: twice }                // Some(twice)
```

*Commentary.* "Once" is the guardrail: a bare `T` offered where
`Option[Option[T]]` is demanded becomes `Some(x): Option[T]`, which then
mismatches and is refused, so nesting is never guessed. "Does not
participate in inference" keeps `fn first[T](x: Option[T])` called as
`first(3)` an error until `T` is known by other means: the conversion
never solves a type variable (Swift lets promotion take part in solving,
which is the source of its overload-resolution cost and surprising picks).
(D103, 2026-10-07.)

### 4.10 Implicit Default Return

When a function's return type implements the `Default` trait and the
body's last expression is `Unit` (a statement like `print`), the
compiler implicitly returns `T.default()`.

The implicit default applies only when the tail's own type is `Unit`. A
tail of any other type is the body's value: it must match the declared
return type or it is a type error. The compiler never discards a tail's
value to substitute `T.default()`.

```
// Before: manual trailing 0
fn demo_strings -> i32:
    let hello = "Hello, C interop!"
    puts(hello)
    print(f"strlen = {strlen(hello)}")
    0                                      // annoying boilerplate

// After: implicit default return
fn demo_strings -> i32:
    let hello = "Hello, C interop!"
    puts(hello)
    print(f"strlen = {strlen(hello)}")
    // implicitly returns 0 (i32.default())
```

**The `Default` trait:**

```
trait Default:
    fn default -> Self
```

Built-in implementations:

| Type | `default()` |
|------|-------------|
| `i8`, `i16`, `i32`, `i64` | `0` |
| `u8`, `u16`, `u32`, `u64` | `0` |
| `usize` | `0` |
| `f32`, `f64` | `0.0` |
| `bool` | `false` |
| `str` | `""` |
| `Option[T]` | `None` |
| `Vec[T]` | empty vec |
| `HashMap[K, V]` | empty map |
| `HashSet[T]` | empty set |

User types can implement `Default` manually or via `@[derive(Default)]`
(requires all fields to implement `Default`):

```
@[derive(Default)]
type Config {
    port: i32,          // defaults to 0
    debug: bool,        // defaults to false
    name: str,          // defaults to ""
}

fn make_config -> Config:
    print("Creating default config...")
    // implicitly returns Config.default()
```

**Interaction with implicit Ok wrapping:**

Both features compose. If the return type is `Result[T, E]` and the
body ends with a `Unit` statement, implicit Ok wrapping takes
priority (returns `Ok(T.default())` if `T` implements `Default`, or
`Ok(())` if `T` is `Unit`).

**When implicit default return does NOT apply:**

- If any path in the body explicitly returns a value (a `return expr`
  or a non-Unit tail expression on another branch), implicit default
  return does not apply — a function that demonstrably produces
  values elsewhere but falls off the end is reported as a missing
  return, not defaulted. The implicit default exists for functions
  that never spell a return value (entry points, handlers); it never
  papers over a forgotten one.
- If the last expression has a non-Unit type, no default insertion
  occurs (the expression is the return value as usual).
- If the return type does not implement `Default`, the compiler
  reports a type mismatch as usual.
- If the return type is `Unit`, no return value is needed (already
  handled).
- Explicit return values always work and are never overridden.

**Implicit unreachable on unproven paths:** If the compiler cannot
statically prove that all code paths return a value of the declared
return type, it silently inserts `unreachable` at the function exit.
If this path is reached at runtime, the program panics with a
diagnostic that includes file and line. You may add an explicit
`unreachable` for clarity, but it is never required.

---
