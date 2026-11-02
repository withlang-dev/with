# D181 — An integer beside a float is the float

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-11-01. **Status:** ruled by Eric ("dividing an integer by a
float should be a float"), on `let p = i / 140.0` being refused in a program
of his with "arithmetic on `isize` and `f64` needs an explicit `as` on one
operand (§4.2.6: no implicit integer-to-float conversion)".

**Ruling.** Integer-to-float conversion is implicit. An integer operand
beside a float operand in arithmetic or a comparison converts to the float's
type, and the result is that float: `i / 140.0` is `f64`, `i * 2.5f32` is
`f32`. An integer where a float is demanded (a binding's annotation, a
parameter, a return, an array or collection element) converts the same way.
The conversion is the one `as` performs (§4.2.6, D125): round to nearest,
ties to even. Float-to-integer stays explicit: `x as i32` truncates,
`x.round() as i32` rounds, and nothing happens without one of them.

**Why.** Law 1: when one meaning is forced the compiler infers it. An
integer next to `140.0` has exactly one meaning: float division. The `as f64`
the compiler demanded stated what it already knew, and the diagnostic
explained itself by representation ("no implicit integer-to-float
conversion"), which Law 2 names as the mark of ceremony. The lossless-only
rule the section carried was Rust's; a 64-bit integer above 2^53 loses low
bits in an `f64`, and that is representation, not a change of meaning (Law
11, D177: the compiler guarantees safety, not correctness of intent). The
other direction differs in kind: a float into an integer discards a
fraction or saturates, two meanings (`as`, `.round()`) the programmer must
choose between, so it stays a spelling.

**What others do.** C, C++, Java, C#, JavaScript, Python and Swift's
literals convert the integer; Go, Rust, Zig and Swift's typed values refuse.
With follows the first group for integer-to-float and the second for
float-to-integer.

**Implementation.** Sema's one numeric join (`implicit_numeric_join`)
returns the float for an integer-and-float pair, so arithmetic and
comparison take it from the same place; a float demand accepts an integer
value; the LLVM backend converts at the operation or the store with the
source's signedness (`si_to_fp`/`ui_to_fp`), the C backend by C's own
conversion. The two compile-error fixtures that pinned the refusal became
a behavior test of the conversion.

**What would reopen it.** A demonstrated class of real bugs from silent
integer-to-float conversion in With programs, as distinct from C's
integer-to-integer truncations this section was written against.
