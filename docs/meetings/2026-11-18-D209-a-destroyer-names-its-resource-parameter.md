# D209 — A destroyer names the parameter that receives the resource

**Laws:** 1 (the contract says once what the wrapper would otherwise make the
program do by hand), D51 (which pointer is destroyed is stated, never drawn
from a position).

**Date:** 2026-11-18. **Status:** ruled by Eric. The words are §31's.

**Context.** #3177: `drop f` and `destroys f` took the resource as the
function's first parameter. `BZ2_bzReadClose(int *bzerror, BZFILE *b)` puts
it second, so no line could state it: 20 functions in 6 libraries stayed raw.
The producing side already had the spelling (`from f(out param N)`,
`init f(self)`).

**Ruling.**

- `destroys f(param N)` and `drop f(param N)`: the parenthesized parameter
  receives the resource; without the parentheses, the first.
- `drop f(param N)` requires every other parameter fixed, since `Drop` has
  nothing else to pass.
- An out-parameter can be fixed as discarded: the wrapper passes scratch
  storage and ignores what C writes. The spelling is `param p discarded`.
- bzip2 then has both: `drop BZ2_bzReadClose(param 1)` with the error
  discarded, and `destroys BZ2_bzReadClose(param 1)` as the explicit close
  for a caller who wants the status.

**Why `discarded` and not a literal.** `param p fixed null` would hand C a
null pointer to write through. The destroyer needs somewhere to write; the
program does not need what it wrote.

**Reopen if** a destroyer's out-parameter carries something the program must
see for safety (not only a status), which a discard would hide.
