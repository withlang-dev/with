# Project State

Status: active checkpoint for agents. Update this file when phase status,
blockers, or the next work queue changes.

Last updated: 2026-05-19.

Read this file immediately after `AGENTS.md`. It exists so long-running build
system and bootstrap work does not have to be reconstructed from git history or
conversation context after compaction.

## Current Focus

Quality-of-life hardening before returning to Phase C extraction work:

1. Persistent project-state doc.
2. Helper scripts for common command/debug patterns.
3. `--no-deps` support for action iteration.
4. Parallel execution for the default test target.

## Verification Baseline

The latest completed code slices before this checkpoint passed:

```sh
make build
make fixpoint
make test
make install-user
```

Recent relevant commits:

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
- Several repository-specific build targets have moved to project-local action
  modules.

Still incomplete:

- Phase C is not finished. Project-specific build behavior still leaks into
  compiler source modules.
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

Remaining Phase C areas include:

- remaining selfhost fixture suites;
- remaining PCRE2 action paths if any compiler-dispatched pieces remain;
- emit-C test/fixpoint/roundtrip extraction;
- compiler stage policy that is still project-specific;
- final `selfhost_suite_test` dispatcher removal after it has no children.

Before starting another extraction, re-check `src/BuildGraphKinds.w`,
`src/main.w`, `docs/phase-c-inventory.md`, and the current git log. Do not rely
solely on this checkpoint for exact line ownership.

## Open Blockers And Follow-Ups

- Implement `--no-deps` for action iteration without weakening dependency
  validation in normal builds.
- Add parallel execution for the default test path while preserving
  deterministic diagnostics and fixpoint safety.
- Keep manual-only heavy targets covered by fast smokes in `make test`.
- Continue removing project-specific build dispatch from generic compiler
  source one target group at a time.
- Continue replacing shell/filesystem work in build internals with typed
  capabilities.

## Local State

At the time of this update, the repository was clean:

```sh
git status -sb
# ## main...origin/main
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
