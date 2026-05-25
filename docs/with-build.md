# With Projects

Status: current user documentation.

This document describes how to create, configure, and build With projects.
The formal build system contract is [build-spec.md](build-spec.md).

---

## Overview

A With project uses up to two configuration files:

```text
with.toml  declarative package metadata, dependencies, and settings
build.w    executable build behavior (optional)
```

Most projects need only `with.toml`. Reach for `build.w` when you need
custom build targets, C library integration, code generation, asset
pipelines, or multi-binary builds.

---

## Getting Started

### Create a Project

```sh
with init my_app
cd my_app
with build
with run main.w
```

This produces:

```
my_app/
  main.w
  with.toml
  build.w
  README.md
  AGENTS.md
  CLAUDE.md
  .gitignore
  test/
    test_main.w
```

`with init` also runs `git init` if git is available (fails silently if not).

Options:

```sh
with init              # init in current directory, name from dirname
with init my_app       # create my_app/ directory
with init --lib        # library project (lib.w, no main)
with init --name foo   # override project name
```

---

## with.toml

`with.toml` is the package manifest. It declares identity, dependencies,
and settings. It does not contain imperative logic.

### Package Identity

```toml
[package]
name = "my_app"
version = "0.1.0"
```

The `name` field is required. It determines the default binary name and
the package identifier for dependency resolution.

### Dependencies

With has two dependency sources:

- **With packages** — `with get json`, `with get http`
- **C packages** — `with get c.glib`, `with get c.sqlite3`

The `c.` prefix routes through Conan Center. With packages come from the
With package registry.

```toml
[package]
name = "my_app"
version = "0.1.0"

[deps]
json = "1.2"
c.glib = "2.78"
c.sqlite3 = "3.45"
```

#### Adding Dependencies

```sh
with get json              # add a With package
with get c.glib            # add a C package (latest stable)
with get c.glib@2.78       # pin a specific version
with get                   # restore all deps from lock file
```

`with get c.X` resolves the package, downloads headers, prebuilt libraries,
and transitive deps into `.with/deps/c/<name>/<version>/`, and updates
`with.toml`.

#### Removing and Updating

```sh
with remove c.glib         # remove dependency
with update                # update all deps to latest compatible
with update c.glib         # update one dep
```

#### Manual C Dependencies

For libraries not in Conan, specify paths directly:

```toml
[deps.c.custom_lib]
include = "/opt/custom/include"
lib = "/opt/custom/lib"
link = ["custom"]
```

#### Build Integration

When `with build` encounters `use c_import("<glib.h>")`, the compiler reads
`with.toml`, finds all `c.*` deps, reads their `metadata.json`, and passes
include and link paths automatically. You never write `-I` or `-l` flags.

If auto-resolution picks the wrong library:

```with
use c_import("<glib.h>", link: "glib-2.0", "gio-2.0")
```

#### Directory Structure

```
.with/
├── deps/c/<name>/<version>/   # headers + libraries
├── cache/c_import/            # c_import translation cache
└── lock.json                  # exact version pins
```

`.with/` is gitignored. `with.toml` and `lock.json` are committed.

### Build Settings

```toml
[build]
overflow = "panic"       # "panic" (default), "wrap", or "saturate"
```

### Runtime Configuration

```toml
[runtime]
fiber_stack_size = "64KB"
fiber_initial_stack = "8KB"
fiber_pool_size = 1024
```

### Freestanding Mode

For embedded, kernel, and bare-metal targets:

```toml
[package]
name = "my-firmware"
std = false
```

Three tiers:

| Tier | Config | What you get |
|------|--------|--------------|
| Full | `std = true` (default) | Everything |
| Alloc | `std = false`, `alloc = true` | `core` + heap types |
| Freestanding | `std = false` | `core` only — no heap |

With `alloc = true`, you get `Vec[T]`, `Box[T]`, `str`, `HashMap`, and
`HashSet` without I/O or OS features. Provide a `@[global_allocator]` to
back the heap.

### What Belongs in with.toml

Allowed:

- Package identity (name, version)
- Dependencies and version constraints
- Target defaults and feature flags
- C include paths, defines, link libraries
- Publishing metadata and lint/runtime policy
- Build settings (overflow, optimization defaults)

Not allowed:

- Conditionals or loops
- Generated-file steps
- Asset pipelines or shader compilation
- Custom shell commands
- Target graph construction
- Platform-specific branching logic

Those belong in `build.w`.

---

## Command Line

### Project Builds

```sh
with build               # build the default target
with build :target       # build a named target
with build --graph       # print the stable graph format
with build --dry-run     # print planned actions, don't execute
with build :action --no-deps  # run one action without deps (debugging)
```

`with build` searches upward for `build.w` or `with.toml`. If `build.w`
exists, the driver evaluates it and executes the returned graph. If no
`build.w` exists, the driver synthesizes a default build of `src/main.w`.

### Direct Source Builds

Direct source builds bypass `build.w`:

```sh
with build src/main.w
with build src/main.w -o out/bin/app
with build src/main.w --emit-obj -o out/main.o
with build src/main.w --emit-c -o out/main.c
```

### Test and Run

```sh
with test                # run the test target
with run src/main.w      # compile and run
with clean               # clean build artifacts
```

### Common Flags

```text
-O0, -O1, -O2, -O3     optimization level
--release               at least -O2, no debug info
-g0                     disable debug info
--no-std                freestanding build
--freestanding          alias for --no-std
--prelude=none          no prelude
--prelude=core          core prelude
--prelude=full          full prelude (default)
--emit-obj              emit object file
--emit-c                emit C (cross-compilation)
-o <path>              output path (direct source builds)
```

### Parallel Test Jobs

Build graph `Test` targets run test files in parallel batches.
Set `WITH_BUILD_TEST_JOBS=N` to control batch size (default 4, max 32).

---

## build.w

`build.w` is executable build behavior written in With. It runs as
capability-bearing comptime code — the driver passes unforgeable capability
handles that grant filesystem, process, and compiler access.

### Entry Point

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build().executable("my_app", "main.w")
    out = out.test("test", "test/*.w")
    out.default("my_app")
```

The driver evaluates `build`, receives the typed build graph, validates it,
selects the requested target closure, and executes it.

### Default Recipe

If no `build.w` exists but `main.w` (or `src/main.w`) does, the driver
synthesizes:

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    let info = ctx.project_info()
    ctx.new_build().executable(info.package_name(), "main.w")
```

---

## Capabilities

Build code can only perform effects through driver-minted capabilities.

### BuildCtx

Top-level capability providing access to narrower capabilities:

```with
let info = ctx.project_info()      // ProjectInfo
let build = ctx.new_build()        // Build graph
let diag = ctx.diagnostics()       // Diagnostics
let emitter = ctx.source_emitter() // SourceEmitter
let fs = ctx.fs()                  // ToolFs
let proc = ctx.process_runner()    // ProcessRunner
let ws = ctx.create_workspace("name") // Workspace
```

### ProjectInfo

```with
info.package_name()     // str
info.package_version()  // str
info.project_root()     // str
```

### ToolFs

Sandboxed filesystem rooted at the project root. Only project-relative
paths are accepted; absolute paths and `..` escapes fail loudly.

```with
let fs = ctx.fs()
fs.mkdir_all("out/gen")
fs.write_text("out/gen/config.w", "pub let version = \"0.1.0\"\n")
let text = fs.read_text("out/gen/config.w")
let exists = fs.exists("src/main.w")
```

Available operations: `read_text`, `write_text`, `exists`, `is_dir`,
`mkdir_all`, `remove_file`, `remove_tree`, `copy_tree`, `rename`, `chmod`,
`list_files`, `host_list_files` (absolute paths), `host_exists` (absolute paths).

### ProcessRunner

Runs external tools with argv. No shell command strings.

```with
let proc = ctx.process_runner()
let args: Vec[str] = Vec.new()
args |> push("tool")
args |> push("--version")
let result = proc.run_capture(args, "out/tool.stdout", "out/tool.stderr", 30000)
if result.rc != 0:
    ctx.diagnostics().error("tool failed")
```

### Diagnostics

```with
let diag = ctx.diagnostics()
diag.warn("something looks off")
diag.error("fatal: missing required file")  // exits nonzero
```

### SourceEmitter

Creates generated-source graph entries:

```with
let emitter = ctx.source_emitter()
let source = emitter.generated_source("out/gen/config.w", "pub let answer = 42\n")
var build = ctx.new_build()
build = build.add_generated_source(source)
```

### Workspace

Compiles, checks, or inspects With source without spawning a subprocess:

```with
let ws = ctx.create_workspace("check")
ws.add_string("generated.w", "fn f -> i32: 7\n")
var options = ws.options()
options.output_kind = BuildOutputKind.Check
ws.set_options(options)
let result = ws.compile()
```

Workspace supports a typed message intercept for build-time introspection:

```with
ws.begin_intercept()
let result = ws.compile()
while true:
    let envelope = ws.wait_for_message()
    match envelope.message:
        CompilerMessage.Complete(done) => break
        CompilerMessage.Error(_, msg, _) => ctx.diagnostics().error(msg)
        _ => false
ws.end_intercept()
```

---

## Target Construction

### Convenience Methods

```with
var out = ctx.new_build()
out = out.executable("app", "src/main.w")
out = out.library("mylib", "src/lib.w")
out = out.test("test", "tests/*.w")
out.default("app")
```

### Full Control

```with
var target = target_new(.Executable, "app", "src/main.w")
target = target.optimize(.release)
target = target.include_path("include")
target = target.define("WITH_FEATURE=1")
target = target.link_system_lib("m")
target = target.output("out/bin/app")
target = target.dep("generate")

var build = ctx.new_build()
build = build.add_target(target)
```

### Target Modifiers

```with
target.output("out/bin/app")       // output path
target.input("path")               // declared input
target.extra_output("path")        // additional output file/dir
target.write_scope("directory")    // broader write root
target.dep("other-target")         // dependency
target.arg("value")                // action-specific argument
target.compiler("out/bin/with")    // compiler override
target.target(.darwin_aarch64)     // cross-platform target
target.optimize(.release)          // optimization mode
```

---

## Standard Target Kinds

### Product Targets

| Kind | Description |
|------|-------------|
| `Executable` | Build an executable from With source |
| `Library` | Build a static library from With source |
| `Object` | Build an object file from With source |
| `Archive` | Build a static archive from With source |

### Test and Verification

| Kind | Description |
|------|-------------|
| `Test` | Compile and run With tests (single file or `*.w` glob) |
| `BinaryCompare` | Compare two files byte-for-byte |
| `FixpointCompare` | Compare two files as a codegen fixpoint |
| `RunCorpusTest` | Run a tool with captured stdout/stderr |

### Toolchain Targets

| Kind | Description |
|------|-------------|
| `CompileCObject` | Compile C source to an object file |
| `CompileAsmObject` | Assemble source to an object file |
| `CompileLlvmIrObject` | Compile LLVM IR to an object file |
| `CreateStaticArchive` | Create a static archive from objects |
| `GenerateResponseFile` | Write an argv response file |
| `EmbedObjectFiles` | Embed binary data as assembly symbols |

### Filesystem and Installation

| Kind | Description |
|------|-------------|
| `Install` | Copy/install an artifact |
| `Clean` | Remove declared artifact paths |
| `CopyFile` | Copy a single file |
| `CopyTree` | Copy a directory tree |
| `PromoteTreeIfVerified` | Promote output after verification passes |

### Composition

| Kind | Description |
|------|-------------|
| `Group` | Aggregate target (like a Make phony target) |
| `Command` | Argv-based external command |
| `Action` | Project-local With function as a graph target |

---

## Project-Local Actions

Use `Action` for build steps specific to your project:

```with
use std.build

fn generate(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    fs.mkdir_all("out/gen")
    if fs.write_text(ctx.output(), "pub let generated = true\n") != 0:
        ctx.diagnostics().error("failed to write")
        return 1
    0

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build()
    var gen = target_new(.Action, "generate", "").output("out/gen/generated.w")
    gen.action = generate
    out = out.add_target(gen)
    out = out.executable("app", "src/main.w").dep("generate")
    out.default("app")
```

`ActionCtx` provides: `target_name()`, `project_info()`, `diagnostics()`,
`fs()`, `process_runner()`, `inputs()`, `outputs()`, `args()`, `output()`.

Action filesystem writes are restricted to declared outputs. Use
`target.extra_output(path)` for additional files the action creates.

---

## Examples

### Executable Plus Tests

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build().executable("app", "src/main.w")
    out = out.test("test", "tests/*.w")
    out.default("app")
```

### Library

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build()
    out = out.library("mylib", "src/lib.w")
    out = out.test("test", "tests/*.w")
    out.default("mylib")
```

### C Interop

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var app = target_new(.Executable, "app", "src/main.w")
    app = app.include_path("include")
    app = app.define("WITH_FEATURE=1")
    app = app.link_system_lib("m")
    ctx.new_build().add_target(app).default("app")
```

### Generated Source

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
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

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build()
    out = out.executable("app", "src/main.w")
    out = out.test("test", "tests/*.w")

    var check = target_new(.Group, "check", "")
    check = check.dep("app")
    check = check.dep("test")
    out = out.add_target(check)
    out.default("check")
```

---

## Cross-Platform Targets

```with
BuildTarget.native
BuildTarget.linux_x86_64
BuildTarget.linux_aarch64
BuildTarget.darwin_x86_64
BuildTarget.darwin_aarch64
BuildTarget.windows_x86_64
```

Unsupported targets fail loudly. The language design does not privilege one
operating system over another.

---

## Safety Rules

- Use typed targets and capabilities instead of shell recipes.
- Use project-relative paths with `ToolFs`.
- Declare dependencies with `Target.dep`.
- Fail loudly with `Diagnostics.error` or a nonzero return.
- Do not emit placeholder generated code to hide unsupported behavior.
- Keep project-specific policy in project `build.w`, not in `std.build`.
