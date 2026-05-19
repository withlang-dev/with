# Phase C Extraction Plan: Seed Download

## Placement

Seed acquisition is specific to the With compiler repository. The generic build
driver should not know that this project stores its seed compiler at `src/main`
or downloads release assets from `withlang-dev/with`. The extracted action will
live in a new project-local module, `build_seed.w`, imported by the repository
root `build.w`.

## What Moves

- BuildKind `1024`, currently `seed_download`.
- `build_graph_seed_release_from_api` from `src/BuildGraphOps.w`.
- `build_graph_run_seed_download` from `src/BuildGraphOps.w`.

Shared generic helpers stay where they are unless they become unused by generic
code after the extraction. The project action will use `std.build` capabilities
and small local string/path helpers instead of calling `BuildGraphRuntime`.

## Target Shape

`build.w` will replace:

```with
target_new(project_kind_seed_download(), "seed", "withlang-dev/with")
```

with:

```with
target_new(.Action, "seed", "").output("src/main")
```

The action function will be `run_seed_download_action` in `build_seed.w`. The
repository and asset name will be action arguments, preserving the current
`withlang-dev/with` and `main` configuration.

## Capabilities

The action needs:

- `ToolFs` to check, write, rename, chmod, and remove seed files under the
  project root.
- `ProcessRunner` to invoke `curl`.
- `Diagnostics` to report missing release assets and download failures.
- `ProjectInfo` to build absolute paths for process output files.

These are already available from `ActionCtx`.

## Reserved Kind

Kind `1024` must be moved from live project kind to removed project kind. Its
name should become `removed_seed_download`, and serialized graphs that still use
`1024` should fail with the existing removed-kind diagnostic.

## Dispatch Removal

`run_build_graph` should no longer contain a branch for
`build_graph_kind_seed_download()`. After extraction, no source file should call
`build_graph_run_seed_download`.

## Parity Standard

The non-destructive baseline is:

```sh
out/bin/with build :seed
```

when `src/main` already exists. The extracted action must return exit code `0`
and print the same public message:

```text
seed binary already exists: src/main
remove it first if you want to re-download
```

The network download path is preserved by code inspection and focused action
structure; it should not be exercised during normal verification because it
would replace the local seed.

## Verification Sequence

1. `out/bin/with check build.w`
2. `out/bin/with check src/main.w`
3. `out/bin/with build :seed`, compared against the captured baseline above
4. `make build`
5. `make fixpoint`
6. `make test`
7. Commit and push the extraction
8. Update `docs/build-kind-table-audit.md` in a separate docs-only commit
