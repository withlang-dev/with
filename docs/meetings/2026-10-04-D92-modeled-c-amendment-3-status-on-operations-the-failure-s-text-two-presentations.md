# D92 — Modeled-C Amendment 3: `ok` on a status-returning operation, the failure's text, two presentations of one function

**Date:** 2026-10-04. **Status:** BDFL ruling (Eric: "amendment 3
blessed"). The words are Amendment 3 of
`Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`;
spec v7.22 §16.2b.4, §16.2b.11. **The implementation is NON-COMPLIANT
until it catches up.**

**The question.** The SQLite facade is the example everyone reads, and its
fixture still compared status codes by hand: `db.exec(sql, None, None) !=
SQLITE_OK`, `stmt.step() != SQLITE_ROW`. The ruling's §17 and Amendment 1
gave `ok` to a *producing* declaration only, and the compiler conformed: on
`sqlite3_exec` it refused `ok SQLITE_OK` ("there is no value to present on
success"), and on `sqlite3_step` it refused a list ("an fn item's `ok` …
names one").

**Decision.** Three additions, in Eric's blessed words (the amendment):

1. An fn item whose C function returns a status may state `ok`, with one
   constant (`Result[T, E]`, `T` being `Unit` when the operation presents
   nothing else) or several (`T` carries the status that matched).
2. A resource may name the operation that describes its most recent
   failure (`message sqlite3_errmsg`); an error from an operation on that
   resource then carries `message: str`, an owned copy read before any
   other operation on the resource.
3. An fn item may be written more than once when each states a distinct
   `rename`; each is a presentation with its own fixed parameters.

What the fixture should then show (Eric): `db.exec(sql)?` with no
`None, None` (the callback form is a second presented method);
`stmt.step()` distinguishing row from done as values, with real failures
as errors (`while stmt.step()? == SQLITE_ROW:`); and an error that prints
SQLite's own message. If iterating rows needs more than `ok` can express,
the fixture stops at `step()` and the iterator is its own facade question.

**Why.** A status the header defines, compared by hand at every call, is
the programmer writing what the program already determined, and nothing
makes them write it: the unchecked call compiles. `?` on a `Result` is the
guardrail. Without the message, `?` would turn a useful SQL error into a
bare number.

**References.** None of the reference languages has a declarative layer
here: Zig and Swift import the C function as it is, and Rust's wrappers
(rusqlite) do this by hand. This is With's own ground.

**The fixture is Eric's.** `uat/fixtures/sqlite3_main.w` is a UAT contract:
the implementation's PR carries the new fixture text for his approval and
does not merge before it.

**Reopen if** a library's failure text is not a function of the resource
alone (it needs the failing status, or a thread-local): the `message`
clause then needs a parameter, by a ruling.
