# D160 — A shift count is a demand on the literal-typed local it reads: `u32`, as an untyped count is (delegated; extends D128)

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-26. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2646.

**Decision.** D128's demanding uses gain one: a shift count. A count
(`v >> s`, `1 << b`) that reads a literal-typed local, directly, through
arithmetic, or through a `for` over a list or range literal, demands `u32`
of it, the type §4.2.1 already gives an untyped count. The local is then
typed by D128's rule as at any other demand: uses that disagree are an
error naming both.

**Context.** `for shift in [0, 8, 16, 24]: (v >> shift) & 255`,
`for k in 0..4: v >> (k * 8)` and `let s = 8` then `v >> s` were each
"shift count must be unsigned integer"; the program had to write
`[0u32, 8, 16, 24]`, a token only the compiler needed. A count written as a
literal was already `u32`, and a parameter use already typed the same
locals; only the shift count was missing from D128's list.

**What the others do.** Rust: the literal is an inference variable and the
shift takes any integer amount, so it compiles (as `i32`). Go: an untyped
constant count is accepted; a typed one must be an integer. Swift: `>>` is
generic over the right operand. Zig: the count is the left operand's log2
type, and comptime literals coerce into it.

**Alternatives.** (a) Keep the error: the programmer states what the use
already says, Law 1. (b) Accept a signed count everywhere: a meaning change
to §4.2.4 (a negative count), not a demand. (c) The left operand's log2
width (Zig): a second default for one meaning; §4.2.1 already chose `u32`.

**Prediction.** 90%: D128 names "a demand shape the rule misses that a user
program shows" as what reopens it, and Law 2 is one mechanism, so a new
demanding site is an instance, not a new rule.

**Reopens if** a count's local is wanted as a signed value elsewhere in
the same function often enough that the disagreement error is ceremony.
