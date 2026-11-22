# Phase C Inventory

Status: complete as of `8f47830`.

This document records the final state of the Phase C inventory: project-specific
build graph code for this repository no longer lives under `src/`.

Scope:

- Included: PCRE2-related, emit-C-related, seed-related,
  compiler-build-related, and selfhost-fixture-related build functions, types,
  and `BuildKind` values.
- Excluded: general compiler implementation code such as C migration internals,
  C codegen internals, parser, sema, MIR, and standard build graph primitives.

## Result

No live project-specific build graph kind remains.

`src/BuildGraphKinds.with` keeps the old 1000-series project kind numbers only as
removed-kind diagnostics for stale serialized build graphs. `build_graph_kind_is_project`
returns `false` for all values.

## Removed Project Kinds

| Kind | Removed name |
| ---: | --- |
| 1000 | `removed_embedded_runtime_extract_test` |
| 1001 | `removed_selfhost_noop_local_regression` |
| 1002 | `removed_cli_selfhost_smoke_test` |
| 1003 | `removed_generate_compiler_entrypoints` |
| 1004 | `removed_with_compiler_build` |
| 1005 | `removed_pcre2_run_test` |
| 1006 | `removed_pcre2_generated_check` |
| 1007 | `removed_pcre2_generated_promote` |
| 1008 | `removed_pcre2_build` |
| 1009 | `removed_cli_selfhost_one_liner_test` |
| 1010 | `removed_cli_selfhost_object_symbol_test` |
| 1011 | `removed_cli_selfhost_build_w_test` |
| 1012 | `removed_generate_compat_runtime` |
| 1013 | `removed_with_compiler_ir` |
| 1014 | `removed_cli_selfhost_project_test` |
| 1015 | `removed_cli_selfhost_edge_test` |
| 1016 | `removed_cli_selfhost_pcre2_prep_test` |
| 1017 | `removed_cli_selfhost_migrate_basic_test` |
| 1018 | `removed_cli_selfhost_migrate_core_test` |
| 1019 | `removed_selfhost_suite_test` |
| 1020 | `removed_generate_llvm_link_metadata` |
| 1021 | `removed_pcre2_reference_prepare` |
| 1022 | `removed_pcre2_migrate` |
| 1023 | `removed_unused_1023` |
| 1024 | `removed_seed_download` |
| 1025 | `removed_emit_c_test` |
| 1026 | `removed_emit_c_fixpoint` |
| 1027 | `removed_emit_c_roundtrip` |

Kind `1023` was never a live serialized target. It was skipped when project
kinds were named in `3fd6f81`; it remains reserved so the gap is intentional
and diagnosable.

## Generic Build Graph Code Remaining Under `src/`

| File | Purpose |
| --- | --- |
| `src/BuildGraphDispatch.with` | Standard graph planning and dependency traversal. |
| `src/BuildGraphKinds.with` | Stable standard kind names and removed-kind diagnostics. |
| `src/BuildGraphModel.with` | Generic build graph data model and parser. |
| `src/BuildGraphOps.with` | Generic standard target operations. |
| `src/BuildGraphRuntime.with` | Runtime bridge for generic build graph operations. |
| `src/BuildGraphSupport.with` | Generic path, argv, and validation helpers. |
| `src/BuildGraphTests.with` | Generic graph parser/serializer tests. |
| `src/BuildGraphTools.with` | Generic external tool execution helpers. |
| `src/main.with` | CLI driver, standard graph execution, and project-local action invocation. |

The remaining `src/main.with` build-driver responsibilities are generic:

- graph loading from `build.with`;
- standard target execution;
- project-local action runner generation;
- capability minting;
- stale-kind diagnostics.

It no longer dispatches PCRE2, emit-C, seed, compiler-build, or selfhost
fixture behavior by project kind.

## Project-Local Build Modules

Repository-specific build policy now lives outside `src/`:

| Module | Owns |
| --- | --- |
| `build.with` | Repository target graph declaration. |
| `build_compiler.with` | Compiler source generation, LLVM link metadata, compiler build, and compiler IR actions. |
| `build_emit_c.with` | Emit-C test, fixpoint, and roundtrip actions. |
| `build_pcre2.with` | PCRE2 reference, migrate, build, test, check, and promote actions. |
| `build_runtime.with` | Runtime compatibility source generation actions. |
| `build_seed.with` | Seed download/update actions. |
| `build_selfhost.with` | Repository selfhost fixture actions. |

## Verification

The final Phase C extraction was verified with:

```sh
make build
out/bin/with build :cli-selfhost-build-w-tests --no-deps
make fixpoint
make test
```
