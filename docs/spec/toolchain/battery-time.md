# Battery time

The battery (`with run tools/battery.w`: the gate, the acceptance scenarios
and `:battery-checks`, one scheduled graph driven by the pinned seed) is
measured by wall clock on the release host, an 18-core Mac. Every number
below is an official run: the pinned seed driving, a committed tree, no
check weakened, skipped or moved out of the PR tier (D131 moved the
release-tier checks to `:release-checks`, which a seed cut and a release
run). The target set on 2026-10-14 was ten minutes.

| Date | Sources | Seed driving | Wall | What changed |
|---|---|---|---|---|
| 2026-10-13 | main 2447935e8 | 10-11 (serial driver) | ~75 min | baseline: gate ~12–17 min, uat ~1 min, survey ~55 min, half of it driver overhead between targets |
| 2026-10-14 | 0da433ee8 (#2410) | 10-11 | 597 s | one scheduled graph (#2408); validation tiers (D131); emit-c demand-driven emission (D130); a runtime directory is accepted by its bytes (D132); jobserver slots per lane |
| 2026-10-14 | #2411 | 10-14 local-2 (one-graph driver) | 1298 s | the first battery under the one-graph seed: the store prune walked 20,798 files after every published target |
| 2026-10-14 | #2413 | local-2 | 472 s (warm) | the store prune lists the top level; a directory listing is linear; an Action before the runner runs in the driver |
| 2026-10-14 | 592eb6602 (#2414) | 10-14 local-3 | **390 s** (warm worktree), **491 s** (fresh worktree) | the first seed whose driver carries every fix |

A warm worktree already holds `out/` from an earlier run; a fresh worktree
has only the seed, with the machine-wide stores (`~/.local/with-build-cache`,
`~/.local/with-test-verdicts`) as any PR finds them.

## Where the 491 s go (fresh worktree, seed local-3)

Elapsed stamps from the run's `[time]` lines:

| At | Target | Lane time |
|---|---|---|
| 28 s | build.w evaluated, bootstrap runtime compiled by the seed | |
| 86 s | stage1 | 76 s |
| 175 s | stage2 | 74 s |
| 184 s | build (the release stamp) | 3 s |
| 273 s | debug-alloc-tests | 88 s |
| 339 s | selfcheck | 162 s |
| 355 s | tools-tests | 170 s |
| 398 s | internals-tests | 153 s |
| 452 s | behavior-tests | 208 s |
| 478 s | emit-c-smoke | 292 s (58 s alone) |
| 484 s | test-green | 6 s |
| 491 s | last-green | 8 s |

The wall is `build` (184 s, the chain seed → stage1 → stage2 that nothing
shortens but a faster compile of the compiler) plus the longest test lane.
`emit-c-smoke` runs its 34 cases one after another and is the lane that
ends the run.

## How to measure

- Never `time`-wrapped: the driver prints `[build] :battery wall N s` and the
  battery log's `[time] <target> <lane> @<elapsed>` lines are the timeline.
- Read logs with `with run ~/.claude/hooks/verdict.w <log>` (`--times`,
  `--progress`, `--detail <needle>`).
- A measurement with a driver that is not the pinned seed (a release binary
  built from the tree, to time a driver change before a seed carries it)
  fails `seed-driver` and everything downstream of it; it measures the graph,
  not the battery.
- A driver change reaches the official battery only through a seed cut and a
  `seed.lock` bump: the seed is the driver.

## What was found, and fixed, on the way

- **The runtime was refused after every compiler edit.** A generation hashes
  all of `src/` and `rt/`, so the last build's runtime objects were "another
  generation's" though recompiling gave the same bytes; the action runner
  then had no link root and fell back to the comptime evaluator. A runtime
  directory whose objects are the bytes the compiler embeds is the
  compiler's (D132), and stage1 no longer deletes `out/lib`.
- **The evidence targets ran before what they bless.** `test-green` and
  `last-green-record` had no edges on the targets whose evidence they read;
  the serial driver's declaration order hid it. They declare the edges now.
- **The store prune walked the whole store after every published target**,
  15–17 s each, serial on the driver's main thread (`build_cache_store_publish
  → build_cache_store_prune → with_fs_list_files`); the listing itself was
  quadratic in the files listed (`out ++ line` per entry). The prune lists the
  top level (`rt_list_dir`, `std.fs.list_dir_text`) and the listing
  accumulates in one buffer: 20,798 files in under a millisecond.
- **An Action before the runner exists ran as a `build :X --no-deps` child**,
  re-evaluating build.w around a 2 s compile (18 s under stage1, 55 s under
  the seed), eighteen of them one after another in a cold worktree (993 s).
  It runs in the driver's own evaluation now (56 s for the eighteen).
- **emit-c emitted the whole program** (24 MB of C for `print("hi")`); it
  emits what the program reaches (D130), `--emit-all` keeps the old output.
- A quadratic scan in emit-c's assignment index (12.7 s → 8.7 s per emit).
