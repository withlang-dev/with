# Archived Phase D Design (Pre-v3)

This is the only pre-v3 Phase D design committed in repository history
(`313f9bf`). The exact v2 text referenced by `docs/completed/pre-phase-d-plan.md` was
not present as a separate git revision; this archive preserves the historical
pre-review design under the required path for reference.

---

# Phase D Design: In-Process Workspaces and Message Loop

Status: implementation design. Implementation pending.

Phase D closes the gap between the current Make-parity build graph and the
Jai-style integrated compiler driver described in `docs/build-spec.md`.
The current build system can express this repository's targets, but it still
uses generated runner binaries for `build.w` and project-local actions, and it
does not expose compiler workspaces or compiler message interception to build
code. Phase D replaces that transitional machinery with in-process tool-mode
execution, compiler workspaces, a structured message loop, and stable compiler
summary APIs.

This document is the implementation contract for Phase D. It is intentionally
more concrete than the final-state spec because the first implementation slices
need exact boundaries and verification points.

## 1. Doctrine

With build code is ordinary With code executed by the compiler driver in
tool mode. Tool power is capability-based:

- discovery is by convention (`build.w`) or annotation (`@[compiler_hook]`);
- capability parameters determine what privileged operations are available;
- compiler phases determine when hooks run, not what power they have;
- ordinary `comptime` remains pure and deterministic;
- capability values are driver-minted, unforgeable handles;
- capability APIs must be safe across implementation boundaries.

The public user model must not depend on whether the compiler executes tool
code in-process, in a helper binary, or over RPC. Phase D's implementation is
in-process, but the APIs must still be boundary-safe: no raw pointer transport,
no direct access to compiler-owned data structures, and no ABI promises based
on shared address space.

## 2. Non-Goals

These items are deliberately outside Phase D:

- Jai-style `#run` as a general language feature.
- Default-metaprogram replacement for arbitrary source builds.
- Direct AST or Sema mutation from user build code.
- Raw AST handles exposed to build scripts.
- Cross-process or RPC capability transport.
- Full public package-manager integration.

Phase D may leave implementation seams that make these possible later, but it
must not implement them under another name.

## 3. D1: In-Process Tool Execution

D1 removes generated build/action runner binaries from normal build execution.
The compiler driver must invoke `build(ctx)` and selected action functions
inside the compiler process.

Current transitional behavior:

1. The driver writes `__with_build_runner.<stamp>.w`.
2. The driver compiles that source to a runner binary.
3. The driver executes the runner binary with environment capability tokens.
4. Action targets repeat the same pattern with a second generated runner.

Target behavior:

1. The driver parses, resolves, typechecks, and lowers `build.w` as tool code.
2. The driver mints a `BuildCtx` capability.
3. The driver invokes `pub fn build(ctx: BuildCtx) -> Build` through an
   in-process tool executor.
4. The returned `Build` graph remains driver-owned typed data.
5. For a selected `Action` target, the driver invokes the stored action
   function through the same in-process executor with an `ActionCtx`.

No generated action runner source files, runner binaries, exported symbols, or
subprocess calls are allowed for normal `build.w` or action dispatch after D1.

The executor may initially reuse the compiler's typed AST, MIR, or another
internal callable representation. The required property is user-visible: tool
functions are invoked in-process by the compiler driver and receive only
driver-minted capabilities.

### Function Identity

Action functions in `Build.action(name, action_fn)` must be recorded as stable
tool-mode function references, not C symbol names and not generated code
snippets. The graph serialization used for `--graph` may print an opaque
function id for diagnostics, but it must not become the execution mechanism.

### Crash Isolation

Tool-mode execution must recover enough context to produce a useful diagnostic
when a build script or action crashes:

- entry point kind: `build`, `action`, or `compiler_hook`;
- function name when known;
- target name for actions;
- source location of the entry point;
- capability operation in progress, if a capability method raised the failure;
- original runtime signal or panic text.

The driver exits non-zero. It must not silently fall back to the old generated
runner path.

### Capability Tokens

D1 may keep token validation internally, but environment variables are no
longer the transport for production in-process dispatch. Capability tokens are
driver-owned values placed directly in capability handles. Tests may still use
mock or sandboxed handles minted by the test driver.

## 4. Workspace API

A workspace is an isolated compiler environment used to compile one program,
library, object, C source output, generated source set, or tool. Workspaces own
their source set, build options, diagnostics, message queue, generated source
strings, and compilation artifacts.

Public API lives in `std.build` unless otherwise noted:

```with
pub type Workspace

pub fn BuildCtx.create_workspace(self: &Self, name: str) -> Workspace
pub fn BuildCtx.current_workspace(self: &Self) -> Workspace

pub fn Workspace.name(self: &Self) -> str
pub fn Workspace.add_file(self: &Self, path: str)
pub fn Workspace.add_string(self: &Self, name: str, source: str)
pub fn Workspace.options(self: &Self) -> BuildOptions
pub fn Workspace.set_options(self: &Self, options: BuildOptions)
pub fn Workspace.compile(self: &Self) -> BuildResult
pub fn Workspace.begin_intercept(self: &Self)
pub fn Workspace.wait_for_message(self: &Self) -> CompilerMessage
pub fn Workspace.end_intercept(self: &Self)

pub fn parallel(workspaces: Vec[Workspace]) -> Vec[BuildResult]
```

`BuildCtx` may also provide forwarding helpers for common use:

```with
pub fn BuildCtx.add_file(self: &Self, workspace: Workspace, path: str)
pub fn BuildCtx.add_string(self: &Self, workspace: Workspace, name: str, source: str)
pub fn BuildCtx.compile(self: &Self, workspace: Workspace) -> BuildResult
pub fn BuildCtx.parallel(self: &Self, workspaces: Vec[Workspace]) -> Vec[BuildResult]
```

The storage representation of `Workspace` is compiler-private. A workspace
handle is a capability value. User code may receive, pass, borrow, and store it
locally during tool execution, but may not construct or deserialize one.

### Isolation

Workspace isolation requirements:

- source additions in one workspace do not affect another;
- options are copied by value at the API boundary;
- diagnostics identify the workspace name and id;
- generated source is explicit through `add_string`;
- hooks and message interception belong only to the compiling workspace;
- artifacts produced by one workspace are visible to another only by paths or
  explicit build graph dependencies.

### `add_string` and Re-Typecheck

`Workspace.add_string(name, source)` adds a named source unit to the workspace.
If called before compilation starts, it is equivalent to adding a generated
source file. If called from a compiler message loop after typechecking has
already reached quiescence, the workspace returns to parse/typecheck scheduling
for the added source and emits the appropriate phase messages again.

The compiler must track a quiescence generation number:

1. Source set changes increment the generation.
2. Typecheck runs until no more work remains for the current generation.
3. `TYPECHECKED` and phase messages include the generation.
4. Adding source during `TYPECHECKED` or `PRE_LINK` creates a new generation.
5. Linking is blocked until the latest generation reaches `PRE_CODEGEN` and
   `CODEGEN_DONE`.

This is the mechanism used for generated source during compiler hooks and
build-time code generation. It must not mutate raw AST in place from user code.

## 5. BuildOptions

`BuildOptions` is the single typed representation of compiler build settings.
The CLI parser and workspace API must share one definition and one defaulting
path. The CLI is not allowed to have independent behavior that cannot be
expressed in `BuildOptions`.

```with
pub enum OutputKind: i32:
    no_output = 0
    executable = 1
    static_library = 2
    dynamic_library = 3
    object_file = 4
    c_source = 5
    llvm_ir = 6

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

pub enum PreludeMode: i32:
    normal = 0
    no_std = 1
    no_prelude = 2

pub type BuildOptions {
    output_kind: OutputKind,
    output_name: str,
    output_dir: str,
    intermediate_dir: str,
    target: BuildTarget,
    optimize: OptimizeMode,
    debug_info: bool,
    line_directives: bool,
    prelude_mode: PreludeMode,
    allocator_mode: i32,
    array_bounds_check: bool,
    cast_bounds_check: bool,
    null_pointer_check: bool,
    import_paths: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    system_libs: Vec[str],
    library_paths: Vec[str],
    emit_c: bool,
    emit_ir: bool,
    emit_obj: bool,
}
```

Implementation rule: define an internal compiler option record and conversion
helpers once. CLI parsing populates the same record that `Workspace.options`
returns. `Workspace.set_options` validates and stores that record. Direct
source builds, build graph targets, and workspaces all lower through the same
conversion into `CompilationConfig`.

Unsupported combinations fail before execution and name:

- requested output kind;
- requested target;
- host target;
- option causing the incompatibility.

## 6. BuildResult and Artifacts

Workspace compilation returns structured results rather than requiring build
scripts to parse stdout:

```with
pub type SourceSpan {
    file: str,
    start: i32,
    end: i32,
    line: i32,
    column: i32,
}

pub type DiagnosticSummary {
    severity: str,
    message: str,
    source: SourceSpan,
}

pub enum BuildStatus: i32:
    ok = 0
    failed = 1
    crashed = 2
    cancelled = 3

pub enum ArtifactKind: i32:
    executable = 0
    object = 1
    static_library = 2
    dynamic_library = 3
    c_source = 4
    llvm_ir = 5
    diagnostics = 6

pub type Artifact {
    kind: ArtifactKind,
    path: str,
}

pub type BuildResult {
    status: BuildStatus,
    rc: i32,
    workspace_name: str,
    artifacts: Vec[Artifact],
    diagnostics: Vec[DiagnosticSummary],
}
```

`rc == 0` only when `status == .ok`. A non-empty artifact list does not imply
success.

## 7. Compiler Message Loop

The message loop is the architecture for build-time compiler orchestration.
It replaces shelling out to `with build` for compiler-internal workflows.

```with
pub enum CompilerMessageKind: i32:
    phase = 0
    file = 1
    import = 2
    typechecked = 3
    diagnostic = 4
    artifact = 5
    complete = 6
    error = 7
    debug_dump = 8

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
    error = 10
    debug_dump = 11
```

Message payloads:

```with
pub type CompilerMessage {
    kind: CompilerMessageKind,
    workspace_name: str,
    phase: CompilerPhase,
    file: str,
    import_name: str,
    decls: Vec[DeclSummary],
    diagnostic: DiagnosticSummary,
    artifact: Artifact,
    link_command: LinkCommand,
    error_code: i32,
    debug_text: str,
    generation: i32,
}
```

Only fields relevant to `kind` are populated. Empty strings and empty vectors
represent unused fields.

### Phase Emission Points

The compiler must emit phases at these stable integration points:

- `PRE_PARSE`: before parser work begins for the current generation.
- `PARSED`: after all known source units in the generation are parsed.
- `PRE_TYPECHECK`: before sema begins or resumes.
- `TYPECHECKED`: after sema reaches quiescence for the current generation.
- `LOWERED_TO_MIR`: after all selected functions are lowered to MIR.
- `PRE_CODEGEN`: after MIR is ready and before backend code generation.
- `CODEGEN_DONE`: after backend code generation produced objects or C/IR text.
- `PRE_LINK`: after all link inputs are known, before invoking the linker.
- `LINKED`: after link command completes.
- `COMPLETE`: after all workspace work is done.
- `ERROR`: when compilation cannot continue.
- `DEBUG_DUMP`: when the compiler emits crash/debug context.

`PRE_LINK` messages carry a mutable-by-replacement `LinkCommand` summary.
Build code may provide a replacement command through an explicit workspace API:

```with
pub fn Workspace.set_link_command(self: &Self, command: LinkCommand)
```

The replacement must be typed argv/cwd/env data. Shell command strings are not
accepted.

## 8. DeclSummary

Build code and compiler hooks receive stable summaries, not raw AST or Sema
nodes. `DeclSummary` is versioned so future fields can be added without
turning internal compiler layout into a public ABI.

```with
pub enum DeclKind: i32:
    function = 0
    type_decl = 1
    global = 2
    method = 3
    trait_decl = 4
    impl_decl = 5

pub type DeclSummary {
    version: i32,
    kind: DeclKind,
    module_name: str,
    name: str,
    qualified_name: str,
    public_value: bool,
    docs_value: bool,
    type_text: str,
    return_type_text: str,
    param_count: i32,
    generic_param_count: i32,
    receiver_type_text: str,
    source: SourceSpan,
    notes: Vec[str],
}
```

`version` starts at `1`. The compiler may add fields only by increasing the
version and keeping old fields meaningful. Build code must not depend on AST
node ids, symbol ids, pointer identity, or enum numeric values outside the
documented public enums.

Existing `std.compiler` hook types should converge on this stable structure.
Avoid duplicate public names with incompatible shapes between `std.build` and
`std.compiler`; shared compiler-facing summaries belong in one module and may
be imported by the other.

## 9. LinkCommand

`PRE_LINK` exposes the planned link command as typed data:

```with
pub type EnvVar {
    name: str,
    value: str,
}

pub type LinkCommand {
    linker: str,
    args: Vec[str],
    cwd: str,
    env: Vec[EnvVar],
    inputs: Vec[str],
    outputs: Vec[str],
}
```

Build code may inspect this command for diagnostics or replace it with
`Workspace.set_link_command`. Replacements must preserve declared outputs or
fail validation. The driver must reject replacements that escape sandboxed
paths unless the caller has an explicit install/link capability.

## 10. Parallel Workspaces

`parallel(workspaces)` schedules independent workspaces concurrently and waits
for all results. It must be deterministic:

- result order matches input workspace order;
- diagnostics include workspace identity;
- shared caches use stable keys, not pointer order;
- artifact paths are validated before scheduling;
- mutable global compiler state is either read-only, synchronized, or
  workspace-local.

Allowed shared state:

- interned strings with deterministic ids or id-free public APIs;
- parsed module cache keyed by canonical path and compiler options;
- immutable standard library source cache;
- object/runtime metadata cache.

Forbidden shared state:

- unordered-map iteration affecting emitted output;
- pointer-address ordering in diagnostics or graph output;
- shared mutable Sema or MIR state across workspaces.

## 11. Compiler Integration Plan

The following compiler areas need explicit integration:

- `src/main.w`: replace generated build/action runner execution with
  in-process tool dispatch; route direct CLI flags through `BuildOptions`.
- `src/compiler/Compilation.w`: own workspace lifecycle, phase emission,
  message queues, generated-source re-entry, hook scheduling, and
  `BuildResult` construction.
- Parser/Ast: support named in-memory source units from `Workspace.add_string`.
- Sema: expose stable `DeclSummary` construction; enforce capability
  construction and closure escape rules for in-process tool execution.
- MIR lowering: provide callable tool function bodies to the in-process
  executor and continue failing loudly for unsupported tool-mode constructs.
- Codegen backends: emit `LOWERED_TO_MIR`, `PRE_CODEGEN`, and `CODEGEN_DONE`
  phase messages at stable boundaries.
- Link layer: expose `PRE_LINK`, typed `LinkCommand`, replacement validation,
  `LINKED`, and link artifacts.

## 12. Implementation Slices

### D1: In-Process Action Execution

Implement in-process tool dispatch for `build.w` and `Action` targets.
Remove generated build/action runner binaries from normal build execution.
Keep existing public `BuildCtx` and `ActionCtx` user code working.

Focused verification:

- existing `with build :cli-selfhost-build-w-tests`;
- action target with filesystem and process capabilities;
- action crash diagnostic includes target and source location;
- no generated `__with_build_runner.*.w` or `__with_build_action_runner.*.w`
  files are created during normal execution.

### D2: Workspace Skeleton and Shared BuildOptions

Add workspace handles, source file/string addition, typed options, compile,
and parallel scheduling. Co-design `BuildOptions` with CLI parsing so direct
source builds and workspace builds share defaults and validation.

Validation target: port `build_emit_c.w` or an equivalent emit-C build flow to
use `Workspace` directly.

### D3: Full Message Loop

Implement `begin_intercept`, `wait_for_message`, `end_intercept`, all required
phases, `DeclSummary`, `BuildResult` artifacts, and `PRE_LINK` replacement.

Focused verification:

- build script records file/import/phase/typechecked/artifact/complete
  messages in deterministic order;
- `add_string` during typecheck creates another typecheck generation;
- `PRE_LINK` replacement can select a custom argv-based linker command;
- diagnostics from message-loop builds include workspace identity.

### D4: Migrate Existing Project Actions to Workspaces

Replace action implementations that shell out to `with build` with direct
workspace usage. This includes compiler self-build, emit-C flows, seed flows,
and any selfhost fixtures that currently spawn the compiler only to compile
With source.

External tools such as `zig cc`, archive utilities, and corpus test binaries
remain `ProcessRunner` calls. The compiler itself should be invoked through
`Workspace` unless the target is explicitly testing the CLI process boundary.

### D5: DeclSummary-Driven Tooling Use Case

Implement one real compiler-tooling use case on `DeclSummary` and the message
loop. The preferred first use case is C migrator integration: drive a migrated
source compile from a workspace, inspect declarations through summaries, and
fail loudly on missing expected symbols.

This slice proves that stable summaries are sufficient for real tooling
without exposing raw AST/Sema internals.

## 13. Verification Standard

Every code slice must pass:

```sh
make build
make fixpoint
make test
```

Each slice also needs focused checks named in that slice. D1-D5 are separate
commits. If implementation uncovers a stdlib, runtime, or compiler bug, stop
the current slice, fix the bug in its own commit, then resume from a clean
tree. Do not bundle bug fixes into Phase D feature commits.

Docs-only changes do not require the full verification sequence, but must be
committed separately from code.
