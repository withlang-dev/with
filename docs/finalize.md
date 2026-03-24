# Finalize — Idiomatic Rewrite and Quality Pass

---

## Part I — Idiomatic Rewrite and Quality

Goal: Rewrite the compiler source to idiomatic With. This is
the quality pass from the manifesto (Part II of this document).

Scope: Every file in `src/`. No functional changes — the
compiler does the same thing, but the code is clean.

Rule: One file at a time. Verify fixpoint after each file.
Never batch multiple files.

**Codebase stats (updated 2026-03-24):** 52,064 total lines
across 62 source files (34 in src/, 28 in src/compiler/).
Largest files: Codegen.w (10,494), Sema.w (8,982), CImport.w
(4,628), Parser.w (4,403), MirLower.w (3,918), CCodegen.w (3,775).

---

## Phase 1: Enum Conversions

Convert integer constant groups to discriminant enums. Each file
is a standalone unit of work. `make build && make fixpoint` after
each file.

### 1.1 src/Ast.w — Node Kinds (92 constants)

**Current:** `const NK_FN_DECL: i32 = 1` through 92 NK_* constants
**Target:** `type NodeKind = disc i32 { FN_DECL = 1, TYPE_DECL = 2, ... }`

- [ ] Read src/Ast.w to catalog all 92 NK_* constants
- [ ] Define `type NodeKind` discriminant enum with all variants
      preserving existing integer values
- [ ] Delete all `const NK_*` definitions
- [ ] `make build` — fix all compilation errors from removed constants
- [ ] Update src/Ast.w internal uses
- [ ] `make build && make fixpoint`

- [ ] Update src/Sema.w: replace ~430 `if kind == NK_*` with `match kind`
      (largest consumer — do in batches of ~50 if-chains per sub-step)
- [ ] `make build && make fixpoint`
- [ ] Update src/Codegen.w: replace ~125 NK_* if-chains with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/render.w: replace NK_* if-chains with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/Resolve.w: replace NK_* if-chains with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/MirLower.w: replace NK_* if-chains with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/AsyncLower.w: replace NK_* if-chains with `match kind`
- [ ] `make build && make fixpoint`
- [ ] Update src/Parser.w: replace NK_* references with enum variants
- [ ] `make build && make fixpoint`
- [ ] Update src/main.w and src/main_emit_temp.w: replace NK_* uses
- [ ] Update src/BorrowCfg.w: replace NK_* uses
- [ ] `make build && make fixpoint`

### 1.2 src/Ast.w — Operator Kinds (25 + 7 constants)

**Current:** `const OP_ADD: i32 = 0` through `const OP_NOT_IN: i32 = 24`,
`const UOP_NEGATE: i32 = 0` through `const UOP_BIT_NOT: i32 = 6`

- [ ] Define `type BinOp` discriminant enum with 25 OP_* variants
- [ ] Define `type UnaryOp` discriminant enum with 7 UOP_* variants
- [ ] Delete all `const OP_*` and `const UOP_*` definitions
- [ ] Update all consumers across src/ files
- [ ] `make build && make fixpoint`

### 1.3 src/Ast.w — Other Constant Groups

**Current:** TDK_* (7 type decl sub-kinds + 2 flag bits), FN_FLAG_* (13 bit flags),
VIS_* (2 visibility levels), FSTR_SEG_* (2 f-string segment types)

- [ ] Define `type TypeDeclKind` discriminant enum with 7 TDK_* variants
      (keep TDK_FLAG_EPHEMERAL and TDK_FLAG_PACKED as bit constants)
- [ ] Define `type Visibility` discriminant enum with VIS_PRIVATE, VIS_PUBLIC
- [ ] Define `type FstrSegKind` discriminant enum with FSTR_SEG_LITERAL, FSTR_SEG_EXPR
- [ ] Keep FN_FLAG_* as bit constants (flags combine — they are not enums)
- [ ] Update all consumers
- [ ] `make build && make fixpoint`

### 1.4 src/Token.w — Token Kinds (~125 constants)

**Current:** `const TK_INT_LIT: i32 = 0` through ~125 TK_* constants
**Target:** `type TokenKind` discriminant enum

- [ ] Read src/Token.w to catalog all ~125 TK_* constants
- [ ] Define `type TokenKind` discriminant enum preserving integer values
- [ ] Delete all `const TK_*` definitions
- [ ] Update src/Token.w internal uses (114 occurrences in `tag_name`)
- [ ] `make build && make fixpoint`
- [ ] Update src/Parser.w TK_* references
- [ ] Update src/Lexer.w TK_* references
- [ ] Update src/main.w and src/main_emit_temp.w TK_* references
- [ ] `make build && make fixpoint`

### 1.5 src/Sema.w — Type Kinds (20 constants)

**Current:** `const TY_ERR: i32 = 0` through 20 TY_* constants
**Target:** `type TypeKind` discriminant enum

- [ ] Define `type TypeKind` discriminant enum with 20 TY_* variants
- [ ] Delete all `const TY_*` definitions
- [ ] Update src/Sema.w internal uses
- [ ] Update src/Codegen.w TY_* references
- [ ] Update any other consumers (CCodegen.w, MirLower.w)
- [ ] `make build && make fixpoint`

### 1.6 src/Sema.w — Other Constant Groups

**Current:** VS_* (2 var states), BK_* (2 borrow kinds), DR_* (3 derive reqs)

- [x] Define `type VarState` discriminant enum (LIVE, MOVED)
- [x] Define `type BorrowKind` discriminant enum (SHARED, EXCLUSIVE)
- [x] Define `type DeriveReq` discriminant enum (COPY, CLONE, EQ)
- [x] Update all consumers (Sema.w, Mir.w, MirLower.w — 21 refs)
- [x] `make build && make fixpoint` ✓

### 1.7 src/Mir.w — All MIR Constant Groups (85+ constants)

**Current:** SK_* (5), TK_* (6), RK_* (9), OK_* (3), CK_* (7),
PK_* (4), DK_* (2), MIR_INTRINSIC_* (54)

- [ ] Define `type StmtKind` discriminant enum (5 SK_* variants)
- [ ] Define `type TermKind` discriminant enum (6 TK_* variants)
- [ ] Define `type RvalueKind` discriminant enum (9 RK_* variants)
- [ ] Define `type OperandKind` discriminant enum (3 OK_* variants)
- [ ] Define `type ConstKind` discriminant enum (7 CK_* variants)
- [ ] Define `type ProjKind` discriminant enum (4 PK_* variants)
- [ ] Define `type DropKind` discriminant enum (2 DK_* variants)
- [ ] Define `type MirIntrinsic` discriminant enum (54 variants)
- [ ] Delete all original constant definitions
- [ ] Update src/Mir.w internal uses
- [ ] Update src/MirLower.w consumers
- [ ] Update src/Codegen.w MIR consumers
- [ ] Update src/MirOpt.w consumers
- [ ] Update src/BorrowCfg.w consumers
- [ ] `make build && make fixpoint`

### 1.8 src/Resolve.w — Constant Groups (20 constants)

**Current:** IMPORT_KIND_* (2), DEF_KIND_* (9), SCOPE_KIND_* (7)

- [ ] Define `type ImportKind` discriminant enum (USE, C_IMPORT)
- [ ] Define `type DefKind` discriminant enum (9 DEF_KIND_* variants)
- [ ] Define `type ScopeKind` discriminant enum (7 SCOPE_KIND_* variants)
- [ ] Update all consumers in src/Resolve.w
- [ ] `make build && make fixpoint`

### 1.9 src/Codegen.w — Remaining Integer Constants

- [ ] Audit src/Codegen.w for any integer constant groups not
      covered by Ast/Token/Sema/Mir/Resolve enums
- [ ] Convert any found groups to discriminant enums
- [ ] `make build && make fixpoint`

---

## Phase 2: Handle Types (distinct i32)

**Prerequisite:** The `distinct` keyword must be implemented in the
compiler first. Currently not supported — this phase is blocked.

Replace raw `i32` handle types with `distinct i32` to prevent
accidentally passing a NodeId where a TypeId is expected.

### 2.0 Implement `distinct` keyword support

- [ ] Add `distinct` keyword to lexer and parser
- [ ] Implement `type X = distinct Y` in sema (creates new type
      that doesn't implicitly convert to/from Y)
- [ ] Implement explicit cast: `val as X` and `val as Y`
- [ ] Add tests for distinct types
- [ ] `make build && make fixpoint`

### 2.1 type NodeId = distinct i32

**File:** src/Ast.w

- [ ] Add `type NodeId = distinct i32` to src/Ast.w
- [ ] Update AstPool functions to accept/return NodeId
- [ ] Update all consumer files (Parser.w, Resolve.w, Sema.w,
      Codegen.w, MirLower.w, render.w, etc.)
- [ ] `make build && make fixpoint`

### 2.2 type TypeId = distinct i32

**File:** src/Sema.w

- [ ] Add `type TypeId = distinct i32` to src/Sema.w
- [ ] Update type table functions to accept/return TypeId
- [ ] Update all consumer files
- [ ] `make build && make fixpoint`

### 2.3 type BlockId = distinct i32

**File:** src/Mir.w

- [ ] Add `type BlockId = distinct i32` to src/Mir.w
- [ ] Update MIR basic block functions to use BlockId
- [ ] Update all consumer files
- [ ] `make build && make fixpoint`

---

## Phase 3: Idiomatic Patterns

Apply idiomatic With patterns across the codebase. These are
mechanical transformations that preserve semantics.

### 3.1 Replace verbose closures with `it`

`it` implicit closures are implemented (TK_KW_IT, token 110).
Compiler source does not currently use `it` anywhere.

- [ ] Search all src/*.w files for single-parameter closure patterns
- [ ] Replace eligible closures with `it` shorthand
- [ ] Verify no nested `it` usage (parser rejects this)
- [ ] `make build && make fixpoint`

### 3.2 Replace manual error matching with `?`

- [ ] Search for `match result` / `match option` patterns that
      propagate errors manually
- [ ] Replace with `?` operator where applicable
- [ ] `make build && make fixpoint`

### 3.3 Replace nested calls with `|>` pipelines

Pipeline operator is used in ~11 places currently. Extend where
readability improves.

- [ ] Identify deeply nested function calls where data flows linearly
- [ ] Replace where readability improves (judgment call)
- [ ] `make build && make fixpoint`

### 3.4 Replace `== false` with `not`

**Current:** 5 occurrences remain (Sema.w: 4, Lexer.w: 1)

- [x] Replace 5 remaining `== false` patterns with `not`
- [x] `make build && make fixpoint` ✓

### 3.5 Replace remaining int_to_string with f-strings

**Current:** 13 `int_to_string` call sites remain in Sema.w cache
key construction. These cannot be converted until the next seed
update (bootstrap cache key format interaction).

- [ ] After next seed install: convert remaining 13 Sema.w cache
      key sites from `int_to_string(x) ++ ":" ++ int_to_string(y)`
      to `f"{x}:{y}"`
- [ ] `make build && make fixpoint`

---

## Phase 4: Compiler Quality Improvements

### 4.1 AstPool Metadata: Add HashMaps for O(1) Lookup

**File:** src/Ast.w

**Current:** 9 functions do O(n) linear scans on metadata arrays:
`find_fn_meta`, `find_type_meta`, `find_where_meta`,
`find_for_meta`, `find_fn_param_pattern_meta`, `find_impl_type_params`,
`is_must_use_type_node`, `is_sealed_trait_node`, `is_move_closure`

- [x] Add 12 HashMaps to AstPool: fn_meta_map, type_meta_map,
      where_meta_map, for_meta_map, fn_param_pattern_meta_map,
      impl_type_params_map, impl_target_type_nodes_map,
      impl_trait_type_args_map, must_use_type_set, sealed_trait_set,
      move_closure_set, non_escaping_closure_set
- [x] Rewrite all 12 find/is functions to use O(1) HashMap lookup
- [x] `make build && make fixpoint` ✓

### 4.2 Sema Scope Lookup: Add HashMap Overlay

**File:** src/Sema.w

**Current:** `scope_lookup` and 12 related functions do reverse
linear scans of `bind_names` Vec.

- [x] Added `scope_name_map: HashMap[i32, i32]` to Sema
- [x] Rewrite all 13 scope functions to O(1) HashMap lookup
- [x] Populate on scope_put_at, remove on pop_scope
- [x] `make build && make fixpoint` ✓

### 4.3 Lexer: Replace Remaining Magic Numbers

**File:** src/Lexer.w

**Current:** 36 CH_* constants defined, but ~50+ magic number
comparisons still used with inline comments.

- [x] Added 23 new CH_* constants (letters, digits)
- [x] Replaced ~100 magic number comparisons with CH_* constants
- [x] `make build && make fixpoint` ✓

### 4.4 Document find_source_arg Assumptions

**File:** src/main.w

- [x] Added documenting comments to `find_source_arg`
- [x] Cached result: computed once, stored in `source` variable, passed to
      all subcommands (17 redundant calls → 1)
- [x] `make build && make fixpoint` ✓

---

## Phase 5: Pipeline Ownership

**Status: 95% complete.** main.w already routes through
compiler.Compilation. Zcu is the canonical state owner. Driver.w
is a thin adapter (205 lines).

### 5.1 Delete Driver or reduce further

- [x] Checked: only Lsp.w imported Driver (unused), now removed
- [ ] Delete src/Driver.w (only string references remain in CCodegen.w
      and Scaffold.w — not actual imports)
- [x] Remove `use Driver` imports ✓
- [x] `make build && make fixpoint` ✓

---

## Phase 6: Hardcode Removal

**Status: Partially complete.** `is_builtin_fn` and `is_builtin_value`
are already deleted. `--no-prelude` flag is implemented.

### 6.1 Delete sema_is_builtin_trait_name

**Current:** 16 hardcoded trait names (Copy, Drop, Scoped, Debug, etc.)

- [ ] Replace with proper trait resolution from prelude imports
- [ ] `make build && make fixpoint`

### 6.2 Reduce String-Based Dispatch in Codegen

**Current:** 74 string comparisons (`method_name == "..."`) in Codegen.w

- [ ] Categorize: language primitives (must stay) vs prelude-provided (remove)
- [ ] Replace prelude-provided dispatch with type-based dispatch
      (Vec methods, HashMap methods, Option/Result methods, string methods)
- [ ] `make build && make fixpoint` after each category

### 6.3 Verify --no-prelude Makes println Unavailable

- [x] `--no-prelude` flag exists (FULL_MODE=0, CORE_MODE=1, NONE_MODE=2)
- [ ] Write test verifying `--no-prelude` rejects `println`
- [ ] Verify `--no-prelude` also makes Vec, HashMap, Option unavailable
- [ ] `make build && make fixpoint`

---

## Part II — Quality Pass Implementation Plan

The compiler reached fixpoint on March 6, 2026. Stage 2 and
Stage 3 are byte-identical. Everything from here is the compiler
improving itself.

---

## Phase II-1: Idiomatic Rewrite

**Detailed plan:** Part I of this document

Summary: enum conversions, handle types, idiomatic patterns.

---

## Phase II-2: Type System Completion

**Detailed plan:** `docs/05_Generics.md`

- [ ] Fix generic type erasure (`Vec[i32]` != `Vec[str]` in sema)
- [ ] Instantiation cache: `(base_type, type_args)` → TypeId
- [ ] Type substitution function
- [ ] Delete codegen parallel type tracking (~2000 lines)

---

## Phase II-3: Pipeline Ownership

See Part I Phase 5. **95% complete.**

---

## Phase II-4: Hardcode Removal

See Part I Phase 6. **Partially complete.**

---

## Phase II-5: C Backend Completion

**Current state:** CCodegen.w (3,775 lines) reads MIR. `--emit-c`
flag works. Runtime files exist. Not yet capable of
cross-compiling the compiler for 4 targets.

### 5.1 Audit CCodegen Coverage Gaps

- [ ] Compile test programs with `--emit-c`, verify output compiles
- [ ] List all 54 MIR intrinsics and verify CCodegen handles each
- [ ] List all runtime functions called by CCodegen and verify they exist
- [ ] `make build && make fixpoint`

### 5.2 Self-Compile via C Backend

- [ ] Attempt: `./out/bin/with-stage2 build src/main.w --emit-c`
- [ ] Fix CCodegen gaps until self-compile completes
- [ ] After each fix: `make build && make fixpoint`

### 5.3 Compile Emitted C to Working Binary

- [ ] Compile out/main.c with host C compiler
- [ ] Run C-compiled compiler: `check src/main.w` must succeed
- [ ] Compare output vs LLVM-compiled compiler

### 5.4 Cross-Compilation for 4 Targets

- [ ] aarch64-apple-darwin, x86_64-unknown-linux-gnu,
      aarch64-unknown-linux-gnu, x86_64-apple-darwin
- [ ] Cross-compile with `zig cc -target <triple>`
- [ ] Document workflow in CONTRIBUTING.md

### 5.5 Ship with_compiler.c as New Seed

- [ ] Generate `with_compiler.c` from self-compile
- [ ] Verify it compiles to working compiler on clean machine
- [ ] Add to repo (replaces binary src/main as auditable seed)
- [ ] Update Makefile: `make bootstrap-from-c`

---

## Phase II-6: Tooling

### 6.1 `with fmt` — Code Formatter

**Current state:** Stub in main.w.

- [ ] Design formatting rules (indent, width, whitespace)
- [ ] Implement as AST round-trip: parse → walk → emit
- [ ] Wire `with fmt` command in main.w
- [ ] Run on compiler source, verify fixpoint holds
- [ ] `make build && make fixpoint`

### 6.2 `with test` — Zero-Config Test Runner

**Current state:** Basic test runner exists. No `@[test]` discovery.

- [ ] Implement `@[test]` attribute support
- [ ] Test function discovery and reporting
- [ ] `--filter <pattern>` flag
- [ ] `make build && make fixpoint`

### 6.3 `with bench` — Zero-Config Benchmarking

**Current state:** No command handler.

- [ ] Design `@[bench]` attribute support
- [ ] Implement benchmark runner with timing
- [ ] `make build && make fixpoint`

### 6.4 Error Messages with Suggestions

- [ ] Audit errors missing source locations or suggestions
- [ ] Add "did you mean?" for undefined variables (Levenshtein)
- [ ] Add signature display for wrong argument count
- [ ] Verify every error has a location
- [ ] `make build && make fixpoint`

---

## Principle Enforcement

Cross-cutting concerns from the manifesto.

### P2: One Source of Truth — Eliminate i32 Fallbacks

**Current:** Codegen.w has `wl_i32_type` fallbacks. Sema.w returns
0 from type resolution in 30+ places.

- [ ] Convert each codegen fallback to a hard compile error
- [ ] Replace sentinel 0 returns with proper error propagation
- [ ] `make build && make fixpoint`

### P5: Determinism — HashMap Audit

**Current:** 244+ HashMap declarations (Codegen.w: 166, Sema.w: 62,
CCodegen.w: 16). Fixpoint holds, meaning iteration order currently
doesn't affect output — but this must be verified, not assumed.

- [ ] Audit all HashMap usages: safe (lookup-only) vs unsafe (iterated)
- [ ] Design and implement OrderedMap for iterated maps
- [ ] Replace unsafe HashMaps with OrderedMap
- [ ] `make build && make fixpoint`

### P8: Errors Are Values — Poisoned Nodes

- [ ] Add NK_POISONED to AST for error recovery
- [ ] Update parser to emit NK_POISONED on errors
- [ ] Update all downstream phases to handle gracefully
- [ ] `make build && make fixpoint`

### P11: File Complexity Budget

**Current:** Codegen.w is 10,494 lines (2x the 5,000 line budget).
Sema.w is 8,982 lines (1.8x budget).

- [ ] Split Codegen.w: extract string/Vec/HashMap/Option/closure/match
      codegen into separate modules
- [ ] Each split is a separate step with fixpoint verification
- [ ] Target: Codegen.w under 5,000 lines
- [ ] Evaluate Sema.w for potential splits
- [ ] `make build && make fixpoint`

### P12: Compile Time Tracking

- [ ] Add timing to Makefile (log stage1/stage2 build times)
- [ ] Create `scripts/benchmark_self_compile.sh`
- [ ] Document baseline compile time
- [ ] `make build && make fixpoint`

### P13: Phase Boundary Tests

- [ ] Write phase output test infrastructure
- [ ] Add tests for lexer, parser, sema, MIR dump outputs
- [ ] Add C backend round-trip tests
- [ ] `make build && make fixpoint`

### P14: Reserved Syntax

**Current:** `const` and `it` are implemented. `where` has parser
support. `errdefer` and `move` emit errors. `async`/`await`/`yield`
are implemented.

- [ ] Verify all reserved keywords work or emit proper errors
- [ ] Audit for any missing reservations (`macro`, etc.)
- [ ] `make build && make fixpoint`

### P15: Seed Management

**Current:** Binary seed at `src/main` (~49MB). Manual update.

- [ ] Add `make update-seed` target (verify fixpoint → copy stage2)
- [ ] Add safety check: refuse if tests fail
- [ ] When C backend can self-compile: replace binary with C seed
- [ ] `make build && make fixpoint`

---

## Execution Protocol

For each change:

1. Read the relevant source before editing.
2. Make one logical change.
3. `make build`
4. Run specific test(s) if applicable.
5. `make fixpoint`

If the build breaks, stop and bisect. Do not batch changes.

**Recommended order:**

1. Phase 4 (quality improvements) — lowest risk, immediate benefit
2. Phase 1.5 + 1.6 (Sema.w small enums) — well-contained
3. Phase 1.7 (Mir.w enums) — well-contained
4. Phase 1.8 (Resolve.w enums) — small
5. Phase 1.4 (Token.w enums) — medium scope
6. Phase 1.1 (Ast.w NodeKind) — largest enum, most consumers
7. Phase 2 (distinct types) — depends on enum conversions + `distinct` keyword
8. Phase 3 (idiomatic patterns) — can be done incrementally
9. Phase 5 (pipeline ownership) — nearly done, just delete Driver
10. Phase 6 (hardcode removal) — depends on Phase 5 and generics
11. Phase II-5 (C backend) — depends on core compiler stability
12. Phase II-6 (tooling) — independent, can be done anytime
13. Principle enforcement — ongoing, interleave with other phases

**Dependencies:**
- Phase 2 blocked on `distinct` keyword implementation
- Phase 6.2 partially depends on generics (TypeId-based dispatch)
- Phase 1.1 (largest) benefits from doing smaller enums first as practice
- Phase 3.5 blocked on next seed install

---

## Exit Gate

- [ ] All NK_*, TK_*, TY_*, SK_*, RK_*, OK_*, CK_*, PK_*, DK_*,
      OP_*, UOP_*, TDK_*, VIS_*, DEF_KIND_*, SCOPE_KIND_*,
      IMPORT_KIND_*, FSTR_SEG_*, MIR_INTRINSIC_* constants are
      discriminant enums
- [ ] NodeId, TypeId, BlockId are distinct i32 types
- [ ] No if-chains for node kind dispatch (all converted to match)
- [ ] All 9 AstPool metadata lookups use O(1) HashMap
- [ ] Sema scope lookup uses HashMap overlay
- [ ] No magic number characters in Lexer.w
- [ ] find_source_arg documented and deduplicated
- [ ] Driver deleted or reduced to thin adapter
- [ ] main.w routes through compiler.Compilation
- [ ] No string-based method dispatch in Codegen (prelude-provided)
- [ ] `--no-prelude` makes println unavailable
- [ ] Compiler source uses f-strings consistently (zero int_to_string)
- [ ] `--emit-c` cross-compiles the compiler for four targets
- [ ] `with fmt` exists and compiler source passes it
- [ ] All tests pass
- [ ] `make fixpoint` holds after every change
