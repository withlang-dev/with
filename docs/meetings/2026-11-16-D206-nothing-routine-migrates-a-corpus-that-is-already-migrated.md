# D206 — Nothing routine migrates a corpus that is already migrated

**Laws:** 2 (a fact is produced once: a migrated library is not produced
again to be looked at and thrown away).

**Date:** 2026-11-16. **Status:** ruled by Eric. Supersedes D112's amendment 1
(the re-migration gate) and its nightly drift report; the rest of D112 stands
(the migrator is a pinned input of each corpus; the three promotion triggers;
integrity in every battery; corpora teach no idioms).

**Context.** D112 amendment 1 gated a migrator change on migrating every
corpus into scratch and running its upstream tests there, with a nightly
report of what a re-promotion would change. D131 then put that gate
(`corpus-migrator-gate`, the `<corpus>-test-fresh` lanes) in
`:release-checks`, so every seed cut and release migrated all six corpora and
their test programs afresh, and CI ran `:corpus-drift-report` on every run. A
seed cut on 2026-11-16 stalled on those lanes on three platforms.

**Ruling (Eric, verbatim).** "I never authorized a routine seed cut to migrate
anything (discarded or not). that is senseless waste of time and money. we
need to DEEPLY erase any senseless re-migration of things we have already
migrated." "purge that infinite migration from our routine processes."

**Consequences.**
- A corpus is migrated when it is promoted, and at no other time. The
  promotion triggers are D112's three.
- Removed: `corpus-migrator-gate`, every `<corpus>-test-fresh` lane and the
  `fresh=` mode of the corpus test actions, `corpus-drift-report` with its CI
  step, and the `<stem>-stamp` tool (it migrated a corpus to prove it was
  already today's output; every corpus has its stamp).
- `:release-checks` is the fixpoint, the Sema regression rebuilds, the
  corpora's own tests on the promoted corpora, and wo-drift (each stored
  bundle rebuilt from its promoted source: a compile, not a migration). It
  runs the migrator on nothing.
- The migrator's own tests (`c-migrator-tests`: C fixtures written for the
  tests, no library) move from `:release-checks` to `:test`, where every
  feature's tests are and where every platform's CI runs them.
- `pcre2-test` and `zlib-test` (upstream's tests on the migration being
  promoted) remain, reached only by their corpus's promote.

**What would reopen it.** A migrator regression that reached a promotion and
that only a routine re-migration would have caught earlier.
