# D191 — The indentation of a `|>` line decides what its left-hand side includes

**Laws:** 1 (docs/mission.md).

**Date:** 2026-11-02. **Status:** ruled by Eric, on examples/fizzbuzz.w.

**Ruling (Eric's words).** "The tab should decide what the LHS of `|>`
includes."

**What it means.** A line that begins with `|>` (and, by the same rule,
`<|` or `??`) continues the expression whose line is indented no more
than the operator's line. At the column of a `match` it pipes the whole
match, arms and all; indented under an operand (`let total = xs` then
`    |> sum()`) it continues that operand, as it always did. A line
indented less than the line its operand starts on belongs to an
enclosing expression, never to the innermost one that happened to be
open.

**Why.** The parser is column-driven everywhere else: a body belongs to
the construct it is indented under (§29.13), a match's arms end where the
column returns, a `for`'s `else` is the one at the `for`'s column. A
`|>` line was the one place the column was ignored and the operator
attached to the innermost expression however deep, so in fizzbuzz
`|> print` at the match's column printed only the `_` arm (Law 1: a
person reads the column). Scala 3 under significant indentation reads a
leading infix operator the same way.

**Reopens it.** Nothing foreseen; a `|>` dedented below its own statement
no longer parses as a continuation, which reads as the mistake it is.
