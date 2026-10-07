# D29 — Name resolution: implicit std availability as a lowest-priority fallback tier; #750 resolved by staged conformance

**Laws:** 1, 9 (docs/mission.md).

**Date:** 2026-08-01
**Status:** Ruled by Eric ("BDFL has spoken."), verbatim directive below.
Normative from the spec update landing with this entry (§18.2). The spec is
deliberately ahead of the implementation: it describes the destination (the
fallback tier), while the implementation reaches it in stages (work items
below). Supersedes the flat injection of lib/std names that #750 documented;
extends D28's chain toward the roundtrip.

**Ruling (verbatim):**

> The destination design is implicit standard-library availability. Every
> public declaration of std is available by its unqualified name as the
> lowest-priority resolution tier. Fallback declarations retain canonical
> module identity — this tier is a lookup fallback, never injection into the
> module's declaration table. Precedence order: lexical bindings and generic
> parameters, current-module declarations, explicit imports/aliases, prelude,
> unique std fallback. A user-controlled declaration is never shadowed,
> merged, or impl-captured by this tier. Fallback matching is exact — no
> fuzzy matching, ever. Two or more std candidates for one name is a hard
> ambiguity error, with each candidate offered as an insertable-import
> fix-it; candidate ranking may order suggestions but never resolves. In
> impl and extend headers, a non-prelude std name may not resolve through
> fallback alone — explicit import or qualified path required. Compatibility
> invariant: a std addition may turn a unique fallback resolution into an
> ambiguity, but may never rebind an existing resolution. Engine packages
> are ordinary explicit dependencies and are never ambient; a public
> re-export from std is deliberate promotion into the ambient vocabulary.
> The prelude's enumerated list is retained; its role narrows to (a) names
> permitted bare in impl/extend headers and (b) the --no-std core. Do not
> add HashMap/HashSet or anything else to it.

**Work items (staged):**

1. **#750 unblock — scaffolding, the roundtrip gate.** Option A narrowly,
   labeled *scaffolding* in every commit message and doc comment: remove
   flat injection of lib/std declarations into user modules; enforce the
   §18.2 prelude exactly as enumerated with §18.1 precedence (user wins);
   std internals resolve their own names via the existing tier machinery;
   ship a fix-it inserting the missing `use` for any unresolved name
   uniquely matching a public std declaration, applied automatically by the
   migrator to its own output; migrate the affected behavior tests via the
   fix-it, not by hand, forking (not overwriting) the import-free originals
   into a quarantined suite named as the D acceptance corpus. Acceptance:
   roundtrip output compiles; `type Regex { r: i32 }` resolves to the
   user's type; `impl Copy for CString` attaches to the user's type; the
   string.w module-drop probe no longer rebinds Display impls; all 935
   behavior tests green post-migration.
2. **B campaign (filed, not started):** canonical module-qualified identity
   for every declaration, carried through impl attachment, trait
   resolution/coherence, generic instantiation, MIR, comptime, all
   backends, and the migrator — no short-name re-resolution after initial
   lookup, anywhere. Sequenced after the #747 str flip unless Eric
   re-orders.
3. **D activation (filed, blocked on B):** enable the fallback tier per the
   ruling; impl/extend-header restriction; ambiguity diagnostic with
   insertable-import fix-its and context-aware ranking; `with update`
   records prior fallback resolutions and inserts pinning imports as a
   reviewable migration (ships with or before the tier — hard requirement);
   `with explain-name` / resolved-path-on-hover observability;
   migrator/formatter removes `use` lines that become redundant, including
   the ones item 1 inserted; un-quarantine the D acceptance corpus as the
   activation test; migrator targets std shims where coverage exists,
   otherwise emits explicit engine dependency + qualified calls, logging
   emitted engine paths as the shim-priority worklist.

**Rejected (do not build, do not re-propose):** option C or any
migrate-only/lean-prelude build mode; prelude-list expansion; fuzzy or
ranked resolution; any "surprising symbol" lint or second curation surface
in tooling; flat injection in any form.

**Escalate, don't decide:** any change to the ruling text; any new
normative spec wording; anything making fallback resolution order- or
ranking-dependent; the shim naming policy for common nouns
(Connection/Config/Error) when it first bites.

---
