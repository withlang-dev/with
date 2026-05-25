# Design: Simplified Build Entry Point

Status: proposal.

## Problem

The current `build.w` entry point requires ceremony that every project
copies verbatim:

```with
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build().executable("my_app", "main.w")
    out = out.test("test", "test/*.w")
    out.default("my_app")
```

Three lines of boilerplate before you write a single meaningful line.
`comptime with BuildCtx as ctx:` is the capability-binding incantation.
`pub fn build -> Build:` is the well-known entry point. Every `build.w`
has them, and they teach nothing.

## Proposed Shape

```with
use with.build

fn build(out: Build) -> Build:
    out
        .binary("my_app", "main.w")
        .tests("test/")
```

### Changes

1. **`use with.build`** instead of `use std.build`. The build DSL is part
   of the `with` tool, not a general-purpose stdlib module. Rename signals
   that this is tool-mode-specific.

2. **Implicit capability binding.** The driver recognizes `fn build` (or
   `pub fn build`) with the signature `(Build) -> Build` as the build entry
   point. The driver constructs `BuildCtx` internally and passes a
   pre-constructed `Build` with package metadata already populated from
   `with.toml`. No `comptime with ... as ctx:` wrapper needed.

3. **`Build` passed in, not constructed.** The driver pre-populates the
   `Build` with the package name and version from `with.toml`. The user
   transforms it and returns it. No `ctx.new_build()` boilerplate.

4. **`.binary()` and `.tests()`** as ergonomic shorthand:
   - `.binary(name, entry)` = `.executable(name, entry)` (shorter, clearer)
   - `.tests(dir)` = `.test("test", dir ++ "*.w")` (common pattern)

5. **No explicit `.default()`** — if there's exactly one product target,
   it's the default. Explicit `.default()` only needed when ambiguous.

### Advanced: Capabilities on Demand

When you need `ToolFs`, `ProcessRunner`, or `Workspace`, access them
through the `Build` value:

```with
fn build(out: Build) -> Build:
    let fs = out.fs()
    let template = fs.read_text("templates/config.w")
    out
        .generated_source("out/gen/config.w", template)
        .binary("app", "main.w")
```

Or through a richer entry point when you need `ActionCtx`-level power:

```with
fn build(ctx: BuildCtx) -> Build:
    // full capability access, same as today minus the comptime wrapper
    ...
```

The driver detects the signature:
- `(Build) -> Build` — simple mode, pre-populated Build
- `(BuildCtx) -> Build` — full mode, raw capability access

### Migration Path

Both entry points coexist indefinitely. The `comptime with BuildCtx as ctx:`
form continues to work. The new form is syntactic sugar the driver
recognizes. No breaking change.

### What the Driver Does

When the driver finds `build.w` without a `comptime with` block but with
a matching `fn build` signature:

1. Parse `with.toml` for package name/version
2. Construct a `Build` value pre-populated with package metadata
3. Call `build(pre_build)` in tool-mode comptime
4. Receive the returned `Build` graph
5. Validate and execute as today

### Action Functions

Actions stay as-is — they receive `ActionCtx`:

```with
fn generate(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    fs.write_text(ctx.output(), "pub let version = \"1.0\"\n")
    0

fn build(out: Build) -> Build:
    out
        .action("generate", generate, output: "out/gen/version.w")
        .binary("app", "main.w")
```

## Summary

| Today | Proposed |
|-------|----------|
| `use std.build` | `use with.build` |
| `comptime with BuildCtx as ctx:` | (implicit) |
| `pub fn build -> Build:` | `fn build(out: Build) -> Build:` |
| `ctx.new_build().executable(...)` | `out.binary(...)` |
| `out.test("test", "test/*.w")` | `out.tests("test/")` |
| `out.default("app")` | (implicit when unambiguous) |

Seven files, zero boilerplate. A new user writes the interesting part first.
