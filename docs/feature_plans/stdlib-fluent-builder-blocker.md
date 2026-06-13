# Stdlib Fluent Builder Follow-Up

Status: partially resolved. `Vec.push` receiver-return chaining is implemented,
and `ProcessEnv.set` is a value-builder API. The remaining gap is type
inference for unannotated `Vec.new()` pipeline chains.

Several build-system APIs want this ergonomic shape:

```with
fn Type.method(mut self: Type, value: T) -> Type:
    self.field = self.field.updated(value)
    self
```

This is the natural builder pattern for value types. It should support both explicit reassignment and fluent chaining.

## Resolved: `Vec.new() |> push(...)`

Annotated action-argument chains now work:

```with
let args: Vec[str] = Vec.new() |> push("tool") |> push("--flag")
```

The remaining inference gap is the unannotated form:

```with
let args = Vec.new() |> push("tool") |> push("--flag")
```

`Vec.push` now returns the vector, but `Vec.new()` still does not receive enough type context through the pipeline to infer `T` from the later `push` argument.

## Resolved: `process_env().set(...)`

`ProcessEnv.set` is a value-builder method:

```with
pub fn ProcessEnv.set(self: ProcessEnv, name: str, value: str) -> ProcessEnv:
    var vars = self.vars
    vars.push(ProcessEnvVar { name, value })
    ProcessEnv { vars }
```

This supports temporary chaining:

```with
let env = process_env().set("NAME", "value").set("OTHER", "second")
```

## Remaining Resolution

The remaining coherent fix is type-context propagation through pipelines so the unannotated `Vec.new()` form can infer its element type from subsequent method calls.
