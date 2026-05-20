# Phase C Extraction Plan: C Migrator Core Tests

Status: completed extraction plan. Implementation complete.

This extraction will move `c-migrator-core-tests` out of generic
compiler-driver dispatch and into a repository-local build action.

## Placement

The target will live in the repository-local `build_selfhost.w` module,
imported by root `build.w`. These fixtures test this repository's C migrator;
they are not standard build-system APIs and do not belong in `lib/std`.

## What Moves

Move the migrate-core selfhost implementation out of
`src/BuildGraphSelfhost.w` and generic dispatch:

- `BuildKind 1018`, currently `cli_selfhost_migrate_core_test`
- `run_cli_selfhost_migrate_core_test`
- migrate-core fixture helpers:
  - `bgs_check_migrate_libc_ctype`
  - `bgs_check_migrate_macro_unsigned_minus`
  - `bgs_check_migrate_tentative_global_owner`
  - `bgs_check_migrate_cross_file_tentative_global_owner`
  - `bgs_check_migrate_noop_pointer_casts`
  - `bgs_check_migrate_raw_pointer_index`
  - `bgs_check_migrate_prefer_brace_ws`
  - `bgs_check_migrate_typed_cast_macros`

After migrate-core moves, delete these now-migrator-only shared helpers from
`src/BuildGraphSelfhost.w`:

- `bgs_migrate_error`
- `bgs_migrate_assert_contains`
- `bgs_migrate_assert_not_contains`
- `bgs_migrate_file_contains`
- `bgs_migrate_file_forbids`
- `bgs_migrate_expect_success`
- `bgs_index_of`
- `bgs_count_occurrences`

Reuse the equivalent `bs_*` helpers in `build_selfhost.w` introduced in the
migrate-basic extraction. Do not add new helper layers in this slice unless a
fixture has no existing `bs_*` equivalent.

## Target Shape

`build.w` will declare `c-migrator-core-tests` as a standard `.Action` target:

```with
var c_migrator_core_tests = target_new(.Action, "c-migrator-core-tests", "").output("out/test-graph/c-migrator-core-tests")
c_migrator_core_tests.action = run_cli_selfhost_migrate_core_action
c_migrator_core_tests = c_migrator_core_tests.input("out/bin/with-stage2")
c_migrator_core_tests = c_migrator_core_tests.dep("selfcheck")
out = out.add_target(c_migrator_core_tests)
```

The action will read the compiler path from `ctx.inputs().get(0)` and write all
fixtures, captures, and generated migrated files under its declared output
directory.

## Capabilities

The action will use only capabilities already exposed by `ActionCtx`:

- `Diagnostics` for clear target-specific failures
- `ToolFs` for fixture directories, fixture files, migrated output reads, and
  cleanup where needed
- `ProcessRunner` for invoking `with migrate`, `with check`, and generated
  build/run commands
- `ProjectInfo` for resolving project-relative paths
- declared inputs and outputs through `ctx.inputs()` and `ctx.output()`

Filesystem work will go through `ToolFs`; process execution will use argv-based
`ProcessRunner` calls, not shell command strings.

## Reserved Kind

Kind `1018` will be reserved after extraction. `build_graph_kind_removed(1018)`
must return true, `build_graph_kind_is_project(1018)` must return false, and
`build_graph_kind_name(1018)` should return
`removed_cli_selfhost_migrate_core_test`.

Old serialized graphs should fail with the standard removed-kind diagnostic:
`this kind was removed; regenerate your build graph`.

## Dispatch Removal

After extraction, `src/main.w` must not dispatch kind `1018` or branch on the
`"migrate-core"` suite argument. Verify with:

```sh
rg -n "cli_selfhost_migrate_core|run_cli_selfhost_migrate_core|migrate-core|bgs_migrate_|bgs_index_of|bgs_count_occurrences" src/main.w src/BuildGraphKinds.w src/BuildGraphSelfhost.w
```

Expected remaining hits are limited to the removed-kind name/diagnostic and any
documentation outside the generic driver.

## Parity Standard

Before and after the extraction, run:

```sh
out/bin/with build :c-migrator-core-tests > /tmp/with-migrate-core.out 2> /tmp/with-migrate-core.err
echo $? > /tmp/with-migrate-core.rc
```

The extraction is correct only if the target's exit code and observable output
remain equivalent. Generated fixture paths may include per-run stamps, so
capture comparison should focus on command exit status and public diagnostics,
not transient path names.

## Verification Sequence

The implementation slice must run:

```sh
out/bin/with check build_selfhost.w
out/bin/with check build.w
out/bin/with build :c-migrator-core-tests
make build
make fixpoint
make test
```

After the extraction commit lands, update `build-kind-table-audit.md` in a
separate follow-up commit so kind `1018` is listed as removed.
