# Making With a Coherent Programmable Toolchain — v2

## Preamble

This document revises an earlier proposal that drew heavily on Jai
comparisons. That framing imported useful ideas but also imported
terminology and assumptions from languages With is not. This revision
keeps the good ideas and restates them in terms of what With actually
is, what it already specifies, and what order of work makes sense
given where the project stands today.

The core thesis survives: a language becomes more powerful when its
compiler, build system, metaprogramming, allocator conventions, interop
story, and project tooling feel like one coherent instrument. With is
well-positioned for this because its spec already contains the pieces
— `comptime`, `with`, `implicit`, ephemeral types, arenas, handles —
they just haven't been wired together into a unified toolchain story
yet.

---

## 1. What With Actually Is (Correcting the Frame)

The original proposal repeatedly says "borrow checker." With does not
have a borrow checker in the Rust sense. With's safety model is:

- **Second-class references** (§3.3). References cannot be stored in
  structs, enum variants, heap containers, or globals. This single
  restriction eliminates lifetime annotations entirely.

- **Ephemeral types** (§5). Types that contain references are marked
  `ephemeral` and propagate that restriction through type constructors.
  Ephemeral values exist only as locals, parameters, and (propagated)
  return values.

- **View-liveness analysis** (§3.2). Active shared borrows are
  invalidated when the borrowed place is mutated. This is enforced at
  compile time but requires no annotations — the compiler tracks it.

- **Handles over pointers** (§6). Long-lived inter-object references
  use typed generational indices (`Handle[T]`) into arenas
  (`SlotMap[T]`), not raw pointers or borrowed references.

- **`with` scoping** (§7). Guarded access, builder patterns, scoped
  bindings, and implicit contexts all use the same keyword with
  compiler-enforced scope boundaries.

- **Single safe reference type** (§3.1). With has `&T` — a shared,
  read-only borrow. There is no safe `&mut T`. Mutation is expressed
  through owned values (`mut self: Self` receivers), `with` scoped
  access, and `IndexPlace` projections.

This is not "Rust minus the hard parts." It is a different design that
trades one capability (stored references) for a large simplification
(no lifetime annotations, no `Pin`, no `PhantomData`). The safety
properties — no use-after-free, no double-free, no data races in safe
code — are the same, but the mechanism is fundamentally different.

Any proposal for With's toolchain should build on these mechanisms,
not describe them in Rust terminology.

---

## 2. Build Doctrine: `build.w` Is the Build System

### Decision

This is the strongest idea from the original proposal and survives
with refinement.

```
build.w   = executable build behavior (With code)
with.toml = declarative package configuration
```

### Boundary between `with.toml` and `build.w`

**Allowed in `with.toml`:**

- Package identity (name, version, authors, license)
- Dependencies and their version constraints
- Minimum With version
- Target defaults and feature flags
- Lint policy
- Runtime knobs (overflow mode, fiber stack size)
- C toolchain defaults (`cc`, include paths, defines)
- Link directives (libraries, search paths)
- Publishing metadata

**Not allowed in `with.toml`:**

- Conditionals or loops
- Generated-file steps
- Asset pipelines or shader compilation
- Custom build commands
- Target graph construction
- Platform-specific branching logic
- Multi-binary or multi-library definitions

Those belong in `build.w`.

For simple projects, the compiler synthesizes a default build recipe.
For complex projects, users write `build.w`. There is never a question
about which file an imperative build concern belongs in.

### Default recipe

A project with no `build.w` behaves as though this existed:

```
use std.build

pub fn build(b: Build) -> Build:
    with b as mut build:
        build.executable(package.name, "src/main.w")
```

The `with ... as mut` block returns `build` (the root `Build` value)
as the function result. This avoids a type issue: `executable()`
likely returns a target builder (e.g., `Executable`), not `Build`,
so chaining it directly as the return value would be ill-typed. The
scoped mutation pattern is idiomatic With — it uses the language's
own `with` construct to express staged build graph construction.

There is no `&mut Build`. Mutation uses `mut self: Self` receivers
or `with ... as mut` scoped access.

A complex project:

```
use std.build

pub fn build(b: Build) -> Build:
    var out = b.generated_source(
        "out/gen/version.w",
        "pub fn build_version -> str:\n    \"dev\"\n",
    )
    var game = target_new(.Executable, "game", "src/main.w")
    game = game.target(BuildTarget.native)
    game = game.optimize(.debug)
    game = game.link_system_lib("SDL2")
    out = out.add_target(game)
    out.test("unit", "tests/*.w")
```

### `build.w` is not ordinary `comptime`

The spec's `comptime` is deterministic, side-effect-free, and cannot
perform I/O, call FFI, or allocate heap memory that persists to
runtime (§17.1, §17.7). A build system needs to read files, invoke
tools, and write outputs.

`build.w` is **tool-mode With code** run by the compiler driver.
Normal `comptime` remains pure and deterministic; build effects are
allowed only through `std.build` APIs, which the compiler driver
provides as a privileged execution context. This is analogous to how
`comptime_error` can emit diagnostics despite `comptime` having no
I/O — the compiler provides the capability, not the language runtime.

### Why this matters now

The current build uses Make. That works for bootstrapping but doesn't
compose with the language. The doctrine decision should happen early
because it shapes documentation, examples, package layout, and the
design of `std.build`. Implementation can be staged — the decision
is what matters.

---

## 3. Standard Context via `implicit` and `with`

### Decision

Define a standard `Context` type in `std.context` as the conventional
home for cross-cutting execution services.

### Why this fits With specifically

With already has both mechanisms this needs:

1. **`implicit` parameters** (§9.1a) — a function can declare
   `ctx: implicit &Context` and the compiler fills it from the
   enclosing scope.

2. **`with context(expr):` blocks** (§7.3a) — introduces an implicit
   context binding whose type the compiler uses for resolution.

The original proposal described these mechanisms correctly. They are
spec'd and ready to use. The question is only what `Context` contains.

### Proposed type

`Context` contains references, so it must be `ephemeral` (§5.1 —
structs with reference fields must be marked `ephemeral`):

```
module std.context

type Context = ephemeral {
    allocator: &dyn Allocator,
    temp: &TempArena,
    logger: &dyn Logger,
    cancellation: CancellationToken,
    trace_id: TraceId,
}
```

This is correct: `Context` is a scoped execution environment, not a
storable data structure. It exists as a local binding inside a `with
context(...)` block and is passed via `implicit` parameters. It never
needs to be stored in a struct, container, or global — ephemeral is
exactly right.

### Usage

```
fn handle_request(req: Request, ctx: implicit &Context) -> Result[Response, Error]:
    ctx.logger.info("handling request", trace_id: ctx.trace_id)
    let body = parse_body(req.body, allocator: ctx.temp)?
    let result = process(body, ctx)?
    Response.ok(result)
```

Call site:

```
with context(server_context):
    let response = handle_request(req).await?
```

### Guardrail

Context is for execution services (allocator, logger, tracer,
cancellation), not application state (database, config, current user).
The standard fields should stay small. Application-specific context
belongs in user-defined ephemeral types that compose with `Context`:

```
type ServerContext = ephemeral {
    std: Context,
    database: &Database,
    config: &Config,
}
```

Or, if the application needs a storable service locator, use owned
handles rather than borrowed references:

```
type ServiceRegistry {
    database: Arc[Database],
    config: Arc[Config],
}
```

The choice between ephemeral-with-references and storable-with-handles
follows from the use site: scoped request processing uses ephemeral
context; long-lived service wiring uses owned handles. Both are
idiomatic With.

---

## 4. Temporary Arenas — Safe Because of Ephemeral Types

### Decision

Provide `TempArena` in `std.alloc`, integrated with `with` scoping
and `Context`.

### Arena type distinctions

The spec already mentions `Arena` and `FrameArena` in §8.3.
`TempArena` is a third arena type with a distinct semantic contract:

| Type | Reset authority | Primary use case |
|------|-----------------|------------------|
| `Arena` | User-controlled, explicit reset/drop | Long-lived region allocation |
| `FrameArena` | External reset per frame/tick | Game loops, render passes |
| `TempArena` | Lexical scope, resets at `with` block exit | Scratch computation |

`TempArena` exists because its reset is tied to lexical scope — the
`with` block boundary — rather than to an external signal (frame
tick) or explicit user call. This makes it the natural choice for
`scratch_arena()`.

### Why With can make this safe (and most languages cannot)

With's ephemeral system (§5) provides a guarantee most languages
lack: **arena-allocated references cannot escape the arena scope.**

Here is why:

1. A `TempArena` lives inside a `with` block.
2. References allocated from it are `&T` — ephemeral by §3.3.
3. Ephemeral values cannot be stored in structs, containers, or
   globals (§5.1).
4. Ephemeral values cannot be returned from functions unless the
   return type is itself ephemeral (§3.4), which propagates the
   restriction to the caller.
5. When the `with` block exits, the arena resets and all allocations
   are freed. No dangling references survive because the ephemeral
   system prevented them from escaping.

### Escape prevention examples

**Attempting to store an arena reference in a struct:**

```
type UserLabel {
    text: &str,
}
// ERROR: ordinary struct cannot contain ephemeral field
// help: mark UserLabel as ephemeral, or store an owned str
```

**Attempting to return an arena-allocated value from a guarded
`with` block:**

```
let leaked =
    with scratch_arena() as arena:
        format_name(user, allocator: arena)
// ERROR: guarded with block result is ephemeral;
//        it cannot outlive the arena scope
```

The original proposal claimed this worked via a "borrow checker."
The actual mechanism is the ephemeral type system — a different
path to the same safety guarantee, requiring no lifetime annotations.

### API

```
module std.alloc

type TempArena:
    impl Allocator

pub fn scratch_arena() -> Scoped[TempArena]
```

Usage:

```
with scratch_arena() as arena:
    let names = parse_names(input, allocator: arena)
    process(names)
// all arena allocations released here
```

Context-integrated:

```
with context(ctx.with_temp()):
    let scratch = heavy_computation()
    let result = scratch.summarize()
// temporary allocations reset here
```

### Where this is immediately useful

- The C migrator (parsing temporary ASTs per file)
- The regex library (match-time scratch space)
- Request handlers (per-request allocation that resets on response)
- Game frames (per-frame scratch that resets each tick)
- Compilers and parsers (temporary node storage during a pass)

---

## 5. `@[specified]` Enums

### Decision

Add `@[specified]` for enums whose discriminants must all be explicit.

The spec already has discriminant enums with auto-increment (§4.4a)
and `@[flags]` for bitflag doubling. `@[specified]` is the third
mode: every variant must have an explicit value.

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong = 2
    Data = 3
```

This should fail:

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong = 2
    Data        // ERROR: @[specified] requires explicit value
```

### Why

Auto-increment is fine for local implementation details. It is
dangerous for values that cross process, machine, or version
boundaries: network protocols, file formats, database encodings,
FFI, stable plugin APIs, serialized messages. Adding or reordering
a variant must not silently change wire format.

### Cost

Tiny. One attribute, one check during enum lowering, one error
message.

---

## 6. Honest C Interop — Formalizing What Already Exists

### Decision

With's C interop should follow an "honest translation" rule: if a C
declaration cannot be translated correctly, the compiler must say so.

### What already exists

The spec describes `c_import` (§16.1), macro handling (§16.2), and
`comptime_error` stubs for untranslatable constructs (§17.5). The C
migrator already follows this principle — untranslatable function
bodies become `comptime_error("untranslatable function body")` stubs,
and the STRUCTURAL/LEGACY trace verification ensures the structural
path actually fires.

The `allow_untranslated` mechanism from the original proposal would
formalize this:

```
use c_import("complex_lib.h",
    link: "complex",
    allow_untranslated: ["WEIRD_MACRO", "PLATFORM_HACK"],
)
```

### The broader principle

This extends beyond C interop:

```
Partial success must be visible.
Silent fallbacks are bugs.
Generated code must not pretend to be complete.
```

A `comptime_error` stub is acceptable — it is a loud, visible
marker that fires on use. What is not acceptable is a silent
placeholder that makes a binding surface appear complete when it
is not. The distinction is between an honest "this is missing" and
a quiet "this exists but does nothing."

This principle applies to migration tools, code generators, schema
compilers, derive macros, package publishing, and build steps.

---

## 7. Compiler Introspection — Building on `comptime`

### Decision

Expose a constrained compiler introspection API for project-wide
analysis, diagnostics, and eventually explicit code generation.

### What the spec already provides

- `comptime` functions (§17.1)
- `T.fields()`, `T.variants()`, `T.implements(Trait)` at compile
  time (§17.2)
- Derive-like code generation via `comptime fn` (§17.3)
- `comptime for` unrolling (§17.4)
- `comptime if` dead-branch elimination (§17.5)

The spec's metaprogramming model is already substantial. What it
lacks is **project-wide** visibility — the ability to inspect all
modules, all public functions, all types, and emit diagnostics across
the project rather than one type at a time.

### Phase 1: Read-only project inspection

```
@[compiler_hook(after_typecheck)]
fn lint_project(project: ProjectInfo):
    for f in project.functions():
        if f.is_pub() and not f.has_docs():
            compiler.error(f.location, "public function missing docs")
```

This is significant new infrastructure. It requires the compiler to
expose a stable `ProjectInfo` API, run user code after type checking,
and feed diagnostics back into the error pipeline. This should not be
underestimated.

Note: `compiler_hook` functions run in tool-mode context (like
`build.w`), not in pure `comptime` context. The name `compiler_hook`
rather than `comptime_hook` reflects this: these hooks are compiler
driver extensions, not ordinary deterministic comptime evaluation.
They may emit diagnostics and inspect the full project graph, but
they cannot perform arbitrary I/O.

### Phase 2: Explicit source emission

Only after Phase 1 is stable:

```
@[compiler_hook(after_typecheck)]
fn gen_rpc_stubs(project: ProjectInfo):
    for s in project.structs():
        if s.has_attr("rpc_service"):
            compiler.emit_source(generate_client(s))
            compiler.emit_source(generate_server(s))
```

Emitted source must be parsed, typechecked, and visible in
diagnostics normally.

### What With should NOT do

- Arbitrary AST mutation
- Caller-scope macros (macros that return from the caller)
- Untyped token rewriting
- Project-specific sublanguages hidden inside macros
- Runtime reflection by default (§17.7 already forbids this)

The spec already makes the right choice here: "With does not have
macros. It has `comptime`." The introspection API extends comptime
to project scope. It does not introduce a macro system.

---

## 8. Data-Oriented Derives

### Decision

Provide blessed data-oriented derives, starting with `@[derive(SoA)]`.

The spec already describes the derive mechanism (§17.3) and shows
a SoA example in §17.6. This is a matter of shipping the standard
derives, not designing a new system.

```
@[derive(SoA)]
type Transform {
    position: Vec3,
    rotation: Quat,
    scale: f32,
}
```

Generates:

```
type TransformSoA {
    position: Vec[Vec3],
    rotation: Vec[Quat],
    scale: Vec[f32],
}

impl TransformSoA:
    fn push(mut self: Self, t: Transform)
    fn get(self: &Self, idx: usize) -> Transform
    fn len(self: &Self) -> usize
```

### Initial blessed derives

- `SoA` — struct-of-arrays layout
- `Serialize` / `Deserialize` — JSON and binary
- `ComponentId` — ECS component registration

These should be implemented on top of the existing `comptime`
`T.fields()` API (§17.2), not through a separate macro system.

---

## 9. What the Original Proposal Missed

### With's distinctive features

The original proposal didn't engage with the features that make With
*With*:

**The `with` keyword** is the language's central construct (§7). It
appears in guarded access, builder patterns, scoped bindings, implicit
contexts, and record updates. Any toolchain proposal should leverage
`with` as the scoping primitive, not introduce parallel mechanisms.

**Handles and SlotMaps** (§6) are With's answer to stored references.
The handle/arena pattern is the idiomatic way to express long-lived
relationships. Toolchain features like ECS derives and serialization
should build on `Handle[T]` and `SlotMap[T]`, not assume raw-pointer
or reference-based architectures.

**Ephemeral types** (§5) are the mechanism that makes arenas safe,
iterators composable, and concurrent closures sound. The toolchain
story should explain ephemeral types as the safety mechanism, not
hand-wave about a "borrow checker."

**Fiber-based async** (§14) is a major differentiator. The runtime
uses real stacks, not state machines. The toolchain should acknowledge
this — build steps, test runners, and project analysis can all be
async without the complexity of Rust's pinning model.

### The current state of the project

The compiler is self-hosting and bootstraps through a three-stage
fixpoint. The C migrator is translating PCRE2 (30 modules, 600K+
lines of generated code). The regex library is being built on top
of the migrated PCRE2. Implicit main was just spec'd. The test suite
has 700+ tests.

These are the actual near-term priorities:
1. Finish the C migrator (remaining raw_string elimination)
2. Get PCRE2 fully clean (regex-check at 0 errors)
3. Ship the regex library (`std.re`)
4. Implement implicit main
5. Stabilize the language surface for early users

A toolchain proposal that ignores this reality and jumps to
"programmable build hooks" and "compiler introspection API" is
proposing work for a language that doesn't exist yet — one that has
users, packages, and an ecosystem. With is still building its
compiler.

---

## 10. Revised Priority Order

### Phase 0: Decisions (no implementation required)

- **Build doctrine**: `build.w` is the build system, `with.toml` is
  declarative configuration. Decide this now even if `std.build` ships
  much later. It shapes documentation and examples immediately.

### Phase 1: Near-term (during current compiler work)

- **`@[specified]` enums**: Small, clear, high value-to-cost ratio.
  Can land alongside other parser/sema work.

- **Standard Context type**: Define `std.context.Context` (ephemeral)
  and wire it through `implicit` + `with context()`. The mechanisms
  exist; this is API design and stdlib work.

- **Honest C interop audit**: Formalize `allow_untranslated` in
  `c_import`. The behavior already exists in the migrator; this
  makes it a language-level feature.

### Phase 2: After the compiler stabilizes

- **TempArena in std.alloc**: Implement `scratch_arena()` with `with`
  integration and ephemeral escape prevention. Depends on the
  allocator API being stable.

- **Blessed derives**: `@[derive(SoA)]`, `@[derive(Serialize)]`,
  `@[derive(Deserialize)]`. Depends on `comptime` `T.fields()` being
  reliable.

### Phase 3: Ecosystem tooling

- **`std.build` implementation**: The actual build API, running in
  tool-mode context. Depends on the compiler driver supporting
  privileged execution of `build.w`.

- **Read-only compiler introspection**: `ProjectInfo` API for
  project-wide lints and diagnostics. Significant compiler work.

### Phase 4: Advanced metaprogramming

- **`compiler.emit_source()`**: Explicit code generation from
  compiler hooks. Only after read-only introspection is proven.

- **Build/introspection integration**: Compiler hooks that
  participate in the build graph.

---

## 11. Rejected Ideas

### Raw pointers as default

Reject. With's identity is safe systems programming with explicit
`unsafe` at the edges. (Same conclusion as the original proposal.)

### Caller-scope AST macros

Reject. The spec already chose `comptime` over macros (§17.7). This
is the right choice. Macros that affect caller control flow make code
unreadable.

### Runtime reflection by default

Reject. The spec already forbids this (§17.7 constraint 1):
"`TypeInfo` is only available in `comptime` contexts." Runtime
reflection should remain opt-in via `@[reflect]`.

### Weak error conventions

Reject. With's `Result[T, E]`, `?`, `??`, implicit Ok wrapping
(§4.9), and `errdefer` (§2.4) are a coherent error-handling story
that composes well. Jai's `value, ok` pattern does not.

### Replacing async

Reject. With's fiber model (§14) with real stacks, `.await` at
suspension points, `async scope` for structured concurrency, and
`select await` for racing is a major differentiator. It should be
showcased, not replaced.

---

## 12. The Story

With's toolchain story is not "we copied the best parts of Jai."
It is:

**With code builds With projects.** The build system is With code,
not TOML-that-grew-legs. Build logic is typechecked, debuggable, and
uses the same language you write your project in.

**Scope is the organizing principle.** `with` scopes execution
context, resource access, temporary allocation, and implicit
parameter resolution. The same keyword, the same mental model,
everywhere.

**Temporary memory is fast and safe.** Arena allocation is a pointer
bump. The ephemeral type system prevents escape at compile time. No
lifetime annotations required.

**The compiler is inspectable from within.** `comptime` functions can
examine types, generate implementations, and (eventually) analyze
whole projects. Generated code goes through the full type checker.
Nothing is hidden.

**C interop is honest.** What translates, translates. What doesn't,
says so. No silent stubs, no fake completeness.

**Boundary-facing values don't change silently.** `@[specified]`
enums prevent accidental wire-format drift.

That is the coherent toolchain identity: one language, one build
model, explicit scopes, honest output. It happens to share goals
with Jai's philosophy of a programmable toolchain, but it achieves
them through With's own mechanisms — ephemeral types instead of
lifetime annotations, `with` scoping instead of global context,
`comptime` instead of macros, handles instead of raw pointers.

---

## 13. Summary of Concrete Decisions

```
1.  build.w is the only build behavior mechanism.
2.  with.toml is declarative package configuration.
3.  Add std.build with default synthesized build recipes.
4.  Add std.context.Context (ephemeral) with implicit + with
    integration.
5.  Add std.alloc.TempArena and scratch_arena().
6.  Add @[specified] enums.
7.  Formalize allow_untranslated in c_import.
8.  Add read-only ProjectInfo compiler introspection (later).
9.  Add compiler.emit_source() (later still).
10. Add blessed derives: SoA, Serialize, Deserialize, ComponentId.
11. Reject raw-pointer defaults, caller-scope macros, runtime
    reflection by default, weak error conventions, and async
    replacement.
```

Items 1–2 are decisions that cost nothing to make now.
Items 4–7 are implementable during current compiler work.
Items 3, 8–10 require the compiler and comptime to mature first.

---

## 14. Required Spec Edits

If this proposal is accepted, the following spec sections should be
added or amended:

| Spec location | Change |
|---------------|--------|
| §4.4b (new) | `@[specified]` discriminant enums — attribute definition, compile error for missing values |
| §8.3a (new) or std.alloc section | `TempArena` and `scratch_arena()` — type definition, arena distinction table, `with` integration |
| §16.2b (new) | `allow_untranslated` — `c_import` parameter for explicit omission acknowledgment |
| §18.5a (new) | `build.w` and `std.build` doctrine — tool-mode execution, default recipe synthesis, `with.toml` boundary |
| §7.3a (amend) | Add `std.context.Context` as the standard implicit context type |
| §17 (amend) | Add future-work note for `ProjectInfo`, `compiler_hook`, and `compiler.emit_source()` |
| stdlib module map | Add `std.context`, `std.build`, `std.alloc.TempArena` |

These edits are ordered by implementation phase. §4.4b and §16.2b
are small enough to land immediately. §18.5a is a doctrine statement
that can land before implementation. §8.3a and §7.3a depend on
allocator and context API design. §17 amendments are future-work
markers only.
