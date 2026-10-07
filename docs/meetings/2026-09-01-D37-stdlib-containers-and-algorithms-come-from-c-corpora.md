# D37 — Stdlib containers and algorithms come from C corpora migrated whole; `with migrate` is raw, the With-ness lives in the facade

**Laws:** 8, 9 (docs/mission.md).

**Date:** 2026-09-01
**Status:** Ruled by Eric. Verbatim: "we dont 'selectively migrate' — but
we do 'selectively facade'"; "with migrate should be raw / the Withyness
resides in the facade". Plan: `docs/stdlib_sourcing_plan.md`.

**Decision.** The stdlib's data structures and algorithms are sourced from
three C corpora migrated **whole** — c-algorithms, TommyDS, STC — plus a
surgical port of M*LIB's `m-bptree.h`; the With stdlib is a facade that
selects and exposes engines. `with migrate` produces a raw, faithful,
C-shaped transpile (one concrete copy per template instantiation the
corpus contains, `void*`/`elem_size`/callback genericity, raw pointers)
and adds no ownership modeling, generic lifting, or ergonomics. Every
With-ism — views, transfers, drops, generic surfaces, complexity
contracts — is the facade's. Native code is reserved for what migration
provenance cannot beat: graph algorithms, union-find, and SlotMap's free
list. The original native-Vec exception is superseded by the follow-on
selection below; With's `str` semantics remain the public contract.

**Follow-on selection (Eric, 2026-09-12).** The
[facade map](stdlib_sourcing_plan.md#facade-and-engine-selection--erics-ruling-2026-09-12)
selects STC for everyday containers and algorithms, including `Vec`,
`hmap`/`hset` for the default owning hash collections, and `smap`/`sset`
for `OrderedMap`/`OrderedSet`. STC's inline entries and compact Robin Hood
metadata fit an owning generic map. M*LIB's B+ tree supplies
`BTreeMap`/`BTreeSet`; c-algorithms supplies classical engines and
references; TommyDS supplies specialized indexing/storage. Corpus names
need not become public types. Benchmarks validate these selections and
compare alternatives; they no longer leave the default engine undecided.

**Context.** #936 (SlotMap O(n) insert, no free list) prompted a survey
that found the same species in BTreeMap/BTreeSet (#937, linear lookup,
O(n²) insert), consuming iteration (#938), HashMap delete (#939), and no
sort at all (#940). The containers had been written to pass fixtures with
nothing measuring complexity.

**Alternatives.** Native rewrites (rejected: repeats the failure mode and
forgoes decades of tuning); a C wrapper (rejected: a foreign boundary the
ownership model cannot see through; also not self-hosted); migrating
pieces of corpora (rejected: partial forks lose the shared machinery a
library evolved with, and the un-facaded code is coverage, alternates,
and a migrator bug corpus); lifting templates to With generics inside the
migrator (rejected: With-ness belongs in one place, the facade; the
migrator stays a transpiler whose correctness is checkable against the
upstream's own tests).

**Reasoning.** Migration is With's first-class path ("modeled C becomes
humane"), and this is its largest dogfooding: three real corpora, one of
them (STC) a deliberate macro-migrator hardening campaign. Keeping the
migrator raw keeps its oracle simple — the upstream's tests must pass
under With — and keeps every design choice about ownership and ergonomics
in the facade, where the drop audit and complexity fixtures can hold it.
Reopen if a corpus's raw form proves unusable behind any facade (the
signal would be a facade that cannot express its engine's ownership), or
if the STC instantiation-set question in the plan's Phase 3 has no
benchmark-backed answer.

---
