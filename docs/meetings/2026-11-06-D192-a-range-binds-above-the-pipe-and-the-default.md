# D192 — A range binds above `|>` and `??`, below the operators that compute its bounds

**Laws:** 1, 3 (docs/mission.md).

**Date:** 2026-11-06. **Status:** delegated (D98, 85%) on #3001, under the
#1 goal (bridge-the-impl-gap.md).

**Ruling.** `..` and `..=` are a precedence level of their own (§9.9 level
7): above `|>` and `??`, below `|` and everything that computes a value.
So `0..n |> map(f)` is `(0..n) |> map(f)`, `a..b ?? c` is `(a..b) ?? c`,
and `0..n + 1` is `0..(n + 1)`. The level is non-associative: `a..b..c`
has no meaning. In a subscript, `xs[a..b]` is the slice it always was, and
`xs[a..]` the open slice; nothing there changes.

**Why.** The §9.9 table had no row for the range operators, so
`for x in 0..3 |> map(it * 2)` parsed the pipe inside the range
(`0..(3 |> map(..))`) and refused `it` as undefined (#3001, found writing
the D186 fixture). A range is a value a pipeline starts from, like a list
or a call; a programmer reading `0..n |> map(f)` sees the range piped.
Putting it below `|>` would make every piped range need parentheses the
compiler already knows how to place: ceremony.

**What the others do.** Rust gives `..` the lowest binary precedence of
all (below `||`), so `a == b..c` is `(a == b)..c`; it has no pipe
operator, so the question this ruling answers never arises there. Go,
Zig and Swift have no infix range operator over which a pipe could bind;
Swift's `...`/`..<` sit above the comparisons and below the arithmetic,
which is this ruling's placement.

**Reopens it.** A stepped range spelling (`a..b..s`) would need the level
to associate, or its own form; a second infix operator with a value
meaning placed between `|>` and `|`.
