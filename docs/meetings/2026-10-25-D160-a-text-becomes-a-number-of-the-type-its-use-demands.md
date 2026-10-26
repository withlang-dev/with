# D160 — A text becomes a number of the type its use demands: `s.parse()`, strict, `Option` (delegated)

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-25. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #959.

**Decision.** `str` has one `parse()`: `pub fn parse[T: Parse]() ->
Option[T]`. Its type comes from its use: a typed binding (`let n: i64 =
s.parse() ?? 0`), a `??` whose result is demanded (the demand on a `??`
reaches its carrier as a hint, never as an `Option` demand, D103), a
parameter. It is strict: None unless the whole text is one value of the
type, in range. An integer is an optional sign and decimal digits; a float
is digits with an optional fraction and exponent, read as the correctly
rounded double. `Parse` (`fn parse_text(text: &str) -> Option[Self]`) is
the trait a type implements to be parsed; std implements it for the
integer types and `f64`. `f32` is not implemented until its parse is
correctly rounded on its own (rounding through `f64` can differ). The
free function `std.string.parse(s) -> i32` is unchanged.

**Context.** `str` had no `parse` method, so a field could not become a
number (`f[1].parse()`: "unknown method"). Eric, reviewing #2127: a
type-suffixed `parse_i64` is "bad, not Withy"; parsing takes its type from
its use.

**What the others do.** Rust: `s.parse::<T>()` over `FromStr`, a
`Result`, strict, typed by inference or turbofish. Go: `strconv.Atoi` /
`ParseInt(s, 10, 64)`, width in the call. Swift: `Int(s)`, an optional,
strict. Zig: `std.fmt.parseInt(T, s, 10)`. Strict whole-text parsing with
an optional result is common to all of them; the type from the use is
Rust's and Swift's.

**Alternatives.** (a) `parse_i64`/`parse_f64`: the width in the name,
which Eric refused. (b) A `Result` with an error kind: a non-number is
ordinary input, and `?`/`??`/`unwrap_or` read naturally on an `Option`;
nothing so far needs the kind. (c) The explicit form `s.parse[i64]()` when
nothing decides the type: #598 rules out type arguments at call sites,
which this decision does not reopen. An undecided use is refused with the
existing "annotate the result binding" diagnostic.

**Prediction.** 85%: Eric stated the shape in the #2127 review.

**Reopens if** a caller needs to tell an overflow from a malformed text,
or Eric rules the explicit `parse[T]()` form in (amending #598).
