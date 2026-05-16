# Tool-Mode Design

Status: canonical design. Implementation pending.

This document defines how privileged "tool-mode" operations are exposed in With. It supersedes prior design sketches; earlier options are retained at the end of the file as historical context.

### The Three Axes

The load-bearing insight: discovery, capability, and phase are independent axes. Earlier designs collapsed two or three of them onto a single mechanism (path magic, `tool fn`, `#run`). The clean design separates them.

```
Discovery:   how the driver finds the function
Capability:  what privileged operations the function can perform
Phase:       when the driver invokes the function
```

Pick the right answer for each axis independently.

### The Doctrine

> Tool power in With is capability-based.
>
> The compiler driver discovers tool entry points by convention or annotation. It invokes ordinary With functions and passes unforgeable capability values. The capability parameters determine what privileged operations are available. Compiler phases determine when hooks run, not what power they have. Ordinary comptime remains pure and deterministic. Capabilities are abstract handles whose APIs must be implementation-boundary-safe. Tests receive mock or sandboxed capabilities from the test driver.

### The Seven-Point Design

1. `build.w` is a conventional driver-discovered entry point.
2. `pub fn build(ctx: BuildCtx) -> Build` is an ordinary function.
3. `BuildCtx` and related objects are unforgeable capabilities.
4. Helper functions receive only the capabilities they need.
5. Compiler hooks later use annotations for scheduling only.
6. Ordinary `comptime` stays pure and deterministic.
7. Implementation may be same-process, separate binary, or RPC-backed, but the user model remains capability parameters.

### Initial Capability Set

Start coarse. Split only on demonstrated reuse, security, or testing need.

```
BuildCtx        — top-level build entry capability
ProjectInfo     — read-only access to project metadata and structure
Diagnostics     — emit warnings and errors
SourceEmitter   — generate source files into a workspace
ToolFs          — filesystem read/write
ProcessRunner   — execute external processes
```

### Operational Principle

> Start with coarse capabilities. Split only when there is a demonstrated reuse, security, or testing reason.

### Load-Bearing Requirements

These are not optional. The design fails if any of these are not met.

**1. Boundary-safe capabilities.**

Capability values are abstract handles. Their API must not require shared address space. Implementations may back them with direct pointers, serialized handles, RPC channels, or driver-managed tokens. The user-facing model is the same in all cases.

This means capability APIs cannot expose raw pointers, cannot assume same-process memory, and cannot rely on the caller and callee sharing an address space.

**2. Unforgeable construction.**

Tool capability types are constructible only by the compiler driver or by explicitly privileged test harnesses. User code may receive, pass, borrow, store locally, and call methods on capability values, but may not construct or deserialize them.

Opaque types alone are insufficient because the defining module can still construct them. The implementation must use one of:

- driver-intrinsic constructors
- stdlib modules compiled with privileged visibility
- sealed constructors unavailable outside the driver
- opaque handle values whose tokens are validated by the driver

The choice of mechanism is open; the property is not.

**3. Capabilities in closures and generics.**

Capabilities are ordinary values for parameter passing and closure capture. Capturing a capability in a closure gives that closure the same tool power, subject to ordinary escaping rules. Capability-bearing closures must not escape into runtime artifacts.

Example:

```with
fn run_all[T](items: Vec[T], action: fn(T)):
    for item in items:
        action(item)

fn generate_all(fs: ToolFsWrite, names: Vec[str]):
    run_all(names, name => fs.write_file(name, render(name)))
```

This works. The closure captures `fs`. The closure inherits `fs`'s privilege. The closure cannot be stored in a non-tool data structure that escapes to runtime code.

**4. Sanctioned test mocks.**

Tests receive mock or sandboxed capability implementations through the test driver. User code still cannot forge production capabilities. Mock capabilities preserve the same public API and may record calls, use an in-memory filesystem, or deny operations.

Example:

```with
test fn writes_version_file(fs: MockToolFsWrite):
    generate_version_file(fs, PackageInfo { name: "app", version: "1.0.0" })
    assert_eq(fs.read("build/version.w"), expected)

test fn build_declares_app(ctx: MockBuildCtx):
    let build = build(ctx)
    assert(build.has_executable("app"))
```

### Open Implementation Questions

These are the questions the design deliberately leaves open. They must be answered during implementation, not now.

1. **Unforgeability mechanism.** Which of the four options above (driver intrinsics, privileged stdlib visibility, sealed constructors, validated tokens) does the implementation use? May differ per capability type.

2. **Closure escape detection.** How does the compiler enforce "capability-bearing closures must not escape into runtime artifacts"? Likely requires lifetime/effect tracking on capability-capturing closures.

3. **Annotation mechanism for `@[compiler_hook]`.** This is registration/discovery machinery, not a privilege model. It needs its own design: how hooks are listed, how they compose, what happens with multiple hooks for the same phase, how hook ordering is determined.

4. **Mock capability provisioning.** How does the test driver construct mock capabilities given the unforgeability requirement? Likely: test builds compile with a `test` privilege that the production driver does not have; or mock types are a separate set of capability types accepted by all the same APIs.

5. **Cross-implementation capability transport.** If a same-process implementation later moves to separate-binary or RPC, what does the migration look like? The user model is stable by design; the open question is what serialization format or handle protocol is used.

### Historical Context

These options were considered and rejected in favor of the capability-parameter doctrine above. Retained for reference.

## Option 1: `tool fn` and `tool { ... }`

Add a first-class tool-mode marker:

```with
tool fn build(ctx: BuildContext) -> Build:
    let w = ctx.create_workspace("app")
    ctx.add_source_file(w, "src/main.w")
    ctx.build(w)

tool:
    generate_bindings()
```

A `tool fn` can call ordinary functions and pure `comptime` helpers, but only tool-mode code can call tool APIs such as workspace creation, source injection, process execution, downloads, and artifact promotion. A `tool` block is the block-level form for one-off build actions.

Pros:
- Makes the capability boundary visible in source.
- Gives sema a simple rule: tool APIs require tool context.
- Scales beyond `build.w` to future compiler hooks, generators, and package tools.
- Keeps ordinary `comptime` pure.

Cons:
- Adds a new language mode and keyword-level surface.
- Requires call-graph checking so tool-only effects cannot leak into runtime code.
- Needs clear rules for whether `tool fn` emits runtime code, tool code only, or both.

## Option 2: `build.w` Is Special Tool Entry Point

Keep syntax unchanged. The compiler treats `build.w` as a known tool-mode entry point and exposes `std.build`/`std.compiler` APIs only while compiling that file and its tool-only imports.

```with
use std.build

pub fn build(ctx: BuildContext) -> Build:
    ...
```

Pros:
- Minimal new syntax.
- Good enough to replace Make and scripts.
- Easy mental model: `build.w` is a build script, not application code.
- Similar to Rust's separate `build.rs` entry point, but written in With.

Cons:
- Tool-ness is file/path convention, not explicit in declarations.
- Harder to reuse tool functions from normal modules without import-mode rules.
- Does not naturally support future non-build compiler metaprograms.
- Can become another special case in the driver instead of a general model.

## Option 3: Jai-Style Compile-Time Run Marker

Introduce an explicit run marker that executes a function or block during compilation in a compiler workspace context:

```with
#run build()

fn build(ctx: BuildContext):
    let w = ctx.create_workspace("app")
    ctx.add_source_file(w, "src/main.w")
```

The marker creates the tool-mode context. Functions reachable from that entry are checked under tool-mode rules.

Pros:
- Closest to Jai's model.
- Allows ordinary source files to contain the metaprogram entry point.
- Naturally supports generated source and phase-oriented compiler work.
- The execution site is explicit.

Cons:
- `#run` is a new directive style that does not otherwise fit current With syntax.
- It risks blurring pure `comptime` and tool execution unless the distinction is very strict.
- More complex for package builds: users must understand both default driver behavior and explicit run markers.

## Tentative Recommendation

Use Option 1 as the long-term language model, with Option 2 as the short-term bootstrap shape.

In the near term, `build.w` can remain the special tool entry point so we can finish Make replacement without designing the entire compiler-as-library surface. But the APIs should be shaped as if they require an explicit tool context:

```with
pub fn build(ctx: BuildContext) -> Build
```

Then the language can later add `tool fn` / `tool { ... }` without changing the core API. This avoids turning ordinary `comptime` into an effectful scripting language, avoids making path-based `build.w` magic permanent, and gives the compiler a clean sema rule: privileged compiler-driver capabilities require tool context.
