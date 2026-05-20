# Phase C Extraction Plan: Build.w Selfhost Tests

Status: completed extraction plan. Implementation complete.

This extraction will move `cli-selfhost-build-w-tests` out of generic
compiler-driver dispatch and into a repository-local build action.

## Placement

The target will live in the repository-local `build_selfhost.w` module,
imported by root `build.w`. These fixtures test this repository's integrated
build-system behavior; they are not standard build-system APIs and do not
belong in `lib/std`.

## What Moves

Move the build.w selfhost implementation out of `src/BuildGraphSelfhost.w` and
generic dispatch:

- `BuildKind 1011`, currently `cli_selfhost_build_w_test`
- `run_cli_selfhost_build_w_test`
- build.w fixture helpers:
  - `bgs_tool_from_env`
  - `bgs_nm_smoke`
  - `bgs_check_build_w_not_ignored`
  - `bgs_check_build_w_test_targets`
  - `bgs_check_build_w_library_and_targets`
  - `bgs_check_build_w_generated_source`
  - `bgs_graph_build_file`
  - `bgs_require_case_file`
  - `bgs_forbid_case_file`
  - `bgs_check_build_w_graph_v2`
  - `bgs_check_removed_build_kind_diagnostic`
  - `bgs_check_build_w_action_target`
  - `bgs_check_build_w_action_failures`

Reuse the equivalent `bs_*` helpers already in `build_selfhost.w` for fixture
writing, capture, path handling, assertions, file existence, and binary runs.
Do not introduce another generic helper layer in this slice.

## Target Shape

`build.w` will declare `cli-selfhost-build-w-tests` as a standard `.Action`
target:

```with
var cli_selfhost_build_w_tests = target_new(.Action, "cli-selfhost-build-w-tests", "").output("out/test-graph/cli-selfhost-build-w-tests")
cli_selfhost_build_w_tests.action = run_cli_selfhost_build_w_action
cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.input("out/bin/with-stage2")
cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.dep("selfcheck")
out = out.add_target(cli_selfhost_build_w_tests)
```

The action will read the compiler path from `ctx.inputs().get(0)` and write all
fixtures, captures, generated projects, and command outputs under its declared
output directory.

## Capabilities

The action will use only capabilities already exposed by `ActionCtx`:

- `Diagnostics` for target-specific failure messages
- `ToolFs` for fixture directories, fixture files, generated outputs, and
  cleanup
- `ProcessRunner` for invoking the compiler CLI, produced binaries, and
  genuine external inspection tools such as `nm`
- `ProjectInfo` for resolving project-relative paths
- declared inputs and outputs through `ctx.inputs()` and `ctx.output()`

Filesystem work will go through `ToolFs`. Process execution will use argv-based
`ProcessRunner` calls, not shell command strings.

## Reserved Kind

Kind `1011` will be reserved after extraction. `build_graph_kind_removed(1011)`
must return true, `build_graph_kind_is_project(1011)` must return false, and
`build_graph_kind_name(1011)` should return
`removed_cli_selfhost_build_w_test`.

Old serialized graphs should fail with the standard removed-kind diagnostic:
`this kind was removed; regenerate your build graph`.

## Dispatch Removal

After extraction, `src/main.w` must not dispatch kind `1011` or branch on the
`"build-w"` suite argument. Verify with:

```sh
rg -n "cli_selfhost_build_w|run_cli_selfhost_build_w|build-w|bgs_check_build_w|bgs_graph_build_file|bgs_require_case_file|bgs_forbid_case_file" src/main.w src/BuildGraphKinds.w src/BuildGraphSelfhost.w
```

Expected remaining hits are limited to the removed-kind name/diagnostic and any
documentation outside the generic driver.

## Parity Standard

Before and after the extraction, run:

```sh
out/bin/with build :cli-selfhost-build-w-tests > /tmp/with-build-w.out 2> /tmp/with-build-w.err
echo $? > /tmp/with-build-w.rc
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
out/bin/with build :cli-selfhost-build-w-tests
make build
make fixpoint
make test
```

After the extraction commit lands, update `build-kind-table-audit.md` in a
separate follow-up commit so kind `1011` is listed as removed.
