# Phase C Extraction Plan: Embedded Runtime Regression

Status: plan for the next extraction slice. No implementation in this commit.

This extraction will move `embedded-runtime-regression` out of generic
compiler-driver dispatch and into the With compiler repository's project-local
build actions.

## 1. Placement

The extracted action will live in `build_selfhost.w`.

This is a repository selfhost fixture, not a standard build primitive. It tests
the With compiler binary's embedded runtime-object behavior by building and
running a tiny program in an isolated fixture directory.

## 2. What Moves

Move from `src/main.w`:

- `build_graph_run_embedded_runtime_extract_test`
- the `run_build_graph` dispatch branch for
  `build_graph_kind_embedded_runtime_extract_test()`

Move from `build.w`:

- `project_kind_embedded_runtime_extract_test() -> BuildKind: 1000 as BuildKind`

Reserve in `src/BuildGraphKinds.w`:

- `1000` as `removed_embedded_runtime_extract_test`

## 3. Target Shape

`build.w` will define `embedded-runtime-regression` as a `.Action` target:

```with
var embedded_runtime_regression = target_new(.Action, "embedded-runtime-regression", "")
embedded_runtime_regression.action = run_embedded_runtime_regression_action
embedded_runtime_regression = embedded_runtime_regression.output("out/test-graph/embedded-runtime-regression")
embedded_runtime_regression = embedded_runtime_regression.input("out/bin/with")
embedded_runtime_regression = embedded_runtime_regression.dep("build")
```

The action will copy the compiler input into its output fixture directory, write
`hello.w`, run the copied compiler with `WITH_OUT_DIR` set to a nonexistent
directory, run the produced program, and assert stdout is exactly `hello`.

## 4. Capabilities

The action needs:

- `ActionCtx.inputs()` for the built compiler path.
- `ActionCtx.output()` for the fixture directory.
- `ToolFs` for directory creation, file writing, file reading, file removal,
  compiler binary copy, and executable permission setting.
- `ProcessRunner` for running the copied compiler and the produced test binary.
- `Diagnostics` for loud failures.

Current gap: `ToolFs` has tree-copy and symlink operations, but it does not have
single-file copy or chmod. Those must land as a separate stdlib capability slice
before this extraction. The extraction commit must not smuggle that capability
change into the project-target move.

## 5. Reserved Kind

Kind `1000` will be reserved after extraction. `build_graph_kind_removed(1000)`
must return true, and `build_graph_kind_name(1000)` must return
`removed_embedded_runtime_extract_test`.

Old serialized graphs containing kind `1000` should fail with the existing
removed-kind diagnostic and tell the user to regenerate the build graph.

## 6. Dispatch Removal

After extraction, `src/main.w` must not dispatch kind `1000` or branch on
`build_graph_kind_embedded_runtime_extract_test()`.

`src/BuildGraphKinds.w` must not expose
`build_graph_kind_embedded_runtime_extract_test()`.

## 7. Parity Standard

Before and after the extraction, run:

```sh
out/bin/with build :embedded-runtime-regression > /tmp/with-embedded-before.out 2> /tmp/with-embedded-before.err
out/bin/with build :embedded-runtime-regression > /tmp/with-embedded-after.out 2> /tmp/with-embedded-after.err
```

The target's exit code, stdout, and stderr must match exactly.

## 8. Verification Sequence

For the prerequisite `ToolFs` capability slice:

1. Implement `ToolFs.copy_file` and `ToolFs.chmod` with sandbox checks.
2. Add focused selfhost fixture coverage.
3. Run `out/bin/with check build_selfhost.w`.
4. Run `make build`.
5. Run `make fixpoint`.
6. Run `make test`.
7. Commit and push.

For the extraction slice:

1. Capture the before output.
2. Move the target to `build_selfhost.w`.
3. Reserve kind `1000`.
4. Remove generic-driver dispatch.
5. Run focused checks and the before/after parity comparison.
6. Run `make build`.
7. Run `make fixpoint`.
8. Run `make test`.
9. Commit and push.
10. Update `docs/build-kind-table-audit.md` in a separate docs-only commit.
