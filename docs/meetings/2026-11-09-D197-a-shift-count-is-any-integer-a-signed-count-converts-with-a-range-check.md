# D197 — A shift count is any integer; a signed count converts to `u32` with a range check, so a negative count panics (delegated; strikes §4.2.4's cast rule)

**Laws:** 1, 2, 9, 11 (docs/mission.md).

**Date:** 2026-11-09. **Status:** delegated (D98): the mission decides it
(Eric, 2026-11-09: "when the mission clearly decides the issue you don't
need to ask me; that is what the mission is for"); Eric vetoes by revert.
**Issue:** #3072.

**Decision.** §4.2.4's "a right operand of any unsigned integer type; a
signed right operand is a type error; callers must cast explicitly" is
struck. A shift count is any integer type. An unsigned count is taken as
it is; a signed count converts to `u32` as §4.2.6 converts a value at a
narrower demand (D183): with a range check, so a negative count panics
(`integer does not fit \`u32\` (§4.2.6)`). An untyped count stays `u32`
(§4.2.1). D160's `u32` demand on a literal-typed local retires: the shift no
longer needs the local unsigned, so the local is typed by its other uses
(D128, `isize` when none) and converts at the count; the disagreement error
`err_2646_shift_count_and_param_disagree` and `err_shift_signed_count_var`
go with the rule they tested. `with fix-ceremony` removes
count, with the parens that held it.

**Context.** 52 sites in `src/`, `rt/` and `lib/std` wrote
`1 << (slot as u32)`: the count is in every one an `i32` the program
minted (a slot, a bit position, a loop counter). D160's "reopens if a
count's local is wanted as a signed value elsewhere in the same function
often enough that the disagreement error is ceremony" is met by those
sites; D160 listed this decision as its alternative (b) and left it as a
meaning question for §4.2.4, which this entry answers.

**Derivation.** Law 1's test: the cast states the count's unsignedness,
which the compiler knows (the type) and which has no consequence for the
shift (a count in range shifts; one out of range is defined by §4.2.4
either way). Law 2: the count is a demanded site, and an `i32` at a `u32`
demand is the pair §4.2.6 already converts; the shift was the one site
that refused it by type. Law 11's test: the type error could only catch a
count that goes negative by a logic mistake, which is correctness of
intent, not safety; the guarantee that matters, no undefined behavior, is
kept by the range check. Law 9: the struck sentence was a second spelling
of one meaning kept out of habit. No law pulls the other way: no resource
is inferred (laws 4, 5), and no accepted program changes meaning.

**What the others do.** Rust: `Shl`/`Shr` for every integer count type,
signed and unsigned; a negative or oversize count is a debug panic.
Go: any integer count since 1.13; a negative count panics. Swift: a
"smart shift" over any `BinaryInteger`; a negative count shifts the other
way. Zig: the count is `Log2Int(T)`, so an index needs `@intCast`; the
only one that does what §4.2.4 did.

**Alternatives.** (a) Keep the type error and sweep the casts in: Zig's
answer; fails law 1. (b) Swift's negative-shifts-the-other-way: two
meanings for one count, which the mission says the programmer spells;
and a shift by a negative amount is never written on purpose in C-shaped
code. (c) Widen the count to the left operand's type: a second default
for one meaning (D160 chose `u32`).

**Reopens if** a program wants a shift count's negative branch to mean
something (a rotate, a bidirectional shift), which is a new operator, not
a change to this one.
