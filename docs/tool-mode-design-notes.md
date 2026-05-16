# Tool-Mode Design Notes

Status: design sketch, not an implementation contract.

With needs a privileged build/metaprogram context similar to Jai's compiler metaprogram, but ordinary `comptime` should stay deterministic and side-effect-free. Tool mode is the place for filesystem, process, artifact, workspace, and compiler-driver operations.

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
