# D79 — A bundle function's global writes are a declared, checked `writes` clause, never an inferred interface fact

**Laws:** 6, 4 (docs/mission.md).

**Date:** 2026-09-29. **Status:** BDFL ruling (Eric: "B", the spelling
"Option 1", then "blessed" on the words). Spec v7.13:
toolchain/wo_bundles.md "Global writes are the declaration", grammar
`WRITES_CLAUSE`. Refines D39. Issues #1827, #1819.

**Amended 2026-10-03 by D84** (Eric approved; #1903): where this entry
says "only exported globals" appear or count, it now reads "exported
globals, and every global that is an origin of an exported function's
returned view". A global origin is part of the function's interface
(§21.1 rule 6), so a write to it can conflict with a caller's view even
when the global is not exported.

**Context.** §21.1 rule 1 makes a call write every global its callee
writes, so a view of a global may not be live across such a call. For a
bundle function the caller has no body. 1288aa57 assumed every bundle call
writes every exported global of its bundle, which refused valid programs
(tommyds `check_`: `tommy_hash_u32` is a pure hash). 84a6d046 inferred the
exact set and emitted it into the `.wi` as `@[writes(...)]`, which D39
forbids ("No body-inferred ownership/effect information is part of the
bundle interface").

**Decision.** (B) The write set is part of the declaration: a trailing
`writes COUNTER, other.TOTAL` clause on a bundle's `pub` function, always
the last clause (after `-> R` and any future `from a`). Absent means
"writes no exported global", verified against the body. A superset warns.
Only exported globals appear. A caller of another bundle's function
declares at least that callee's set, checked from the two interfaces. Whole
globals only in v1; qualified paths from the start; `writes` is contextual;
source and `.wi` print one spelling; the diagnostic for an omitted write
offers the literal clause to insert. 84a6d046's Sema pass becomes the
checker of the declaration instead of its emitter.

**Why.** Go's escape tags (`escape.go:289`, "Record parameter tags for
package export data") are optimization facts: a body change alters the
code callers get, never which programs are legal. A global write set is a
legality fact: inferred into the `.wi`, a bundle author adding one write
silently breaks every downstream caller holding a view, with no change to
anything they declared — the invisible interface change D39 exists to
prevent, and why `&T` vs `T` is in the signature. A declared, checked
contract turns that edit into a build failure in the bundle, where the
author sees it. One trailing-clause family (`from a`, `writes X`) keeps
both boundary contracts reading as part of the declaration; an attribute
would read as metadata.

**Cheap by construction.** Absent means none, only exported globals count,
only bundle `pub` functions carry it, the migrator emits it for C corpora
(whose mutable state is usually file-static), and the fix-it writes it.
SPARK's `Global` contracts (from memory; not in `.reference`) are the one
real precedent for a declared, checked global contract; their reputation
for weight came from being pervasive and fine-grained, which this avoids.

**Alternatives.** (A) amend D39 to let the `.wi` carry the inferred set —
Go's weaker guarantee. Keeping the over-approximation — refuses correct
programs. `@[writes(...)]`, `writes(...)` lists, `uses mut X` — rejected
spellings (metadata reading; a future `reads` wants its own clause; the
last inverts the relationship and spends a keyword).

**Reopen if** a real library needs field-granular writes, or a caller
needs `reads` contracts for its own views.
