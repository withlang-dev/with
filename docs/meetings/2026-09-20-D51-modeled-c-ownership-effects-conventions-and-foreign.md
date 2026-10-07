# D51 — Modeled C: ownership, effects, conventions and foreign lifetimes live in a checked facade; one canonical ruling

**Laws:** 4, 6 (docs/mission.md).

**Date:** 2026-09-20. **Status:** ruled; specification projections blessed
the same day ("Canonized into law") and landed as §16.2b plus the
replacements in §16.2a, §16.3c, §15.3, §16.3d, §18.5 and §18.8
(`docs/modeled-c-spec-projection-draft.md` records the projection and its
traceability). The complete, controlling text is
`docs/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`
(Eric's ruling, 69 sections). As with D22, that file is canonical: this entry
is a pointer, the specification carries conforming projections, and
`docs/modeled-c-implementation-plan.md` is a derivative execution plan that
cannot amend it. Any document, comment, test, TODO or behavior that conflicts
with it is non-conforming.

**Context.** `examples/c-interop` had been cut down to hand-written externs
(e0ce209b) and then rewritten as a Rust-style wrapper module with `unsafe` in
it; `:user-programs-safe` flagged it and Eric ruled that this is exactly what
the gate exists to prevent. The compiler marks a c_imported function raw on
type spelling alone (`SemaDecl.w` ~735-765), §16.2a's auto-methods construct
handles safely with no `Drop` (a leak), and the #357 owning wrapper emits its
constructor as `unsafe fn`. The brief that preceded the ruling, with the
reference-language evidence (all seven `.reference/` trees, cited) and a
survey of real headers, is `docs/completed/modeled-c-decision-brief.md`.

**The ruling, in its own governing sentences.**
> With uses the strongest reliable evidence available, including conventions
> where doing so is safe and useful.

> A convention may be inferred silently when being wrong can only remove
> capability or reject a valid program. A convention that can create memory
> unsafety must be explicit, strongly established, or deliberately trusted.

> Heuristics may suggest; they do not decide safety-critical semantics.

> With proves what it can, trusts what the facade asserts, exploits safe
> conventions where appropriate, refuses what none of those justify, and
> never pretends one category is another.

> A restrictive interpretation is the absence of a proof, not a choice between
> program meanings.

**Shape.** Semantic facts about C (ownership, destruction, consumption,
retention, dependency, independence, status, preservation, nullability,
callbacks, threads, presentation) live in a `c facade name:` block of ordinary
With syntax after `use c_import(...)`. The core abstraction is the *resource*
(opaque pointer, in-place struct, by-value token), never Copy, owning a
foreign representation with a designated `drop` and any alternate
`destroys`. Evidence precedence: explicit facade clause → explicitly adopted,
versioned convention profile → conservative default; ABI/header facts
constrain all; every fact carries provenance that `with analyze` and
diagnostics expose. Unknown independence is dependency; unknown preservation
invalidates; unknown status stays uninterpreted; no `0 == success` rule;
out-parameter production is NULL-initialize-then-inspect; a failed status may
still produce ownership. Strings are `Option[&CStr]` with explicit
`to_str()` / `to_str_lossy()` / `to_owned()`; no `char *` becomes `str`
silently. Foreign-state domains (`errno`) give ownerless C storage an origin.
Resources are creator-thread-bound; `send` requires `drop_any_thread` in v1.
Facades and profiles are versioned packages, never compiler tables.

**Supersedes / narrows.** D4's `retains:` attribute is subsumed by the
facade's `retains … by …` clause (one retention system). §16.2a's "proven
ownership cleanup" paragraph is replaced: name heuristics may shape
presentation only. §16.3c's evidence-source list is replaced by the ruling's
precedence; "package-supplied binding metadata" is a facade package, which
does not revive the per-package compiler tables D46 rejected.

**Non-compliance.** Every existing safe C auto-constructor without a
complete destruction contract (§65) reverts to raw or becomes fully modeled.
The compiler is non-compliant until the facade language is implemented.

**Ordering (§66).** The SQLite facade is written first, against the real
header, and must compile before any example, release UAT, blog sample or
documentation example is rewritten against the new surface: validation
artifacts test the rule, they do not define it.

**Reopen if** a facade-asserted contract class turns out to be unverifiable
in a way that makes safe application code unsound in practice, or a convention
profile is found to need compiler-owned knowledge to work.

---
