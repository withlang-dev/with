# Phase C Extraction Plan: C Migrator Basic Tests

Status: completed extraction plan. Implementation complete.

This extraction will move `c-migrator-basic-tests` out of generic
compiler-driver dispatch and into a repository-local build action.

## Placement

The target will live in the repository-local `build_selfhost.w` module,
imported by root `build.w`. These fixtures test this repository's C migrator;
they are not standard build-system APIs and do not belong in `lib/std`.

## What Moves

Move the migrate-basic selfhost implementation out of
`src/BuildGraphSelfhost.w` and generic dispatch:

- `BuildKind 1017`, currently `cli_selfhost_migrate_basic_test`
- `run_cli_selfhost_migrate_basic_test`
- migrate-basic-only fixture helpers:
  - `bgs_check_migrate_global_init_list`
  - `bgs_check_migrate_host_header_compat`
  - `bgs_check_migrate_assignment_compat`
  - `bgs_check_migrate_rvalue_sequencing`
  - `bgs_check_migrate_directory_progress`
  - `bgs_check_migrate_cross_file_global_owner_arrays`
  - `bgs_check_migrate_shared_defs_ownerless_extern`

Shared migrator assertion, capture, path, argv, and fixture helpers should move
only if the extracted action needs project-local versions and the remaining
generic selfhost code no longer owns them.

## Target Shape

`build.w` will declare `c-migrator-basic-tests` as a standard `.Action` target:

```with
var c_migrator_basic_tests = target_new(.Action, "c-migrator-basic-tests", "").output("out/test-graph/c-migrator-basic-tests")
c_migrator_basic_tests.action = run_cli_selfhost_migrate_basic_action
c_migrator_basic_tests = c_migrator_basic_tests.input("out/bin/with-stage2")
c_migrator_basic_tests = c_migrator_basic_tests.dep("selfcheck")
out = out.add_target(c_migrator_basic_tests)
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

Kind `1017` will be reserved after extraction. `build_graph_kind_removed(1017)`
must return true, `build_graph_kind_is_project(1017)` must return false, and
`build_graph_kind_name(1017)` should return
`removed_cli_selfhost_migrate_basic_test`.

Old serialized graphs should fail with the standard removed-kind diagnostic:
`this kind was removed; regenerate your build graph`.

## Dispatch Removal

After extraction, `src/main.w` must not dispatch kind `1017` or branch on the
`"migrate-basic"` suite argument. Verify with:

```sh
rg -n "cli_selfhost_migrate_basic|run_cli_selfhost_migrate_basic|migrate-basic" src/main.w src/BuildGraphKinds.w src/BuildGraphSelfhost.w
```

Expected remaining hits are limited to the removed-kind name/diagnostic and any
documentation outside the generic driver.

## Parity Standard

Before and after the extraction, run:

```sh
out/bin/with build :c-migrator-basic-tests > /tmp/with-migrate-basic.out 2> /tmp/with-migrate-basic.err
echo $? > /tmp/with-migrate-basic.rc
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
out/bin/with build :c-migrator-basic-tests
make build
make fixpoint
make test
```

After the extraction commit lands, update `build-kind-table-audit.md` in a
separate follow-up commit so kind `1017` is listed as removed.
