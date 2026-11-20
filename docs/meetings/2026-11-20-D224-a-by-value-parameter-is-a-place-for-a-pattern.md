# D224 — A by-value parameter is a place for a pattern; only a temporary and `move` are owned subjects

**Laws:** 4 (one spelling, one meaning), D115 (the blessed §9.7 words name a
temporary and a place moved with `move`, nothing else), D144 (a local is a
place).

**Date:** 2026-11-20. **Status:** ruled by Eric ("B, count first", then
"go"). §9.7's words do not change: they are D115's.

**Context.** The compiler took a by-value parameter apart under a bare
`match x` and observed a local under the same text. D144's entry reported
that as "§9.7 lists … a parameter", which §9.7 never did (corrected
2026-11-19). The effect was observable: a read-only match dropped a
parameter's payload inside the match and made the parameter unusable
afterwards; the same match on a `let` did neither.

**Decision.** A pattern's subject is owned when it is a temporary or is
moved with `move`. Every other subject is a place and is observed: a local,
a parameter of any mode, a receiver of any mode, a field, an element.
`match move x` takes a place apart.

**The count that preceded it** (a compiler built with the rule, tracing
every pattern on a by-value parameter of a type that is not plain bits;
values copy, so only resource-holding types can differ): 13 sites in 6 test
files, none in `src/`, `lib/`, `rt/`, `tools/`, `build/`, the bundled
corpora, the examples or the UAT scenarios. Two sites (one test) needed
`move`. No lock, file or task was matched as a by-value parameter.

**Not chosen.** (A) Keep the asymmetry: no ruling ever made it. (C) Take
the subject apart when an arm takes a binding and observe otherwise: no
`move` at all, but it reopens D144 and lets one arm's body change what the
others see; a count of two did not justify it.

**Consequences.** The "cannot consume read-only view binding" error names
`match move x`. The #3461 diagnostic "the list pattern took `xs` apart" is
deleted: a parameter is taken apart only where the program wrote `move`.

**Reopen if** programs outside this tree show the `move` on consuming
matches is common enough to read as ceremony; option C is then the
candidate.
