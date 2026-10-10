# D124 — An untyped constant expression has no width until a context types it; a cast is such a context and converts the exact value

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **Extends** D114
and §4.2.1. **The compiler is NON-COMPLIANT** until implemented (the D114
branch, #2327, carries it).

**Context.** Under D114 an unsuffixed literal nothing demands a width of is
`isize`, checked at the target's width. A cast was not a typing context, so
`(4294967295 as c_uint)` and `(0 - 1) as c_uint` — how the migrator spells
C constants — passed their literal through `isize`. On wasm32 (32-bit
`isize`) the migrated pcre2, zlib and tommyds bundles failed with 1,436
errors. The spec did not say how `LIT as T` is typed.

**Brief.** Others: Go converts an untyped constant exactly and refuses one
that does not fit; Zig's `@as` takes the exact value and truncation is
`@truncate`; Rust does not let a cast type a literal (it falls back to
`i32` and refuses it). Spec: §4.2.1's six literal contexts did not include a
cast. Options: A — `as` on an untyped constant converts its exact value at
compile time under the runtime cast's wrap/truncate rule, never through
`isize`; B — the cast types the literal and a value that does not fit is an
error. Prediction: A (80%).

**Ruling (Eric, verbatim).**

"**Rule A, and widen it from literals to untyped constant expressions.**

**Why A**

- **The migrator needs it.** C's conversion to unsigned is modular by
  definition, so `(unsigned)-1` is `UINT_MAX` on every C target. Option A is
  just C's rule applied at compile time. Option B would make the migrator
  rewrite correct C into something else, and a faithful translation
  shouldn't need a rewrite step.
- **The programmer already chose the type.** Option B makes them restate it
  in a different form. That is ceremony.
- **It's target-independent.** Today's failure is a 32-bit `isize` on
  wasm32. A 16-bit target would fail on `70000 as u32` in exactly the same
  way. Option A removes the whole class of failure, not just the wasm32
  instance, which fits your rule that today's choices shouldn't sabotage
  16- or 128-bit targets later.
- **The prior art doesn't argue against it.** The brief's summary matches my
  understanding: Go and Zig error on a value that doesn't fit, and Rust
  falls back to `i32` and rejects it. But all three are designing for native
  code, not for code translated from C. Here C's own semantics should
  decide.

**The part the brief understates**

`(0 - 1) as c_uint` is not a literal. It's arithmetic on literals. If the
rule only covers literals, that subtraction is evaluated in `isize` before
the cast sees it. That happens to work for `0 - 1`, but `(1 << 40) as u64`
on wasm32 would overflow on the way. The ruling should read:

> An untyped constant expression is evaluated exactly, with no width, until
> a context gives it a type. A cast is such a context. The cast converts the
> exact value with the same wrap and truncate rule a runtime cast uses. An
> untyped constant never passes through `isize` on its way to a cast.

That probably also explains some of the 1,436 errors. Check whether any of
them are shifts or products rather than bare literals.

**One optional guard**

Under A, `300 as u8` silently becomes 44. That is almost always a typo, not
an idiom. A warning when a nonnegative constant wraps would catch it. A
negative constant cast to an unsigned type stays silent, since that's the
`-1` idiom. Migrator output should be exempt from the warning. I'd add it,
but it's separable from D114 and shouldn't block it.

**Floats**

Float constants in a cast should follow the runtime rule too: `3.7 as i32`
gives 3. Then there is one conversion rule, not two.

With that ruling, D114 can go green once the 1,436 errors clear on wasm32.
#2325 and #2326 are independent of it."

**Spec projection.** §4.2.1 gains the ruling's sentence as written, and its
float clause, after the literal-context list; the context list gains the
cast as rule 7.

**Follow-ups.** The wrap warning (a nonnegative constant that wraps in a
cast; negative-to-unsigned silent; migrator output exempt) is its own
change, filed separately. Exact evaluation is bounded by the compiler's
current 64-bit constant arithmetic until `comptime-int-width.md` lands.

**What would reopen it.** A target where C's modular conversion is not what
migrated code means.
