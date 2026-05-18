# Phase C Extraction Plan: PCRE2 Targets

Status: plan for the PCRE2 extraction group. No implementation in this commit.

This extraction will move the With repository's PCRE2 migrated-library targets
out of generic compiler-driver dispatch and into project-local build actions.
PCRE2 is the first migrated third-party library, but the shape must generalize
to future migrated libraries such as jq, sqlite, minicoro, and termbox2.

## 1. Placement

The extracted code will live in a new project-local module:

```with
module build_pcre2
```

at repository root as `build_pcre2.w`.

It does not belong in `lib/std/build.w`: PCRE2 release URLs, reference-tree
normalization, migration exclusion lists, generated stdlib promotion, and corpus
policy are specific to this repository.

## 2. What Moves

Move from `src/BuildGraphPcre2.w`:

- PCRE2 reference preparation helpers:
  - `pcre2_split_lines`
  - `pcre2_emit_normalized_heap_line`
  - `pcre2_append_normalized_heap_line`
  - `pcre2_normalize_heap_output`
  - `pcre2_copy_if_missing`
  - `pcre2_prepare_reference_tree`
  - `build_graph_run_pcre2_reference_prepare`
- PCRE2 migration helpers:
  - `pcre2_remove_dir_if_exists`
  - `pcre2_remove_file_if_exists`
  - `pcre2_remove_w_file_dir`
  - `pcre2_remove_known_build_tree`
  - `build_graph_run_pcre2_migrate`
- PCRE2 corpus test helper:
  - `build_graph_run_pcre2_test`
- Generated-source check and promotion helpers:
  - `build_graph_insert_after_defs_import`
  - `build_graph_pcre2_add_imports`
  - `build_graph_pcre2_module_name`
  - `build_graph_pcre2_ensure_generated_dependencies`
  - `build_graph_pcre2_line_starts_with_fn_main`
  - `build_graph_pcre2_module_defines_main`
  - `build_graph_pcre2_module_body_for_synthetic_check`
  - `build_graph_count_error_lines`
  - `build_graph_pcre2_count_generated_errors`
  - `build_graph_pcre2_reject_c_exports`
  - `build_graph_run_pcre2_generated_check`
  - `build_graph_run_pcre2_generated_promote`
  - `build_graph_copy_w_files`
  - `build_graph_run_pcre2_build`

Remove from `src/main.w`:

- all dispatch branches for kinds `1005`, `1006`, `1007`, `1008`, `1021`, and
  `1022`
- `use BuildGraphPcre2` if no remaining source uses it

Move from `build.w`:

- `project_kind_pcre2_run_test()`
- `project_kind_pcre2_generated_check()`
- `project_kind_pcre2_generated_promote()`
- `project_kind_pcre2_build()`
- `project_kind_pcre2_reference_prepare()`
- `project_kind_pcre2_migrate()`

## 3. Target Shape

Each PCRE2 target becomes an `.Action` target:

- `pcre2-reference` -> `run_pcre2_reference_action`
- `pcre2-migrate` -> `run_pcre2_migrate_action`
- `pcre2-build` -> `run_pcre2_build_action`
- `pcre2-test` -> `run_pcre2_test_action`
- `pcre2-check-generated` -> `run_pcre2_check_generated_action`
- `pcre2-promote` -> `run_pcre2_promote_action`

The existing dependency policy stays unchanged:

- `pcre2-migrate` depends on `pcre2-reference`.
- `pcre2-build` depends on `build`, not on `pcre2-migrate`.
- `pcre2-test` depends on `verified-existing-stage`, not on
  `pcre2-migrate`.
- `pcre2-promote` depends on `pcre2-test`.

The critical invariant remains: `pcre2-build`, `pcre2-test`, `build`, and
`test` must never implicitly trigger PCRE2 migration.

## 4. Capabilities

The actions need:

- `ActionCtx.inputs()`, `ActionCtx.args()`, and `ActionCtx.output()` for graph
  parameters.
- `ToolFs` for reading, writing, listing, copying, removing, chmod where needed,
  and creating directories.
- `ProcessRunner` for `curl`, `tar`, compiler migration/build/check commands,
  `RunTest`, and produced binaries.
- `Diagnostics` for loud nonzero failures.
- Plain stdout printing for progress/status messages.

Current likely capability gaps:

- `ToolFs.rename` is needed to publish extracted/migrated temp directories
  atomically.
- `ToolFs.remove_dir` may be useful for empty directory cleanup, though
  `remove_tree` can replace most current uses.
- `ProcessRunner` still lacks scoped environment overrides. PCRE2 corpus tests
  currently set `srcdir` and `pcre2test` around the child process. If this is
  needed in project-local code, add a proper ProcessRunner environment API in a
  separate stdlib capability slice before extraction.

These gaps must not be hidden inside the PCRE2 extraction commit.

## 5. Reserved Kinds

After extraction, reserve:

- `1005` as `removed_pcre2_run_test`
- `1006` as `removed_pcre2_generated_check`
- `1007` as `removed_pcre2_generated_promote`
- `1008` as `removed_pcre2_build`
- `1021` as `removed_pcre2_reference_prepare`
- `1022` as `removed_pcre2_migrate`

`build_graph_kind_removed` must return true for each, and old serialized graphs
must fail with the existing regenerate-graph diagnostic.

## 6. Dispatch Removal

After extraction, generic compiler-driver code must not dispatch any PCRE2
project kind and must not import `BuildGraphPcre2`.

If `src/BuildGraphPcre2.w` becomes empty, delete it.

## 7. Parity Standard

Before and after each action extraction, run the corresponding target and
compare exit code, stdout, and stderr.

Targets that are expensive or manually triggered remain manually triggered:

```sh
out/bin/with build :pcre2-reference
out/bin/with build :pcre2-migrate
out/bin/with build :pcre2-build
out/bin/with build :pcre2-test
out/bin/with build :pcre2-check-generated
out/bin/with build :pcre2-promote
```

Do not run `pcre2-migrate` as an implicit side effect of any other target.

## 8. Verification Sequence

For each prerequisite capability slice:

1. Implement the generic capability.
2. Add focused build-system tests.
3. Run `out/bin/with check lib/std/build.w`.
4. Run the focused selfhost target.
5. Run `make build`.
6. Run `make fixpoint`.
7. Run `make test`.
8. Commit and push.

For the PCRE2 extraction:

1. Capture before outputs for the target being extracted.
2. Move one target or tightly coupled target pair.
3. Reserve the old kind(s).
4. Remove generic-driver dispatch for those kind(s).
5. Run focused checks and before/after parity comparison.
6. Run `make build`.
7. Run `make fixpoint`.
8. Run `make test`.
9. Commit and push.
10. Update `docs/build-kind-table-audit.md` in a separate docs-only commit.

Do not combine a stdlib/runtime capability fix with a PCRE2 target extraction.
