# D13 — Commit-derived compiler versions are post-link metadata, never compiled inputs

**Laws:** 8 (docs/mission.md).

**Date:** 2026-07-17
**Status:** Accepted — implementation tracked by #650. **Deciders:** Eric (BDFL)

### The decision

The compiler's commit-derived version is provenance metadata. It must never be
substituted into generated source, object code, or any other hashed input of the
native compiler stage/link chain. The expensive compiler build embeds a stable,
fixed-width sentinel and produces `with.unstamped`; a separate cheap `build`
action tracks `.git/HEAD`, its resolved ref, and `WITH_VERSION`, patches the
real version plus NUL into a distinct final `with` output, and fails loudly if
the slot is missing, truncated, or too small.

The stage chain depends only on the commit-independent generated main source.
Versioned bootstrap/version artifacts live behind a separate target: a target
that tracks HEAD cannot be a stage dependency even when its relevant output is
byte-identical, because the build cache deliberately invalidates a target when
any dependency rebuilt.

On macOS, patching invalidates the linker's enforced ad-hoc code signature, so
the patch action must ad-hoc re-sign the final binary after writing and chmod.
Linux and Windows do not run that signing step.

### Context / why

The cache was already content-addressed, but every commit changed
`out/gen/main.w` by substituting `v<base>-g<commit>` before compilation. That
made documentation-only commits rebuild the full self-hosted compiler. Keeping
the generated main byte-stable was necessary but not sufficient: the original
combined source-generation action still tracked HEAD, and
`build_cache_freshness_reason` treats a rebuilt dependency as stale, so stage1
would still rebuild after every commit. Separating stable and versioned source
generation removes both invalidation paths.

The version suffix does not affect compiler semantics, fixpoint identity, or
artifact correctness; it is late-bound provenance. Post-link stamping preserves
the exact user-visible version while keeping semantic build inputs truthful.

### Protection / the rule going forward

- Never restore version substitution in `out/gen/main.w` or another native
  compiler input.
- Keep the unstamped link output separate from the patched output; modifying a
  target's own cached output in place makes that target perpetually stale.
- Do not attach HEAD/version inputs, directly or through a rebuilt dependency,
  to the stage chain or `link-compiler`.
- Preserve the loud slot bounds/sentinel checks and the macOS re-sign step.

---
