# D74 — Entry sources, optional-chain field moves, and the field-view examples

**Laws:** 5 (docs/mission.md).

**Date:** 2026-09-27. **Status:** BDFL ruling (Eric: "1) yes … 3) yes", then
"yes" to the entry-source sentence).

1. **Entry sources (§18.5b, #1759).** The old sentence "Ordinary module
   files require an explicit `fn main`" read as if a library needed one
   (Eric: "what if they are just libraries intended to be used by other
   programs?"). It never did: a module file holds declarations. A file whose
   top level also holds executable statements is an entry source; those
   statements are its `main`, and it may not also declare `fn main`. An
   imported module may not hold executable statements. `run`, `build`,
   `check` and `test` apply one rule, so `with check tools/battery.w` accepts
   what `with run` accepts.
2. **Optional chains (§10.3, #1710).** `o?.a` on a named place moved the
   whole base into a temporary with no move recorded, so `o` read empty
   afterward. Ruled as D22/D73 already imply: a chain on a named place reads
   it, so `expr?.field` yields `Option[&U]`, a view; an owned demand on a
   non-`Copy` payload gets the clone fix-it; a chain on a temporary yields
   the owned `Option[U]`. (A first draft refused non-`Copy` chains outright,
   which contradicted §10.3's own `profile.address?.zip` example; the
   implementing agent caught it.) This is D22's stage-4 chain-view work;
   until it lands the compiler records the move it makes today, so a later
   use of the base is "use of moved value" rather than a silent blank.
3. **Examples (#1531).** The compiler now binds an unannotated `let` of a
   `Copy` field as a view, as §3.8/D27 already said. That refused one line
   each in `examples/json-parser/json.w` and `examples/ecs/src/world.w`;
   they are respelled with the fix-it (`let x: T = s.n`). Per D55 ruling 4
   and the §18.3 precedent, the examples were the non-conforming side.

---
