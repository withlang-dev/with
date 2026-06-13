# With Integrated Build System Specification

Archived: historical final-state build-system specification. The active
Makefile-removal plan is `docs/eliminate-Makefile.md`. This file is retained as
project history, not as the current implementation contract.

Status: final-state specification.

This document defines the intended end state of the With build system. It is
not an implementation progress report. The build system is complete when this
document describes reality without caveats.

With builds are written in With. A normal project must not need Make, CMake,
Ninja, shell scripts, Python, Perl, or generated IDE project files to build,
test, install, generate sources, run code generators, or orchestrate compiler
workflows.

The design is inspired by Jai's integrated build process, but uses With's
capability-based tool-mode model.

---

## 1. Doctrine

With has two build configuration surfaces:

```text
with.toml  declarative package metadata
build.w    executable build behavior
```

`with.toml` contains package identity, dependencies, minimum compiler version,
feature defaults, publishing metadata, and declarative defaults.

`build.w` contains imperative build behavior:

- conditionals and loops;
- target graph construction;
- generated source and generated binary data;
- asset pipelines;
- compiler workspaces;
- compiler hooks and project checks;
- test harnesses;
- C migration flows;
- migrated-library build/test/promote flows;
- install, clean, and promotion operations.

Imperative build behavior in `with.toml` is invalid. The compiler must reject
it and point the user to `build.w`.

---

## 2. Command Surface

Required user commands:

```sh
with build
with build :target
with test
with clean
with install-user
```

`with test`, `with clean`, and `with install-user` are driver conveniences for
the corresponding build targets. They must not contain behavior that cannot be
expressed in `build.w`.

Required build flags:

```text
--target <target>
--release
--debug
--out <path>
--verbose
--dry-run
--graph
--explain <target>
```

`--graph` prints a stable graph representation.

`--dry-run` prints the selected graph and planned actions without mutating
files.

`--explain <target>` prints why a target will run, which dependencies and
producer edges selected it, and which declared inputs/outputs are involved.

Direct source builds remain supported:

```sh
with build src/main.w
with build src/main.w -o out/bin/app
with build src/main.w --emit-obj -o out/main.o
with build src/main.w --emit-c -o out/main.c
```

Direct source builds bypass `build.w`.

---

## 3. Build File Discovery

When `with build` is run in a project directory:

1. The driver searches upward for `with.toml` or `build.w`.
2. The driver reads `with.toml` if present.
3. If `build.w` exists, the driver compiles and executes it in tool mode.
4. If no `build.w` exists, the driver synthesizes the default recipe.

Default recipe:

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    let info = ctx.project_info()
    ctx.new_build().executable(info.package_name(), "src/main.w")
```

If neither `build.w` nor `src/main.w` exists, the driver fails with a
diagnostic.

---

## 4. Tool Mode

`build.w` is compiled and run by the compiler driver as capability-bearing
comptime With code. Pure `comptime` remains deterministic and side-effect-free.
Tool-mode effects are available only through compiler-provided capabilities.

Capability values are unforgeable driver handles. User code may receive, pass,
borrow, store locally, and call methods on capability values, but may not
construct or deserialize production capabilities.

Tool-mode capability APIs must be implementation-boundary-safe:

- no raw pointer transport;
- no shared-address-space assumptions;
- no hidden global compiler object;
- no dependency on same-process execution.

The driver may implement capabilities in-process, through a separate tool
binary, or through RPC. The user-facing model remains capability parameters.

---

## 5. Build Entry Point

A project build file exposes:

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    ...
```

The driver constructs `BuildCtx`, binds it into the capability-bearing
comptime entry point as `ctx`, evaluates `build`, receives a `Build` graph,
validates it, selects the requested target closure, and executes it.

`build.w` is normal With code. There is no separate build language.

---

## 6. Capabilities

The initial capability set is:

```text
BuildCtx        top-level build entry capability
ProjectInfo     read-only project metadata and structure
Diagnostics     warnings and fatal errors
SourceEmitter   generated source construction
ToolFs          sandboxed filesystem operations
ProcessRunner   argv-based process execution
Workspace       compiler workspace handle
```

Capabilities are coarse at first. New capabilities are split out only for
demonstrated reuse, security, or testing reasons.

### BuildCtx

`BuildCtx` exposes narrower capabilities and workspace operations:

```with
pub fn BuildCtx.project_info(self: &Self) -> ProjectInfo
pub fn BuildCtx.new_build(self: &Self) -> Build
pub fn BuildCtx.diagnostics(self: &Self) -> Diagnostics
pub fn BuildCtx.source_emitter(self: &Self) -> SourceEmitter
pub fn BuildCtx.fs(self: &Self) -> ToolFs
pub fn BuildCtx.process_runner(self: &Self) -> ProcessRunner
pub fn BuildCtx.create_workspace(self: &Self, name: str) -> Workspace
pub fn BuildCtx.current_workspace(self: &Self) -> Workspace
```

### ToolFs

`ToolFs` is rooted at the project root by default. Project-root operations
accept project-relative paths. Absolute paths and parent-directory escapes
fail unless a narrower explicit capability grants that destination.

Required operations:

```with
read_text(path: str) -> str
read_binary(path: str) -> Vec[u8]
write_text(path: str, contents: str) -> i32
write_binary(path: str, bytes: Vec[u8]) -> i32
exists(path: str) -> bool
is_dir(path: str) -> bool
mkdir_all(path: str) -> i32
remove_file(path: str) -> i32
remove_tree(path: str) -> i32
copy_file(src: str, dst: str) -> i32
copy_tree(src: str, dst: str) -> i32
rename(src: str, dst: str) -> i32
symlink(src: str, dst: str) -> i32
chmod(path: str, mode: i32) -> i32
glob(pattern: str) -> Vec[str]
normalize(path: str) -> str
join(base: str, child: str) -> str
```

Directory listings and globs must be deterministic.

### ProcessRunner

Processes use argv, cwd, environment, capture files, and timeout. No primary
process API accepts a shell command string.

```with
pub type ProcessSpec {
    executable: str,
    args: Vec[str],
    cwd: str,
    env: Vec[EnvVar],
    timeout_ms: i64,
    stdin: str,
    capture_stdout: bool,
    capture_stderr: bool,
}

pub type ProcessResult {
    rc: i32,
    stdout: str,
    stderr: str,
    timed_out: bool,
}

pub fn ProcessRunner.run(self: &Self, spec: ProcessSpec) -> ProcessResult
```

If shell execution is ever exposed, it must be a separate explicitly named
unsafe/tool-only API and is forbidden for compiler repository build logic.

---

## 7. Workspaces

A workspace is an isolated compiler environment used to compile one program,
library, object, generated source set, or tool.

Workspaces are isolated:

- source additions in one workspace do not affect another;
- build options are per-workspace;
- diagnostics identify the workspace;
- generated source is explicitly added to a workspace;
- compiler hooks run only for the workspace being compiled.

Required workspace operations:

```with
pub fn BuildCtx.create_workspace(self: &Self, name: str) -> Workspace
pub fn BuildCtx.current_workspace(self: &Self) -> Workspace
pub fn ActionCtx.create_workspace(self: &Self, name: str) -> Workspace
pub fn ActionCtx.current_workspace(self: &Self) -> Workspace

pub fn Workspace.name(self: &Self) -> str
pub fn Workspace.add_file(self: &Self, path: str)
pub fn Workspace.add_string(self: &Self, name: str, source: str)
pub fn Workspace.options(self: &Self) -> BuildOptions
pub fn Workspace.set_options(self: &Self, options: BuildOptions)
pub fn Workspace.set_migrate_options(self: &Self, options: MigrateOptions)
pub fn Workspace.compile(self: &Self) -> BuildResult
pub fn Workspace.begin_intercept(self: &Self)
pub fn Workspace.wait_for_message(self: &Self) -> CompilerMessageEnvelope
pub fn Workspace.end_intercept(self: &Self)
pub fn Workspace.set_link_command(self: &Self, command: LinkCommand)

pub fn parallel(workspaces: Vec[Workspace]) -> Vec[BuildResult]
```

The storage representation of `Workspace` is compiler-private.

---

## 8. Build Options

Build options are typed values, not strings.

```with
pub enum BuildOutputKind: i32:
    Binary = 0
    Object = 1
    C = 2
    LlvmIr = 3
    Archive = 4
    Check = 5

pub enum OptimizeMode: i32:
    debug = 0
    release = 1

pub enum BuildTarget: i32:
    native = 0
    linux_x86_64 = 1
    linux_aarch64 = 2
    darwin_x86_64 = 3
    darwin_aarch64 = 4
    windows_x86_64 = 5

pub enum PreludeMode: i32:
    Full = 0
    Core = 1
    None = 2

pub type BuildOptions {
    source_path: str,
    output_path: str,
    output_kind: BuildOutputKind,
    opt_level: i32,
    debug_info: bool,
    no_std: bool,
    alloc_mode: bool,
    prelude_mode: PreludeMode,
    deterministic: bool,
    target: BuildTarget,
    include_paths: Vec[str],
    defines: Vec[str],
    link_libs: Vec[str],
    compiler_hooks_enabled: bool,
}
```

Unsupported target/options combinations fail before action execution and name
the requested target, host target, and unsupported operation.

---

## 9. Build Graph

`std.build` constructs a declarative typed graph. Effects happen when the
driver executes the graph, not while user code constructs target values.

All graph nodes have:

- stable name;
- source location of declaration when available;
- kind;
- explicit dependencies;
- declared inputs;
- declared outputs;
- target platform;
- build options;
- action-specific arguments.

Graph execution is deterministic. Duplicate output paths fail before any
selected node runs.

Selecting a target selects its dependency closure and producer edges. Producer
edges are inferred from declared inputs/outputs.

---

## 10. Standard Target Kinds

The standard target vocabulary lives in `std.build`.

### Product Targets

```text
Executable
Library
Object
Archive
```

`Library` may produce static or dynamic output according to typed options.
`Object` emits a With source file to an object file. `Archive` emits a With
source file to a static archive. Generated sources are graph entries, not
target kinds, because they carry source contents rather than source paths.

### Composition Targets

```text
Group
Command
```

`Group` is an aggregate target.

`Command` runs a declared argv-based external process with inputs, outputs,
cwd, environment, capture policy, and timeout.

### Verification Targets

```text
Test
BinaryCompare
FixpointCompare
RunCorpusTest
```

`FixpointCompare` is a named standard operation because self-hosting compilers
and code generators commonly need byte-identical convergence diagnostics.

`RunCorpusTest` runs a declared test program or compiler mode across a corpus
with structured capture and timeout reporting.

### Toolchain Targets

```text
CompileCObject
CompileAsmObject
CompileLlvmIrObject
CreateStaticArchive
GenerateResponseFile
EmbedObjectFiles
```

These are standard because ordinary With projects may link C, assembly, LLVM
IR, archives, or embedded binary assets.

### Filesystem and Promotion Targets

```text
Install
Clean
CopyFile
CopyTree
PromoteTreeIfVerified
```

`Clean` removes declared artifact paths safely.

`PromoteTreeIfVerified` copies generated output into a source or distribution
location only after declared verification dependencies pass.

---

## 11. Project-Local Tool Actions

Project-specific build behavior must not require compiler source changes.

`build.w` can declare project-local tool actions as typed graph nodes backed by
ordinary With functions:

```with
comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build()
    out = out.action("generate-bindings", generate_bindings)
    out

fn generate_bindings(ctx: ActionCtx) -> i32:
    ...
```

`ActionCtx` provides only declared capabilities:

- diagnostics;
- sandboxed filesystem;
- process runner;
- project info;
- declared inputs;
- declared outputs;
- target name;
- temporary output directories.

Project-local actions must declare inputs, outputs, dependencies, cwd,
environment, timeout, and whether they may access network or install paths.

The compiler repository's PCRE2, emit-C roundtrip, seed, selfhost fixture, and
compiler stage policy are project-local actions or compositions of standard
nodes. They are not hardcoded into the generic build driver.

---

## 12. Source Inputs and Generated Source

Source inputs may be:

- file paths;
- generated source paths;
- in-memory source strings;
- directory globs;
- explicit file lists.

Generated source paths must be relative and must not escape the project root or
declared output root unless an explicit capability grants that destination.

Generated source appears in diagnostics using its declared path/name.

Empty globs fail loudly by default.

---

## 13. Compiler Message Loop

Tool-mode build code can intercept compiler progress for a workspace.

Message payloads:

```with
pub enum CompilerMessage:
    Phase(CompilerPhase)
    File(str)
    Import(str, str)
    Typechecked(Vec[DeclSummary])
    Diagnostic(DiagnosticSummary)
    Artifact(Artifact)
    PreLink(LinkCommand)
    Linked(LinkCommand, i32)
    Complete(BuildResult)
    Error(i32, str, SourceSpan)
    DebugDump(str)
```

Compiler phases:

```with
pub enum CompilerPhase: i32:
    pre_parse = 0
    parsed = 1
    pre_typecheck = 2
    typechecked = 3
    lowered_to_mir = 4
    pre_codegen = 5
    codegen_done = 6
    pre_link = 7
    linked = 8
    complete = 9
```

This supports build-time code inspection, generated source after typechecking,
and project-specific rule enforcement.

---

## 14. Project Introspection

`std.compiler.ProjectInfo` is the stable user-facing introspection model.
Build code and compiler hooks may inspect:

- modules;
- imports;
- functions;
- types;
- fields;
- attributes;
- source locations;
- visibility;
- typed signatures.

Build code must not depend on raw internal AST node layouts.

---

## 15. Tests

The integrated build system supports:

- behavior tests;
- compile-error tests;
- CLI selfhost tests;
- temp-project regression tests;
- generated-code tests;
- standard-library tests;
- external corpus tests.

Compile-error tests assert diagnostics intentionally. They do not pass just
because compilation failed for an unrelated reason.

Default project test targets run project tests. Migrated-library upstream
corpora are explicit per-library targets such as `pcre2-test`, not part of the
default test target.

---

## 16. Downloads and External Sources

Downloaded external sources are build inputs under `out/` by default.

Required standard operations:

```with
pub type Download {
    url: str,
    sha256: str,
    output_path: str,
}

pub fn Build.download(self: Build, name: str, spec: Download) -> Build
pub fn Build.extract_tar_gz(self: Build, name: str, archive: str, output_dir: str) -> Build
```

A missing checksum is allowed only for explicitly marked development workflows
and prints a warning.

---

## 17. Install, Promote, and Seed Safety

Install operations are first-class graph nodes.

Install nodes may write outside the project only through explicit install
capabilities.

Seed and user compiler updates require:

- successful compiler build;
- successful fixpoint;
- successful full test suite;
- committed source state unless explicitly overridden by a privileged
  developer-only flag.

The driver must make unsafe install/update-seed operations difficult to run
accidentally.

---

## 18. Repository Locking and Incrementality

The build driver provides a repository lock for shared mutable output roots.

Required behavior:

- one top-level mutating build action at a time;
- owner metadata includes target name, pid, and start time;
- stale lock diagnosis is explicit;
- nested graph execution inside one top-level action does not deadlock.

The driver tracks declared inputs, outputs, tool identities, options, and
selected environment. Incrementality is a correctness feature first. A target
may be skipped only when the driver can prove that every declared output was
produced by the same logical action from the same logical inputs.

### Build State

The driver stores build state under the active output root, not in source
directories. The state database records one entry per graph node:

- build schema version;
- compiler identity and compiler build fingerprint;
- package root and normalized graph node name;
- graph node kind and source location in `build.w` when available;
- stable action signature;
- sorted declared input fingerprints;
- sorted dependency output fingerprints;
- sorted declared output fingerprints;
- relevant environment fingerprints;
- tool and external executable fingerprints;
- completion status.

Changing the state schema, graph-node encoding, standard target kind table, or
compiler cache-key algorithm invalidates affected entries. Stale serialized
state must fail with a regenerate diagnostic or be ignored and rebuilt; it must
not be partially interpreted.

### Fingerprints

The canonical fingerprint for file contents is a cryptographic content hash.
Modification time is allowed only as a fast path for deciding whether to
re-read a file before computing the authoritative content hash. It is never
proof that a target is fresh.

A file fingerprint includes:

- normalized project-relative or capability-granted absolute path;
- file kind: regular file, directory, symlink, or absent;
- content hash for regular files;
- symlink target for symlinks;
- executable bit when relevant to an action;
- file size as a diagnostic aid, not as the identity.

Directory and glob fingerprints are computed from sorted child entries. Empty
globs fail unless the graph node explicitly opted into empty input sets.

Generated source and in-memory source strings use their declared logical path
and content hash. Two generated sources with identical contents but different
declared paths are distinct inputs because diagnostics and import resolution
observe the path.

### Action Signatures

A target action signature includes all data that can change the outputs:

- target kind and target name;
- typed build options;
- target platform and optimization/debug settings;
- declared argv, cwd, timeout, capture policy, and stdin for command targets;
- declared environment variables and their values;
- source file list, generated source list, include paths, defines, link libs,
  and runtime object selection for compiler workspaces;
- compiler version, standard-library version, and runtime object fingerprints;
- external executable identity for process-backed targets;
- implementation version for standard target kinds and project-local action
  functions.

Project-local actions must declare an implementation version or function body
fingerprint. If the driver cannot fingerprint the action implementation, the
action is treated as stale rather than assumed fresh.

Environment is opt-in. The driver fingerprints only variables declared by the
target or required by a standard operation. If an action reads undeclared
environment through a capability, the capability records the read and the
driver diagnoses the missing declaration.

### Freshness Rules

A graph node is fresh only when all of these are true:

- its state entry exists and has a compatible schema version;
- its action signature matches;
- every declared input fingerprint matches current filesystem state;
- every dependency output fingerprint matches the dependency's current
  declared outputs;
- every declared output exists and matches the recorded output fingerprint;
- no previous execution of the node ended in failure or partial completion.

If any condition is false, the node is stale and must run. Missing outputs are
stale. Extra undeclared outputs are a diagnostic unless the target kind
explicitly owns an output directory and records its directory fingerprint.

Skipped nodes are reported as skipped, not successful reruns. `--explain
<target>` must say which freshness rule passed or failed for each selected
node, naming the first stale input, output, dependency, tool, or environment
entry when available.

### Execution and Atomicity

Targets write into a target-private temporary directory or temporary file.
After successful execution, the driver verifies that all declared outputs were
created, fingerprints them, and atomically promotes them into their declared
locations where the platform supports atomic replacement.

If execution fails, times out, or is interrupted, the state entry remains
failed and no fresh stamp is written. Partial outputs are removed when safe, or
left with a diagnostic naming them when removal is unsafe.

`ToolFs.write_text`, `ToolFs.write_binary`, generated source emission, copy,
promotion, response-file generation, and install staging use skip-if-unchanged
writes: if the destination already contains the requested bytes and metadata,
the driver does not rewrite the file. This preserves downstream freshness and
prevents timestamp churn.

### Dependency Tracking

Declared graph inputs are authoritative. Standard compiler workspace targets
also record compiler-observed imports, C imports, included headers, runtime
objects, and linker inputs. If observed inputs differ from declared inputs,
the driver updates the recorded observed-input set for future freshness checks
and reports the mismatch in verbose or explain output.

Process-backed project actions may only be cached from declared inputs,
declared outputs, declared environment, and declared tools. The driver must not
infer arbitrary process filesystem reads by tracing the operating system as a
substitute for declarations. A future traced-input mode may diagnose missing
declarations, but it is not part of the correctness proof for a cache hit.

### Cache Reuse

The initial implementation may use per-output-root state and local artifact
fingerprints. A later content-addressed cache may reuse artifacts across output
roots only when the action signature and all input fingerprints match exactly.

Cache reuse is an optimization. If the cache is missing, corrupt, has an
unknown schema, or cannot verify an output hash, the target rebuilds or fails
loudly according to the target kind. The driver must never fabricate a
declared output to satisfy downstream targets.

---

## 19. Diagnostics and Failure Semantics

Build diagnostics include:

- selected build target;
- graph node name;
- source location in `build.w` when available;
- workspace name when relevant;
- underlying compiler diagnostic when available;
- process exit code when applicable;
- failed artifact path.

Hard failures:

- unsupported graph node kind;
- unsupported target platform;
- missing generated file;
- empty test glob;
- duplicate output path;
- untranslated migrator construct;
- missing external tool;
- failed process;
- failed install;
- unsafe path escape;
- stale or failed verification dependency.

No build step may create placeholder output to let later steps compile.

---

## 20. Compiler Repository Requirements

The With compiler repository must be buildable entirely through `with build`.

Required targets:

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

The graph preserves bootstrap order:

1. seed builds stage1;
2. stage1 builds stage2;
3. stage2 builds stage3;
4. stage2 and stage3 fixpoint outputs compare byte-identically;
5. only verified stage2 becomes canonical/user-installed.

Migrated-library command families are per library:

```text
<lib>-reference
<lib>-migrate
<lib>-build
<lib>-test
<lib>-promote
```

PCRE2 is the first migrated library. Future libraries such as jq, sqlite,
minicoro, and termbox2 use the same family without adding compiler-driver
special cases.

---

## 21. Make and Scripts

The final build system has no repository Makefile dependency and no required
repository shell scripts for building, testing, migrating, promoting,
installing, cleaning, or running emit-C roundtrips.

Repository shell scripts may remain only as optional developer conveniences
that call `with build` or as fixtures whose purpose is testing shell-facing
behavior. They are not part of the authoritative build path.

---

## 22. Acceptance Criteria

The integrated build system is complete when all of these pass without Make or
repository shell scripts:

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

and:

- the produced compiler passes fixpoint;
- the full default test suite passes;
- migrated-library corpora pass only when explicitly requested;
- generated/promoted stdlib code is verified before promotion;
- no silent migrator fallback is used;
- every standard target kind executes or has been deliberately removed from
  the standard vocabulary;
- project-specific build behavior lives in project `build.w` modules, not in
  generic compiler driver source;
- no Python, Perl, Make, or shell script is required for the compiler build.
