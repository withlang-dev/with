# D78 — SIMD vectors: `Vector[N, T]` with one-token aliases, `Mask[N, W]`, splat only where one meaning is forced

**Date:** 2026-09-29. **Status:** BDFL ruling (Eric: "implement it
properly", then the design paste, then "blessed" on the words). Spec
v7.11: §4.3d Vector Types, §16.1 C vector types. Issues #1874, #1872.

**Decision.** One type with two spellings: `Vector[N, T]` is the type;
`f32x4`, `i32x8`, `u8x16`, … are aliases of it for the native widths.
Masks carry the lane width: `Mask[N, W]` underneath, `m32x4`, `m8x16`
on top — a comparison of `f32x4` yields `m32x4`, which is what the
hardware produces and what `select` needs. Splat: a literal in a vector
context and a scalar operand in arithmetic with a vector broadcast (one
meaning each); a scalar *variable* bound alone as a vector does not —
`f32x4.splat(s)` is the one place the word is asked for, because a type
mistake there would silently become a broadcast. Non-power-of-two `N` is
legal in the generic, has no alias, and its size rounds up to a power of
two (`Vector[3, f32]` is 16 bytes, 16-aligned) — stated before anyone
imports a graphics header. Swizzles (`.xyzw`, `.xy`, `.wzyx`) are
clang's `ext_vector_type` swizzles, not an invention. `as` is lane-wise;
`.bits()` is the reinterpret: defaults pick representations, never
meanings. `c_import` prints the aliases, because they are what the C
typedefs already say.

**Amended by D80** (2026-09-29): lane selection is `m.select(a, b)`, a
scalar broadcasts on either side of every lane-wise operator, masks gain
construction, indexing and `& | ^`/`not`, and `W` includes 128.

**Why.** Generic code needs the parameterized form
(`fn dot[N](a: Vector[N, f32], …)`); everyone else needs the one-token
name; the aliases are presentation and cost nothing semantically. This
is what Rust (`Simd<T, N>` + `f32x4`) and Mojo (`SIMD[dtype, width]` +
`Float32x4`) converged on, for the same reason.

**References (checked in their trees).** Zig `@Vector(N, T)`; Rust
`std::simd::Simd<T, N>` with `f32x4`-style aliases and `Mask<T, N>`;
Swift `SIMD4<Float>` with `.x .y .z .w` and swizzles; Mojo
`SIMD[DType, width]`; clang `ext_vector_type` (swizzles, `(3)` lanes)
and GCC `vector_size`; LLVM `<N x T>` (non-power-of-two alloc size
rounds up).

**Alternatives.** LLVM's `[4 x f32]` notation (honest, unreadable);
`simd[4, f32]` (a second generic name for the same thing); `f32[4]`
(rejected outright: it is an array in With and the ABI differs).

**Reopen if** a target's native vector layout cannot round to a power of
two, or masks need a lane-count-only form (`Mask[N]`) for a hardware
family whose predicates carry no width.
