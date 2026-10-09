# D112 — The migrator is a pinned input of each corpus

**Date:** 2026-10-08. **Status:** ruled (Eric Hartford). Amends how
`corpus-drift-check` enforces the SDLC ruling in
`docs/proposals/harden_migrate.md`; the ruling itself stands.

**Context.** The SDLC ruling says migrated code is "a pinned, regenerated
artifact… Upstream ships a version we want → update the pin → re-migrate."
`corpus-drift-check` required every checked-in corpus to equal the current
migrator's output, so any migrator change re-promoted every corpus: the
ternary-lowering fix during STC Phase 3 regenerated pcre2 (21 modules), zlib,
c-algorithms and TommyDS. Migrator work scaled with the number of corpora (4
today, toward 100). Zig's translate-c, the nearest reference
(`.reference/translate-c`), is a pinned dependency of each consumer
(`zig fetch --save` records its commit): a translator release never forces
every consumer to regenerate.

**Ruling (Eric, verbatim).** "Take A. The diagnosis is right: the ruling says
re-migrate when the pin moves, and the drift check quietly turned that into
"re-migrate on every migrator change," which makes migrator work scale with
the number of corpora. Pinning the migrator per corpus is the honest reading
of your own SDLC ruling, and the hash keeps "never edit generated code"
enforceable."

A: each corpus records the migrator generation that produced it
(`migrated_by`) and a content hash of its promoted files. Every battery checks
integrity (the files match their hash: no hand edits) and behavior (the
corpus builds and passes its upstream tests with today's compiler). A corpus
is re-migrated when its upstream pin moves or its migrator pin is bumped.

"**1. Gate migrator changes on re-migration, without promotion.** … any PR
that touches the migrator re-migrates every corpus into a scratch directory
and runs each corpus's upstream tests on the fresh output. That's a gate.
Nothing is promoted and no diff lands. You keep the correctness coverage of
today's drift check, and lose only its promotion churn. The nightly then
becomes purely a drift report: which corpora would change, and by how much."

"**2. Stale corpora must not teach.** … The corpora are the largest body of
With code in the tree, and under A they'll increasingly carry old migrator
idioms: hoisted ternary temps, `Vec.new()` plus push chains, `.clone()` on
strings. Agents copy whatever's nearby. So mark corpora as generated in a way
the tooling sees: exclude them from the ceremony census or count them
separately, and add a CLAUDE.md line saying never to take idioms from a
corpus. Their job is to prove the migrator and the compiler work, not to show
how With is written."

"**3. Name the third re-promotion trigger.** … a language ruling that changes
what conforming or idiomatic output is. … The rule: a ruling that breaks or
obsoletes migrator output carries the re-promotion of the affected corpora as
part of its own campaign, batched once per ruling. That keeps the cost
O(rulings) rather than O(migrator changes × corpora), and it means corpora
catch up exactly when the language moves, which is when it matters."

"The old-generation-must-keep-compiling obligation the brief names is real
and worth keeping. It turns the corpora into free backward-compatibility
tests for the compiler, right up until a ruling deliberately breaks them, at
which point amendment 3 takes over."

**Consequences.**
- A corpus is re-promoted for exactly three reasons: its upstream pin moves;
  its migrator pin is bumped to take a fix it needs; a language ruling breaks
  or obsoletes its output (batched once per ruling, in that ruling's
  campaign). A migrator change alone never re-promotes a corpus.
- Every battery: integrity (promoted files match the corpus stamp) and
  behavior (the corpora lanes). A change to the migrator also runs the
  re-migration gate (fresh output into scratch, upstream tests on it). The
  nightly drift report is informational.
- Corpora are generated code to tooling: the ceremony census does not count
  them as written With, and CLAUDE.md forbids taking idioms from them.

**What would reopen it.** A corpus whose old-generation output cannot be kept
compiling without a ruling, or a migrator regression the re-migration gate
did not catch.
