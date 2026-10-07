# D28 — str flips owned+Drop; view tokens lose Copy interim; ephemeral view-structs are the token shape; roundtrip migrate pins its cap until the flip

**Laws:** 5, 9 (docs/mission.md).

**Date:** 2026-07-31
**Status:** Ruled by Eric ("your predictions are both correct. Proceed with my
blessing.") on the two-ruling #744 brief. Answers D27's reopen clause and the
audit note it left open ("the #691 str flip must decide what `Copy` means for
str-bearing structs").

**Ruling 1 — str is owned and drops; Copy-with-str-fields ends with the flip.**
§2.3 rules 1–3 and §15.1 already classify `str` (= `String`) as owning+Drop
and recursively exclude it from `Copy`; the flip makes the text true at
runtime. The shipped Copy-with-str tokens (`JsonView`, `Package`,
`ProjectInfo`, `Diagnostics`) lose `Copy` as interim conformance — boundaries
borrow, and D5 auto-referencing keeps every call site spelled identically.
The remaining `impl Copy` sites (~95) are audited for str-bearing fields in
the flip campaign. Rejected: Swift-style CoW/ARC str (hidden refcount per
implicit copy — invisible cost) and Vale-style shared-immutable str (Vale
classifies `StrT` as `ShareT`/`ImmutableT` — verified in
`.reference/Vale/Frontend/TypingPass/src/dev/vale/typing/Compiler.scala:1655`
— a share-managed memory doctrine that forks "every allocation is owned...
its owner's scope releases it").

**Ruling 2 — ephemeral view-structs are the view-token mechanism's new
shape.** §3.3 bans reference fields, so a token cannot respell `str` fields
as `&str`; D27 ruling 1's reopen clause anticipated exactly this ("mechanism,
not intent"). Destination: extend the existing `ephemeral` type marker
(`ScopedJoinHandle` precedent; §3.4 propagation) to structs with view
fields — such a struct is itself second-class (param/local/return only, no
heap storage, no escape) and may opt into `Copy`. When it lands, `JsonView`
re-acquires by-value Copy and D27 ruling 1's declared signatures stand
unchanged. Separate campaign; normative spec wording goes to Eric before it
lands.

**Ruling 3 — the roundtrip's migrate step pins its memory cap until the
flip.** Per-step `WITH_MEMORY_LIMIT_BYTES=0` in `emitc_migrate_compiler_c`
only, with the revert condition named in the code (delete with the str
flip). Grounded in the #608/#693 pin doctrine: a gate red for one known,
scheduled cause stops discovering everything queued behind it (#746 was
invisible until migration could complete). The cap stays live for every
other step. Measured basis: 68.4 GB peak migrating the 48 MB compiler C,
entirely transient strings pending the flip (#744 investigation).

**Reopen if:** the flip audit finds a de-Copy'd site that breaks a shipped
surface D5 auto-ref cannot absorb (surface to Eric; do not narrow), or
ephemeral view-struct origin tracking proves irreconcilable with §3.4's
propagation chains.

---
