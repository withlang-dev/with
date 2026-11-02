# D182 — A float beside a wider float is the wider float; a float where a narrower float is demanded converts

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-11-02. **Status:** delegated (D98): implemented on the
prediction below; Eric vetoes by revert. Raised by the program that raised
D181 the day before: with `i / 140.0` accepted, the next line,
`ColorFromHSV(p * 360 + t * 50, 0.85, 1)` (a raylib `float` parameter) and
`mouse.x + cos(angle) * radius` (an `f32` field beside an `f64`), were
refused with "implicit float narrowing from `f64` to `f32`; use an
explicit `as` cast (§4.2.6)".

**Ruling.** Float widths join to the wider in arithmetic and comparison
(`f32 + f64` is `f64`, as before). A float where a narrower float is
demanded (a binding's annotation, a parameter, a return, an element)
converts to it; the conversion is the one `as` performs (§4.2.6, D125):
round to nearest, ties to even, ±infinity when out of range. Float-to-
integer stays explicit, as D181 left it.

**Why.** Law 1: a value has one meaning when forced. `f64` to `f32` has
exactly one: the nearest `f32`. The cast the compiler demanded told it
nothing it did not know, and the diagnostic explained itself by
representation ("precision loss"), the Law 2 mark of ceremony. D181 drew
the line between the directions by meaning, not by information: integer to
float may drop low bits and is implicit; float to integer chooses between
truncate and round and is spelled. A narrower float is on the first side of
that line. Law 11 (D177): the compiler guarantees safety, not correctness
of intent; no float width is unsafe.

**What others do.** C and C++ convert; Java, C# and Swift refuse (Swift's
literals adapt); Go, Rust and Zig refuse. With follows C here, as D181 did
for integers, and keeps the refusal only where two meanings remain.

**Prediction.** 85%: Eric rules this on sight, as he ruled D181 ("dividing
an integer by a float should be a float"). What would make it wrong: a
wish to make `f32` a deliberate, visible choice in numeric code, which no
ruling so far has expressed.

**Implementation.** Sema's demand check accepts a float at a narrower float
demand (the join already took the wider float); the LLVM backend's `fp_cast`
at the store, already present at every coercion site, does the rounding.
`err_1803_float_narrowing` became part of the D182 behavior test;
`err_2096_typed_const_keeps_its_type` now pins D88 with an integer
narrowing, which still exists.

**What would reopen it.** A demonstrated class of real bugs from silent
`f64` to `f32` conversion in With programs, where the programmer meant to
keep the wide value.
