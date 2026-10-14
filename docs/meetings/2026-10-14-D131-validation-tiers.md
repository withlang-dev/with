# D131 — Validation is scoped to its tier: a fix, a PR, a seed cut or release; migration runs only at a seed cut or release, or when a human asks

**Date:** 2026-10-14. **Status:** ruled (Eric). **Supersedes:** the part of
D14/D56 that made one battery run every check on every PR.

**Ruling (Eric, 2026-10-14).** "What is *actually* required per-fix, per-PR,
and per-release? We should limit the scope of each to only what's actually
necessary for that scope." On the tiering brief: "implement this first." And:
"per PR and per fix, never run migration. go ahead and make that a seed /
release thing only. let the human decide when to run migrate."

**Decision.**

| Tier | Must prove | Runs |
|---|---|---|
| Fix | it does what it says and breaks nothing nearby | `with check`, `:dev`, the tests it touches |
| PR (the battery) | main stays correct and buildable | `:gate`, `battery-uat`, `:battery-checks`: the language suites, the audits, the green evidence |
| Seed cut or release | the toolchain reproduces itself; the migrator and the corpora agree | `:release-checks`: the fixpoint, issue61, the invariance rebuilds, the C migrator tests, every corpus migrated afresh and tested, wo-drift |

- No migration runs in a fix or a PR: `c-migrator-basic-tests` left the gate's
  fixed list, and nothing the battery reaches migrates (verified on the
  `:battery` graph: 217 targets, none a migrate, drift, fixpoint, invariance
  or corpus lane). A human runs `:c-migrator-tests` or a corpus lane when a
  change calls for it; `:release-checks` runs them all.
- `release-uat` depends on `release-checks`; a seed is cut only from a tree
  whose `:release-checks` is green.
- `:last-green` no longer requires fixpoint evidence; it records it when this
  compiler has it.
- `corpus-integrity-check` stays in the gate: it hashes the committed corpora
  and migrates nothing (D112).

**Why.** The battery's wall was its slowest chain, and the fixpoint (stage3
compiling the compiler, 180-295 s under load) sat on it after stage1 and
stage2; the corpus lanes re-migrated four C libraries (600-800 s of CPU) on
every compiler change though only a migrator change can move them. Neither
protects a PR's claim that main is correct; both protect the claims a seed
cut and a release make.

**Risk accepted.** A nondeterminism bug or a migrator regression can land on
main and surface at the next seed cut; it is fixed before the cut.
`emit-c-fixpoint` (#2409, red) stays outside every tier until fixed, as before.
