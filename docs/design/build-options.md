# BuildOptions Design

Status: pre-Phase-D design for D2 implementation.

This document specifies the unified build option model and CLI integration
plan required before Phase D workspaces can become the driver primitive.

## Goals

- Parse CLI flags once into structured option values.
- Stop passing long positional option lists through `src/main.w`.
- Give `Compilation`, build graph targets, and future `Workspace` APIs the
  same normalized option representation.
- Preserve every current CLI flag and diagnostic behavior unless a change is
  explicitly listed as a compatibility break.

## Current CLI Survey

### Command Selection

The command is `argv[1]`. A source file ending in `.w` in command position is
treated as implicit `run`.

Current commands:

- `build`
- `run`
- `ir`
- `ast`
- `check`
- `tokens`
- `test`
- `bench`
- `version` / `--version`
- `help` / `--help` / `-h`
- `clean`
- `init`
- `get`
- `remove`
- `lsp`
- `migrate`
- `fmt`
- `repl` and `doc` are recognized but report not implemented

### General Compile Flags

| Flag | Current effect |
| --- | --- |
| `-O0` | optimization level 0 |
| `-O1` | optimization level 1 |
| `-O2` | optimization level 2 |
| `-O3` | optimization level 3 |
| `--release` | raises optimization to at least 2 and disables debug info |
| `-g0` | disables debug info |
| `-o <path>` | output path |
| `--output=<path>` | output path |
| `--alloc` | enables allocation mode |
| `--no-std` | disables standard library support |
| `--freestanding` | alias for `--no-std` plus no prelude |
| `--no-prelude` | disables implicit prelude import |
| `--prelude=full` | full implicit prelude |
| `--prelude=core` | core implicit prelude |
| `--prelude=none` | no implicit prelude |

Default optimization:

- `build`, `run`, `test`, and implicit `.w` run default to `-O1`.
- Other commands default to `-O0`.

### Build-Only Flags

| Flag | Current effect |
| --- | --- |
| `--emit-c` | `with build` emits C instead of a binary; rejected for build.w tool-mode |
| `--emit-obj` | `with build` emits an object file instead of a binary; rejected for build.w tool-mode |
| `:target` | selects a build.w target |
| `--graph` | prints selected build graph text and exits |
| `--dry-run` | same selected graph output path as `--graph` today |
| `--no-deps` | for build.w action targets only; selects the named action without dependencies |

### Check/Debug Dump Flags

These are meaningful with `check`:

- `--dump-tokens`
- `--dump-ast`
- `--dump-resolved`
- `--dump-typed`
- `--dump-project-info`
- `--dump-mir`
- `--dump-async-mir`
- `--deterministic` affects token/AST style dumps where used

### Test and Bench Flags

| Flag | Current effect |
| --- | --- |
| `-v`, `--verbose` | verbose test output |
| `-q`, `--quiet` | quiet test output; overridden by verbose |
| `--filter=<text>` | substring filter for test or bench names |
| `--filter <text>` | same |
| `-f <text>` | same |

Test directive `//! extra-args:` may also inject compile flags such as `-O*`,
`--no-std`, `--freestanding`, and `--prelude=*` for individual test files.

### One-Liner Flags

| Flag | Current effect |
| --- | --- |
| `-e <code>` | compile and run code as top-level statements |
| `-n <code>` | run code for each stdin line as `line`/`nr` |
| `-p <code>` | like `-n`, then print `line` |
| `-- <args>` | pass remaining args to one-liner `args` |

One-liners also accept the general compile flags above.

### Migrator Flags

| Flag | Current effect |
| --- | --- |
| `-o <path>` | migrated output path |
| `-I <dir>` | add include path |
| `-include <header>` | add forced include |
| `-D <define>` | add C preprocessor define |
| `--check` | recognized, mode not implemented |
| `--diff` | recognized, mode not implemented |
| `--stats` | recognized, mode not implemented |
| `--no-c-export` | do not emit `@[c_export]` attributes / local externs |
| `--c-export-functions` | preserve C ABI symbols for translated function definitions |
| `--convert-goto-to-structured` | enable structured goto conversion |
| `--prefer-brace` | emit brace-form With |
| `--prefer-colon` | emit colon-form With |
| `--prefer-curly` | rejected; renamed to `--prefer-brace` |
| `--width-slice <n>` | set PCRE2 width slice |
| `--shared-defs <module>` | enable shared definitions mode |
| `--migrate-one <basename>` | directory migration internal one-file mode |
| `--shared-fragment <path>` | directory migration internal fragment path |
| `--exclude <basename>` | exclude basename during directory migration |
| `--exclude=<basename>` | same |
| `--ir-roundtrip` | hidden developer test mode |

### Format Flags

| Flag | Current effect |
| --- | --- |
| `-w` | write formatted files |
| `-l` | list files that would change |
| `--check` | fail if formatting changes are needed |
| `--prefer-brace` | brace-form style |
| `--prefer-colon` | colon-form style |
| `--prefer-curly` | rejected; renamed to `--prefer-brace` |

### Init Flags

| Flag | Current effect |
| --- | --- |
| `--name <name>` | package name |
| `--lib` | create a library template |

## Proposed Option Types

### `BuildOutputKind`

```with
pub enum BuildOutputKind: i32:
    Binary = 0
    Object = 1
    C = 2
    LlvmIr = 3
    Archive = 4
```

`Archive` is used by build graph/library paths, not current top-level CLI
`with build`.

### `PreludeMode`

Use the existing numeric modes, but move them into a shared driver options
module:

```with
pub enum PreludeMode: i32:
    Full = 0
    Core = 1
    None = 2
```

### `BuildOptions`

```with
pub type BuildOptions {
    source_path: str,
    output_path: str,
    output_kind: BuildOutputKind,
    opt_level: i32,
    debug_info: bool,
    no_std: bool,
    alloc_mode: bool,
    prelude_mode: PreludeMode,
    deterministic: bool,
    target: BuildTarget,
    include_paths: Vec[str],
    defines: Vec[str],
    link_libs: Vec[str],
    compiler_hooks_enabled: bool,
}
```

Field details:

| Field | Default | Set by | Read by | Validation |
| --- | --- | --- | --- | --- |
| `source_path` | `""` | positional source or project default | driver/workspace compile entry | required for direct compile/run/check except build.w project default |
| `output_path` | `""` | `-o`, `--output=` or project default | build/link/emit paths | cannot be used with multi-target build.w outputs |
| `output_kind` | `Binary` | command plus `--emit-c`/`--emit-obj` | workspace compile/emit | `--emit-c` and `--emit-obj` mutually exclusive |
| `opt_level` | command default | `-O*`, `--release` | sema/codegen/backend | 0 through 3 |
| `debug_info` | `true` | `-g0`, `--release` | codegen/link | boolean |
| `no_std` | `false` | `--no-std`, `--freestanding` | frontend/imports/link | if `--freestanding`, prelude becomes `None` |
| `alloc_mode` | `false` | `--alloc` | compilation config | boolean |
| `prelude_mode` | `Full` | `--no-prelude`, `--freestanding`, `--prelude=*` | frontend/Zcu | full/core/none only |
| `deterministic` | `false` | `--deterministic` | dumps/tests that need stable formatting | boolean |
| `target` | host/native | build target config | build graph/workspace | non-host targets may remain unsupported until cross work resumes |
| `include_paths` | empty | build target fields; future CLI | frontend/c_import/codegen | project-relative or absolute paths accepted as today |
| `defines` | empty | build target fields; future CLI | tests/build settings | validate with current build graph define rules |
| `link_libs` | empty | build target fields; future CLI | link | no shell expansion |
| `compiler_hooks_enabled` | `true` | internal runner settings | compilation | runner/helper compilations can disable hooks |

`BuildOptions` deliberately does not include test filters, build target
selection, graph printing, init options, formatting options, or C migrator
options. Those are command-level options layered around build/compile work.

### `TestOptions`

```with
pub type TestOptions {
    filter: str,
    verbose: bool,
    quiet: bool,
}
```

`TestOptions` combines with `BuildOptions` for test builds.

### `BuildGraphOptions`

```with
pub type BuildGraphOptions {
    selected_target: str,
    graph_only: bool,
    dry_run: bool,
    no_deps: bool,
}
```

These govern build graph selection/execution, not compilation itself.

### `MigrateOptions`

Migrator options stay separate:

```with
pub type MigrateOptions {
    source_path: str,
    output_path: str,
    include_paths: Vec[str],
    forced_includes: Vec[str],
    defines: Vec[str],
    exclude_basenames: Vec[str],
    check_mode: bool,
    diff_mode: bool,
    stats_mode: bool,
    no_c_export: bool,
    c_export_functions: bool,
    convert_goto_to_structured: bool,
    block_style: i32,
    width_slice: i32,
    shared_defs: str,
    migrate_one: str,
    shared_fragment: str,
    ir_roundtrip: bool,
}
```

Rationale: C migration has a different domain than compiling With code. It
includes C preprocessor configuration, directory reinvocation state, shared
definition modes, and hidden migration test knobs. Folding these into
`BuildOptions` would make every workspace compile option carry C-specific
fields. D2 should add `Workspace.set_migrate_options` or an equivalent
`Workspace.migrate(options: MigrateOptions)` API instead.

## CLI Parser Refactor Plan

### New Module

Create a driver options module, tentatively:

```text
src/compiler/DriverOptions.w
```

It owns:

- option structs and enums
- default computation
- argument scanning helpers
- validation
- parse result types

### Parse Result

```with
pub type DriverCommandOptions {
    command: str,
    build: BuildOptions,
    test: TestOptions,
    graph: BuildGraphOptions,
    migrate: MigrateOptions,
    fmt: FmtOptions,
    init: InitOptions,
    one_liner: OneLinerOptions,
    error: str,
}
```

The parser returns a value. It does not call `exit`, mutate `Compilation`, or
print diagnostics directly. The driver prints `error` with command context.

### Defaults

Defaults are computed in one place:

- command-specific optimization default
- `--release` raises opt level and disables debug info
- `--freestanding` sets both `no_std` and prelude none
- prelude values normalize through one function shared with `Compilation`
- output kind derives from command plus `--emit-c`/`--emit-obj`

### Validation

Validation happens before command execution:

- unknown prelude value is an error
- `--emit-c` and `--emit-obj` conflict
- `--emit-c`/`--emit-obj` are build-only
- build.w tool-mode rejects direct `--emit-c`/`--emit-obj`
- `--no-deps` requires an explicit build.w action target
- `-o` is rejected for multi-target build.w execution as today
- one-liner modes `-e`, `-n`, and `-p` are mutually exclusive
- format `--prefer-curly` remains a loud rename error
- migrate `--prefer-curly` remains a loud rename error

### Compilation Integration

Add:

```with
fn Compilation.configure_options(self: Compilation, options: BuildOptions)
```

Then retire or narrow:

```with
fn Compilation.configure(self: Compilation, opt_level: i32, no_std: bool, alloc_mode: bool)
fn Compilation.set_prelude_mode(self: Compilation, mode: i32)
fn Compilation.set_debug_info(self: Compilation, enabled: bool)
```

Existing callers can be migrated incrementally, but D2 is complete only when
the driver no longer threads option fields as long positional argument lists.

### Build Graph Overlay

Build graph target fields overlay `BuildOptions`:

- `Target.optimize(.Release)` may raise `opt_level` for that target.
- `Target.include_path`, `define`, and `link_system_lib` populate the target
  option vectors.
- `Target.target` overlays `target`.
- Target kind overlays `output_kind`.
- Command-level `-o` is still subject to the current single-target checks.

The overlay operation should produce a fresh `BuildOptions` value for each
target, not mutate the command-level base options in place.

## Compatibility Test Fixture Set

D2 must preserve these behaviors:

1. `with build test/hello.w -o /tmp/x` creates the requested binary.
2. `with build test/hello.w --emit-c -o /tmp/x.c` emits C.
3. `with build test/hello.w --emit-obj -o /tmp/x.o` emits an object.
4. `with build test/hello.w -O0`, `-O1`, `-O2`, `-O3`, and `--release` produce
   successful outputs.
5. `with check test/hello.w --dump-tokens`, `--dump-ast`, `--dump-resolved`,
   `--dump-typed`, `--dump-project-info`, `--dump-mir`, and
   `--dump-async-mir` preserve current success/failure behavior.
6. `with build :test --graph` and `with build :test --dry-run` preserve graph
   text shape.
7. `with build :some-action --no-deps` works for action targets and rejects
   non-action/direct source builds.
8. `with test test/behavior --filter=<text>`, `--filter <text>`, `-f <text>`,
   `-v`, and `-q` preserve current behavior.
9. One-liners `-e`, `-n`, `-p`, and `--` preserve current behavior.
10. Migrator options listed above parse into the same migrator state and keep
    `--prefer-curly` as an error.
11. `with fmt -w`, `-l`, `--check`, `--prefer-brace`, `--prefer-colon`, and
    `--prefer-curly` preserve current behavior.
12. `with init --name <name>` and `with init --lib` preserve current template
    selection.

These should become focused behavior/selfhost fixtures before or during D2.

## D2 Implementation Checklist

1. Add `DriverOptions.w` with structs, defaults, parser, and validation.
2. Add `Compilation.configure_options`.
3. Convert direct `Compilation` callers in `src/main.w` to use
   `BuildOptions`.
4. Convert build graph target execution to use target-overlaid
   `BuildOptions`.
5. Move migrator parsing to `MigrateOptions` without changing migrator
   behavior.
6. Preserve existing help text or update it to match the structured parser.
7. Run the compatibility fixture set and the full pre-D baseline suite.
