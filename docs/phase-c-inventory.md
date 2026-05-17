# Phase C Inventory

Status: read-only inventory.

This document lists project-specific build graph code that currently lives under
`src/`. It intentionally does not propose moves or fixes.

Scope:

- Included: PCRE2-related, emit-C-related, seed-related, and selfhost-fixture-related build functions, types, and `BuildKind` values.
- Excluded: general compiler implementation code such as C migration internals, C codegen internals, parser, sema, MIR, and standard build graph primitives unless they directly define one of the categories above.

Line counts are approximate source spans for the listed declaration.

## Project Build Kinds

File: `src/BuildGraphKinds.w`

| Kind | Name | Description |
| ---: | --- | --- |
| 1000 | `embedded_runtime_extract_test` | Selfhost fixture target for embedded runtime extraction behavior. |
| 1002 | `cli_selfhost_smoke_test` | Selfhost CLI smoke target. |
| 1003 | `generate_compiler_entrypoints` | Compiler-project target that generates versioned compiler entrypoint source. |
| 1004 | `with_compiler_build` | Compiler-project target that builds the With compiler. |
| 1005 | `pcre2_run_test` | PCRE2 migrated-library corpus test target. |
| 1006 | `pcre2_generated_check` | PCRE2 generated-source check target. |
| 1007 | `pcre2_generated_promote` | PCRE2 generated-source promotion target. |
| 1008 | `pcre2_build` | PCRE2 migrated-library build target. |
| 1009 | `cli_selfhost_one_liner_test` | Selfhost fixture target for one-liner behavior. |
| 1010 | `cli_selfhost_object_symbol_test` | Selfhost fixture target for object symbol behavior. |
| 1011 | `cli_selfhost_build_w_test` | Selfhost fixture target for `build.w` behavior. |
| 1013 | `with_compiler_ir` | Compiler-project target that emits compiler IR. |
| 1014 | `cli_selfhost_project_test` | Selfhost fixture target for project initialization and project metadata behavior. |
| 1015 | `cli_selfhost_edge_test` | Selfhost fixture target for edge-case CLI/compiler behavior. |
| 1016 | `cli_selfhost_pcre2_prep_test` | Selfhost fixture target for PCRE2 preparation behavior. |
| 1017 | `cli_selfhost_migrate_basic_test` | Selfhost fixture target for basic C migrator behavior. |
| 1018 | `cli_selfhost_migrate_core_test` | Selfhost fixture target for core C migrator behavior. |
| 1019 | `selfhost_suite_test` | Selfhost fixture suite aggregation target. |
| 1020 | `generate_llvm_link_metadata` | Compiler-project target that generates LLVM link metadata. |
| 1021 | `pcre2_reference_prepare` | PCRE2 reference source preparation target. |
| 1022 | `pcre2_migrate` | PCRE2 migration target. |
| 1024 | `seed_download` | Seed compiler download target. |
| 1025 | `emit_c_test` | Emit-C smoke/parity test target. |
| 1026 | `emit_c_fixpoint` | Emit-C fixpoint target. |
| 1027 | `emit_c_roundtrip` | Emit-C roundtrip target. |

Removed project kinds retained for diagnostics:

| Kind | Name | Description |
| ---: | --- | --- |
| 1001 | `removed_selfhost_noop_local_regression` | Removed project target kind; old graphs should be regenerated. |
| 1012 | `removed_generate_compat_runtime` | Removed project target kind; old graphs should be regenerated. |

## Project Dispatch

File: `src/main.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `run_build_action_from_build_w` | ~63 | Runs a `build.w` action target by reinvoking the build driver with action environment variables. |
| `load_build_graph_from_build_w` | ~39 | Loads a serialized build graph from a project `build.w`. |
| `run_build_graph` | ~346 | Main build graph executor; dispatches standard kinds and every project-specific 1000-series kind. |

## Selfhost Fixture Harness

File: `src/BuildGraphSelfhostHarness.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `bgs_argv_append` | ~3 | Appends one argument to a newline-delimited argv blob. |
| `bgs_resolve_join` | ~9 | Joins a base path and relative path for fixture execution. |
| `bgs_dirname` | ~9 | Returns a path dirname for fixture helpers. |
| `bgs_basename` | ~7 | Returns a path basename for fixture helpers. |
| `bgs_trim_trailing_line_endings` | ~9 | Trims trailing line endings from captured output. |
| `bgs_with_string_literal` | ~18 | Escapes text as a With string literal for generated fixtures. |
| `bgs_assert_contains` | ~6 | Fixture assertion for expected substring. |
| `bgs_assert_not_contains` | ~6 | Fixture assertion for forbidden substring. |
| `bgs_regex_matches` | ~16 | Regex-backed fixture matching helper. |
| `bgs_assert_matches` | ~6 | Fixture assertion for expected regex match. |
| `bgs_assert_not_matches` | ~6 | Fixture assertion for forbidden regex match. |
| `bgs_project_assert_contains` | ~6 | Project fixture assertion for expected output text. |
| `bgs_project_expect_file` | ~6 | Project fixture assertion for expected file existence. |
| `bgs_project_expect_absent` | ~6 | Project fixture assertion for expected missing file. |
| `bgs_write_fixture` | ~10 | Writes fixture files, creating parent directories. |
| `bgs_write_project_manifest` | ~3 | Writes a minimal project manifest fixture. |
| `bgs_expect_file_contains` | ~9 | Checks a fixture file for expected text. |
| `bgs_run_cli_capture_cwd` | ~17 | Runs the compiler CLI in a fixture working directory with captured output. |
| `bgs_run_binary_capture` | ~16 | Runs a produced binary and captures output. |
| `bgs_build_expect_success` | ~6 | Fixture assertion for successful build command output. |
| `bgs_project_expect_success` | ~5 | Fixture assertion for successful project command output. |

## Selfhost Fixture Targets

File: `src/BuildGraphSelfhost.w`

### CLI And Project Fixtures

| Item | Lines | Description |
| --- | ---: | --- |
| `run_cli_selfhost_parallel_test` | ~51 | Selfhost parallel execution fixture target. |
| `bgs_check_init_ai_docs` | ~15 | Checks `with init` AI docs are generated from embedded templates. |
| `bgs_check_init_common_files` | ~23 | Checks common `with init` files and directories. |
| `bgs_check_init_in_cwd` | ~21 | Checks initializing a project in the current directory. |
| `bgs_check_init_named_dir` | ~26 | Checks initializing a project in a named directory. |
| `bgs_check_build_uses_package_section_name` | ~9 | Checks build behavior uses the package section name. |
| `bgs_check_build_rejects_imperative_manifest` | ~17 | Checks imperative manifest syntax is rejected. |
| `run_cli_selfhost_project_test` | ~11 | Runs project initialization and metadata fixture checks. |

### Edge Fixtures

| Item | Lines | Description |
| --- | ---: | --- |
| `bgs_edge_assert_exact` | ~9 | Edge fixture exact-output assertion. |
| `bgs_edge_assert_contains` | ~6 | Edge fixture substring assertion. |
| `bgs_edge_assert_not_contains` | ~6 | Edge fixture negative substring assertion. |
| `bgs_edge_expect_success` | ~6 | Edge fixture success assertion. |
| `bgs_check_pointer_index_rejected` | ~20 | Checks invalid pointer indexing diagnostics. |
| `bgs_check_prelude_output_functions` | ~10 | Checks prelude output function behavior. |
| `bgs_check_whole_program_extern_var_redecl` | ~22 | Checks whole-program extern variable redeclaration behavior. |
| `bgs_check_imported_module_dependency_order` | ~14 | Checks imported module dependency ordering. |
| `run_cli_selfhost_edge_test` | ~11 | Runs edge fixture checks. |

### PCRE2 Preparation Fixtures

| Item | Lines | Description |
| --- | ---: | --- |
| `bgs_regex_assert_contains` | ~6 | PCRE2 prep fixture substring assertion. |
| `bgs_regex_assert_not_contains` | ~6 | PCRE2 prep fixture negative substring assertion. |
| `bgs_regex_file_contains` | ~6 | PCRE2 prep fixture file substring assertion. |
| `bgs_regex_file_forbids` | ~6 | PCRE2 prep fixture file negative assertion. |
| `bgs_copy_fixture_file` | ~6 | Copies PCRE2 prep fixture files. |
| `bgs_drop_first_lines` | ~13 | Drops leading lines from fixture text. |
| `bgs_regex_expect_success` | ~6 | PCRE2 prep fixture success assertion. |
| `bgs_check_pcre2_defs_prune_ebcdic_tables` | ~6 | Checks EBCDIC table pruning in PCRE2 defs. |
| `bgs_check_pcre2_prepare_shared_externs` | ~32 | Checks PCRE2 shared extern preparation. |
| `bgs_check_pcre2_prepare_width_prunes` | ~24 | Checks width-specific PCRE2 pruning. |
| `bgs_check_pcre2_prepare_shared_lets` | ~36 | Checks shared `let` generation during PCRE2 prep. |
| `bgs_check_std_re_shared_dependency_imports` | ~8 | Checks stdlib regex shared dependency imports. |
| `bgs_check_opaque_field_access_rejected` | ~10 | Checks opaque field access remains rejected. |
| `bgs_check_pcre2_match_heapframe` | ~20 | Checks PCRE2 match heapframe migration behavior. |
| `bgs_check_pcre2_compile_builds` | ~16 | Checks migrated PCRE2 compile module builds. |
| `bgs_check_pcre2_jit_no_support` | ~9 | Checks unsupported JIT path behavior. |
| `bgs_check_pcre2_generated_existing_main` | ~23 | Checks generated PCRE2 code with existing `main`. |
| `run_cli_selfhost_pcre2_prep_test` | ~25 | Runs PCRE2 preparation fixture checks. |

### C Migrator Fixtures

| Item | Lines | Description |
| --- | ---: | --- |
| `bgs_migrate_error` | ~3 | Formats a C migrator fixture error. |
| `bgs_migrate_assert_contains` | ~6 | C migrator fixture substring assertion. |
| `bgs_migrate_assert_not_contains` | ~6 | C migrator fixture negative substring assertion. |
| `bgs_migrate_file_contains` | ~6 | C migrator fixture file substring assertion. |
| `bgs_migrate_file_forbids` | ~6 | C migrator fixture file negative assertion. |
| `bgs_index_of` | ~16 | Substring index helper for migrator fixtures. |
| `bgs_count_occurrences` | ~13 | Counts substring occurrences for migrator fixtures. |
| `bgs_migrate_expect_success` | ~6 | C migrator fixture success assertion. |
| `bgs_check_migrate_global_init_list` | ~16 | Checks global initializer list migration. |
| `bgs_check_migrate_host_header_compat` | ~21 | Checks host header compatibility migration. |
| `bgs_check_migrate_assignment_compat` | ~33 | Checks assignment compatibility migration. |
| `bgs_check_migrate_rvalue_sequencing` | ~31 | Checks rvalue sequencing migration. |
| `bgs_check_migrate_directory_progress` | ~19 | Checks directory migration progress output. |
| `bgs_check_migrate_cross_file_global_owner_arrays` | ~48 | Checks cross-file global owner array migration. |
| `bgs_check_migrate_shared_defs_ownerless_extern` | ~29 | Checks shared defs ownerless extern migration. |
| `run_cli_selfhost_migrate_basic_test` | ~17 | Runs basic C migrator fixture checks. |
| `bgs_check_migrate_libc_ctype` | ~37 | Checks libc ctype migration. |
| `bgs_check_migrate_macro_unsigned_minus` | ~31 | Checks unsigned-minus macro migration. |
| `bgs_check_migrate_tentative_global_owner` | ~21 | Checks tentative global owner migration. |
| `bgs_check_migrate_cross_file_tentative_global_owner` | ~26 | Checks cross-file tentative global owner migration. |
| `bgs_check_migrate_noop_pointer_casts` | ~35 | Checks no-op pointer cast migration. |
| `bgs_check_migrate_raw_pointer_index` | ~24 | Checks raw pointer index migration. |
| `bgs_check_migrate_prefer_brace_ws` | ~28 | Checks migrated brace whitespace style. |
| `bgs_check_migrate_typed_cast_macros` | ~23 | Checks typed cast macro migration. |
| `run_cli_selfhost_migrate_core_test` | ~19 | Runs core C migrator fixture checks. |

### `build.w` Selfhost Fixtures

| Item | Lines | Description |
| --- | ---: | --- |
| `bgs_tool_from_env` | ~6 | Reads a required fixture tool path from the environment. |
| `bgs_nm_smoke` | ~17 | Checks `nm` availability for object-symbol fixtures. |
| `bgs_check_build_w_not_ignored` | ~28 | Checks `build.w` is not ignored by project builds. |
| `bgs_check_build_w_test_targets` | ~30 | Checks test target declaration behavior. |
| `bgs_check_build_w_library_and_targets` | ~50 | Checks library and target declaration behavior. |
| `bgs_check_build_w_generated_source` | ~76 | Checks generated-source-related build graph behavior. |
| `bgs_graph_build_file` | ~58 | Returns a fixture `build.w` body for graph serialization tests. |
| `bgs_require_case_file` | ~7 | Checks a fixture case file exists. |
| `bgs_forbid_case_file` | ~7 | Checks a fixture case file is absent. |
| `bgs_check_build_w_graph_v2` | ~121 | Checks build graph v2 serialization and executor behavior. |
| `bgs_check_removed_build_kind_diagnostic` | ~22 | Checks removed build kind diagnostics. |
| `bgs_check_build_w_action_target` | ~39 | Checks action target declaration and execution behavior. |
| `bgs_check_build_w_action_failures` | ~103 | Checks action target failure diagnostics. |
| `run_cli_selfhost_build_w_test` | ~18 | Runs `build.w` selfhost fixture checks. |

## PCRE2 Build Targets

File: `src/BuildGraphPcre2.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `pcre2_split_lines` | ~15 | Splits PCRE2-related output into lines. |
| `pcre2_emit_normalized_heap_line` | ~22 | Normalizes one heap-test output line. |
| `pcre2_append_normalized_heap_line` | ~3 | Appends a normalized heap-test line. |
| `pcre2_normalize_heap_output` | ~41 | Normalizes PCRE2 heap-test output before comparison. |
| `pcre2_copy_if_missing` | ~12 | Copies a PCRE2 reference file if the destination is absent. |
| `pcre2_prepare_reference_tree` | ~47 | Prepares the PCRE2 reference source tree. |
| `build_graph_run_pcre2_reference_prepare` | ~63 | Build graph target runner for PCRE2 reference preparation. |
| `pcre2_remove_dir_if_exists` | ~8 | Removes a PCRE2 directory when present. |
| `pcre2_remove_file_if_exists` | ~8 | Removes a PCRE2 file when present. |
| `pcre2_remove_w_file_dir` | ~11 | Removes generated `.w` file directories. |
| `pcre2_remove_known_build_tree` | ~48 | Cleans known PCRE2 migration/build output trees. |
| `build_graph_run_pcre2_migrate` | ~89 | Build graph target runner for PCRE2 migration. |
| `build_graph_run_pcre2_test` | ~59 | Build graph target runner for PCRE2 corpus tests. |
| `build_graph_insert_after_defs_import` | ~23 | Inserts PCRE2 generated dependency text after the defs import. |
| `build_graph_pcre2_add_imports` | ~11 | Adds generated imports to a PCRE2 module file. |
| `build_graph_pcre2_module_name` | ~6 | Computes a PCRE2 generated module name from a path. |
| `build_graph_pcre2_ensure_generated_dependencies` | ~41 | Ensures generated PCRE2 dependency imports exist. |
| `build_graph_pcre2_line_starts_with_fn_main` | ~9 | Detects generated `fn main` declarations. |
| `build_graph_pcre2_module_defines_main` | ~12 | Detects whether a generated PCRE2 module defines `main`. |
| `build_graph_pcre2_module_body_for_synthetic_check` | ~17 | Builds synthetic PCRE2 module text for checking. |
| `build_graph_count_error_lines` | ~15 | Counts compiler error lines in generated PCRE2 checks. |
| `build_graph_pcre2_count_generated_errors` | ~57 | Counts expected generated PCRE2 check errors. |
| `build_graph_pcre2_reject_c_exports` | ~11 | Rejects generated PCRE2 files containing `c_export`. |
| `build_graph_run_pcre2_generated_check` | ~19 | Build graph target runner for generated PCRE2 checks. |
| `build_graph_run_pcre2_generated_promote` | ~38 | Build graph target runner for promoting generated PCRE2 code. |
| `build_graph_copy_w_files` | ~17 | Copies generated `.w` files between PCRE2 trees. |
| `build_graph_run_pcre2_build` | ~66 | Build graph target runner for building migrated PCRE2. |

## Emit-C Build Targets

File: `src/BuildGraphEmitC.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `EmitCParam` | ~5 | Temporary parsed C parameter description used by emit-C bridge generation. |
| `EmitCFunction` | ~7 | Temporary parsed C function description used by emit-C bridge generation. |
| `emitc_index_of` | ~19 | Substring index helper for emit-C target code. |
| `emitc_trim` | ~15 | Trims text for emit-C parsing. |
| `emitc_split_lines` | ~15 | Splits emit-C output text into lines. |
| `emitc_c_export_symbol` | ~13 | Extracts a C export symbol from a generated line. |
| `emitc_find_matching_paren` | ~14 | Finds a matching parenthesis in generated C text. |
| `emitc_c_type` | ~18 | Maps With type spelling to generated C type spelling. |
| `emitc_stub_return` | ~9 | Produces a C stub return expression for bridge generation. |
| `emitc_parse_param` | ~14 | Parses one generated C parameter. |
| `emitc_parse_params` | ~14 | Parses generated C parameter lists. |
| `emitc_parse_export_function` | ~39 | Parses one exported generated C function signature. |
| `emitc_collect_exports_from_text` | ~27 | Collects exported functions from generated C text. |
| `emitc_collect_bridge_exports` | ~16 | Collects bridge exports needed by emit-C tests. |
| `emitc_function_proto` | ~12 | Renders a C function prototype. |
| `emitc_generate_stub_files` | ~36 | Generates temporary C bridge stub files. |
| `emitc_run_capture` | ~23 | Runs an emit-C-produced tool and captures output. |
| `emitc_compile_runtime_args` | ~11 | Produces runtime compile arguments for emit-C builds. |
| `emitc_build_compiler_c` | ~10 | Emits the compiler to C. |
| `emitc_compile_c_compiler` | ~19 | Compiles emitted compiler C. |
| `emitc_compile_c_compiler_with_bridges` | ~24 | Compiles emitted compiler C with bridge stubs. |
| `emitc_migrate_compiler_c` | ~14 | Migrates emitted compiler C back to With. |
| `emitc_build_with_compiler` | ~10 | Builds the migrated/emitted compiler with With. |
| `emitc_run_single_test` | ~8 | Runs one compiler test through an emit-C compiler path. |
| `emitc_run_test_group` | ~13 | Runs a group of compiler tests through an emit-C compiler path. |
| `emitc_run_compiler_test_suite` | ~14 | Runs the compiler behavior test subset for emit-C validation. |
| `emitc_build_hello_c` | ~11 | Emits a hello fixture to C. |
| `emitc_compile_hello` | ~15 | Compiles a hello C fixture. |
| `emitc_run_hello` | ~23 | Runs and checks a hello fixture. |
| `emitc_compare_files` | ~18 | Compares emitted/fixpoint files byte-for-byte. |
| `build_graph_run_emit_c_test` | ~54 | Build graph target runner for emit-C smoke tests. |
| `build_graph_run_emit_c_fixpoint` | ~33 | Build graph target runner for emit-C fixpoint comparison. |
| `build_graph_run_emit_c_roundtrip` | ~70 | Build graph target runner for emit-C roundtrip validation. |

## Seed And Compiler-Project Targets

### Seed Download

File: `src/BuildGraphOps.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `build_graph_json_line_value` | ~32 | Extracts simple JSON line values from GitHub release metadata. |
| `build_graph_seed_release_from_api` | ~36 | Selects a seed release URL from release API output. |
| `build_graph_run_seed_download` | ~49 | Build graph target runner for downloading the seed compiler. |

### Compiler Build Entrypoints

File: `src/BuildGraphCompiler.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `bgc_trim_space_and_newlines` | ~15 | Trims text for compiler-project command output parsing. |
| `bgc_first_trimmed_line` | ~9 | Reads the first trimmed line from command output. |
| `bgc_find_substr` | ~16 | Finds a substring in compiler-project text. |
| `bgc_replace_all` | ~19 | Replaces text in generated compiler-project sources. |
| `bgc_capture_text` | ~16 | Runs a compiler-project command and captures text. |
| `bgc_resolve_compiler_version` | ~28 | Resolves the current compiler version string. |
| `bgc_write_versioned_source` | ~18 | Writes generated versioned compiler source. |
| `build_graph_generate_compiler_entrypoints` | ~27 | Build graph target runner for compiler entrypoint generation. |
| `bgc_resolve_seed_compiler` | ~18 | Resolves the seed compiler path. |
| `bgc_compiler_path` | ~5 | Resolves the compiler path used by compiler-project targets. |
| `build_graph_run_with_compiler_build` | ~68 | Build graph target runner for building the compiler. |
| `build_graph_run_with_compiler_ir` | ~55 | Build graph target runner for emitting compiler IR. |

## Selfhost Fixture Dispatch In `src/main.w`

File: `src/main.w`

| Item | Lines | Description |
| --- | ---: | --- |
| `build_graph_run_tool_capture` | ~19 | Captures external tool output for build graph fixture execution. |
| `build_graph_run_embedded_runtime_extract_test` | ~60 | Runs embedded runtime extraction selfhost fixture target. |
| `build_graph_assert_contains` | ~6 | Selfhost fixture substring assertion. |
| `build_graph_assert_not_contains` | ~6 | Selfhost fixture negative substring assertion. |
| `build_graph_run_cli_capture` | ~18 | Captures compiler CLI output for selfhost fixtures. |
| `build_graph_run_cli_expect_success` | ~6 | Asserts compiler CLI success for selfhost fixtures. |
| `build_graph_run_cli_selfhost_help` | ~20 | Runs CLI help selfhost fixture target. |
| `build_graph_run_cli_selfhost_test_directives` | ~34 | Runs test directive selfhost fixture target. |
| `build_graph_run_cli_selfhost_smoke_test` | ~18 | Runs CLI selfhost smoke target. |
| `build_graph_run_cli_capture_input` | ~23 | Captures compiler CLI output with stdin input. |
| `build_graph_assert_stdout_exact` | ~7 | Exact stdout assertion for selfhost fixtures. |
| `build_graph_expect_cli_success_exact` | ~7 | Exact-output CLI success assertion. |
| `build_graph_expect_cli_input_success_exact` | ~7 | Exact-output CLI success assertion with stdin input. |
| `build_graph_run_cli_selfhost_one_liner_test` | ~151 | Runs one-liner CLI selfhost fixture target. |
| `build_graph_split_words` | ~20 | Splits shell-like output for object symbol fixtures. |
| `build_graph_strip_mach_o_underscore` | ~5 | Normalizes Mach-O symbol names for fixture checks. |
| `build_graph_nm_symbol_name` | ~6 | Extracts a symbol name from `nm` output. |
| `build_graph_nm_symbol_type` | ~6 | Extracts a symbol type from `nm` output. |
| `build_graph_nm_output` | ~17 | Runs `nm` for object symbol fixtures. |
| `build_graph_nm_has_symbol` | ~23 | Checks whether `nm` output contains a symbol. |
| `build_graph_nm_forbid_symbol` | ~3 | Checks whether `nm` output forbids a symbol. |
| `build_graph_expect_nm_symbol` | ~7 | Asserts an expected symbol exists. |
| `build_graph_expect_nm_forbid` | ~7 | Asserts a forbidden symbol is absent. |
| `build_graph_write_fixture` | ~10 | Writes fixture source files from `src/main.w` selfhost helpers. |
| `build_graph_build_emit_obj` | ~14 | Builds an object fixture for symbol tests. |
| `build_graph_check_object_symbols` | ~94 | Checks emitted object file symbols. |
| `build_graph_run_cli_selfhost_object_symbol_test` | ~18 | Runs object-symbol selfhost fixture target. |
| `build_graph_run_cli_selfhost_suite_test` | ~38 | Runs the selfhost fixture suite target. |
