# Stdlib Fluent Builder Follow-Up — Superseded

**Status:** Superseded by specification §9.6 and decision D21
(2026-07-22). This file records the retired receiver-returning design; it is
not an implementation plan.

Replacement plan: `docs/feature_plans/d21-mutator-pipeline-implementation.md`.

The earlier design made `Vec.push` return the receiver so ordinary
return-value pipelines could chain:

```with
let args: Vec[str] = Vec.new() |> push("tool") |> push("--flag")
```

That contract is retired. A `mut self` method borrows the caller's place and
cannot also return a second non-Copy owner of the receiver. `Vec.push` is a
Unit-returning in-place mutator. The source form above remains the intended
surface, but D21 gives it sound place-threading semantics:

```with
// Conceptual lowering; no owned receiver is returned by push.
var hidden: Vec[str] = Vec.new()
hidden.push("tool")
hidden.push("--flag")
let args = hidden
```

The hidden place follows ordinary statement-temporary rules. It is moved into
`args` because it remains the final pipeline value. If a later non-Unit stage
switches the pipeline to another result, the hidden Vec drops at statement end.

The previous design also proposed this general pattern:

```with
fn Type.method(mut self: Type, value: T) -> Type:
    self.field = self.field.updated(value)
    self
```

That form is invalid for a non-Copy receiver when the return duplicates
ownership still held by the caller. Receiver-returning fluent methods are
consuming and use `move fn`; Unit-returning `mut fn` methods get pipeline
fluency from D21 instead. Copy results, tracked views, fresh owned results, and
owned projections moved out under reset-on-move remain valid `mut fn` returns.

`ProcessEnv.set` is a separate value-builder API, but its current implementation
also needs a D18/D21 ownership audit. It is declared with a borrowed receiver
and initializes a new `ProcessEnv` from `self.vars`; that is valid only if the
new value receives fresh independent ownership. A copied Vec header is an owned
alias and is forbidden. The implementation must either perform a genuine clone
or make `set` a consuming value-builder (`move fn`) that transfers the Vec:

```with
move fn set(name: str, value: str) -> ProcessEnv:
    var vars = move self.vars
    vars.push(ProcessEnvVar { name, value })
    ProcessEnv { vars }
```

The existing consuming/value call shape remains coherent under the latter
contract:

```with
let env = process_env().set("NAME", "value").set("OTHER", "second")
```

Type-context propagation through an unannotated `Vec.new()` pipeline remains a
separate inference concern. It must be solved under D21's place-threading
semantics, not by restoring an owned return from `Vec.push`.
