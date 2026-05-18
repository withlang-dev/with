# Phase C Extraction Plan: CLI Selfhost Smoke Test

Status: retroactive template for completed extraction.

This document records the intended extraction shape for
`cli-selfhost-smoke-tests`. Future Phase C extractions should use this level of
planning before code moves.

## Placement

The target belongs in the repository-local `build_selfhost.w` module, imported
by root `build.w`. The smoke fixtures test this compiler's CLI behavior; they
are not generic build-system APIs and do not belong in `lib/std`.

## What Moves

Move the project-specific selfhost smoke implementation out of generic
compiler-driver dispatch:

- `BuildKind 1002`, previously `cli_selfhost_smoke_test`
- `build_graph_run_cli_capture`
- `build_graph_run_cli_expect_success`
- `build_graph_run_cli_selfhost_help`
- `build_graph_run_cli_selfhost_test_directives`
- `build_graph_run_cli_selfhost_smoke_test`

Shared assertion helpers can stay only if they still serve other generic graph
paths. Smoke-only helper code moves with the action.

## Target Shape

The root build graph should declare a standard `.Action` target named
`cli-selfhost-smoke-tests`, set its action to the project-local smoke runner,
depend on `selfcheck`, and pass `out/bin/with-stage2` as an input. Fixture and
capture files must be written under a declared output directory such as
`out/test-graph/cli-selfhost-smoke-tests`.

## Capabilities

The action requires only capabilities already exposed by `ActionCtx`:

- `Diagnostics` for target-specific failure messages
- `ToolFs` for fixture directories, fixture files, capture reads, and cleanup
- `ProcessRunner` for invoking the compiler CLI with argv and timeout
- `ProjectInfo` for resolving project-relative paths
- declared inputs and outputs through `ctx.inputs()` / `ctx.outputs()`

No filesystem shell commands are part of the action shape.

## Reserved Kind

Kind `1002` remains reserved after extraction. `build_graph_kind_removed(1002)`
must return true, `build_graph_kind_is_project(1002)` must return false, and
`build_graph_kind_name(1002)` should return `removed_cli_selfhost_smoke_test`.
Old serialized graphs should fail with the standard removed-kind diagnostic:
`this kind was removed; regenerate your build graph`.

## Dispatch Removal

After extraction, `src/main.w` must not dispatch kind `1002` or branch on the
`"smoke"` suite argument. Verify with:

```sh
rg -n "cli_selfhost_smoke_test|build_graph_run_cli_selfhost_smoke|build_graph_run_cli_selfhost_help|build_graph_run_cli_selfhost_test_directives" src/main.w src/BuildGraphKinds.w
```

Expected remaining hits are limited to the removed-kind name/diagnostic.

## Parity Standard

Before and after the extraction, run:

```sh
out/bin/with build :cli-selfhost-smoke-tests > /tmp/with-smoke.out 2> /tmp/with-smoke.err
echo $? > /tmp/with-smoke.rc
```

The extraction is correct only if the target's exit code and observable output
remain equivalent, and the full slice verification also passes:

```sh
out/bin/with check build_selfhost.w
out/bin/with check build.w
out/bin/with build :cli-selfhost-smoke-tests
make build
make fixpoint
make test
```
