# Spec Gaps Found from Crypto Implementation

The SHA-256 port is correct but ugly. Each ugliness traces to a
missing language feature or a spec gap. These affect all systems
code, not just crypto.

## 1. `unsafe fn` — function-level unsafe context

**Problem:** Every field access through a pointer requires
`unsafe:` wrapping:

```
// What you have to write:
unsafe: (*ctx).state[0] = (unsafe: (*ctx).state[0]) +% a

// What you should write:
unsafe fn sha256_compress(ctx: *mut Sha256):
    ctx.state[0] +%= a
```

When a function takes `*mut T`, almost every line dereferences
that pointer. Wrapping each access in `unsafe:` is noise that
hides the actual logic.

**Fix:** Add `unsafe fn` to the spec. Inside an unsafe function
body, all operations that would normally require `unsafe:` are
permitted without the wrapper. The `unsafe` keyword on the
function signature is the signal to the reader.

Callers of unsafe functions must still use `unsafe:` at the
call site (or be in an unsafe function themselves). This
preserves the "audit trail" property — grep for `unsafe` finds
every boundary.

**Spec change:** §7.1 add `unsafe fn` declaration form.
~5 lines of spec text, ~20 lines of compiler change (Sema
checks a flag instead of requiring unsafe blocks).

## 2. Compound wrapping assignment operators

**Problem:** No `+%=`, `-%=`, `*%=` operators:

```
// What you have to write:
ctx.state[0] = ctx.state[0] +% a
ctx.state[1] = ctx.state[1] +% b
// ... 8 lines of this

// What you should write:
ctx.state[0] +%= a
ctx.state[1] +%= b
```

Crypto code uses wrapping arithmetic on every line. Without
compound assignment, every operation doubles in length and
repeats the lvalue.

**Fix:** Add `+%=`, `-%=`, `*%=` to the spec alongside the
existing `+=`, `-=`, etc.

**Spec change:** §5.3 add wrapping compound assignment.
~3 lines of spec, ~10 lines of Parser.w, ~5 lines of
MirLower.w (desugar to read + wrapping_op + write).

## 3. Auto-deref for pointer method receivers

**Problem:** `ctx.buf[off]` doesn't work when `ctx` is
`*mut Sha256`. You must write `(*ctx).buf[off]` or use
`unsafe: (*ctx).buf[off]`.

```
// What you have to write:
let b = unsafe: (*ctx).buf[off]

// What you should write:
let b = ctx.buf[off]
```

C handles this: `ctx->buf[off]`. Rust handles this: auto-deref
on method receivers and field access. With should too.

**Fix:** When `x` has type `*T` or `*mut T`, `x.field` should
auto-deref to `(*x).field`. This is already how method calls
work in most languages with pointers. Field access should
follow the same rule.

The `unsafe` requirement still applies — accessing through a
raw pointer is unsafe. But with `unsafe fn`, the function body
is already in an unsafe context, so the deref is permitted.

**Spec change:** §6.2 add auto-deref for pointer field access.
~5 lines of spec, ~15 lines of Sema.w (check_field_access
inserts deref when base is pointer type).

## 4. Byte-order builtins

**Problem:** Every crypto algorithm and network protocol needs
big-endian and little-endian encode/decode. Currently:

```
// What you have to write (4 lines per u32 decode):
let b0 = ctx.buf[off] as u32
let b1 = ctx.buf[off + 1] as u32
let b2 = ctx.buf[off + 2] as u32
let b3 = ctx.buf[off + 3] as u32
w[i] = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3

// What you should write:
w[i] = u32.from_be(ctx.buf, off)
```

**Fix:** Add to `std.mem` or as builtin methods on integer types:

```
u16.from_be(buf: &[u8], offset: i32) -> u16
u16.from_le(buf: &[u8], offset: i32) -> u16
u32.from_be(buf: &[u8], offset: i32) -> u32
u32.from_le(buf: &[u8], offset: i32) -> u32
u64.from_be(buf: &[u8], offset: i32) -> u64
u64.from_le(buf: &[u8], offset: i32) -> u64

u16.to_be(buf: &mut [u8], offset: i32, val: u16)
u16.to_le(buf: &mut [u8], offset: i32, val: u16)
u32.to_be(buf: &mut [u8], offset: i32, val: u32)
u32.to_le(buf: &mut [u8], offset: i32, val: u32)
u64.to_be(buf: &mut [u8], offset: i32, val: u64)
u64.to_le(buf: &mut [u8], offset: i32, val: u64)
```

These compile to single instructions on most architectures
(bswap + load/store). They're not library functions — they're
fundamental operations that every systems language provides.

**Spec change:** §4.1 add byte-order methods on integer types.
~15 lines of spec, ~60 lines of implementation (can be
intrinsics or stdlib with @[inline]).

## 5. Borrow checker false positives on &mut self

**Problem:** The SHA-256 implementation uses `*mut Sha256`
instead of `&mut Sha256` because the borrow checker produces
false positives:

```
// This should work but doesn't:
fn Sha256.update(self: &mut Sha256, data: *const u8, len: i32):
    // ... modifies self.buf and self.count ...
    sha256_compress(&mut self)  // ERROR: already borrowed

// So you write this instead:
fn Sha256.update(self: *mut Sha256, data: *const u8, len: i32):
    // ... everything requires unsafe: (*self). ...
```

The borrow checker thinks `self` is still mutably borrowed when
`sha256_compress` takes `&mut self`. But the borrow from the
update method should allow reborrowing for nested calls — this
is how Rust's borrow checker works (reborrowing is permitted).

**Fix:** Implement reborrowing for `&mut` references. When a
function takes `&mut self` and calls another function that also
takes `&mut Self`, the borrow checker should allow it — the
original borrow is "reborrowed" for the duration of the call.

**Spec change:** §12.3 add reborrowing rule.
~10 lines of spec, ~30-50 lines in Sema.w borrow checking.

## 6. Rotate intrinsic

**Problem:** Bitwise rotation is the most common crypto
operation. Currently:

```
fn rotr(x: u32, n: i32) -> u32:
    (x >> n as u32) | (x << (32 - n) as u32)
```

This should be a builtin or intrinsic that compiles to a single
`ror` instruction:

```
x.rotate_right(n)
// or
@rotr(x, n)
```

**Fix:** Add `rotate_left` and `rotate_right` as methods on
integer types, or as compiler intrinsics. LLVM has
`llvm.fshl` and `llvm.fshr` intrinsics that compile to single
rotate instructions on all modern architectures.

**Spec change:** §4.1 add rotate methods on integer types.
~5 lines of spec, ~20 lines of codegen (emit llvm.fshl/fshr).

## Summary — Implementation Status

| # | Feature | Status |
|---|---------|--------|
| 1 | `unsafe fn` | **Done** — Parser wraps body in NK_UNSAFE_BLOCK |
| 2 | Compound wrapping assign (`+%=`) | **Done** — Lexer, Parser, Codegen |
| 3 | Auto-deref pointer fields | **Done** — Sema auto-derefs TY_PTR/TY_REF in check_field_access |
| 4 | Byte-order builtins | **Done** — `lib/std/crypto/endian.w` has all functions; `swap_bytes()` intrinsic on integer types emits `@llvm.bswap` |
| 5 | Borrow checker reborrowing | **Done** — Exclusive-to-exclusive reborrowing works (Sema check_borrow_create) |
| 6 | Rotate intrinsic | **Done** — `rotate_left`/`rotate_right` methods with MIR intrinsics |

All 6 gaps are resolved. Static method syntax for byte-order
(`u32.from_be(buf, off)`) is deferred — free functions
(`u32_from_be(buf, off)`) are used instead.

## What SHA-256 Should Look Like

After all fixes:

```
unsafe fn sha256_compress(ctx: &mut Sha256):
    var w: [u32; 64] = [0 as u32; 64]
    for i in 0..16:
        w[i] = u32.from_be(ctx.buf, i * 4)
    for i in 16..64:
        w[i] = w[i-2].rotate_right(17) ^ w[i-2].rotate_right(19) ^ (w[i-2] >> 10)
            +% w[i-7]
            +% w[i-15].rotate_right(7) ^ w[i-15].rotate_right(18) ^ (w[i-15] >> 3)
            +% w[i-16]

    var a = ctx.state[0]
    var b = ctx.state[1]
    // ...

    for i in 0..64:
        let s1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25)
        let ch = (e & f) ^ (~e & g)
        let t1 = h +% s1 +% ch +% K[i] +% w[i]
        let s0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22)
        let maj = (a & b) ^ (a & c) ^ (b & c)
        let t2 = s0 +% maj
        // ...

    ctx.state[0] +%= a
    ctx.state[1] +%= b
    // ...
```

Clean, readable, obviously correct. No `unsafe:` on every line,
no `(*ctx).` everywhere, no manual byte decoding. This is what
systems code in With should look like.