# Phase C Extraction Plan: CLI Selfhost Smoke Test

Status: implementation pending.

This is the first Phase C extraction slice. The goal is to remove the
`cli_selfhost_smoke_test` project-specific target from generic compiler-driver
dispatch and re-express it as a repository-local `Build.action` target.

## What's Moving

Current project-specific kind:

- `BuildKind 1002`, named `cli_selfhost_smoke_test`
  - current declaration: `src/BuildGraphKinds.w`
  - current dispatch: `src/main.w`, in `run_build_graph`

Current implementation functions:

- `build_graph_run_cli_capture`
  - file: `src/main.w`
  - role: run compiler CLI with captured stdout/stderr.
- `build_graph_run_cli_expect_success`
  - file: `src/main.w`
  - role: wrapper around captured CLI execution with success diagnostic.
- `build_graph_run_cli_selfhost_help`
  - file: `src/main.w`
  - role: checks top-level `with --help` output.
- `build_graph_run_cli_selfhost_test_directives`
  - file: `src/main.w`
  - role: writes small test directive fixtures and checks success/failure behavior.
- `build_graph_run_cli_selfhost_smoke_test`
  - file: `src/main.w`
  - role: validates compiler path and runs the help and test-directive checks.

Nearby assertion helpers currently used by this path:

- `build_graph_assert_contains`
- `build_graph_assert_not_contains`

Current repository target shape:

- `build.w` does not directly create kind `1002`.
- `build.w` creates `cli-selfhost-smoke-tests` as kind `1019`
  (`selfhost_suite_test`) with arg `"smoke"`.
- `build_graph_run_cli_selfhost_suite_test` dispatches `"smoke"` to
  `build_graph_run_cli_selfhost_smoke_test`.

The extraction therefore removes both the direct `1002` dispatch path and the
`"smoke"` branch inside the hardcoded selfhost suite dispatcher for this target.

## Where It's Moving

Create a repository-local module at:

```text
build_selfhost.w
```

Justification:

- The selfhost fixtures are tests for this repository's compiler CLI.
- They are not standard build-system APIs and do not belong in `lib/std`.
- They are small enough to start as one root-level project build module,
  matching the existing `build_runtime.w` pattern.
- Larger fixture groups can later split into narrower project-local modules if
  needed, but the first extraction should keep import and bootstrap surface
  minimal.

`build.w` will import `build_selfhost` and use its action function when
declaring `cli-selfhost-smoke-tests`.

## New Target Shape

Before:

```with
var cli_selfhost_smoke_tests = target_new(project_kind_selfhost_suite_test(), "cli-selfhost-smoke-tests", "out/bin/with-stage2")
cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.arg("smoke")
cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.input("out/bin/with-stage2")
cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.dep("selfcheck")
out = out.add_target(cli_selfhost_smoke_tests)
```

After:

```with
var cli_selfhost_smoke_tests = target_new(.Action, "cli-selfhost-smoke-tests", "").output("out/test-graph/cli-selfhost-smoke-tests")
cli_selfhost_smoke_tests.action = run_cli_selfhost_smoke_action
cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.input("out/bin/with-stage2")
cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.dep("selfcheck")
out = out.add_target(cli_selfhost_smoke_tests)
```

The action reads the compiler path from `ctx.inputs().get(0)`. The target output
is a declared action output directory under `out/test-graph/` so fixture writes
remain inside the action write scope.

## Required Capabilities

The action needs:

- `Diagnostics`
  - available through `ActionCtx.diagnostics()`;
  - used for clear target-specific failure messages.
- `ToolFs`
  - available through `ActionCtx.fs()`;
  - used to create fixture directories, write fixture source files, read
    captured output, and remove successful capture files.
- `ProcessRunner`
  - available through `ActionCtx.process_runner()`;
  - used to invoke the compiler CLI with argv and timeout.
- `ProjectInfo`
  - available through `ActionCtx.project_info()`;
  - used to resolve project-relative paths to absolute process/capture paths.
- Declared inputs and outputs
  - available through `ActionCtx.inputs()`, `ActionCtx.outputs()`, and
    `ActionCtx.output()`.

All required capabilities already exist on `ActionCtx`.

## Reserved-Kind Diagnostic

Old kind `1002` must not disappear silently.

Implementation requirements:

- remove `build_graph_kind_cli_selfhost_smoke_test()`;
- mark `1002` as removed in `build_graph_kind_removed`;
- update `build_graph_kind_is_project` so `1002` is no longer valid;
- keep `build_graph_kind_name(1002)` returning a removed-name string such as
  `removed_cli_selfhost_smoke_test`;
- rely on the existing removed-kind diagnostic:
  `"this kind was removed; regenerate your build graph"`.

This matches the existing reserved-kind pattern for `1001` and `1012`.

## Dispatch Code Removed

Remove from `src/main.w`:

- the `run_build_graph` case that checks
  `target.kind == build_graph_kind_cli_selfhost_smoke_test()`;
- the `"smoke"` branch in `build_graph_run_cli_selfhost_suite_test`;
- the smoke implementation helpers listed in "What's Moving" once they are
  available in `build_selfhost.w`.

Confirm by inspection after the extraction:

```sh
rg -n "cli_selfhost_smoke_test|build_graph_run_cli_selfhost_smoke|build_graph_run_cli_selfhost_help|build_graph_run_cli_selfhost_test_directives" src/main.w src/BuildGraphKinds.w
```

Expected remaining hits should be only the removed-kind name/diagnostic for
`1002`, if any.

## Verification Plan

Baseline before implementation:

```sh
out/bin/with build :cli-selfhost-smoke-tests > /tmp/with-smoke-before.out 2> /tmp/with-smoke-before.err
echo $? > /tmp/with-smoke-before.rc
```

After implementation:

```sh
out/bin/with build :cli-selfhost-smoke-tests > /tmp/with-smoke-after.out 2> /tmp/with-smoke-after.err
echo $? > /tmp/with-smoke-after.rc
cmp /tmp/with-smoke-before.rc /tmp/with-smoke-after.rc
cmp /tmp/with-smoke-before.out /tmp/with-smoke-after.out
cmp /tmp/with-smoke-before.err /tmp/with-smoke-after.err
```

This proves the public build target keeps the same command behavior across the
extraction.

Full slice verification:

```sh
out/bin/with check build_selfhost.w
out/bin/with check build.w
out/bin/with build :cli-selfhost-smoke-tests
make build
make fixpoint
make test
```

After verification, commit and push the implementation slice separately from
this plan.
