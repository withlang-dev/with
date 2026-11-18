# D217 — One-liners keep state by position: `-e` before and after the loop, and `last`

**Laws:** 1 (the loop already holds every line, so "this is the final one"
is a fact the compiler has), 4 (a `var` in a loop body means one thing
everywhere).

**Date:** 2026-11-18. **Status:** delegated (D98): not C interop, ownership
or safety; a CLI surface that is easy to reverse; prediction 75%. Eric
vetoes by revert.

**Context.** #957: `-n` and `-p` had no state across lines and no code
after the loop, so a sum, a count, the longest line, `tail -1` and `wc -l`
had no one-liner spelling; each needed `-e` and a hand-written loop.

**Decision.**

- **`last` is bound** to whether the current line is the final one. A
  one-liner that declares its own `last` keeps its own.
- **`-e` by position.** Beside `-n` or `-p`, `-e` code before the first loop
  part runs once before the loop, and `-e` code after the last runs once
  after it: awk's BEGIN and END. `-e` between two loop parts is an error.
- **A `var` in `-n` code is not hoisted.** It is the loop body's and starts
  again on every line, as in any loop.

**Why not hoist a top-level `var`.** In `-n` the code is a loop body, and
hoisting would give the same text a second meaning there. Of the 111
scoreboard tasks with an `-n`/`-p` spelling, 10 declare a top-level `var`
and hoisting changes 9 of them; five would print accumulated text with no
error. Per line and across lines are two meanings, so the programmer
spells which one, by position.

**`last` and code after the loop are different facts.** On empty input
`if last:` never fires, so `tail -1` prints nothing, while code after the
loop still runs and `wc -l` prints `0`.

**Cost.** A one-liner that declares state writes ` -e ''` around the
declaration: five characters against the hoisting form.

**Alternatives.** `-B`/`-E` flags: the same meaning at the same length,
with two more flags to learn. Hoisting plus `-E`, as the issue was filed:
see above.

**What would reopen it.** Position reading as too clever in practice, in
which case `-B`/`-E` say the same.
