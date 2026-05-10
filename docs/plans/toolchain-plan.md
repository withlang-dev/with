# Toolchain Implementation Plan

Source: `docs/toolchain.md`.

## Completed In This Slice

- Build doctrine basics:
  - `with build` can infer `src/main.w` from a project `with.toml`.
  - `[package].name` / `[project].name` choose the default output name.
  - Imperative manifest entries such as `[build]` fail loudly and point users
    to `build.w`.
  - A project `build.w` is not silently ignored; until tool-mode execution is
    implemented, `with build` fails loudly and direct-source builds remain
    available.
- `std.build` initial typed graph API:
  - `Build`, `Target`, `Package`, `BuildKind`, `BuildTarget`,
    `OptimizeMode`.
  - Target builder methods for executable/library/test, target selection,
    optimization mode, system libraries, include paths, and defines.
  - Non-native target selections are represented in the graph and fail loudly
    until cross-target codegen/linking is implemented.
- `std.context` initial scoped execution context:
  - `Context` as an ephemeral stdlib type.
  - `TraceId`, `CancellationToken`, `NoopLogger`, `default_context()`,
    `Context.with_temp()`.
- `std.alloc.TempArena`:
  - `scratch_arena()`, `TempArena.alloc`, `TempArena.alloc_zeroed`,
    `TempArena.reset`.
  - `TempArena.drop()` resets outstanding scratch allocations at scope exit.
- `@[specified]` discriminant enums:
  - Parser flagging.
  - Diagnostics for missing explicit backing type and missing explicit
    discriminant values.
  - Rendering support.
- `c_import(..., allow_untranslated: ...)` parsing and rendering:
  - AST packing for link-library count plus allow-list count.
  - Resolve/frontend cache key includes the allow-list.
- PCRE2 reference source location:
  - `Makefile` fetches PCRE2 10.47 into `out/pcre2_reference/...` instead of
    using `.reference` as mutable staging.
- Embedded stdlib generator:
  - Replaced `scripts/generate_embedded_stdlib.py` with
    `src/tools/generate_embedded_stdlib.w`.
  - Make builds and runs the With tool.
- Script pruning/dependency cleanup:
  - Only Make-touched scripts remain live.
  - Make-touched scripts no longer shell out to Python or Perl.
- Main specification updates:
  - Documented `@[specified]`, `TempArena`, `allow_untranslated`,
    `std.context`, `std.build`, and `build.w` doctrine in
    `docs/with-specification.md`.
- `with test` synthetic-main path:
  - Attribute-only test files now build only the synthesized test source,
    avoiding the previous no-`main` linker stderr leak before the real test
    binary was built.
- Initial `build.w` tool-mode execution:
  - `with build` compiles and runs a generated tool-mode runner for project
    `build.w`.
  - The runner calls `build(new_build(package))` and writes a stable
    `std.build` graph for the driver.
  - Executable targets are built from that graph, including
    `link_system_lib` entries.
  - `include_path` entries are resolved relative to the project root and
    passed through to `c_import`.
  - `define` entries are passed through to `c_import` as C preprocessor
    definitions, including `NAME=value` forms.
  - Test targets run through the normal `with test` pipeline and inherit
    `include_path`, `define`, and `link_system_lib` build settings.
  - Library targets emit static archives under `out/lib` and inherit
    `include_path`, `define`, and `link_system_lib` build settings.
  - Unsupported graph features fail loudly instead of being ignored.

## Verified

- `make build`
- `make fixpoint`
- Focused behavior and compile-error tests for `std.context`, `TempArena`, and
  `@[specified]`.
- `WITH=out/bin/with ./scripts/run_cli_selfhost_tests.sh`
- `make test`
- `make regex-migrate`
- `make regex-build`
- `make regex-test`

## Remaining

- Platform-independent build replacement for Make itself. The current work
  removes Python from the build path but does not yet replace Make/shell as the
  orchestration layer.
- Complete `build.w` graph execution beyond executable, library, and test
  targets: actual cross-target codegen/linking and custom source-generation
  steps still need driver support.
- Read-only `ProjectInfo`, compiler hooks, source emission, and blessed derives
  remain future phases per `docs/toolchain.md`.
