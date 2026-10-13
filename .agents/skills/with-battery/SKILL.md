---
name: with-battery
description: Operate a With compiler stack end to end — worktree, iterate tier, corpus promotes, gate, battery, merge, reseed — without the failure modes that cost extra battery rounds.
---

# With Battery And Stack Work

Use this skill when working on a stack in this repository: creating a
worktree, running promotes, the gate, or `tools/battery.w`, triaging red
targets, merging a PR, or reseeding. `AGENTS.md` is the canonical rule
set; this skill is the operational checklist distilled from it and from
the d119-step3 stack (PR #2364), where each item below cost a battery
round or an hour when missed.

## Worktree discipline

- One worktree per stack under `~/.local/with-staging/<name>`, branch
  from `origin/main`, `.deps` symlinked, `with build :seed` once.
- **Every file path in a worktree is absolute.** Relative tool paths
  resolve to the main checkout (`~/with`), so a relative read silently
  reads main's file while you believe you are reading the branch's.
  Verify once per session with a canary: a file the branch is known to
  have changed.
- Never `git stash`. Commits are the human's identity; no AI trailers.

## Before the battery (iterate tier)

- Each fix lands with a fixture shown FAILING before the fix
  (`out/bootstrap/bin/with-stage1 test <files>` after `with build :dev`).
- A **migrator spelling change** sweeps every textual expectation of the
  old spelling in the whole tree before the first battery — never a
  head-truncated grep — and runs the migrator selfhost checks
  (`src/main build :c-migrator-basic-tests --no-deps`).
- New code in `src/` gets a ceremony sanity pass before the battery
  (`with run tools/ceremony_census.w`); a redundant `move`/cast copied
  from neighboring code is a census rise. Do not copy an idiom because
  it is local precedent.
- Read battery/gate logs only through
  `with run ~/.claude/hooks/verdict.w [--progress|--detail <target>] <log>`.

## Corpus promotes

- One promote target per `src/main build` invocation is no longer
  required (driver fixed), but each promote still depends on `:build`,
  whose release compiler needs `.wo` bundles built from the corpora
  **currently in the tree**. If the in-tree corpus cannot bundle,
  restore its last-green (main) state first, promote that corpus first,
  then the rest. A corpus moves only by re-promotion (D112); the
  temporary restore is scaffolding, and the committed state comes from
  the promote run.

## Running the battery

- Clean committed tree; `with run tools/battery.w > out/battery-runN.log
  2>&1` with an `rc=$?` line appended. Every phase already runs under
  its own caffeinate hold and the battery takes a machine-wide slot —
  do not wrap the invocation in caffeinate or a keep-awake lease.
- Watch it with **one persistent monitor** (no 30-minute ceiling) on the
  terminal `rc=` line of the run log, printing `out/battery/status.txt`.
  Stop duplicate monitors. Do not poll: phases on the release host ran
  gate ≈ 800 s, UAT ≈ 20 s, battery-checks ≈ 1,300 s.
- Read the result from `out/battery/status.txt` via the verdict tool,
  never by eyeballing logs.

## Triaging reds

- One battery per stack top commit; a red is fixed on the stack with
  iterate-tier evidence, then the battery runs once more. Batteries do
  not average: a green phase on older code blesses nothing.
- The battery surveys across targets but gates between phases and stops
  within a target at its first failing case, and a failed target skips
  its dependents. So one red run reports one failure per independent
  target in the earliest failing phase — expect the next run to reach
  code the previous one never exercised.
- Distinguish root reds from cascade skips (`verdict --detail` shows
  "dependency X did not succeed"). Fix roots only.
- A failure is pre-existing only when verified on the previous commit
  (worktree or clone, never stash).

## Merge, reseed, cleanup

1. Post the battery evidence on the PR (head hash, gate/uat/checks rc
   and wall times from `status.txt`).
2. `gh pr ready <n>`; `gh pr merge <n> --squash --delete-branch`
   (dependent PRs: `gh stack`, never hand-chained bases).
3. `cd ~/with && git pull --ff-only`.
4. Reseed in `~/.local/with-staging/reseed-main`: `git fetch`,
   `git checkout --detach origin/main`, `with build :seed`,
   `WITH=$PWD/src/main src/main build`,
   `out/release/bin/with build :install-user`. Verify the installed
   compiler on one new fixture before reporting done.
5. Remove the worktree and branch from the main checkout; close the
   stack's issues with the merge and battery evidence.
6. Report current compiler reachability honestly: what the installed
   `with` at `~/.local/bin/with` is built from, verified by running it.
