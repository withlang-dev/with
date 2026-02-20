# The With Compiler — Development Plan

Companion to: Specification v4.1, Implementation Notes v9
Implementation language: **Zig** (bootstrap), then **With** (self-hosting)

---

## Overview

A phased implementation plan for building the With compiler from
zero to a self-hosting toolchain.

**Target:** A v1.0 compiler that passes all §25 test cases, compiles
the standard library, and can build a real async HTTP server with
database access.

---

## Part I — Strategic Decisions

### Decision 1: Implementation Language — Zig, then bootstrap to With

Zig is the bootstrap compiler language:

1. **Philosophical alignment.** Zig's values — explicit allocation,
   comptime, no hidden control flow, C interop as a first-class
   feature — are the same values With embodies. Writing the compiler
   in Zig means thinking in the same mental model as the language
   being compiled.

2. **C interop.** With's `c_import` feature requires invoking the
   C preprocessor and parsing C headers. Zig's seamless `@cImport`
   provides a working reference model and Zig's C interop makes
   calling into libclang (if needed) trivial.

3. **Comptime.** Zig's comptime enables generating lookup tables,
   keyword maps, and test infrastructure at compile time — directly
   paralleling With's own comptime feature.

4. **Fast iteration.** Zig compiles fast. The edit-compile-test cycle
   for the compiler itself stays tight throughout development.

5. **Bootstrap path.** Once With is mature enough (post-v1.0), the
   compiler transitions to self-hosting. Zig's simplicity means the
   Zig→With port is straightforward — both languages think in terms
   of explicit allocators, slices, tagged unions, and comptime.

Key Zig patterns for compiler work:
- **Interning:** `std.StringHashMap` or custom intern table backed
  by `std.mem.Allocator` and `std.ArrayList`
- **Arenas:** `std.heap.ArenaAllocator` (ideal for AST allocation —
  allocate forward, free all at once)
- **Error reporting:** hand-written diagnostic renderer using
  `std.io.Writer`
- **LLVM codegen:** `@cImport("llvm-c/Core.h")` — call LLVM-C API
  directly from Zig
- **Testing:** Zig's built-in `test` blocks + a custom snapshot
  test harness (read expected output files, compare, update on flag)

### Decision 2: Backend — LLVM from day one

Zig can `@cImport` the LLVM-C headers and call the LLVM C API
directly. The Zig project itself uses LLVM as its backend, so there
is strong ecosystem precedent and community knowledge for
LLVM-from-Zig. Starting with LLVM means:

- **No throwaway backend.** Every line of codegen work goes toward
  the production backend.
- **Optimization from the start.** `llvm.PassManager` gives `-O2`
  for free once the IR is correct.
- **Correct ABI handling.** LLVM knows calling conventions for every
  target.
- **All targets from day one.** x86_64, aarch64, RISC-V, WebAssembly
  — whatever LLVM supports, With supports.
- **Debug info.** LLVM's DWARF/CodeView generation means `gdb`/`lldb`
  integration is available early, not as a late-stage addition.
- **JIT capability.** LLVM's ORC JIT enables a future REPL without
  a separate backend.

**SSA construction strategy:** Use `alloca` for all local variables,
then run LLVM's `mem2reg` pass to promote to SSA registers. This is
the standard approach (used by Clang, Zig, and most LLVM frontends).
It means the codegen emits simple, imperative IR without manually
constructing phi nodes — `mem2reg` handles it.

**Debugging LLVM IR:** When generated code behaves incorrectly:
1. Dump the `.ll` file (`LLVMPrintModuleToFile`) and read it
2. Run `llvm-dis` on bitcode, `opt -print-after-all` to trace passes
3. Use `lli` to interpret IR directly (isolates codegen from backend)
4. Compare against expected IR using snapshot tests

The LLVM-C API covers everything needed for a v1.0 compiler:
module/function/block construction, all instruction types, type
system, pass manager, target machine, object file emission. The few
gaps (some newer passes, custom pass plugins) are not needed for
With's requirements.

**Build dependency:** The compiler requires LLVM to build. This is
managed via `build.zig` linking against the system LLVM installation
(or a vendored copy). Zig's build system handles this naturally —
`@cImport("llvm-c/Core.h")` and link flags in `build.zig`.

### Decision 3: Parser — Hand-written recursive descent

Error messages are a primary UX goal. Every successful
language compiler (Go, Rust, Swift, Zig, TypeScript) uses
hand-written parsing because it gives the best error recovery
and the best diagnostics.

With's grammar is mostly LL(1) with a few lookahead points:
- `with` keyword requires lookahead to distinguish forms (§7)
- `|>` vs `|` (closure) requires context
- Expression vs statement requires newline sensitivity

These are all tractable with recursive descent + minimal lookahead.

---

## Part II — Architecture

### Error Architecture

Errors are accumulated, not fatal. The compiler reports as many
errors as possible in a single pass:

1. **Error recovery in the parser** — skip to next statement/block
   on parse error, continue parsing
2. **Poisoned AST nodes** — mark subtrees as erroneous, skip them
   in later passes
3. **Salsa-style query architecture** (optional, for IDE support) —
   incremental recomputation of changed modules

For v1.0: accumulate errors per phase, run all phases that can
proceed despite errors. A type error in function A should not
prevent borrow-checking function B.

### Testing Strategy

Every compiler feature ships with three test categories:

1. **Positive tests** — valid programs that must compile and run
   (the §25 test suite)
2. **Negative tests** — invalid programs that must produce specific
   errors (the §20b denied patterns, borrow check violations, type
   errors)
3. **Diagnostic tests** — verify that error messages contain the
   expected text, point to the right line, and suggest the right fix

Use snapshot testing for AST dumps, MIR output, and LLVM IR. The
snapshot harness reads `.expected` files and diffs against actual
output. When a test breaks, you review the diff rather than writing
assertion boilerplate. Pass `--update-snapshots` to refresh.

**The §25 test suite is the acceptance criteria.** Every phase is
done when its milestone tests pass.

### Compiler Data Structures

```
Source File (.w)
    │
    ▼
Tokens ─────────── Lexer
    │                 (produces token stream with spans)
    ▼
Concrete Syntax ── Parser
Tree (CST)           (hand-written recursive descent)
    │                 (preserves trivia: comments, whitespace)
    ▼
AST ─────────────── AST Lowering
    │                 (typed, resolved, no sugar)
    │
    ├── c_import ─── C Header Resolution
    │                 (invoke cc -E, parse, map types)
    │
    ├── Name Res ─── Name Resolution
    │                 (resolve all identifiers to definitions)
    │
    ├── Type Check ── Bidirectional Type Inference
    │                  (Hindley-Milner local, explicit at boundaries)
    │
    ├── Ephemeral ─── Ephemeral Checker
    │   Check          (post-type-check walk, verify storage rules)
    │
    ├── Borrow ────── Borrow Checker
    │   Check          (intra-procedural, NLL, disjoint fields)
    │
    ├── Denied ────── Denied Patterns Checker
    │   Patterns       (§20b: must_use, unreachable, narrowing, etc.)
    │
    ▼
MIR ─────────────── MIR Lowering
    │                 (desugar: with-blocks, generators, match,
    │                  closures, async/await, comptime expansion)
    │
    ├── Optimize ─── MIR Optimization
    │                 (monomorphization, devirtualization,
    │                  escape analysis, move elision)
    │
    ▼
LLVM IR ─────────── LLVM Backend
    │                 (alloca + mem2reg)
    │
    ├── Optimize ─── LLVM Pass Pipeline (-O0 / -O2 / -Os)
    │                 (inlining, constant folding, DCE,
    │                  vectorization, register allocation)
    │
    ▼
Object File ────── LLVM Target Machine (emit .o)
    │
    ▼
Binary ──────────── System Linker (ld/lld)
                     (with c_import link directives)
```

### Key Internal Types

```zig
// Spans track source locations for error reporting
const Span = struct {
    file: FileId,
    start: u32,
    end: u32,
};

// Interned strings for fast comparison
const Symbol = u32; // index into string interner

// AST nodes are arena-allocated (std.heap.ArenaAllocator)
const Expr = struct {
    kind: ExprKind,
    span: Span,
    ty: ?TypeId, // null until type-checked
};

const ExprKind = union(enum) {
    literal: Literal,
    ident: Symbol,
    binary: struct { op: BinOp, lhs: *const Expr, rhs: *const Expr },
    call: struct { callee: *const Expr, args: []const *const Expr },
    with_block: WithForm,
    match_expr: struct { subject: *const Expr, arms: []const Arm },
    closure: struct { params: []const Param, body: *const Expr },
    await_expr: *const Expr,
    pipeline: struct { lhs: *const Expr, rhs: *const Expr },
    field_access: struct { expr: *const Expr, field: Symbol },
    optional_chain: struct { expr: *const Expr, field: Symbol }, // ?.
    default_op: struct { lhs: *const Expr, rhs: *const Expr },  // ??
    tuple: []const *const Expr,
    tuple_index: struct { expr: *const Expr, index: u32 },
    comprehension: ComprehensionForm,
    variant_shorthand: Symbol, // .Member
    // ...
};

// Types are interned for fast equality
const TypeId = u32; // index into type interner

const Type = union(enum) {
    primitive: PrimType,
    @"struct": struct { name: Symbol, fields: []const Field },
    @"enum": struct { name: Symbol, variants: []const Variant },
    function: struct { params: []const TypeId, ret: TypeId },
    generic: struct { name: Symbol, args: []const TypeId },
    ref: struct { kind: RefKind, pointee: TypeId },
    tuple: []const TypeId,
    task: TypeId,
    range: TypeId,
    never,
    @"error", // poison type for error recovery
};

// MIR: simplified, desugared, explicit control flow
const MirStmt = union(enum) {
    assign: struct { place: Place, value: MirExpr },
    drop: Place,
    call: struct { dest: Place, func: FnId, args: []const Operand },
    switch_int: struct { operand: Operand, cases: []const Case, default: BlockId },
    ret: Operand,
    goto: BlockId,
    // ...
};
```

### Source Map and Diagnostics

Every AST node carries a `Span`. Every error is a structured value:

```zig
const Diagnostic = struct {
    severity: enum { @"error", warning },
    code: DiagCode,                // E0701, E0802, etc.
    message: []const u8,
    primary: Span,                 // "the problem is here"
    labels: []const Label,         // secondary locations
    notes: []const []const u8,     // = note: ...
    helps: []const []const u8,     // = help: ...
};

const Label = struct {
    span: Span,
    message: []const u8,
};
```

Render diagnostics with a hand-written renderer using `std.io.Writer`.
The output format follows §15 (file:line:col, underlines, color).
This is straightforward to implement — ~200 lines of Zig — and gives
full control over the output format without external dependencies.

---

## Part III — Phased Implementation

### Phase 0: Bootstrap + C Interop

**Goal:** Compile a With file that calls `printf` via `c_import`.

#### 0.1 Project Scaffolding

- Zig project with `build.zig`: modules for `ast`, `types`, `parse`,
  `check`, `mir`, `codegen`, `driver`, `diag`
- Each module is a separate Zig file or directory under `compiler/src/`
- CI pipeline: `zig build test` on Linux, macOS, Windows
- Test harness: reads `.w` files from `tests/`, compiles, runs,
  checks output and exit code against expected
- Snapshot test infrastructure: custom test runner that compares
  output against `.expected` files, with `--update` flag to refresh

#### 0.2 Lexer

Tokenize With source into a stream of typed tokens with spans.

Key tokens: keywords (`fn`, `let`, `with`, `match`, `for`, `if`,
`else`, `return`, `break`, `continue`, `async`, `await`, `unsafe`,
`type`, `trait`, `impl`, `use`, `module`, `pub`, `extend`, `var`,
`comptime`, `gen`, `in`, `as`, `mut`, `then`, `loop`, `while`,
`ephemeral`, `spawn`, `defer`, `error`, `extern`),
operators (`|>`, `<|`, `>>`, `<<`, `?`, `?.`, `??`, `->`, `=>`,
`..`, `..=`, `=`, `+`, `-`, `*`, `/`, `+%`, `-%`, `*%`, `@`),
brackets (including `[` for generics and comprehensions),
literals (int, float, string with interpolation, bool),
identifiers, `.Variant` (dot-prefixed for enum variant shorthand),
comments, newlines (significant for statement separation).

String interpolation (`"hello {name}"`) tokenizes as: STRING_START,
expression tokens, STRING_END. The parser reassembles these.

Test: tokenize all §25 test cases, snapshot token output.
Use Zig's built-in `test` blocks for unit tests; the snapshot
harness for integration tests.

#### 0.3 Parser

Hand-written recursive descent parser producing a CST/AST.

Start with the minimal subset needed for Phase 0:
- Module declaration, use imports
- Function definitions (fn, parameters, return type, body)
- Let bindings (let, var), defer
- Expressions: literals, identifiers, binary ops, unary ops,
  function calls, field access, index, if/else, block, ranges
  (`..`, `..=`)
- Type annotations: primitives, named types, generics (T[U]),
  references (&T, &mut T), function types, tuples
- `unsafe` blocks
- Basic error recovery: on parse error, skip to next `fn` or
  top-level declaration

Deferred to later phases: `with` blocks, closures, match, for,
generators, async/await, pattern matching, pipelines, comptime,
optional chaining (`?.`), default operator (`??`), comprehensions,
enum variant shorthand (`.Member`), field shorthand, default field
values, `let...else`, partial application.

Test: parse all Phase 0 test programs, snapshot AST output.

#### 0.4 Name Resolution

Build a scope tree. Resolve all identifiers to their definitions.
Handle: function parameters, let bindings, module-level functions
and types, prelude imports (Option, Result, primitives), use imports.

No generics yet — just direct name lookup.

#### 0.5 Type Checker — Minimal

Bidirectional type inference for the Phase 0 subset:
- Literal types (integer, float, bool, string)
- Variable types from annotations or inference
- Function call type checking (argument count and types)
- Return type checking
- Binary operator type rules
- Struct construction and field access
- Tuple types: `(T, U)`, tuple construction, `.0`/`.1` access,
  tuple destructuring in `let` bindings (§4.8)
- Range types: `Range[T]` for `..`, `RangeInclusive[T]` for `..=`
- Pointer types for FFI (`*const T`, `*mut T`)
- **Type aliases (§15.1):** `str` = `String`, `&str` = `StrView`.
  These must exist from Phase 0 — they appear in nearly every
  function signature. Implement as built-in aliases in the prelude.

No generics, no traits, no closures. Just enough to type-check
C interop code.

#### 0.6 `c_import` via libclang

This is the critical Phase 0 deliverable. Implementation uses
**libclang** as the primary mechanism — not a hand-written C parser.

Real system headers (`stdio.h`, `stdlib.h`) pull in hundreds of
typedefs, compiler builtins, platform-specific attributes, and
`__attribute__` extensions. Writing a C declaration parser that
handles all of this is a multi-month project. libclang handles it
correctly because it *is* the C compiler. Since we already link
LLVM (which includes the clang libraries), libclang is essentially
free — no additional dependency.

Implementation:

1. **Invoke libclang:** Use `clang_parseTranslationUnit` to parse
   the header. This handles preprocessing, includes, platform
   detection, and all C language extensions automatically.
2. **Walk the AST:** Use `clang_visitChildren` to traverse
   declarations. Extract function signatures, struct/union/enum
   definitions, typedefs, and `#define` integer/string constants.
3. **Map types:** `int` → `i32`, `long` → `i64`, `char*` → `*const u8`,
   `void*` → `*mut u8`, `size_t` → `usize`, etc. (see impl notes §16.4)
4. **Inject as module:** Make the parsed declarations available as
   a With module. All functions are `unsafe`.
5. **Link directives:** `c_import("sqlite3.h", link: "sqlite3")`
   passes `-lsqlite3` to the linker.
6. **Caching:** Cache parsed headers by content hash. Don't re-parse
   unchanged system headers.

Zig itself uses libclang for `@cImport` — this is proven at scale.

Start with `stdio.h` (printf, puts), `stdlib.h` (malloc, free,
exit), `string.h` (strlen, memcpy). These are enough to bootstrap.

Test: compile and run:
```
use c_import("stdio.h", link: "c")
fn main() -> i32 =
    unsafe { c.printf("Hello from With!\n") }
    0
```

#### 0.7 LLVM Backend — Minimal

Generate LLVM IR from the typed AST via the LLVM-C API.

Setup:
- `@cImport` the LLVM-C headers (`llvm-c/Core.h`, `llvm-c/Target.h`,
  `llvm-c/Analysis.h`, `llvm-c/TargetMachine.h`)
- Link against LLVM libraries in `build.zig`
- Initialize native target (`LLVMInitializeNativeTarget`,
  `LLVMInitializeNativeAsmPrinter`)

Mapping (minimal Phase 0 subset):
- Module → `LLVMModuleCreateWithName`
- Functions → `LLVMAddFunction` with `LLVMFunctionType`
- Entry block → `LLVMAppendBasicBlock`
- Let bindings → `LLVMBuildAlloca` (promoted by `mem2reg`)
- If/else → `LLVMBuildCondBr` + basic blocks + `LLVMBuildPhi`
  (or use alloca approach and let mem2reg handle it)
- Function calls → `LLVMBuildCall2`
- Return → `LLVMBuildRet`
- Unsafe blocks → stripped (unsafe is compile-time only)
- Literals → `LLVMConstInt`, `LLVMConstReal`
- Extern functions (from c_import) → `LLVMAddFunction` with
  `LLVMSetLinkage(LLVMExternalLinkage)`

Output: emit an object file via `LLVMTargetMachineEmitToFile`,
then invoke the system linker (`ld` / `lld`) to produce a binary.
Link with any `c_import` link directives (`-lsqlite3`, etc.).

For debugging: dump `.ll` text via `LLVMPrintModuleToFile`.
Verify IR correctness with `LLVMVerifyModule`.

Test: compile and run the `printf` test case above. Output:
"Hello from With!"

#### 0.8 Build Driver

The `with build` and `with run` commands:
- `with run file.w` → lex → parse → check → LLVM IR → link → run
- `with build` → reads `with.toml`, compiles all modules, links
- `with test` → compile and run all `*_test.w` files

At this point you have a working (minimal) compiler. It can compile
a With file that calls C functions and produces a native binary.

**Phase 0 Milestone:** `c_import("stdio.h")` works. Can call
`printf` from With. Compiles and runs on Linux, macOS, Windows.

---

### Phase 1: Ownership Core

**Goal:** Move semantics, borrow checking, ephemeral types.
The memory safety guarantees are enforced.

#### 1.1 Move Semantics

- Values move on assignment (memcpy + invalidate source)
- Use-after-move is a compile error
- Copy trait: types that are bitwise-copyable are not moved
- Drop: insert destructor calls at scope exit, reverse declaration
  order
- **Copy and Drop are mutually exclusive (§2.3).** A type cannot
  implement both. This is a type-checker rule enforced at impl
  resolution: if a type has `Drop`, it cannot be `Copy`. If a type
  is `Copy`, implementing `Drop` is a compile error. This prevents
  double-free from implicit copies of types with destructors.

In LLVM IR: moves become `memcpy` intrinsic + debug-mode
`llvm.memset` zero-fill. Drops become calls to generated destructor
functions. Drop glue is emitted as LLVM functions called at scope
exit points.

#### 1.2 Borrow Checker

Implement the algorithm from impl notes §2:

1. Build control flow graph (CFG) for each function
2. Compute NLL ranges (borrow start → last use) using liveness
3. At each program point, check for conflicts:
   - No exclusive + any borrow of overlapping places
   - No use of moved values
4. Disjoint field analysis: `&mut obj.x` and `&mut obj.y` are
   non-conflicting

Key data structure: `Place` (variable, field access, deref, index).
Borrows are tracked as `(kind, place, liveness_range)`.

This is dramatically simpler than Rust's borrow checker because:
- No lifetime parameters (intra-procedural only)
- No lifetime subtyping
- No variance analysis
- No higher-ranked lifetimes
- Borrows cannot be stored (ephemeral rule handles that)

#### 1.3 Ephemeral Type Checker

Post-type-check AST walk (impl notes §3):

1. Mark types as ephemeral if they contain references
2. Verify: ephemeral values not stored in structs
3. Verify: ephemeral values not stored in collections
4. Verify: ephemeral values not returned except as ephemeral returns
5. Closures that capture ephemeral values are treated conservatively

#### 1.4 Reference Returns

A function can return a reference, but only if it borrows from a
parameter. The return value is ephemeral.

```
fn first(items: &[T]) -> &T = &items[0]
```

In the borrow checker: the return value's borrow is considered to
borrow from all reference parameters (conservative in v1.0).

**Phase 1 Milestone:** Tests 25.1–25.6 pass (ownership, borrowing,
ephemeral types, moves, drops).

---

### Phase 2: Generics + Ergonomic Surface

**Goal:** Minimal generics, `with` blocks, closures, pattern
matching, pipelines, error types. The language starts feeling like
With — and critically, the stdlib can be written with real types.

#### 2.1 Minimal Generics (Monomorphization Only)

Generics must land before the stdlib (Phase 3). Without them,
`Vec`, `HashMap`, `Option`, `Result`, `Iter`, `Scoped`, and `Try`
cannot be written — and the stdlib is unwritable. Writing concrete
`Vec_i32`, `Vec_String` etc. and "retrofitting later" means writing
the entire stdlib twice. Instead, ship minimal generics early:

**What ships in Phase 2:**
- Generic type definitions: `type Vec[T] = { ... }`
- Generic function definitions: `fn map[T, U](opt: Option[T], f: fn(T) -> U) -> Option[U]`
- Monomorphization: for each concrete instantiation, generate a
  specialized LLVM function
- Type parameter inference at call sites
- Dead code elimination: don't monomorphize unused instantiations

**What does NOT ship in Phase 2 (deferred to Phase 5):**
- Trait bounds (`T: Ord`, `T: Hash + Eq`)
- Trait definitions and impl blocks
- Dynamic dispatch (`dyn Trait`)
- Associated types
- Orphan rules

This is sufficient for the stdlib. `Vec[T]` works. `HashMap[K, V]`
works. `Result[T, E]` and `Option[T]` work. `for` loops desugar to
calling `.next()` — the compiler knows the concrete type at each
call site, so monomorphization handles it without trait bounds.

`with` blocks (Form 1) need `Scoped[T]`/`ScopedMut[T]` — but in
Phase 2 these can be resolved structurally (check if the type has
an `enter()`/`enter_mut()` method) rather than via trait dispatch.
Full trait resolution comes in Phase 5.

Similarly, `?` can desugar to a match on `Result`/`Option` directly
(the compiler knows which type it is) without requiring the `Try`
trait. The `Try` trait generalizes this in Phase 5.

#### 2.2 `with` Block Lowering

Implement all four forms (impl notes §4):

**Form 1 (Guarded):** Desugar to: call `.enter()`/`.enter_mut()`,
bind result, execute body, drop guard on exit (or unwind). Check
`@[no_await_guard]` annotation (§7.9). In Phase 2, resolve
structurally (method lookup), not via Scoped trait.

**Form 2 (Builder):** Desugar to: let-binding with mutable local,
execute body, result is block value.

**Form 3 (Binding):** Desugar to: let-binding, execute body.

**Form 4 (Record update):** Desugar to: struct construction with
fields from source plus overrides, move/copy semantics.

**Dispatch rule (§7.5):** check if type implements
`Scoped`/`ScopedMut` (structurally via `.enter()`/`.enter_mut()`
in Phase 2, via trait dispatch in Phase 5) → Form 1.
Check for `mut` on non-Scoped type → Form 2. Otherwise → Form 3.
Non-local control flow (`return`, `break`, `continue`, `?`) inside
`with` blocks is transparent — it affects the enclosing function
or loop, not the desugared closure (§7.7).

#### 2.3 Closures

- Parse closure syntax: `|params| expr` and `|params| { block }`
- Capture analysis: determine which variables the closure captures
- Capture mode: by reference (default) or by move (`move |...|`)
- Escaping detection (spec §12.3): closures bound to named
  variables are conservatively treated as escaping
- LLVM codegen: closure → struct of captured values + function pointer

#### 2.4 Pattern Matching

Full pattern matching (impl notes §9):

- Literal patterns, variable patterns, wildcard
- Constructor patterns (enum variants)
- Nested patterns
- Or-patterns (`A | B ->`)
- Guard clauses (`if condition`)
- Binding (`name @ pattern`)
- Exhaustiveness checking (required)
- Usefulness checking (warn on unreachable arms)
- `if let` as sugar for single-arm match with fallthrough

Compile to decision trees (impl notes §9 recommends Maranget's
algorithm).

#### 2.5 Pipeline Operator

`a |> f` desugars to `f(a)`.
`a |> f(b, _, c)` desugars to `f(b, a, c)` (placeholder).
`f >> g` desugars to `|x| g(f(x))`.
`f << g` desugars to `|x| f(g(x))`.
`f <| a` desugars to `f(a)`.

These are purely syntactic transforms applied during AST lowering.
No runtime cost.

#### 2.6 Struct Ergonomics (§4.3)

**Field shorthand:** When a variable name matches a field name,
the explicit `: value` can be omitted:
`User { name, email, active: true }` → `User { name: name, email: email, active: true }`.
This is parser sugar — the desugaring happens during AST lowering.

**Default field values:** Struct definitions can specify defaults:
`type Config = { port: u16 = 8080, debug: bool = false }`.
Fields with defaults can be omitted at construction time:
`Config { port: 9090 }` uses `debug: false`. The compiler inserts
default expressions at each construction site. Defaults are
evaluated fresh per construction (not cached).

Both features apply to record update syntax too:
`{ config with port }` uses field shorthand in the update.

#### 2.7 Enum Variant Shorthand (§4.4)

When the expected type is known from context, enum variants can be
written with a dot prefix instead of the full type name:
`.Member` instead of `Role.Member`.

The compiler infers the type from:
- Return type annotations: `fn default() -> Color = .Blue`
- Match subjects: `match c { .Red -> ..., .Blue -> ... }`
- Function arguments: `paint(.Red)`
- Struct field types: `Config { theme: .Green }`

Without a known type, `.Variant` is a compile error (§25.35).
This is type-checker sugar — the AST stores the shorthand, the
type checker resolves it to the full qualified name.

#### 2.8 Tuples (§4.8)

Tuples are first-class types: `(i32, str)`, `(A, B, C)`.
Phase 0 adds the type and construction syntax. Phase 2 adds:
- Tuple patterns in match: `(0, 0) -> "origin"`
- Tuple destructuring in `let`: `let (x, y) = point`
- Tuple destructuring in `for`: `for (k, v) in map:`
- Nested tuple patterns: `let ((a, b), c) = nested`
- Tuple is Copy when all elements are Copy (§25.36)

#### 2.9 Optional Chaining and Default Operator (§10.3, §10.4)

**Optional chaining (`?.`):** `user.address?.city` desugars to
`user.address.map(|a| a.city)`. Works on both `Option[T]` and
`Result[T, E]`. Chains naturally: `a?.b?.c`.

**Default operator (`??`):** `x ?? default` desugars to
`x.unwrap_or(default)` with lazy evaluation of the right side.
Chains: `a ?? b ?? c ?? fallback`.

**Early exit form:** `let user = find(id) ?? return Err(.NotFound)`
desugars to a match + early return. This replaces most `let...else`
uses in practice.

#### 2.10 Collection Comprehensions (§13.6)

`[expr for x in iter if cond]` desugars to
`iter |> filter(|x| cond) |> map(|x| expr) |> collect[Vec]()`.

Multiple `for` clauses desugar to nested `flat_map`. Comprehensions
always produce `Vec`. This is pure sugar — no new semantics.

#### 2.11 Let-Else and Destructuring (§9.7)

**`let...else`:** `let Some(x) = expr else return Err(.NotFound)`
— refutable pattern with mandatory diverging else branch.

**Slice patterns:** `[first, ..rest]`, `[]`, `[only]` in match
and `let` bindings.

**Parameter patterns:** Function parameters can destructure:
`fn distance({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point)`.
Desugars to a match on the parameter at function entry.

**`match` in pipelines:** `input |> parse |> match { Ok(v) -> ..., Err(e) -> ... }`

#### 2.12 Error Types

`error` declarations desugar to enum types with auto-generated
`Display` and `Debug` impls.

`?` operator desugars to match + early return on `Result`/`Option`
directly. Generalized `Try` trait comes in Phase 5.

#### 2.13 Denied Patterns Checker

Implement the six §20b rules as a post-type-check pass:
- E0701: `await` inside `@[no_await_guard]` guard
- E0802: unused `Result` or `Option`
- E0801: unused `Task`
- E0901: unnecessary `unsafe`
- E0201: implicit narrowing
- E0601: unreachable code (requires control flow analysis)

#### 2.14 For Loops

`for x in collection:` desugars to iterator protocol calls
(`.iter()`, `.next()`). In Phase 2, the compiler knows the concrete
type at each call site and resolves `.next()` via method lookup +
monomorphization. The `Iter[T]` trait formalizes this in Phase 5.

#### 2.15 Tail Call Optimization

Detect tail position calls. In LLVM: emit `musttail call` (LLVM
guarantees tail call elimination for `musttail`). Guaranteed, not
optional. `@[tailrec]` annotation on a non-tail-recursive function
is a compile error (§9.2).

**Phase 2 Milestone:** Tests 25.7, 25.9, 25.12–25.14,
25.19–25.31, 25.34–25.39, 25.41–25.42 pass. Generic `Vec[T]`
and `HashMap[K, V]` work. Field shorthand, default field values,
enum variant shorthand, tuples, optional chaining, `??`, and
comprehensions all work. The language is usable for real programs
(without traits or async).

---

### Phase 3: Standard Library

**Goal:** Users can write real programs without `c_import`.

This phase is mostly With code, not compiler (Zig) work. The compiler
has generics (Phase 2), so the stdlib is written with real generic
types from the start — `Vec[T]`, `HashMap[K, V]`, `Option[T]`,
`Result[T, E]`. No concrete-type stubs, no retrofit.

This is also the first real validation that the compiler works — if
the stdlib can be written and tested in With, the language is viable.

#### 3a: Core

Written in With using `c_import` (via libclang) for platform access:
- `std.mem` (size_of, align_of, copy)
- `std.fmt` (Display, Debug, format, string interpolation backend)
- `std.io` (Reader, Writer, print/println, stdin/stdout/stderr)
- `std.fs` (File, read_file, write_file, directory ops)
- `std.string` (String methods, StrView methods)
- `std.collections` (`Vec[T]`, `HashMap[K, V]`, `HashSet[T]`) — pure With
- `Option[T]` combinator methods: `map`, `and_then`, `or_else`,
  `unwrap_or`, `filter`, `zip`, `flatten`, `cloned`, `transpose`
- `Result[T, E]` combinator methods: `map`, `map_err`, `and_then`,
  `or_else`, `context`, `with_context`, `ok`, `err`, `transpose`
- `ContextError[E]` type for `.context()` error wrapping (§10.6)
- Collection combinators: `sequence`, `traverse` (§10.7)

Pure-With modules (collections, combinators) can be written and
tested immediately. Platform-dependent modules (fs, io) require
conditional compilation (`comptime if cfg.target_os`).

#### 3b: Systems

- `std.time` (Instant, Duration, SystemTime)
- `std.math` (f32/f64 methods wrapping libm)
- `std.process` (args, env, exit, Command)
- `std.random` (Rng)
- `std.hash` (Hasher, DefaultHasher) — pure With
- `std.collections` continued (SlotMap, Handle, BTreeMap)

#### 3c: Concurrency Foundations

- `std.thread` (spawn_os, JoinHandle — wraps pthreads)
- `std.sync` (Mutex, RwLock, Atomic, Condvar — wraps pthreads)
- `std.alloc` (Arena, Pool)
- Generator lowering (impl notes §5)

**Phase 3 Milestone:** Tests 25.8, 25.15, 25.16, 25.19, 25.22 pass.
A user can write file I/O, collections, string processing, timing
code without ever seeing `c_import`.

---

### Phase 4: Concurrency

**Goal:** Async/await, fiber runtime, structured concurrency.

#### 4.1 Fiber Runtime

Implement the runtime described in impl notes §7–8:
- **Context switching via hand-written assembly** (primary approach).
  `ucontext` is deprecated on macOS and absent on some platforms.
  Go, Zig, and most production fiber libraries use hand-written
  assembly for context switching — it is faster (~10 ns vs ~50 ns
  for `ucontext`) and portable. Required assembly:
  - x86_64: save/restore callee-saved registers + stack pointer swap
  - aarch64: same pattern, different registers
  - Fallback: `ucontext` on platforms where assembly is not yet written
- Fiber pool with recycled stacks
- 8KB initial stack, growable to 64KB (segmented stacks)
- M:N scheduler: fibers multiplexed onto OS thread pool
- Work-stealing dequeue (one per OS thread)

The runtime is a Zig library (with assembly stubs) linked into every
async With program. Zig's ability to target C ABIs and cross-compile
makes the runtime portable. It is absent in `no_runtime` builds.

#### 4.2 Async/Await Lowering

`async fn` → function that allocates a fiber and returns `Task[T]`.
`await expr` → suspend current fiber, resume when task completes.

In MIR: `await` becomes `yield_to_scheduler(task)`.
In LLVM IR: emit a call to the fiber runtime's context-switch
function. The runtime handles suspension/resumption via
`swapcontext` (or platform equivalent). The LLVM IR itself is
straightforward — fiber suspension is just a function call, not a
coroutine transformation.

Key difference from Rust: no state machine transformation. The fiber
has a real stack. Local variables across `await` are just stack
variables. The borrow checker doesn't need special async handling.

#### 4.3 Task[T], Structured Concurrency, Channels

- `Task[T]` — opaque handle wrapping a fiber ID
- `@[must_use]` enforcement on `Task`
- **Task ephemerality (§14.20):** If the spawned fiber's environment
  captures ephemeral values (references, StrView, etc.), the `Task`
  itself is ephemeral and cannot be stored or returned. The compiler
  must track whether a Task's closure captures ephemerals and
  propagate the ephemeral flag to the Task value. This ensures
  tasks that borrow local data cannot outlive their scope.
- `cancel()` — set cancellation flag, unwind at next await
- `async scope` — spawn tasks that must complete before scope exits
- `select()` — wait on first of N tasks
- `Channel[T]` — MPMC channel, bounded and unbounded variants
- `Send`/`Sync` trait enforcement

#### 4.4 std.net

- `TcpListener`, `TcpStream`, `UdpSocket`
- DNS resolution
- Integration with fiber scheduler (async I/O via epoll/kqueue/IOCP)
- `std.signal` (thin wrapper)

**Phase 4 Milestone:** Tests 25.17, 25.18 pass. A simple HTTP
server runs with concurrent connection handling.

---

### Phase 5: Traits

**Goal:** Full trait system, trait bounds on generics, dynamic
dispatch, syntax traits.

Generics (monomorphization) already shipped in Phase 2. The stdlib
is already generic. This phase adds the *constraint system* — trait
bounds that restrict what types can be used, trait objects for
dynamic dispatch, and syntax traits that power language features.

#### 5.1 Trait Definitions and Impls

- Parse trait definitions with methods (including default methods)
- Parse impl blocks
- Orphan rules (impl notes §13)
- Method resolution: look up method on concrete type, then trait impls
- Trait coherence checking (no overlapping impls)

#### 5.2 Trait Bounds

- `fn sort[T: Ord](items: &mut [T])` — constrain type parameters
- Multiple bounds: `T: Hash + Eq`
- Where clauses for complex bounds
- Bounds checked at call site and enforced in body

#### 5.3 Syntax Traits (§11.7)

Wire up the language features that were using structural resolution
(Phase 2) to their formal trait definitions:
- `Iter[T]` — powers `for` loops and iterator methods
- `Scoped[T]` / `ScopedMut[T]` — powers `with` block Form 1
- `Index[K, V]` — powers `[]` subscript syntax
- `Try[T, E]` — powers `?` operator (generalizes beyond Result/Option)
- `Add`, `Sub`, `Mul`, etc. — operator overloading
- `Drop` — destructor trait (already works, now formalized)
- `Display`, `Debug` — string formatting

#### 5.4 Dynamic Dispatch

- `dyn Trait` — trait objects with vtable dispatch
- Object safety rules (no generic methods in vtable)
- `Box[dyn Trait]`, `&dyn Trait`
- Devirtualization optimization (MIR pass): when concrete type is
  known at a call site, replace vtable dispatch with direct call

#### 5.5 Stdlib Trait Impls

Add trait implementations to the existing generic stdlib:
- `Vec[T]` implements `Iter[T]`, `Index[usize, T]`
- `HashMap[K, V]` implements `Index[K, V]`
- `Result[T, E]` implements `Try[T, E]`
- `Mutex[T]` implements `ScopedMut[T]`
- `String` implements `Display`, `Debug`, `Add`

**Phase 5 Milestone:** Tests 25.10, 25.11 pass. Trait-bounded
generics work. `dyn Trait` works. Syntax traits power `for`, `with`,
`?`, and `[]`.

---

### Phase 6: Polish

**Goal:** Comptime, tooling, optimization, production readiness.

#### 6.1 Comptime

Compile-time evaluation (§17):
- `comptime if` / `comptime for` — conditional compilation and
  unrolling
- `TypeInfo` API — type introspection at compile time:
  `TypeInfo.fields[T]()`, `TypeInfo.variants[T]()`,
  `TypeInfo.size[T]()`, `TypeInfo.implements[T, Trait]()`,
  `TypeInfo.is_copy[T]()` (§17.2)
- `comptime fn` — functions that run at compile time,
  deterministic, no I/O (§17.7)
- `comptime_error` — custom compile errors from comptime code
- Code generation: comptime loops stamp out code, feed through
  normal type checking and borrow checking
- `@[derive(...)]` — comptime-powered derive macros (§17.3)
- `@[derive(all)]` — derive all qualifying structural traits:
  Copy, Clone, Eq, Hash, Ord, Debug. Conservative — only derives
  traits where all fields qualify. Silently drops traits when a
  field is added that doesn't satisfy requirements (§11.8)

This is a significant feature but well-isolated — it's an
additional compiler pass between type checking and MIR lowering.

#### 6.2 Formatter (`with fmt`)

Auto-formatter with canonical style. No configuration debates.
Operates on the CST (preserves comments). Fast (whole-project
formatting in <1s).

#### 6.3 Doc Generator (`with doc`)

Parse doc comments, generate HTML documentation. Cross-linked types.
Usage examples extracted and tested.

#### 6.4 Language Server (LSP)

Incremental compilation via Salsa-style queries. Provides:
- Go to definition
- Find references
- Type on hover
- Autocomplete
- Inline error diagnostics
- Rename symbol

This is the most effort-intensive single feature. Consider starting
with a basic "batch compile and report errors" mode, then adding
incremental support over time.

#### 6.5 REPL (`with repl`)

Interactive evaluation. Use LLVM's ORC JIT API (available via
LLVM-C) to compile and execute With expressions in-process. Since
LLVM is already linked, JIT support is a natural extension — no
extra backend needed. Not critical for v1.0 but excellent for
learning.

#### 6.6 Optimization

LLVM's pass pipeline handles standard optimizations at `-O2`:
inlining, constant folding, dead code elimination, register
allocation, instruction selection, vectorization.

The With compiler should focus on **MIR-level optimizations** that
require language-level knowledge LLVM doesn't have:

- **Devirtualization:** monomorphize trait object calls when the
  concrete type is known at a call site
- **Escape analysis:** stack-allocate `Box` allocations when the
  value doesn't escape the current scope
- **Dead field elimination:** remove struct fields that are never
  read (requires whole-program analysis)
- **Move elision:** eliminate redundant memcpy when source is
  immediately consumed (LLVM can sometimes do this, but With's
  ownership semantics make it provable at MIR level)

#### 6.7 `c_import` Improvements

- Translate more C macros (function-like macros, common patterns)
- Handle C++ headers (via `extern "C"` blocks)
- Improved caching and invalidation
- Better error messages for untranslatable declarations

#### 6.8 Source Translation Tools

Three automated translation tools for languages structurally close
enough to With that mechanical conversion is practical. Each tool
parses source using the language's own parser infrastructure, applies
AST-to-AST transforms, and emits With source text. The output is
idiomatic but may require manual fixups for patterns that have no
direct equivalent.

Languages **not** covered (Go, C, C++) require fundamentally different
ownership thinking — automated translation would produce broken code.
Developers from those languages should use the migration guide
(`docs/with-migration-guide.md`) and convert by hand.

**`rust2with`** — Rust → With

Rust is the closest language to With. The ownership model, borrow
checker, and trait system are identical. Translation is almost
entirely syntactic:

Mechanical transforms:
- `{ }` blocks → `:` + indentation (reindent entire file)
- `let mut x` → `var x`; strip semicolons
- `<T>` → `[T]` in all generic positions
- `impl Foo` → `extend Foo`; `impl Trait for Foo` → `extend Foo: Trait`
- `&self` → `self: &Foo`; `&mut self` → `self: &mut Foo`
- `String` → `str`; `String::from("x")` / `"x".to_string()` → `"x"`
- `Ok(())` → `Ok()`; `#[attr]` → `@[attr]`; `::` → `.`
- `println!("{}", x)` → `println("{x}")` (rewrite format macros)
- `match x { A => ..., }` → `match x` + newline + `A -> ...`
- Strip all lifetime annotations (`'a`, `'static`, `'_`)
- `async fn` / `.await` → same (but strip `Send` bounds)
- `Box::new(x)` → `Box.new(x)`

Requires manual fixup:
- Complex lifetime relationships (restructure to owned types or
  ephemeral returns)
- Proc macro expansions (expand first, then translate)
- `Pin`/`Unpin` patterns (delete — fibers don't need them)
- `Fn`/`FnMut`/`FnOnce` trait bounds (simplify to closure types)
- Crate-level module structure (`mod.rs` → file-per-module)

Implementation: invoke `rustc` as a library (`rustc_ast` / `rustc_hir`)
or use `syn` to parse, walk the AST, emit With source. Can be a
standalone Rust binary that shells out from `with migrate rust src/`.

**`zig2with`** — Zig → With

Zig and With share comptime, explicit control flow, and similar type
systems. The main addition is ownership — Zig trusts the programmer,
With enforces it.

Mechanical transforms:
- `const x: T = val` → `let x: T = val`; `var` → `var`
- `fn foo(x: T) T { return expr; }` → `fn foo(x: T) -> T = expr`
- `try expr` → `expr?`; `orelse` → `??`
- `!T` (error union) → `Result[T, E]`; `?T` → `Option[T]`
- `[]const u8` → `&[u8]`; string literals → `&str`
- `std.ArrayList(T)` → `Vec[T]`; `std.AutoHashMap(K,V)` →
  `HashMap[K, V]`
- `@as(T, val)` → `val as T`; `@intCast(val)` → `val as T`
- `@typeInfo(T)` → `TypeInfo.fields[T]()`; `inline for` →
  `comptime for`
- `test "name" { ... }` → `fn test_name() = ...`
- `{ }` blocks → `:` + indentation
- Strip allocator parameters and `.deinit()` calls (RAII handles it)
- `null` → `None`; `undefined` → (flag as error, must initialize)

Requires manual fixup:
- Manual memory management patterns (alloc/free → owned types)
- `errdefer` (restructure using `?` propagation + RAII)
- `undefined` sentinel values (must provide real initializers)
- Custom allocator strategies (arena patterns need `with` blocks)
- Comptime duck typing (add trait bounds where Zig relied on
  structural conformance)

Implementation: use Zig's `std.zig.Ast` parser directly (the
compiler is already Zig). Parse, walk, emit With source. Natural
integration into the build: `with migrate zig src/`.

**`swift2with`** — Swift → With

Swift is surprisingly close: value types, optionals, protocol-oriented
design, structured concurrency. The main difference is ARC → ownership.

Mechanical transforms:
- `let` / `var` → `let` / `var` (identical)
- `func foo(_ x: Int) -> Int` → `fn foo(x: i32) -> i32`
- `T?` → `Option[T]`; `nil` → `None`
- `guard let x = opt else { return }` → `let x = opt else return`
- `throws` / `try` → `-> Result[T, E]` / `?`
- `protocol Foo` → `trait Foo`; `extension Foo: Bar` →
  `extend Foo: Bar`
- `switch x { case .a: ... }` → `match x` + `.A -> ...`
- `\(expr)` → `{expr}` (string interpolation)
- `async throws` → `async fn ... -> Result[T, E]`
- `try await expr` → `expr.await?`
- `withThrowingTaskGroup` → `async scope |s|:`; `group.addTask` →
  `s.track()`
- `class` → `type` (flag shared-ownership cases for `Arc`)
- `[T]` (Array) → `Vec[T]`; `[K: V]` → `HashMap[K, V]`
- `Set<T>` → `HashSet[T]`

Requires manual fixup:
- `weak`/`unowned` references (restructure ownership or use `Arc`)
- `@MainActor` isolation (delete — not needed with fibers)
- `@Published` / Combine (rewrite to channels)
- Trailing closure syntax (rewrite to pipelines or named functions)
- Implicit `self` capture rules (explicit in With)
- Class inheritance hierarchies (flatten to trait composition)

Implementation: use `swift-syntax` (Swift's own parser library) to
parse, walk the syntax tree, emit With source. Standalone Swift
binary: `with migrate swift Sources/`.

**CLI interface:**

```
with migrate <lang> <path>         Translate files in-place, writing .w alongside originals
with migrate <lang> <path> --check Dry run — report what would change, flag manual fixups
with migrate <lang> <path> --diff  Show before/after diff without writing
```

The `--check` mode is particularly valuable: it scans source files
and reports a summary of mechanical transforms vs. manual fixups
needed, giving developers a realistic estimate before starting.

**Phase 6 Milestone:** Tests 25.40 (derive) pass. `with fmt`,
`with doc`, `with repl`, and `with migrate` work. Comptime enables
`@[derive(all)]` and `@[derive(Serialize)]`. LSP provides basic IDE
support.

---

## Part IV — Structure

### Repository Layout

```
with/
├── build.zig             # Zig build system entry point
├── build.zig.zon         # Zig package manifest
├── compiler/
│   └── src/
│       ├── main.zig      # CLI entry point (with build/run/test)
│       ├── driver.zig    # Compilation pipeline orchestration
│       ├── lexer.zig     # Tokenizer
│       ├── parser.zig    # Recursive descent parser → AST
│       ├── ast.zig       # AST type definitions
│       ├── types.zig     # Type interner, type definitions
│       ├── resolve.zig   # Name resolution
│       ├── check.zig     # Type checker
│       ├── borrow.zig    # Borrow checker
│       ├── ephemeral.zig # Ephemeral type checker
│       ├── mir.zig       # MIR types + lowering
│       ├── codegen_llvm.zig # LLVM IR backend
│       ├── diag.zig      # Diagnostic types + rendering
│       ├── intern.zig    # String interner (Symbol table)
│       ├── c_import.zig  # C header parser + type mapping
│       └── test_harness.zig # Snapshot test runner
├── stdlib/
│   ├── std/
│   │   ├── io.w
│   │   ├── fs.w
│   │   ├── time.w
│   │   ├── collections/
│   │   │   ├── vec.w
│   │   │   ├── hashmap.w
│   │   │   └── ...
│   │   └── ...
│   └── os/
│       ├── posix/
│       └── windows/
├── runtime/
│   ├── fiber.zig         # Fiber context switching
│   ├── scheduler.zig     # M:N scheduler
│   ├── channel.zig       # Channel implementation
│   ├── stack_pool.zig    # Fiber stack management
│   └── compat.c          # Platform-specific C (ucontext shims)
├── tests/
│   ├── spec/             # §25 test suite (.w files)
│   ├── errors/           # Expected error tests
│   ├── snapshots/        # AST/MIR/codegen expected output
│   └── integration/      # Full program tests
├── tools/
│   ├── fmt.zig           # Formatter (with fmt)
│   ├── doc.zig           # Doc generator (with doc)
│   └── lsp.zig           # Language server
├── examples/             # Example With programs
└── docs/
    ├── spec.md           # Language specification
    ├── impl-notes.md     # Implementation notes
    └── tutorial/         # User-facing documentation
```

**Why Zig modules, not a workspace of packages:** Zig's build system
handles multi-file projects as a single compilation unit with explicit
module imports. Unlike Rust's workspace-of-crates model, Zig compiles
the entire compiler as one artifact. This is simpler, compiles faster,
and avoids package boundary overhead. Internal modularity comes from
file-level `pub` visibility, not package boundaries.

**Language mix:** The compiler and runtime are Zig. The standard
library and tools are With (using `c_import` for platform bindings).

---

## Part V — First Steps

Day-one checklist:

1. `mkdir with-compiler && cd with-compiler && zig init`
2. Set up `build.zig` with a `with-compiler` executable target
3. Define `Token` tagged union with spans in `src/lexer.zig`
4. Write lexer for: `fn`, `let`, `=`, `(`, `)`, `{`, `}`, `:`,
   `->`, identifiers, integer literals, string literals, `+`, `-`,
   `*`, `/`, `,`, `;`, newlines
5. Test: `zig build test` — lex `fn main() -> i32 = 42`
6. Write parser for: function definition, let binding, return,
   integer literal, function call, binary expression (`src/parser.zig`)
7. Write AST pretty-printer (use `std.io.Writer`)
8. Test: parse and pretty-print `fn main() -> i32 = 42`
9. Write LLVM backend (`src/codegen_llvm.zig`):
   - `LLVMModuleCreateWithName("main")`
   - `LLVMAddFunction` for `main` returning `i32`
   - `LLVMAppendBasicBlock`, `LLVMBuildRet(LLVMConstInt(i32, 42))`
   - `LLVMVerifyModule`
10. Emit object file via `LLVMTargetMachineEmitToFile`, link with `ld`
11. Run the binary. Exit code 42. **You have a compiler.**

Everything else is incremental from there.

### Bootstrap Plan: Zig → With

The compiler stays in Zig through v1.0. After With is feature-complete
and stable, the self-hosting transition proceeds:

1. **Post-v1.0:** Begin porting the compiler from Zig to With,
   module by module. Start with the simplest modules (intern, diag,
   AST types) where With's features (error types, pattern matching,
   `with` blocks) provide the clearest wins over Zig.

2. **Dual build:** Maintain both Zig and With versions in parallel
   during transition. The Zig version remains the reference — the
   With version must produce identical output for all test cases.

3. **Cutover:** When the With compiler passes the full test suite
   and can compile itself, the Zig version becomes the bootstrap-only
   build path (used only to build the first With compiler from
   scratch).

4. **Zig retained for runtime:** The fiber runtime (`runtime/`)
   may stay in Zig/C long-term — it requires platform-specific
   assembly and `ucontext` calls that benefit from Zig's low-level
   control. This is not a compromise; it's the right tool choice.
