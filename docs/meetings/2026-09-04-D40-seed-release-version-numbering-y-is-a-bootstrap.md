# D40 — Seed/release version numbering: `y` is a bootstrap-compatibility group; a bootstrap breakage bumps `y` and resets `z`

**Date:** 2026-09-04 (granted 2026-09-05)
**Status:** Accepted (Eric, 2026-09-05). The convention below is now the rule:
`Y` is a bootstrap-compatibility group; a bootstrap breakage bumps `Y` and
resets `Z = 0`. The digits of a release tag now carry this agreed meaning, and
the release runbook's version-bump step points here.

Applied retroactively (Eric, 2026-09-05). The str-index bootstrap breakage
went out as `v0.15.1.9`..`v0.15.1.13`, which this convention says should have
opened the `v0.15.2.x` group. Only one of those was actually pinned — the
Mac/Linux seed `v0.15.1.10` (7 CI pins + `seed.lock`) — so it was republished
as **`v0.15.2.0`**, the first seed of the new group (same commit `4fd309e3`,
byte-identical assets, so the pinned SHA-256 digests are unchanged; it
bootstraps from `v0.15.1.8`, the last seed of the old group). `seed.lock` and
every CI pin moved `v0.15.1.10` → `v0.15.2.0`. The unpinned transient chain
tags (`v0.15.1.9`, `.11`, `.12`, `.13`) and the superseded `v0.15.1.10` were
removed. `v0.15.1.8` stays as the old group's last seed (still the Windows
pin, pending #1081).

**The convention.** A published `with` seed/release is tagged `vW.X.Y.Z`:

- **`W.X`** — the product/language line.
- **`Y`** — the **bootstrap-compatibility group**. Every seed tagged `vW.X.Y.*`
  is *mutually* bootstrap-compatible: any `vW.X.Y.Z` seed can build the source
  tree at any other `vW.X.Y.Z'` tag in the same group. Equivalently, every
  commit released inside a group is bootstrappable by every seed of that group.
- **`Z`** — a sequential cut *within* a group. A new `Z` is a **non-breaking**
  release: bug fixes, or a compiler feature that is merely *added* (so the
  group's existing seeds can still bootstrap the tree because build-driver code
  does not yet *use* it).
- **A "breakage"** is a commit the current group's seeds *cannot* bootstrap —
  because build-graph / build-driver code (comptime-evaluated by the pinned
  seed at graph materialization, before any stage compiles) uses a language or
  compiler feature newer than those seeds. A breakage **must open a new group**:
  bump `Y`, reset `Z = 0`.
- **The seed chain never breaks.** The first seed of a new group, `vW.X.(Y+1).0`,
  must be bootstrappable from the **immediately-preceding** seed (the last
  `vW.X.Y.*`) — but it need *not* be buildable by the rest of the old group.
  So the seed *lineage* is an unbroken chain N→N+1 (you can always walk one hop
  forward from any published seed to head), while the *mutual*-compat guarantee
  is scoped to a single `Y`.

**Why.** Sharing `Y` is a *promise* of mutual bootstrap compatibility, and CI
relies on it: each self-host lane pins a seed and expects any group seed to
build any group commit. Numbering a breaking seed *within* the old group
silently breaks that promise — the old seeds stay pinned, the tree now needs a
feature they lack, and every pinned lane dies at graph materialization
(`comptime index requires an array, tuple, or vec` — exactly the #956 failure).
Resetting `Z=0` on a breakage makes the incompatibility legible in the number
itself: "a `.2.0` tree cannot be built by a `.1.x` seed" is readable without
archaeology. Keeping only the N→N+1 chain (rather than demanding whole-group
compat across the break) is the *minimum* constraint that keeps bootstrap
reproducible end to end.

This is the same shape used by bootstrapped toolchains elsewhere — rustc's
stage0 is always the *immediately* previous release, never an arbitrary older
one; Go's bootstrap toolchain is a specific prior version — and it is the
release-facing corollary of AGENTS.md's bootstrap invariant, *"if a change
needs a newer seed, tag a release to be that seed first."* SemVer governs the
`W.X` API line and is orthogonal; `Y`/`Z` describe *bootstrap* compatibility,
which SemVer has no concept of.

**Immediate application (the live case).** Comptime `str` indexing (`s[i]` where
`s: str`) landed in `af7db8ce` (#1017, "a str's element is its byte, u8") and is
then *used* in comptime-evaluated build-driver files by `0173d08e`. Seeds
`v0.15.1.3`–`v0.15.1.8` do **not** support comptime `str` indexing, so they
reject the materialized build graph of the tree at/after `0173d08e`. That tree
is therefore a **breakage** relative to the `v0.15.1` group. The str-index-capable
seed (cut from `af7db8ce`, buildable *by* `v0.15.1.8`) is the **first seed of a
new group** and must be tagged **`v0.15.2.0`**, not `v0.15.1.9`: `v0.15.1.8`
builds it (chain intact) while `v0.15.1.3`–`.7` cannot (correctly excluded —
they are the old group). Tagging it `v0.15.1.9` would assert membership in the
mutually-compatible `.1` group, which is false. If this convention is blessed,
`release/v0.15.1.9` (`61b6e574`, currently bumping `src/version` to `v0.15.1.9`)
should become `v0.15.2.0`.
