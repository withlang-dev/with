# Project State

Status: active checkpoint for agents. Update this file when phase status,
blockers, or the next work queue changes.

Last updated: 2026-05-21.

Read this file immediately after `AGENTS.md`. It exists so long-running build
system and bootstrap work does not have to be reconstructed from git history or
conversation context after compaction.

## Current Focus

Phase C extraction work is complete. Pre-Phase-D preparation is complete
through P9, including the follow-up source-location diagnostic gap. Phase D D1,
D2, and D3 are complete. Phase D D4 is in progress.

Completed D1 sub-slices:

1. Shared capability registry used by Sema, plus a reserved capability value
   kind for evaluator dispatch.
2. Comptime function values and function-field calls, needed for evaluating
   `Build.action(..., action_fn)` targets without generated runner binaries.
3. Comptime struct field assignment, needed to preserve `Target.action` and
   other build-record mutations during direct `build.w` evaluation.
4. Evaluator-owned capability records, handle validation, and initial
   capability receiver dispatch for `BuildCtx.project_info()` and
   `ProjectInfo` accessors.
5. Evaluator handlers for `BuildCtx.new_build()` and BuildCtx child
   capabilities: diagnostics, source emitter, ToolFs, and ProcessRunner.
6. A typed `ComptimeValue(Build)` to `BuildGraph` materializer substrate,
   including a driver-only action function reference on `BuildGraphTarget`.
7. Build-time evaluator handlers for `Diagnostics.warn/error`,
   `SourceEmitter.generated_source`, and `ToolFs` filesystem operations used
   during direct `build(ctx)` evaluation.
8. The normal `build.w` graph-load path now compiles an evaluator wrapper,
   evaluates `build(ctx)` in-process, and materializes the typed returned
   `Build` value directly into `BuildGraph`.
9. Action targets now execute in-process through the evaluator with a minted
   `ActionCtx`; generated action runner source files and binaries are no
   longer part of the normal action path.

Completed D2 work:

1. Added typed build option structs to `std.build`: `BuildOptions`,
   `BuildGraphOptions`, `TestOptions`, and `MigrateOptions`.
2. Added driver-side structured build option parsing for `with build`.
3. Routed direct `with build` source builds and build graph execution through
   `BuildCommandOptions` instead of long positional option lists.
4. Added `Compilation.configure_options` as the typed compilation option
   boundary.
5. Added focused build-options API and CLI compatibility coverage.
6. Updated the Phase D design and language specification with canonical
   capability-bearing comptime syntax:
   `comptime with BuildCtx as ctx:`, with `comptime with BuildCtx:` as the
   standard default-binding shorthand.

Completed D3 work:

1. Parser support for `comptime with Capability as name:` and standard
   default-binding shorthand.
2. Build entry points written as `comptime with BuildCtx as ctx:` or
   `comptime with BuildCtx:` lower to the existing explicit `build(ctx)`
   entry shape used by the evaluator-backed driver.
3. Sema allows trusted `std.build` and `std.compiler` implementation-boundary
   functions to be called from capability-bearing comptime functions while
   preserving the normal restriction against arbitrary runtime calls.
4. Focused selfhost coverage proves canonical build entry points, shorthand
   default binding, and duplicate default-binding diagnostics.
5. Sequential `Workspace` capability skeleton, including
   `BuildCtx.create_workspace`, `BuildCtx.current_workspace`, source-file and
   source-string inputs, typed `BuildOptions`, `Workspace.compile`, and typed
   `BuildResult` / `Artifact` values.
6. Focused selfhost coverage proves workspace file compilation, workspace
   source-string compilation, BuildResult artifact construction, and the
   `current_workspace()` failure diagnostic before a workspace exists.
7. `ActionCtx` can mint workspaces for action-local compilation, and the fast
   emit-C smoke action now emits `test/hello.w` to C through
   `Workspace.compile()` instead of spawning `with build --emit-c`.
8. `Workspace` is an ephemeral capability handle, so storing it in ordinary
   long-lived structs is rejected by Sema. The compile-error suite covers this
   with `err_workspace_ephemeral_struct_field.w`.

Remaining D3 work: none.

D4 may start after this D3 checkpoint lands and passes the same
build/fixpoint/test baseline.

Completed D4 substrate work:

1. The comptime evaluator can represent payload enum values and match on
   payload enum patterns. This is required before `CompilerMessage` can use the
   tagged-union shape specified by `docs/phase-d-design.md` instead of a flat
   message struct. Focused build-w selfhost coverage exercises payload enum
   construction and payload binding during direct `build(ctx)` evaluation.
2. Enum type collection resolves payload types before writing enum layout rows
   into `type_extra`, so generic payload resolution cannot interleave unrelated
   type metadata into an in-progress enum layout. Behavior coverage protects an
   enum with a generic payload followed by a variant whose name matches its
   payload type.
3. `std.build` exposes the public D4 message data surface:
   `DeclSummary`, `CompilerPhase`, `LinkCommand`, `CompilerMessage`, and
   `CompilerMessageEnvelope`. The build-w selfhost payload-enum fixture now
   constructs and matches a public `CompilerMessage.Typechecked` value through
   the real `std.build` import path.
4. `Workspace.begin_intercept`, `wait_for_message`, and `end_intercept` have
   evaluator-backed lifecycle support for synchronous `Workspace.compile()`.
   Intercepted compilation now delivers phase markers through codegen,
   `CompilerMessage.Typechecked(Vec[DeclSummary])` from the real sema snapshot,
   produced artifacts, then the terminal phase marker and terminal payload.
   Cooperative suspension, link-phase coverage, and `set_link_command` remain
   the next D4 work.
5. Tool build/action evaluation now rejects unfinished workspace interceptions
   at the evaluator boundary. A build script that returns with an active
   intercept and no delivered terminal message fails loudly instead of
   materializing a graph.
6. Intercepted `Workspace.compile()` now queues the terminal phase marker and
   terminal payload as separate messages: `Phase(complete)` followed by
   `Complete(BuildResult)`.
7. `Workspace.end_intercept()` now rejects attempts to end an interception
   while terminal messages are still unread, so build scripts cannot hide an
   abandoned message queue by closing the intercept before returning.
8. The build-w selfhost workspace message fixture covers closed-queue
   semantics: after `Complete(BuildResult)` is consumed, the next
   `wait_for_message()` returns `CompilerMessage.Error(1, "Workspace message
   queue is closed", unknown_span)`.
9. Successful intercepted `Workspace.compile()` calls now queue one
   `CompilerMessage.Artifact(Artifact)` for each produced build artifact
   before the terminal `Phase(complete)` / `Complete(BuildResult)` pair.
10. Successful intercepted `Workspace.compile()` calls now queue
   `Phase(typechecked)` followed by `Typechecked(Vec[DeclSummary])` before
   artifact messages. The summaries are materialized directly from the
   compiler's typed declaration snapshot and include function/type names,
   module names, public flags, source spans, return type text, and parameter
   counts.
11. Successful intercepted `Workspace.compile()` calls now queue the
   non-link phase markers currently available on the synchronous path:
   `pre_parse`, `parsed`, `pre_typecheck`, `typechecked`,
   `lowered_to_mir`, `pre_codegen`, `codegen_done`, `pre_link`, and `linked`.
12. The primary link path now constructs an internal typed argv command
   (`LinkStageCommand`) and executes it through `with_exec_argv` instead of
   assembling shell command strings. This is the substrate for exposing
   `CompilerMessage.PreLink(LinkCommand)` and accepting validated
   `Workspace.set_link_command` replacements.
13. `Compilation` now retains the last link command and link rc for successful
   binary build attempts. The data is still internal, but it gives the
   evaluator a real command object to materialize into `PreLink`/`Linked`
   messages instead of re-planning or parsing textual command output.
14. Successful intercepted binary `Workspace.compile()` calls now queue
    `Phase(pre_link)`, `PreLink(LinkCommand)`, `Phase(linked)`, and
    `Linked(LinkCommand, rc)` before artifact and terminal messages. Link
    replacement through `Workspace.set_link_command` is still pending.
15. The link layer now has an internal planning boundary:
    `link_stage_link_object_to_binary_plan` constructs the typed command
    without executing it, and the existing result path executes the plan.
    This is the next substrate needed for validating and applying
    `Workspace.set_link_command` replacements before link execution.
16. `Compilation.finish_binary_from_pool` is now split into
    `prepare_binary_link_from_pool` and `execute_binary_link_plan`. Binary
    compilation can produce the object file and typed link command before
    executing the command, giving the workspace message loop a compiler-level
    pause point to expose as `PreLink`.
17. Binary link-plan execution is factored into
    `compilation_execute_binary_link_plan`, so the future workspace pre-link
    continuation can execute a validated replacement command through the same
    cleanup/profile/dSYM path as normal binary compilation.

D1 architectural boundary: the evaluator must return a typed std.build `Build`
value. The driver materializes that value directly into `BuildGraph`.
`Build.emit_graph()` remains a debug/export compatibility facility and must not
be the evaluator-to-driver transport.

Completed quality-of-life slices:

1. `855594b` Add persistent project state checkpoint.
2. `9186a59` Add build debugging helper scripts.
3. `f078129` Add action `--no-deps` build flag.
4. `5f81dca` Run external build tests in parallel batches.

## Verification Baseline

The original P9 pre-D1 baseline is recorded in
`docs/audits/pre-d1-baseline.md`. The current verified checkpoint is the commit
containing this project-state update:

```text
Support payload enum values in comptime evaluation
```

Commands passed:

```sh
make build
out/bin/with build :cli-selfhost-build-w-tests --no-deps
make fixpoint
make test
```

The previous verified checkpoint also passed:

```sh
make build
out/bin/with build :cli-selfhost-build-w-tests --no-deps
out/bin/with build :build
out/bin/with build :fixpoint
out/bin/with build :test
out/bin/with run test/behavior/behav_std_build_options_api.w
out/bin/with build test/hello.w -o /tmp/with-d2-hello
out/bin/with build test/hello.w --emit-c -o /tmp/with-d2-hello.c
out/bin/with build test/hello.w --emit-obj -o /tmp/with-d2-hello.o
out/bin/with build :cli-selfhost-edge-tests --no-deps
out/bin/with test test/behavior/behav_build_w_basic_invocation.w
out/bin/with test test/behavior/behav_action_capability_filesystem.w
out/bin/with test test/behavior/behav_action_capability_process.w
out/bin/with test test/behavior/behav_action_crash_diagnostic.w
out/bin/with test test/behavior/behav_action_no_deps_isolation.w
out/bin/with build :cli-selfhost-smoke-tests
out/bin/with build :c-migrator-core-tests
out/bin/with build :pcre2-reference
out/bin/with build :test
make fixpoint
make test
```

Full `:emit-c-test` remains a manual release/emit-C-feature verification
target. Do not run it for normal compiler, stdlib, or build-system slices; the
default `:test` target includes the fast emit-C smoke.

Recent Phase D/pre-D commits:

- current checkpoint: Support payload enum values in comptime evaluation.
- previous checkpoint: Make Workspace an ephemeral capability.
- previous checkpoint: Use workspaces for emit-C smoke compilation.
- previous checkpoint: Implement workspace compile capability skeleton.
- `5e5674a` Unify build CLI parsing with BuildOptions.
- `2cba39a` Execute build actions in-process.
- `f5cc0c5` Evaluate build.w graphs in-process.
- previous checkpoint: Implement source-location magic constants.
- `617aecd` Reconcile Phase D design with pre-D artifacts.
- `db64d01` Isolate generated action runner dispatch.
- `6d1b052` Add pre-D build action behavior regressions.
- `366b681` Design BuildOptions and CLI integration.
- `af5a756` Design capability dispatch for Phase D.
- `0ebdcd2` Survey build scripts before Phase D.
- `3e10eed` Audit parallel compiler state before Phase D.
- `1cbc348` Audit comptime evaluator before Phase D.

Recent Phase C and hardening commits:

- `c993471` Extract compiler generators to build actions.
- `8f47830` Extract compiler build targets to build actions.
- `7ead507` Preserve action runner output while capturing diagnostics.
- `d852d2c` Lower binding initializers before binding locals.
- `3242741` Add host existence checks to ToolFs.
- `765c0d0` Extract emit-C targets to build actions.
- `862a510` Preserve HashMap key types in emitted C.
- `9ec2148` Materialize copy let bindings in MIR.
- `d9116c2` Fix emit-C enum and scalar lowering.
- `5f81dca` Run external build tests in parallel batches.
- `f078129` Add action `--no-deps` build flag.
- `9186a59` Add build debugging helper scripts.
- `855594b` Add persistent project state checkpoint.
- `54ecd97` Consolidate emit-C call inference caches.
- `7c40e67` Add emit-C smoke to default tests.
- `c47ee60` Decode string escapes in emitted C.
- `237b498` Add PCRE2 test smoke to default tests.
- `d4be079` Add PCRE2 migrate smoke to default tests.
- `bd0b85f` Make ProcessEnv set fluent.
- `6719ad4` Run migrator selfhost smokes in default tests.
- `de87372` Make Vec.push composable in pipelines.
- `f21002e` Record value-ref ABI parameters in Sema.
- `eb01bed` Add selfhost regressions for emit-C receivers and switch scope
  migration.

## Build Plan Status

The authoritative plan remains `docs/build-plan.md`; the final architecture is
specified in `docs/build-spec.md`. Phase D implementation is governed by
`docs/phase-d-design.md`; pre-D preparation is governed by
`docs/pre-phase-d-plan.md`.

Completed at a high level:

- Build actions and capability plumbing exist.
- Scoped `ToolFs` writes and declared extra outputs exist.
- Default `with build :test` no longer runs the full PCRE2 upstream corpus.
- Fast smoke coverage exists for PCRE2 migration, PCRE2 tests, and emit-C.
- Action targets support `--no-deps` for focused iteration.
- External-compiler build graph test targets run in parallel batches.
- Several repository-specific build targets have moved to project-local action
  modules.

Still incomplete:

- Phase C is complete. Project-specific build behavior no longer uses live
  compiler-dispatched project graph kinds.
- Phase D D1 is complete. `build.w` graph loading uses the evaluator-backed
  typed materializer path, and action targets execute through evaluator-backed
  `ActionCtx` dispatch instead of generated runner binaries.
- Phase D D2 is complete. `with build` parsing now produces typed build
  options, build graph target execution overlays those options per target, and
  `std.build` exposes the option structs required by future workspaces.
- Action timeout/cwd/env/network/install policy declarations are incomplete.
- Jai-style workspace/build-options/message-loop APIs are incomplete.
- Make remains a compatibility layer.
- Some repository scripts remain because workflows or tests still reference
  them.
- Cross-platform plumbing exists, but current-host paths are the routinely
  exercised ones.

## Phase C Extraction Status

Completed Phase C-style extractions include:

- `issue61-regression`
- `compat-runtime-source`
- `cli-selfhost-smoke-tests`
- `cli-selfhost-one-liner-tests`
- `cli-selfhost-object-symbol-tests`
- `cli-selfhost-project-tests`
- `cli-selfhost-edge-tests`
- `cli-selfhost-parallel-tests`
- `c-migrator-pcre2-prep-tests`
- `pcre2-reference`
- `pcre2-build` / `pcre2-test`
- `pcre2-check-generated` / `pcre2-promote`
- `seed-download`
- `emit-c-test` / `emit-c-fixpoint` / `emit-c-roundtrip`
- `compiler-sources`
- `bootstrap-llvm-link-metadata` / `llvm-link-metadata`
- compiler build / compiler IR targets

No Phase C extraction areas remain. All old 1000-series repository-specific
graph kinds are reserved as removed-kind diagnostics.

Before adding new repository build policy, re-check `src/BuildGraphKinds.w`,
`src/main.w`, `docs/completed/phase-c-inventory.md`, and the current git log.
New repository-specific behavior should go into project-local build modules,
not a new compiler-dispatched project graph kind.

## Open Blockers And Follow-Ups

- Continue Phase D with D3 next. Do not start D4-D8 until D3 is committed and
  passes the build/fixpoint/test baseline.
- Preserve the pre-D behavior tests during D1:
  `behav_build_w_basic_invocation`, `behav_action_capability_filesystem`,
  `behav_action_capability_process`, `behav_capability_token_mismatch`,
  `behav_action_crash_diagnostic`, and `behav_action_no_deps_isolation`.
- Decide whether in-process build graph test targets should also move to
  external parallel execution, or remain serial for diagnostic fidelity.
- Keep manual-only heavy targets covered by fast smokes in `make test`.
- Run full `:emit-c-test` only for release verification or emit-C-specific
  work. For ordinary changes, rely on `make test`'s emit-C smoke.
- Keep project-specific build policy in project-local modules and avoid adding
  new compiler-dispatched project graph kinds.
- Continue replacing shell/filesystem work in build internals with typed
  capabilities.

## Local State

At the time of this update, Phase D D2 BuildOptions/CLI unification was
verified and ready to commit. The current D2 verification passed:

```sh
make build
out/bin/with build :build
out/bin/with build :fixpoint
out/bin/with build :test
out/bin/with run test/behavior/behav_std_build_options_api.w
out/bin/with build test/hello.w -o /tmp/with-d2-hello
out/bin/with build test/hello.w --emit-c -o /tmp/with-d2-hello.c
out/bin/with build test/hello.w --emit-obj -o /tmp/with-d2-hello.o
out/bin/with build :cli-selfhost-edge-tests --no-deps
out/bin/with test test/behavior/behav_build_w_basic_invocation.w
out/bin/with test test/behavior/behav_action_capability_filesystem.w
out/bin/with test test/behavior/behav_action_capability_process.w
out/bin/with test test/behavior/behav_action_crash_diagnostic.w
out/bin/with test test/behavior/behav_action_no_deps_isolation.w
out/bin/with build :cli-selfhost-smoke-tests
out/bin/with build :c-migrator-core-tests
out/bin/with build :pcre2-reference
out/bin/with build :test
make fixpoint
make test
```

The full emit-C test was intentionally not part of this verification pass per
the manual-only policy above.

Always run `git status -sb` before editing; this file is a checkpoint, not a
substitute for inspecting the current worktree.

## Environment Notes

- Stale `/tmp/openjai_test_*` directories and `out/bin/with.tmp.*` artifacts can
  consume large amounts of disk after interrupted runs.
- If link errors mention missing regex runtime exports, inspect
  `out/lib/regex_runtime.o`; a disk-full interruption once left it truncated and
  required regenerating the object.
- `make doctor` is mentioned in `AGENTS.md` but is not currently implemented.
