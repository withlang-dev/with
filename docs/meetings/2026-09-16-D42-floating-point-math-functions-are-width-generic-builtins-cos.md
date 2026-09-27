# D42 — Floating-point math functions are width-generic builtins: `cos(x)` and `x.cos()` for f32 and f64, no width suffix

**Date:** 2026-09-16. **Status:** ruled (Eric), implemented.

**Ruling.** `cos(x)` and `x.cos()` work for `f32` and `f64` with no width in
the name; the `*_f64` wrappers in `std.math` are deleted. Both spellings; the
full libm surface (specification §17.6a lists it); the intrinsic-vs-libm
split is hidden. Integer operands convert to the call's float type (the
float operand's width, else `f64`), as integers convert to floats anywhere
in With. A function of the same name defined in scope shadows the builtin;
an `extern fn` declaration of the name does not.

**Context.** With has no ad-hoc overloading, so `std.math` shipped
`cos_f64(x)` over an `extern fn cos(f64)`. That makes the user spell a type
the compiler already reads off the argument — the Go tax (`math.Cos` is
`float64`-only). Meanwhile `abs`/`min`/`max`/`mul_add` were already
width-generic builtins; only the transcendentals had been left out.

**References (verified in `.reference/`).** Zig: `math.cos(value: anytype)`
over `@cos`. Rust: `x.cos()` per float type over `cosf32`/`cosf64`
intrinsics. Swift: free `cos(_:)` per type; its `tgmath` splits functions
that have an LLVM intrinsic from those that do not — the exact split adopted
here. Go: `float64`-only, the outlier. Vale: one 64-bit `float`, so the
question never arises; With has real `f32`/`f64`, so it does.

**Mechanism.** One table, `src/MathBuiltins.w` (name, arity, LLVM name, libm
name). Sema types the call and records free calls in `math_builtin_calls`;
MirLower tags both spellings `MirIntrinsic.MATH_FN` with the row id at the
NK_CALL dispatch, before any call shape is chosen; each backend lowers from
the row (LLVM: `llvm.cos.f32/f64` or `tan`/`tanf`; C: `cos`/`cosf`). Single
source of truth (the D6 FnAbi rule): the three phases cannot drift.

**Precedence, and why externs yield.** D29 makes every `extern fn` globally
visible (one C symbol, one contract). The migrator emits `pub extern fn cos
(f64)` into every migrated corpus, and `std.re` is prelude-closure, so that
declaration was ambient in every program and would have shadowed the
builtin — returning `f64` for `cos(0.0f32)`. `check_call` therefore lets a
math builtin outrank an *extern* declaration of its own name, while a real,
non-extern definition still wins. Inside migrated C, `cos(double)` reaches
the builtin and lowers to the identical symbol. Removing the redundant
migrator decls is #1153.

**Reopens if.** With gains ad-hoc overloading or a `Float` trait, at which
point a stdlib generic could replace the compiler table.

---
