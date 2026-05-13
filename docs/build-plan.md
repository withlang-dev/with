# Implement docs/build-spec.md

  ## Summary

  Implement the integrated With build system as a graph-first tool-mode build driver. build.w will declare typed build nodes; the
  compiler driver will execute them without Make or repository shell scripts. Current-host execution is required first, but platform/
  target data stays explicit and non-host paths fail loudly.

  Make remains only as a temporary compatibility shim during migration. The final state is that the compiler repository can build, test,
  migrate PCRE2, promote regex sources, install the user compiler, and clean using with build :... targets directly.

  ## Current Progress

  Completed:

  - Graph v2 parsing/serialization with target outputs, inputs, deps, args, and default target selection.
  - Dependency-closure target selection, including explicit `dep(...)` edges and producer edges inferred from inputs/entries.
  - Implemented executable graph nodes for:
      - executable/library/test targets;
      - group targets;
      - binary_compare / fixpoint_compare;
      - compile_c_object / compile_asm_object / compile_llvm_ir_object;
      - create_static_archive;
      - generate_response_file;
      - embed_object_files;
      - copy_runtime_tree;
      - run_corpus_test;
      - promote_tree_if_verified;
      - command (argv-only, no shell command strings);
      - install.
  - Runtime argv process execution with stdout/stderr capture and timeout.
  - Runtime chmod support for install nodes.
  - Native test directory discovery now avoids shell command strings for
    directory checks and sorted file collection.
  - Native `with test` now handles the suite directives used by the script runner:
    `expect-check-fail`, `expect-error`, `expect-build-fail`,
    `expect-check-stdout`, `check-only`, `skip`, and `args`.
  - Native `Test` graph targets are exposed for behavior, compile-error,
    codegen, spec, and phase directories. Test graph nodes can select an
    explicit compiler with `compiler=<path>`, so the behavior suite now runs
    through `out/bin/with-stage2` without `scripts/run_tests.sh`.
  - The embedded runtime extraction regression now runs as a typed
    `embedded_runtime_extract_test` graph node instead of
    `scripts/run_embedded_runtime_extract_regression.sh`.
  - The issue61 noop-local selfhost regression now runs as a typed
    `selfhost_noop_local_regression` graph node instead of
    `scripts/run_issue61_noop_local_regression.sh`.
  - CLI selfhost top-level help and `with test` runtime-directive checks now
    run as a typed `cli_selfhost_smoke_test` graph node.
  - CLI one-liner coverage now runs as a typed
    `cli_selfhost_one_liner_test` graph node, including `-e`, repeated `-e`,
    semicolon splitting, argument forwarding, `-n`, `-p`, regex captures,
    named captures, f-string capture interpolation, implicit-main stdin
    programs, and diagnostic source-location checks.
  - CLI selfhost object-symbol coverage now runs as a typed
    `cli_selfhost_object_symbol_test` graph node, covering emitted globals,
    imported module symbol ownership, imported-vs-extern redeclarations, and
    PCRE2 C ABI symbol preservation without shell `nm | awk` pipelines.
  - CLI selfhost package/build.w coverage now runs as a typed
    `cli_selfhost_build_w_test` graph node, covering project `build.w`
    execution, test/library targets, explicit host and rejected non-host
    targets, generated source validation, graph v2 serialization, target
    selection, dependency closure, response files, archives, embedded objects,
    copy/promote nodes, command nodes, install nodes, and corpus nodes.
  - The compiler runtime process API now supports argv execution with supplied
    stdin plus captured stdout/stderr, so graph tests no longer need shell
    pipelines to exercise stdin-driven compiler behavior.
  - `with build :stage1`, `:stage2`, `:stage3`, and `:fixpoint` now build
    through typed graph nodes instead of comparing stale stage artifacts:
      - `generate_compiler_entrypoints` emits the version-substituted
        `out/gen/*.w` entry files and `out/gen/version.txt`.
      - `with_compiler_build` invokes the selected compiler through argv,
        writes stage binaries or fixpoint objects, and reports captured
        stdout/stderr on failure.
      - `fixpoint_compare` depends on regenerated stage2/stage3 fixpoint
        objects and prints `FIXPOINT` on success.
  - `with test` with no explicit source path now dispatches to the project
    graph target `with build :test`.
  - `with build :regex-test` now runs the upstream PCRE2 `RunTest -8 0-29
    heap` corpus through a typed `pcre2_run_test` graph node instead of the
    repository wrapper script `scripts/verify_pcre2_works.sh`.
  - `with build :regex-build` now consumes existing `out/pcre2_migrated`
    sources, checks generated modules, and builds `out/pcre2_build/bin/pcre2test`
    through a typed `pcre2_build` graph node. It does not trigger migration.
  - `with build :regex-check-generated` now checks generated PCRE2 modules
    through a typed `pcre2_generated_check` node instead of
    `scripts/pcre2_generated_workflow.sh`.
  - `with build :regex-promote` now refuses promotion unless generated PCRE2
    modules type-check cleanly, then copies the verified tree through a typed
    `pcre2_generated_promote` node.
  - PCRE2 migration is now treated as a manual refresh step in the legacy
    Make path too: `regex-test` no longer depends on `regex-build`, and
    `regex-build` no longer depends on `regex-migrate`.
  - `make regex-test` is now a compatibility shim over
    `with build :regex-test` after checking that existing migrated PCRE2
    sources, built `pcre2test`, and the reference tree are present.
  - `make regex-build` is now a compatibility shim over
    `with build :regex-build`.
  - `make regex-promote` is now a compatibility shim over
    `with build :regex-promote`.
  - `make test` is now a compatibility shim over `with build :test`; Make no
    longer invokes `scripts/run_tests.sh`, the issue61 regression script, or
    the embedded-runtime regression script directly.
  - Initial repository `build.w`:
      - `with build`
      - `with build :selfcheck`
      - `with build :fixpoint`
      - `with build :test`
      - `with build :install-user`
      - `with build :update-seed`
      - `with build :regex-test`
      - `with build :regex-check-generated`
      - `with build :regex-promote`

  Remaining:

  - Replace the remaining temporary `with build :test` script invocation with
    native typed With test harness nodes for the rest of the CLI selfhost
    categories: migration fixtures, regex preparation checks, and parallel
    same-source testing.
  - Port runtime object generation into `build.w`.
  - Port embedded runtime object generation out of shell.
  - Port the canonical `out/bin/with` compiler build into `build.w`; stage1,
    stage2, stage3, and fixpoint object generation now have direct graph
    targets, but canonical runtime refresh/embedding still lives in Make.
  - Port PCRE2 download/migrate/source-preparation into typed nodes;
    `regex-build`, `regex-test`, generated-source checking, and promotion are
    typed. Migration must remain manually triggered; normal test/build targets
    should consume existing migrated output and fail loudly if it is missing.
  - Port seed, clean, emit-c, and cross targets.
  - Make Makefile delegate to `with build :...` only after direct graph paths are equivalent.
  - Remove Make recipes and obsolete scripts last.

  ## Key Changes

  - Extend std.build from the current simple target list into graph v2:
      - Add typed nodes for executable, test, library/archive, object, generated source/binary, group, clean, install, download/extract,
        process, corpus test, promote, and all current Make parity operations.
      - Every node records stable name, inputs, outputs, deps, target, options, and source location where available.
      - Emit WITH_BUILD_GRAPH\t2; keep v1 parser only long enough for existing tests, then update tests to v2.
  - Add build-driver execution infrastructure:
      - Move ad hoc graph parsing/execution out of src/main.w into a dedicated build-driver module.
      - Support with build, with build :target, with test, with clean, and with install-user.
      - Add --graph, --dry-run, --explain, --verbose, --target, --debug, --release, and --out.
      - Enforce duplicate-output detection, dependency order, current-host target validation, repo locking, and loud unsupported-node
        diagnostics.
  - Add typed tool-mode capabilities instead of shell recipes:
      - Filesystem: read/write text and binary, mkdir, remove tree, copy file/tree, rename, symlink, chmod, glob, normalize/join paths.
      - Process: argv-based execution with cwd/env, stdout/stderr capture, exit code, timeout, and process-tree cleanup. No shell
        command strings.
      - Host tools: typed adapters for cc, assembler, LLVM IR compilation, ar, dsymutil, git, curl, and tar where still required;
        missing tools fail with explicit diagnostics.
      - Replace build-path uses of with_system("...") with these typed APIs.
  - Implement current Make parity nodes:
      - binary_compare / fixpoint_compare
      - compile_c_object
      - compile_asm_object
      - compile_llvm_ir_object
      - create_static_archive
      - generate_response_file
      - embed_object_files
      - copy_runtime_tree
      - run_corpus_test
      - promote_tree_if_verified
  - Add repository build.w targets:
      - build, stage1, stage2, stage3, runtime, fixpoint, test, regex_migrate, regex_build, regex_test, regex_promote, install_user,
        update_seed, seed, clean, emit_c_test, emit_c_fixpoint, and cross.
      - Preserve bootstrap order: seed → stage1 → stage2 → stage3; compare stage2/stage3 fixpoint objects before install/update-seed.
      - Generate versioned compiler entry files under out/gen.
      - Build embedded stdlib, runtime objects, LLVM/Clang bridge objects, embedded object payloads, canonical compiler, and runtime
        tree through graph nodes.
  - Port each live script into typed build functionality:
      - embed_runtime_objects.sh becomes embed_object_files.
      - pcre2_generated_workflow.sh becomes generated-PCRE2 dependency check/promote nodes.
      - prepare_pcre2_reference.sh becomes a PCRE2 source preparation node.
      - verify_pcre2_works.sh becomes run_corpus_test for upstream RunTest -8 0-29 heap.
      - run_tests.sh, selfhost_runner.sh, CLI selfhost tests, and regression scripts become With test-suite nodes with directive
        parsing, temp-project support, timeouts, and output assertions.
      - generate_wl_stubs.sh becomes a typed emit-C support node.
  - Migration sequence:
      - First add APIs and graph executor while Make still works.
      - Then add repository build.w targets and compare them against Make outputs.
      - Then make Make call with build :... as a shim.
      - Finally remove Make recipes and shell scripts once direct with build paths pass.

  ## Test Plan

  - Focused tests:
      - Graph v2 serialization/parsing, unknown node, duplicate output, dependency order, empty glob, invalid path escape, unsupported
        target.
      - Named build entrypoints: with build :target, missing target, wrong signature.
      - Process API: argv handling, cwd/env, stdout/stderr capture, nonzero exit, timeout.
      - Filesystem API: binary read/write, copy tree, remove tree, symlink, chmod, glob ordering.
      - Make parity nodes: object compilation, assembly compilation, LLVM IR compilation, archive determinism, response file
        determinism, binary compare failure offsets, embedded object symbol output.
      - Install/promote guardrails: refused stale verification, reported changed paths, no partial silent success.
  - Repository parity tests:
      - with build :stage1
      - with build :stage2
      - with build :stage3
      - with build :fixpoint
      - with build :runtime
      - with build :regex-build
      - with build :regex-test
      - with build :regex-promote --dry-run
      - with build :emit-c-test
      - with build :install-user --dry-run
  - Final acceptance:
      - with build :compiler
      - with build :fixpoint
      - with build :test
      - with build :regex-migrate
      - with build :regex-build
      - with build :regex-test
      - with build :install-user
      - No Makefile or repository shell script is required for those commands.
      - make build, if still present during shim phase, delegates to with build :compiler.

  ## Assumptions

  - Build execution is graph-first: build.w declares typed nodes; the driver performs effects after graph construction.
  - The current exercised host is macOS, but public APIs must not encode a Mac preference.
  - Typed process adapters may invoke host tools such as cc, LLVM tools, git, curl, tar, and dsymutil; they must not invoke shell
    command strings.
  - Make is replaced last to protect bootstrap safety.
  - docs/build-spec.md should be cleaned up during implementation to remove the remaining “macOS-first” wording in favor of “current-host.”
