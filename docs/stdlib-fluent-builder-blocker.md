# Stdlib Fluent Builder Blocker

Status: unresolved design question.

Several build-system APIs want the same ergonomic shape:

```with
fn Type.method(mut self: Type, value: T) -> Type:
    self.field = self.field.updated(value)
    self
```

This is the natural builder pattern for value types. It should support both explicit reassignment and fluent chaining. In practice, two current gaps make the pattern unreliable for build-system code.

## Workaround 1: `Vec.new() |> push(...)`

The desired action-argument style is:

```with
let args = Vec.new() |> push("tool") |> push("--flag")
```

That currently fails for two reasons tracked during the pipeline work:

- `Vec.push` does not return the vector, so a fully fluent chain cannot continue after the first push.
- `Vec.new()` does not provide enough type context through the pipeline in this position.

The cleanup in commit `e3f1260` used the current workable form instead:

```with
var args: Vec[str] = Vec.new()
args |> push("tool")
args |> push("--flag")
```

That avoids helper functions, but it is still not the fluent builder form the build API wants.

## Workaround 2: `process_env().set(...)`

`ProcessEnv.set` is already a value-returning builder method:

```with
pub fn ProcessEnv.set(mut self: ProcessEnv, name: str, value: str) -> ProcessEnv:
    self.vars.push(ProcessEnvVar { name, value })
    self
```

The desired use is:

```with
let env = process_env().set("NAME", "value")
```

During commit `a86f689`, generated action-runner code had to use an explicit variable and reassignment instead:

```with
var child_env = process_env()
child_env = child_env.set("NAME", "value")
```

The direct fluent call hit the compiler rule that mutating methods require a place receiver. A temporary value such as `process_env()` is not currently accepted as the receiver for a `mut self -> Self` builder call.

## Possible Resolutions

There are two coherent ways to close this gap.

1. Fix the language/compiler so `mut self -> Self` methods can be called on temporaries when the method consumes and returns the value. This would make `process_env().set(...)` legal and would preserve the natural value-builder API shape.

2. Change stdlib builder APIs to avoid mutating temporary receivers. That could mean free functions, constructors that take all fields at once, or non-mutating methods whose implementation reconstructs the value instead of mutating `self`.

The first option is more consistent with the builder style already used by `Target`, `Build`, and `ProcessEnv`. The second option may be simpler mechanically, but it would make user-facing build code less direct.

Until this is resolved, build actions should use explicit local variables for these builders instead of adding helper functions that encode the workaround in more places.
