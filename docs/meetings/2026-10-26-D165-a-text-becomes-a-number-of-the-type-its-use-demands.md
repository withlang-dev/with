# D165 — A text becomes a number of the type its use demands: `s.parse()`, strict, `Option` (delegated)

Renumbered from the D160 recorded on the unmerged `fix-959` branch
(D160–D162 were taken by stack 11); the decision is that record, plus
the pipeline rule its landing needed.

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-26. **Status:** delegated (D98): implemented on the
predictions below; Eric vetoes by revert. **Issue:** #959.

**Decision.** `str` has one `parse()`: `pub fn parse[T: Parse]() ->
Option[T]`. Its type comes from its use: a typed binding (`let n: i64 =
s.parse() ?? 0`), a `??` whose result is demanded (the demand on a `??`
reaches its carrier as a hint, never as an `Option` demand, D103; #2724),
a parameter. It is strict: None unless the whole text is one value of the
type, in range. An integer is an optional sign and decimal digits; a float
is digits with an optional fraction and exponent, read as the correctly
rounded double. `Parse` (`fn parse_text(text: &str) -> Option[Self]`) is
the trait a type implements to be parsed; std implements it for the
integer types and `f64`. `f32` is not implemented until its parse is
correctly rounded on its own (rounding through `f64` can differ). The
free function `std.string.parse(s) -> i32` is unchanged.

**Also decided (the landing collision).** A generic method is
*applicable* at a pipeline stage (§9.6) only when the stage can
instantiate it — every type parameter determined by the piped value, the
stage's arguments, explicit type arguments, or the demand on the stage's
result. `input |> parse` under a program's own `fn parse` is that
function: `str.parse[T]`'s `T` is determined by nothing at the stage,
so it does not take precedence; under `let n: Option[i64] = text |>
parse` the demand determines `T` and the method applies. With no
same-named free function the method is the meaning and the refusal
names the missing type, as at any call. This extends §9.6's own "if no
applicable method exists" — it does not invert method precedence.

**Context.** `str` had no `parse` method, so a field could not become a
number (`f[1].parse()`: "unknown method"). Eric, reviewing #2127: a
type-suffixed `parse_i64` is "bad, not Withy"; parsing takes its type from
its use. Three Sema gaps stood in the way and are closed here (a generic
method of a builtin owner was never instantiated; a method type
parameter no argument mentions never took the result demand; the third,
the `??` carrier hint, landed earlier as #2724). Landing `str.parse`
broke every `text |> parse` pipeline that named a program's own `parse`
(the battery found it in `behav_pipeline_match` and
`spec_ss09_7_pipeline_match`), which is the applicability rule above.

**What the others do.** Rust: `s.parse::<T>()` over `FromStr`, a
`Result`, strict, typed by inference or turbofish. Go: `strconv.Atoi` /
`ParseInt(s, 10, 64)`, width in the call. Swift: `Int(s)`, an optional,
strict. Zig: `std.fmt.parseInt(T, s, 10)`. Strict whole-text parsing with
an optional result is common to all of them; the type from the use is
Rust's and Swift's. For pipelines: F# and Elixir stages are always
function application (no method lookup to collide with); D's UFCS member
wins unconditionally, which is the collision itself.

**Alternatives.** (a) `parse_i64`/`parse_f64`: the width in the name,
which Eric refused. (b) A `Result` with an error kind: a non-number is
ordinary input, and `?`/`??`/`unwrap_or` read naturally on an `Option`;
nothing so far needs the kind. (c) The explicit form `s.parse[i64]()`
when nothing decides the type: it compiles today (method type arguments
are ordinary), so an undecided use can spell it. (d) For the pipeline: a
program's own declaration always wins over a std method — broader than
needed; it would invert §9.6 where the method *is* instantiable and
plainly meant.

**Prediction.** 85% for `parse()` (Eric stated the shape in the #2127
review); 80% for the applicability reading (the method a stage cannot
instantiate cannot be what the program means when a visible function
fits; a meaning already forced is not spelled again).

**Reopens if** a caller needs to tell an overflow from a malformed text,
or a pipeline stage appears where the uninstantiable method, not the
free function, was meant.
