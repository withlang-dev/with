# Phase D Design: Capability-Bearing Comptime and Workspaces

Status: implementation contract, v6 draft. Pre-Phase-D prerequisites complete. Implementation pending; D1 may begin after this revision is accepted.

This is the design contract for Phase D. It supersedes v5 and incorporates a small set of final refinements: a "prefer explicit handles" note on `current_workspace`, a softer intern-pool identity requirement, and an explicit measurement methodology for D7's regression thresholds.

The pre-Phase-D work documented in `docs/pre-phase-d-impl.md` has completed: audits, capability dispatch design, BuildOptions design, behavior tests, and the `src/main.w` refactor are all in place. The findings from those efforts are absorbed into this document.

## Revision History

**v6** (this document):

* §5: `current_workspace()` semantics retained but with explicit guidance that callers should prefer explicit workspace handles; the method exists for the single-workspace convenience case and may be deprecated if explicit handles cover all callers in practice.
* §11: intern pool row softened. The requirement is that public symbol identity be content-stable; internal ids may remain allocation-based if they are never exposed in public output (object files, debug info, mangled names, diagnostics, graph output).
* §13 D7: regression measurement methodology specified — median of 3 warm runs on the same machine, with a baseline warm-up run preceding the measured runs.

**v5**:

* §4: dispatch table is immutable after compiler startup; parallel reads are free.
* §5: `current_workspace()` semantics defined; aborts if no workspace exists.
* §5: workspace lifetime constraint extends to containing structures.
* §6: BuildOptions scope clarified; covers `with build` flags only; other subcommands have their own option structs that may share fields by composition.
* §8: each `wait_for_message` returns exactly one message; multi-message phases (e.g., `Phase(TYPECHECKED)` followed by `Typechecked { decls }`) deliver as separate sequential messages.
* §9: `docs_value: bool` replaced with `docs: str`; empty string represents absence.
* §11: LLVM context per-workspace, with per-workspace OS thread when running under `parallel` to align with LLVM's one-context-per-thread model.
* §13 D1: D1a/D1b land together in one PR as separate review commits; the tree is never broken at HEAD.
* §13 D2: BuildOptions covers compilation-affecting flags only; CLI-only flags (`--help`, `--version`, `--graph`, etc.) remain in the CLI layer.
* §13 D7: regression threshold named — wall-clock regression exceeding 20% on full `with build :build` or 50% on any individual ported action triggers investigation.

**v4**:

* Clarified that the API listed in §5 is the final Phase D API, introduced incrementally by slices.
* Removed unresolved syntax wording around `intrinsic`; the capability-method declaration form is now fixed by the pre-D syntax/design work.
* Narrowed generated-source re-entry in Phase D to `TYPECHECKED` only. `PRE_LINK` re-entry deferred until a concrete use case justifies it.
* Tightened ProcessRunner parallel-safety language: reentrant only when each invocation owns argv/env/cwd/capture/timeout state and does not mutate process-global cwd/env.
* Made D7 performance a measured diagnostic criterion rather than a hard pass/fail gate.
* Noted that D1 may land as D1a/D1b commits internally for review clarity while remaining one Phase D slice.
* Added an explicit unknown-source-span requirement for non-source errors.

**v3**:

* Audit findings from `docs/audits/comptime-eval-audit.md` absorbed into §3.
* Authoritative global-state enumeration from `docs/audits/parallel-state-audit.md` absorbed into §11.
* Capability dispatch mechanism from `docs/design/capability-dispatch.md` absorbed as §4.
* BuildOptions and CLI integration plan from `docs/design/build-options.md` absorbed into §6.
* Slicing expanded from D1-D5 to D1-D8 with clearer per-slice scope.
* Interpreter-only execution reframed as implementation strategy, not doctrine; native compilation reserved as future optimization.
* Incomplete interception is now an error, not a warning.
* LinkCommand authority bounded; arbitrary linker execution requires ProcessCap.
* Symbol id stability caveat added.
* `comptime fn` syntax compatibility clarified.

**v2**: initial capability-bearing comptime design; superseded by review feedback.

**v1**: tool-mode framing; superseded by capability-bearing comptime model.

---

## 1. Doctrine

Compile-time evaluation in With is governed by capabilities, not by execution modes.

There is one compile-time execution abstraction: `comptime`. Effects are not a separate mode; they are gated by capability values passed as function parameters.

```text
comptime:                     pure, deterministic, effect-free
comptime with BuildCtx:       build orchestration authority
comptime with Workspace:      workspace compilation authority
comptime with ToolFs:         filesystem authority
comptime with ProcessRunner:  process invocation authority
```

Operational rules:

* Pure `comptime` evaluation is deterministic and effect-free. The existing `ComptimeEval` infrastructure handles this case.
* A comptime function declares its required capabilities as ordinary parameters. The function's effects are bounded by the capabilities it receives.
* Capability values are unforgeable, driver-minted handles. User code cannot construct, deserialize, or forge them.
* The compiler driver is the sole entity that mints top-level capabilities, and it does so at well-defined points: invoking `pub fn build(ctx: BuildCtx)` at build-graph construction, dispatching action functions with `ActionCtx`, and so on.
* A function with capability-typed parameters cannot be invoked from runtime code. Capability types exist only at compile time. The type system enforces this.
* A pure comptime function, meaning a function with no capability parameters and no effectful capability calls, may be invoked from any context subject to the existing comptime rules. Runtime code does not execute it at runtime; it may trigger compile-time evaluation where the existing language rules allow that.

The public user model must not depend on whether the compiler executes capability-bearing comptime in-process, in a helper binary, or over RPC. Phase D's implementation is in-process and interpreter-based, but the APIs remain boundary-safe: no raw pointer transport, no direct access to compiler-owned data structures, and no ABI promises based on shared address space.

---

## 2. Non-Goals

These items are deliberately outside Phase D:

* **`#run` directives invoked from inside an arbitrary source file.** With's general comptime mechanism is real and remains. What is not added is a top-level directive that causes a function to execute at the compile time of its own file. Build entry points are invoked by the compiler driver, not by user-placed `#run` directives.
* **Default-metaprogram replacement for arbitrary source builds.** `with build` uses `build.w` if present. `build.w` is the metaprogram; there is no separate default to replace.
* **Direct AST or Sema mutation from user comptime code.** Code generation is performed through `Workspace.add_string`. Direct AST mutation is permanently out.
* **Raw AST handles exposed to comptime code.** Comptime code receives `DeclSummary`, never internal AST or Sema nodes.
* **Cross-process or RPC capability transport.** Implementation is in-process. APIs remain boundary-safe so cross-process transport is possible later if needed.
* **Public package manager integration.** Phase D may leave seams that support this later but does not implement it.

These items are not implemented under different names during Phase D.

---

## 3. Comptime Infrastructure

This section absorbs findings from `docs/audits/comptime-eval-audit.md`.

### Current State of ComptimeEval

The existing `src/ComptimeEval.w` evaluator handles:

* Constant expression evaluation for `const X: T = expr` declarations.
* Compile-time function invocation for functions referenced in constant contexts.
* Type-level evaluation for generic parameter resolution.

The evaluator interprets MIR. It does not currently compile to native code; it walks MIR statements with an interpreter loop. This is the foundation Phase D builds on.

The evaluator does **not** currently:

* Recognize capability-typed parameters as anything special. It treats them as ordinary struct values, which works for construction but does not dispatch their methods to compiler-internal implementations.
* Dispatch effects from inside evaluation. All effects in the current build system happen in a separately compiled native runner binary that calls runtime functions like `with_fs_read_file`. The evaluator itself is effect-free.
* Support cooperative suspension. The evaluator runs each comptime call to completion before returning to its caller.

### Required Extensions

Phase D adds three extensions to the evaluator:

**E1: Capability-aware method dispatch.** When evaluation reaches a method call on a capability-typed value, the evaluator consults a capability dispatch table (§4) and invokes the compiler-internal implementation rather than interpreting the method's MIR body. This extension is required for D1.

**E2: Intrinsic effect dispatch.** Capability method implementations are compiler-internal native code that performs effects: filesystem operations, process invocation, compilation state mutation, and related driver operations. The evaluator calls these implementations via the dispatch table. Token validation happens at the entry of each call. This extension is required for D1.

**E3: Cooperative suspension.** When `Workspace.wait_for_message` is invoked with an empty message queue, the evaluator must save its current execution state, return control to the compiler driver, and resume execution with a delivered message when one is available. This requires turning the evaluator loop into something resumable: either a coroutine implementation, a continuation-passing transform, or an explicit evaluator state object that can be paused and resumed. This extension is required for D4 and beyond. D1 through D3 do not require suspension.

### Implementation Strategy

Capability-bearing comptime is implemented by interpreting MIR with capability-aware intrinsic dispatch. This is the implementation strategy for Phase D. If interpretation becomes a measured bottleneck in later phases, native compilation may be added as an optimization; the public semantics — capability dispatch, message loop, suspension behavior, token validation, and boundary-safe handles — remain evaluator-based regardless.

Capability methods themselves execute at native speed because their implementations are compiler-internal native code. Interpretation overhead applies only to user logic between capability calls. In practice this overhead is expected to be small relative to the time spent inside compiler operations such as parsing, typechecking, codegen, IO, and process invocation. This expectation is not doctrine; if measured build workloads show evaluator overhead dominating, native execution may be introduced later behind the same public semantics.

---

## 4. Capability Dispatch

This section absorbs `docs/design/capability-dispatch.md`.

### Capability Type Identification

Capability types are marked with the `@[capability]` attribute:

```with
@[capability]
pub type Workspace:
    token: str
    workspace_id: i32
```

The attribute is recognized by Sema. Types marked `@[capability]`:

* May only be constructed by compiler-internal code. The driver mints them.
* Cannot appear in runtime code paths. Sema rejects values of capability type in non-comptime contexts.
* Have their methods routed through the capability dispatch table.

This mechanism is location-independent. Capability types may live in any module; the attribute is the marker.

### Capability Method Declaration

Methods on capability types are declared in `std.build` and `std.compiler` with the `@[capability_method]` attribute and the intrinsic declaration form defined by `docs/design/comptime-capability-syntax.md`:

```with
@[capability_method("Workspace.compile")]
pub fn Workspace.compile(&mut self) -> BuildResult:
    intrinsic

@[capability_method("Workspace.add_string")]
pub fn Workspace.add_string(&mut self, name: str, source: str):
    intrinsic
```

The `intrinsic` declaration form means the method's implementation is supplied by the compiler. The attribute parameter is the dispatch key. The evaluator does not interpret a With body for these methods.

### Dispatch Table

The compiler maintains a dispatch table mapping `(capability_type_name, method_name)` to internal implementation functions:

```text
("BuildCtx",   "create_workspace")  -> driver_create_workspace_impl
("Workspace",  "compile")           -> workspace_compile_impl
("Workspace",  "add_string")        -> workspace_add_string_impl
("Workspace",  "wait_for_message")  -> workspace_wait_for_message_impl
("ToolFs",     "read_text")         -> toolfs_read_text_impl
```

The table is populated once at compiler startup and is immutable thereafter for the lifetime of the compiler process. The evaluator consults it when dispatching capability method calls. Immutability means parallel reads are free of synchronization concerns; under `parallel` workspaces, dispatch table lookups require no locking.

User-defined capabilities are not part of Phase D. If a future phase introduces user-defined capabilities, the dispatch-table mutation semantics will be revisited then.

### Token Validation

Every capability method call validates the capability's token field against the expected value for the workspace/context it belongs to:

```text
fn workspace_compile_impl(workspace: WorkspaceCapability, ...) -> BuildResult:
    if workspace.token != driver.expected_token(workspace.workspace_id):
        return tool_capability_violation(workspace, "compile")
    ...
```

Token storage moves from environment variables, the current transitional mechanism, to fields on the capability value itself. The driver stores expected tokens in per-workspace state. Validation happens at the entry of every capability method, not once at evaluator startup.

### Adding New Capabilities

To add a new capability in future phases, such as `LinkCap` or `NetworkCap`:

1. Declare the type with `@[capability]` in the appropriate stdlib module.
2. Declare its methods with `@[capability_method("TypeName.method_name")]`.
3. Implement the dispatch handlers in the compiler.
4. Register the handlers in the dispatch table at compiler startup.

No core architectural changes are required. The dispatch table is extensible at compiler-build time; runtime extension is not in scope.

---

## 5. Workspace API

A workspace is an isolated compiler environment used to compile one program, library, object, C source output, generated source set, or tool. Workspaces own their source set, build options, diagnostics, message queue, generated source strings, and compilation artifacts.

### API Staging

The API listed in this section is the final Phase D public API. It is introduced incrementally by slice:

* D3 introduces workspace creation, source addition, options, migration options, synchronous `compile`, `BuildResult`, and artifacts.
* D4 introduces interception, message-loop APIs, `set_link_command`, `CompilerMessageEnvelope`, and `LinkCommand`.
* D6 introduces `parallel(workspaces)`.

Methods listed here but not yet implemented in a slice must not be exposed as inert stubs. They either do not exist yet or fail at compile time until their owning slice lands.

### Lifetime and Ownership

Workspaces are owned by the `BuildCtx` that minted them. `BuildCtx.create_workspace` returns a `Workspace` handle, which is a reference to compiler-owned storage. The handle's lifetime is bounded by the BuildCtx's lifetime, which is bounded by the driver's call to `pub fn build(ctx: BuildCtx) -> Build`.

User code may pass handles, borrow them, and store them in local data structures during comptime evaluation. User code cannot construct, serialize, or extend the lifetime of a workspace handle beyond the BuildCtx.

Any structure containing a `Workspace` handle (directly or transitively) inherits the BuildCtx's lifetime bound. Sema enforces this: a struct field of type `Workspace`, or a struct field whose type transitively contains `Workspace`, can only be instantiated in a context that has access to a live BuildCtx, and the resulting struct value cannot outlive that BuildCtx.

### Entry Point Compatibility

Existing `pub fn build(ctx: BuildCtx) -> Build` continues to work unchanged. A function whose parameter list includes a capability type is treated as a capability-bearing comptime entry point when invoked by the driver. Explicit `comptime fn` marker syntax is not required during Phase D; it may be added in a later phase if disambiguation becomes necessary.

### current_workspace Semantics

`BuildCtx.current_workspace(&self) -> Workspace` returns the workspace most recently created by this `BuildCtx`. If no workspace has been created, the call aborts with a structured error identifying the BuildCtx and the call site.

The semantics deliberately match a "last created" model rather than any thread-local or stack-based notion of "currently compiling," because the build script does not run inside a workspace; it runs in the compiler's comptime evaluator and creates workspaces by calling `create_workspace`.

**Callers with more than one workspace should prefer explicit handles.** `current_workspace()` is a convenience for the single-workspace case where threading a local variable adds noise. In a multi-workspace build script, "current" is implicit and easy to misread — a script that creates `ws_a` then `ws_b` and calls `current_workspace()` expecting `ws_a` will silently get `ws_b` with no diagnostic. Explicit handles eliminate this class of error. The method may be deprecated in a later phase if explicit handles cover all real callers in practice.

If future use cases require a different notion of "current," this API may grow additional methods (e.g., `most_recent_workspace`, `workspace_by_name`) rather than redefining `current_workspace`'s meaning.

### Final Phase D Public API

Public API lives in `std.build` unless otherwise noted.

```with
@[capability]
pub type Workspace

pub fn BuildCtx.create_workspace(&mut self, name: str) -> Workspace
pub fn BuildCtx.current_workspace(&self) -> Workspace

pub fn Workspace.name(&self) -> str
pub fn Workspace.add_file(&mut self, path: str)
pub fn Workspace.add_string(&mut self, name: str, source: str)
pub fn Workspace.options(&self) -> BuildOptions
pub fn Workspace.set_options(&mut self, options: BuildOptions)
pub fn Workspace.set_migrate_options(&mut self, options: MigrateOptions)
pub fn Workspace.compile(&mut self) -> BuildResult

// Introduced in D4.
pub fn Workspace.begin_intercept(&mut self)
pub fn Workspace.wait_for_message(&mut self) -> CompilerMessageEnvelope
pub fn Workspace.end_intercept(&mut self)
pub fn Workspace.set_link_command(&mut self, command: LinkCommand)

// Introduced in D6.
pub fn parallel(workspaces: Vec[Workspace]) -> Vec[BuildResult]
```

### Isolation

Workspace isolation requirements:

* Source additions in one workspace do not affect another.
* Options are copied by value at the API boundary.
* Diagnostics identify the workspace name and id.
* Generated source is explicit through `add_string`.
* Intercept state and message queues belong to one workspace.
* Artifacts produced by one workspace are visible to another only through paths or explicit build graph dependencies.

### add_string and Re-Typecheck

`Workspace.add_string(name, source)` adds a named source unit to the workspace. If called before compilation begins, it is equivalent to adding a generated source file. If called from a comptime message loop after typechecking has reached quiescence, the workspace re-enters parse/typecheck scheduling for the added source and emits the appropriate phase messages again.

The compiler maintains a quiescence generation number per workspace:

1. Source set changes (`add_file`, `add_string`) increment the generation.
2. Typecheck runs until no work remains for the current generation.
3. All messages carry the generation number.
4. During Phase D, generated-source re-entry is supported at `TYPECHECKED` only.
5. Calling `add_string` during `TYPECHECKED` creates a new generation; parse/typecheck and downstream phase messages re-fire for the new source.
6. Linking is blocked until the latest generation reaches both `PRE_CODEGEN` and `CODEGEN_DONE`.

`PRE_LINK` re-entry is intentionally not supported in Phase D. It may be added later only if a concrete use case justifies the extra rewind semantics and validation rules.

This is the safe mechanism for build-time code generation. Comptime code never mutates AST in place.

---

## 6. BuildOptions and CLI Integration

This section absorbs `docs/design/build-options.md`.

### Scope

`BuildOptions` represents the compilation-affecting flags accepted by `with build`. It is not a universal options struct for all subcommands.

* Flags that affect compilation behavior (`-O`, `--target`, `-I`, `-D`, `--emit-c`, etc.) map to `BuildOptions` fields.
* Flags that affect only CLI behavior (`--help`, `--version`, `--graph`, `--verbose`, etc.) remain in the CLI layer and are not part of `BuildOptions`.
* Other subcommands (`with migrate`, `with run`, `with test`) have their own option structs. Where fields overlap (e.g., `c_include_paths`), the option structs may share field definitions by composition, but they are not merged into a single mega-struct.

`MigrateOptions` is a separate struct attached to a workspace via `Workspace.set_migrate_options`. It is not folded into `BuildOptions`.

### BuildOptions Struct

`BuildOptions` is the single typed representation of compiler build settings exposed by the workspace API. The CLI parser for `with build` and the workspace API share one definition and one defaulting path.

```with
pub enum OutputKind: i32:
    no_output = 0
    executable = 1
    static_library = 2
    dynamic_library = 3
    object_file = 4
    c_source = 5
    llvm_ir = 6

pub enum OptLevel: i32:
    O0 = 0
    O1 = 1
    O2 = 2
    O3 = 3

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

pub type BuildOptions:
    output_kind: OutputKind
    output_name: str
    output_dir: str
    intermediate_dir: str
    target: BuildTarget
    opt_level: OptLevel
    debug_info: bool
    line_directives: bool
    prelude_mode: PreludeMode
    allocator_mode: i32
    array_bounds_check: bool
    cast_bounds_check: bool
    null_pointer_check: bool
    import_paths: Vec[str]
    c_include_paths: Vec[str]
    c_defines: Vec[str]
    system_libs: Vec[str]
    library_paths: Vec[str]
    emit_c: bool
    emit_ir: bool
    emit_obj: bool

pub type MigrateOptions:
    no_c_export: bool
    prefer_brace: bool
    width_slice: i32
    shared_defs: str
    c_include_paths: Vec[str]
    c_defines: Vec[str]
```

`OptLevel` distinguishes `-O0` through `-O3` to match current CLI granularity.

`import_paths` are With module search paths; `c_include_paths` are C `#include` search paths used by the migrator and emit-C. These are separate concerns and have separate fields.

### CLI Parser Refactor

The current CLI parser for `with build` mutates `Compilation` state directly. The target state: parser produces a `BuildOptions` value; driver constructs a workspace from it; workspace drives compilation.

This refactor is the largest single piece of D2 integration work. It touches:

* Argument parsing, which lives in `src/main.w`.
* Default value computation.
* Validation: mutually exclusive flags, target-host compatibility, and related cross-field checks.
* The main driver loop, which now calls a workspace instead of mutating `Compilation` directly.

The refactor preserves byte-for-byte CLI compatibility. The behavior tests in `test/behavior/behav_cli_compat_*.w`, committed during pre-Phase-D, lock this in.

Other subcommands (`with migrate`, `with run`, `with test`) keep their existing parsing in D2 and may be migrated later if useful. They are explicitly out of scope for D2.

### Validation

Unsupported option combinations fail before execution and name:

* requested output kind;
* requested target;
* host target;
* option causing the incompatibility.

Examples of disallowed combinations: `emit_c && emit_ir`, `output_kind == .object_file && system_libs.len() > 0`, and target/host mismatches that lack a cross-compiler.

---

## 7. BuildResult and Artifacts

Workspace compilation returns structured results rather than requiring comptime code to parse stdout.

```with
pub type SourceSpan:
    file: str
    start: i32
    end: i32
    line: i32
    column: i32

pub type DiagnosticSummary:
    severity: str
    message: str
    source: SourceSpan

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

pub type Artifact:
    kind: ArtifactKind
    path: str

pub type BuildResult:
    status: BuildStatus
    rc: i32
    workspace_name: str
    artifacts: Vec[Artifact]
    diagnostics: Vec[DiagnosticSummary]
```

`rc == 0` only when `status == .ok`. A non-empty artifact list does not imply success.

Diagnostics that do not have a source location, such as linker failures, capability violations, or workspace lifecycle errors, must use a well-defined unknown span. The unknown span uses an empty `file`, `start = -1`, `end = -1`, `line = -1`, and `column = -1` unless the existing diagnostic system already defines a canonical unknown span.

---

## 8. Compiler Message Loop

The message loop is the architecture for build-time compiler orchestration. It replaces shelling out to `with build` for compiler-internal workflows.

`CompilerMessage` is a tagged union over message payloads, not a flat struct with optional fields. Each variant carries only the data relevant to its kind.

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

pub enum CompilerMessage:
    Phase { phase: CompilerPhase }
    File { path: str }
    Import { name: str, path: str }
    Typechecked { decls: Vec[DeclSummary] }
    Diagnostic { diagnostic: DiagnosticSummary }
    Artifact { artifact: Artifact }
    PreLink { command: LinkCommand }
    Linked { command: LinkCommand, rc: i32 }
    Complete { result: BuildResult }
    Error { code: i32, message: str, source: SourceSpan }
    DebugDump { text: str }

pub type CompilerMessageEnvelope:
    workspace_name: str
    generation: i32
    message: CompilerMessage
```

`wait_for_message` returns a `CompilerMessageEnvelope`. The envelope carries workspace identity and generation; user code branches on `envelope.message`.

### Phase Emission Points

The compiler emits phases at these stable integration points:

* `Phase(PRE_PARSE)`: before parser work begins for the current generation.
* `Phase(PARSED)`: after all known source units in the generation are parsed.
* `Phase(PRE_TYPECHECK)`: before sema begins or resumes.
* `Phase(TYPECHECKED)` followed by `Typechecked { decls }`: after sema reaches quiescence for the current generation. The `Typechecked` message carries declaration summaries.
* `Phase(LOWERED_TO_MIR)`: after all selected functions are lowered to MIR.
* `Phase(PRE_CODEGEN)`: after MIR is ready and before backend code generation.
* `Phase(CODEGEN_DONE)`: after backend code generation produced objects, C, or IR text.
* `Phase(PRE_LINK)` followed by `PreLink { command }`: after all link inputs are known, before invoking the linker.
* `Phase(LINKED)` followed by `Linked { command, rc }`: after link command completes.
* `Phase(COMPLETE)` followed by `Complete { result }`: terminal message.
* `Error`: when compilation cannot continue. Workspace transitions to terminal state.
* `DebugDump`: when the compiler emits crash/debug context.

Build code may provide a replacement link command in response to `PreLink` by calling `Workspace.set_link_command(command)` before consuming the next message.

### Message Stream Semantics

Within a single workspace, the message stream is totally ordered. The compiler delivers phase messages in the order listed above for each generation. Messages within a generation are delivered before messages of the next generation.

Each `wait_for_message` call returns exactly one message. Messages associated with the same phase (e.g., `Phase(TYPECHECKED)` followed by `Typechecked { decls }`) are delivered as separate sequential messages, in the order listed in the phase emission points above. A build script that wants to react to a typecheck completion will see two distinct messages: first the `Phase(TYPECHECKED)` marker, then the `Typechecked { decls }` payload. This keeps the API uniform — one `wait_for_message` call, one message returned.

Under `parallel(ws1, ws2, ...)`, each workspace has an independent message queue. `begin_intercept`, `wait_for_message`, and `end_intercept` operate on the specific workspace they're called on. Message streams from different workspaces are never interleaved.

### Backpressure

The compiler advances a workspace's compilation only between message deliveries.

* If the queue contains messages when `wait_for_message` is called, the next message is returned immediately without compiler advancement.
* If the queue is empty and compilation is incomplete, the comptime evaluator suspends (extension E3 in §3). The compiler advances compilation until the next phase boundary emits a message. The evaluator resumes with that message.
* If the queue is empty and compilation has terminated (`Complete` or `Error` has been delivered), `wait_for_message` returns an `Error` message indicating the workspace is closed.

### Incomplete Interception

If a build script calls `begin_intercept` and returns without calling `end_intercept`, the driver reports this as a build script error, unless the workspace had already delivered `Complete` or `Error`. Compiler orchestration cannot be silently abandoned.

The driver detects this by checking each workspace's intercept state at build script return. Any workspace in an active-intercept state without a terminal message produces a structured error and a non-zero exit.

---

## 9. DeclSummary

Comptime code receives stable summaries, not raw AST or Sema nodes. `DeclSummary` is versioned so future fields can be added without turning internal compiler layout into a public ABI.

```with
pub enum DeclKind: i32:
    function = 0
    type_decl = 1
    global = 2
    method = 3
    trait_decl = 4
    impl_decl = 5

pub type DeclSummary:
    version: i32
    kind: DeclKind
    module_name: str
    name: str
    qualified_name: str
    public_value: bool
    docs: str
    type_text: str
    return_type_text: str
    param_count: i32
    generic_param_count: i32
    receiver_type_text: str
    source: SourceSpan
    notes: Vec[str]
```

`version` starts at `1`. The compiler may add fields only by increasing the version and keeping old fields meaningful. Comptime code must not depend on AST node ids, symbol ids, pointer identity, or enum numeric values outside the documented public enums.

`docs` carries the declaration's doc-comment text verbatim, or an empty string if no doc comment is attached. Build code that needs to detect presence of docs checks `docs.len() > 0`. Doc-driven generators (binding generators, documentation extractors) consume the string directly.

`DeclSummary`, `DiagnosticSummary`, `SourceSpan`, and `Artifact` live in `std.compiler` and are re-exported from `std.build`.

---

## 10. LinkCommand

`PreLink` exposes the planned link command as typed data. `LinkCommand` does not carry any capability; it is a description of what the compiler intends to invoke, not an authorization to invoke it.

```with
pub type EnvVar:
    name: str
    value: str

pub type LinkCommand:
    linker: str
    args: Vec[str]
    cwd: str
    env: Vec[EnvVar]
    inputs: Vec[str]
    outputs: Vec[str]
```

Comptime code may inspect this command for diagnostics or replace it via `Workspace.set_link_command(command)`. Replacement validation:

* The replacement's `outputs` must be a superset of the original's `outputs`. Declared workspace outputs cannot be silently dropped.
* The replacement's `inputs` are not constrained by Phase D beyond normal path validation; user code may add additional link inputs.
* The replacement's `cwd` and `env` are passed through to the linker invocation after path/scope validation.
* The replacement's `args` may be any sequence; this is argv-level modification within the workspace's existing linker authority.
* Changing the `linker` executable to a different path requires an explicit `ProcessRunner`/`ProcessCap` authority or a future `LinkCap`. The Workspace capability alone grants authority to modify args for the planned linker, not to invoke arbitrary executables.

The driver validates the replacement and aborts the build with a structured error if validation fails.

---

## 11. Parallel Workspaces

`parallel(workspaces)` schedules independent workspaces concurrently and waits for all results. This section absorbs the authoritative enumeration from `docs/audits/parallel-state-audit.md`.

### Determinism Requirements

* Result order matches input workspace order.
* Diagnostics include workspace identity.
* Shared caches use stable keys, not pointer order.
* Artifact paths are validated before scheduling.
* Mutable global compiler state is either read-only, synchronized, or workspace-local.

### Global State Disposition

From the parallel-state audit, current global compiler state and its parallel-safe handling:

| State                       | Current    | Strategy                                                                                                                        |
| --------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Intern pool                 | Global     | Stays global; mutex-synchronized append-and-lookup; public symbol identity must be content-stable; internal ids may remain allocation-based if never exposed in public output |
| Parsed module cache         | Global     | Stays global; immutable post-construction; keyed by canonical path + options hash                                               |
| Embedded stdlib cache       | Global     | Stays global; read-only after init                                                                                              |
| Zcu / Compilation           | Global     | Per-workspace                                                                                                                   |
| Sema state                  | Global     | Per-workspace                                                                                                                   |
| MIR module                  | Global     | Per-workspace                                                                                                                   |
| Diagnostic emitter          | Global     | Per-workspace; results aggregated in `BuildResult`                                                                              |
| LLVM context                | Global     | Per-workspace; under `parallel`, each workspace runs on its own OS thread to align with LLVM's one-context-per-thread model     |
| Capability dispatch table   | Global     | Stays global; immutable post-startup (§4); no synchronization needed                                                            |
| ToolFs write scope tracking | Per-action | Per-workspace; scoped to workspace output_dir                                                                                   |
| ProcessRunner               | Global     | Stays global only if each invocation owns argv/env/cwd/capture buffers/timeout state and does not mutate process-global cwd/env |
| Build graph evaluator       | Global     | Stays global; orchestrates workspaces, not affected                                                                             |
| Temp file naming counter    | Global     | Stays global; mutex-synchronized; deterministic seed                                                                            |
| Selfcheck stage cache       | Global     | Stays global; immutable per session                                                                                             |
| PCRE2 reference download    | Global     | Stays global; idempotent                                                                                                        |

Refactor complexity per item, estimated during the audit:

* Small: temp file naming counter, ToolFs write scope.
* Medium: diagnostic emitter, intern pool synchronization, ProcessRunner state audit/fixes if any non-reentrant global state is found.
* Large: Zcu, Sema state, MIR module, LLVM context, all together.

The large refactor is the bulk of D6 parallel-workspaces work. D2 through D5 can use the current global state with a single active workspace at a time.

### LLVM Threading Model

LLVM's threading guarantees are organized around one `LLVMContext` per thread. Per-workspace LLVM contexts are sufficient when each workspace runs on its own thread; sharing a thread between workspaces requires switching contexts, which LLVM does not natively support without serialization.

`parallel(workspaces)` therefore assigns each workspace to its own OS thread. Within a single workspace's thread, the message-loop suspension mechanism (§3 E3) yields back to the compiler driver without crossing thread boundaries. Cross-thread suspension is not part of Phase D.

If a future phase introduces work-stealing or a more sophisticated scheduler, the LLVMContext-per-thread invariant must be preserved (or LLVM's threading model worked around explicitly).

### Forbidden Patterns

* Unordered-map iteration affecting emitted output.
* Pointer-address ordering in diagnostics or graph output.
* Shared mutable Sema, MIR, or codegen state across workspaces.
* Non-deterministic file system iteration order observable in artifact contents.
* Process execution helpers that mutate process-global cwd/env.

---

## 12. Compiler Integration Plan

The following compiler areas need integration work. Several involve real refactors and are called out as such.

* **`src/main.w`**: replace generated build/action runner execution with comptime evaluator dispatch. **The CLI argument parser for `with build` is refactored to produce a `BuildOptions` value rather than mutating `Compilation` state directly.** A direct source build (`with build src.w`) constructs an implicit workspace from the produced `BuildOptions` and drives it through the same evaluator path as explicit workspaces. This refactor is the largest single piece of integration work; it touches argument parsing, default values, validation, and the main driver loop. The pre-D refactor isolated the action-runner code into a small set of named functions; D1 replaces those functions with evaluator dispatch.

* **`src/compiler/Compilation.w`**: owns workspace lifecycle, phase emission, per-workspace message queues, generated-source re-entry with generation tracking, hook scheduling, and `BuildResult` construction. The compilation entry point gains explicit phase emission calls at each integration point listed in §8.

* **`src/ComptimeEval.w`**: extended per §3. E1 (capability dispatch) and E2 (intrinsic effect dispatch) land in D1. E3 (cooperative suspension) lands in D4.

* **Parser / Ast**: support named in-memory source units from `Workspace.add_string`. Source manager extended to track virtual file paths for generated sources.

* **Sema**: expose stable `DeclSummary` construction. Enforce capability-value construction rules: capability types marked with `@[capability]` can only be constructed by compiler-internal code. Closure capture rules for capability values must prevent escape from the comptime context. Lifetime checks on containing structures (§5).

* **MIR lowering**: provide callable comptime function bodies to the evaluator. Continue failing loudly for unsupported comptime constructs.

* **Codegen backends**: emit `LOWERED_TO_MIR`, `PRE_CODEGEN`, and `CODEGEN_DONE` phase messages at stable boundaries. Workspace-local LLVM context.

* **Link layer**: expose `PRE_LINK` and `LINKED` messages with typed `LinkCommand`, support replacement validation per §10, attach link artifacts to `BuildResult`.

---

## 13. Implementation Slices

Phase D is sliced into D1 through D8. Each slice is its own commit or short sequence of commits if stdlib capability additions or bug fixes surface along the way. Each slice has explicit scope, deliverables, and verification.

### D1: Capability-Bearing Comptime Evaluator (No Message Loop)

Implement comptime evaluator dispatch for `build.w` and `Action` targets through capability-bearing comptime functions. Implement evaluator extensions E1 and E2: capability dispatch and intrinsic effect dispatch. Do not implement E3 suspension; that lives in D4.

D1 lands as one PR but may be split into two review commits for clarity:

* **D1a:** capability attributes, capability-method declarations, dispatch table, evaluator dispatch, and token validation.
* **D1b:** driver replacement of generated build/action runner execution with evaluator dispatch.

Both commits land together in the same PR. The tree at HEAD passes the full verification chain after D1b; intermediate states between D1a and D1b are not required to pass independently. The split is for review readability, not for tree-state staging.

Scope:

* `@[capability]` and `@[capability_method]` attributes recognized by Sema.
* Capability dispatch table populated at compiler startup; immutable thereafter.
* Evaluator routes capability method calls through the dispatch table.
* Token validation at every capability method entry.
* Driver invokes `build(ctx)` via the evaluator instead of generating a runner binary.
* Driver invokes action functions via the evaluator with `ActionCtx`.
* Crash diagnostics include entry point, target name, source location, evaluator stack frames, and capability operation in progress.

Removed:

* Generated `__with_build_runner.*.w` files.
* Generated `__with_build_action_runner.*.w` files.
* Action runner binary compilation and execution.
* Environment variable transport for capability tokens.

Focused verification:

* Behavior tests from pre-Phase-D pass: `behav_build_w_basic_invocation`, `behav_action_capability_filesystem`, `behav_action_capability_process`, `behav_capability_token_mismatch`, `behav_action_crash_diagnostic`, `behav_action_no_deps_isolation`, and related CLI compatibility tests not affected by D1.
* No generated runner files in `out/tmp/` during normal builds.
* Capability token mismatch produces structured violation error.
* `with build :build`, `with build :fixpoint`, and `with build :test` pass.

### D2: BuildOptions and CLI Unification

Refactor CLI parsing for `with build` to produce `BuildOptions`. Implement `BuildOptions` and `MigrateOptions` structs. Direct source builds (`with build src.w`) construct an implicit workspace internally.

Scope:

* `BuildOptions` and `MigrateOptions` struct definitions in `std.build`.
* CLI parser for `with build` produces `BuildOptions` value.
* Driver constructs implicit workspace from `BuildOptions` for direct source builds.
* All current `with build` flags that affect compilation behavior map to `BuildOptions` fields.
* CLI-only flags (`--help`, `--version`, `--graph`, `--verbose`, etc.) remain in the CLI layer and do not produce `BuildOptions` fields.
* Other subcommands (`with migrate`, `with run`, `with test`) retain their existing parsing and option handling; they are explicitly out of scope.
* Unsupported combinations rejected with structured errors.

Out of scope:

* Public `Workspace` API. It lives in D3.
* Message loop. It lives in D4.
* Refactoring non-`with build` subcommand parsers.

Focused verification:

* Behavior tests `behav_cli_compat_*.w` pass byte-for-byte.
* `with build :build`, `with build :fixpoint`, and `with build :test` pass.
* Direct `with build src.w` produces identical output to pre-D2.
* Other subcommands continue to work unchanged.

### D3: Sequential Workspace Skeleton

Implement the public `Workspace` API with sequential, non-parallel execution. `Workspace.compile()` is synchronous and returns a `BuildResult`.

Scope:

* `BuildCtx.create_workspace`, `BuildCtx.current_workspace`.
* `Workspace.name`, `add_file`, `add_string`, `options`, `set_options`, `set_migrate_options`, `compile`.
* `BuildResult` and `Artifact` construction.
* Workspace lifetime tied to BuildCtx, including lifetime constraint on containing structures.

Out of scope:

* `begin_intercept`, `wait_for_message`, `end_intercept`. They live in D4.
* `set_link_command`. It lives in D4.
* `parallel(ws1, ws2)`. It lives in D6.
* Generated-source generations. They live in D5.

Focused verification:

* A build script can create a workspace, add a file, call compile, and receive a BuildResult.
* `current_workspace()` aborts cleanly with a structured error if called before any workspace has been created.
* A struct containing a `Workspace` field cannot outlive its `BuildCtx` (Sema rejection).
* One existing action is ported from `ProcessRunner.run_capture(["with", "build", ...])` to `workspace.compile()`. Recommended target: `build_emit_c.w`'s emit-C invocation.
* Output is byte-equivalent to pre-D3 for the ported action.

### D4: Message Loop

Implement evaluator extension E3 (cooperative suspension) and the message loop API.

Scope:

* `Workspace.begin_intercept`, `wait_for_message`, `end_intercept`.
* All phase emission points in the compiler (§8).
* `CompilerMessage` tagged union and `CompilerMessageEnvelope`.
* One-message-per-`wait_for_message` delivery semantics.
* Backpressure semantics: evaluator suspends, compiler advances, evaluator resumes.
* Incomplete interception detection: driver reports as error if workspace not in terminal state at build script return.
* `Workspace.set_link_command` and `LinkCommand` replacement validation.
* `PreLink` and `Linked` messages.

Focused verification:

* A build script can intercept, observe phase messages in order, and acknowledge complete.
* Each `wait_for_message` call returns exactly one message; multi-message phases deliver sequentially.
* Backpressure works: evaluator yields when queue empty and resumes with delivered message.
* Incomplete interception triggers an error.
* `LinkCommand` replacement modifies argv correctly.
* Attempting to change `linker` executable without `ProcessRunner`/`ProcessCap` authority fails with structured error.
* Non-source errors use the canonical unknown source span.

### D5: Generated-Source Generations

Implement quiescence generation tracking for `add_string` during intercept.

Scope:

* Generation counter per workspace.
* `add_string` during `TYPECHECKED` increments generation and re-enters parse/typecheck.
* Phase messages re-fire for the new generation.
* Linking blocked until latest generation reaches `PRE_CODEGEN` and `CODEGEN_DONE`.
* `add_string` during `PRE_LINK` remains unsupported in Phase D and produces a structured error if attempted.

Focused verification:

* A build script can observe `TYPECHECKED`, generate new source via `add_string`, and observe a second `TYPECHECKED` for the new source.
* Generation numbers in messages match.
* Linking does not start until all generations have completed codegen.
* Attempting `add_string` during `PRE_LINK` produces the expected structured error.

### D6: Parallel Workspaces

Implement `parallel(workspaces)` with the per-workspace state changes from §11.

Scope:

* Per-workspace Zcu, Sema state, MIR module, diagnostic emitter, LLVM context.
* Per-workspace OS thread under `parallel` to align with LLVM's threading model.
* Synchronized intern pool access.
* Parsed module cache synchronization.
* ProcessRunner reentrancy constraints verified and fixed if needed.
* `parallel(ws1, ws2)` schedules workspaces concurrently.
* Result order matches input order.
* Per-workspace message queues are independent.

Focused verification:

* Two workspaces compiling independent programs in parallel produce identical results to sequential compilation.
* Diagnostics include workspace identity.
* No data race detectable under thread sanitizer, if available.
* `parallel([ws])` with a single workspace behaves identically to `ws.compile()`.
* ProcessRunner-based actions used concurrently do not mutate process-global cwd/env and preserve independent capture/timeout state.

### D7: Migrate Existing Project Actions to Workspaces

Replace action implementations that shell out to `with build` with direct workspace usage. External tools such as `zig cc`, archive utilities, corpus test binaries, and tests intentionally exercising the CLI process boundary remain `ProcessRunner` calls.

Scope:

* `build_compiler.w` stage builders use `workspace.compile()` where they invoke the compiler only to compile With source.
* `build_emit_c.w` emit-C flows use `workspace.compile()` with `emit_c = true`.
* `build_pcre2.w` migration uses `workspace.compile()` with migration options where appropriate.
* `build_seed.w` continues using ProcessRunner where a different compiler binary or process boundary is the point of the action.
* `build_selfhost.w` test fixtures that compile With source use workspaces; fixtures that test the CLI process boundary remain as ProcessRunner calls.

Focused verification:

* All ported actions produce byte-equivalent output to pre-D7.
* Build performance is measured against the D0/pre-D7 baseline using the **median of 3 warm runs on the same machine**. A baseline warm-up run is executed first to populate filesystem caches and warm the loader; the three measured runs follow. Cold runs (first invocation after reboot or after substantial filesystem activity) are not used for the comparison because they measure cache-population cost, not compilation work.
* A wall-clock regression exceeding **20% on the full `with build :build` cycle**, or **50% on any individual ported action**, triggers investigation. Regressions below those thresholds are recorded but not blocking. Regressions above either threshold require either a fix or a documented follow-up issue before Phase D closes.
* Selfhost test fixtures pass.

### D8: DeclSummary-Driven Tooling Use Case

Implement one real compiler-tooling use case on `DeclSummary` and the message loop. Recommended: C migrator integration.

Scope:

* A migrator integration in `build.w` that:

  * Creates a workspace for migrated source.
  * Intercepts compilation.
  * On `TYPECHECKED`, inspects declarations via `DeclSummary`.
  * Verifies expected symbols are present.
  * Fails loudly on missing symbols.
* Optionally: generates additional source via `add_string` based on observed declarations.
* Optionally: extracts and uses `docs` strings from typechecked declarations.

Focused verification:

* The migrator integration replaces an existing external check or generation step.
* Output is equivalent to pre-D8.
* DeclSummary fields used are documented as the stable v1 set.

---

## 14. Verification Standard

Every code slice must pass:

```sh
out/bin/with build :build
out/bin/with build :fixpoint
out/bin/with build :test
```

The Make targets are Phase C compatibility wrappers and are not the verification path for Phase D. If the Make path and the `with build` path diverge during Phase D, that is a regression to investigate, not a checkpoint to pass through.

Each slice also requires the focused checks named in that slice.

D1 through D8 are separate slices. Each slice normally lands as one commit. D1 may land as D1a/D1b review commits within a single PR, with the full verification chain required at the PR's HEAD but not at the intermediate commit. Unrelated bug fixes must be separate commits with regression coverage.

If implementation uncovers a stdlib, runtime, or compiler bug, stop the current slice, fix the bug in its own commit with regression coverage, then resume from a clean tree. Do not bundle bug fixes into Phase D feature commits.

Docs-only changes do not require the full verification sequence but must be committed separately from code.

---

## 15. Audits and References

This document depends on the following pre-Phase-D artifacts:

* `docs/pre-phase-d-impl.md` — the pre-D work contract.
* `docs/audits/comptime-eval-audit.md` — ComptimeEval audit findings, absorbed into §3.
* `docs/audits/parallel-state-audit.md` — global state enumeration, absorbed into §11.
* `docs/audits/build-script-survey.md` — current build.w inventory, referenced by D7 scope.
* `docs/design/capability-dispatch.md` — capability mechanism design, absorbed into §4.
* `docs/design/build-options.md` — BuildOptions and CLI design, absorbed into §6.
* `docs/design/comptime-capability-syntax.md` — capability-bearing comptime syntax and Sema rules, reflected in §4 and §5.
* `docs/audits/d0-baseline.md` — verification baseline captured before D1 begins.

If any audit finding contradicts the design absorbed into this document, this document is updated and re-reviewed before implementation continues. Audit findings are the ground truth; the design conforms to them.

---

## 16. What This Document Is Not

This document does not specify pre-Phase-D work. That work is contracted in `docs/pre-phase-d-impl.md` and is presumed complete when D1 begins.

This document does not specify future phases E and beyond. It is scoped to Phase D.