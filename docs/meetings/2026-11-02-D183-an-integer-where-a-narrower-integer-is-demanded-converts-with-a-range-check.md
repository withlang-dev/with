# D183 — An integer where a narrower integer or a different sign is demanded converts with a range check; `as` is the wrap spelling

**Laws:** 1, 2, 11 (docs/mission.md).

**Date:** 2026-11-02. **Status:** ruled by Eric, on the brief for #2522
(the `.len() as i32` sites, the census' largest ceremony pattern).

**Ruling (Eric's words).** "The general checked conversion, as predicted,
and fix the two hot spots differently. A trap is never a silent meaning
change, so `let b: i32 = x` with `x: i64` converting with a range check is
sound, and `as` stays the wrap spelling. But a checked conversion that
fires inside the loop body of a compiler is a cost, so the real goal is
that most of the 839 sites stop being conversions at all:
- `len()` returns `isize`, and D114 says positions have no assumed width,
  so a loop index that comes from `0..xs.len()` is `isize` by inference,
  and `xs[i]` with an `isize` needs no conversion. Each site that stays a
  conversion after that is a place where an `i32` field or parameter is
  what's actually wrong, and the lint should point at that declaration,
  not the use.
- One guard: a checked narrowing inside a comptime initializer must fail
  at compile time, not become a runtime trap."

**What it means.** An integer value where a narrower integer, or an
integer of the other signedness, is demanded (a binding's annotation, a
parameter, a return, a field, an element) converts with a range check: a
value the destination cannot hold panics, as an out-of-range index panics
(D71). `as` keeps the two's-complement wrap (§4.2.6). In a comptime
initializer the check runs at compile time and an out-of-range value is a
compile error. Positions are `isize`: a loop index from `0..xs.len()` is
`isize` by inference and indexes with no conversion. A conversion that
remains is a lint on the declaration whose width is wrong (the `i32`
field or parameter), never on the use.

**Why.** Law 1: the cast states nothing the compiler can establish, and
wrap and trap are two meanings, so a *silent* narrowing cannot be
implicit while a *checked* one is one meaning (D71 chose it for indexing).
Law 2: a phase-two conversion between two known types. Law 11: the
guarantee (no silent wrap) is kept; the restriction (write `as`) only
protected the programmer from themselves. §4.2.6's rationale paragraph is
rewritten with it (#2964, delegated, D98): `as` is written where two
meanings remain, never because representation is lost.

**What others do.** Go and Swift have one `int`; Rust narrows by `as`
(wrap) or `try_into` (checked); Zig by `@intCast` (checked in safe modes).

**Implementation.** Sema's demand check accepts the narrowing and records
it as checked; MIR lowers a checked conversion (a compare and a panic
edge, the D71 shape); the comptime evaluator refuses an out-of-range
value; a lint names the narrow declaration a conversion flows into; the
`.len() as i32` sweep (#2522) follows. Fixtures: the conversion's panic
message, the comptime refusal, the lint's target.

**What would reopen it.** A measured cost of the range checks in a hot
compiler loop that the `isize` positions do not remove.
