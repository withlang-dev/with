# 18.5a Project Builds

`build.w` is executable build behavior written in With. `with.toml`
is declarative package configuration. Imperative build concerns belong
in `build.w`, not in `with.toml`.

Allowed in `with.toml`:

- Package identity such as name and version
- Dependencies and version constraints
- Target defaults and feature flags
- C include paths, defines, link libraries, and link search paths
- Publishing metadata and lint/runtime policy

Not allowed in `with.toml`:

- Conditionals or loops
- Generated-file steps
- Asset pipelines or shader compilation
- Custom shell commands
- Target graph construction
- Platform-specific branching logic
- Multi-binary or multi-library build behavior

Those belong in `build.w`.

For simple projects with no `build.w`, the compiler synthesizes the
default recipe:

```
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    let info = ctx.project_info()
    ctx.new_build().executable(info.package_name(), "src/main.w")
```

Build targets have no implicit peak-memory budget. RSS measurement and
reporting do not by themselves make a successful target fail.
`Target.rss_limit(bytes)` explicitly sets a positive i64 byte budget for
that target; a measured peak strictly above the budget fails the build
with the target name, measured bytes, and configured limit. The policy
belongs to the declaring graph, survives graph caching and target
selection, and is not inherited by nested projects. Changing a budget
invalidates that target's cached execution. The compiler repository's
self-build targets explicitly opt into their internal regression budget;
ordinary applications do not inherit it.

The standard build graph API lives in `std.build`. It defines
`Package`, `Build`, `Target`, `BuildKind`, `BuildTarget`, and
`OptimizeMode`, plus target construction methods such as
`Build.executable`, `Build.library`, `Build.test`,
`Build.generated_source`, `Target.optimize`, `Target.link_system_lib`,
`Target.include_path`, and `Target.define`.

`build.w` runs as capability-bearing comptime, not ordinary pure
`comptime`. Build code may perform effects only through `std.build`
capabilities supplied by the driver. Those capabilities grant authority,
not nondeterminism: any output-affecting effect must be deterministic
over declared, tracked, or pinned inputs, or it must be recorded as
nondeterministic and rejected in strict and self-hosting builds.
Untrusted fetched build code receives only the capabilities the driver
grants it; compiling a project does not give dependencies ambient access
to the user's filesystem, environment, network, process table, or
toolchain.

The compiler driver discovers `build.w`, evaluates the `build` entry
point with a driver-minted `BuildCtx`, consumes the returned typed build
graph, and builds executable, library, and test targets. Per-target
`link_system_lib`, `include_path`, and `define` settings are honored by
the corresponding compile/test path. `Build.generated_source(path,
contents)` declares a generated source file to write before target
compilation; generated paths are project-relative and escaping paths
must fail loudly. `BuildTarget` can represent non-native targets, but
until cross-target codegen/linking is implemented those selections must
fail loudly instead of falling back to native output. Unsupported graph
features must likewise fail loudly instead of being ignored. A compiler
version that recognizes project `build.w` files but does not execute
them must likewise fail loudly instead of silently building some other
target.
