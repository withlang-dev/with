# D230 — In `name @ pattern` the name binds the subject and the inner names observe it

**Laws:** access observes; nothing makes a second owner (D22, D27, D44).

**Date:** 2026-11-22. **Status:** ruled by Eric; the §9.7 sentence is his
and is in v7.82. Implemented (#3543, and the message below).

**Context.** `match move r: Err(err @ .Bad(msg)) => …` gave `err` and `msg`
each the string, and each freed it: a double free in safe code. #3543 made
the outer name the owner and the inner names observers. That refuses a
program that compiled before:

```
whole @ .Click(tag, n) => tag.name.len() as i32 + take(whole)
```

**Ruling.** Keep it. The sentence: "In `name @ pattern`, `name` binds the
subject as a plain binding would, and the names inside the pattern observe
it: each is a binding from a place (§3)."

The message at a move of the origin says what happened, "'whole' is moved
while 'tag' still views it", for every view and not only this one. Its help
names a rewrite that compiles: the inner name is in scope until its block
ends, so reading it in a `let` before the move is not enough inside the arm;
a `match` on a borrow of the value, ended before the move, is.

**Not decided here.** Ending a view at its last use would accept the program
above as written. It relaxes every view, so it is its own question.

**Found on the way.** A match whose arms all bind the whole value
(`whole @ .Click(..)`, `whole @ .Key(..)`) was refused as missing every
variant; `name @ pattern` now covers what its pattern covers.
