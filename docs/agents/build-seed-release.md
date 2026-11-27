# Build, seed, releases, other hosts and bootstrap rules

Moved verbatim from AGENTS.md (#2374). Nothing here was reworded.

## Other hosts

The Mac is the release host. `eric-5090` is no longer occupied and is available
anytime for Linux or Windows builds and tests (Eric, 2026-11-27):

- **Linux:** `ssh eric-5090`.
- **Windows:** start the Windows VM on `eric-5090` (`ssh eric-5090 virsh start win10`),
  then `ssh win10`. Shut the VM down cleanly when finished (`ssh eric-5090 virsh shutdown win10`)
  if it was off before you started.
- **QuixiInfer service:** you are permitted to shut down the production
  QuixiInfer service on `eric-5090` while building or testing, as long as you
  restart it when you are finished.

Build and test there as here (the pinned seed drives the battery; never `git
stash`), and leave no build jobs running.


## Build System

```
with build              # full build (seed → stage1 → stage2 → final)
with build :dev         # dev tier: seed → stage1 only (D14 iterate loop)
with build :stage1 / :stage2
with build :fixpoint    # verify stage2 == stage3 (byte-identical)
with build :test        # run test suite
with build :test-green  # verify/record current test evidence
with build :seed-driver # the driver is the seed pinned in seed.lock (first in :test)
with build :clean
```

Fixpoint invariant: `stage2 == stage3`. If it fails, code generation is
nondeterministic: stop and fix. **If the build breaks, fixing it is the top
priority.**

### Optimization level: ALWAYS `-O1`, NEVER `-O0`

Every stage, runtime object and the release binary are built at `-O1`; there
is no `-O0` in `build.with` / `build/*.with` — an invariant, not a preference. `-O0`
is pathologically slow (a 26k-line module: 31+ min vs seconds), and `-O1` is
fully deterministic: a fixpoint break under `-O1` is a real nondeterminism bug
(`with build :fixpoint-diff`), and a bug only at `-O1` is a real UB or
miscompile. **Dropping to `-O0` to make a red build go green is the single most
forbidden shortcut.** The only allowed `-O0` is an explicitly approved,
temporary local diagnostic, reverted before any commit; `-O0` anywhere in the
build files is a regression.


## Seed Compiler

Resolution order: `WITH=<path>` → `with` on PATH → `src/main`. `src/main` is
not in git; it is always the seed pinned in `seed.lock`, fetched from the
`with-darwin-aarch64` release asset by `with build :seed` (a no-op while it
matches the lock). The battery is driven by that seed, exactly as CI is —
never by the installed compiler:

```
with build :seed                      # once per seed.lock bump
export WITH=$PWD/src/main
src/main build
src/main build :test                  # seed-driver first, test-green last
src/main build :last-green
src/main build :release-checks        # seed cut or release only (D131)
src/main build :install-user          # the fresh compiler to ~/.local/bin/with
```

`seed-driver` refuses `:test`, `:test-green` and `:last-green` when the
driver's digest is not the lock's (or an ancestor process is another
compiler). Only `:seed` writes `src/main`; there is no `:update-seed`.
`:test-green` records evidence from a completed run, not a substitute for it.
The iterate tier (`with check`, `with build :dev`) uses the installed compiler.

**A green belongs to the sources, not to the commit or worktree (D49).**
`:last-green` publishes the green keyed on the battery's inputs, the pinned
seed and the host (`~/.local/with-green/green.tsv`). The inputs are the
committed tree without `docs/` and top-level `*.md` (the build measures
software, not documents, Eric 2026-09-21; D50: key on what the output is made
from). `GreenEvidence.with` and `build/retention.with` apply the same rule and must
agree byte for byte. After a squash-merge of a battery-green branch, the
reseed on main is `git pull`, `src/main build`, `out/release/bin/with build
:install-user`: no second `:fixpoint` or `:test`. The gate refuses a dirty
worktree; never re-run a battery over sources that already passed one.

If the seed, installed compiler and release binaries are all broken, the
compiler cannot be recovered.


## Releases

Follow `docs/spec/toolchain/with-release-runbook.md`. Release work is packaging
and verification: no compiler, runtime, stdlib, migrator, build-system or test
changes unless the maintainer expands scope. An unrelated bug found in release
prep is filed with its repro, not fixed, unless the maintainer says it blocks.
Publish the Darwin arm64 binary as `with-darwin-aarch64`; never publish an
asset named `main` (`src/main` is only the local seed path).


## Bootstrap Rules

### Changes land via pull request
All changes reach `main` through a PR. Branch protection requires a PR with
zero approvals (Eric, 2026-09-23): the seed-driven battery is the gate (D56).
Batch related commits into one PR as the battery batches them. GitHub lanes are
not a merge signal (a lane takes hours; the nightly release runs every
platform once a night and the per-platform lanes run on dispatch only,
post-hoc); a PR is a draft until its seed-driven battery is green and posted,
then marked ready. The SDK is built only on release (`sdk-release.yml`).

**windows-aarch64 is non-gating (D137, Eric 2026-10-19).** Dispatch its jobs
(`selfhost-windows-aarch64`, `seed-windows-aarch64`, its SDK and release
jobs) and move on: never wait for one, never hold a merge, reseed, seed cut,
release, PR or issue for its verdict. A red run seen later is filed as a new
issue (run ID, failing targets, captures) and fixed like any other bug.

### Dependent PRs are a `gh stack`, never hand-chained bases
Dependent PRs are a GitHub stack via the `gh stack` extension (`gh extension
install github/gh-stack`; exit code 9 means stacks are not enabled). Never
stack by hand with `gh pr edit --base` or cumulative branches (that landed five
PRs as one commit, 2026-09-22).
- **Create/update:** `gh stack link --base main <bottom> … <top>` (branch names
  or PR numbers, bottom to top); it pushes, creates missing PRs and fixes each
  base. Each layer holds only its own commits.
- **Draft until green:** link as drafts; `gh stack link --open …` or `gh pr
  ready` only after the battery is green and posted.
- **Merge:** the whole stack or up to one PR, in order, all-or-nothing: `gh
  stack merge <top-pr> --yes --squash`. Never merge a middle layer by hand.
- **Main moved:** `gh stack rebase` from a stack checkout, then `gh stack
  push`; a rebase that resolves conflicts needs a new battery.
- **Independent PRs are not stacked.** A single-PR batch has base `main`.

### Every PR must be bootstrappable
Each PR must be green and buildable from a tagged seed release that exists
before it merges; if a change needs a newer seed, tag one first. The pinned
seed is `seed.lock` (version and per-platform digests); every CI lane and `with
build :seed` read it, and the local battery is driven by it: `build.with`,
`build/*.with` and `lib/std/build.with` are comptime-evaluated by the driver under
the pinned seed's evaluator. `seed-driver` refuses any other driver and any
workflow pin that disagrees with the lock. A language or evaluator feature used
in the build layer raises the minimum seed — never revert the surface to
appease an old seed (Eric, 2026-09-04): cut a newer seed, bump `seed.lock`
(`with run tools/bump_seed_pins.with`, `with build :seed`), then land the change.
(Main was unbuildable by every published seed for two days, 2026-09-02..04;
`seed-driver` red is stop-the-line.)

### The seed compiler is frozen
The installed compiler at `~/.local/bin/with` has its own Link.with, embedded
runtime objects and codegen baked in; editing source files does not change it
until you install a new seed.

### Never run `with build :install` with uncommitted changes
It updates the seed, and a broken seed breaks all future builds. Install only
after `with build :fixpoint` passes on committed code.

### Never change Link.with and runtime files in the same commit
Commit 1: new exports in rt_core.with (old link path still works). Commit 2:
Link.with (new path activates). Each must independently pass `:fixpoint`.

### Bootstrap order for runtime migration
1. Checkout all runtime/link files to the last green state.
2. `with build && with build :fixpoint` (green baseline).
3. Apply rt_core.with changes only (new exports, ABI fixes); build and fixpoint.
4. Apply Link.with changes; stage1 is built with the old seed (old link path),
   stage1 has the new Link.with and builds stage2 with the new path.
5. `with build :fixpoint` (stage2 == stage3 converges); then `with build
   :install` (seed updated).
