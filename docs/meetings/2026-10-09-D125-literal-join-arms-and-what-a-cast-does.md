# D125 — A literal arm of a join takes the typed arms' type (§4.2.1 rule 8); what `as` does at run time (§4.2.6); exact constants have no width limit

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford: "blessed" on the
words below). **Extends** D114 and D124. **The compiler is NON-COMPLIANT**
until implemented (the D114 branch, #2327: rule 8 is implemented there;
float saturation and the width limit are not yet).

**Context.** Asked whether the spec had been consulted for the D114 fixes,
the honest accounting was: no rule covered literal arms of a join, literal
returns of an inferred function, or an all-literal `if` as an operand; the
spec never defined what a runtime `as` does, which D124 leans on; and the
D124 implementation stopped at 64 bits. A review accepted the behaviors and
asked for two sentences in rule 8 (an outer context wins over an all-literal
join; typed arms that disagree are an error), saturation for an
out-of-range float-to-integer cast with NaN to 0, ties-to-even, a rule for
float narrowing, and no 64-bit limit. The words below include them.

**Blessed words (Eric, verbatim: "blessed").**

> **§4.2.1, rule 8: the other arms of a join.** In an `if`, `match` or
> `??`, and among a function's returns when its return type is inferred, an
> untyped literal arm takes the type of the typed arms. So does a tuple of
> untyped literals, or an `if` whose every arm is one. Beside a view of a
> number it takes the number's type. When every arm is untyped, the join is
> itself an untyped literal expression, and an outer context types it
> (`let x: u8 = if c: 1 else: 2` is `u8`). When the typed arms disagree
> (`i32` in one arm, `i64` in another), the join is an error (§4.2.6); no
> arm's width wins.
>
> **§4.2.6, casts.** `v as T` between integer types takes `v`'s
> mathematical value and keeps its low bits in two's complement, so widening
> sign- or zero-extends. From a float to an integer it truncates toward
> zero; a value out of range saturates to `T`'s minimum or maximum, and NaN
> gives 0. From an integer to a float, and from a wider float to a narrower
> one, it rounds to nearest, ties to even; a value too large for the
> narrower float becomes ±infinity.
>
> **§4.2.1, D124, added sentence.** Exact evaluation has no width limit; a
> compiler that cannot represent a value says so as its own limitation,
> never by typing the constant narrower.

**Review points carried into the work.** Saturate because it is
deterministic on every target (the mission point for migrated C), cheap
(wasm's `trunc_sat`; Rust settled on it after the undefined alternative
caused bugs), and a faithful translation of a case C leaves undefined. The
constant evaluator goes to at least 128 bits before D114 lands, since `u128`
exists and `(1 << 100) as u128` is legitimate.

**Open, not settled here.** What `&` of a constant points at (`opt ?? &-1`)
and how long it lives: briefed separately (prediction: a view of a static
constant of the demanded type).

**What would reopen it.** A target whose native float-to-integer conversion
cannot saturate at acceptable cost.
