# Spec and Implementation Notes: Lessons from Zig Devlog

Three targeted improvements derived from Zig's March 2026 devlog.

---

## §S.X Implicit Main

### Spec Language

The build or run entry file may omit `fn main` when it contains
top-level executable statements. In that case, the compiler
synthesizes an implicit:

```with
fn main:
    ...
```

whose body contains the file's top-level statements in source
order.

Only the entry file is eligible. Imported modules, `with check`,
and test-harness synthesis continue to use the existing
declaration-only top-level model.

Top-level declarations remain module-scoped:

- `fn`
- `type`
- `enum`
- `trait`
- `impl`
- `use`
- `extern`
- `const`

Top-level executable statements become the implicit main body:

- expression statements
- assignments
- control-flow statements
- top-level `let` / `var` when script mode is active

If a file defines `fn main`, top-level `let` / `var` retain their
existing module-global meaning and no implicit main is synthesized.

It is an error for an entry file to contain both:

1. an explicit `fn main`, and
2. any non-declaration top-level executable statement

### Rationale

The feature is meant to improve the first-run script experience
without changing library semantics or breaking existing programs
that use explicit `fn main` plus top-level globals.

That distinction matters. The naive rule "in script mode, treat
top-level `let` / `var` as statements" is not enough, because the
parser sees items incrementally. If the compiler reclassifies
top-level `var g = ...` before it has discovered a later explicit
`fn main`, it silently changes module-global state into a local and
then produces the wrong explicit-main conflict.

The implemented rule is therefore:

- entry-file parse mode is enabled only for build/run entry files
- the parser performs a cheap top-level pre-scan for `fn main`
- if `fn main` exists anywhere at top level, top-level `let` / `var`
  stay declarations for the whole file
- only files with no explicit main permit top-level statements to
  accumulate into a synthesized main

This preserves the existing meaning of files such as:

```with
var g_counter: i32 = 0

fn main:
    g_counter = g_counter + 1
```

while still allowing:

```with
let x = 3
print(int_to_string(double(x) + 1))

fn double(n: i32) -> i32:
    n * 2
```

### Implementation Note

The implementation lives entirely in the frontend/parser path.
No sema, MIR, or codegen special cases are needed once the parser
produces a normal synthesized `NK_FN_DECL`.

#### Parser changes

`Parser` now carries:

- `implicit_main_mode`
- `implicit_main_has_main_hint`
- `top_level_stmts`
- `explicit_main_decl`

When implicit-main mode is enabled:

1. The parser first performs a top-level token pre-scan to detect
   whether the file contains `fn main`.
2. If the file has no explicit main, non-declaration top-level items
   are parsed as expressions/statements and appended to
   `top_level_stmts`.
3. At end of module parse, if `top_level_stmts` is non-empty, the
   parser synthesizes:
   - an `NK_BLOCK` containing those statements
   - a normal `NK_FN_DECL` named `main`
   - zero-parameter function metadata
4. If the file has both explicit main and top-level executable
   statements, the parser emits a hard error naming both sites.

Because the synthesized node is an ordinary function declaration,
the rest of the pipeline treats it exactly like handwritten
`fn main`.

#### Frontend wiring

The mode is enabled only through dedicated entry-file frontend calls:

- `Compilation.build_binary_to_path`
- `Compilation.build_binary_from_source_to_path`

The shared parse/check/import paths are unchanged:

- `Compilation.compile_file`
- `with check`
- imported module parsing in `Resolve`
- test/bench discovery parsers

This is the critical containment boundary. Implicit main is a build
entry feature, not a general parse mode.

### Tests

Coverage added:

- `test/behavior/behav_implicit_main.w`
  Verifies declaration hoisting, forward reference visibility, and
  top-level `let` locality in synthesized main.
- `test/compile_errors/err_implicit_main_check.w`
  Verifies `with check` still rejects top-level executable
  statements.
- `test/compile_errors/err_implicit_main_conflict.w`
  Verifies explicit `fn main` plus top-level executable statements
  is a hard error.
- `test/compile_errors/err_implicit_main_import_stmt.w`
  Verifies imported files with top-level executable statements still
  fail.

### Verification

The final implementation passed:

- `make build`
- `make fixpoint`
- `make test`

The important regression during development was explicit-main files
with top-level globals. The first implementation incorrectly treated
top-level `let` / `var` as statements too early, which broke files
such as `behav_basic_semantics.w` and `behav_globals.w`. The root
cause was classification without whole-file knowledge. The fix was
the top-level `fn main` pre-scan described above.

---

## §4.X Lazy Type Resolution

### Spec Language

Generic type instantiations are resolved **lazily**. Referencing
a generic type as a namespace or passing it as a type argument
does not force resolution of its fields or layout. Fields are
resolved only when:

1. A value of that type is constructed.
2. A field of that type is accessed.
3. The size or alignment of that type is queried.

```
type Config[T] = {
    value: T,
    metadata: ExpensiveType[T],    // not resolved until needed
}

// OK: Config used as namespace, fields not resolved
let default_timeout = Config.DEFAULT_TIMEOUT

// OK: Config[i32] mentioned in a type bound, fields not resolved
fn accepts[T: Into[Config[T]]](x: T): ...

// Fields resolved here: Config[i32] is actually constructed
let c = Config[i32] { value: 42, metadata: build_metadata(42) }
```

**Rationale:** Without lazy resolution, importing a module that
defines `Config[T]` forces the compiler to resolve every type
reachable through `Config`'s fields — including types that are
never used. This causes unnecessary compile-time work and can
trigger spurious dependency loops.

**Interaction with `comptime`:** `comptime` expressions that
query type layout (e.g., size, alignment, field offsets) force
resolution of the queried type. This is expected and correct.

**Interaction with trait impls:** Implementing a trait for a
generic type does not force field resolution of that type.
Only method bodies that access fields trigger resolution. A
trait impl that only calls other methods (which themselves may
not access fields) does not force resolution.

---

## §E.X Dependency Loop Diagnostics

### Spec Language

When the compiler detects a circular type dependency, the error
message must include the **full loop** with one note per edge,
showing the exact source location where each type depends on
the next.

```
error[E0401]: dependency loop with length 2
  --> src/ast.w:5:18
   |
 5 | type Node = { parent: Tree }
   |                       ^^^^ type `Node` depends on `Tree` here
   |
  --> src/ast.w:8:21
   |
 8 | type Tree = { root: Node }
   |                     ^^^^ type `Tree` depends on `Node` here
   |
   = help: eliminate any one of these dependencies to break the loop
   = help: consider using Handle[Node] instead of Node
```

**Requirements:**

1. Every edge in the loop is shown with file:line and a note
   explaining the dependency relationship (field declaration,
   alignment query, generic argument, trait bound, etc.).
2. Loops of any length are fully reported — not just "circular
   dependency detected" with no context.
3. The `help` line suggests concrete fixes when possible:
   - Use `Handle[T]` instead of storing the type directly.
   - Use `Option[&T]` if a reference suffices.
   - Reorder type definitions.
   - Break the loop by making one field lazy (`fn` accessor
     instead of stored field).

**Rationale:** Dependency loop errors are among the most
confusing compiler errors. Without the full loop trace, the
developer has to manually chase the chain across files. Zig
shipped this in March 2026 and it immediately improved the
developer experience. With should have it from release.

---

## §P.X Package Manager: `--fork` Flag

### Spec Language

The `with get` package manager supports a `--fork` flag that
overrides any matching dependency in the entire dependency tree
with a local source checkout.

```bash
# Use local checkout of a dependency
with build --fork=/path/to/my-fork-of-json-lib

# Multiple forks
with build --fork=/path/to/json-lib --fork=/path/to/http-lib
```

**Matching:** The fork path is matched against dependencies by
package name and fingerprint (from `with.toml`). If the fork
matches one or more packages in the dependency tree, all are
overridden. If the fork matches no packages, the compiler emits
an error:

```
error: fork /path/to/json-lib matched no json-lib packages
```

When a fork is active, the compiler emits an informational
message:

```
info: fork /path/to/json-lib matched 2 (json-lib) packages
```

**Ephemerality:** The `--fork` flag is a CLI argument, not stored
in `with.toml` or any configuration file. Removing the flag
restores the original published dependency. This is intentional:
forks are for development and debugging, not for permanent
overrides.

**Use case:** The primary workflow is debugging ecosystem breakage:

1. Build fails because a dependency has a bug.
2. Clone the dependency locally, fix the bug.
3. `with build --fork=/path/to/fixed-dep` — build succeeds.
4. Submit the fix upstream.
5. When upstream publishes, drop the `--fork` flag.

The developer never needs to edit `with.toml` to point at a
fork, which avoids accidental commits of development overrides.

**Interaction with lock files:** When `--fork` is active, the
lock file is not updated. The fork is invisible to version
resolution. Other developers building the same project without
the `--fork` flag see the original dependency.

---

## Implementation Note: Lazy Type Resolution

### Note

This affects the generic type instantiation system (Plan 5).
Build laziness into `GenericInst` from the start.

**Type states:** Each `GenericInst` type in the intern pool has
a resolution state:

```
type TypeResolution: i32 =
    Unresolved = 0     // type exists but fields not known
    Resolving = 1      // currently resolving (cycle detection)
    Resolved = 2       // fields, size, alignment all known
```

**When to resolve:**

- `resolve_type_expr` for `Vec[i32]` creates the `GenericInst`
  in `Unresolved` state. Field layout is not computed.
- Accessing a field (`x.value`) triggers resolution of the
  containing type. If state is `Unresolved`, resolve now.
- `sizeof`, `alignof`, struct literal construction — all trigger
  resolution.
- Type-checking a function signature that mentions `Vec[i32]`
  does NOT trigger resolution.
- Method lookup on `Vec[i32]` does NOT trigger resolution unless
  the method body accesses fields (which it usually does, so
  resolution happens inside the method, not at the call site).

**Cycle detection:** When resolution begins, set state to
`Resolving`. If resolution encounters a type that's already
`Resolving`, a dependency loop exists. At this point, collect
the loop edges and emit the diagnostic (see below).

**Implementation in sema:**

```
fn ensure_type_resolved(self: Sema, type_id: TypeId):
    let state = self.type_resolution_state(type_id)
    if state == .Resolved: return
    if state == .Resolving:
        self.emit_dependency_loop_error(type_id)
        return
    self.set_resolution_state(type_id, .Resolving)
    // ... resolve fields, compute layout ...
    self.set_resolution_state(type_id, .Resolved)
```

Call `ensure_type_resolved` at field access, construction, and
layout query sites — not at type reference sites.

---

## Implementation Note: Dependency Loop Diagnostics

### Note

**When:** Implement alongside lazy type resolution. The cycle
detection state (`Resolving`) is the trigger for this diagnostic.

**Data structure:** When a cycle is detected, walk the resolution
stack to collect all edges:

```
type DepEdge = {
    from_type: TypeId,
    to_type: TypeId,
    span: Span,           // source location of the dependency
    reason: DepReason,    // why the dependency exists
}

type DepReason: i32 =
    FieldDecl = 0         // type used as field type
    AlignQuery = 1        // alignment of type queried
    SizeQuery = 2         // size of type queried
    GenericArg = 3        // type used as generic argument
    TraitBound = 4        // type appears in trait bound
    Inheritance = 5       // type extends another type
```

**Diagnostic construction:**

1. When `ensure_type_resolved` hits a `Resolving` type, walk
   the resolution stack backward to find the full loop.
2. For each edge in the loop, emit a `note` with the span and
   a description of the relationship.
3. Emit a `help` with suggested fixes based on the edge types:
   - Field dependency → "consider using Handle[T]"
   - Alignment query → "consider removing align constraint"
   - Generic argument → "consider using indirection"

**Resolution stack:** Maintain a `Vec[DepEdge]` as a thread-local
or pass-local stack. Push when entering `ensure_type_resolved`,
pop when leaving. On cycle detection, the stack contains the
full loop.

---

## Implementation Note: `--fork` Flag

### Note

This is a package manager feature, not a compiler feature.
Implement when `with get` is built.

**CLI parsing:** `--fork` takes one path argument. Multiple
`--fork` flags are allowed. Paths are resolved to absolute
paths at parse time.

**Matching:** Each fork path must contain a `with.toml` with
a `[package]` section specifying `name` and `fingerprint`.
Match against the dependency tree's `with.lock` entries by
`(name, fingerprint)`. If no match, error. If match, log info
and override.

**Override mechanism:** Before dependency resolution fetches
or extracts a package, check the fork list. If a fork matches,
substitute the fork path for the fetched/extracted path. All
downstream resolution uses the fork path.

**Lock file policy:** Do not update `with.lock` when forks are
active. The lock file reflects the published dependency tree,
not development overrides. Emit a warning if the user runs
`with get --update` while forks are active:

```
warning: --fork is active, lock file not updated
  forks: /path/to/json-lib (json-lib)
```

**Build output policy:** Compiled artifacts from forked
dependencies go into a separate build cache directory
(`.with/fork-cache/`) to avoid polluting the normal build
cache. When the fork is removed, the fork cache is stale
but harmless — normal builds use the normal cache.

---

## Implementation Note: Compiler Self-Use of Async

### Note

This is a design constraint, not a feature to implement.

**Rule:** The With compiler itself must not use `async`, `spawn`,
`.await`, or the fiber scheduler in its own implementation.
The compiler pipeline is synchronous:

```
source → lex → parse → resolve → sema → MIR → codegen → link
```

Each phase runs to completion before the next begins. No fibers,
no concurrent phases, no async I/O.

**Rationale:** Zig discovered in February 2026 that using their
evented I/O for the compiler itself caused "unexpected performance
degradation." The overhead of the fiber scheduler (stack allocation,
context switching, event loop) exceeds the benefit for a
CPU-bound, sequential pipeline. The compiler processes one file
at a time through a deterministic pipeline. Async adds overhead
with no parallelism benefit.

**Future:** If function-level parallel codegen is ever added
(multiple functions codegen'd simultaneously), use OS threads
via `scope |s|:` blocks (available in `no_runtime` mode), not
fibers. Codegen is CPU-bound, not I/O-bound. Threads give real
parallelism. Fibers give cooperative scheduling for I/O — the
wrong tool for the job.

**Enforcement:** The compiler source (`src/*.w`) must compile
under `--no-runtime` mode. If it doesn't, something is using
async that shouldn't be. Add this as a CI check.
