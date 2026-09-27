# An empty zlib reference tree was stamped ready

`build :zlib-migrate` failed because `adler32.c` was missing, immediately
after `zlib-reference` had succeeded. The reference directory contained only
`.with-reference-url` and `.with-reference-ready`.

The route was the action's own native build runner under LLDB. Breaking on
`run_zlib_reference_action`, then `ToolFs.is_dir`, and stepping out reached
the action's directory-only guard (`build/zlib.w`, original line 276).
At PC `0x100082020` (`run_zlib_reference_action+728`), `w22` was 1.
The `cbz w22` instruction fell through to `+732` instead of entering the
extraction block. The next block wrote the success markers. Transcripts:
`/tmp/with-zlib-reference-branch-lldb.log` and
`/tmp/with-zlib-reference-verdict-lldb.log`.

The directory exists because `Build.__driver_run_action` creates every
declared output's parent before invoking an action (`lib/std/build.w`,
original lines 2963–2977). This target declares a ready stamp inside its
reference directory. The action therefore mistook output preparation for
completed work. PCRE2 had already corrected the analogous directory-only
guard; zlib still contained it.

The readiness predicate now checks every nonempty source/header required by
migration, plus `test/example.c` and `test/minigzip.c`. An incomplete tree
loses its stale ready stamp. Extraction occurs in scratch storage, and all
required files are checked before the generated partial tree is replaced.
Success is stamped only after the action completes.

Cold and partial-tree recovery are integration checks against the pinned,
SHA-verified upstream archive. They are not added to the ordinary behavior
suite because they require network access and run the complete reference
action. Their results are recorded with the branch's validation evidence.

Both integration checks passed using the action's native runner. For the
partial-tree check, `adler32.c` was moved aside while the ready stamp remained;
the action restored a byte-identical source and rewrote the ready stamp only
after successful extraction. Logs: `/tmp/with-zlib-reference-cold-recovery.log`
and `/tmp/with-zlib-reference-partial-recovery.log`. The direct runner used
`WITH_BUILD_ACTION_NAME=zlib-reference`, the worktree as
`WITH_BUILD_RUNNER_ROOT`, and its stage2 as `WITH_BUILD_COMPILER`.
