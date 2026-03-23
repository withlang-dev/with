# Wave 11 Coverage Matrix

Stage0 driver/link/c_import script mapping for Wave 11 corpus entries.

| Stage0 Script | Coverage State | Wave 11 Evidence | Notes |
| --- | --- | --- | --- |
| `run_phase0_driver_commands_tests.sh` | `COVERED` | `cli|help`, `cli|version`, `cli|unknown_command`, `cli|build_missing_arg`, `cli|run_missing_arg`, `cli|test_unknown_flag`, `test|test/wave11/cases/c_import_bad_header_fail.w` | Command dispatch and CLI error boundaries covered. |
| `run_phase0_object_link_tests.sh` | `COVERED` | `build/run|test/wave11/cases/c_import_link_ok.w`, `build|test/wave11/cases/c_import_link_missing_fail.w`, `build/run|test/wave9/cases/runtime_linkage_sync_ok.w`, `build/run|test/wave9/cases/runtime_linkage_async_ok.w` | Object/link success, runtime object selection, and missing-link failure covered. |
| `run_phase0_import_path_regression_tests.sh` | `COVERED` | `check|test/wave11/cases/imports/relative_root.w`, `check|test/wave11/cases/imports/qualified_root.w`, `check|test/wave11/cases/imports/missing_root.w` | Relative, package-qualified, and missing import resolution covered. |
| `run_phase0_c_import_tests.sh` | `COVERED` | `run|test/wave11/cases/c_import_stdio_ok.w`, `check|test/wave11/cases/c_import_bad_header_fail.w` | Basic c_import runtime + malformed header behavior covered. |
| `run_phase0_c_import_link_tests.sh` | `COVERED` | `run|test/wave11/cases/c_import_link_ok.w`, `build|test/wave11/cases/c_import_link_missing_fail.w` | Link-lib propagation and missing-link failure covered. |
| `run_phase0_c_import_cache_tests.sh` | `COVERED` | `check|test/wave11/cases/c_import_cache_same.w`, `check|test/wave11/cases/c_import_cache_diff_links.w` | Cache-key behavior covered in check-mode corpus. |
| `run_phase0_c_import_milestone_tests.sh` | `COVERED` | `run|test/wave11/cases/c_import_stdio_ok.w`, `build|test/wave11/cases/c_import_bad_header_fail.w` | Milestone c_import positive + negative path coverage. |
| `run_phase6_c_import_cache_invalidation_tests.sh` | `COVERED` | `check|test/wave11/cases/c_import_cache_diff_links.w`, `check|test/wave11/cases/c_import_cache_epoch_override.w` | Cache invalidation and epoch-sensitive behavior covered. |
| `run_phase6_c_import_macro_diagnostics_tests.sh` | `COVERED` | `check|test/wave11/cases/c_import_macro_constants_ok.w`, `check|test/wave11/cases/c_import_macro_function_like_ok.w`, `check|test/wave11/cases/c_import_bad_header_fail.w` | Macro import diagnostics coverage is present. |
