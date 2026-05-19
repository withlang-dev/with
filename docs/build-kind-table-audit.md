# Build Graph Kind Table Audit

Status: current as of `0a38d52`.

This audit covers `src/BuildGraphKinds.w` after the Phase C selfhost smoke,
one-liner, object-symbol, project, edge, PCRE2-prep, migrate-basic, and
migrate-core, and build-w extractions. The old selfhost suite dispatcher is
also removed. The embedded-runtime regression, all PCRE2 project targets, seed
download, and the selfhost suites extracted so far are now action targets.

## Standard Kinds

Live standard kinds:

| Kind | Name |
| --- | --- |
| 0 | `executable` |
| 1 | `library` |
| 2 | `test` |
| 3 | `object` |
| 4 | `archive` |
| 7 | `command` |
| 8 | `install` |
| 9 | `group` |
| 10 | `binary_compare` |
| 11 | `fixpoint_compare` |
| 12 | `compile_c_object` |
| 13 | `compile_asm_object` |
| 14 | `compile_llvm_ir_object` |
| 15 | `create_static_archive` |
| 16 | `generate_response_file` |
| 17 | `embed_object_files` |
| 18 | `copy_tree` |
| 19 | `run_corpus_test` |
| 20 | `promote_tree_if_verified` |
| 21 | `clean` |
| 22 | `copy_file` |
| 23 | `action` |

Removed standard kinds:

| Kind | Name |
| --- | --- |
| 5 | `removed_generated_source` |
| 6 | `removed_generated_binary` |

`build_graph_kind_is_standard` accepts exactly the live standard set:
`0..4` and `7..23`. `build_graph_kind_removed` reserves `5` and `6`.

## Project Kinds

Live project kinds:

| Kind | Name |
| --- | --- |
| 1003 | `generate_compiler_entrypoints` |
| 1004 | `with_compiler_build` |
| 1013 | `with_compiler_ir` |
| 1020 | `generate_llvm_link_metadata` |
| 1025 | `emit_c_test` |
| 1026 | `emit_c_fixpoint` |
| 1027 | `emit_c_roundtrip` |

Removed project kinds:

| Kind | Name |
| --- | --- |
| 1000 | `removed_embedded_runtime_extract_test` |
| 1001 | `removed_selfhost_noop_local_regression` |
| 1002 | `removed_cli_selfhost_smoke_test` |
| 1005 | `removed_pcre2_run_test` |
| 1006 | `removed_pcre2_generated_check` |
| 1007 | `removed_pcre2_generated_promote` |
| 1008 | `removed_pcre2_build` |
| 1009 | `removed_cli_selfhost_one_liner_test` |
| 1010 | `removed_cli_selfhost_object_symbol_test` |
| 1011 | `removed_cli_selfhost_build_w_test` |
| 1012 | `removed_generate_compat_runtime` |
| 1014 | `removed_cli_selfhost_project_test` |
| 1015 | `removed_cli_selfhost_edge_test` |
| 1016 | `removed_cli_selfhost_pcre2_prep_test` |
| 1017 | `removed_cli_selfhost_migrate_basic_test` |
| 1018 | `removed_cli_selfhost_migrate_core_test` |
| 1019 | `removed_selfhost_suite_test` |
| 1021 | `removed_pcre2_reference_prepare` |
| 1022 | `removed_pcre2_migrate` |
| 1023 | `removed_unused_1023` |
| 1024 | `removed_seed_download` |

`build_graph_kind_is_project` accepts every live project kind and excludes
every removed project kind. `build_graph_kind_removed` reserves every removed
project kind.

Kind `1023` was never a live serialized target. It was skipped when project
kinds were named in `3fd6f81`; it is now explicitly reserved as
`removed_unused_1023` so the gap is intentional and diagnosable.

No source corrections were required by this audit.
