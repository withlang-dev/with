# Build Script Compatibility Survey

Status: pre-Phase-D audit complete.

This document inventories the current `build.w` ecosystem before D1 changes
how build scripts execute. D1 must preserve these observable semantics while
replacing generated runner binaries with capability-aware comptime evaluation.

## Survey Scope

Build script files in the repository:

- `build.w`
- `build_compiler.w`
- `build_emit_c.w`
- `build_pcre2.w`
- `build_runtime.w`
- `build_seed.w`
- `build_selfhost.w`

No other `build.w` or `build_*.w` project files were found outside
`lib/std/build.w`, which is the standard library API surface rather than a
project script.

## Capability API Surface Used

The surveyed scripts currently use the following capability methods from
`lib/std/build.w`.

| Capability | Methods used | D1 compatibility | D7 replacement sketch |
| --- | --- | --- | --- |
| `BuildCtx` | `new_build`, `project_info`, `diagnostics`, `source_emitter`, `fs`, `process_runner` | Must work unchanged. Existing `pub fn build(ctx: BuildCtx) -> Build` remains accepted. | Build declarations stay in `build.w`; compiler-project actions can later move to workspace methods where appropriate. |
| `ActionCtx` | `target_name`, `project_info`, `diagnostics`, `fs`, `process_runner`, `inputs`, `outputs`, `args`, `output` | Must work unchanged for action functions. D1 changes invocation mechanism only. | Actions that are really compiler invocations become `Workspace.compile`/`Workspace.emit_*` calls. File and process orchestration remains capability-based. |
| `ToolFs` | `exists`, `host_exists`, `is_dir`, `mkdir_all`, `read_text`, `list_files`, `write_text`, `copy_file`, `chmod`, `rename`, `remove_file`, `remove_tree`, `copy_tree`, `symlink` | Must preserve sandboxing, write scopes, and path diagnostics. | Workspace APIs should use `ToolFs` for filesystem effects rather than reintroducing shell commands. |
| `ProcessRunner` | `run`, `run_capture`, `run_capture_with_env`, `run_capture_cwd`, `run_capture_cwd_with_env`, `run_capture_input`, `spawn_capture`, `wait` | Must preserve argv semantics, capture files, timeout behavior, env override behavior, and driver-env stripping. | Compiler invocations should migrate to workspace APIs; genuine external tools (`curl`, `tar`, `git`, `xcrun`, `zig cc`, `nm`) remain `ProcessRunner` calls until dedicated capabilities exist. |
| `Build` / `Target` | `default`, `add_target`, `generated_source`, `add_generated_source`, convenience target constructors, `target`, `optimize`, `link_system_lib`, `include_path`, `define`, `output`, `input`, `extra_output`, `write_scope`, `dep`, `arg`, `compiler` | Must keep graph output compatible. | D2 may route fields through `BuildOptions`; graph target concepts remain. |

Unsupported pattern found: none. The surveyed scripts rely on generated-runner
process execution, but that is the dispatch mechanism D1 is replacing, not a
user-facing semantic.

## Target Inventory

Only root `build.w` contributes graph targets. The `build_*.w` files define
actions and helpers used by those targets.

Root target categories:

- Compiler source generation: `compiler-sources`.
- Runtime/source generation: `compat-runtime-source`,
  `bootstrap-llvm-link-metadata`, `llvm-link-metadata`.
- Runtime objects: With object targets, LLVM IR object targets, assembly object
  targets, and embedded object assembly/object targets.
- Stage chain: `stage1`, `stage2`, `stage3`, `stage2-fixpoint-object`,
  `stage3-fixpoint-object`, `build`.
- Verification: `selfcheck`, `fixpoint`, behavior/compile-error/codegen/spec/
  phase tests, selfhost action suites, `emit-c-smoke`, `issue61-regression`,
  `embedded-runtime-regression`.
- Install and seed: `install-user`, `install`, `seed`, `update-seed`.
- Maintenance: `clean`.
- Manual emit-C: `emit-c-test`, `emit-c-fixpoint`, `emit-c-roundtrip`.
- Manual PCRE2: `pcre2-reference`, `pcre2-migrate`, `pcre2-build`,
  `pcre2-test`, `pcre2-check-generated`, `pcre2-promote`.
- PCRE2 smoke tests: `pcre2-migrate-smoke`, `pcre2-test-smoke`.

Target kinds used:

- `Action`
- `CompileLlvmIrObject`
- `CompileAsmObject`
- `EmbedObjectFiles`
- `RunCorpusTest`
- `FixpointCompare`
- `Group`
- `Test`
- `Install`
- `Clean`

## File Inventory

### `build.w`

Defined functions:

- Path/string helpers: `build_project_dirname`, `build_project_join`,
  `build_project_abs`, `build_trim_trailing_line_endings`,
  `build_replace_once`.
- Target constructors: `with_object_target`, `with_ir_target`,
  `install_file_target`.
- Issue 61 regression action: `issue61_fail`,
  `issue61_regression_action`.
- Entry point: `pub fn build(ctx: BuildCtx) -> Build`.

Capability methods called:

- `BuildCtx.new_build`.
- `ActionCtx.diagnostics`, `inputs`, `fs`, `output`, `project_info`,
  `process_runner`.
- `ToolFs.exists`, `mkdir_all`, `remove_tree`, `copy_tree`, `symlink`,
  `read_text`, `write_text`.
- `ProcessRunner.run_capture_cwd`.
- `Build.add_target` and many `Target.*` graph construction helpers.

External processes spawned:

- In `issue61_regression_action`, the current compiler is invoked as
  `check src/main.w` in a copied repository fixture.

Files read or written:

- Reads source/runtime/test inputs declared as target inputs.
- Issue 61 action copies `src`, symlinks `lib`, copies
  `out/gen/compiler/EmbeddedStdlibData.w`, patches `src/SemaCheck.w` inside
  a fixture tree, and captures check output under the target output directory.

D1/D7 compatibility:

- D1 must preserve graph construction and action invocation behavior.
- D7 should replace stage compilation actions with workspace compile/emit
  operations, but this file's target graph shape should remain recognizable.

### `build_compiler.w`

Defined functions:

- Helpers: `comp_fail`, `comp_join`, `comp_abs`, `comp_dirname`,
  `comp_trim`, `comp_first_trimmed_line`, `comp_index_of`,
  `comp_replace_all`, `comp_split_whitespace`.
- Tool discovery: `comp_tool_from_env`, `comp_llvm_prefix`,
  `comp_llvm_config_tool`, `comp_llvm_clang_tool`, `comp_libclang_path`,
  `comp_host_sdk_path`, `comp_resolve_seed_compiler`,
  `comp_compiler_path`.
- Compiler/action helpers: `comp_capture_stdout`, `comp_arg_value`,
  `comp_arg_allowed_for_compiler`, `comp_path_exists`,
  `comp_path_for_process`, `comp_run_compiler_capture`,
  `comp_compile_args`, `comp_remove_file_if_exists`,
  `comp_remove_tree_if_exists`, `comp_resolve_compiler_version`,
  `comp_write_versioned_source`.
- Actions: `run_generate_compiler_entrypoints_action`,
  `run_generate_llvm_link_metadata_action`, `run_with_compiler_build_action`,
  `run_with_compiler_ir_action`.

Capability methods called:

- `ActionCtx.diagnostics`, `target_name`, `fs`, `project_info`, `args`,
  `inputs`, `output`, `process_runner`.
- `ToolFs.exists`, `host_exists`, `read_text`, `write_text`, `mkdir_all`,
  `remove_file`, `remove_tree`, `rename`.
- `ProcessRunner.run_capture`, `run_capture_with_env`.

External processes spawned:

- `/usr/bin/xcrun --show-sdk-path`.
- `with --version` for PATH seed probing.
- `git rev-parse --short=9 HEAD` and `git rev-list --count HEAD`.
- `llvm-config --link-static --libfiles ...`.
- Compiler invocations for `build`, `ir`, `--emit-obj`, and related stage
  outputs.

Files read or written:

- Reads `src/version`, source entry files, generated compiler entry files,
  LLVM object inputs, and existing stage outputs.
- Writes `out/gen/main.w`, `out/gen/bootstrap_main.w`,
  `out/gen/main_emit_temp.w`, `out/gen/version.txt`,
  `out/lib/llvm_link.rsp`, `out/lib/llvm_cc`, stage binaries/objects,
  command captures under `out/command/<target>`.

D1/D7 compatibility:

- D1 must preserve action semantics. D7 should replace compiler subprocess
  invocations with workspace compile/emit calls. External `git`, `xcrun`, and
  `llvm-config` remain `ProcessRunner` calls unless future dedicated
  capabilities are introduced.

### `build_emit_c.w`

Defined functions:

- Helpers: `emitc_fail`, `emitc_join`, `emitc_abs`, `emitc_dirname`,
  `emitc_basename`, `emitc_trim`, `emitc_index_of`, `emitc_split_lines`.
- Stub parsing/generation: `emitc_c_export_symbol`,
  `emitc_find_matching_paren`, `emitc_c_type`, `emitc_stub_return`,
  `emitc_parse_param`, `emitc_parse_params`, `emitc_parse_export_function`,
  `emitc_collect_exports_from_text`, `emitc_collect_exports`,
  `emitc_function_proto`, `emitc_generate_stub_files`.
- Process/test helpers: `emitc_capture_rel`, `emitc_run_capture`,
  `emitc_compile_runtime_args`, `emitc_build_compiler_c`,
  `emitc_compile_c_compiler`, `emitc_compile_c_compiler_with_bridges`,
  `emitc_migrate_compiler_c`, `emitc_build_with_compiler`,
  `emitc_run_single_test`, `emitc_test_target_files`,
  `emitc_run_test_group`, `emitc_run_compiler_test_suite`,
  `emitc_build_hello_c`, `emitc_compile_hello`, `emitc_run_hello`,
  `emitc_compare_files`.
- Actions: `run_emit_c_test_action`, `run_emit_c_fixpoint_action`,
  `run_emit_c_roundtrip_action`.

Capability methods called:

- `ActionCtx.diagnostics`, `target_name`, `fs`, `project_info`, `inputs`,
  `output`, `process_runner`.
- `ToolFs.read_text`, `write_text`, `exists`, `mkdir_all`, `remove_tree`,
  `remove_file`, `list_files`.
- `ProcessRunner.run_capture`, `run_capture_with_env`.

External processes spawned:

- Current compiler with `build --emit-c`, `migrate`, `build`, and `test`.
- `zig cc`.
- LLVM C compiler recorded in `out/lib/llvm_cc` with `-fuse-ld=lld`.

Files read or written:

- Reads bridge/runtime source files, runtime objects, emitted C, generated
  declarations, generated stubs, test files, and compiler outputs.
- Writes `out/gen/wl_decls.h`, `out/gen/wl_stubs.c`,
  `out/emit-c-test`, `out/emit-c-roundtrip`, command captures, and stamp
  files.

D1/D7 compatibility:

- D1 must preserve process execution and capture behavior. D7 can replace
  compiler invocations with workspace APIs, but C compilation through `zig cc`
  and external linker execution remain `ProcessRunner` responsibilities.

### `build_pcre2.w`

Defined functions:

- Helpers: `pcre2_join`, `pcre2_scratch_dir`, `pcre2_dirname`,
  `pcre2_basename`, `pcre2_abs`, `pcre2_split_lines`,
  heap-output normalization helpers, `pcre2_copy_if_missing`, `pcre2_fail`,
  `pcre2_remove_tree_if_exists`, `pcre2_remove_file_if_exists`,
  `pcre2_count_w_files`, `pcre2_reject_c_exports`, module/import helpers,
  generated dependency helpers, generated error counting, W-file copying,
  temp-dir helpers, reference-tree preparation.
- Actions: `run_pcre2_reference_action`, `run_pcre2_migrate_action`,
  `run_pcre2_migrate_smoke_action`, `run_pcre2_test_smoke_action`,
  `run_pcre2_build_action`, `run_pcre2_test_action`,
  `run_pcre2_check_generated_action`, `run_pcre2_promote_action`.

Capability methods called:

- `ActionCtx.diagnostics`, `target_name`, `fs`, `project_info`, `inputs`,
  `outputs`, `args`, `output`, `process_runner`.
- `ToolFs.exists`, `mkdir_all`, `read_text`, `write_text`, `remove_file`,
  `remove_tree`, `copy_file`, `rename`, `list_files`.
- `ProcessRunner.run`, `run_capture`, `run_capture_with_env`,
  `run_capture_cwd_with_env`.

External processes spawned:

- `curl` and `tar` for reference download/extract.
- Current compiler for `migrate`, `check`, `build`, and test binary execution.

Files read or written:

- Reads `.reference`/PCRE2 source files once downloaded, generated `.w` files,
  `lib/std/re` support files, temporary smoke fixtures, and corpus outputs.
- Writes `out/pcre2_reference`, `out/pcre2_tmp`, `out/pcre2_migrate_raw`,
  `out/pcre2_generated`, `out/pcre2_build`, `out/corpus/pcre2-test`, PCRE2
  stamp files, and optionally promoted `lib/std/re` files.

D1/D7 compatibility:

- D1 must preserve actions exactly. D7 can replace compiler subprocesses with
  workspace `migrate`, `check`, and `build` operations. `curl`/`tar` stay
  external unless a future download/archive capability is designed.

### `build_runtime.w`

Defined functions:

- Helpers: `br_fail`, `br_join`, `br_dirname`, `br_split_nonempty_lines`,
  `br_str_compare`, `br_sorted_paths`, `br_collect_stdlib_files`,
  `br_contains_delimiter`, `br_raw_string_literal`, `br_embedded_rel_path`,
  `br_generate_embedded_stdlib`.
- Action: `generate_compat_runtime_action`.

Capability methods called:

- `ActionCtx.diagnostics`, `inputs`, `outputs`, `fs`.
- `ToolFs.list_files`, `read_text`, `exists`, `mkdir_all`, `write_text`.

External processes spawned:

- None.

Files read or written:

- Reads `lib/std/**` through `ToolFs.list_files`, reads `rt/compat_runtime.w`,
  writes generated embedded stdlib data and generated compat runtime source.

D1/D7 compatibility:

- Should continue unchanged through D1. D7 may keep this as an action or model
  it as a generated-source workspace step.

### `build_seed.w`

Defined functions:

- Helpers: `seed_join`, `seed_dirname`, `seed_abs`, `seed_fail`,
  `seed_tool_from_env`, `seed_split_nonempty_lines`, `seed_json_line_value`,
  `seed_release_from_api`.
- Action: `run_seed_download_action`.

Capability methods called:

- `ActionCtx.diagnostics`, `target_name`, `fs`, `project_info`, `args`,
  `output`, `process_runner`.
- `ToolFs.exists`, `mkdir_all`, `read_text`, `remove_file`, `rename`, `chmod`.
- `ProcessRunner.run`, `run_capture`.

External processes spawned:

- `curl` for GitHub release API and seed asset download.

Files read or written:

- Writes and removes temporary files under `out/tmp/seed-download`.
- Writes `src/main` and marks it executable.

D1/D7 compatibility:

- Should continue unchanged through D1. It is not a compiler workspace
  operation; it remains an external download/install action.

### `build_selfhost.w`

Defined functions:

- Shared helpers: `bs_fail`, path helpers, capture-path helpers, string literal
  helpers, command wrappers, assertion helpers, file assertions, split/count
  helpers, project fixture helpers, `nm` helpers.
- Action groups:
  - `run_embedded_runtime_regression_action`
  - `run_cli_selfhost_smoke_action`
  - `run_cli_selfhost_one_liner_action`
  - `run_cli_selfhost_project_action`
  - `run_emit_c_smoke_action`
  - `run_cli_selfhost_edge_action`
  - `run_cli_selfhost_parallel_action`
  - `run_cli_selfhost_migrate_basic_action`
  - `run_cli_selfhost_migrate_core_action`
  - `run_cli_selfhost_build_w_action`
  - `run_cli_selfhost_pcre2_prep_action`
  - `run_cli_selfhost_object_symbol_action`

Capability methods called:

- `ActionCtx.diagnostics`, `target_name`, `fs`, `project_info`, `inputs`,
  `output`, `process_runner`.
- `ToolFs.exists`, `mkdir_all`, `read_text`, `write_text`, `copy_file`,
  `chmod`, `remove_file`, `remove_tree`.
- `ProcessRunner.run_capture`, `run_capture_input`, `run_capture_cwd`,
  `spawn_capture`, `wait`.

External processes spawned:

- Current compiler for `check`, `build`, `test`, `migrate`, `--emit-c`,
  `--emit-obj`, one-liner `-e`, and project `init`.
- Built test binaries.
- C compiler for emit-C smoke cases.
- `nm` for object symbol tests.

Files read or written:

- Writes extensive temporary fixtures under `out/test-graph/**`.
- Reads `docs/with_for_ai.md`, generated stdlib/runtime files, test fixtures,
  migrated PCRE2 fixtures, object files, emitted C, and compiler outputs.
- Captures stdout/stderr/stdin files for selfhost commands.

D1/D7 compatibility:

- D1 must preserve action behavior and process capture semantics. D7 should
  migrate compiler subprocess calls that build/check/test/migrate With code to
  workspace operations where this does not weaken the tests. Some tests must
  intentionally keep subprocess execution because they are CLI tests.

## Compatibility Planning by Pattern

| Pattern | Current examples | D1 status | D7 sketch |
| --- | --- | --- | --- |
| Build graph construction | root `build.w`, generated build.w fixtures in `build_selfhost.w` | Preserve graph text and target semantics. | Build graph remains the user-facing build declaration format unless workspaces replace only internal execution. |
| Generated-source declaration | `compat-runtime-source`, build-w generated-source fixtures | Preserve `SourceEmitter` and generated-source graph semantics. | D5/D7 may map generated sources to workspace generations. |
| Compiler subprocess build/check/test | stage actions, selfhost suites, PCRE2, emit-C | Preserve existing subprocess semantics during D1. | Replace project-internal compiler invocations with workspace compile/test/migrate APIs except for tests that explicitly validate CLI behavior. |
| External system tools | `curl`, `tar`, `git`, `xcrun`, `llvm-config`, `zig cc`, `nm` | Preserve via `ProcessRunner`. | Stay process calls or become future dedicated capabilities. Do not fold into Workspace. |
| Filesystem orchestration | all action modules | Preserve `ToolFs` sandbox and write-scope checks. | Keep `ToolFs`; workspaces should not bypass it for project file effects. |
| Environment override | LLVM/compile actions, PCRE2 run/build actions, emitted C actions | Preserve `ProcessEnv` behavior. | Process env must become per-child, not parent-process mutation, before D6. |
| Parallel child process orchestration | `run_cli_selfhost_parallel_action` uses `spawn_capture`/`wait` | Preserve existing APIs and timeouts. | D6 scheduler may eventually run action graph nodes in parallel; this test still validates `ProcessRunner` child management. |
| Manual target smoke/full split | PCRE2 and emit-C targets | Preserve target names and manual/default distinction. | Workspace APIs can speed internals; target policy remains in `build.w`. |

## Blockers for Phase-D Design

No unsupported build-script pattern blocks D1. The risky areas are already
identified by other pre-D documents:

- generated-runner/env-token dispatch must be replaced without changing
  capability semantics
- process environment mutation must not survive into parallel execution
- compiler subprocess calls need a careful D7 split so CLI tests remain CLI
  tests while internal build/test/migrate actions become workspace calls

## Verification Expectations

The P7 tests should cover at least these currently surveyed behaviors:

- minimal `BuildCtx` graph construction
- generated source emission
- `ToolFs` read/write/list/copy/remove sandbox behavior
- `ProcessRunner` capture, cwd, env, stdin, and timeout behavior
- action failure diagnostics with target name
- `--no-deps` action isolation

Those tests should pass before and after the P8 `src/main.w` refactor, then
serve as the first regression net for D1.
