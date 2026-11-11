# D199 — A compiler that cannot read the registry's facts for a package uses the facts its own release published (delegated, D98)

**Laws:** 8 (the toolchain absorbs the environment, within a boundary), 7
(fail loudly or do the work).

**Date:** 2026-11-11. **Status:** delegated (D98): not C interop, ownership
or safety, a revert undoes it. Amends D136's "tip of `main`". The sentence
for `package-management.md` waits for Eric's words.

**Context.** D136: `with get` reads `registry/c/<package>/facts.w` at the
tip of `main` and pins the commit in `lock.json`. The facts language grows
(`runs threads` and `from F, nullable field a.b` reached main on
2026-11-11), so main's file for raylib is one no compiler built before that
day reads. #3241 made the refusal loud: `with get c.raylib` fails by name on
every released compiler. Loud, and still broken for a user who did nothing.

**Decision.** When the reader refuses main's file, the compiler reads the
package's file at the commit its own version tags (`v0.16.0.8`), says so
(`note: the registry's facts for raylib need a newer compiler (<line>:
<reason>); using the facts v0.16.0.8 published`), and pins that commit. A
release's battery runs over its own tree's registry, so those are the
newest facts the compiler provably reads. When the release published no
file for the package, none are used, with the same note. A build whose
version no tag names, and a `WITH_REGISTRY` mirror with no
`WITH_REGISTRY_RELEASE`, have no fallback and fail by name as before.

**Alternatives.** Read the registry at the release tag always: deterministic,
but a released compiler never receives a fact reviewed after it shipped,
which is the point of a shared registry (D121). A versioned path per facts
grammar (`facts.v2.w`): a copy per grammar generation for every package,
which does not survive 20,000 packages. Skip the lines the reader does not
know: a facade from half a facts file is a plausible wrong thing (law 7).

**Reopen if** a fact must be withdrawn for safety from compilers already
released: the fallback would keep serving the withdrawn fact from the tag.
