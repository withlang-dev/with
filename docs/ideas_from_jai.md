# Ideas from Jai

Jai is not just a language — it is a programming environment where
compiler, build system, metaprogramming, allocator conventions, C
interop, reflection, and data layout all reinforce each other. With
should not copy Jai's safety model (raw pointers, manual memory, no
borrow checker), which is almost the opposite of With's identity. But
With can steal Jai's *workflow power* — the feeling that the
language/compiler/toolchain is one coherent instrument.

The strategic goal: make With's compiler programmable enough to replace
build scripts, code generators, schema compilers, bindgen glue, asset
pipelines, and project lints — while keeping the language itself safe
and deterministic.

---

## 1. Programmable Build Hooks (`build.w`)

### What Jai does

Jai has no external build system. Build configuration is Jai code. A
build metaprogram creates workspaces, sets options (~45 fields), adds
source files, and can run arbitrary compile-time logic. One invocation
can build multiple targets. No Makefiles, no CMake, no TOML.

### What With should do

Keep `with.toml` for normal projects. Add an optional `build.w` for
projects that need real logic: multiple binaries, generated assets, C
library compilation, shader compilation, codegen steps, platform-specific
packaging.

```
pub comptime fn build(b: &mut Build):
    b.executable("game", "src/main.w")
        .target(.native)
        .optimize(.debug)

    b.test("unit", "test/*.w")
    b.asset_dir("assets")
```

### Why

`with.toml` cannot express conditional compilation, multi-target builds,
or codegen steps without shelling out. `build.w` gives escape velocity
for complex projects without abandoning the simple path for simple
projects. Zig has `build.zig` for the same reason.

### How

- Define a `Build` API in `std.build` with methods for declaring
  executables, libraries, tests, asset directories, and custom steps.
- If `build.w` exists in the project root, `with build` compiles and
  runs it instead of reading `with.toml` directly.
- `build.w` can read `with.toml` programmatically for defaults, then
  layer logic on top.
- Start small: target declaration, optimization level, source sets,
  link libraries, pre/post-build steps. Expand the API surface based
  on real usage.

---

## 2. Compiler Introspection API

### What Jai does

Jai's compiler message loop (`compiler_begin_intercept` /
`compiler_wait_for_message`) lets user code intercept every compilation
phase: file loading, imports, typechecking, errors. Combined with AST
access (`compiler_get_nodes`) and code insertion (`#insert`), it enables
arbitrary compile-time code generation and project-wide enforcement.

### What With should do

Adopt the inspection and diagnostics power. Do NOT adopt arbitrary AST
mutation. Provide structured APIs for inspecting the project after
typechecking, emitting diagnostics, and generating code through explicit
emit functions.

```
comptime fn lint_project(project: ProjectInfo):
    for f in project.functions():
        if f.is_pub() and not f.has_docs():
            compiler.error(f.location, "public function missing docs")
```

```
comptime fn gen_rpc_stubs(project: ProjectInfo):
    for s in project.structs():
        if s.has_attr("rpc_service"):
            compiler.emit_source(generate_client(s))
            compiler.emit_source(generate_server(s))
```

### Why

This covers the important use cases — linters, codegen from annotations,
enforcing project conventions, schema generation — without the "every
codebase invents its own sub-language" problem that unrestricted AST
macros create. Generated code passes through the full type checker, so
errors are comprehensible.

### How

- Define `ProjectInfo`, `FunctionInfo`, `StructInfo`, `EnumInfo` types
  that expose post-typechecking metadata (names, types, attributes,
  locations, visibility).
- `compiler.error()`, `compiler.warning()`, `compiler.note()` for
  diagnostics tied to source locations.
- `compiler.emit_source()` accepts a string of With source code that
  gets parsed, typechecked, and compiled as if it were part of the
  project.
- Register introspection functions via `@[comptime_hook(after_typecheck)]`
  or similar. The compiler calls them at the appropriate phase.
- Phase 1: read-only inspection + diagnostics. Phase 2: code emission.
  Phase 3: build integration (introspection hooks can add build
  targets).

---

## 3. Standard Context

### What Jai does

Every Jai function receives an implicit `Context` struct carrying the
current allocator, logger, temporary storage, assert handler, and stack
trace. `push_context` swaps it for a scope. This solves the "allocator
threading" problem elegantly — you never pass an allocator through 15
layers of function calls.

### What With should do

With already has `implicit` parameters and `with context(...)` blocks.
Promote this from a language mechanism to a flagship stdlib pattern with
a standard `Context` type.

```
type Context:
    allocator: &dyn Allocator
    logger: &dyn Logger
    trace_id: TraceId
    cancellation: CancellationToken
    temp: &mut TempArena
```

```
with context(server_context):
    handle_request(req).await?
```

### Why

This gives Jai's ambient-service ergonomics without global mutable
state. The allocator, logger, and cancellation token are the three
things every server function needs and nobody wants to thread manually.
Games need allocator + temp arena. Jai proved this pattern works at
scale.

### How

- Define `std.context.Context` with the fields above.
- stdlib functions that allocate accept `ctx: implicit &Context` and
  use `ctx.allocator` by default.
- `Context.default()` provides a sane default (system allocator, stderr
  logger, empty trace, no cancellation, thread-local temp arena).
- Users override per-request, per-frame, or per-test via
  `with context(...)`.
- The `temp` field is a `TempArena` — see next section.

---

## 4. Scratch / Temporary Arenas

### What Jai does

Jai has a built-in per-thread bump allocator (`Temporary_Storage`) that
resets in bulk, typically once per frame. `tprint`, `talloc_string`, and
other stdlib functions use it implicitly. It is extremely fast (pointer
increment) and eliminates per-allocation overhead for short-lived data.

### What With should do

Provide a `TempArena` type that integrates with `with` scoping and the
standard `Context`.

```
with scratch_arena() as arena:
    let temp_names = parse_names(input, allocator: arena)
    process(temp_names)
// all temp allocations released here
```

Or via the context:

```
with context(ctx.with_temp()):
    let scratch = heavy_computation()
    let result = scratch.summarize()
// temp arena reset, scratch is gone, result was copied out
```

### Why

This is a perfect fit for the `with` construct. Jai invented temporary
storage for game loops; With can express it more cleanly because `with`
already handles scoped resource lifetime. It reinforces the "allocations
are obvious" promise — you can see exactly where temporary memory lives
and dies.

### How

- `TempArena` is a bump allocator implementing `Allocator`. Allocation
  is a pointer increment. No individual `free`. `reset()` reclaims
  everything at once.
- `scratch_arena()` returns a `Scoped[TempArena]` so `with` handles
  setup and teardown.
- Per-thread by default (no synchronization needed). Each thread's
  `Context` carries its own.
- Containers that accept an allocator parameter (`Vec`, `HashMap`, etc.)
  work with `TempArena` unchanged.
- Attempting to escape a reference to temp-arena-allocated data past
  the `with` scope is caught by the borrow checker — this is where
  With's safety model pays off vs. Jai's "hope you remembered to copy."

---

## 5. Data-Oriented Comptime Recipes

### What Jai does

Jai uses `#insert` and compile-time `type_info` introspection to
generate SOA layouts, serialization code, component registrations, and
layout transforms. There is no special syntax — the metaprogramming
system is general enough to cover it.

### What With should do

Provide blessed `@[derive]` targets for common data-oriented patterns,
especially SOA transforms for the game/ECS use case.

```
@[derive(SoA)]
type Transform:
    position: Vec3
    rotation: Quat
    scale: f32
```

Generates:

```
type TransformSoA:
    position: Vec[Vec3]
    rotation: Vec[Quat]
    scale: Vec[f32]

impl TransformSoA:
    fn push(&mut self, t: Transform): ...
    fn get(&self, idx: usize) -> Transform: ...
    fn len(&self) -> usize: ...
```

### Why

SOA layout is table stakes for ECS and cache-friendly game architecture.
Making it a one-line annotation that uses machinery With already has
(`comptime fn` + `T.fields()`) is far better than asking users to
maintain parallel struct definitions by hand.

### How

- Implement `derive_soa` as a `comptime fn` in `std.derive` that
  iterates `T.fields()`, generates a struct with `Vec[FieldType]` for
  each field, and emits accessor methods.
- Additional derives for common patterns: `@[derive(Serialize)]`,
  `@[derive(ComponentId)]` for ECS registration.
- The compiler introspection API (§2 above) is the foundation — these
  derives are the first consumers.
- Document the pattern so users can write their own project-specific
  derives.

---

## 6. Honest C Interop

### What Jai does

Jai's `Bindings_Generator` module auto-generates declarations from C/C++
headers. It is pragmatic — it handles what it can and leaves the rest
for manual binding.

### What With should do

With's `c_import` reads C headers at compile time, which is more
ambitious. The ambition is correct, but the output must be honest.
Following the project's "no silent fallbacks" principle:

- Constants: translated.
- Simple function-like macros: translated only when provably correct.
- Complex macros (token pasting, recursive expansion, side effects):
  produce a compile diagnostic and fail, unless explicitly suppressed.
- Untranslatable constructs: emit a named diagnostic, not a stub.

```
use c_import("complex_lib.h",
    link: "complex",
    allow_untranslated: ["WEIRD_MACRO", "PLATFORM_HACK"],
)
```

### Why

A binding file that looks complete but has hidden stubs is a lie about
completeness. This directly violates the project's core principle: a
migrator that produces 30/30 files with silent stubs is worse than one
that produces 0/30 with a loud error. The same applies to `c_import`.

### How

- `c_import` already does most of this. Audit the current behavior for
  cases where it silently drops or stubs declarations.
- Add `allow_untranslated` as an explicit opt-in list. Anything not on
  the list that can't be translated is a hard error.
- Emit a summary at the end of compilation: "c_import: 342/350
  declarations translated, 8 skipped (listed above)."

---

## 7. `@[specified]` Enums

### What Jai does

`#specified` forces every enum variant to have an explicit integer
value. Adding or reordering variants without updating values is a
compile error. This prevents silent ABI/serialization breakage.

### What With should do

Add `@[specified]` for discriminant enums that cross serialization or
ABI boundaries.

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong = 2
    Data = 3
```

Adding `Ack` without a value is a compile error, not a silent
auto-increment to 4.

### Why

Low cost, high value. Any enum that gets serialized to disk, sent over
a network, or exposed through FFI should have this. Auto-incrementing
discriminants are a time bomb in those contexts.

### How

- Parser recognizes `@[specified]` on discriminant enum declarations.
- Sema checks that every variant has an explicit value. Error otherwise.
- Minimal implementation cost — it's a validation pass, not new codegen.

---

## What NOT to take from Jai

These were considered and deliberately rejected:

- **Unrestricted raw pointers as default.** Undermines With's strongest
  differentiator. With's borrow checker with the "no stored references"
  simplification is a better answer.

- **AST macros with caller-scope access.** Jai's backtick macros
  (`` `return `` returns from the *caller*) produce hard-to-reason-about
  code. With's `comptime` introspection is more constrained but keeps
  codebases readable by people who didn't write the metaprogram.

- **Runtime reflection by default.** With's "type info is comptime only"
  is a good performance and simplicity boundary. If runtime type info is
  needed (ECS component registration, hot-reload), make it opt-in per
  type via `@[reflect]`, not a global default.

- **No error types.** Jai's `value, ok := ...` pattern doesn't compose.
  With's `Result[T, E]` + `?` + `??` is strictly better for real
  codebases.

- **No async.** Jai punts on concurrency (OS threads only). With's
  fiber-based async is a major differentiator for the server/database
  use case.

- **`uninit` / explicit non-initialization.** Considered for performance
  in hot loops, but conflicts with With's safety guarantees. If added
  later, confine to `unsafe` blocks.

---

## Priority Order

1. **Standard Context + TempArena** (§3, §4) — highest leverage, builds
   on existing `implicit` + `with` mechanics, immediately useful for
   both game and server code.

2. **`@[specified]` enums** (§7) — trivial to implement, prevents real
   bugs. Do it next time you're in the parser/sema.

3. **Honest C interop** (§6) — audit and harden what already exists.
   No new features, just better failure modes.

4. **Data-oriented derives** (§5) — `@[derive(SoA)]` is a strong
   selling point for the ECS/game audience. Requires the comptime
   introspection foundation.

5. **Compiler introspection API** (§2) — the foundation for §5 and
   future project-wide tooling. Significant design work.

6. **Programmable build hooks** (§1) — `build.w` is important for
   complex projects but `with.toml` covers most needs today. Defer
   until real users hit the wall.
