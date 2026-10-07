# D107 — A migrated definition's function-pointer parameter is `Option` by evidence (body test, NULL caller, nullable sink), computed as a corpus fixed point; system prototypes stay under D102

**Laws:** 4, 3, 9 (docs/mission.md).

**Date:** 2026-10-06. **Status:** Eric's ruling, verbatim below; the
compiler's migrator is NON-COMPLIANT until it conforms (it wraps every
migrated definition's and project prototype's function-pointer parameter
in `Option` by declaration site, `ClangBridge.w` D102 comment).
**Supersedes** the declaration-site split that shipped with D102's
implementation (PR #2218); D102's rules for prototypes, fields, returns
and globals stand.

## The ruling

> Rule B, but it's not quite the proposal as forwarded — the brief's own
> research changed two things, and the "passes it where a nullable is
> demanded" clause has a consequence the brief didn't draw.
>
> **Take the "nobody does this" finding seriously, then set it aside.**
> Zig, Swift, bindgen, c2rust — none reads the body, and that's worth a
> pause: is it a bad idea or an untried one? I think untried, for a reason
> that doesn't apply here. Those tools are header-first (bindgen,
> ClangImporter) or fidelity-first (c2rust, which wants the Rust to mirror
> the C, ceremony included). None has a corpus-wide migrator whose stated
> product goal is minimal ceremony with a diff tool to audit the result.
> With does. The mission justifies the extra machinery; the question is
> only whether the machinery is sound.
>
> **Three fixes to B before it's ruled:**
>
> 1. *System prototypes aren't "no definition in the corpus."* As
>    written, B says no definition → Option, which would make every libc
>    function pointer optional — Zig's maximal ceremony, and a reversal of
>    D102. B must scope itself: it governs definitions in the corpus and
>    their project prototypes; system-header prototypes stay under D102 as
>    is (non-null unless `nullable param N`). Say it explicitly, or the
>    pre-pass will eat libc.
>
> 2. *Caller evidence, not just body evidence.* The brief's Law 4 story is
>    "wrong = always-succeeding unwrap," but B can be wrong the *other*
>    way: a body that stores the pointer into a struct or forwards it to
>    code outside the corpus never tests it, so B says non-null — and then
>    a legal C call passing NULL (pcre2's own `pcre2_set_callout(ctx, NULL,
>    NULL)` is the pattern) fails to migrate. That's safe (a compile error,
>    not unsafety), but it's a Law 1 cost the migrator can avoid, because a
>    NULL literal at a corpus call site is itself evidence of nullability.
>    Add it. Body tests OR a corpus caller passing NULL → Option.
>
> 3. *This is a fixed point, not a pre-pass.* "Passes it where a nullable
>    is demanded" makes f's verdict depend on g's verdict (and on
>    struct-field nullability if the pointer is stored). Plus caller
>    evidence from (2). That's a least-fixed-point computation over the
>    corpus — which is fine, the comptime-callability ruling just approved
>    the same shape — but it needs its safe default stated: on cycles or
>    unresolved dependencies, Option. And it gives you determinism for
>    free, which the brief's "every unit agrees with the definition"
>    concern needs anyway: the verdict can't depend on unit order.
>
> **One classification bug in the evidence rule:** "truth-tests it" lumps
> `if (cb) cb(x);` with `assert(cb != NULL);`. The first says NULL is a
> handled case; the second says NULL is a *contract violation*. An assert
> (or any test whose failure branch aborts) is evidence of non-null, not
> nullability. Distinguish them, or every defensively-written library
> migrates with gratuitous `Some`.
>
> With those four, B is the right ruling: nullability gets one owner (Law
> 3), the asymmetry survives only where C's semantics require it (Law 9),
> the direction is still safe (Law 4), and `migrate_diff` turns the whole
> thing into an auditable change on pcre2/zlib/tommyds. The fixture
> changing is expected and fine. I'd also ask that the pre-pass emit its
> verdict reasoning per function — "Option: body tests at line N" /
> "Option: caller at X passes NULL" / "non-null: called unconditionally,
> no NULL callers" — so the first disagreement with it is a one-line
> diagnosis rather than a re-derivation.

## The brief it answers (summary)

References (`.reference/`): Zig translate-c makes every function pointer
`?*const fn`; Swift imports an unannotated pointer parameter as an
implicitly-unwrapped optional; bindgen/c2rust use `Option<unsafe extern
"C" fn>` unconditionally; cgo has no nullability. None reads a body. The
spec (§16.6): a function-pointer parameter imports non-null; `nullable
param N` is the facade's claim, never inferred from a name. The shipped
split (definition → `Option`, system prototype → non-null, project
prototype → `Option` for cross-unit agreement) was the implementation's
reading, not blessed text. Options: A blanket (shipped), B evidence, C
non-null with an `Option` local copy (left out: refuses legal C such as
`pcre2_set_callout(ctx, NULL, NULL)`). Prediction: B, 85%.

## Implementation (conforming projection)

- **Scope.** Definitions in the migrated corpus and the project
  prototypes that declare them. A prototype from a system header keeps
  D102: non-null unless `nullable param N`.
- **Evidence for `Option`** on parameter `p` of definition `f`: (a) the
  body tests `p` for NULL — `p == NULL`, `p != NULL`, `!p`, `if (p)`,
  `p ? … : …` — where the NULL branch continues; a test whose NULL branch
  aborts (`assert(p)`, `assert(p != NULL)`, an `abort()`/`exit()`/
  `__builtin_trap()` branch) is evidence of *non-null*; (b) a call site in
  the corpus passes a NULL literal (or a null-like `(T)0`) at that
  position; (c) the body passes `p` where a nullable is demanded: an
  `Option` parameter of a corpus definition (the fixed point), a record
  field (fields are nullable under D102), a global of `Option` type.
- **Fixed point.** Least fixed point over the corpus: start every
  in-scope parameter non-null, add `Option` from (a) and (b), then iterate
  (c) until no verdict changes; a dependency on a function with no
  definition in the corpus (outside system headers) or an unanalyzable
  body is `Option`; a cycle resolves to `Option` for every member. The
  verdict is a function of the corpus, never of unit order; every unit
  renders the same type for `f`'s parameter.
- **Reasoning.** The migrator records and prints one line per decided
  parameter — `f param 2: Option: body tests at line N` / `Option: caller
  g at X passes NULL` / `Option: passed to h param 1` / `non-null: called
  unconditionally, no NULL callers` — into the migration log and the
  shared defs manifest.
- **Pins.** `bs_check_migrate_nullable_fn_pointer` gains the four cases
  (handled test, assert, NULL caller, store into a field) and the
  non-null case; `migrate_diff` audits the corpora; the corpora are
  re-promoted.
