# D58 — The `else` of `let ... else` takes a body or a same-line diverging expression

**Date:** 2026-09-22. **Status:** BDFL ruling (Eric: "b", then "blessed,
same-line only. if they want next line they MUST use colon."); §9.7,
§29.13 and §30.4 carry the blessed text.

**Decision.** `let PATTERN = EXPR else` is followed either by a body in any
of the three §29.13 forms (`else: stmt`, `else:` + indented block,
`else { ... }`) or by a single diverging expression on the same line
(`else return Err(.NotFound)`). Anything on the next line needs the colon:
`else` + newline + an indented block with no introducer is a parse error.
`VAR_STMT` takes a `PATTERN` like `LET_STMT` (it said `IDENT`, contradicting
§9.7's "all pattern forms are available in `let`/`var`"), and both take the
optional `LET_ELSE`.

**Why.** Eric: "I know purists will poo poo this. but this is
*quintessential* to With. We do right by the USER." The one-line guard —
bind or bail — is the most common let-else there is; making the programmer
type a colon there buys grammar uniformity, not a caught mistake.

**Context.** §9.7 wrote `else return …` with no colon while §29.13 required `:`
or `{` after every `else`; the grammar had no let-else at all. The
same-line bare expression is the shortest spelling of the common case
(Zig's `x orelse return err` is the precedent, `grammar.peg:334`); Rust
(`parse_block()` after `else`, `rustc_parse/src/parser/stmt.rs:406`) and
Swift (`guard … else` needs braces, `ParseStmt.cpp:2075`) require a block.
Allowing the bare form only on the same line keeps the no-introducer shape
an error everywhere else in the language: let-else is the single, visible
exception, and a multi-line branch looks like every other body.

**Alternatives.** (a) One form, `else` + BODY only (§9.7's examples would
gain a colon). (c) A bare expression only — rejected, it cannot express a
multi-statement branch. A next-line bare expression was offered and
refused: "if they want next line they MUST use colon."

**Reopens if** the same-line form proves to hide a real mistake the colon
would catch.

---
