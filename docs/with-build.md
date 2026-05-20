# With Build

Status: current user documentation.

This document describes the build system that is implemented today. The formal
contract is [build-spec.md](build-spec.md); implementation sequencing lives in
[build-plan.md](build-plan.md).

With projects can describe their build in With source using two files:

```text
with.toml  declarative package metadata
build.w    executable build behavior
```

The compiler driver discovers `build.w`, runs it with driver-minted build
capabilities, receives a typed build graph, and executes that graph. Ordinary
projects do not need Makefiles or shell scripts for normal builds.

Implementation note: current releases execute `build.w` and action functions
through generated runner binaries. Phase D is replacing that internal path with
capability-bearing comptime evaluation inside the driver. The public API is the
same either way: `pub fn build(ctx: BuildCtx) -> Build`, `ActionCtx` for action
targets, typed graph nodes, and explicit capabilities.

## Quick Start

Create a project:

```sh
with init my_app
cd my_app
with build
with run src/main.w
with build :test
```

A minimal executable project looks like this:

```text
my_app/
  with.toml
  build.w
  src/main.w
  tests/smoke.w
```

`with.toml` contains package identity:

```toml
[package]
name = "my_app"
version = "0.1.0"
```

`build.w` declares the build graph:

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build().executable("my_app", "src/main.w")
    var tests = target_new(.Test, "test", "tests/*.w")
    out = out.add_target(tests)
    out.default("my_app")
```

Then:

```sh
with build        # builds the default target
with build :test  # runs the target named "test"
```

## Command Line

### Project Builds

From a project directory:

```sh
with build
with build :target
with build --graph
with build --dry-run
with build :action --no-deps
```

`with build` searches upward from the current directory for `build.w` or
`with.toml`. If `build.w` exists, the driver invokes its `build(ctx)` entry
point and executes the returned graph. If no `build.w` exists, the driver falls
back to a default build of `src/main.w` using the package name from
`with.toml`.

`:target` selects a target by name from the graph returned by `build.w`.

`--graph` prints the stable graph format for the discovered project build.

`--dry-run` currently prints the selected graph without executing it.

`--no-deps` is an action-iteration flag. It may be used only with an explicit
`Action` target, and runs that action target without expanding declared
dependencies or producer edges:

```sh
with build :pcre2-migrate --no-deps
```

Normal builds should not use this flag. It assumes required inputs already
exist and is intended for debugging or iterating on one action body.

Build graph `Test` targets that run through an external compiler execute test
files in parallel batches. Set `WITH_BUILD_TEST_JOBS=N` to control the batch
size; the default is 4 and the maximum is 32.

### Direct Source Builds

The build command still supports direct source files:

```sh
with build src/main.w
with build src/main.w -o out/bin/app
with build src/main.w --emit-obj -o out/main.o
with build src/main.w --emit-c -o out/main.c
```

These paths bypass `build.w` and compile the named source file directly.

### Common Flags

```text
-O0, -O1, -O2, -O3     optimization level
--release              at least -O2 and no debug info
-g0                    disable debug info
--no-std               freestanding build
--freestanding         alias for --no-std
--prelude=none         no prelude
--prelude=core         core prelude
--prelude=full         full prelude
--emit-obj             emit object file
--emit-c               emit C
-o <path>              output path for direct source builds
```

For build graph targets, `-o` is only valid where the selected target kind
supports an explicit output override. It cannot be used with test targets.

## The Build Function

A build file exposes:

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    ...
```

The compiler driver constructs `BuildCtx`. User code cannot construct
`BuildCtx` or other tool capabilities directly. The build function returns a
`Build`, which is a typed graph of targets, generated sources, dependencies,
and package metadata.

`build.w` is ordinary With code except that the driver invokes it with
unforgeable capabilities. Capability-bearing functions are compile-time tool
entry points; they cannot be called from runtime code with forged handles.

## Tool Mode

Tool mode is the privileged build-driver environment. Privilege is explicit:
build code can perform effects only through capabilities passed by the driver.

The currently exposed build capabilities are:

```text
BuildCtx        top-level build entry capability
ProjectInfo     package name, version, and project root
Diagnostics     warnings and fatal errors
SourceEmitter   generated-source construction
ToolFs          sandboxed project-relative filesystem operations
ProcessRunner   argv-based external process capture
ActionCtx       action-target invocation context
```

Capability values are driver-minted handles. User code may receive, pass, and
call methods on them, but may not construct or deserialize production
capabilities. The current runner path uses validation tokens internally; Phase
D is moving that validation into the evaluator capability store. Build code
should not depend on either representation.

### BuildCtx

`BuildCtx` gives access to package information and narrower capabilities:

```with
let info = ctx.project_info()
let build = ctx.new_build()
let diagnostics = ctx.diagnostics()
let source_emitter = ctx.source_emitter()
let fs = ctx.fs()
let process = ctx.process_runner()
```

### ProjectInfo

```with
info.package_name()
info.package_version()
info.project_root()
```

`project_root()` is the driver-discovered project root.

### ActionCtx

`ActionCtx` is passed to `Action` target functions:

```with
ctx.target_name()
ctx.project_info()
ctx.diagnostics()
ctx.fs()
ctx.process_runner()
ctx.inputs()
ctx.outputs()
ctx.args()
ctx.output()
```

`ctx.fs()` is scoped to the action's declared output and extra outputs. If an
action needs to create additional files or directories, declare them with
`target.extra_output(path)`.

### Diagnostics

```with
diagnostics.warn("message")
diagnostics.error("message")
```

`error` prints a diagnostic and exits nonzero.

### ToolFs

`ToolFs` is rooted at the project root and accepts only project-relative paths.
Absolute paths, `..`, and control characters fail loudly.

```with
let fs = ctx.fs()
assert(fs.mkdir_all("out/gen") == 0)
assert(fs.write_text("out/gen/version.w", "pub let version = \"0.1.0\"\n") == 0)
let text = fs.read_text("out/gen/version.w")
```

This is intentional. Build files should not reach outside their project through
the standard build filesystem capability.

### SourceEmitter

`SourceEmitter` creates generated-source graph entries:

```with
let emitter = ctx.source_emitter()
let source = emitter.generated_source("out/gen/generated.w", "fn main: print(\"hi\")\n")
var build = ctx.new_build()
build = build.add_generated_source(source)
build.executable("generated-app", "out/gen/generated.w")
```

Generated source paths must be project-relative and must not escape the project
root.

### ProcessRunner

`ProcessRunner` runs external tools with argv, not shell strings:

```with
let proc = ctx.process_runner()
let args: Vec[str] = Vec.new()
args |> push("tool")
args |> push("--version")
let result = proc.run_capture(args, "out/tool.stdout", "out/tool.stderr", 30000)
if result.rc != 0:
    ctx.diagnostics().error(result.stderr)
```

Use process execution for external tools. Do not assemble shell command strings
in compiler, runtime, migrator, stdlib, or build-system code.

## Build Graph Data Model

The public graph types live in `std.build`.

```with
pub type Package {
    name: str,
    version: str,
}

pub type Build {
    package: Package,
    default_target: str,
    targets: Vec[Target],
    generated_sources: Vec[GeneratedSource],
}

pub type Target {
    kind: BuildKind,
    name: str,
    entry: str,
    output: str,
    target_kind: BuildTarget,
    optimize_mode: OptimizeMode,
    system_libs: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    inputs: Vec[str],
    extra_outputs: Vec[str],
    write_scopes: Vec[str],
    deps: Vec[str],
    args: Vec[str],
    action: fn(ActionCtx) -> i32,
}
```

The driver validates the graph, filters it by the selected target and
dependencies, then executes the selected graph.

## Target Construction

Most projects use the convenience methods on `Build`:

```with
var out = ctx.new_build()
out = out.executable("app", "src/main.w")
out = out.test("test", "tests/*.w")
out.default("app")
```

For more control, construct a `Target` and add it:

```with
var target = target_new(.Executable, "app", "src/main.w")
target = target.optimize(.release)
target = target.include_path("include")
target = target.define("WITH_FEATURE=1")
target = target.link_system_lib("m")
target = target.output("out/bin/app")

var build = ctx.new_build()
build = build.add_target(target)
```

Target modifiers are value-returning methods:

```with
target.output("out/bin/app")
target.input("path")
target.extra_output("path-or-directory")
target.write_scope("directory")
target.dep("other-target")
target.arg("value")
target.compiler("out/bin/with-stage2")
target.target(.darwin_aarch64)
target.optimize(.release)
```

`dep` names another target in the same graph. Selecting a target also runs its
dependencies. `extra_output` declares additional files or directories that an
action may create. `write_scope` grants a broader project-relative write root
when a target intentionally produces a tree of files.

## Standard Target Kinds

`BuildKind` is the public standard target vocabulary.

### Product Targets

```text
Executable       build an executable from With source
Library          build a static library from With source
Object           build an object file from With source
Archive          build a static archive from With source
```

Generated sources are graph entries, not target kinds. Use
`Build.generated_source` or `SourceEmitter.generated_source`.

### Test and Verification Targets

```text
Test              compile and run With tests
BinaryCompare     compare two files byte-for-byte
FixpointCompare   compare two files as a self-hosting/codegen fixpoint
RunCorpusTest     run a tool/program with captured stdout and stderr
```

`Test` accepts either a single file or a simple `*.w` glob.

### Toolchain Targets

```text
CompileCObject       compile C source to an object
CompileAsmObject     compile assembly source to an object
CompileLlvmIrObject  compile LLVM IR to an object
CreateStaticArchive  create a static archive
GenerateResponseFile write an argv response file
EmbedObjectFiles     embed object files as assembly data
```

These are low-level build primitives. They are standard because ordinary With
projects may need to link C, assembly, LLVM IR, archives, or embedded binary
assets.

### Filesystem and Installation Targets

```text
Install                 copy/install an artifact
Clean                   remove declared artifacts safely
CopyFile                copy a single file
CopyTree                copy a directory tree
PromoteTreeIfVerified   promote generated output after verification
```

`Clean` is a standard graph node, but each project declares its own artifact
paths.

### Composition Targets

```text
Group    aggregate target with dependencies
Command  argv-based external command target
```

`Group` is the build graph equivalent of a Make phony target.

`Command` is an escape hatch for external tools. It is still argv-based, not a
raw shell recipe.

### Project-Local Actions

```text
Action  run a project-local With function as a graph target
```

Use `Action` when a build step is specific to the project and should not become
a compiler-driver target kind.

```with
use std.build

fn generate(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    assert(fs.mkdir_all("out/gen") == 0)
    if fs.write_text(ctx.output(), "pub let generated = true\n") != 0:
        ctx.diagnostics().error("failed to write generated source")
        return 1
    0

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    var gen = target_new(.Action, "generate", "").output("out/gen/generated.w")
    gen.action = generate
    out = out.add_target(gen)
    out = out.executable("app", "src/main.w")
    out.default("app")
```

Action functions can live in `build.w` or in project-local modules imported by
`build.w`. Keep reusable build-system abstractions in `std.build`; keep
project policy, file lists, generated-source rules, and migration commands in
the project build files.

Action functions receive `ActionCtx`, which exposes the target name, project
metadata, diagnostics, process runner, declared inputs, declared outputs, and a
scoped project filesystem capability. Declared inputs and outputs are part of
the graph contract: missing declared inputs fail before the action runs, action
filesystem writes are restricted to declared outputs, and the driver verifies
that every declared output exists after a successful action. Use
`target.extra_output(path)` for additional files or directories the action is
allowed to create.

Selecting a target that depends on an action runs the action first:

```with
var gen = target_new(.Action, "generate", "").output("out/gen/generated.w")
gen.action = generate

var app = target_new(.Executable, "app", "src/main.w")
app = app.dep("generate")
```

## Build Targets

Cross-platform target values exist in the API:

```with
BuildTarget.native
BuildTarget.linux_x86_64
BuildTarget.linux_aarch64
BuildTarget.darwin_x86_64
BuildTarget.darwin_aarch64
BuildTarget.windows_x86_64
```

The current implementation is Mac-first because that is the current developer
host. Non-host build targets may fail loudly. The language design does not
privilege macOS.

## Optimization

Targets can request:

```with
OptimizeMode.debug
OptimizeMode.release
```

The CLI `--release` flag raises the build optimization level to at least `-O2`
and disables debug info. Target-level `release` mode also raises the effective
optimization level for that target when needed.

## Generated Source

There are two supported generated-source paths.

Use `Build.generated_source` for simple generated files:

```with
var build = ctx.new_build()
build = build.generated_source("out/gen/config.w", "pub let answer = 42\n")
build.executable("app", "src/main.w")
```

Use `SourceEmitter.generated_source` when helper code should receive only the
source-emission capability:

```with
fn make_config(emitter: SourceEmitter) -> GeneratedSource:
    emitter.generated_source("out/gen/config.w", "pub let answer = 42\n")
```

Generated source paths are validated by the driver. They must be relative and
must not contain parent-directory escapes.

## Examples

### Executable Plus Tests

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build().executable("app", "src/main.w")
    out = out.test("test", "tests/*.w")
    out.default("app")
```

### Library

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.library("mylib", "src/lib.w")
    out = out.test("test", "tests/*.w")
    out.default("mylib")
```

### C Include Path and Define

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var app = target_new(.Executable, "app", "src/main.w")
    app = app.include_path("include")
    app = app.define("WITH_FEATURE=1")
    app = app.link_system_lib("m")

    ctx.new_build().add_target(app).default("app")
```

### Generated Source From Template

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    let fs = ctx.fs()
    let emitter = ctx.source_emitter()
    let text = fs.read_text("templates/generated.w")
    let generated = emitter.generated_source("out/gen/generated.w", text)

    var out = ctx.new_build()
    out = out.add_generated_source(generated)
    out.executable("generated-app", "out/gen/generated.w")
```

### Aggregate Target

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.executable("app", "src/main.w")
    out = out.test("test", "tests/*.w")

    var check = target_new(.Group, "check", "")
    check = check.dep("app")
    check = check.dep("test")
    out = out.add_target(check)
    out.default("check")
```

## The With Compiler Repository

The With compiler itself uses `build.w` heavily. Repository-specific actions
live in the repository `build.w` and project-local build modules, not in
`std.build` and not as compiler-dispatched project graph kinds. The generic
compiler driver executes standard graph nodes and project-local action
invocations; repository policy stays in repository build modules.

Common repository targets include:

```sh
with build :stage1
with build :stage2
with build :stage3
with build :runtime
with build :build
with build :selfcheck
with build :fixpoint
with build :test
with build :install-user
with build :pcre2-reference
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
with build :clean
```

The default `with build :test` target tests the language, compiler, build
system, standard library, and fast smoke coverage for migrated libraries and
emit-C. It does not run the full PCRE2 upstream corpus or the full emit-C
roundtrip. Heavy manual targets are explicit:

```sh
with build :pcre2-test
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
```

Run the full emit-C targets for release verification or when working on emit-C
itself. For normal compiler, stdlib, and build-system work, the default test
target includes the fast emit-C smoke.

Make remains as a repository compatibility layer for familiar stage commands
and bootstrap recovery. `with build` is the authoritative build path for new
With projects and for ongoing build-system development.

## Safety Rules

Build files and build-system code should follow these rules:

- Use typed targets and capabilities instead of shell recipes.
- Use project-relative paths with `ToolFs`.
- Declare dependencies with `Target.dep`.
- Fail loudly with `Diagnostics.error` or a nonzero target result.
- Do not emit placeholder generated code to hide unsupported behavior.
- Keep project-specific policy in project `build.w`, not in `std.build`.

## Repository Work Still In Progress

- Phase D is in progress. The current public build API is stable, but generated
  build/action runner binaries are still used internally until
  capability-bearing comptime evaluator dispatch replaces them.
- Full Jai-style compiler-as-library workspace APIs are not implemented yet.
- Cross-platform target plumbing exists, but only the current host path is
  routinely exercised.
- `Command` and low-level toolchain targets are argv/file based. Prefer typed
  target kinds and `ToolFs` operations when those exist.
- Make remains as a compatibility layer in this repository.

These are implementation gaps, not design changes. Unsupported operations
should fail loudly rather than silently falling back.
