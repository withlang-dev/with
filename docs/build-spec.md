# With Integrated Build System

Status: draft specification.

This document specifies the intended With build system. The goal is to
replace Makefiles, shell-script orchestration, and project-specific build
glue with build behavior written in With itself.

The design is inspired by Jai's integrated build process, but expressed in
With terms: tool-mode With code, typed compiler APIs, explicit workspaces,
normal diagnostics, and no silent fallbacks.

For the near-term implementation, the current developer host is the only
platform that must be fully exercised. At the time this draft is being written
that host is macOS, but macOS is not privileged in the language or build-system
design. The API must model platforms and targets explicitly so Linux, Windows,
and other hosts can be supported without redesigning the build system.

---

## 1. Goals

The build system must make these statements true:

- A With program can describe how it is built using With source code.
- A normal project does not need Make, CMake, Ninja, shell scripts, Python,
  Perl, or any other external build language.
- The compiler can run build code in a privileged tool-mode context.
- Build code uses typed APIs, not shell command strings.
- Build failures are normal compiler/tool diagnostics and exit nonzero.
- Unsupported build features fail loudly; they are never ignored.
- The compiler's own repository can eventually build itself using this system.

The immediate practical target is:

```
with build
with test
with build :compiler
with build :regex-migrate
with build :regex-test
with build :install-user
```

without invoking Make or repository shell scripts.

---

## 2. Non-Goals

The first complete implementation does not need to:

- exercise Linux or Windows builds;
- implement full cross-linking for every target;
- replace GitHub release packaging;
- support arbitrary user shell commands as the primary extension point;
- make ordinary `comptime` effectful.

Cross-platform plumbing should exist in the data model, but only the current
developer host must be exercised during the first implementation slice.

---

## 3. Build Doctrine

With has two build configuration surfaces:

```
with.toml  = declarative package metadata
build.w    = executable build behavior
```

`with.toml` may contain package identity, dependencies, minimum compiler
version, default target settings, feature defaults, and publishing metadata.

`with.toml` must not contain imperative build behavior. These belong in
`build.w`:

- conditionals and loops;
- generated source;
- generated binary data;
- asset pipelines;
- compiler stage graphs;
- test harnesses;
- C migration flows;
- install/promote operations;
- target graph construction.

If imperative build keys appear in `with.toml`, the compiler must reject them
and point to `build.w`.

---

## 4. Build File Discovery

When `with build` is run in a project directory:

1. The driver reads `with.toml` if present.
2. If `build.w` exists, the driver executes it in tool mode.
3. If no `build.w` exists, the driver synthesizes the default build recipe.

Default recipe:

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    let info = ctx.project_info()
    ctx.new_build().executable(info.package_name(), "src/main.w")
```

The default recipe is intentionally small. It builds one executable from
`src/main.w` using the package name as the output name.

If a project has neither `build.w` nor a valid default entry source, the
driver must fail with a diagnostic.

---

## 5. Tool Mode

`build.w` is compiled and run by the compiler driver as tool-mode With code.
Tool mode is not ordinary `comptime`.

Ordinary `comptime` remains deterministic and side-effect-free. Tool mode is
allowed to perform build effects only through compiler-provided APIs such as
`std.build`, `std.compiler`, `std.fs`, and `std.process`.

Tool-mode APIs are capabilities. If an operation is not exposed through a typed
tool-mode API, build code cannot perform it.

Forbidden in compiler, migrator, runtime, stdlib, and build-system code:

- assembling shell command strings to perform filesystem work;
- using shell pipelines as the build abstraction;
- silently falling back to a partial output;
- emitting placeholder generated code for failed build steps.

Shell semantics are acceptable only in test fixtures whose purpose is to test
shell-facing CLI behavior.

---

## 6. Build Entry Points

A project build file must expose this form:

```with
pub fn build(ctx: BuildCtx) -> Build:
    ...
```

The driver constructs a `BuildCtx` capability from package metadata and
invokes `build`. The returned value is the complete build graph.

`build.w` may define additional named build entry points:

```with
pub fn compiler(ctx: BuildCtx) -> Build:
    ctx.new_build()

pub fn regex_migrate(ctx: BuildCtx) -> Build:
    ...
```

CLI selection:

```
with build              # calls build
with build :compiler    # calls compiler
with build :regex-test  # calls regex_test or regex-test alias
```

If the selected entry point does not exist or has the wrong type, the driver
must fail loudly.

---

## 7. Workspaces

A workspace is an isolated compiler environment used to build one program,
library, object, generated source set, or tool.

The build driver starts with one tool workspace for `build.w`. Build code may
request additional workspaces through `std.build` APIs.

Workspaces must be isolated:

- source additions in one workspace do not affect another;
- build options are per-workspace;
- diagnostics identify the workspace that produced them;
- generated source must be explicitly added to the target workspace;
- compiler hooks run only for the workspace being compiled.

Required API model:

```with
pub type Workspace

pub fn BuildCtx.create_workspace(self: &Self, name: str) -> Workspace
pub fn BuildCtx.current_workspace(self: &Self) -> Workspace
```

The exact storage representation of `Workspace` is compiler-private.

---

## 8. Build Options

Build options are typed values, not strings.

```with
pub enum OutputKind: i32:
    no_output = 0
    executable = 1
    static_library = 2
    dynamic_library = 3
    object_file = 4

pub enum OptimizeMode: i32:
    debug = 0
    release = 1

pub enum BuildTarget: i32:
    native = 0
    darwin_aarch64 = 1
    darwin_x86_64 = 2
    linux_aarch64 = 3
    linux_x86_64 = 4
    windows_x86_64 = 5

pub type BuildOptions {
    output_kind: OutputKind,
    output_name: str,
    output_dir: str,
    intermediate_dir: str,
    target: BuildTarget,
    optimize: OptimizeMode,
    debug_info: bool,
    line_directives: bool,
    array_bounds_check: bool,
    cast_bounds_check: bool,
    null_pointer_check: bool,
    import_paths: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    system_libs: Vec[str],
    library_paths: Vec[str],
}
```

The driver may add fields over time, but fields must remain typed and
documented.

Unknown or unsupported target/options combinations must be diagnostics.

For the current-host implementation phase:

- `BuildTarget.native` and the matching Darwin host target must work.
- non-host targets may fail loudly after graph construction.
- the error must name both the requested target and host target.

---

## 9. Build Graph

`std.build` constructs a typed graph. The graph is declarative after `build`
returns. The driver is responsible for executing it.

Core target kinds:

```with
pub enum BuildKind: i32:
    executable = 0
    library = 1
    test = 2
    object = 3
    archive = 4
    generated_source = 5
    generated_binary = 6
    command = 7
    install = 8
    group = 9
```

`command` does not mean "shell command." It means a typed operation supplied by
the build driver or by a With tool target.

All graph nodes have:

- stable name;
- source location of declaration;
- explicit dependencies;
- declared outputs;
- declared inputs;
- target platform;
- build options.

Graph execution must be deterministic. If two nodes write the same output, the
driver must fail before running either node.

---

## 10. Source Inputs

Source inputs may be:

- a file path;
- a generated source path;
- an in-memory source string;
- a directory glob;
- an explicit list of files.

Example:

```with
pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.generated_source(
        "out/gen/version.w",
        "pub fn build_version -> str:\n    \"dev\"\n",
    )
    out = out.executable("app", "src/main.w")
    out
```

Generated paths must be normalized and must not escape the project root or
declared output directory unless the API explicitly grants that permission.

Empty globs fail loudly by default.

---

## 11. Compiler Operations

Tool-mode build code needs typed compiler operations.

Minimum required operations:

```with
pub fn BuildCtx.compile(
    self: &Self,
    workspace: Workspace,
    options: BuildOptions,
    sources: Vec[SourceInput],
) -> BuildResult

pub fn BuildCtx.compile_object(...)
pub fn BuildCtx.link_executable(...)
pub fn BuildCtx.link_static_library(...)
pub fn BuildCtx.run_tests(...)
```

`BuildResult` includes:

- success/failure;
- diagnostics;
- produced artifacts;
- workspace name;
- timing information;
- exit code where applicable.

Compilation failures are not boolean trivia. They are first-class diagnostics.

---

## 12. Compiler Message Loop

The build system must support intercepting compiler progress for a workspace.

Message kinds:

```with
pub enum CompilerMessageKind: i32:
    file = 0
    import = 1
    phase = 2
    typechecked = 3
    diagnostic = 4
    artifact = 5
    complete = 6
```

Compiler phases:

```with
pub enum CompilerPhase: i32:
    parsed_all_sources = 0
    typechecked_all_available = 1
    generated_target_code = 2
    pre_link = 3
    post_link = 4
    complete = 5
```

Required operations:

```with
pub fn BuildCtx.begin_intercept(self: &Self, workspace: Workspace)
pub fn BuildCtx.wait_for_message(self: &Self, workspace: Workspace) -> CompilerMessage
pub fn BuildCtx.end_intercept(self: &Self, workspace: Workspace)
```

This supports build-time tools that inspect project code, generate source after
typechecking, or enforce project rules.

---

## 13. Project Introspection

`std.compiler.ProjectInfo` is the stable user-facing model for compiler
introspection.

Build code and compiler hooks may inspect:

- modules;
- imports;
- functions;
- types;
- fields;
- attributes;
- source locations;
- public/private visibility;
- typed signatures.

Build code must not depend on raw internal AST node layouts. Internal nodes may
change; `ProjectInfo` is the compatibility layer.

---

## 14. Code Generation During Build

Build code may add generated source to a workspace before compilation or after
an interception phase.

Supported forms:

```with
pub fn Build.generated_source(self: Build, path: str, contents: str) -> Build
pub fn BuildCtx.add_source_string(self: &Self, workspace: Workspace, name: str, source: str)
pub fn BuildCtx.add_source_file(self: &Self, workspace: Workspace, path: str)
```

Generated source must be visible in diagnostics using the declared path/name.

Invalid generated source must produce normal parser/sema diagnostics and fail
the build.

---

## 15. Process Operations

The build system should minimize external process use, but some operations are
legitimate:

- invoking the freshly built program in a test;
- invoking system `cc` or LLVM tools until they are fully internalized;
- invoking `curl`/download functionality only through a typed download API;
- executing upstream test binaries such as `pcre2test`.

Process execution must use typed APIs:

```with
pub type ProcessSpec {
    executable: str,
    args: Vec[str],
    cwd: str,
    env: Vec[EnvVar],
    timeout_ms: i64,
    capture_stdout: bool,
    capture_stderr: bool,
}

pub fn BuildCtx.run_process(self: &Self, spec: ProcessSpec) -> ProcessResult
```

No API should accept a shell command string as the primary interface. If shell
execution is ever exposed, it must be named explicitly, marked unsafe/tool-only,
and forbidden for compiler repository build logic.

---

## 16. Filesystem Operations

Tool mode needs typed filesystem operations:

```with
pub fn BuildCtx.read_text(path: str) -> Result[str, FsError]
pub fn BuildCtx.read_binary(path: str) -> Result[Vec[u8], FsError]
pub fn BuildCtx.write_text(path: str, contents: str) -> Result[void, FsError]
pub fn BuildCtx.write_binary(path: str, bytes: Vec[u8]) -> Result[void, FsError]
pub fn BuildCtx.mkdir_all(path: str) -> Result[void, FsError]
pub fn BuildCtx.remove_tree(path: str) -> Result[void, FsError]
pub fn BuildCtx.copy_file(src: str, dst: str) -> Result[void, FsError]
pub fn BuildCtx.copy_tree(src: str, dst: str) -> Result[void, FsError]
pub fn BuildCtx.rename(src: str, dst: str) -> Result[void, FsError]
pub fn BuildCtx.symlink(src: str, dst: str) -> Result[void, FsError]
pub fn BuildCtx.glob(pattern: str) -> Result[Vec[str], FsError]
```

All write operations must normalize paths. Operations that would escape the
project root or output root require an explicit capability.

---

## 17. Downloads and External Sources

Downloaded external sources are build inputs, not source-tree staging.

Required API:

```with
pub type Download {
    url: str,
    sha256: str,
    output_path: str,
}

pub fn Build.download(self: Build, name: str, spec: Download) -> Build
pub fn Build.extract_tar_gz(self: Build, name: str, archive: str, output_dir: str) -> Build
```

Downloads must go under `out/` by default. A missing checksum is allowed only
for explicitly marked development workflows and must print a warning.

For the compiler repository, PCRE2 release sources must be downloaded and
extracted under `out/`.

---

## 18. Tests

The integrated build system must support the existing With test classes:

- behavior tests;
- compile-error tests;
- CLI selfhost tests;
- regression tests requiring temp projects;
- generated-code tests;
- external corpus tests such as PCRE2.

Test target model:

```with
pub type TestOptions {
    timeout_ms: i64,
    expected_exit_code: i32,
    expected_stdout: str,
    expected_stderr_contains: str,
    compile_error: bool,
    run: bool,
    isolate_temp_dir: bool,
}
```

A test target may compile one file, a glob, or a generated test workspace.

Compile-error tests must assert diagnostics intentionally. They must not pass
just because compilation failed for an unrelated reason.

---

## 19. Repository Locking

The compiler repository has shared mutable build output under `out/`. The
integrated build system must provide a repository lock equivalent to the
current Make lock.

Required behavior:

- one top-level mutating build action at a time;
- owner metadata contains target name, pid, and start time;
- stale lock diagnosis is explicit;
- nested graph execution inside one top-level action does not deadlock.

---

## 20. Incrementality

The driver must track declared inputs and outputs for graph nodes.

Initial acceptable implementation:

- deterministic stamps under `out/gen` or `out/build`;
- content hashes for generated source;
- explicit dependency lists;
- loud failure for undeclared output conflicts.

Longer-term implementation:

- content-addressed build cache;
- stable graph serialization;
- parallel scheduling of independent nodes.

The build must prefer correctness over clever caching. A stale artifact is a
build-system bug.

---

## 21. Installing and Promoting Artifacts

Install operations are first-class graph nodes.

Examples:

```with
b.install_binary("user-with", "out/bin/with", "~/.local/bin/with")
b.install_tree("runtime", "out/bin/runtime", "~/.local/bin/runtime")
b.promote_tree("pcre2", "out/pcre2_build/lib/std/re", "lib/std/re")
```

Install nodes may write outside the project only through explicit install
capabilities.

Compiler seed updates require stronger rules:

- build must pass;
- fixpoint must pass;
- test suite must pass;
- the source state should be committed before seed/user compiler update.

The driver must make unsafe install/update-seed operations difficult to run
accidentally.

---

## 22. Compiler Repository Build Targets

The compiler repository's `build.w` should eventually define at least:

```with
pub fn build(ctx: BuildCtx) -> Build              // canonical compiler build
pub fn stage1(ctx: BuildCtx) -> Build
pub fn stage2(ctx: BuildCtx) -> Build
pub fn stage3(ctx: BuildCtx) -> Build
pub fn runtime(ctx: BuildCtx) -> Build
pub fn fixpoint(ctx: BuildCtx) -> Build
pub fn test(ctx: BuildCtx) -> Build
pub fn regex_migrate(ctx: BuildCtx) -> Build
pub fn regex_build(ctx: BuildCtx) -> Build
pub fn regex_test(ctx: BuildCtx) -> Build
pub fn regex_promote(ctx: BuildCtx) -> Build
pub fn install_user(ctx: BuildCtx) -> Build
pub fn clean(ctx: BuildCtx) -> Build
```

The graph must preserve bootstrap ordering:

1. seed builds stage1;
2. stage1 builds stage2;
3. stage2 builds stage3;
4. stage2 and stage3 fixpoint outputs compare byte-identically;
5. only verified stage2 becomes canonical/user-installed.

Runtime/link changes must still obey bootstrap safety rules. The build system
does not remove the need for staged commits and fixpoint checks.

---

## 23. PCRE2 Build Flow

The PCRE2 flow should be represented directly in `build.w`:

1. download PCRE2 release tarball under `out/`;
2. extract to `out/pcre2_reference/pcre2-<version>`;
3. run `with migrate` with explicit include paths, defines, excluded sources,
   and output directory;
4. fail if migration omits unallowed constructs;
5. build generated PCRE2 With sources;
6. build `pcre2test`;
7. run the full upstream 8-bit corpus and heap corpus;
8. promote generated sources to `lib/std/re` only when all checks pass.

The generated file count may be a sanity check, but it is not proof of
correctness. Correctness is corpus execution and absence of silent migrator
fallbacks.

---

## 24. Diagnostics

Build diagnostics must include:

- build target name;
- graph node name;
- source location in `build.w` when available;
- workspace name;
- underlying compiler diagnostic when available;
- command/process exit code when applicable;
- path of any artifact that failed to build.

Example:

```
error: build target 'regex-test' failed
 --> build.w:81:9
  |
81 |     b.regex_test(...)
  |         ^^^^^^^^^^
  = pcre2test exited with code 1
  = output: out/pcre2_test/testoutput8/testoutput6
```

The driver must not replace detailed diagnostics with generic text such as
`build failed`.

---

## 25. Failure Semantics

These are hard requirements:

- unsupported graph node kind: fail;
- unsupported target platform: fail;
- missing generated file: fail;
- empty test glob: fail;
- duplicate output path: fail;
- untranslated migrator construct: fail unless explicitly allowed;
- missing external tool: fail with tool name and expected path/search policy;
- failed process: fail with exit code and captured stderr summary;
- failed install: fail and leave source tree untouched.

No build step may create placeholder output to make later steps compile.

---

## 26. CLI

Required commands:

```
with build
with build :target
with test
with clean
with install-user
```

Compiler-repository aliases may map to build targets:

```
with build :stage1
with build :stage2
with build :stage3
with build :fixpoint
with build :regex-migrate
with build :regex-build
with build :regex-test
with build :regex-promote
```

CLI flags:

```
--target <target>
--release
--debug
--out <path>
--verbose
--dry-run
--graph
--explain <target>
```

`--dry-run` prints the graph and planned actions without mutating files.

`--graph` prints a stable graph format useful for debugging and tests.

---

## 27. Relationship to Compiler Hooks

Compiler hooks and build files solve different problems.

`build.w` constructs and executes build graphs.

`@[compiler_hook(...)]` inspects or augments a specific compilation workspace.

Build code may create workspaces whose source uses compiler hooks. Hook
execution remains scoped to that workspace and must not recursively execute
while compiling hook runners.

---

## 28. Security and Capability Boundaries

Tool-mode code is trusted project code, but capabilities should still be
explicit.

Default permissions:

- read project tree;
- read compiler installation/runtime resources;
- write `out/`;
- spawn compiler-owned tool processes;
- run produced test binaries.

Explicit capabilities required:

- write outside project or `out/`;
- install to user/global paths;
- update seed compiler;
- access network;
- execute arbitrary external process.

For the compiler repository, network access is allowed for the PCRE2 download
target only through the typed download API.

---

## 29. Current-Host Implementation Policy

For the next phase, the implementation may only execute on the current
developer host as long as unsupported paths fail loudly. This is an
implementation staging rule, not a platform preference.

Required current-host support while the active host is macOS:

- Darwin AArch64 host compiler build;
- Darwin runtime object graph;
- local LLVM/Clang bridge discovery;
- fiber assembly/core runtime;
- PCRE2 migration/build/test flow;
- install-user into `~/.local/bin`.

Allowed temporary behavior:

- Linux/Windows targets represented in enums but not executable;
- cross-target graph nodes rejected before action execution;
- non-Darwin runtime object recipes diagnosed as not implemented.

This policy is temporary. It must not leak silent host assumptions or
Mac-specific preferences into public APIs.

---

## 30. Migration Plan

Replacing Make must happen after the equivalent With build graph exists and is
verified.

Recommended order:

1. Add missing tool-mode filesystem, process, download, archive, and artifact
   APIs.
2. Add graph node types for object files, archives, generated binary files,
   install, clean, and group targets.
3. Port runtime object generation into `build.w`.
4. Port embedded runtime object generation out of shell.
5. Port stage1/stage2/stage3/fixpoint graph construction.
6. Port the test harness into typed With test targets.
7. Port PCRE2 download/migrate/build/test/promote.
8. Port install-user and seed-update safety checks.
9. Make Make call `with build :...` as a compatibility shim.
10. Remove Make only after `with build`, `with build :fixpoint`, and
    `with build :test` are the authoritative paths.

At every step, the old path and new path must be comparable. If outputs differ,
the difference must be explained before continuing.

---

## 31. Current Make Parity API Checklist

The following operations are required because the current Makefile and live
shell scripts perform them today. They must exist as named graph nodes,
compiler-driver APIs, or standard build helpers before Make can be removed.

These names are specification names. The implementation may choose slightly
different surface names, but the capability must remain explicit and testable.

### `binary_compare` / `fixpoint_compare`

Compare two generated artifacts byte-for-byte.

Required for:

- stage2/stage3 fixpoint object comparison;
- detecting nondeterministic code generation;
- validating generated/promoted artifacts when needed.

Failure must report both paths and the first differing offset when available.

### `compile_c_object`

Compile a C source file to an object file using the configured host C compiler.

Required for:

- bridge objects that still live in C;
- temporary compatibility paths during runtime migration;
- generated C fixtures used by tests.

Inputs must include source path, output path, include paths, defines, target,
SDK/sysroot, and extra compiler flags as structured fields. The API must not
accept one shell command string.

### `compile_asm_object`

Compile an assembly source file to an object file.

Required for:

- fiber assembly;
- generated embedded-object assembly;
- any platform startup/runtime assembly.

The operation must choose the correct assembler/compiler path from the target
toolchain and fail loudly for unsupported host/target combinations.

### `compile_llvm_ir_object`

Compile LLVM IR or bitcode to an object file.

Required for:

- current `regex_runtime.ll` flow;
- future compiler-generated IR tests;
- bridge paths that intentionally inspect or preserve LLVM IR.

Inputs must include IR path, output object path, target triple when known,
optimization mode, and LLVM toolchain selection.

### `create_static_archive`

Create a deterministic static archive from object files.

Required for:

- library targets;
- runtime object grouping;
- generated C/With mixed libraries.

Archive member order must be deterministic. Duplicate member names or missing
inputs must be diagnostics.

### `generate_response_file`

Write a response file from a deterministic list of linker or compiler
arguments.

Required for:

- LLVM bridge link arguments;
- long linker command lines;
- reproducible stage builds.

The response file node must declare both the logical argument list and the
output path. It must not be assembled through ad hoc string concatenation in
user build code.

### `embed_object_files`

Embed a set of object files into a generated object or assembly file that the
compiler can link into itself.

Required for:

- replacing `scripts/embed_runtime_objects.sh`;
- embedding runtime objects into the compiler binary;
- extracting embedded runtime files for user-program linking.

Inputs must be explicit object paths with stable logical names. Output must be
deterministic across runs.

### `copy_tree`

Copy a declared file tree from one build location to another.

Required for:

- `install`;
- `install-user`;
- embedded runtime extraction tests;
- compiler distribution layout.

The operation must preserve executable bits where relevant and must remove or
replace stale files deterministically.

### `run_corpus_test`

Run an external corpus test suite with declared inputs, expected outputs, and
timeouts.

Required for:

- PCRE2 upstream corpus;
- PCRE2 heap corpus;
- future large compatibility suites.

The operation must capture stdout/stderr, preserve failing output files, report
the failing corpus case when possible, and distinguish timeout, crash, and
output mismatch.

### `promote_tree_if_verified`

Copy a generated tree into a source-controlled destination only after declared
verification dependencies have passed.

Required for:

- promoting generated PCRE2 sources into `lib/std/re`;
- future generated stdlib modules;
- avoiding accidental promotion of unverified generated output.

Promotion must fail if verification dependencies are absent, stale, or failed.
It must report every source-controlled path it changes.

---

## 32. Example: Simple Project

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    ctx.new_build().executable("hello", "src/main.w")
```

Run:

```
with build
```

---

## 33. Example: Generated Source

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.generated_source(
        "out/gen/version.w",
        "pub fn version -> str:\n    \"dev\"\n",
    )
    out.executable("app", "src/main.w")
```

---

## 34. Example: Multiple Targets

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.executable("server", "src/server.w")
    out = out.executable("tool", "src/tool.w")
    out = out.test("unit", "tests/*.w")
    out
```

---

## 35. Example: Compiler-Style Staged Build

This is illustrative; exact API names may change as the implementation lands.

```with
use std.build

pub fn compiler(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    let generated = generate_versioned_entry("out/gen/main.w", "src/main.w")
    out = out.generated_source(generated.path, generated.contents)
    out = out.tool("stage1", compiler: .seed, entry: generated.path)
    out = out.tool("stage2", compiler: .target("stage1"), entry: generated.path)
    out = out.tool("stage3", compiler: .target("stage2"), entry: generated.path)
    out = out.fixpoint("fixpoint", "stage2", "stage3")
    out
```

The actual implementation should use typed graph nodes rather than stringly
references where possible.

---

## 36. Acceptance Criteria

The integrated build system is complete enough to replace Make for this
repository when all of these pass without invoking Make or repository shell
scripts:

```
with build :compiler
with build :fixpoint
with build :test
with build :regex-migrate
with build :regex-build
with build :regex-test
with build :install-user
```

and:

- the produced compiler passes fixpoint;
- the full test suite passes;
- the full PCRE2 corpus passes;
- the generated/promoted regex stdlib is byte-for-byte explainable;
- no silent migrator fallback is used;
- no Python, Perl, Make, or shell script is required for the compiler build.
- every operation in the Current Make Parity API Checklist is implemented or
  has been made unnecessary by a deeper compiler/build-system change.
