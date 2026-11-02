# D190 — `?` in main: an `Err` that reaches main ends the program

**Laws:** 1, 3 (docs/mission.md).

**Date:** 2026-11-02. **Status:** delegated (D98, 90%) on #2935, under the
#1 goal (bridge-the-impl-gap.md, item 2).

**Ruling.** In `main` — `fn main:` with no declared return type, or the
implicit main of a script (§29.15) — `?` on a `Result` needs no `Result`
return: an `Err` it meets is the program's outcome. The error is written
to stderr in its `Debug` form after `error: `, and the process exits with
status 1. Nothing after the `?` runs; no backtrace is printed (it is an
error, not a panic). A `?` inside a closure in main is the closure's and
follows §10.2's ordinary rule. `?` on an `Option` in main is unchanged
(an absent value is not an error message).

**Why.** The mission says the sad path is spelled `?` and nothing else:
`Ok(())`, `unwrap()`, a hand-written `-> Result[(), E]` on main are
ceremony the compiler already knows the answer to (what else could an
`Err` reaching the program's root mean?). The script tools written on
2026-11-02 each carried `.unwrap()` for exactly this reason (#2935), and
improve_oneliners.md had listed the gap since the one-liner audit.

**What the others do.** Rust: `fn main() -> Result<(), E>` with `E:
Debug`, prints `Error: {e:?}`, exit 1; the signature is written by hand.
Swift and Go: no `?`; a top-level `try` in a Swift script traps on an
uncaught error. Zig: `pub fn main() !void`, the error name, exit 1. With
takes Rust's outcome (Debug, exit 1) and drops the signature.

**Reopens it.** A `Display`-first rendering once every std error has one
(the Debug form quotes a `str` error: `error: "bad"`); `?` on `Option` in
main; `fn main -> Result`, which this ruling does not define.
