# D80 — SIMD masks and lane selection: `m.select(a, b)`, broadcast on every lane-wise operator, mask operators, `W = 128`

**Date:** 2026-09-29. **Status:** BDFL ruling (Eric, on the four
questions the #1874 implementation raised; "blessed" on the words).
Spec v7.14: §4.3d. Amends D78. Issue #1874.

**Decision.**

- **Lane selection is a method, `m.select(a, b)`:** `a`'s lane where `m`
  is true, `b`'s where it is false. It replaces §4.3d's
  `select(m, a, b)`, so `select` stays the `select await` keyword alone.
- **A scalar broadcasts on either side of every lane-wise operator** —
  arithmetic, comparison, bitwise, and a shift amount (`0.0 < v`,
  `0xff & v`, `v >> 2`). `let v: f32x4 = s` still requires `.splat(s)`.
- **Masks** construct (`m32x4(true, false, true, true)`,
  `m32x4.splat(true)`), index (`m[i]` is a `bool`), combine with
  `& | ^`, negate with `not`, and broadcast a `bool` operand. `and` and
  `or` are refused on a mask. Masks of different widths do not combine;
  `m as m8x4` converts the width.
- **`W` includes 128,** so `i128`/`u128` lanes compare.

**Why.**

- **select.** A method needs no grammar rule, reads in the order the
  operation happens (the mask decides), and matches Rust
  (`Mask::select`) and Mojo (`SIMD[bool].select`). "`select` followed by
  `(` is a builtin" would be a permanent parser special case: every
  future `select await` form that could start with a parenthesis becomes
  ambiguous, and one reserved word gets two grammars.
- **Broadcast.** A comparison, bitwise operation or shift amount against
  a scalar has one meaning, as arithmetic does; the rule is symmetric so
  the scalar may stand on the left. The one guardrail stays: a scalar
  variable bound alone as a vector is the place a type mistake would
  silently become a broadcast. Swift broadcasts the same way (`.<`, `&`,
  `&>>` against `Scalar`); Rust and Zig do not broadcast at all.
- **Mask operators.** Refusing construction or `&` is ceremony with no
  guardrail: a range check `(v > lo) & (v < hi)` would become a chain of
  selects. `and` and `or` short-circuit, and lanes cannot (Zig refuses
  them on vectors for the same reason). Mixed widths are refused in v1
  with a cast: the meaning is the same, but the result's representation
  is not forced, and a cast is cheap.
- **`W = 128`.** §4.3d already says `T` is any primitive integer and
  that the compiler lowers shapes the target lacks; refusing `i128`
  lanes contradicts both, and refusing only their comparisons leaves a
  hole where the meaning is fully determined. The mask's width is
  representation, not meaning — LLVM compares to `<N x i1>` regardless —
  which is why extending `W` to 128 is harmless.

**Process note.** The first implementation broadcast past the blessed
words (comparisons, bitwise, shifts) without a ruling. It happened to be
right this time; the rule for next time is that the compiler refuses what
the spec does not say, and the brief asks.

**References (checked in their trees).** Rust portable-simd
(`Mask::select`, `BitAnd`/`BitOr`/`BitXor`/`Not` on `Mask`, no 128-bit
`SimdElement`, no scalar operands); Zig langref "Vectors" (`@select`,
mixing scalars and vectors prohibited, bool vectors refuse `and`/`or`,
any integer lane width); Swift stdlib SIMD (`replacing(with:where:)`,
`.& .| .^ .!` on `SIMDMask`, scalar operands for arithmetic, bitwise and
`.<`); Mojo `SIMD` (`select` on bool vectors, `int128`/`uint128` dtypes).

**Reopen if** a target cannot represent a 128-bit-lane mask without a
cost the lowering cannot hide, or mixed-width mask combination turns out
to be common enough that one result width is forced by use.
