# Self-Hosting the With Compiler — Detailed Execution Plan

**Status:** In progress — Wave 1 (foundational stubs)
**Scope:** Translate the With compiler from Zig (bootstrap) to With, drawing architecture from the Zig and Rust reference compilers.

---

## Table of Contents

1. [Strategy & Principles](#1-strategy--principles)
2. [Architecture Overview](#2-architecture-overview)
3. [Compilation Pipeline](#3-compilation-pipeline)
4. [Module Layout](#4-module-layout)
5. [Data Structures](#5-data-structures)
6. [Wave 0 — Determinism & Golden Baseline](#6-wave-0--determinism--golden-baseline)
7. [Wave 1 — Foundational Utilities](#7-wave-1--foundational-utilities)
8. [Wave 2 — Token & Lexer](#8-wave-2--token--lexer)
9. [Wave 3 — AST & Parser](#9-wave-3--ast--parser)
10. [Wave 4 — Intern Pool & Type Representation](#10-wave-4--intern-pool--type-representation)
11. [Wave 5 — Semantic Analysis](#11-wave-5--semantic-analysis)
12. [Wave 6 — MIR & Lowering](#12-wave-6--mir--lowering)
13. [Wave 7 — Borrow Checker](#13-wave-7--borrow-checker)
14. [Wave 8 — LLVM Codegen](#14-wave-8--llvm-codegen)
15. [Wave 9 — Driver & CLI](#15-wave-9--driver--cli)
16. [Wave 10 — Stdlib & Runtime](#16-wave-10--stdlib--runtime)
17. [Wave 11 — Bootstrap Chain & Fixpoint](#17-wave-11--bootstrap-chain--fixpoint)
18. [Testing Strategy](#18-testing-strategy)
19. [Risk Register](#19-risk-register)

---

## 1. Strategy & Principles

### What we are building

A self-hosted With compiler written in With, compiled by the bootstrap Zig compiler (stage0). The self-hosted compiler must implement the full With language as defined in `docs/with-specification.md` and as implemented by the bootstrap at `bootstrap/`.

### What we are NOT doing

- We are **not** line-for-line porting the bootstrap compiler. The bootstrap is ~35,600 lines of inelegant Zig. It works, but its architecture is ad-hoc.
- We are **not** redesigning the language semantics. The spec is the spec.

### Where the architecture comes from

| Concern | Primary Reference | Secondary Reference |
|---------|-------------------|---------------------|
| Interning & type representation | Zig `InternPool.zig` | Rust `rustc_data_structures/intern.rs` |
| IR design (SoA, MultiArrayList) | Zig `Air.zig` | — |
| Semantic analysis structure | Zig `Sema.zig` | Rust `rustc_hir_typeck/` |
| MIR (mid-level IR) | Rust `rustc_middle/mir/` | — |
| Compilation orchestration | Zig `Compilation.zig`, `Zcu.zig` | Rust `rustc_interface/passes.rs` |
| Type system wrapper pattern | Zig `Type.zig`, `Value.zig` | Rust `rustc_middle/ty/context.rs` |
| Diagnostic architecture | Rust `rustc_errors/` | Bootstrap `Diagnostic.zig` |
| Borrow checking (on MIR) | Rust `rustc_borrowck/` | Bootstrap `Sema.zig` (NLL section) |
| Token & lexer | Bootstrap `Token.zig`, `Lexer.zig` | Rust `rustc_lexer/` |
| AST design | Bootstrap `Ast.zig` | Rust `rustc_ast/ast.rs` |
| Parser | Bootstrap `Parser.zig` | Rust `rustc_parse/parser/` |
| Trait resolution | Rust `rustc_trait_selection/` | Bootstrap `Sema.zig` |

### Ground rules

1. **Semantic fidelity first.** Every test case that passes under stage0 must pass under stage1. No exceptions.
2. **Do it right the first time.** If a component has a known-correct architecture (MIR for borrow checking, intern pool for types, query cache for incremental builds), build it that way from the start. Don't ship a shortcut and rewrite later.
3. **Incremental validation.** Each wave produces a working (partial) compiler that can be diffed against golden baselines.
4. **Self-contained modules.** Each module should be independently testable with `with test`.
5. **Use the language.** The self-hosted compiler is the flagship With program. It should demonstrate idiomatic With: traits, generics, match, `with` blocks, `|>`, `?`, `??`.

---

## 2. Architecture Overview

### High-Level Design

The self-hosted compiler follows a **seven-phase pipeline**, drawing from Zig's clean separation while incorporating Rust's MIR for proper borrow checking and lowering:

```
Source (.w file)
    │
    ▼
┌─────────────┐
│   Lexer     │  source text → Token list
└─────────────┘
    │
    ▼
┌─────────────┐
│   Parser    │  tokens → AST (untyped)
└─────────────┘
    │
    ▼
┌─────────────┐
│   Sema      │  AST → typed AST
└─────────────┘  (name resolution, type checking, trait resolution)
    │
    ▼
┌─────────────┐
│   MIR       │  typed AST → control flow graph
└─────────────┘  (desugaring, drop insertion, borrow checking)
    │
    ▼
┌─────────────┐
│   Codegen   │  MIR → LLVM IR
└─────────────┘
    │
    ▼
┌─────────────┐
│   Driver    │  orchestration, linking, CLI
└─────────────┘
    │
    ▼
  Binary
```

### Key Architectural Decisions

**Decision 1: MIR from day one.**
The bootstrap goes directly from AST to LLVM IR. This works but forces the borrow checker to operate on tree-structured AST, which is awkward for control flow analysis. The self-hosted compiler introduces MIR (mid-level IR) — a CFG-based representation where all sugar is desugared, all drops are explicit, and borrow checking operates on a flat graph of basic blocks. This follows Rust's `rustc_middle/mir/` and is the architecture we'd end up with eventually. Build it right the first time.

**Decision 2: Intern everything from the start.**
Following Zig's `InternPool.zig` and Rust's `CtxtInterners`, all strings, types, and constant values are interned from Wave 1. The bootstrap only interns strings and tacks on type interning later. We do both from the start. TypeId is a `distinct u32` into the intern pool. Comparison is integer equality. No gradual migration.

**Decision 3: Trait resolution with selection cache.**
The bootstrap's trait resolution is ad-hoc (inline in Sema). The self-hosted compiler builds a proper trait solver from the start, following Rust's `rustc_trait_selection/`. Obligations are collected during type checking, resolved via a selection cache (avoid re-resolving the same `T: Display` bound repeatedly), with coherence checking (orphan rules) as a separate pass. With has no HKTs, no GATs, no specialization — so the solver is simpler than Rust's, but it's still built correctly from day one.

**Decision 4: Diagnostics with error codes and machine-applicable suggestions.**
The bootstrap emits simple error strings. The self-hosted compiler builds rustc-quality diagnostics from the start: primary span, secondary labels, stable error codes (`E0001`–`E9999`), and machine-applicable suggestions that `with fix` can apply automatically. The diagnostic renderer is separate from the emitter. This follows Rust's `rustc_errors/`.

**Decision 5: Wrapper types for Type and Value.**
Following Zig's `Type.zig` and `Value.zig` (thin wrappers around `InternPool.Index`), our Type and Value types are `distinct u32` handles into the intern pool. Methods on Type/Value delegate to the pool for actual data. 4 bytes, trivial comparison.

**Decision 6: Arena allocation.**
Following both Zig (`Sema.zig` uses arena allocator) and Rust (arena-based `TyCtxt`), all compilation artifacts are allocated in a single arena per compilation unit. Freed in bulk at the end.

**Decision 7: Two-pass semantic analysis.**
Following the bootstrap (`Sema.zig` collectDeclarations → checkBodies) and Rust (`rustc_hir_analysis/collect` → `rustc_hir_typeck`), sema runs two passes: first collecting all type and function signatures, then checking function bodies. This enables forward references without requiring a topological sort.

**Decision 8: LLVM-C FFI via c_import.**
The bootstrap uses LLVM-C bindings directly (`Codegen.zig` calls `LLVMBuildAdd`, `LLVMBuildAlloca`, etc.). The self-hosted compiler does the same via `use c_import("llvm-c/Core.h", link: "LLVM")`.

---

## 3. Compilation Pipeline

### Detailed Phase Flow

```
┌──────────────────────────────────────────────────────────────┐
│ Phase 0: File Loading (Source)                               │
│   • Read .w file into memory                                 │
│   • Compute line offset table for diagnostics                │
│   • Assign FileId                                            │
│   Ref: bootstrap/Source.zig:fromFile()                       │
│   Ref: .reference/rust/compiler/rustc_span/src/lib.rs        │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 1: Lexical Analysis (Lexer)                            │
│   • Hand-written scanner, character-by-character             │
│   • Produces parallel arrays: tags[] + spans[]               │
│   • Handles string interpolation (start/fragment/end)        │
│   • Keyword detection via lookup table                       │
│   Ref: bootstrap/Lexer.zig                                   │
│   Ref: .reference/rust/compiler/rustc_lexer/src/lib.rs       │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 2: Parsing (Parser)                                    │
│   • Recursive descent with Pratt precedence climbing         │
│   • Produces Ast.Module (array of Decl nodes)                │
│   • Error recovery: skip to next top-level on error          │
│   • Handles all syntax: fn, type, match, with, closures      │
│   Ref: bootstrap/Parser.zig                                  │
│   Ref: .reference/rust/compiler/rustc_parse/src/parser/      │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 2.5: Import Processing                                 │
│   • Resolve `use path.to.module` → load .w files             │
│   • Resolve `use c_import(...)` → call libclang → extern fns │
│   • Merge imported declarations into module                  │
│   • Cycle detection via imported_paths set                   │
│   Ref: bootstrap/Driver.zig:processImports()                 │
│   Ref: bootstrap/CImport.zig                                 │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 3: Semantic Analysis (Sema)                            │
│   Pass 1: collectDeclarations                                │
│     • Register all type names, struct fields, fn signatures  │
│     • Build type table: Symbol → TypeId                      │
│     • Detect generic functions, trait declarations           │
│     • Check coherence (orphan rules)                         │
│   Pass 2: checkBodies                                        │
│     • Type-check all function bodies                         │
│     • Infer expression types (bidirectional)                 │
│     • Collect trait obligations, resolve via selection cache  │
│     • Move tracking: VarState (live/moved)                   │
│     • Built-in function validation                           │
│   Ref: bootstrap/Sema.zig                                    │
│   Ref: .reference/zig/src/Sema.zig                           │
│   Ref: .reference/rust/compiler/rustc_hir_typeck/            │
│   Ref: .reference/rust/compiler/rustc_trait_selection/        │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 4: MIR Lowering                                        │
│   • Lower typed AST to control flow graph (basic blocks)     │
│   • Desugar: with, match, closures, gen, async, select,      │
│     defer, optional chaining, ??, |>, record update          │
│   • Insert explicit drop calls at scope exits                │
│   • All implicit transformations become explicit              │
│   Ref: .reference/rust/compiler/rustc_mir_build/              │
│   Ref: .reference/rust/compiler/rustc_middle/src/mir/mod.rs  │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 4.5: Borrow Checking (on MIR)                          │
│   • NLL computation on CFG                                   │
│   • Aliasing rule enforcement                                │
│   • Ephemeral propagation                                    │
│   • Second-class reference enforcement                       │
│   • Drop-as-use rule                                         │
│   Ref: .reference/rust/compiler/rustc_borrowck/              │
│   Ref: bootstrap/Sema.zig (NLL section), BorrowCfg.zig      │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 5: Code Generation (Codegen)                           │
│   • Walk MIR basic blocks, emit LLVM IR via LLVM-C           │
│   • Alloca + mem2reg strategy for locals                     │
│   • Monomorphization of generic functions                    │
│   • Enum layout: tag + payload union                         │
│   • Closure lowering already done in MIR                     │
│   • Vtable generation for dyn Trait                          │
│   Ref: bootstrap/Codegen.zig                                 │
│   Ref: .reference/zig/src/codegen/llvm.zig                   │
│   Ref: .reference/rust/compiler/rustc_codegen_llvm/          │
└──────────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Phase 6: Linking                                             │
│   • Invoke system linker (clang/ld)                          │
│   • Link runtime components (fiber.c, helpers.c)             │
│   • Link LLVM libraries (for self-hosted compiler)           │
│   • Link c_import-requested libraries                        │
│   Ref: bootstrap/Driver.zig:link()                           │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. Module Layout

### Design Rationale

Following the Zig reference compiler's layout (``.reference/zig/src/``): **flat ``src/`` with PascalCase for struct modules, snake_case for utilities.** Zig uses subdirectories only for architectural variants (multiple codegen backends, multiple linker formats) — not for conceptual grouping. Since With has one codegen backend (LLVM) and one linker strategy (delegate to system linker), all ~19 modules sit flat in ``src/``.

Data structures (``HashMap``, ``Vec``, ``Arena``) come from ``lib/std/``, not a ``src/util/`` directory — same as Zig's compiler using ``std.ArrayList``, ``std.HashMap``, etc.

### Project Structure

```
src/
├── main.w              — CLI entry point, command dispatch
├── Span.w              — Span (file, start, end), FileId
├── Source.w            — Source file loading, line offset table
├── Diag.w              — Diagnostic, Severity, Label, Suggestion
├── InternPool.w        — InternPool: strings, types, and values
├── Token.w             — Token.Tag enum, Token struct
├── Lexer.w             — Hand-written lexer → Token list
├── Ast.w               — AST node types (Decl, Expr, TypeExpr, Pattern)
├── Parser.w            — Recursive descent parser → Ast.Module
├── Type.w              — TypeId, TypeKind, type representation
├── Traits.w            — Trait solver, selection cache, coherence
├── Sema.w              — Semantic analysis (two-pass)
├── Mir.w               — MIR types: BasicBlock, Statement, Terminator, Place
├── MirBuild.w          — Typed AST → MIR lowering + desugaring
├── Borrow.w            — Borrow checker (NLL on MIR CFG)
├── Codegen.w           — MIR → LLVM IR code generation
├── CImport.w           — libclang FFI for c_import
├── Driver.w            — Pipeline orchestrator
└── render.w            — AST/MIR pretty-printer (debug, snake_case = utility)
```

Unit tests live alongside integration tests in ``test/``:
```
test/
├── cases/              — Compiler integration tests (.w with //! directives)
├── behavior/           — (future) Runtime behavior tests
└── golden/             — (future) Golden baseline snapshots
```

### Module Dependency Graph

```
main.w
  └─► Driver.w
        ├─► Source.w ──► Span.w
        ├─► Lexer.w ──► Token.w ──► InternPool.w
        │                            └──► Span.w
        ├─► Parser.w ──► Ast.w ──► InternPool.w
        │                          └──► Span.w
        ├─► CImport.w ──► Ast.w
        ├─► Sema.w ──► Ast.w
        │             ├─► Type.w ──► InternPool.w
        │             ├─► Traits.w ──► Type.w
        │             └─► Diag.w
        ├─► MirBuild.w ──► Mir.w
        │                  ├─► Ast.w
        │                  └─► Type.w
        ├─► Borrow.w ──► Mir.w
        │               └─► Diag.w
        ├─► Codegen.w ──► Mir.w
        │                ├─► Type.w
        │                └─► InternPool.w
        └─► Diag.w ──► Span.w
                        └──► Source.w
```

---

## 5. Data Structures

### 5.1 Span & Source

```
// Ref: bootstrap/Span.zig
type FileId = distinct u32

type Span = {
    file: FileId,
    start: u32,
    end: u32,
}
```

```
// Ref: bootstrap/Source.zig
type Source = {
    name: str,
    text: str,
    line_offsets: Vec[u32],
    file_id: FileId,
}
```

### 5.2 InternPool (Strings + Types + Values)

Following Zig's extended intern pool pattern — intern everything from the start, not just strings.

```
// Ref: .reference/zig/src/InternPool.zig (strings + types + values in one pool)
// Ref: .reference/rust/compiler/rustc_middle/src/ty/context.rs (CtxtInterners)
// Ref: bootstrap/InternPool.zig (string-only — we extend this)

type Symbol = distinct u32     // interned string handle
type TypeId = distinct u32     // interned type handle
type ValueId = distinct u32    // interned constant value handle

type InternPool = {
    // String interning
    bytes: Vec[u8],
    string_offsets: Vec[u32],
    string_map: HashMap[str, Symbol],

    // Type interning
    type_kinds: Vec[TypeKind],
    type_map: HashMap[TypeKind, TypeId],

    // Value interning (compile-time constants)
    values: Vec[ValueKind],
    value_map: HashMap[ValueKind, ValueId],

    // Pre-registered builtin types at fixed indices:
    // 0 = error, 1 = unit, 2 = bool, 3 = i8, 4 = i16, 5 = i32, 6 = i64,
    // 7 = u8, 8 = u16, 9 = u32, 10 = u64, 11 = f32, 12 = f64, 13 = str,
    // 14 = never
}
```

### 5.3 Token

```
// Ref: bootstrap/Token.zig (342 lines, 141 Tag variants)

type Tag = int_literal | float_literal | string_literal | c_string_literal
         | string_start | string_end | string_fragment | char_literal
         | true_literal | false_literal
         | identifier | dot_identifier | label
         // ... all 42 keywords (kw_fn, kw_let, kw_var, ...)
         // ... all operators (plus, minus, star, ...)
         // ... delimiters, punctuation, structural tokens
         | eof | invalid

type Token = { tag: Tag, span: Span }

// Parallel arrays for cache efficiency (Zig SoA pattern)
type TokenList = {
    tags: Vec[Tag],
    spans: Vec[Span],
}
```

### 5.4 AST

Mirrors the bootstrap's `Ast.zig` exactly — same variants, same fields.

**Top-level:**
```
type Module = { decls: Vec[Decl], span: Span }
```

**Declarations** (9 variants):
```
type DeclKind =
    Function(FnDecl)
  | TypeDecl(TypeDeclData)
  | UseDecl(UseDeclData)
  | LetDecl(LetDeclData)
  | ExternFn(ExternFnDecl)
  | CImport(CImportDecl)
  | TraitDecl(TraitDeclData)
  | ImplDecl(ImplDeclData)
  | Poisoned
```

**Expressions** (51 variants — full list from bootstrap):
```
type ExprKind =
    IntLiteral(i64) | FloatLiteral(f64) | StringLiteral(Symbol)
  | CStringLiteral(Symbol) | BoolLiteral(bool)
  | Ident(Symbol) | Binary(BinaryExpr) | Unary(UnaryExpr)
  | Call(CallExpr) | FieldAccess(FieldAccessExpr)
  | OptionalChain(OptionalChainExpr) | Index(IndexExpr)
  | Slice(SliceExpr) | Block(BlockExpr) | IfExpr(IfExprData)
  | ReturnExpr(?Expr) | LetBinding(LetBindingData)
  | LetElse(LetElseData) | TupleDestructure(TupleDestructureData)
  | Assign(AssignExpr) | Tuple(Vec[Expr])
  | Range(RangeExpr) | VariantShorthand(VariantShorthandExpr)
  | AwaitExpr(Expr) | AsyncBlock(Expr) | SpawnExpr(Expr)
  | Pipeline(PipelineExpr) | Grouped(Expr)
  | WhileExpr(WhileExprData) | LoopExpr(LoopExprData)
  | ForExpr(ForExprData) | BreakExpr(BreakExprData)
  | ContinueExpr(ContinueExprData)
  | ArrayLiteral(Vec[Expr]) | ArrayComprehension(ComprehensionData)
  | StructLiteral(StructLiteralData) | MatchExpr(MatchExprData)
  | EnumVariant(EnumVariantExpr) | Closure(ClosureExpr)
  | Cast(CastExpr) | DeferExpr(Expr)
  | WithExpr(WithExprData) | RecordUpdate(RecordUpdateData)
  | YieldExpr(Expr) | ComptimeExpr(Expr)
  | AsyncScope(AsyncScopeExpr) | SelectAwait(SelectAwaitExpr)
  | Poisoned
```

**Binary operators** (23 variants):
```
type BinOp = Add | Sub | Mul | Div | Mod
           | Eq | Neq | Lt | Gt | Lte | Gte
           | And | Or
           | BitAnd | BitOr | BitXor | Shl | Shr
           | AddWrap | SubWrap | MulWrap
           | DefaultOp | Concat
```

**Unary operators** (6 variants):
```
type UnaryOp = Negate | Not | RefOf | MutRefOf | Deref | TryOp
```

**Type expressions** (11 variants):
```
type TypeExprKind =
    Named(Symbol) | Generic(GenericTypeExpr)
  | RefType(RefTypeExpr) | PtrType(PtrTypeExpr)
  | FnType(FnTypeExpr) | TupleType(Vec[TypeExpr])
  | Optional(TypeExpr) | ArrayType(ArrayTypeExpr)
  | SliceType(TypeExpr) | TraitObject(Symbol)
  | Inferred
```

**Patterns** (12 variants):
```
type PatternKind =
    Wildcard | Binding(Symbol) | IntLiteral(i64) | BoolLiteral(bool)
  | StringLiteral(Symbol) | Variant(VariantPattern)
  | OrPattern(Vec[Pattern]) | AtBinding(AtBindingData)
  | TuplePattern(Vec[Pattern]) | RangePattern(RangePatternData)
  | SlicePattern(SlicePatternData) | StructPattern(StructPatternData)
```

### 5.5 Type Representation

```
// Ref: .reference/zig/src/Type.zig (wrapper around InternPool.Index)
// Ref: .reference/rust/compiler/rustc_middle/src/ty/context.rs

type TypeKind =
    Err                             // error recovery sentinel
  | Int(IntType)                    // i8/i16/i32/i64, u8/u16/u32/u64
  | Float(FloatType)                // f32, f64
  | Bool
  | Unit                            // zero-sized unit type
  | Never                           // diverging (!, Never)
  | Str                             // {ptr: *u8, len: i64}
  | Struct(StructType)              // user-defined struct
  | Enum(EnumType)                  // user-defined enum
  | Array(ArrayType)                // [N]T
  | Slice(SliceType)                // []T
  | Tuple(TupleType)                // (T1, T2, ...)
  | Fn(FnType)                      // fn(params) -> ret
  | Ptr(PtrType)                    // *const T, *mut T
  | Ref(RefType)                    // &T, &mut T
  | Alias(TypeId)                   // type alias
  | GenericParam(Symbol)            // generic type parameter placeholder
  | TraitObject(TraitObjectType)    // dyn Trait
  | Option(TypeId)                  // Option[T]
  | Result(TypeId, TypeId)          // Result[T, E]
```

### 5.6 MIR (Mid-Level IR)

The key data structure that the bootstrap lacks. A CFG of basic blocks with explicit control flow, desugared syntax, and explicit drop calls. This is what the borrow checker and codegen operate on.

```
// Ref: .reference/rust/compiler/rustc_middle/src/mir/mod.rs

type MirBody = {
    basic_blocks: Vec[BasicBlock],
    locals: Vec[LocalDecl],         // all locals (params + temps + user vars)
    arg_count: u32,                 // first arg_count locals are parameters
    return_local: LocalId,          // local 0 is always the return place
    span: Span,
}

type LocalId = distinct u32

type LocalDecl = {
    name: ?Symbol,                  // None for temporaries
    ty: TypeId,
    mutable: bool,
    span: Span,
}

type BasicBlockId = distinct u32

type BasicBlock = {
    statements: Vec[Statement],
    terminator: Terminator,
}
```

**Places** — Where data lives. Inspired by Rust MIR's `Place`:
```
// A Place is a location that can be read from or written to.
// _1           → local variable
// _1.field     → field projection
// _1[idx]      → index projection
// *_1          → deref projection

type Place = {
    local: LocalId,
    projections: Vec[Projection],
}

type Projection =
    Field(u32)            // struct field by index
  | Index(LocalId)        // array/slice index
  | Deref                 // pointer/reference deref
  | Downcast(u32)         // enum variant payload access
```

**Statements** — Non-branching operations:
```
type Statement =
    Assign(Place, Rvalue)          // place = rvalue
  | Drop(Place)                    // explicit drop call
  | Nop                            // no-op (for padding/debugging)
```

**Rvalues** — Computations that produce a value:
```
type Rvalue =
    Use(Operand)                           // copy or move
  | Ref(BorrowKind, Place)                 // &place or &mut place
  | BinaryOp(BinOp, Operand, Operand)     // a + b
  | UnaryOp(UnaryOp, Operand)             // -a, !a
  | Call(Operand, Vec[Operand])            // fn(args)
  | Aggregate(AggregateKind, Vec[Operand]) // struct/enum/tuple/array literal
  | Cast(CastKind, Operand, TypeId)        // type cast
  | Discriminant(Place)                    // read enum tag
```

**Operands** — Inputs to rvalues:
```
type Operand =
    Copy(Place)           // copy (for Copy types)
  | Move(Place)           // move (for non-Copy types)
  | Constant(ValueId)     // compile-time constant
```

**Terminators** — End of a basic block, always branches:
```
type Terminator =
    Goto(BasicBlockId)
  | SwitchInt(Operand, Vec[(i64, BasicBlockId)], BasicBlockId)  // match on int, with default
  | Return
  | Unreachable
  | Call(Operand, Vec[Operand], Place, BasicBlockId, ?BasicBlockId)  // fn, args, dest, success_bb, unwind_bb
  | Drop(Place, BasicBlockId, ?BasicBlockId)  // drop, success_bb, unwind_bb
  | Assert(Operand, bool, BasicBlockId)       // condition, expected, target
```

### 5.7 Diagnostic

```
// Ref: .reference/rust/compiler/rustc_errors/src/lib.rs
// Extended from bootstrap with error codes and machine-applicable suggestions

type Severity = Error | Warning | Help | Note

type Label = { span: Span, message: str }

type Applicability = MachineApplicable | MaybeIncorrect | HasPlaceholders

type Suggestion = {
    message: str,
    replacements: Vec[(Span, str)],
    applicability: Applicability,
}

type Diagnostic = {
    severity: Severity,
    message: str,
    code: ?str,                 // E0382, W0015, etc.
    primary: Span,
    labels: Vec[Label],
    notes: Vec[str],
    helps: Vec[str],
    suggestions: Vec[Suggestion],
}
```

### 5.8 Trait Resolution

```
// Ref: .reference/rust/compiler/rustc_trait_selection/

type TraitObligation = {
    trait_id: Symbol,
    self_type: TypeId,
    span: Span,
}

type SelectionCache = HashMap[(Symbol, TypeId), ImplId]

type ImplId = distinct u32

type TraitSolver = {
    cache: SelectionCache,
    impls: Vec[ImplInfo],               // all known impl blocks
    trait_defs: HashMap[Symbol, TraitDef],
}
```

---

## 6. Wave 0 — Determinism & Golden Baseline

### 6.0.1 Determinism Audit (Bootstrap)

Before writing any self-hosted code, audit the bootstrap for nondeterminism:

- [ ] **Hash map iteration order.** The bootstrap uses Zig's `StringHashMapUnmanaged` in InternPool and various lookup tables in Sema/Codegen. Zig hash maps do not guarantee iteration order. Any code that iterates a hash map and emits output (diagnostics, LLVM IR, symbol tables) must sort first.
  - Ref: `bootstrap/Codegen.zig` — `fn_table`, `type_table`, `mono_cache`
  - Ref: `bootstrap/Sema.zig` — `type_table`, `fn_table`, `scope_stack`

- [ ] **File discovery order.** `Driver.processImports()` discovers `.w` files. The order must be sorted by path.
  - Ref: `bootstrap/Driver.zig:processImports()`

- [ ] **LLVM IR emission order.** Functions and globals must be emitted in a deterministic order.
  - Ref: `bootstrap/Codegen.zig:genModule()`

- [ ] **Diagnostic sort.** Diagnostics should be sorted by file → line → column before output.
  - Ref: `bootstrap/Diagnostic.zig:renderAll()`

### 6.0.2 Dump Flags

Add to the bootstrap compiler:

```
with build --dump-tokens file.w    # Lex and dump token list
with build --dump-ast file.w       # Parse and dump AST
with build --dump-typed file.w     # Sema and dump typed info
with build --dump-mir file.w       # MIR and dump basic blocks
with build --dump-llvm file.w      # Codegen and dump LLVM IR
```

These must produce deterministic, diffable output.

Note: `--dump-mir` won't have a golden baseline from the bootstrap (which has no MIR). The MIR golden baseline is established by the self-hosted compiler's own output once Wave 6 is stable. The invariant is: MIR → LLVM IR produces the same LLVM IR as the bootstrap's direct AST → LLVM IR path.

### 6.0.3 Golden Baseline Capture

For every test in `test/cases/`:

```
for test in test/cases/*.w:
    capture exit_code
    capture stdout
    capture stderr (diagnostics)
    capture --dump-tokens output
    capture --dump-ast output
    capture --dump-llvm output (normalized)
```

Store in `test/golden/`. Every wave validates against these.

### Validation Gate
- All tests produce identical golden output across repeated runs
- All examples compile and run identically
- Dump outputs are deterministic

---

## 7. Wave 1 — Foundational Utilities

### Goal
Implement the foundational types and utilities that every other module depends on.

### Modules

#### 7.1 `src/Span.w` — Source Locations

Direct port from `bootstrap/Span.zig`. FileId, Span (byte range), merge, len, zero sentinel.

#### 7.2 `src/Source.w` — Source File Loading

Port from `bootstrap/Source.zig`. Loads file content, builds line offset table.

#### 7.3 `src/InternPool.w` — Unified Intern Pool

Not a port — the bootstrap's InternPool is string-only. This is a new module that interns strings, types, and values from the start. Pre-registers all builtin types at fixed indices.

```
// Ref: .reference/zig/src/InternPool.zig (full interning)
// Ref: bootstrap/InternPool.zig (string-only — we extend)
```

#### 7.4 `src/Diag.w` — Error Reporting

New, not a port. Follows rustc's diagnostic model: primary span, secondary labels, error codes, machine-applicable suggestions.

```
// Ref: .reference/rust/compiler/rustc_errors/src/lib.rs
// Ref: bootstrap/Diagnostic.zig (simple model — we extend)
```

The diagnostic renderer (terminal output with colors, span underlines, multi-line context) is built here, separate from diagnostic emission.

#### 7.5 Data Structures — from `lib/std/`

Arena allocator, dynamic arrays, hash maps, and sorting come from the standard library (`lib/std/`). If the stdlib lacks a needed data structure, extend it there — not in a compiler-internal `src/util/`.

### Validation Gate
- Unit tests for Arena (alloc, reset, bulk free)
- Unit tests for InternPool (intern strings, intern types, resolve, dedup, builtin type indices)
- Unit tests for Diagnostic (emit, render with colors, suggestion rendering)
- Unit tests for HashMap (insert, lookup, iterate, delete)
- `with test` passes for all utility modules

---

## 8. Wave 2 — Token & Lexer

### Goal
Tokenize With source files identically to the bootstrap.

### Modules

#### 8.1 `src/Token.w` — Token Definitions

Port all 141 token tag variants from `bootstrap/Token.zig`. Include keyword lookup table.

**Keyword table** — The bootstrap uses Zig's `StaticStringMap` (compile-time perfect hash). In With, implement as a sorted array with binary search, or a hash map initialized at startup.

#### 8.2 `src/Lexer.w` — Lexer

Port `bootstrap/Lexer.zig`. Hand-written scanner.

Key details from bootstrap:
- String interpolation produces `string_start` / `string_fragment` / `string_end` tokens
- Comments are silently skipped
- Newlines are preserved as tokens (statement separators)
- Number literals: decimal, hex (`0x`), binary (`0b`), octal (`0o`)
- Character literals with escape sequences
- Multi-character operators: `==`, `!=`, `<=`, `>=`, `|>`, `<|`, `>>`, `<<`, `++`, `??`, `?.`, `..`, `..=`, `...`, `=>`, `->`, `+=`, `-=`, `*=`, `/=`, `%=`

### Validation Gate
- `--dump-tokens` output identical to golden baseline for all tests
- Unit tests for edge cases: string interpolation, escape sequences, hex/bin/oct literals
- Empty file, comment-only file, unicode identifiers

---

## 9. Wave 3 — AST & Parser

### Goal
Parse With source into AST nodes identically to the bootstrap.

### Modules

#### 9.1 `src/Ast.w` — AST Node Types

Port `bootstrap/Ast.zig`. All types listed in §5.4. Data definition module — no logic, just type declarations. Every variant, every field must match the bootstrap exactly.

#### 9.2 `src/Parser.w` — Recursive Descent Parser

Port `bootstrap/Parser.zig`. This is the largest single translation task in the frontend.

**Architecture:**
```
type Parser = {
    tokens: TokenList,
    pos: u32,
    source: str,
    pool: &mut InternPool,
    diags: &mut DiagnosticList,
    suppress_as: bool,
    pending_attributes: Vec[Attribute],
}
```

**Key parsing methods (in call order):**

1. `parseModule()` → Module
2. `parseDecl()` → Decl — dispatch on first token
3. `parseFnDecl()` → FnDecl — `fn name[T](params) -> ret: body`
4. `parseTypeDecl()` → TypeDecl — `type Name = struct | enum | alias | distinct`
5. `parseExpr()` → Expr — Pratt precedence climbing entry point
6. `parsePrimary()` → Expr — literals, idents, parens, if, match, while, for, loop, with, closures
7. `parsePostfix(expr)` → Expr — field access, index, call, await, `?`, `as`
8. `parseBinaryExpr(lhs, min_prec)` → Expr — precedence climbing loop
9. `parseBlock()` → BlockExpr — indented block
10. `parseIfExpr()` → IfExpr
11. `parseMatchExpr()` → MatchExpr
12. `parseWithExpr()` → WithExpr
13. `parseRecordUpdate()` → RecordUpdateExpr
14. `parseClosure()` → ClosureExpr
15. `parsePattern()` → Pattern — match arm patterns (12 variants)

**Pratt precedence table** (from bootstrap):
```
// 1: or              // 8: &
// 2: and             // 9: <<, >>
// 3: ==, !=          // 10: +, -, ++, ??
// 4: <, >, <=, >=    // 11: *, /, %
// 5: |> (pipeline)   // 12: unary prefix
// 6: |               // 13: postfix
// 7: ^
```

**Error recovery:** On parse error, emit diagnostic with span, create Poisoned node, skip tokens until next top-level keyword (`fn`, `type`, `let`, `use`, `trait`, `impl`, `extend`, `extern`, eof), resume parsing.

### Validation Gate
- `--dump-ast` output identical to golden baseline for all tests
- Parser error messages identical to bootstrap
- Round-trip: parse → render → parse produces identical AST
- Edge cases: deeply nested expressions, all operator precedences, error recovery

---

## 10. Wave 4 — Intern Pool & Type Representation

### Goal
Build the type system infrastructure that Sema will populate and Codegen will consume.

### Modules

#### 10.1 `src/Type.w` — Type System

Full type representation as described in §5.5. The TypeKind enum, struct/enum/fn type details, and the TypeTable that wraps the intern pool's type storage.

**Type table** — Central registry wrapping intern pool:
```
type TypeTable = {
    pool: &mut InternPool,
    // Convenience accessors for builtin types:
    // pool.type_error, pool.type_unit, pool.type_bool,
    // pool.type_i32, pool.type_str, pool.type_never, etc.
}
```

Following the Zig compiler's pattern, builtin types are pre-registered at fixed indices so they can be referenced without lookup.

#### 10.2 Function & Scope Tables

```
type FnInfo = {
    name: Symbol,
    params: Vec[ParamInfo],
    return_type: TypeId,
    is_generic: bool,
    type_params: Vec[Symbol],
    body: ?Expr,
}

type VarInfo = {
    name: Symbol,
    type_id: TypeId,
    is_mutable: bool,
    state: VarState,  // Live | Moved(Span)
}

type Scope = {
    vars: HashMap[Symbol, VarInfo],
    parent: ?&Scope,
}
```

#### 10.3 `src/Traits.w` — Trait Solver

Not a port — new module. Built correctly from the start.

```
// Ref: .reference/rust/compiler/rustc_trait_selection/

type TraitSolver = {
    cache: SelectionCache,
    impls: Vec[ImplInfo],
    trait_defs: HashMap[Symbol, TraitDef],
}

fn resolve(obligation: TraitObligation) -> Result[ImplId, TraitError]:
    // 1. Check cache
    // 2. Search impls for matching self_type
    // 3. Check coherence (no overlapping impls)
    // 4. Cache result
    // 5. Return
```

With has no HKTs, no GATs, no specialization, no lifetime parameters on traits. The solver is a straightforward obligation-fulfillment loop with a dedup cache.

### Validation Gate
- Unit tests for TypeTable (register, lookup, equality)
- All builtin types registered correctly at fixed indices
- Type interning: same type registered twice yields same TypeId
- Scope chain: variable lookup through nested scopes
- Trait solver: basic obligation resolution, cache hit on repeated queries

---

## 11. Wave 5 — Semantic Analysis

### Goal
Type-check and validate all With programs identically to the bootstrap.

### Module: `src/Sema.w`

#### 11.1 Architecture

```
// Ref: bootstrap/Sema.zig
// Ref: .reference/zig/src/Sema.zig
// Ref: .reference/rust/compiler/rustc_hir_typeck/

type Sema = {
    pool: &mut InternPool,
    diags: &mut DiagnosticList,
    type_table: TypeTable,
    fn_table: HashMap[Symbol, FnInfo],
    trait_solver: TraitSolver,
    scope_stack: Vec[Scope],
    current_fn: ?Symbol,
    var_states: HashMap[Symbol, VarState],
    no_std: bool,
}
```

#### 11.2 Two-Pass Strategy

**Pass 1: `collectDeclarations(module: &Module)`**

Walk all top-level declarations. Register struct types, enum types, type aliases, function signatures, trait declarations, impl/extend blocks. Check coherence (orphan rules). Do NOT check function bodies yet.

**Pass 2: `checkBodies(module: &Module)`**

Walk all function bodies. Type-check every expression. Infer types bidirectionally. Collect and resolve trait obligations via the selection cache. Track moves. Validate match exhaustiveness.

#### 11.3 Type Inference

```
fn inferType(expr: &Expr, expected: ?TypeId) -> TypeId
```

Key cases (from bootstrap):

| Expression | Inference Rule |
|-----------|---------------|
| Int literal | expected or i32 |
| Float literal | expected or f64 |
| String literal | str |
| Bool literal | bool |
| Identifier | lookup in scope chain |
| Binary | check operand types, return result type |
| Unary `-` | operand type (must be numeric) |
| Unary `not` | bool |
| Unary `&` | Ref(T, shared) |
| Unary `&mut` | Ref(T, mutable) |
| Unary `*` (deref) | inner type of Ptr/Ref |
| Unary `?` (try) | payload of Option/Result, early return on error |
| Call | lookup fn, check arg types, return ret type |
| Field access | lookup field on struct type |
| Index | check array/slice type, return element type |
| If expr | unify then/else branches |
| Match | unify all arm bodies |
| Closure | infer param types from context, check body |
| `as` (cast) | validate cast is legal, return target type |
| Pipeline `\|>` | desugar to function call |
| `??` | extract Option/Result payload, default on None/Err |
| With expr | Form 2 (builder), Form 3 (binding), Form 4 (record update) |
| Struct literal | check field types against struct def |
| Enum variant | check payload type against variant def |
| Array literal | unify all element types |

#### 11.4 Move Semantics

```
type VarState = Live | Moved(Span)

fn checkMove(name: Symbol, span: Span):
    // If var is Copy type → no-op
    // If var is already Moved → error "use of moved value"
    // Otherwise → mark as Moved
```

Copy types (from spec §2.3): all integer types, float types, bool, raw pointers.

#### 11.5 Built-in Functions

The bootstrap hardcodes special handling for: `println`, `print`, `assert`, `Some`, `Ok`, `Err`. The self-hosted compiler must replicate this:

```
// Built-in functions:
// println(args...) → Unit  (auto-format any type)
// print(args...) → Unit    (no newline)
// assert(cond: bool) → Unit (abort on false)
// Some(val: T) → Option[T]
// Ok(val: T) → Result[T, E]
// Err(val: E) → Result[T, E]
// None — checked in ident resolution AFTER enum variant lookup
```

#### 11.6 Feature Checklist

Every feature from the bootstrap must be validated in sema:

- [ ] Primitive types: i8/i16/i32/i64, u8/u16/u32/u64, f32/f64, bool, str, Unit
- [ ] Let/var bindings with type inference
- [ ] Assignment (simple, compound: +=, -=, *=, /=, %=)
- [ ] If/else with then/: forms
- [ ] While, loop, for, break, continue
- [ ] Boolean: and/or (short-circuit), not
- [ ] Struct definitions with defaults, field shorthand
- [ ] Enum definitions with unit/payload variants
- [ ] Type casting (as): int↔int, int↔float, float↔float
- [ ] Arrays with indexing and .len
- [ ] String type, escape sequences, string interpolation
- [ ] C string literals: `c"hello"` → `&CStr`
- [ ] Pipeline operator (`|>`)
- [ ] Bitwise operators (&, |, ^, ~, <<, >>)
- [ ] Closures: non-capturing (fn ptr) + capturing (fat pointer)
- [ ] Generics (monomorphization): `fn foo[T](x: T) -> T`
- [ ] Tuples: `(a, b)` with `.0`, `.1` access
- [ ] Defer: LIFO before returns
- [ ] Impl/extend blocks
- [ ] Trait declarations (static dispatch)
- [ ] Trait bounds: `fn f[T: Trait](x: T)`
- [ ] Where clauses: `fn f[T](x: T) where T: Trait`
- [ ] Variadic extern functions
- [ ] Type aliases: `type Name = OtherType`
- [ ] Use imports: `use path.to.module`
- [ ] c_import: `use c_import("header.h", link: "lib")`
- [ ] String interpolation: `"text {expr}"`
- [ ] References: `&x`, `&mut x`, `*ptr`, `*ptr = val`
- [ ] Option[T]: `Some(x)`, `None`, `??`, `?`
- [ ] Result[T,E]: `Ok(x)`, `Err(x)`, `??`, `?`
- [ ] `?T` optional type syntax
- [ ] Drop: auto-call `Type.drop(self)` at scope exit
- [ ] `with` blocks: Form 2 (builder), Form 3 (binding), Form 4 (record update)
- [ ] Record update: `{ expr with field: val }`
- [ ] Dynamic dispatch: `dyn Trait` → fat pointer
- [ ] Operator overloading: `+`, `-`, `*`, `==`
- [ ] Match guard duplicate variant handling
- [ ] String pattern matching
- [ ] @[tailrec]: loop-based TCO
- [ ] @[must_use]: warns on discarded return
- [ ] Display trait: println uses `.display()`
- [ ] Comptime: `comptime fn` / `comptime expr`

Note: Move tracking happens here in Sema. Borrow checking happens later on MIR (Wave 7).

### Validation Gate
- `--dump-typed` output identical to golden baseline
- All diagnostics (errors and warnings) identical to bootstrap
- All tests pass sema identically
- Move semantics: moved values properly rejected
- Type inference: all expressions get correct types
- Trait resolution: obligations resolved correctly, cache effective

---

## 12. Wave 6 — MIR & Lowering

### Goal
Lower typed AST into MIR — a CFG of basic blocks with all syntax sugar desugared, all drops explicit, and all control flow represented as branches between blocks.

### Modules

#### 12.1 `src/Mir.w` — MIR Type Definitions

All types defined in §5.6: MirBody, BasicBlock, Statement, Terminator, Place, Rvalue, Operand.

#### 12.2 `src/MirBuild.w` — AST → MIR Lowering

```
// Ref: .reference/rust/compiler/rustc_mir_build/src/build/
// No bootstrap equivalent — this is new

type MirBuilder = {
    body: MirBody,
    current_block: BasicBlockId,
    scope_stack: Vec[MirScope],
    pool: &InternPool,
    type_table: &TypeTable,
}

type MirScope = {
    locals: Vec[LocalId],         // locals declared in this scope
    defers: Vec[Expr],            // deferred expressions
    drop_order: Vec[LocalId],     // reverse declaration order for drops
}
```

**What MIR lowering desugars:**

| AST construct | MIR representation |
|---|---|
| `if cond: a else: b` | `SwitchInt(cond, [(1, bb_then)], bb_else)` |
| `while cond: body` | Loop: `bb_check → SwitchInt → bb_body → Goto(bb_check)`, `bb_exit` |
| `for x in iter: body` | Lower to `while iter.next()` pattern |
| `match expr { arms }` | Chain of `SwitchInt` on discriminant + `Downcast` projections |
| `with expr as name: body` | Assign → body → Drop |
| `with Builder.new() as b: ...` | Assign → body → call `.build()` → Drop |
| `defer expr` | Record in scope, emit before all exits (return, break, scope end) |
| `x ?? default` | `SwitchInt` on Option/Result tag |
| `x?.field` | `SwitchInt` on tag, propagate None on None path |
| `expr \|> fn` | `Call(fn, [expr])` |
| `{ expr with field: val }` | Copy → overwrite field |
| `|args| body` (closure) | Create captures struct, rewrite body to reference captures |
| `gen fn` (generator) | State machine with yield points as separate blocks |
| `async fn` | Fiber spawn + state machine |
| `select { arms }` | Channel multiplex lowering |
| Return from any scope | Insert defers + drops before the `Return` terminator |
| Scope exit | Insert drops in reverse declaration order |

**Drop insertion** — The critical thing MIR gets right that AST→LLVM doesn't:

For every scope exit (return, break, continue, fall-through), MIR inserts explicit `Drop` statements for all locals in reverse declaration order. This makes drop ordering visible, testable, and correct by construction. The bootstrap does this ad-hoc in Codegen; MIR makes it structural.

```
// Example: fn with two locals
fn example:
    let a = Vec.new()       // local _1
    let b = Vec.new()       // local _2
    if condition:
        return               // must drop _2 then _1
    // fall-through: must drop _2 then _1

// MIR:
// bb0: _1 = Call(Vec.new)
//       _2 = Call(Vec.new)
//       SwitchInt(condition, [(1, bb1)], bb2)
// bb1: Drop(_2, bb3)       // early return path
// bb3: Drop(_1, bb4)
// bb4: Return
// bb2: Drop(_2, bb5)       // fall-through path
// bb5: Drop(_1, bb6)
// bb6: Return
```

### Validation Gate
- `--dump-mir` produces stable, deterministic output
- MIR → Codegen → LLVM IR produces identical normalized LLVM IR to the bootstrap's direct AST → LLVM IR path
- All drops inserted in correct order
- All defers emitted before all exit paths
- All sugar desugared (with, match, closures, gen, async, select, ??, ?., |>)
- Round-trip: specific MIR patterns produce expected LLVM IR

---

## 13. Wave 7 — Borrow Checker

### Goal
Enforce the aliasing rule and borrow scoping on MIR, identically to the bootstrap's results but with a cleaner implementation.

### Module: `src/Borrow.w`

```
// Ref: .reference/rust/compiler/rustc_borrowck/ (NLL on MIR)
// Ref: bootstrap/Sema.zig (NLL section), BorrowCfg.zig
```

#### 13.1 Why MIR Makes This Better

The bootstrap checks borrows on the AST, which means:
- Control flow is implicit (nested if/else, early returns)
- Borrow liveness requires ad-hoc scope tracking
- Drop points are computed separately from borrow analysis

With MIR:
- Control flow is explicit (basic blocks + terminators)
- Borrow liveness is a dataflow problem on the CFG
- Drop points are already explicit `Drop` statements
- NLL regions are computed by walking the CFG backwards from last use

#### 13.2 NLL on MIR

```
type BorrowKind = Shared | Mutable

type BorrowInfo = {
    kind: BorrowKind,
    place: Place,             // what is borrowed (with projections)
    region: NllRegion,        // set of BasicBlockIds where borrow is live
    span: Span,               // where the borrow was created
}

type NllRegion = HashSet[BasicBlockId]
```

**Algorithm:**
1. Walk MIR, collect all `Ref` rvalues → create BorrowInfo
2. For each borrow, compute NLL region: the set of basic blocks between the borrow creation and its last use (dataflow analysis)
3. At each `Assign`, `Drop`, or `Call` statement, check: does this conflict with any active borrow?
4. Conflict = writing to a place that has an active shared borrow, or any access to a place that has an active mutable borrow

#### 13.3 Aliasing Rule Enforcement

```
// From spec §3.2:
// For any value, at any point:
//   - Any number of &T (shared borrows), OR
//   - Exactly one &mut T (exclusive borrow)
// Never both.

fn checkAccess(place: &Place, kind: AccessKind, location: Location):
    for borrow in active_borrows_at(location):
        if places_conflict(place, &borrow.place):
            if borrow.kind == Mutable or kind == Write:
                emit_conflict_error(borrow, place, location)
```

#### 13.4 Second-Class References (Spec §3.3)

References are ephemeral — they cannot appear in struct fields, heap containers, or escaping closures. This is enforced in two places:
- In Sema (Wave 5): struct field types checked, container generic args checked
- In Borrow (Wave 7): closure captures checked, return types checked

#### 13.5 Disjoint Field Borrowing

MIR's Place projections enable disjoint field borrowing naturally:

```
// This is legal:
let r1 = &point.x       // Place { local: _1, projections: [Field(0)] }
let r2 = &mut point.y   // Place { local: _1, projections: [Field(1)] }
// r1 and r2 don't conflict because Field(0) ≠ Field(1)
```

The bootstrap handles this with special-case logic. MIR makes it fall out of the `places_conflict` function naturally.

### Validation Gate
- All borrow-related test cases pass identically to bootstrap
- Aliasing violations detected at same locations
- NLL: borrows end at last use, not scope end
- Second-class restriction: references in struct fields rejected
- Disjoint field borrowing works

---

## 14. Wave 8 — LLVM Codegen

### Goal
Generate LLVM IR from MIR, producing identical binaries to the bootstrap.

### Module: `src/Codegen.w`

The bootstrap goes AST → LLVM IR. We go MIR → LLVM IR. The generated LLVM IR must be semantically identical (same behavior), though the exact IR may differ structurally since MIR has already desugared things the bootstrap desugars during codegen.

```
// Ref: bootstrap/Codegen.zig
// Ref: .reference/zig/src/codegen/llvm.zig
// Ref: .reference/rust/compiler/rustc_codegen_llvm/
```

#### 14.1 LLVM-C Bindings

```
use c_import("llvm-c/Core.h", link: "LLVM")
use c_import("llvm-c/Analysis.h")
use c_import("llvm-c/Target.h")
use c_import("llvm-c/TargetMachine.h")
```

#### 14.2 Codegen State

```
type Codegen = {
    context: LLVMContextRef,
    module: LLVMModuleRef,
    builder: LLVMBuilderRef,

    // Tables:
    fn_table: HashMap[Symbol, LLVMValueRef],
    type_table: HashMap[Symbol, LLVMTypeRef],
    local_table: HashMap[LocalId, LLVMValueRef],  // alloca for each MIR local

    // Monomorphization:
    mono_cache: HashMap[str, LLVMValueRef],
    generic_fns: HashMap[Symbol, FnInfo],

    // Option/Result cache:
    option_types: HashMap[TypeId, LLVMTypeRef],
    result_types: HashMap[(TypeId, TypeId), LLVMTypeRef],

    // Context:
    current_fn: ?LLVMValueRef,
    pool: &InternPool,
}
```

#### 14.3 MIR → LLVM IR Translation

Because MIR is already desugared, codegen becomes a straightforward walk:

| MIR construct | LLVM IR |
|---|---|
| `BasicBlock` | LLVM basic block |
| `Assign(place, Rvalue::BinaryOp(...))` | `LLVMBuildAdd` / `LLVMBuildSub` / etc. → store to alloca |
| `Assign(place, Rvalue::Call(...))` | `LLVMBuildCall` → store to alloca |
| `Assign(place, Rvalue::Ref(...))` | `LLVMBuildGEP` (address of place) |
| `Assign(place, Rvalue::Aggregate(...))` | Alloca + GEP stores for fields |
| `Drop(place)` | Call drop function |
| `Goto(bb)` | `LLVMBuildBr` |
| `SwitchInt(op, targets, default)` | `LLVMBuildSwitch` |
| `Return` | `LLVMBuildRet` |
| `Call(fn, args, dest, succ, unwind)` | `LLVMBuildCall` + `LLVMBuildBr(succ)` |

This is simpler than the bootstrap's codegen because all the complexity of desugaring `with`, `match`, closures, defers, etc. already happened in MIR lowering.

#### 14.4 Alloca Strategy

All MIR locals get an alloca at function entry. LLVM's mem2reg pass optimizes away redundant loads/stores. Same strategy as the bootstrap.

```
fn genFunction(fn_info: &FnInfo, mir: &MirBody):
    // 1. Create LLVM function
    // 2. Create entry block
    // 3. Alloca for every local in mir.locals
    // 4. Store parameters into their allocas
    // 5. For each basic block: gen statements + terminator
```

#### 14.5 Enum Representation

```
// Unit-only enum: i32 tag
// Enum with payloads: { tag: i32, payload: <largest variant> }
// Option[T]: { tag: i32, payload: T }  (tag 0 = Some, 1 = None)
// Result[T,E]: { tag: i32, payload: max(sizeof(T), sizeof(E)) }
```

#### 14.6 Trait Dispatch

```
// Static dispatch: direct function call (monomorphized, resolved in sema)
// Dynamic dispatch (dyn Trait): fat pointer { data_ptr, vtable_ptr }
//   vtable: global constant struct of function pointers
//   method call: load fn ptr from vtable, call with data_ptr
```

### Validation Gate
- All tests compile and produce binaries with identical behavior to bootstrap
- All examples compile and run identically
- Monomorphization: generic functions instantiated correctly
- Enum layout: tag+payload matches bootstrap
- Drop functions called at correct scope exits (now explicit in MIR)
- `--dump-llvm` output semantically equivalent to golden baseline (exact match may differ due to MIR desugaring order — validate by program behavior)

---

## 15. Wave 9 — Driver & CLI

### Goal
Wire everything together. The compiler accepts a `.w` file and produces a binary.

### Module: `src/Driver.w`

```
// Ref: bootstrap/Driver.zig
// Ref: .reference/zig/src/Compilation.zig
// Ref: .reference/rust/compiler/rustc_interface/src/passes.rs

type Driver = {
    pool: InternPool,
    arena: Arena,
    diags: DiagnosticList,
    imported_paths: HashSet[str],
    source_dir: str,
    c_import_cache: HashMap[str, Vec[Decl]],
    opt_level: u8,
    no_std: bool,
}
```

**Pipeline method:**
```
fn compileFile(path: str) -> ?Module:
    let source = Source.fromFile(path)
    let tokens = lexer.tokenize(source.text, source.file_id, &self.diags)
    if self.diags.hasErrors(): return None

    let module = parser.parse(tokens, source.text, &self.pool, &self.diags)
    if self.diags.hasErrors(): return None

    let module = self.processCImports(module)
    let module = self.processImports(module)

    let sema = Sema.init(&self.pool, &self.diags)
    sema.checkModule(&module)
    if self.diags.hasErrors(): return None

    let mir = mir_build.lower(&module, &self.pool)
    borrow.check(&mir, &self.diags)
    if self.diags.hasErrors(): return None

    codegen.emit(&mir, &self.pool, self.opt_level)
```

### Module: `src/main.w`

```
fn main -> i32:
    let args = process.args()

    match args[1]
        "build"  -> runBuild(args)
        "run"    -> runRun(args)
        "test"   -> runTest(args)
        "ast"    -> runAst(args)
        "tokens" -> runTokens(args)
        "mir"    -> runMir(args)
        "ir"     -> runIr(args)
        "clean"  -> runClean(args)
        _        -> printUsage()
```

### Module: `src/CImport.w`

```
// Ref: bootstrap/CImport.zig
// Uses libclang FFI to parse C headers → extern fn declarations

use c_import("clang-c/Index.h", link: "clang")

fn processCImport(header: str, link_libs: Vec[str]) -> Vec[Decl]:
    // Create clang index
    // Parse header
    // Visit cursor children
    // For each function declaration: create ExternFn Decl
    // Return list of extern declarations
```

### Module: `src/render.w`

AST and MIR pretty-printer for `--dump-ast`, `--dump-mir`, and debugging.

### Validation Gate
- `with build file.w` produces identical binary to bootstrap
- `with run file.w` produces identical output
- `with test` runs test suite identically
- All CLI flags work: -O0/-O1/-O2/-O3, --release, --no-std, --alloc
- Import resolution: `use path.to.module` works identically
- c_import: `use c_import("header.h", link: "lib")` works identically

---

## 16. Wave 10 — Stdlib & Runtime

### Goal
Ensure the self-hosted compiler can compile programs that use the stdlib.

The stdlib (`lib/std/`) is written in With and compiled by the compiler. It doesn't need porting — it just needs to compile correctly under the self-hosted compiler.

### Compiler's Stdlib Dependencies

The self-hosted compiler will use:
- `lib/std/mem.w` — heap allocation (alloc, free)
- `lib/std/string.w` — string operations
- `lib/std/io.w` — file I/O (reading source files)
- `lib/std/fs.w` — file system operations
- `lib/std/process.w` — CLI args, exit codes
- `lib/std/collections.w` — HashMap, Vec (or custom implementations)

### Runtime Components

The bootstrap links against runtime C files:
- `runtime/fiber.c` — fiber/coroutine support
- `runtime/fiber_asm_aarch64.s` — platform-specific fiber assembly
- `runtime/helpers.c` — helper functions (string operations, etc.)

The self-hosted compiler must link these same runtime components.

### Validation Gate
- All stdlib modules compile under self-hosted compiler
- All tests that use stdlib pass
- All examples compile and run
- Runtime components link correctly

---

## 17. Wave 11 — Bootstrap Chain & Fixpoint

### Goal
Achieve self-hosting: the compiler compiles itself, and the result compiles itself again.

### 17.1 Stage 1: Bootstrap Compiles Self-Hosted

```
# Build bootstrap (stage0)
cd bootstrap && zig build

# Stage0 compiles self-hosted compiler → stage1
./bootstrap/zig-out/bin/with build src/main.w -o .with/build/with-stage1

# Run full test suite with stage1
.with/build/with-stage1 test
```

**Expected issues:**
- Missing language features the compiler uses that aren't fully implemented
- Subtle type inference differences
- LLVM IR differences due to MIR-based codegen vs. direct AST codegen

### 17.2 Stage 2: Self-Hosted Compiles Self

```
# Stage1 compiles self-hosted compiler → stage2
.with/build/with-stage1 build src/main.w -o .with/build/with-stage2

# Run full test suite with stage2
.with/build/with-stage2 test
```

### 17.3 Stage 3: Fixpoint Verification

```
# Stage2 compiles self-hosted compiler → stage3
.with/build/with-stage2 build src/main.w -o .with/build/with-stage3

# Level 1: Semantic fixpoint
.with/build/with-stage3 test  # Must pass all tests

# Level 2: IR fixpoint
diff <(.with/build/with-stage2 ir src/main.w) <(.with/build/with-stage3 ir src/main.w)
# Must be identical (after normalization)

# Level 3: Binary fixpoint (ideal, not required)
sha256sum .with/build/with-stage2 .with/build/with-stage3
```

### 17.4 Post-Fixpoint

Once fixpoint passes:
1. Stage2 becomes the canonical compiler.
2. Bootstrap stays in `bootstrap/` — frozen, no new features.
3. All future development happens in With.
4. CI builds the Zig bootstrap on every commit (recovery insurance).

---

## 18. Testing Strategy

### 18.1 Unit Tests Per Module

Each compiler module has corresponding tests:

| Module | Test File | What's Tested |
|--------|-----------|--------------|
| Span.w | test/span.w | merge, len, zero sentinel |
| InternPool.w | test/intern.w | intern strings+types, resolve, dedup |
| Token.w | test/token.w | keyword lookup, tag display |
| Lexer.w | test/lexer.w | all token types, edge cases |
| Ast.w | test/ast.w | node construction, traversal |
| Parser.w | test/parser.w | all syntax forms, error recovery |
| Type.w | test/types.w | type equality, builtin types |
| Traits.w | test/traits.w | obligation resolution, cache, coherence |
| Sema.w | test/sema.w | type inference, move checking |
| Mir.w | test/mir.w | MIR construction, CFG integrity |
| MirBuild.w | test/mir_build.w | AST→MIR lowering, desugaring, drop insertion |
| Borrow.w | test/borrow.w | NLL on CFG, aliasing, second-class, disjoint fields |
| Codegen.w | test/codegen.w | MIR→LLVM IR generation |

### 18.2 Golden Diff Tests

After each wave, run the full test suite and diff against golden baselines:

```
for test in test/golden/*.w:
    actual = run_compiler(test)
    expected = read(test.expected)
    assert actual == expected
```

### 18.3 Self-Compilation Tests

After Wave 9:
```
# Compile the compiler with itself
with build src/main.w -o .with/build/with-selftest
# Compile a simple program with the self-compiled compiler
echo 'fn main -> i32: 42' | .with/build/with-selftest run -
# Must exit with code 42
```

### 18.4 Regression Testing

Every bug found during self-hosting becomes a test case in `test/cases/`.

---

## 19. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Missing language feature needed by compiler | High | Blocks self-hosting | Compile compiler early, identify gaps in Wave 3 |
| MIR→LLVM IR produces different behavior than AST→LLVM IR | Medium | Fails test suite | Validate behavior (exit codes, stdout) not exact IR |
| Codegen ordering differs from bootstrap | Medium | Fails golden diff | Normalize LLVM IR before comparison |
| c_import doesn't support all needed headers | Medium | Blocks LLVM bindings | Test c_import with LLVM-C headers early |
| Bootstrap compiler bugs | Medium | Wrong golden baseline | Fix bootstrap bugs first, re-capture golden |
| Recursive types in AST/MIR | Medium | Stack overflow | Use explicit stack for deep traversal |
| HashMap iteration nondeterminism | High | Fails golden diff | Sort all hash map iterations in output paths |
| Self-referential data in compiler | Medium | Fights ownership model | Use handle-based design (TypeId, Symbol, LocalId) |
| MIR is more work than AST→LLVM direct | Medium | Delays fixpoint | MIR pays for itself in borrow checker correctness and future optimization passes |

---

## Appendix A: Reference Code Index

| Pattern | Zig Reference | Rust Reference | Bootstrap |
|---------|---------------|----------------|-----------|
| String interning | `src/InternPool.zig:1-66` | `rustc_data_structures/src/intern.rs` | `InternPool.zig` |
| Type interning | `src/InternPool.zig:67+` | `rustc_middle/src/ty/context.rs` | — |
| SoA instruction storage | `src/Air.zig` (MultiArrayList) | — | — |
| Thin type wrapper | `src/Type.zig` | — | — |
| Two-pass analysis | `src/Sema.zig` | `rustc_hir_analysis/src/collect.rs` | `Sema.zig` |
| Arena allocation | `src/Sema.zig` (arena field) | `rustc_arena/` | `Driver.zig` |
| Diagnostic structure | — | `rustc_errors/src/lib.rs` | `Diagnostic.zig` |
| MIR types | — | `rustc_middle/src/mir/mod.rs` | — |
| MIR building | — | `rustc_mir_build/src/build/` | — |
| Borrow checking (NLL on MIR) | — | `rustc_borrowck/src/` | `Sema.zig` + `BorrowCfg.zig` |
| Trait resolution | — | `rustc_trait_selection/` | `Sema.zig` |
| Compilation pipeline | `src/Compilation.zig` | `rustc_interface/src/passes.rs` | `Driver.zig` |
| LLVM-C codegen | `src/codegen/llvm.zig` | `rustc_codegen_llvm/` | `Codegen.zig` |
| Pratt parser | — | `rustc_parse/src/parser/expr.rs` | `Parser.zig` |
| Error recovery | — | `rustc_parse/src/parser/` | `Parser.zig` |
| Keyword lookup | — | `rustc_lexer/src/lib.rs` | `Token.zig` |
| Monomorphization | — | `rustc_monomorphize/` | `Codegen.zig` |
| Vtable generation | — | `rustc_codegen_ssa/` | `Codegen.zig` |

---

## Appendix B: Implementation Order Summary

```
Wave 0:  Determinism audit + Golden baseline capture
Wave 1:  Span.w, Source.w, InternPool.w (full), Diag.w (full) + lib/std/ data structures
Wave 2:  Token.w, Lexer.w
Wave 3:  Ast.w, Parser.w
Wave 4:  Type.w, Traits.w (with selection cache + coherence)
Wave 5:  Sema.w (two-pass, move tracking, trait obligations)
Wave 6:  Mir.w, MirBuild.w (all desugaring, explicit drops)
Wave 7:  Borrow.w (NLL on MIR CFG)
Wave 8:  Codegen.w (MIR → LLVM IR)
Wave 9:  Driver.w, main.w, CImport.w, render.w
Wave 10: Stdlib validation, runtime linking
Wave 11: Bootstrap chain, fixpoint verification
```

Each wave gate: all previous tests still pass + new module tests pass + golden diff clean.