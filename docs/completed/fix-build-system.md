# Fixing the With Build System

Status: completed planning archive. This plan was superseded by
`docs/build-plan.md`, `docs/build-spec.md`, and the completed Phase C/Phase D
work.

The goal is to make With's build system feel like Jai's integrated build
process: the project describes its build in With source, the compiler runs that
build program in a privileged tool context, and ordinary projects do not need
Makefiles, shell scripts, Python, or generated project files.

This document is the plan for moving from the current transitional state to a
With-native replacement for Make and the repository shell scripts. Completing
the phases below gives the With compiler repository Make parity. It does not,
by itself, give With full Jai-style compiler-as-library build parity; that
requires the additional tool-mode/compiler-driver layer described in
section 9.

---

## 1. Desired End State

A project build is defined by:

```text
with.toml  declarative package metadata
build.w    executable build behavior
```

`with.toml` contains identity, dependencies, default target metadata, feature
flags, toolchain defaults, and publishing information.

`build.w` contains imperative build behavior: target graph construction,
generated source, test harnesses, tool discovery, promotion/install operations,
compiler stage graphs, migration flows, and custom validation.

The normal user commands are:

```text
with build
with build :target
with test
```

The With compiler repository should eventually use:

```text
with build
with build :stage1
with build :stage2
with build :stage3
with build :runtime
with build :fixpoint
with build :test
with build :install-user
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
```

Make remains only as a temporary bootstrap shim until the With-native graph is
complete and verified.

---

## 2. Design Principles

### 2.1 The Standard Library Owns Capabilities, Not Project Policy

`lib/std/build.w` must contain build primitives that ordinary With projects can
reuse. It must not contain target kinds or helper APIs specific to the With
compiler repository, PCRE2, emit-C roundtrips, self-hosting fixtures, or seed
compiler release policy.

Project-specific graph construction belongs in the repository's `build.w` or in
project-local modules loaded by `build.w`.

### 2.2 Typed Nodes Replace Shell Recipes

Make has a small core: targets, dependencies, and shell recipes. Its common
targets such as `all`, `clean`, `install`, and `test` are conventions, not
types.

With should keep the useful part, the graph, but replace shell recipe strings
with typed target nodes. A `CompileCObject` node knows it compiles C to an
object file. A `BinaryCompare` node knows it compares two files byte-for-byte.
A `Clean` node knows it removes declared artifact paths safely.

The build graph should not assemble shell command strings except in test
harnesses whose explicit purpose is testing shell-facing CLI behavior.

### 2.3 Jai-Style Metaprogram, With-Style API

Jai exposes compiler workspaces, build options, source addition, message
interception, output kinds, and build-time command-line arguments to build
programs.

With should expose equivalent capabilities in With terms:

- build files run in tool mode;
- build code creates or configures workspaces through typed APIs;
- build options are structured values;
- targets are added to a graph;
- the driver executes the graph and reports diagnostics;
- project-specific metaprogramming remains in project code.

### 2.4 Fail Loudly

Unsupported build nodes, missing tools, unsafe paths, invalid target
definitions, and failed generated-code steps must produce diagnostics and exit
nonzero. They must not silently downgrade, skip, or generate placeholder
output.

---

## 3. Standard Target Vocabulary

These targets should be standard and exported by `std.build`.

### 3.1 Core Product Targets

- `Executable`
- `Library`
- `Object`
- `Archive`
- `GeneratedSource`
- `GeneratedBinary`

`Library` may later split into `StaticLibrary` and `DynamicLibrary` if the API
needs to expose the distinction at construction time. For now, output kind can
remain an option on the target.

### 3.2 Graph Composition Targets

- `Group`
- `Command`

`Group` is the typed equivalent of a Make phony aggregate target.

`Command` is the escape hatch for external tools, but it must use argv, cwd,
environment, capture files, timeout, and declared inputs/outputs. It must not
be a raw shell string.

### 3.3 Verification Targets

- `Test`
- `BinaryCompare`
- `FixpointCompare`
- `RunCorpusTest`

`FixpointCompare` is semantically a byte comparison, but it deserves a standard
name because self-hosting compilers and code generators need this pattern often
enough that the diagnostic should say "fixpoint" instead of generic "binary
compare."

`RunCorpusTest` is standard as a typed harness primitive: run a declared test
program or compiler mode across a corpus with structured capture and failure
reporting. The specific With compiler corpus lives in this repository's
`build.w`.

### 3.4 Toolchain Targets

- `CompileCObject`
- `CompileAsmObject`
- `CompileLlvmIrObject`
- `CreateStaticArchive`
- `GenerateResponseFile`
- `EmbedObjectFiles`

These are the typed equivalents of common low-level Make recipes. They are
needed by this compiler, but they are not compiler-specific. Any With project
that links C, assembly, LLVM IR, or embedded binary assets needs these
primitives.

### 3.5 Filesystem and Promotion Targets

- `Install`
- `Clean`
- `CopyFile`
- `CopyTree`
- `PromoteTreeIfVerified`

`Clean` is standard. The standard operation is "remove these declared build
artifact paths safely." The actual paths are project-specific and belong in
`build.w`.

`CopyRuntimeTree` should not be a standard name. The standard target should be
`CopyTree`; copying the runtime tree is just one project-specific use.

`PromoteTreeIfVerified` is standard because "copy generated output into a
source or distribution location only after verification targets pass" is a
general build-system operation. The PCRE2 promotion target is one instance of
it, not the definition of it.

### 3.6 Optional Future Targets

- `DownloadFile`
- `ExtractArchive`
- `PatchTree`
- `GenerateBindings`

These are useful, but they should not block Make replacement. In the near term,
project-specific targets such as seed download and PCRE2 reference preparation
can remain local to this repository.

---

## 4. Non-Standard Project Targets

These must not be part of `std.build`:

- `EmbeddedRuntimeExtractTest`
- `SelfhostNoopLocalRegression`
- `GenerateCompilerEntrypoints`
- `GenerateCompatRuntime`
- `GenerateLlvmLinkMetadata`
- `WithCompilerBuild`
- `WithCompilerIr`
- `SelfhostSuiteTest`
- `Pcre2ReferencePrepare`
- `Pcre2Migrate`
- `Pcre2Build`
- `Pcre2RunTest`
- `Pcre2GeneratedCheck`
- `Pcre2GeneratedPromote`
- `SeedDownload`
- `EmitCTest`
- `EmitCFixpoint`
- `EmitCRoundtrip`

Some of these should eventually disappear because they can be expressed with
standard nodes. Others are genuinely project-specific and should live in
project-local build modules.

---

## 5. Target Kind Representation

The current integer `BuildKind` enum is too global. It makes
project-specific targets look like standard build-system concepts.

### Near-Term Rule

Keep standard kinds in `std.build`.

Keep project kinds in `build.w` or project-local build modules, using local
helpers only as a transitional bridge.

### Final Rule

Target kinds should be namespaced:

```with
type BuildKind {
    namespace: str,
    name: str,
}
```

Examples:

```text
std:executable
std:clean
std:binary_compare
with:generate_compiler_entrypoints
with:pcre2_migrate
with:emit_c_roundtrip
```

If string-backed target kinds are too large a change for the first slice, use a
numeric reservation:

```text
0..999       std.build target kinds
1000..1999   With compiler repository target kinds
2000..       package-local extension target kinds
```

The string namespace is the better final design because it avoids global enum
coordination across packages.

---

## 6. Build Driver Shape

The build driver should have three layers.

### 6.1 Standard Executor

Executes `std.build` nodes:

- compile With source;
- compile C/asm/LLVM IR objects;
- archive;
- install;
- clean;
- compare files;
- run tests;
- generate response files;
- embed object files;
- copy/promote trees;
- execute typed external commands.

This layer belongs in the compiler/tool driver, not in this repository's
`build.w`.

### 6.2 Extension Registry

Allows a project build file to register custom target handlers by namespace and
name.

Conceptually:

```with
ctx.register_target("with", "pcre2_migrate", run_pcre2_migrate)
ctx.register_target("with", "emit_c_roundtrip", run_emit_c_roundtrip)
```

The exact representation can be adjusted to current language limitations, but
the ownership boundary must remain clear: project extensions are not standard
library target kinds.

### 6.3 Project Graph

The repository's `build.w` constructs the With compiler graph:

- seed acquisition;
- stage1/stage2/stage3;
- runtime objects;
- fixpoint;
- behavior/spec/codegen/phase tests;
- CLI selfhost tests;
- C migrator tests;
- PCRE2 migrate/build/test/promote commands;
- emit-C test/fixpoint/roundtrip commands;
- install/update-seed commands;
- clean paths.

---

## 7. Make Parity Checklist

The With-native build must cover every useful Make target before Make can be
deprecated.

### 7.1 Core Build

- `all`
- `build`
- `stage1`
- `stage2`
- `stage3`
- `runtime`
- `selfcheck`
- `smoke`
- `fixpoint`

### 7.2 Tests

- `test`
- `test-pcre2`

`test` must not run full migrated-library corpora. It should run language,
stdlib, compiler, CLI, and shim tests.

Full migrated-library corpora belong to library-specific commands such as
`pcre2-test`, and later `sqlite-test`, `jq-test`, `minicoro-test`, and
`termbox2-test`.

### 7.3 Migrated Library Workflows

For each migrated library, expose four targets:

```text
<lib>-migrate
<lib>-build
<lib>-test
<lib>-promote
```

PCRE2 is the first instance:

```text
pcre2-migrate
pcre2-build
pcre2-test
pcre2-promote
```

Compatibility aliases may remain temporarily:

```text
regex-migrate -> pcre2-migrate
regex-build   -> pcre2-build
regex-test    -> pcre2-test
regex-promote -> pcre2-promote
```

But the generic concept is "migrated library," not "regex migration."

### 7.4 Emit-C and Bootstrap Verification

- `emit-c-test`
- `emit-c-fixpoint`
- `emit-c-roundtrip`
- future full compiler C roundtrip:
  1. build compiler normally;
  2. emit compiler to C;
  3. build emitted C compiler;
  4. migrate emitted C back to With;
  5. build migrated compiler;
  6. run tests under emitted and migrated compilers;
  7. use migrated compiler to compile the compiler;
  8. compare output byte-for-byte with the normal compiler.

### 7.5 Install and Seed

- `install`
- `install-user`
- `update-seed`
- `seed`

`SeedDownload` is project-specific until `DownloadFile` and release-asset APIs
are mature enough to be standard.

### 7.6 Maintenance

- `clean`
- `print-version`
- `cross`

`clean` is a standard operation with project-specific paths.

`cross` is a project-specific target until cross-compilation is a first-class
standard build capability.

---

## 8. Implementation Phases

### Phase 1: Repair the Public API Boundary

1. Restore `Clean` to `lib/std/build.w` as a standard target.
2. Add a `Build.clean(name)` or `Build.clean(name, paths)` helper.
3. Rename standard `CopyRuntimeTree` to `CopyTree`.
4. Keep compatibility parsing for `copy_runtime_tree` until existing graph
   tests are updated.
5. Confirm `lib/std/build.w` contains only standard build concepts.
6. Move remaining With-repository names out of public std APIs.

Verification:

```text
out/bin/with check lib/std/build.w
out/bin/with check build.w
out/bin/with run test/behavior/behav_std_build_api.w
with build --graph --dry-run
```

### Source Audit Before Phase 2

Before implementation continues beyond Phase 1, audit `src/` for build-system
boundary violations. Current findings:

- `src/main.w` contains project-specific build graph dispatch for target kinds
  21-48. This includes selfhost fixture tests, compiler-entrypoint generation,
  With compiler stage invocation, PCRE2 build/test/promote/migrate handlers,
  seed download, clean, emit-C tests, and emit-C roundtrip.
- `src/BuildGraphPcre2.w` contains PCRE2-specific migrated-library workflow
  handlers. This is project-specific and should not be part of the generic
  compiler build driver.
- `src/BuildGraphEmitC.w` contains emit-C roundtrip workflow handlers and is
  currently untracked in the worktree. This is project-specific verification
  logic and should be moved out of generic compiler dispatch before it becomes
  part of the permanent compiler surface.
- `src/BuildGraphSelfhost.w` and `src/BuildGraphSelfhostHarness.w` contain a
  large fixture warehouse for repository selfhost tests. These tests are
  valuable, but the fixture data should eventually live as normal test/build
  fixture files or project-local test modules, not as bulky compiler-linked
  source.
- `src/BuildGraphKinds.w` still names every project-specific kind as if it were
  a stable global build-system kind. This is the same boundary bug as
  project-specific constructors in `std.build`, just one layer lower.
- `src/BuildGraphOps.w`, `src/BuildGraphRuntime.w`, `src/BuildGraphSupport.w`,
  `src/BuildGraphTools.w`, and `src/BuildGraphModel.w` are mostly generic
  build-driver infrastructure. They should remain compiler/tooling code, but
  their public vocabulary must be limited to standard targets and extension
  dispatch.

Do not fix these audit items opportunistically. Use them to drive Phases 2 and
3.

### Phase 2: Introduce Namespaced or Reserved Custom Target Kinds

Do this before rewriting dispatch. Otherwise the dispatch split will be built
against the representation we already know is wrong, then rewritten again.

1. Define the final target-kind representation, preferably:

   ```with
   type BuildKind {
       namespace: str,
       name: str,
   }
   ```

2. If that is too large for the immediate bootstrap slice, reserve numeric
   ranges explicitly:

   ```text
   0..999       std.build target kinds
   1000..1999   With compiler repository target kinds
   2000..       package-local extension target kinds
   ```

3. Update graph serialization and parsing.
4. Keep old integer decoding temporarily for bootstrapping.
5. Move project kinds out of the standard range.
6. Add tests proving a package-local target cannot collide with a standard
   target.

Verification:

```text
out/bin/with test test/behavior/behav_std_build_api.w
with build --graph --dry-run
with build :test
```

### Phase 3: Split Project-Specific Execution Out of `src/main.w`

1. Create a build-driver module for standard graph dispatch.
2. Move standard target execution out of ad hoc `main.w` branches.
3. Move With-compiler project handlers into a project-specific module.
4. Replace giant target-kind condition chains with named predicates or a
   dispatch table.
5. Keep diagnostics exact: unknown target kind, unsupported target kind, and
   failed target execution must be distinct failures.
6. Use the representation from Phase 2 so this split does not need to be
   rewritten.

Verification:

```text
with build --graph --dry-run
with build :smoke
with build :fixpoint
```

### Phase 4: Replace Make Target Parity in Checkpointed Groups

For each Make target:

1. Identify the target's exact inputs, outputs, dependencies, environment, and
   diagnostics.
2. Model it as standard nodes when possible.
3. Use project-specific nodes only when the action is actually unique to this
   repository.
4. Add a dry-run graph assertion.
5. Run the With-native target and compare output/state with the Make target.
6. Commit before moving to the next checkpoint group.

Do not convert this as a 23-item trickle. Convert in checkpointed groups. After
each group, stop, run parity checks between `make X` and `with build :X` for
every target in the group, confirm byte-equal outputs where applicable, then
commit.

#### Group A: Infrastructure

- `clean`
- `print-version`
- `seed`
- `update-seed`

Stop here. Run parity checks between `make X` and `with build :X` for every
target in the group. Confirm downloaded/copied artifacts match expected paths
and permissions. Commit before moving on.

#### Group B: Compiler Builds

- `stage1`
- `stage2`
- `stage3`
- `runtime`
- `build`

Stop here. Run parity checks between `make X` and `with build :X` for every
target in the group. Confirm stage and runtime object outputs are byte-equal
where Make currently promises byte equality, and confirm generated compiler
entrypoint files match. Commit before moving on.

#### Group C: Verification

- `selfcheck`
- `smoke`
- `fixpoint`
- `test`

Stop here. Run parity checks between `make X` and `with build :X` for every
target in the group. Confirm `fixpoint` compares the same artifacts
byte-for-byte and `test` does not run full migrated-library corpora. Commit
before moving on.

#### Group D: Install

- `install`
- `install-user`

Stop here. Run parity checks between `make X` and `with build :X` for every
target in the group. Confirm installed paths, modes, and overwrite behavior.
Commit before moving on.

#### Group E: PCRE2

- `pcre2-migrate`
- `pcre2-build`
- `pcre2-test`
- `pcre2-promote`

Stop here. Run parity checks between `make X` and `with build :X` for every
target in the group. Confirm migration is only triggered by `pcre2-migrate`,
not by `pcre2-build`, `pcre2-test`, `build`, or `test`. Confirm promoted files
match verified generated files. Commit before moving on.

#### Group F: Emit-C

- `emit-c-test`
- `emit-c-fixpoint`
- `emit-c-roundtrip`

Stop here. Run parity checks between `make X` and `with build :X` for every
target in the group. Confirm emitted C artifacts, rebuilt compiler outputs, and
roundtrip stamps match the Make behavior. Commit before moving on.

#### Group G: Other

- `cross`

Stop here. Run parity checks between `make cross` and `with build :cross`.
Confirm unsupported or unexercised platforms fail loudly with the same
diagnostic contract. Commit before moving on.

PCRE2 migration must remain manually triggered. `test`, `build`, and ordinary
verification targets must not implicitly run `pcre2-migrate`.

### Phase 5: Make `with build` the Primary Path

1. Update documentation to teach `with build` first.
2. Keep Make as a compatibility wrapper that delegates to `with build`.
3. Ensure wrapper targets do not add behavior that is absent from `with build`.
4. Run full parity:

```text
make build
with build :build
make fixpoint
with build :fixpoint
make test
with build :test
```

5. Compare expected build artifacts where byte equality is required.
6. Only after parity, remove Make-only logic.

### Phase 6: Delete Make and Scripts

Deprecation is not complete while Make still owns build behavior. The end state
is deletion, not a permanent compatibility layer.

#### 6.1 Script Deletion Audit

1. List every file in `scripts/`.
2. For each script, identify whether it is referenced by Make, `build.w`,
   compiler code, docs, or CI.
3. Classify scripts into:
   - already unused: delete immediately after confirming no references;
   - replaced by `with build`: delete after the corresponding Phase 4 group
     parity check passes;
   - bootstrap-only: keep temporarily with a deletion condition.
4. Commit script deletions separately from behavior changes.

#### 6.2 Delete Replaced Scripts by Group

After each Phase 4 group passes and is committed, delete the scripts made
obsolete by that group:

- after Group A, delete scripts used only for clean/version/seed/update-seed;
- after Group B, delete scripts used only for compiler staging/runtime object
  generation;
- after Group C, delete scripts used only for core test orchestration;
- after Group D, delete scripts used only for install copying;
- after Group E, delete scripts used only for PCRE2 migrate/build/test/promote;
- after Group F, delete scripts used only for emit-C testing and roundtrip;
- after Group G, delete scripts used only for cross target glue.

Each deletion must be gated by:

```text
rg <script-name>
with build :<group-targets>
```

If any remaining reference exists, either remove the reference in the same
change or keep the script with a written deletion condition.

#### 6.3 Remove Fallback Paths in Compiler Source

After project-specific target execution has moved out of generic compiler
dispatch:

1. Remove hardcoded project target branches from `src/main.w`.
2. Remove old integer project-kind decoding from `src/BuildGraphKinds.w`.
3. Remove compatibility aliases such as `copy_runtime_tree` once graph fixtures
   and docs use the standard name.
4. Delete project-specific build executor modules from `src/` if they have
   moved into project-local build modules.

Each removal must be gated by:

```text
with build --graph --dry-run
with build :build
with build :fixpoint
with build :test
```

#### 6.4 Turn Make Into a Shim

Only after every Phase 4 group has passed parity:

1. Replace Make target bodies with one-line delegations to `with build :target`.
2. Keep this shim for one release cycle.
3. Add CI that uses `with build` directly.
4. Add CI that fails if Make contains behavior other than delegation.

#### 6.5 Delete the Makefile

After the shim release cycle:

1. Delete the Makefile.
2. Update documentation and CI to remove Make references.
3. Confirm bootstrap instructions use `with build` and the seed compiler path.
4. Run:

   ```text
   with build :build
   with build :fixpoint
   with build :test
   ```

5. Commit the Makefile deletion separately.

---

## 9. Beyond Make Parity: Compiler-as-Library

Phases 1-6 replace the current Makefile and shell-script build system with a
With-native target graph. That is necessary, but it is not the full Jai build
model.

Jai's integrated build system is stronger than a typed replacement for Make:
the build program talks to the compiler as a library. It can create isolated
compiler workspaces, configure build options for each workspace, add source
files or generated source strings, intercept compiler messages, inspect typed
code, generate more code at specific phases, and choose whether the build
program itself emits an executable.

With should grow the same capability in With terms, but it must not be done by
making ordinary `comptime` effectful.

### 9.1 Comptime Remains Pure

Ordinary `comptime` is deterministic compile-time evaluation. It is for type
introspection, constant computation, derives, generated declarations, and
compile-time diagnostics. It must remain reproducible and must not gain broad
filesystem, process, network, or toolchain effects.

Privileged build operations belong to tool mode. `build.w` is tool-mode
compiler-driver code, not ordinary pure `comptime`.

### 9.2 Missing Compiler-Driver Capabilities

Full Jai-style parity requires at least these APIs and runtime semantics:

1. **Workspace APIs.**
   Build code must be able to create and name isolated compiler workspaces,
   ask for the current workspace, and keep source additions, diagnostics, and
   build options scoped per workspace.

2. **Source injection.**
   Build code must be able to add source files and source strings to a
   workspace. Generated source should be explicit and should go through the
   normal parser, type checker, borrow checker, and code generator.

3. **Compiler message loop.**
   Build code must be able to begin intercepting a workspace, wait for typed
   messages, and end interception. Messages should include at least file load,
   import, phase, typechecked declarations, debug dump, error, and complete.

4. **Structured build options.**
   Output kind, output path/name, optimization level, target triple, import
   paths, link inputs, runtime checks, debug info, and text-output policy
   should be structured values attached to a workspace, not CLI strings.

5. **Capability gating.**
   Filesystem, process execution, downloads, archive extraction, artifact
   promotion, and compiler mutation are tool-mode capabilities. They should be
   unavailable to ordinary `comptime` unless exposed through a deliberately
   restricted API.

6. **Default-metaprogram behavior.**
   `with build` should act as the built-in default build driver. A project
   `build.w` should be able to replace or extend the default behavior, and a
   future module-style metaprogram should be able to customize the default
   build path without requiring Make, CMake, Ninja, or generated project files.

### 9.3 Bridge Between Comptime and Tool Mode

Jai uses `#run` to execute build/metaprogram code at compile time in a compiler
context. With needs an equivalent boundary, but the design is not settled.

The bridge must answer:

- how source marks a function or block as tool-mode-only;
- how the compiler prevents tool APIs from leaking into ordinary runtime code;
- how tool code invokes normal compilation workspaces;
- how generated source is made visible to the target workspace;
- how diagnostics point at the build code, generated code, and target code
  clearly;
- how this interacts with existing pure `comptime` functions.

Until that boundary is designed, `build.w` should be treated as a pragmatic
tool-mode entry point implemented by the CLI driver, not as the final
compiler-as-library model.

### 9.4 Not in Scope for Phases 1-6

The current phases do not include:

- first-class compiler workspace creation from user build code;
- public `BuildOptions` APIs equivalent to Jai's `get_build_options` and
  `set_build_options`;
- public `add_source_file` or `add_source_string` workspace APIs;
- compiler message interception or phase callbacks;
- typed code inspection from build scripts;
- compiler hooks that can generate code during a selected workspace phase;
- a final syntax for tool-mode-only functions or blocks;
- a replacement for the default compiler metaprogram.

Therefore, Phase 6 completion means "Make and shell-script replacement is
complete." It does not mean "With has reached Jai build-system parity." The
compiler-as-library layer is the next architectural project after Make parity.

---

## 10. Quality Bar

Every implementation slice must keep these invariants:

- No project-specific target names in `lib/std/build.w`.
- No silent fallback when a target cannot execute.
- No raw shell command strings in compiler, stdlib, runtime, or build-system
  implementation code.
- `make test` and `with build :test` do not run full migrated-library corpora.
- Full migrated-library tests remain explicit library targets.
- `clean` is standard, but clean paths are project-defined.
- PCRE2 is treated as one migrated library workflow, not a special regex build
  system.
- Build graph serialization is deterministic.
- Fixpoint remains byte-for-byte.

---

## 11. First Concrete Slice

The next implementation slice should be deliberately small:

1. Re-add standard `Clean` to `lib/std/build.w`.
2. Replace `project_kind_clean()` in `build.w` with `.Clean`.
3. Rename `CopyRuntimeTree` to `CopyTree` in the public API, keeping a temporary
   compatibility alias if needed.
4. Update `src/BuildGraphKinds.w` names and implemented-kind checks so the
   standard/project boundary is explicit.
5. Add or update behavior tests for:
   - `Build.clean`;
   - `Build.copy_tree`;
   - no With-repository target constructors in `std.build`.
6. Verify:

```text
out/bin/with check lib/std/build.w
out/bin/with check build.w
out/bin/with run test/behavior/behav_std_build_api.w
out/bin/with build --graph --dry-run
```

Only after that passes should the next slice move dispatch out of `src/main.w`.
