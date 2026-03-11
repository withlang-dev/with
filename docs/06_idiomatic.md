# 06 — Idiomatic Rewrite and Quality

Goal: Rewrite the compiler source to idiomatic With. This is
the quality pass from the manifesto (docs/07_quality.md).

Scope: Every file in `src/`. No functional changes — the
compiler does the same thing, but the code is clean.

Rule: One file at a time. Verify fixpoint after each file.
Never batch multiple files.

**Codebase stats:** 36,387 total lines across 33+ source files.
Largest files: Codegen.w (10,821), Sema.w (5,820), CCodegen.w
(3,749), Parser.w (3,538).

---

## Phase 1: Enum Conversions

Convert integer constant groups to discriminant enums. Each file
is a standalone unit of work. `make build && make fixpoint` after
each file.

### 1.1 src/Ast.w — Node Kinds (60 constants, 690 if-chain uses)

**Current:** `const NK_FN_DECL: i32 = 1` through `const NK_PAT_SLICE: i32 = 113`
**Target:** `type NodeKind = disc i32 { FN_DECL = 1, TYPE_DECL = 2, ... }`

- [ ] Read src/Ast.w lines 15-123 to catalog all 60 NK_* constants
- [ ] Define `type NodeKind` discriminant enum with all 60 variants
      preserving existing integer values
- [ ] Delete all 60 `const NK_*` definitions
- [ ] Update `fn NK_*() -> i32` accessor pattern if used (check callers)
- [ ] `make build` — fix all compilation errors from removed constants
- [ ] Update src/Ast.w internal uses (if-chains within the file)
- [ ] `make build && make fixpoint`

- [ ] Update src/Sema.w: replace 320 `if kind == NK_*` with `match kind`
      (largest consumer — do in batches of ~50 if-chains per sub-step)
- [ ] `make build && make fixpoint`
- [ ] Update src/Codegen.w: replace 126 `if kind == NK_*` with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/render.w: replace 83 `if kind == NK_*` with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/Resolve.w: replace 64 `if kind == NK_*` with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/MirLower.w: replace 43 `if kind == NK_*` with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/AsyncLower.w: replace 31 `if kind == NK_*` with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/Parser.w: replace NK_* references with enum variants
- [ ] `make build && make fixpoint`
- [ ] Update src/main.w and src/main_emit_temp.w: replace 18 NK_* uses
- [ ] Update src/BorrowCfg.w: replace 5 NK_* uses
- [ ] `make build && make fixpoint`

### 1.2 src/Ast.w — Operator Kinds (25 + 6 constants)

**Current:** `const OP_ADD: i32 = 0` through `const OP_NOT_IN: i32 = 24`,
`const UOP_NEGATE: i32 = 0` through `const UOP_TRY: i32 = 5`

- [ ] Define `type BinOp` discriminant enum with 25 OP_* variants
- [ ] Define `type UnaryOp` discriminant enum with 6 UOP_* variants
- [ ] Delete all `const OP_*` and `const UOP_*` definitions
- [ ] Update all consumers across src/ files
- [ ] `make build && make fixpoint`

### 1.3 src/Ast.w — Other Constant Groups

**Current:** TDK_* (5 type decl sub-kinds), FN_FLAG_* (13 bit flags),
VIS_* (2 visibility levels)

- [ ] Define `type TypeDeclKind` discriminant enum with 5 TDK_* variants
- [ ] Define `type Visibility` discriminant enum with VIS_PRIVATE, VIS_PUBLIC
- [ ] Keep FN_FLAG_* as bit constants (flags are not enums — they combine)
- [ ] Update all consumers
- [ ] `make build && make fixpoint`

### 1.4 src/Token.w — Token Kinds (141 constants)

**Current:** `const TK_INT_LIT: i32 = 0` through `const TK_WHERE: i32 = 113`
**Target:** `type TokenKind` discriminant enum

- [ ] Read src/Token.w lines 13-140 to catalog all 141 TK_* constants
- [ ] Define `type TokenKind` discriminant enum preserving integer values
- [ ] Delete all `const TK_*` definitions
- [ ] Update src/Token.w internal uses (114 occurrences in `tag_name`)
- [ ] `make build && make fixpoint`
- [ ] Update src/Parser.w TK_* references
- [ ] Update src/Lexer.w TK_* references
- [ ] Update src/main.w and src/main_emit_temp.w TK_* references
- [ ] `make build && make fixpoint`

### 1.5 src/Sema.w — Type Kinds (19 constants)

**Current:** `const TY_ERR: i32 = 0` through `const TY_NEVER: i32 = 18`
**Target:** `type TypeKind` discriminant enum

- [ ] Define `type TypeKind` discriminant enum with 19 TY_* variants
- [ ] Delete all `const TY_*` definitions
- [ ] Update src/Sema.w internal uses
- [ ] Update src/Codegen.w TY_* references
- [ ] Update any other consumers (CCodegen.w, MirLower.w)
- [ ] `make build && make fixpoint`

### 1.6 src/Sema.w — Other Constant Groups

**Current:** VS_* (2 var states), BK_* (2 borrow kinds), DR_* (3 derive reqs)

- [ ] Define `type VarState` discriminant enum (LIVE, MOVED)
- [ ] Define `type BorrowKind` discriminant enum (SHARED, EXCLUSIVE)
- [ ] Define `type DeriveReq` discriminant enum (COPY, CLONE, EQ)
- [ ] Update all consumers
- [ ] `make build && make fixpoint`

### 1.7 src/Mir.w — All MIR Constant Groups (36+ constants)

**Current:** SK_* (5), TK_* (6), RK_* (9), OK_* (3), CK_* (7),
PK_* (4), DK_* (2), MIR_INTRINSIC_* (17)

- [ ] Define `type StmtKind` discriminant enum (5 SK_* variants)
- [ ] Define `type TermKind` discriminant enum (6 TK_* variants)
- [ ] Define `type RvalueKind` discriminant enum (9 RK_* variants)
- [ ] Define `type OperandKind` discriminant enum (3 OK_* variants)
- [ ] Define `type ConstKind` discriminant enum (7 CK_* variants)
- [ ] Define `type ProjKind` discriminant enum (4 PK_* variants)
- [ ] Define `type DropKind` discriminant enum (2 DK_* variants)
- [ ] Define `type MirIntrinsic` discriminant enum (17 variants)
- [ ] Delete all original constant definitions
- [ ] Update src/Mir.w internal uses
- [ ] Update src/MirLower.w consumers
- [ ] Update src/Codegen.w MIR consumers
- [ ] Update src/MirOpt.w consumers
- [ ] Update src/BorrowCfg.w consumers
- [ ] `make build && make fixpoint`

### 1.8 src/Codegen.w — Remaining Integer Constants

- [ ] Audit src/Codegen.w for any integer constant groups not
      covered by Ast/Token/Sema/Mir enums
- [ ] Convert any found groups to discriminant enums
- [ ] `make build && make fixpoint`

---

## Phase 2: Handle Types (distinct i32)

Replace raw `i32` handle types with `distinct i32` to prevent
accidentally passing a NodeId where a TypeId is expected.

### 2.1 type NodeId = distinct i32

**File:** src/Ast.w

- [ ] Add `type NodeId = distinct i32` to src/Ast.w
- [ ] Update AstPool functions to accept/return NodeId instead of i32
      for node-index parameters
- [ ] Update callers in src/Ast.w
- [ ] `make build` — catalog all type errors
- [ ] Update src/Parser.w to use NodeId
- [ ] Update src/Resolve.w to use NodeId
- [ ] Update src/Sema.w to use NodeId
- [ ] Update src/Codegen.w to use NodeId
- [ ] Update src/MirLower.w to use NodeId
- [ ] Update src/render.w to use NodeId
- [ ] Update remaining files (AsyncLower.w, BorrowCfg.w, main.w, etc.)
- [ ] `make build && make fixpoint`

### 2.2 type TypeId = distinct i32

**File:** src/Sema.w

- [ ] Add `type TypeId = distinct i32` to src/Sema.w
- [ ] Update type table functions (add_type, get_type_kind, etc.)
      to accept/return TypeId
- [ ] Update src/Sema.w internal uses
- [ ] `make build` — catalog all type errors
- [ ] Update src/Codegen.w to use TypeId
- [ ] Update remaining consumer files
- [ ] `make build && make fixpoint`

### 2.3 type BlockId = distinct i32

**File:** src/Mir.w

- [ ] Add `type BlockId = distinct i32` to src/Mir.w
- [ ] Update MIR basic block functions to use BlockId
- [ ] Update src/MirLower.w to use BlockId
- [ ] Update src/Codegen.w MIR consumers to use BlockId
- [ ] Update src/MirOpt.w, src/BorrowCfg.w
- [ ] `make build && make fixpoint`

---

## Phase 3: Idiomatic Patterns

Apply idiomatic With patterns across the codebase. These are
mechanical transformations that preserve semantics.

### 3.1 Replace verbose closures with `it`

- [ ] Search all src/*.w files for `|x|` single-parameter closure patterns
- [ ] Replace eligible closures with `it` shorthand
      (e.g., `v.filter(|x| x > 0)` → `v.filter(it > 0)`)
- [ ] Verify no nested `it` usage (parser rejects this)
- [ ] `make build && make fixpoint`

### 3.2 Replace manual error matching with `?`

- [ ] Search for `match result` / `match option` patterns that
      propagate errors manually (unwrap-or-return patterns)
- [ ] Replace with `?` operator where the function returns
      Result or Option
- [ ] `make build && make fixpoint`

### 3.3 Replace nested calls with `|>` pipelines

- [ ] Identify deeply nested function calls where data flows linearly
      (e.g., `f(g(h(x)))` → `x |> h |> g |> f`)
- [ ] Replace where readability improves (judgment call — not all
      nesting benefits from pipelines)
- [ ] `make build && make fixpoint`

### 3.4 Replace `if x == false` with `if not x`

- [ ] Search for `== false` patterns in src/*.w
- [ ] **Status:** 0 occurrences found in current codebase — verify
      and skip if confirmed
- [ ] `make build && make fixpoint` (if any changes made)

### 3.5 Remove unnecessary parens on zero-arg functions

- [ ] Search for `fn name()` patterns where parens are unnecessary
      in With syntax
- [ ] Remove unnecessary parens where idiomatic
- [ ] `make build && make fixpoint`

### 3.6 Remove unnecessary return type annotations on void functions

- [ ] Search for `fn name() -> ()` or explicit void return annotations
- [ ] **Status:** 0 occurrences found — verify and skip if confirmed
- [ ] `make build && make fixpoint` (if any changes made)

---

## Phase 4: Compiler Quality Improvements

### 4.1 AstPool Metadata: Add HashMaps for O(1) Lookup

**File:** src/Ast.w (lines 427-570)

**Current:** 9 functions do O(n) linear scans on metadata arrays:
`find_fn_meta` (line 427), `find_type_meta` (line 458),
`find_where_meta` (line 510), `find_for_meta` (line 564),
`find_fn_param_pattern_meta` (line 545),
`find_impl_type_params` (line 523),
`is_must_use_type_node` (line 475),
`is_sealed_trait_node` (line 486),
`is_move_closure` (line 497)

- [ ] Read src/Ast.w lines 427-570 to understand each metadata lookup
- [ ] Add `fn_meta_map: HashMap[i32, i32]` to AstPool struct
      (maps node → index in fn_meta vec)
- [ ] Populate fn_meta_map when fn_meta entries are added
- [ ] Rewrite `find_fn_meta` to use HashMap lookup
- [ ] `make build && make fixpoint`
- [ ] Add `type_meta_map: HashMap[i32, i32]` to AstPool struct
- [ ] Rewrite `find_type_meta` to use HashMap lookup
- [ ] `make build && make fixpoint`
- [ ] Add `where_meta_map: HashMap[i32, i32]` to AstPool struct
- [ ] Rewrite `find_where_meta` to use HashMap lookup
- [ ] `make build && make fixpoint`
- [ ] Add `for_meta_map: HashMap[i32, i32]` to AstPool struct
- [ ] Rewrite `find_for_meta` to use HashMap lookup
- [ ] `make build && make fixpoint`
- [ ] Add `fn_param_pattern_meta_map: HashMap[i32, i32]` to AstPool struct
- [ ] Rewrite `find_fn_param_pattern_meta` to use HashMap lookup
- [ ] `make build && make fixpoint`
- [ ] Add `impl_type_params_map: HashMap[i32, i32]` to AstPool struct
- [ ] Rewrite `find_impl_type_params` to use HashMap lookup
- [ ] `make build && make fixpoint`
- [ ] Convert `must_use_type_nodes` to `HashMap[i32, i32]` (node → 1)
- [ ] Rewrite `is_must_use_type_node` to use HashMap.contains
- [ ] `make build && make fixpoint`
- [ ] Convert `sealed_trait_nodes` to `HashMap[i32, i32]` (node → 1)
- [ ] Rewrite `is_sealed_trait_node` to use HashMap.contains
- [ ] `make build && make fixpoint`
- [ ] Convert `move_closure_nodes` to `HashMap[i32, i32]` (node → 1)
- [ ] Rewrite `is_move_closure` to use HashMap.contains
- [ ] `make build && make fixpoint`

### 4.2 Sema Scope Lookup: Add HashMap Overlay

**File:** src/Sema.w (lines 781-921)

**Current:** 13 scope lookup functions do reverse linear scans of
`bind_names` Vec. Scope uses watermark stack (`scope_starts`).

- [ ] Read src/Sema.w lines 781-921 to understand scope architecture
- [ ] Design HashMap overlay: `scope_name_map: HashMap[i32, i32]`
      mapping sym → most recent binding index
- [ ] On `push_scope`: save current map state (snapshot or copy)
- [ ] On `define_var`: insert sym → index into scope_name_map
- [ ] On `pop_scope`: restore previous map state
- [ ] Rewrite `scope_lookup` to use HashMap first, fall back to
      linear scan only if miss (defensive)
- [ ] `make build && make fixpoint`
- [ ] Once verified, remove linear scan fallback
- [ ] Rewrite `scope_lookup_mut` to use HashMap
- [ ] Rewrite `scope_lookup_state` to use HashMap
- [ ] Rewrite `scope_has` to use HashMap.contains
- [ ] Rewrite remaining 9 scope functions to use HashMap
- [ ] `make build && make fixpoint`

### 4.3 Lexer: Replace Remaining Magic Numbers

**File:** src/Lexer.w (lines 83-234)

**Current:** 6 remaining numeric character comparisons despite
36 CH_* constants already defined (lines 11-46).

- [ ] Read src/Lexer.w lines 83-234 to find remaining magic numbers
- [ ] Replace `== 10` with `== CH_NEWLINE` (line 83)
- [ ] Replace remaining numeric char comparisons (lines 88-227)
      with existing CH_* constants
- [ ] Verify no new constants needed (all 36 CH_* cover the cases)
- [ ] `make build && make fixpoint`

### 4.4 Document find_source_arg Assumptions

**File:** src/main.w (lines 275-291)

**Current:** `find_source_arg` does linear scan of CLI args,
called 16+ times redundantly.

- [ ] Read src/main.w lines 275-291 and all callers
- [ ] Add comment documenting assumptions:
      - Skips `-o <path>` (2-arg option)
      - Skips `--output=<path>` prefix options
      - Returns first non-flag positional argument
      - Returns "" if no source file found
- [ ] Consider caching: compute source_arg once, store in local
- [ ] If caching: refactor main to call find_source_arg once and
      pass result to subcommand handlers
- [ ] `make build && make fixpoint`

---

## Phase 5: Pipeline Ownership

Move compilation state from Driver to Zcu. Route main.w through
compiler.Compilation. Delete or reduce Driver.

### 5.1 Audit Current State Distribution

**Files:** src/Driver.w (204 lines), src/compiler/Zcu.w (256 lines),
src/compiler/Compilation.w (317 lines), src/main.w (550 lines)

- [ ] Read src/Driver.w in full — catalog all state fields
      (comp, mode, source_path, output_path, opt_level, no_std,
      alloc, last_error_count)
- [ ] Read src/compiler/Zcu.w in full — catalog all state fields
- [ ] Read src/compiler/Compilation.w — understand adapter role
- [ ] Read src/main.w — understand current entry point flow
- [ ] Map which Driver fields duplicate Zcu/Compilation fields
- [ ] Map which Driver methods simply delegate to Compilation

### 5.2 Move State from Driver to Zcu

- [ ] Identify Driver fields not already in Zcu:
      mode, source_path, output_path, opt_level, last_error_count
- [ ] Move `mode` to CompilationConfig (MODE_CHECK, MODE_BUILD, MODE_RUN)
- [ ] Move `source_path` to Zcu (if not already via current_source_path)
- [ ] Move `output_path` to CompilationConfig
- [ ] Move `opt_level` to CompilationConfig (if not already there)
- [ ] Remove `last_error_count` — use Zcu.diagnostics.count() directly
- [ ] `make build && make fixpoint`

### 5.3 Route main.w Through compiler.Compilation

- [ ] Update main.w subcommand handlers to use Compilation directly
      instead of creating Driver instances
- [ ] Replace `Driver.new()` calls with `Compilation.init()` calls
- [ ] Replace `driver.build()` with `comp.build()`
- [ ] Replace `driver.check()` with `comp.check()`
- [ ] Verify all CLI flags are passed through CompilationConfig
- [ ] `make build && make fixpoint`

### 5.4 Delete Driver or Reduce to Thin Adapter

- [ ] After main.w no longer uses Driver directly:
      check if any test files or other code still references Driver
- [ ] If no remaining references: delete src/Driver.w entirely
- [ ] If references remain: reduce Driver to thin adapter that
      wraps Compilation with no duplicated state
- [ ] Remove `use Driver` imports from all files
- [ ] `make build && make fixpoint`

---

## Phase 6: Hardcode Removal

Remove all non-primitive hardcoded symbol names from sema and
codegen. The prelude is the sole source of ambient names.

### 6.1 Audit Hardcoded Names

- [ ] Read `sema_is_builtin_trait_name()` (Sema.w lines 1457-1468)
      — lists 11 hardcoded trait names: Drop, Scoped, ScopedMut,
      Debug, Display, Default, Iter, IntoIter, Eq, Hash, Ord
- [ ] Audit src/Codegen.w for string-based dispatch — estimated
      133+ string comparisons for method/type names
- [ ] Categorize each hardcoded name:
      - **Language primitive** (must stay): primitive types (i32, bool, str, etc.),
        `c_import`, `comptime`, `it`, operator desugaring
      - **Prelude-provided** (must remove): println, eprintln, Vec, HashMap,
        Option, Result, Some, None, Ok, Err, assert, todo, unreachable
      - **Trait dispatch** (must remove): method names dispatched by string

### 6.2 Delete is_builtin_fn from Sema

- [ ] Read `is_builtin_fn` in src/Sema.w (find exact location)
- [ ] Identify all callers of is_builtin_fn
- [ ] Replace each call site with proper trait/impl lookup or
      prelude-based resolution
- [ ] Delete the function
- [ ] `make build && make fixpoint`

### 6.3 Delete is_builtin_value from Sema

- [ ] Read `is_builtin_value` in src/Sema.w (find exact location)
- [ ] Identify all callers
- [ ] Replace with proper scope-based resolution (values come from
      prelude imports, not hardcoded lists)
- [ ] Delete the function
- [ ] `make build && make fixpoint`

### 6.4 Delete Name-Based Dispatch from Codegen

This is the largest hardcode removal task. Codegen dispatches
method calls by comparing string names (133+ comparisons).

- [ ] Catalog all string-based dispatches in gen_method_call
      (Codegen.w lines 7088-7276): Vec methods, HashMap methods,
      Option methods, Result methods, string methods
- [ ] Design replacement: codegen should dispatch based on
      sema-provided TypeId + method symbol, not string names
- [ ] Replace Vec method dispatch (push, get, pop, len, is_empty,
      clear, contains, map, filter, fold, join) with type-based dispatch
- [ ] `make build && make fixpoint`
- [ ] Replace HashMap method dispatch (insert, get, remove, contains,
      len, is_empty, increment, decrement, update, append)
      with type-based dispatch
- [ ] `make build && make fixpoint`
- [ ] Replace Option method dispatch (is_some, is_none, unwrap,
      expect, unwrap_or, map, and_then, filter, or_else, flatten)
      with type-based dispatch
- [ ] `make build && make fixpoint`
- [ ] Replace Result method dispatch (is_ok, is_err, unwrap, expect,
      ok, err, map, map_err, and_then, context)
      with type-based dispatch
- [ ] `make build && make fixpoint`
- [ ] Replace string method dispatch (len, is_empty, contains,
      starts_with, ends_with, find, slice, byte_at, to_upper,
      to_lower, trim, repeat, split, replace)
      with type-based dispatch
- [ ] `make build && make fixpoint`
- [ ] Replace builtin function dispatch (eprintln, todo, unreachable,
      assert, require, check, printf, Some, None, Ok, Err)
      with prelude-resolved dispatch
- [ ] `make build && make fixpoint`

### 6.5 Verify --no-prelude Makes println Unavailable

- [ ] Write test `test/cases/err_no_prelude_println.w`:
      ```
      //! args: --no-prelude
      //! expect-check-fail: undefined
      fn main:
          println("hello")
      ```
- [ ] Run test: `./scripts/run_tests.sh test/cases/err_no_prelude_println.w`
- [ ] Verify that `--no-prelude` also makes Vec, HashMap, Option,
      Result unavailable (they come from prelude)
- [ ] `make build && make fixpoint`

---

## Execution Protocol

For each change:

1. Read the relevant source before editing.
2. Make one logical change.
3. `make build`
4. Run specific test(s) if applicable.
5. Run full test suite: `./scripts/run_tests.sh`
6. After each file/group: `make fixpoint`

If the build breaks, stop and bisect. Do not batch changes
across files.

**Recommended order:**

1. Phase 4 (quality improvements) — lowest risk, immediate benefit
2. Phase 1.5 + 1.6 (Sema.w enums) — small, well-contained
3. Phase 1.7 (Mir.w enums) — small, well-contained
4. Phase 1.4 (Token.w enums) — medium scope
5. Phase 1.1 (Ast.w NodeKind) — largest enum, most consumers
6. Phase 2 (distinct types) — depends on enum conversions
7. Phase 3 (idiomatic patterns) — can be done incrementally
8. Phase 5 (pipeline ownership) — structural change
9. Phase 6 (hardcode removal) — depends on Phase 5 and
   generic instantiation (docs/05_Generics.md)

**Dependencies:**
- Phase 6.4 (name-based dispatch removal) partially depends on
  docs/05_Generics.md — codegen needs sema TypeId to replace
  string-based type dispatch
- Phase 2 (distinct types) is smoother after Phase 1 enums
  are in place

---

## Exit Gate

- [ ] All NK_*, TK_*, TY_*, SK_*, RK_*, OK_*, CK_*, PK_*, DK_*
      constants are discriminant enums
- [ ] All OP_*, UOP_*, TDK_*, VIS_* constants are discriminant enums
- [ ] NodeId, TypeId, BlockId are distinct i32 types
- [ ] No if-chains for node kind dispatch (all converted to match)
- [ ] All 9 AstPool metadata lookups use O(1) HashMap
- [ ] Sema scope lookup uses HashMap overlay
- [ ] No magic number characters in Lexer.w
- [ ] find_source_arg documented and deduplicated
- [ ] Driver deleted or reduced to thin adapter
- [ ] main.w routes through compiler.Compilation
- [ ] is_builtin_fn and is_builtin_value deleted from Sema
- [ ] No string-based method dispatch in Codegen
- [ ] `--no-prelude` makes println unavailable
- [ ] All tests pass under `./scripts/run_tests.sh`
- [ ] `make fixpoint` holds after every change
