# D185 — One comprehension family: the bracket form over `Option` and `Result`; the `yield` expression form is retired; the statement form stays

**Laws:** 1, 2, 9 (docs/mission.md).

**Date:** 2026-11-02. **Status:** ruled by Eric on the brief for #2960.

**Ruling (Eric's words).** "`[x + y for x in a for y in b]` over `Option`
with the first clause fixing the carrier, retire the `yield` expression
form, keep the statement form because nothing else says 'run this when
every clause succeeds.' The one thing the spec must say: a bracket
comprehension over `Option`/`Result` produces an `Option`/`Result` of the
element, never a `List` of one element. That's where someone reading
`[x for x in a]` over an `Option` will guess wrong, and it should be in
the sentence, not inferred from §13.6a."

**What it means.** The bracket comprehension is the one expression form.
Its first clause fixes the carrier: a collection or range builds the
demanded collection (§13.6); an `Option` or `Result` builds an `Option`
or `Result` of the element, never a `List` of one element, unwrapping
each clause and short-circuiting on `None`/`Err`; a guard that fails
yields `None` (a `Result` comprehension chooses its `Err` with an
explicit `if`/`match`). The `for a in x; b in y: yield e` expression form
is retired (Law 9: two spellings of one meaning). The statement form,
`for a in x; b in y:` with a body and no `yield`, stays: it runs the body
only when every clause succeeds, and no bracket form says that.

**Why.** Law 9's test: the `yield` form was a second spelling of the
bracket form's meaning; the statement form is the unique spelling of its
own. Law 2: the carrier comes from the first clause's own type before any
outer demand. Scala's one `for … yield` over `List` and `Option` is the
reference.

**Implementation.** Sema accepts an `Option`/`Result` first clause in a
bracket comprehension and types the result as the carrier of the element;
the `yield` form becomes an error naming the bracket form; fixtures for
Option, Result, a guard, and the statement form unchanged.
