# Porting the With Compiler from Zig to With — Self-Hosting Plan

**Prerequisite:** A working With compiler written in Zig (the "stage0"
compiler) that implements enough of the spec to compile itself.

---

## 0. Why Self-Host and Why Now

Self-hosting proves three things simultaneously:

1. **The language works.** A compiler is a real program — ASTs, hash
   maps, string processing, file I/O, error handling, complex control
   flow. If With can't build a compiler, it can't build anything.

2. **The ergonomics are real.** You'll feel every papercut. If
   something is annoying in 50,000 lines of compiler code, it'll be
   annoying for every user. This is the last chance to fix syntax
   and semantics before v1.0.

3. **The bootstrap chain is clean.** After self-hosting, With depends
   only on itself + a C compiler (for `c_import` and codegen). The
   Zig dependency disappears from the runtime story.

**Why now and not later:** Every day you spend adding features to the
Zig compiler is a day you'll have to re-implement in With. The
sooner you port, the less duplicate work. The Zig compiler is at
maximum value right now — it works, it's tested, and it's about to
become legacy.

---

## 1. The Bootstrap Chain

```
STAGE 0 (today):
    zig compiler source  →  Zig compiler  →  with-stage0 binary
    (what you have now)

STAGE 1 (the port):
    with compiler source  →  with-stage0  →  with-stage1 binary
    (With code, compiled by the Zig-built compiler)

STAGE 2 (self-hosted):
    with compiler source  →  with-stage1  →  with-stage2 binary
    (same With source, compiled by itself)

VERIFICATION:
    with compiler source  →  with-stage2  →  with-stage3 binary
    assert(stage2 binary == stage3 binary)  // fixpoint reached
```

Stage 2 = Stage 3 proves the compiler is a fixpoint — it produces
identical output when compiling itself. This is the gold standard.
Zig, Rust, Go, and every self-hosting compiler does this check.

**You keep the Zig compiler forever** as the bootstrap path. If
someone clones the repo fresh, they build stage0 from Zig, then
stage1 from stage0. This is how Go works (Go 1.4 in C bootstraps
all later versions).

---

## 2. Prerequisites — What Stage0 Must Support

Before you begin porting, the Zig compiler must handle the subset
of With that a compiler needs. Audit this list:

### 2.1 Must Have (blocking)

- [ ] Structs with methods (the entire AST is structs)
- [ ] Enums with data (AST node types, token types)
- [ ] Pattern matching on enums (the whole compiler is `match node`)
- [ ] Generics (at minimum `Vec[T]`, `HashMap[K, V]`, `Option[T]`, `Result[T, E]`)
- [ ] Closures (iterator chains, callbacks)
- [ ] Trait definitions and implementations (at minimum `Display`, `Debug`, `Eq`, `Hash`)
- [ ] String handling (`str`, `&str`, interpolation, slicing)
- [ ] `Vec` and `HashMap` (fully functional with iterators)
- [ ] File I/O (`std.fs.read_file`, `std.fs.write_file`, `std.io.print`)
- [ ] Error types and `?` propagation
- [ ] `with` blocks (at minimum binding form for builders)
- [ ] `for` loops over iterators and ranges
- [ ] `if let` and `let...else`
- [ ] Pipeline operator `|>`
- [ ] `defer`
- [ ] Implicit `Ok` wrapping
- [ ] String auto-promotion
- [ ] Auto-deref and auto-ref
- [ ] `@[derive(Eq, Hash, Debug, Clone)]`
- [ ] Module system with `use` imports
- [ ] Enum variant shorthand (`.Variant` without type prefix)
- [ ] Chained `if let`
- [ ] Default field values

### 2.2 Nice to Have (makes porting pleasant)

- [ ] Comptime (for compile-time tables, debug flags)
- [ ] Generators (for lazy tree traversal of AST)
- [ ] `@[derive(all)]`
- [ ] Pipeline with placeholder `|> map(_.name)`
- [ ] Comprehensions `[x for x in items if pred(x)]`

### 2.3 Not Needed for Self-Hosting

- Async / fibers / channels (compiler is synchronous)
- Fiber runtime
- `c_import` (compiler doesn't wrap C libraries)
- `unsafe` (compiler doesn't do pointer arithmetic)
- `@[no_await_guard]` (no async)
- `ScopedSend` / `Send` traits (single-threaded compiler)
- Ephemeral type checking (nice but compiler code won't hit edge cases)

### 2.4 The Audit Process

Write a test for every item in §2.1. If any test fails, fix the
Zig compiler first. Do NOT start porting until all §2.1 items
pass. You'll be debugging the Zig compiler and the With source
simultaneously otherwise, and that's hell.

```bash
# Run the prerequisite test suite
with test tests/selfhost-prereqs/
# ALL must pass before proceeding
```

---

## 3. Architecture of the Port

### 3.1 Module Map

A compiler has a natural dependency order. Port bottom-up — modules
with zero internal dependencies first, then modules that depend
only on already-ported modules.

```
LAYER 0 — Zero dependencies (pure data + utilities):
    src/util/arena.w          — Arena allocator
    src/util/string_pool.w    — Interned strings
    src/util/source.w         — Source location tracking (file, line, col)
    src/util/diagnostic.w     — Error/warning message types

LAYER 1 — Tokens and source:
    src/token.w               — Token type enum + TokenKind
    src/lexer.w               — Lexer (source text → tokens)
    src/span.w                — Source spans for error reporting

LAYER 2 — AST:
    src/ast.w                 — AST node types (big enum)
    src/ast_printer.w         — AST → string (for debugging)
    src/parser.w              — Tokens → AST

LAYER 3 — Semantic analysis:
    src/types.w               — Type representation
    src/scope.w               — Name resolution / symbol tables
    src/resolver.w            — Name resolution pass
    src/type_check.w          — Type checker + inference
    src/borrow_check.w        — Borrow checker (NLL)
    src/ephemeral_check.w     — Ephemeral type enforcement

LAYER 4 — Lowering and codegen:
    src/mir.w                 — Mid-level IR types
    src/lower.w               — AST → MIR lowering (desugar with, defer, etc.)
    src/codegen_c.w           — MIR → C code generation
    src/linker.w              — Invoke system linker

LAYER 5 — Driver:
    src/driver.w              — CLI argument parsing
    src/project.w             — with.toml parsing
    src/main.w                — Entry point, orchestration
```

### 3.2 Porting Strategy: One Module at a Time

You do NOT rewrite everything at once. You port one `.zig` file to
one `.w` file at a time, keeping the rest in Zig. This requires a
mixed-compilation strategy:

**Option A — Interface files (recommended):**

Port each module to With. The Zig compiler compiles the With module
to a `.c` file (since With's backend is C codegen). Compile the `.c`
file and link it with the remaining Zig-compiled modules.

This requires that the Zig compiler and the With modules agree on
data layout (`@[repr(C)]` on shared types). This is manageable if
you define shared types in a header-like module that both sides
read.

**Option B — Clean break (simpler but riskier):**

Port everything to With at once. You have the Zig source as
reference. You rewrite file-by-file in With, testing each file
against the test suite before moving to the next. The compiler
is either 100% Zig or 100% With, never mixed.

This is simpler (no mixed linking) but riskier (you can't test
incrementally until all files are ported).

**Option C — Parallel implementation (safest):**

Write the With version alongside the Zig version. Both compile.
Both produce output. Diff the output on every test case. When
they match on the full test suite, switch to the With version.

This is the most work but the safest. It's what Go did (Go 1.5
had both a C and Go compiler, compared output).

**Recommendation: Option B with a twist.** Port file by file, bottom
up. After each file, compile the complete With source with stage0
and run the full test suite. If any test fails, the bug is in the
file you just ported (since everything else was working before).

---

## 4. The Porting Order

Port files in dependency order. After each file, the full compiler
source is valid With, compilable by stage0, passing all tests.

### Wave 1: Utilities and Data Types (Week 1)

These modules are small, pure, and have no dependencies. They
establish patterns you'll reuse everywhere.

```
1. src/util/source.w         — SourceLoc, FileId
2. src/util/diagnostic.w     — Diagnostic, Severity, DiagnosticBag
3. src/util/string_pool.w    — StringPool, InternedString
4. src/util/arena.w          — Arena[T]
5. src/span.w                — Span, SpanRange
```

**Test after each file:** Unit tests for that module.
**Test after wave:** Full test suite (lexer, parser, everything
still works because these are leaf dependencies).

**Patterns to establish here:**

```with
// Establish your error pattern early
error CompilerError from
    LexError, ParseError, TypeError, BorrowError

// Establish your ID pattern early  
type FileId = distinct u32
type NodeId = distinct u32
type TypeId = distinct u32

// Establish your arena pattern early
type Arena[T] = {
    items: Vec[T],
}

extend Arena[T]
    fn alloc(self: &mut Self, item: T) -> Handle[T] =
        let id = self.items.len()
        self.items.push(item)
        Handle { id: id as u32 }

    fn get(self: &Self, handle: Handle[T]) -> &T =
        &self.items[handle.id as usize]
```

### Wave 2: Lexer (Week 1–2)

```
6. src/token.w               — TokenKind enum (50+ variants)
7. src/lexer.w               — Lexer struct + next_token()
```

The lexer is the ideal early port. It's self-contained (reads
source text, produces tokens), heavily uses pattern matching and
enums, and has an obvious test strategy (lex known input, compare
tokens).

**This is your first real test of With's ergonomics.** The Zig lexer
is probably a big `switch` statement. The With version should be
a `match`. Compare them. Which reads better?

```with
type TokenKind =
    // Literals
    | IntLit(i64)
    | FloatLit(f64)
    | StringLit(str)
    // Keywords
    | Fn | Let | Var | Mut | If | Else | Match | For | While
    | Return | Break | Continue | Type | Trait | Impl | Extend
    | Async | Await | Spawn | Select | With | As | In | Use
    | Comptime | Unsafe | Defer | Gen | Yield
    // Operators
    | Plus | Minus | Star | Slash | Percent
    | Eq | NotEq | Lt | Gt | LtEq | GtEq
    | And | Or | Not
    | Pipe | PipeRight | Arrow | FatArrow | Question
    | Dot | DotDot | DotDotEq | Colon | Semicolon | Comma
    // Delimiters
    | LParen | RParen | LBracket | RBracket | LBrace | RBrace
    // Special
    | Eof | Error(str)

@[derive(all)]
type Token = {
    kind: TokenKind,
    span: Span,
}
```

**Test:** Lex every file in your test suite with both the Zig
lexer and the With lexer. Token streams must be identical.

### Wave 3: AST and Parser (Week 2–3)

```
8. src/ast.w                 — AST node types (the big one)
9. src/parser.w              — Recursive descent parser
10. src/ast_printer.w        — AST pretty printer (for diffing)
```

The AST is the largest type definition in the compiler. In Zig
it's probably a tagged union or array of structs. In With, it's
a big enum:

```with
type Expr =
    | Literal(LitExpr)
    | Ident(str, Span)
    | Binary(op: BinOp, lhs: Box[Expr], rhs: Box[Expr])
    | Unary(op: UnaryOp, operand: Box[Expr])
    | Call(callee: Box[Expr], args: Vec[Expr])
    | FieldAccess(obj: Box[Expr], field: str)
    | Index(obj: Box[Expr], index: Box[Expr])
    | If(IfExpr)
    | Match(MatchExpr)
    | Block(Vec[Stmt])
    | Closure(ClosureExpr)
    | Pipeline(lhs: Box[Expr], rhs: Box[Expr])
    | With(WithExpr)
    | Async(Box[Expr])
    | Await(Box[Expr])
    | Return(Option[Box[Expr]])
    | Break(Option[Box[Expr]])
    | Continue
    | Assign(lhs: Box[Expr], rhs: Box[Expr])
    | Range(start: Option[Box[Expr]], end: Option[Box[Expr]], inclusive: bool)
    // ... etc
```

The parser is the most line-heavy module. Port it method by
method. Each parsing function (`parse_expr`, `parse_if`,
`parse_match`, etc.) is independent enough to test individually.

**Test strategy:** Parse every test file with both parsers. Pretty-
print both ASTs. Diff. Must be identical.

### Wave 4: Type System (Week 3–4)

```
11. src/types.w              — Type, TypeKind, type equality
12. src/scope.w              — Scope, SymbolTable, name lookup
13. src/resolver.w           — Name resolution pass
14. src/type_check.w         — Type inference + checking
```

This is the hardest wave. The type checker is where most compiler
complexity lives. Port it carefully.

**Key concern:** The type checker is where your language's
semantics get real. If there's a subtle difference between the
Zig implementation and the With implementation (e.g., inference
behavior, coercion rules), you'll get different compilation
results. Test exhaustively.

```with
type Type =
    | Void
    | Bool
    | Int(bits: u8, signed: bool)  // i8..i64, u8..u64
    | Float(bits: u8)              // f32, f64
    | Str                          // owned string
    | StrView                      // &str
    | Named(name: str, id: TypeId)
    | Generic(name: str, id: TypeId, args: Vec[Type])
    | Function(params: Vec[Type], ret: Box[Type])
    | Reference(inner: Box[Type], mutable: bool)
    | Option(inner: Box[Type])
    | Result(ok: Box[Type], err: Box[Type])
    | Tuple(elements: Vec[Type])
    | Array(element: Box[Type], size: usize)
    | Slice(element: Box[Type])
    | DynTrait(trait_id: TypeId)
    | Inferred(id: InferenceVar)
    | Error  // poison type for error recovery
```

**Test:** The type checker test suite is your most important asset.
Every test must produce identical diagnostics (same errors, same
warnings, same source locations).

### Wave 5: Analysis Passes (Week 4–5)

```
15. src/borrow_check.w       — NLL borrow checker
16. src/ephemeral_check.w    — Ephemeral type enforcement
```

The borrow checker is algorithmically complex but structurally
simple. It walks the MIR/AST, computes liveness, and checks for
conflicts. Port it as-is — don't try to improve it during the port.

### Wave 6: Lowering and Codegen (Week 5–6)

```
17. src/mir.w                — MIR types
18. src/lower.w              — AST → MIR (desugar with, defer, match, etc.)
19. src/codegen_c.w          — MIR → C source code
20. src/linker.w             — Invoke cc to compile generated C
```

The code generator is the most satisfying module to port because
it's where With generates C code — and now it'll be generating
the C code that compiles *itself*.

**Ironic moment:** Your With code will contain string literals of
C code. Your With compiler will emit C code. That C code will be
compiled by cc. The resulting binary will be a With compiler. The
snake eats its tail.

### Wave 7: Driver (Week 6)

```
21. src/project.w            — with.toml parsing
22. src/driver.w             — CLI arg parsing, file discovery
23. src/main.w               — Entry point
```

Last. These are glue code — not algorithmically interesting but
they tie everything together.

---

## 5. Testing Protocol

### 5.1 The Golden Test Suite

Before you start porting, capture the output of the Zig compiler on
every test file:

```bash
# Generate golden outputs from the Zig compiler
mkdir golden/
for test in tests/**/*.w; do
    with-stage0-zig compile $test > golden/$(basename $test).output 2>&1
    echo $? > golden/$(basename $test).exitcode
done
```

After every wave, run the With compiler (compiled by stage0) on
the same tests and diff:

```bash
# Compare With compiler output against golden
for test in tests/**/*.w; do
    with-stage0 compile $test > actual/$(basename $test).output 2>&1
    echo $? > actual/$(basename $test).exitcode
    diff golden/$(basename $test).output actual/$(basename $test).output
    diff golden/$(basename $test).exitcode actual/$(basename $test).exitcode
done
```

**Zero diffs = wave complete.** Any diff means a bug in the port.

### 5.2 The Self-Compilation Test

After all waves are complete:

```bash
# Stage 1: Zig-built compiler compiles With source
with-stage0-zig compile src/ -o with-stage1

# Stage 2: With-built compiler compiles With source
./with-stage1 compile src/ -o with-stage2

# Fixpoint check: stage2 compiles itself identically
./with-stage2 compile src/ -o with-stage3

diff with-stage2 with-stage3    # MUST be identical
```

If stage2 ≠ stage3, there's a nondeterminism bug (usually hash
map iteration order or pointer-based sorting). Fix it.

### 5.3 Performance Baseline

Before porting, measure the Zig compiler's performance:

```bash
# Time the Zig compiler on itself (or on the test suite)
time with-stage0-zig compile src/
# Record: wall time, peak RSS, binary size
```

After self-hosting, compare:

```bash
time ./with-stage1 compile src/
# Compare: wall time, peak RSS, binary size
```

The With compiler will likely be slower than the Zig compiler
(C codegen + cc invocation vs Zig's direct codegen). That's
expected and fine. If it's more than 3x slower, investigate.

---

## 6. Common Pitfalls

### 6.1 String Handling

Zig strings are `[]const u8` (byte slices). With strings are owned
`str` or borrowed `&str`. You'll be converting a lot of:

```zig
// Zig
const name = token.lexeme;  // []const u8, no allocation
```

to:

```with
// With — will this allocate?
let name = token.lexeme     // &str if borrowed, str if owned
```

**Decision:** Decide early whether AST nodes store owned `str` or
`&str` (with the source text as the backing store). Owned is
simpler (no lifetime concerns). Borrowed is faster (no allocation
for identifiers). The With spec's string auto-promotion makes owned
strings easy, but 50,000 identifier allocations add up.

**Recommendation:** Use a `StringPool` (interning table). All
identifiers go through the pool. AST nodes store `InternedString`
(a `distinct u32` index). Zero allocations per identifier after
the first occurrence. This is what every production compiler does.

### 6.2 Arena Allocation

The Zig compiler probably uses `std.mem.Allocator` or arena
allocation. With doesn't have custom allocators in v1.0 (the
stdlib uses the global allocator).

**Solution:** Write an `Arena[T]` as a `Vec[T]` with `Handle[T]`
indices. This is the With-idiomatic pattern. It's actually cleaner
than Zig's allocator-passing pattern.

```with
type AstArena = {
    exprs: Arena[Expr],
    stmts: Arena[Stmt],
    types: Arena[TypeNode],
    decls: Arena[Decl],
}

// Instead of Box[Expr], use Handle[Expr]
type BinaryExpr = {
    op: BinOp,
    lhs: Handle[Expr],    // index into arena
    rhs: Handle[Expr],
}
```

### 6.3 Error Recovery

Zig's error handling is `try`/`catch` with error unions. With's
is `Result[T, E]` with `?`. The translation is usually mechanical:

```zig
// Zig
const token = self.expect(.LParen) catch |err| {
    self.report(err);
    return error.ParseError;
};
```

```with
// With
let token = self.expect(.LParen)?
```

But watch for cases where Zig uses `catch` to do error recovery
(continue parsing after an error). In With, you'll need explicit
`match` or `let...else`:

```with
let token = match self.expect(.LParen)
    Ok(t)  -> t
    Err(e) ->
        self.report(e)
        self.synchronize()     // skip to next statement
        return self.parse_next_stmt()
```

### 6.4 Mutable State

Zig is explicit about mutability (`var` vs `const`). With is
similar (`var` vs `let`). But Zig allows mutating through pointers
freely, while With's borrow checker may reject some patterns.

**Common issue:** The Zig compiler probably mutates AST nodes after
construction (e.g., filling in type information during type checking).
In With, you'll need `&mut` access to the nodes, which means the
borrow checker will enforce non-aliasing.

**Solution:** Use the arena pattern. Store AST nodes in arenas,
reference them by handle. Mutation goes through `arena.get_mut(handle)`.
The borrow checker is happy because you borrow the arena, not
individual nodes.

### 6.5 Hash Map Iteration Order

If the Zig compiler iterates over hash maps and the order affects
output (e.g., order of error messages, order of generated code),
you'll get diff failures even if the logic is correct.

**Solution:** Sort hash map outputs deterministically when order
matters (e.g., sort diagnostics by source location before printing).

### 6.6 Do Not Improve While Porting

This is the hardest discipline. You will see ugly Zig code and
think "I should restructure this in With." Don't. Port it
faithfully first. Get the fixpoint. Then improve.

Every "improvement" during porting is a potential bug that you
can't diff against the Zig output. Improvements come AFTER
self-hosting is verified.

---

## 7. After Self-Hosting

### 7.1 Delete the Zig Source?

**No.** Keep it in the repo under `bootstrap/`. Anyone who wants to
build from source needs a path from zero: install Zig, build
stage0 from the Zig source, then build the real compiler from With
source using stage0. This is the bootstrap chain. It must always
work.

Alternatively, check in a pre-built stage0 binary (like Go does
with its bootstrap toolchain). This removes the Zig dependency
for casual users but keeps the Zig source for auditability.

### 7.2 First Improvements After Self-Hosting

Now that the compiler is in With, improvements are self-reinforcing.
Every improvement to the compiler makes it nicer to work on the
compiler.

Priority improvements:

1. **Better error messages.** Now you can use With's string
   interpolation, pattern matching, and `Display` trait to produce
   beautiful diagnostics.

2. **Parallel compilation.** Add fiber-based parallelism to the
   module compilation pipeline. This is impossible in the Zig
   version (different concurrency model) but natural in With.

3. **Incremental compilation.** Now that the compiler is in With,
   you can use the module system to cache and invalidate
   compilation units properly.

4. **LSP server.** Write it in With, using the same parser and
   type checker. It's the same code. In Zig, you'd have to
   maintain two implementations or do awkward FFI.

### 7.3 The Blog Post

Self-hosting is a major milestone. Write about it. The narrative:

> "We built a programming language. Then we used it to rebuild
> its own compiler. Here's the Zig version (X lines) and the
> With version (Y lines). Here's what we learned. Here's what
> hurt. Here's what we changed. The With version is Z% shorter
> and we think it's more readable — but judge for yourself."

Show both versions side-by-side. Let people compare. That's the
pitch for the language.

---

## 8. Timeline Estimate

| Week | Work | Deliverable |
|------|------|-------------|
| 0 | Audit stage0, fill gaps, build golden test suite | All §2.1 prereqs pass |
| 1 | Wave 1 (utilities) + Wave 2 (lexer) | Lexer in With, tests pass |
| 2 | Wave 3 (AST + parser) | Parser in With, tests pass |
| 3 | Wave 4 (types, resolver, type checker) — part 1 | Resolver + type representation ported |
| 4 | Wave 4 (type checker) — part 2 | Type checker in With, tests pass |
| 5 | Wave 5 (borrow checker, ephemeral checker) | Analysis passes in With |
| 6 | Wave 6 (MIR, lowering, codegen) | Code generation in With |
| 7 | Wave 7 (driver, main) + integration | Full compiler in With |
| 8 | Fixpoint testing, bug fixes, nondeterminism | stage2 == stage3 |

**8 weeks is aggressive but realistic** if:
- The Zig compiler is stable and well-tested
- You're porting, not redesigning
- You resist the urge to improve while porting

If you're also fixing compiler bugs discovered during porting
(likely), add 2–4 weeks. Realistic total: 10–12 weeks.

---

## 9. Decision Checklist

Before starting, decide and document:

- [ ] **AST storage:** Arena + handles or Box[Expr]?
- [ ] **String storage:** Interned pool or owned str?
- [ ] **Error recovery:** Panic mode + synchronize, or continue parsing?
- [ ] **Test strategy:** Golden diff, or per-module unit tests, or both?
- [ ] **Mixed compilation:** Option A (interop), B (clean break), or C (parallel)?
- [ ] **Binary distribution:** Ship stage0 binary, or require Zig to bootstrap?
- [ ] **Diagnostic ordering:** Sort by source location, or preserve emission order?
- [ ] **C codegen output:** Match Zig output exactly, or accept semantic equivalence?

For that last point: if you require byte-identical C output, your
fixpoint test is a simple `diff`. If you accept semantic equivalence,
you need to compile both outputs and compare binary behavior on the
test suite. Start with byte-identical — it's easier to debug.

---

*Self-hosting is the point where the language stops being a project
and starts being a tool. After this, every line of code you write
for the compiler is a line of With that proves the language works.
Every bug you fix makes the language better. Every feature you add
is immediately available to the compiler itself. The flywheel starts
spinning.*

Triple-Test: when you compile the sources with the bootstrap compiler to create stage0, then compile the sources with the stage0 compiler to create stage1, then compile again with stage1 to create stage2 and verify it is at a fixpoint (stage1 output == stage2 output). There's a lot of stuff that can get past stage0 -> stage1, but trips up on stage1 -> stage2.