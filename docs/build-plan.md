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
  - CLI selfhost project/init coverage now runs as a typed
    `cli_selfhost_project_test` graph node, covering `with init` in the
    current directory, `with init <dir>`, default package-name build output,
    and rejection of imperative `[build]` manifest configuration for both
    implicit and explicit-source builds.
  - CLI selfhost edge coverage now runs as a typed `cli_selfhost_edge_test`
    graph node, covering pointer-index diagnostics, prelude stdout/stderr
    output contracts, whole-program extern var redeclaration, and imported
    module dependency ordering.
  - CLI selfhost regex/PCRE2 preparation coverage now runs as a typed
    `cli_selfhost_pcre2_prep_test` graph node, covering EBCDIC table pruning,
    raw-to-generated preservation of shared extern/let ownership, width-suffix
    local preservation, std.re shared dependency imports, opaque field
    diagnostics, concrete PCRE2 heapframe structs, clean pcre2_compile builds,
    and JIT no-support fallback behavior.
  - The compiler runtime process API now supports argv execution with supplied
    stdin plus captured stdout/stderr, so graph tests no longer need shell
    pipelines to exercise stdin-driven compiler behavior.
  - Build graph target/platform metadata now lives in a dedicated
    `BuildGraphKinds` module instead of `src/main.w`.
  - Reusable selfhost fixture/process/assertion helpers now live in
    `BuildGraphSelfhostHarness`, reducing the fixture warehouse pressure in
    `BuildGraphSelfhost.w`.
  - The selfhost harness now has PCRE2-backed regex assertions, and migrated
    brace-format checks use structural regex patterns instead of hand-written
    line scanning.
  - Repository selfhost suites now use a generic `selfhost_suite_test` graph
    kind keyed by suite name, so new selfhost batches no longer require a new
    BuildKind and top-level dispatch branch.
  - Host tool lookup now lives in a typed `BuildGraphTools` module with named
    resolvers for cc, ar, nm, LLVM clang, opt, curl, tar, and dsymutil.
  - Build graph data structures, v1/v2 parsing, serialization, and dependency
    closure selection now live in `BuildGraphModel` instead of `src/main.w`.
  - Build graph path normalization, output path helpers, argv blob assembly,
    and process-argument validation now live in `BuildGraphSupport` instead of
    `src/main.w`.
  - Sorted `.w` file discovery now lives in `BuildGraphSupport`, giving
    selfhost tests and PCRE2 graph operations a shared fixture/file listing
    primitive instead of keeping the finder inside `src/main.w`.
  - Generic executable graph operations now live in `BuildGraphOps`, including
    binary/fixpoint comparisons, response files, C/asm/LLVM object compilation,
    static archives, embedded object assembly, manifest copy, corpus/command
    execution, file copy, and install nodes.
  - PCRE2-specific graph operations now live in `BuildGraphPcre2`, keeping the
    generated-source checks, promotion, pcre2test build, and upstream corpus run
    out of `src/main.w` while using the centralized `BuildGraphRuntime`
    boundary for process, environment, and filesystem effects.
  - Native `Test` graph execution now lives in `BuildGraphTests`, so test-file
    glob expansion, `compiler=` selection, and per-file process capture are no
    longer embedded in `src/main.w`.
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
  - `with build :runtime` now refreshes the compiler runtime object set
    through typed graph nodes:
      - `generate_compat_runtime` generates `out/gen/embedded_stdlib_runtime.w`
        and `out/gen/compat_runtime.w` without the old generator binary.
      - `with_compiler_build` compiles With runtime objects with stage2.
      - `with_compiler_ir` preserves the existing `regex_runtime.w` IR-to-object
        path so imported PCRE2 modules are included correctly.
      - `embed_object_files` and `compile_asm_object` generate and compile
        `out/lib/embedded_objects.{s,o}` without the shell embedding script.
  - `with build :build` now produces the canonical `out/bin/with` through the
    graph path by depending on refreshed runtime objects and embedded objects.
  - `with build :pcre2-test` now runs the upstream PCRE2 `RunTest -8 0-29
    heap` corpus through a typed `pcre2_run_test` graph node instead of the
    repository wrapper script `scripts/verify_pcre2_works.sh`.
  - `with build :pcre2-build` now consumes existing `out/pcre2_migrated`
    sources, checks generated modules, and builds `out/pcre2_build/bin/pcre2test`
    through a typed `pcre2_build` graph node. It does not trigger migration.
  - `with build :pcre2-check-generated` now checks generated PCRE2 modules
    through a typed `pcre2_generated_check` node instead of
    `scripts/pcre2_generated_workflow.sh`.
  - `with build :pcre2-promote` now refuses promotion unless generated PCRE2
    modules type-check cleanly, then copies the verified tree through a typed
    `pcre2_generated_promote` node.
  - PCRE2 migration is now treated as a manual refresh step in the legacy
    Make path too: `pcre2-test` no longer depends on `pcre2-build`, and
    `pcre2-build` no longer depends on `pcre2-migrate`.
  - `make pcre2-test` is now a compatibility shim over
    `with build :pcre2-test` after checking that existing migrated PCRE2
    sources, built `pcre2test`, and the reference tree are present.
  - `make pcre2-build` is now a compatibility shim over
    `with build :pcre2-build`.
  - `make pcre2-promote` is now a compatibility shim over
    `with build :pcre2-promote`.
  - `make test` is now a compatibility shim over `with build :test`; Make no
    longer invokes `scripts/run_tests.sh`, the issue61 regression script, or
    the embedded-runtime regression script directly.
  - `with build :test` now runs the first migrator fixture batch through a
    typed `cli_selfhost_migrate_basic_test` node:
      - global initializer lists
      - host header compatibility
      - assignment sequencing compatibility
      - rvalue sequencing
      - directory progress stdout
      - cross-file global owner arrays
      - shared defs pruning of unused ownerless externs
  - `with build :test` now runs the core migrator fixture batch through a
    typed `cli_selfhost_migrate_core_test` node:
      - libc ctype calls preserve C return-value semantics
      - macro initializer lists and typed unsigned minus constants
      - tentative global owner selection across one or more source files
      - no-op pointer cast cleanup
      - raw pointer indexing diagnostics and unsafe indexing output
      - brace-preferred migration output formatting
      - typed casts inside macro-expanded expressions
  - `with build :test` now checks the generated-PCRE2 existing-`main`
    workflow through the typed `pcre2_generated_check` node instead of
    `scripts/pcre2_generated_workflow.sh`.
  - Initial repository `build.w`:
      - `with build`
      - `with build :selfcheck`
      - `with build :fixpoint`
      - `with build :test`
      - `with build :install-user`
      - `with build :update-seed`
      - `with build :c-migrator-tests`
      - `with build :pcre2-build`
      - `with build :pcre2-test`
      - `with build :pcre2-check-generated`
      - `with build :pcre2-promote`
  - Default `with build :test` no longer runs PCRE2/migrator-prep suites.
    C migrator correctness checks are grouped under the explicit
    `with build :c-migrator-tests` target, while migrated-library operations
    use the per-library command family (`pcre2-migrate`, `pcre2-build`,
    `pcre2-test`, `pcre2-promote`) so normal tests do not validate a rare
    library refresh path by accident.
  - Default `with build :test` still exercises With regex syntax and the
    standard-library regex shim through the normal behavior/compile-error
    suites, including literal parsing, flags, `=~`/`!~`, match-arm captures,
    f-string capture interpolation, global `/g` progression, invalid literals,
    invalid flags, and capture-scope diagnostics.
  - CLI selfhost parallel same-source coverage now runs as a typed
    `selfhost_suite_test` graph target named `cli-selfhost-parallel-tests`.
    It verifies one serial `with test` run and 32 concurrent same-source runs
    without invoking the legacy shell test script.
  - `with build :llvm-link-metadata` now compiles `rt/llvm_bridge.w` and
    `rt/clang_bridge.w` through graph nodes and regenerates
    `out/lib/llvm_link.rsp`, `out/lib/llvm_cc`, and
    `out/lib/.llvm-link-ready` through a typed metadata node. `stage1` now
    depends on this graph node, so direct graph builds no longer rely on stale
    Make-generated LLVM bridge metadata.

  Remaining:

  - Port clean-bootstrap runtime/link preparation into the graph path. Direct
    `with build :build` works after a normal repository build, but Make still
    owns bootstrap-time runtime/link metadata setup from a cold checkout.
  - Port PCRE2 download/migrate/source-preparation into typed nodes;
    `pcre2-build`, `pcre2-test`, generated-source checking, and promotion are
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
      - with build :pcre2-build
      - with build :pcre2-test
      - with build :pcre2-promote --dry-run
      - with build :emit-c-test
      - with build :install-user --dry-run
  - Final acceptance:
      - with build :compiler
      - with build :fixpoint
      - with build :test
      - with build :pcre2-migrate
      - with build :pcre2-build
      - with build :pcre2-test
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
