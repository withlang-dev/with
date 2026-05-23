# Capability Dispatch Design

Status: pre-Phase-D design for D1 implementation.

This document specifies how user-level capability method calls reach
compiler-internal implementations during capability-bearing comptime
evaluation. It answers P4 from `docs/completed/pre-phase-d-plan.md`.

## Goals

- Preserve the public capability-parameter model from
  `docs/tool-mode-design-notes.md`.
- Replace generated native runner binaries for `build.w` and action execution.
- Keep ordinary comptime pure; only driver-minted capabilities can perform
  privileged operations.
- Keep capability values boundary-safe: user code sees ordinary typed values,
  but the evaluator stores abstract handles, not raw compiler pointers.
- Make adding future capabilities mechanical.

## Non-Goals

- D1 does not implement message-loop suspension. That belongs to D4.
- D1 does not implement parallel workspaces. That belongs to D6.
- D1 does not redesign all stdlib build APIs. It preserves current semantics
  and changes only the execution path.

## Public Surface

The public source shape remains ordinary With:

```with
use std.build

pub fn build(ctx: BuildCtx) -> Build:
    let fs = ctx.fs()
    let text = fs.read_text("with.toml")
    ...

fn generate(ctx: ActionCtx) -> i32:
    ctx.fs().write_text(ctx.output(), "ok\n")
    0
```

Existing `pub fn build(ctx: BuildCtx) -> Build` remains the conventional
entry point. A function whose parameter list includes a tool capability type is
treated as a capability-bearing comptime entry point when the driver invokes
it. An explicit `comptime fn` marker is not required for D1.

Capability methods remain declared in `lib/std/build.w` and
`lib/std/compiler.w` so normal sema can typecheck user code. During D1
evaluation, the evaluator intercepts capability method calls before executing
their With bodies. The With bodies may remain temporarily for the old runner
path while D1 is in progress, but the D1-complete path does not rely on native
runner execution.

## Capability Identification

Phase D uses an explicit compiler registry of capability types. A capability
type is identified by stable module path plus type name, not by raw symbol id.

Initial registered types:

| Module | Type |
| --- | --- |
| `std.build` | `BuildCtx` |
| `std.build` | `ProjectInfo` |
| `std.build` | `Diagnostics` |
| `std.build` | `SourceEmitter` |
| `std.build` | `ToolFs` |
| `std.build` | `ProcessRunner` |
| `std.build` | `ActionCtx` |
| `std.compiler` | `Diagnostics` |
| `std.compiler` | `SourceEmitter` |

The current compiler already has a hardcoded path/name check in
`Sema.is_tool_capability_type`; D1 should replace or wrap that with a single
registry query so sema and evaluator use the same source of truth.

Future extension path:

1. Add the public capability type and method declarations to a stdlib module.
2. Add the capability type to the compiler registry.
3. Add handler entries for each effectful method.
4. Add construction rules for driver-minted instances.
5. Add unforgeability and dispatch tests.

An attribute such as `@[tool_capability]` may replace registry entries later,
but D1 should not depend on a new attribute system. The registry is explicit,
reviewable, and sufficient for the initial capability set.

## Runtime Representation in the Evaluator

D1 introduces a capability value representation in comptime evaluation:

```text
CapabilityValue {
    capability_kind: CapabilityKind
    handle_id: i32
    generation: i32
}
```

This may be implemented as a new `ComptimeValueKind.CV_CAPABILITY` or as an
equivalent tagged value inside the evaluator. The important property is that
the evaluator stores an abstract handle. It does not expose a raw pointer,
process environment token, or serialized constructor to user code.

Each capability-bearing evaluation owns a `CapabilityStore`:

```text
CapabilityStore {
    handles: Vec<CapabilityRecord>
}

CapabilityRecord {
    kind: CapabilityKind
    generation: i32
    payload: compiler-owned data
}
```

The payload is private to the compiler. User code can pass, borrow, return, and
capture the capability value, but cannot inspect or construct the payload.

Driver entry points mint the initial handles:

- build graph evaluation mints `BuildCtx`
- action evaluation mints `ActionCtx`
- compiler hook evaluation mints hook capabilities when that path moves
  in-process

Capability methods return either ordinary comptime values or more capability
handles. For example, `BuildCtx.fs()` returns a `ToolFs` handle backed by the
same project root and write-scope policy.

## Dispatch Point

The dispatch point is method-call evaluation in `ComptimeEval`. Today the
evaluator has special cases for static methods, `Vec`, and `HashMap`; every
other method receiver fails as not comptime-evaluable. D1 inserts capability
dispatch before that failure:

```text
eval_method_call(receiver, method, args):
    receiver_value = eval(receiver)
    if receiver_value is CapabilityValue:
        return dispatch_capability_method(receiver_value, method, args)

    existing static/Vec/HashMap handling
    existing failure
```

Dispatch is based on the receiver's `CapabilityKind` plus the stable method
name. The evaluator should not execute the With body for capability methods.

## Handler Table

Compiler-internal handlers live behind one dispatch table:

```text
CapabilityDispatchTable:
    (CapabilityKind, method_name) -> CapabilityHandler

CapabilityHandler:
    (CapabilityDispatchContext, CapabilityHandle, Vec[ComptimeValue])
        -> CapabilityResult
```

`CapabilityDispatchContext` gives handlers access to driver-owned state:

- current project root and package info
- build graph output accumulator
- action target metadata
- diagnostics sink
- generated source sink
- filesystem implementation and write-scope checks
- process runner implementation
- current `Zcu`/compilation only when a method explicitly requires it

Handlers validate:

- receiver handle exists
- receiver kind matches the registered method receiver kind
- generation matches the current store entry
- argument count and argument value types are correct
- the operation is allowed by the receiver payload, such as write scopes

On violation, the handler returns a structured evaluator error. It must not
panic, silently return a default value, or continue after a capability
violation.

## Token Validation

D1 removes environment-variable tokens from the build/action capability path.
The security boundary becomes handle validation in `CapabilityStore`.

Validation happens on every capability method call:

1. The receiver value must be `CapabilityValue`.
2. `handle_id` must be in range.
3. The record's `generation` must equal the value's generation.
4. The record's `kind` must equal the method receiver's registered kind.
5. The current evaluator must own the `CapabilityStore` containing the handle.

If any check fails, evaluation aborts with a tool-capability-violation
diagnostic that includes the capability type and method name.

This preserves unforgeability:

- User code cannot construct `CapabilityValue` through a struct literal.
- Direct calls to `.__driver_new` remain rejected outside driver-visible code.
- Field access on tool capability values remains rejected.
- Serialized handle ids are not accepted from user code.

## Public Method Backing

For D1, capability method declarations should remain ordinary declarations in
stdlib modules for typechecking and editor tooling. The evaluator dispatches by
receiver kind and method name before interpreting those bodies.

Longer term, capability methods can become explicit intrinsic stubs, but that
is not required for D1. If a capability method body is ever reached outside the
evaluator-backed tool path, it must fail loudly rather than silently perform a
partial operation.

## Initial Handler Set

Minimum D1 handlers needed for current `build.w` and action scripts:

### `BuildCtx`

- `project_info`
- `new_build`
- `diagnostics`
- `source_emitter`
- `fs`
- `process_runner`

### `ActionCtx`

- `target_name`
- `project_info`
- `diagnostics`
- `fs`
- `process_runner`
- `inputs`
- `outputs`
- `args`
- `output`

### `ProjectInfo`

- `package_name`
- `package_version`
- `project_root`

### `Diagnostics`

- build diagnostics methods currently used by `build.w`
- compiler-hook diagnostics methods when hooks move in-process

### `SourceEmitter`

- `generated_source`
- `emit_source` for compiler hooks when hooks move in-process

### `ToolFs`

- `exists`, `host_exists`, `is_dir`, `mkdir_all`, `read_text`, `list_files`,
  `write_text`, `copy_file`, `chmod`, `rename`, `remove_file`, `remove_tree`,
  `copy_tree`, `symlink`

### `ProcessRunner`

- `run`
- `run_capture`
- `run_capture_with_env`
- `run_capture_cwd`
- `run_capture_cwd_with_env`
- `run_capture_input`
- `spawn_capture`
- `wait`

## Return Values

Handlers return `ComptimeValue` values:

- `i32`, `bool`, and `str` map to existing scalar/string values.
- `Vec[str]` and other supported containers use the evaluator's existing
  comptime collection representation.
- `Build`, `Target`, `GeneratedSource`, `ToolProcessResult`, `ProcessEnv`, and
  other ordinary structs use existing struct value representation.
- Capability-returning methods allocate a new handle in `CapabilityStore` and
  return a `CapabilityValue`.

If an existing return type cannot be represented by `ComptimeEval`, D1 must add
the representation or fail the D1 slice. It must not route only that method
through a generated native runner as a fallback.

## Adding Future Capabilities

New capabilities follow a mechanical path:

1. Define the public type and method declarations.
2. Add a `CapabilityKind`.
3. Register the stable module path and type name.
4. Add method handlers to the dispatch table.
5. Add sema construction/field-access tests.
6. Add evaluator dispatch tests.

Capabilities should start coarse. Split only when reuse, security, or testing
requires it.

## Error Semantics

Capability dispatch failures are build script errors, not panics:

- unknown capability method: typechecked code should normally prevent this; if
  reached, report an internal capability dispatch error
- invalid handle: report tool-capability violation
- sandbox violation: report the same user-facing ToolFs diagnostic as today
- process failure: return the same `ToolProcessResult`/rc semantics as today
- handler internal failure: report a diagnostic and return evaluator error

No handler may silently produce a default value to let evaluation continue.

## D1 Implementation Checklist

1. Add the capability registry shared by sema and evaluator.
2. Add evaluator capability value representation and `CapabilityStore`.
3. Add driver entry points that mint `BuildCtx`/`ActionCtx` handles and invoke
   capability-bearing functions.
4. Add the dispatch table and initial handlers.
5. Route capability receiver method calls through dispatch.
6. Replace build graph/action generated runner execution with evaluator
   dispatch.
7. Preserve existing capability unforgeability diagnostics.
8. Run P7 behavior tests against both normal build graph construction and
   action execution.
