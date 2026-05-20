# Project State

Status: active checkpoint for agents. Update this file when phase status,
blockers, or the next work queue changes.

Last updated: 2026-05-19.

Read this file immediately after `AGENTS.md`. It exists so long-running build
system and bootstrap work does not have to be reconstructed from git history or
conversation context after compaction.

## Current Focus

Phase C extraction work is complete. The next major build-system direction is
to continue with post-extraction hardening: action policy declarations,
compiler-as-library/tool-mode APIs, shell-string removal, and Make retirement.

Completed quality-of-life slices:

1. `855594b` Add persistent project state checkpoint.
2. `9186a59` Add build debugging helper scripts.
3. `f078129` Add action `--no-deps` build flag.
4. `5f81dca` Run external build tests in parallel batches.

## Verification Baseline

The latest completed code slices before this checkpoint passed:

```sh
make build
make fixpoint
make test
make install-user
```

Recent relevant commits:

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
specified in `docs/build-spec.md`.

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
`src/main.w`, `docs/phase-c-inventory.md`, and the current git log. New
repository-specific behavior should go into project-local build modules, not a
new compiler-dispatched project graph kind.

## Open Blockers And Follow-Ups

- Decide whether in-process build graph test targets should also move to
  external parallel execution, or remain serial for diagnostic fidelity.
- Keep manual-only heavy targets covered by fast smokes in `make test`.
- Keep project-specific build policy in project-local modules and avoid adding
  new compiler-dispatched project graph kinds.
- Continue replacing shell/filesystem work in build internals with typed
  capabilities.

## Local State

At the time of this update, the source changes for Phase C completion were
committed locally after passing:

```sh
make build
out/bin/with build :cli-selfhost-build-w-tests --no-deps
make fixpoint
make test
```

Always run `git status -sb` before editing; this file is a checkpoint, not a
substitute for inspecting the current worktree.

## Environment Notes

- Stale `/tmp/openjai_test_*` directories and `out/bin/with.tmp.*` artifacts can
  consume large amounts of disk after interrupted runs.
- If link errors mention missing regex runtime exports, inspect
  `out/lib/regex_runtime.o`; a disk-full interruption once left it truncated and
  required regenerating the object.
- `make doctor` is mentioned in `AGENTS.md` but is not currently implemented.
