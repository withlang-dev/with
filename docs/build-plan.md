# Build System Completion Plan

Status: implementation plan.

This plan describes the remaining work needed to make
[build-spec.md](build-spec.md) describe reality. The end state is a With-native
build system with no authoritative Makefile, no required repository shell
scripts, and no project-specific build dispatch hardcoded into the generic
compiler driver.

---

## 1. Current State

Already implemented:

- `build.w` discovery and tool-mode execution.
- Driver-minted `BuildCtx` and narrower tool capabilities.
- Sandboxed project-relative `ToolFs`.
- Graph v2 serialization/parsing.
- Target selection by `with build :target`.
- Dependency-closure selection using explicit deps and producer edges.
- `--graph` and `--dry-run` graph printing.
- Project-local `Action` targets.
- Scoped action filesystem writes for declared outputs.
- Default `with test` dispatch through `with build :test`.
- Standard graph nodes for:
  - `Executable`
  - `Library`
  - `Test`
  - `Object`
  - `Archive`
  - `Group`
  - `Command`
  - `BinaryCompare`
  - `FixpointCompare`
  - `CompileCObject`
  - `CompileAsmObject`
  - `CompileLlvmIrObject`
  - `CreateStaticArchive`
  - `GenerateResponseFile`
  - `EmbedObjectFiles`
  - `CopyTree`
  - `CopyFile`
  - `RunCorpusTest`
  - `PromoteTreeIfVerified`
  - `Install`
  - `Clean`
- Repository graph targets for:
  - stage chain and fixpoint
  - runtime object generation
  - canonical compiler build
  - default test suite
  - install/install-user
  - seed download
  - PCRE2 reference/migrate/build/test/promote
  - several emit-C targets
- Make compatibility targets delegate many paths to `with build :...`.
- Default `with build :test` no longer runs the full PCRE2 upstream corpus.

Still not acceptable as final state:

- Project-specific build behavior still leaks into compiler source modules.
- Action target process/install policy declarations are still incomplete.
- Full Jai-style workspace/build-options/message-loop APIs are incomplete.
- Make remains as a compatibility layer.
- Some repository scripts still exist because old workflows or tests reference
  them.
- Some compiler/build paths still assemble shell command strings internally.
- Cross-platform target plumbing exists, but only current-host paths are
  routinely exercised.

---

## 2. Rule for the Rest of the Work

Every remaining item is completed one slice at a time:

1. Implement one logical capability or target group.
2. Run focused verification for that slice.
3. Run `make build`.
4. Run `make fixpoint`.
5. Run relevant `with build :...` parity checks.
6. Run `make test` when code behavior changed.
7. Commit and push.

Do not replace Make until every target it protects has a proven `with build`
path.

---

## 3. Phase A: Finish the Standard Target Vocabulary

Goal: every target kind exported by `std.build` is either fully executable or
removed from the standard vocabulary.

Status: complete. Commit: `Complete Phase A build target vocabulary` (the
final Git hash is reported after commit because a commit cannot embed its own
hash).

Tasks:

1. Audit every `BuildKind` in `lib/std/build.w`. Done.
2. For each kind, record:
   - validation rules;
   - graph parser support;
   - executor support;
   - docs;
   - tests. Done.
3. Fully implement or remove:
   - `Object`: implemented as With source to object file;
   - `Archive`: implemented as With source to static archive;
   - `GeneratedSource`: removed as a target kind; generated sources are graph
     entries;
   - `GeneratedBinary`: removed until a binary-content graph entry exists.
4. Add the missing standard target:
   - `CopyFile`: implemented as a file-copy target with optional octal mode.
5. Ensure standard nodes have:
   - duplicate-output detection;
   - declared input validation;
   - clear failure diagnostics;
   - deterministic output.

Verification:

```sh
with build :cli-selfhost-build-w-tests
with build --graph
make build
make fixpoint
make test
```

Commit after this phase.

---

## 4. Phase B: Project-Local Tool Actions

Goal: project-specific build behavior no longer requires compiler source
changes.

Status: core action invocation complete. Commit:
`Add project-local build action targets` (the final Git hash is reported after
commit). Action capability hardening continues in Phase B.1.

Design and implement a project-local action mechanism:

```with
pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.action("name", action_fn)
    out

fn action_fn(ctx: ActionCtx) -> i32:
    ...
```

Implemented `ActionCtx` exposure:

- target name;
- declared inputs;
- declared outputs;
- diagnostics;
- sandboxed filesystem;
- process runner;
- project info.

Implemented action targets declare:

- inputs;
- outputs;
- deps;
- target platform.

Implemented tests:

- action succeeds and writes declared output;
- action failure fails graph target;
- missing input is diagnosed;
- action receives only declared capabilities;
- action can be used as a dependency of a standard target.

Verification:

```sh
with build :cli-selfhost-build-w-tests
make build
make fixpoint
make test
```

Commit after this phase.

---

## 5. Phase B.1: Harden Action Capabilities

Goal: action targets receive only the filesystem/process/install privileges
they explicitly declare.

Status: scoped action filesystem writes are implemented and verified. The
`Declare extra action outputs` slice added graph-level extra outputs so actions
can declare every file or directory they are allowed to create. Remaining action
process/install policy declarations stay tracked below.

Completed action hardening:

- scoped `ToolFs` writes for declared outputs;
- extra declared action outputs;
- undeclared output rejection;
- action path escape diagnostics;

Remaining action hardening:

- action timeout support;
- action cwd/env support;
- network-access declaration;
- install-path access declaration.

Related stdlib/language blockers tracked for later design:

- `Vec.push` currently returns `void`, so `Vec.new() |> push("a") |> push("b")`
  cannot be a fluent builder chain until the Vec mutation API is redesigned.
- Type context does not yet propagate through pipelines into `Vec.new()`, so
  `Vec.new() |> push("a")` cannot infer the element type from the later method.

Implemented tests:

- undeclared action output is rejected;
- extra declared action output is writable and verified;
- `..` and absolute write paths are rejected;
- declared output directories may be created;

Required remaining tests:

- timeout terminates the action and reports the target name;
- cwd/env are available only when declared;
- install-path writes require explicit install capability.

Verification:

```sh
with build :cli-selfhost-build-w-tests
make build
make fixpoint
make test
```

Commit after this phase.

---

## 6. Phase C: Move Project-Specific Build Logic Out of Generic Driver

Goal: `src/main.w` and generic build graph executor code no longer know about
PCRE2, emit-C roundtrip policy, seed policy, or With-repository selfhost
fixtures.

Move these into repository-local build modules backed by standard nodes or
project-local actions:

- PCRE2 reference preparation.
- PCRE2 migration.
- PCRE2 build.
- PCRE2 corpus test.
- PCRE2 promotion.
- emit-C test.
- emit-C fixpoint.
- emit-C roundtrip.
- seed download/update policy.
- compiler stage policy that is not a generic graph operation.
- selfhost fixture suites.

Status: in progress. Completed slices:

- Moved `issue61-regression` from a compiler-hardcoded project kind to a
  `build.w` Action target and removed the old compiler dispatch path for that
  target.
- Moved `compat-runtime-source` generation from a compiler-hardcoded project
  kind to the repository-local `build_runtime.w` module. The target is now an
  `Action` with declared primary and extra outputs, and project kind 1012 is
  reserved as removed legacy graph data.
- Moved `cli-selfhost-smoke-tests` from hardcoded `cli_selfhost_smoke_test`
  dispatch to the repository-local `build_selfhost.w` module. The target is now
  an `Action`, and project kind 1002 is reserved as removed legacy graph data.
- Moved `cli-selfhost-one-liner-tests` from hardcoded
  `cli_selfhost_one_liner_test` dispatch to the repository-local
  `build_selfhost.w` module. The target is now an `Action`, and project kind
  1009 is reserved as removed legacy graph data.
- Moved `cli-selfhost-object-symbol-tests` from hardcoded
  `cli_selfhost_object_symbol_test` dispatch to the repository-local
  `build_selfhost.w` module. The target is now an `Action`, and project kind
  1010 is reserved as removed legacy graph data.
- Moved `cli-selfhost-project-tests` from hardcoded
  `cli_selfhost_project_test` dispatch to the repository-local
  `build_selfhost.w` module. The target is now an `Action`, and project kind
  1014 is reserved as removed legacy graph data.
- Moved `cli-selfhost-edge-tests` from hardcoded
  `cli_selfhost_edge_test` dispatch to the repository-local
  `build_selfhost.w` module. The target is now an `Action`, and project kind
  1015 is reserved as removed legacy graph data.

Generic compiler-driver code may retain only:

- graph parsing and validation;
- standard target execution;
- project-local action invocation;
- capability minting;
- workspace/compiler APIs.

Verification:

```sh
with build :pcre2-reference
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
with build :test
make build
make fixpoint
make test
```

Commit after this phase.

---

## 7. Phase D: Complete Tool-Mode Compiler Driver APIs

Goal: With has the Jai-style compiler-driver surface required by the spec.

Implement:

1. `Workspace` capability.
2. `BuildOptions` typed API.
3. Source injection:
   - add source file;
   - add source string;
   - add generated source.
4. Workspace compilation:
   - executable;
   - static library;
   - dynamic library;
   - object;
   - C source emission.
5. Compiler message loop:
   - begin intercept;
   - wait for message;
   - end intercept.
6. Build result model:
   - diagnostics;
   - artifacts;
   - workspace name;
   - timing;
   - exit code.

Tests:

- build file creates two independent workspaces;
- generated source in one workspace does not leak into another;
- build options affect only the intended workspace;
- message loop sees phases in order;
- typechecked introspection can generate source;
- hook execution does not recursively invoke hook runners.

Verification:

```sh
with build :cli-selfhost-build-w-tests
with build :test
make build
make fixpoint
make test
```

Commit after this phase.

---

## 8. Phase E: Remove Shell Command Strings From Build Internals

Goal: compiler, migrator, runtime, stdlib, and build-system code do filesystem
and process work through typed APIs, not shell strings.

Audit and replace shell-string use in:

- `src/main.w`
- `src/compiler/*`
- `src/BuildGraph*`
- migrator code
- stdlib build/process/fs modules
- runtime-facing build helpers

Allowed shell use:

- Makefile while it still exists;
- test fixtures whose purpose is shell-facing CLI behavior;
- comments or docs.

Required replacements:

- remove file/tree;
- mkdir;
- copy;
- chmod;
- command execution;
- stdout/stderr redirection;
- pipelines such as `nm | awk`.

Verification:

```sh
rg -n "with_system|\\|>|<| rm |mkdir -p|\\| awk|\\| grep" src lib rt build.w
with build :test
make build
make fixpoint
make test
```

Every remaining hit must be either a false positive, a test fixture, or an
explicitly documented exception.

Commit after this phase.

---

## 9. Phase F: Harden Path, Install, and Promotion Semantics

Goal: every path-writing capability and target has explicit sandbox or install
permissions.

Tasks:

1. Apply project-root validation to:
   - generated source;
   - response files;
   - copy targets;
   - command capture paths;
   - corpus outputs;
   - clean targets.
2. Add explicit install capability for:
   - install;
   - install-user;
   - seed/update-seed;
   - promotion into source-controlled trees.
3. Add stale-verification checks for `PromoteTreeIfVerified`.
4. Add path diagnostics that name the target, field, and rejected path.

Tests:

- absolute path rejection without install capability;
- `..` rejection;
- generated-source escape rejection;
- copy/install/promote escape rejection;
- clean cannot remove outside declared roots;
- install-user requires the verified dependency chain.

Verification:

```sh
with build :cli-selfhost-build-w-tests
with build :install-user --dry-run
with build :pcre2-promote --dry-run
make build
make fixpoint
make test
```

Commit after this phase.

---

## 10. Phase G: Complete Repository Target Parity

Goal: every live Make target has an equivalent direct `with build` target.

Required direct targets:

```sh
with build
with build :stage1
with build :stage2
with build :stage3
with build :runtime
with build :build
with build :selfcheck
with build :fixpoint
with build :test
with build :install
with build :install-user
with build :seed
with build :update-seed
with build :clean
with build :pcre2-reference
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
```

For each target:

1. Run the old Make target if still available.
2. Run the `with build :...` target.
3. Compare output artifacts byte-for-byte where applicable.
4. Explain any intentional difference.
5. Make Make delegate to the `with build` target.

Batch order:

1. Infrastructure:
   - clean;
   - seed;
   - update-seed.
2. Compiler builds:
   - stage1;
   - stage2;
   - stage3;
   - runtime;
   - build.
3. Verification:
   - selfcheck;
   - smoke;
   - fixpoint;
   - test.
4. Install:
   - install;
   - install-user.
5. PCRE2:
   - pcre2-reference;
   - pcre2-migrate;
   - pcre2-build;
   - pcre2-test;
   - pcre2-promote.
6. emit-C:
   - emit-c-test;
   - emit-c-fixpoint;
   - emit-c-roundtrip.

Commit after each batch.

---

## 11. Phase H: Delete Make and Obsolete Scripts

Goal: remove compatibility infrastructure after direct `with build` paths are
authoritative.

Deletion sequence:

1. Replace Make target bodies with one-line delegations to `with build :...`.
2. Verify every delegated target.
3. Delete shell scripts no longer referenced by:
   - `build.w`;
   - tests;
   - docs;
   - release automation.
4. Turn the Makefile into a temporary one-line diagnostic shim that says to use
   `with build`.
5. Update CI/docs to use `with build` directly.
6. Delete the Makefile.

Before deleting the Makefile, these must pass without invoking Make:

```sh
with build :build
with build :fixpoint
with build :test
with build :pcre2-test
with build :emit-c-roundtrip
```

Commit the deletion separately.

---

## 12. Phase I: Documentation Finalization

Goal: remove all transitional wording from user-facing build docs.

Update:

- `docs/with-build.md`
- `docs/build-spec.md`
- `docs/toolchain.md`
- bootstrap instructions;
- release instructions;
- AI-facing repository docs.

Remove or archive implementation-plan docs that are no longer active.

Final docs must not describe:

- Make as a required path;
- shell scripts as required build tools;
- standard targets as reserved/unimplemented;
- project-specific build logic in compiler source;
- current-host limitations as design constraints.

Commit after this phase.

---

## 13. Final Acceptance

The build system is complete when:

```sh
with build :build
with build :fixpoint
with build :test
with build :pcre2-reference
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
with build :install-user
```

all pass without Make or required repository shell scripts, and:

- the produced compiler passes fixpoint;
- the full default test suite passes;
- migrated-library corpora are explicit per-library targets;
- project-specific build behavior lives in project-local build modules;
- every `std.build` target kind is implemented or removed;
- no compiler/build-system internal path relies on shell command strings;
- generated/promoted code is verified before promotion;
- the Makefile is gone.
