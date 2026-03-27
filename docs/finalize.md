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

- [x] Read src/Ast.w to catalog all 92 NK_* constants
- [x] Define `type NodeKind` discriminant enum with all variants
      preserving existing integer values
- [x] Delete all `const NK_*` definitions
- [x] `make build` — fix all compilation errors from removed constants
- [x] Update src/Ast.w internal uses
- [x] `make build && make fixpoint`

- [x] Update src/Sema.w: replace ~430 `if kind == NK_*` with `match kind`
      (largest consumer — do in batches of ~50 if-chains per sub-step)
- [x] `make build && make fixpoint`
- [x] Update src/Codegen.w: replace ~125 NK_* if-chains with `match kind`
- [x] `make build && make fixpoint`
- [x] Update src/render.w: replace NK_* if-chains with `match kind`
- [x] `make build && make fixpoint`
- [x] Update src/Resolve.w: replace NK_* if-chains with `match kind`
- [x] `make build && make fixpoint`
- [x] Update src/MirLower.w: replace NK_* if-chains with `match kind`
- [x] `make build && make fixpoint`
- [x] Update src/AsyncLower.w: replace NK_* if-chains with `match kind`
- [x] `make build && make fixpoint`
- [x] Update src/Parser.w: replace NK_* references with enum variants
- [x] `make build && make fixpoint`
- [x] Update src/main.w and src/main_emit_temp.w: replace NK_* uses
- [x] Update src/BorrowCfg.w: replace NK_* uses
- [x] `make build && make fixpoint`

### 1.2 src/Ast.w — Operator Kinds (25 + 7 constants)

**Current:** `const OP_ADD: i32 = 0` through `const OP_NOT_IN: i32 = 24`,
`const UOP_NEGATE: i32 = 0` through `const UOP_BIT_NOT: i32 = 6`

- [x] Define `type BinOp` discriminant enum with 25 OP_* variants
- [x] Define `type UnaryOp` discriminant enum with 7 UOP_* variants
- [x] Delete all `const OP_*` and `const UOP_*` definitions
- [x] Update all consumers across src/ files
- [x] `make build && make fixpoint`

### 1.3 src/Ast.w — Other Constant Groups

**Current:** TDK_* (7 type decl sub-kinds + 2 flag bits), FN_FLAG_* (13 bit flags),
VIS_* (2 visibility levels), FSTR_SEG_* (2 f-string segment types)

- [x] Define `type TypeDeclKind` discriminant enum with 7 TDK_* variants
      (keep TDK_FLAG_EPHEMERAL and TDK_FLAG_PACKED as bit constants)
- [x] Define `type Visibility` discriminant enum with VIS_PRIVATE, VIS_PUBLIC
- [x] Define `type FstrSegKind` discriminant enum with FSTR_SEG_LITERAL, FSTR_SEG_EXPR
- [x] Keep FN_FLAG_* as bit constants (flags combine — they are not enums)
- [x] Update all consumers
- [x] `make build && make fixpoint`

### 1.4 src/Token.w — Token Kinds (~125 constants)

**Current:** `const TK_INT_LIT: i32 = 0` through ~125 TK_* constants
**Target:** `type TokenKind` discriminant enum

- [x] Read src/Token.w to catalog all ~125 TK_* constants
- [x] Define `type TokenKind` discriminant enum preserving integer values
- [x] Delete all `const TK_*` definitions
- [x] Update src/Token.w internal uses (114 occurrences in `tag_name`)
- [x] `make build && make fixpoint`
- [x] Update src/Parser.w TK_* references
- [x] Update src/Lexer.w TK_* references
- [x] Update src/main.w and src/main_emit_temp.w TK_* references
- [x] `make build && make fixpoint`

### 1.5 src/Sema.w — Type Kinds (20 constants)

**Current:** `const TY_ERR: i32 = 0` through 20 TY_* constants
**Target:** `type TypeKind` discriminant enum

- [x] Define `type TypeKind` discriminant enum with 20 TY_* variants
- [x] Delete all `const TY_*` definitions
- [x] Update src/Sema.w internal uses
- [x] Update src/Codegen.w TY_* references
- [x] Update any other consumers (CCodegen.w, MirLower.w)
- [x] `make build && make fixpoint`

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

- [x] Define `type StmtKind` discriminant enum (5 SK_* variants)
- [x] Define `type TermKind` discriminant enum (6 TK_* variants)
- [x] Define `type RvalueKind` discriminant enum (9 RK_* variants)
- [x] Define `type OperandKind` discriminant enum (3 OK_* variants)
- [x] Define `type ConstKind` discriminant enum (7 CK_* variants)
- [x] Define `type ProjKind` discriminant enum (4 PK_* variants)
- [x] Define `type DropKind` discriminant enum (2 DK_* variants)
- [x] Define `type MirIntrinsic` discriminant enum (54 variants)
- [x] Delete all original constant definitions
- [x] Update src/Mir.w internal uses
- [x] Update src/MirLower.w consumers
- [x] Update src/Codegen.w MIR consumers
- [x] Update src/MirOpt.w consumers
- [x] Update src/BorrowCfg.w consumers
- [x] `make build && make fixpoint`

### 1.8 src/Resolve.w — Constant Groups (20 constants)

**Current:** IMPORT_KIND_* (2), DEF_KIND_* (9), SCOPE_KIND_* (7)

- [x] Define `type ImportKind` discriminant enum (USE, C_IMPORT)
- [x] Define `type DefKind` discriminant enum (9 DEF_KIND_* variants)
- [x] Define `type ScopeKind` discriminant enum (7 SCOPE_KIND_* variants)
- [x] Update all consumers in src/Resolve.w
- [x] `make build && make fixpoint`

### 1.9 src/Codegen.w — Remaining Integer Constants

- [x] Audit src/Codegen.w for any integer constant groups not
      covered by Ast/Token/Sema/Mir/Resolve enums
- [x] Convert any found groups to discriminant enums
- [x] `make build && make fixpoint`

---

## Phase 2: Handle Types (distinct i32)

`distinct` keyword is fully implemented. Transparent at LLVM level
(no wrapper struct). BlockId migration done. NodeId/TypeId deferred
(450+ sites each, mechanical but very large).

### 2.0 Implement `distinct` keyword support — DONE ✓

- [x] Add `distinct` keyword to lexer and parser
- [x] Implement `type X = distinct Y` in sema
- [x] Implement explicit cast: `val as X` and `val as Y`
- [x] Transparent LLVM lowering (no wrapper struct)
- [x] 21-test compatibility suite (`test/behavior/behav_distinct_compat.w`)
- [x] `make build && make fixpoint`

### 2.1 type NodeId = distinct i32

**File:** src/Ast.w — **Deferred** (450+ sites across 8 files)

- [ ] Add `type NodeId = distinct i32` to src/Ast.w
- [ ] Update AstPool functions to accept/return NodeId
- [ ] Update all consumer files (Parser.w, Resolve.w, Sema.w,
      Codegen.w, MirLower.w, render.w, etc.)
- [ ] `make build && make fixpoint`

### 2.2 type TypeId = distinct i32

**File:** src/Sema.w — **Deferred** (300+ sites)

- [ ] Add `type TypeId = distinct i32` to src/Sema.w
- [ ] Update type table functions to accept/return TypeId
- [ ] Update all consumer files
- [ ] `make build && make fixpoint`

### 2.3 type BlockId = distinct i32 — DONE ✓

**File:** src/Mir.w

- [x] Add `type BlockId = distinct i32` to src/Mir.w
- [x] Update MIR basic block functions to use BlockId
- [x] Update MirLower.w (15 boundary casts)
- [x] `make build && make fixpoint`

---

## Phase 3: Idiomatic Patterns

Apply idiomatic With patterns across the codebase. These are
mechanical transformations that preserve semantics.

### 3.1 Replace verbose closures with `it`

`it` implicit closures are implemented (TK_KW_IT, token 110).
Compiler source does not currently use `it` anywhere.

**N/A:** No closure patterns found in compiler source — the compiler
does not use higher-order functions with single-argument closures.
No sites to convert.

- [x] Search all src/*.w files for single-parameter closure patterns
- [x] Replace eligible closures with `it` shorthand (none found)
- [x] Verify no nested `it` usage (parser rejects this)
- [x] `make build && make fixpoint` (no changes needed)

### 3.2 Replace manual error matching with `?`

**N/A:** The compiler source does not use `Result` or `Option` return
types. All error handling uses sentinel values (`0`, `-1`). No manual
error matching patterns exist to convert.

- [x] Search all src/*.w files for match result/option patterns (none found)
- [x] No sites to convert — compiler uses sentinel returns, not Result/Option

### 3.3 Replace nested calls with `|>` pipelines

**N/A:** Already 27 uses of `|>` in Compilation.w, Link.w, main.w
(shell commands). Core compiler files use `let` chains and LLVM builder
nesting (`wl_const_int(wl_i64_type(ctx), ...)`) where `|>` would not
improve readability. No further conversion sites identified.

- [x] Audit all src/*.w for deeply nested function call chains
- [x] Existing 27 `|>` uses already cover natural pipeline sites
- [x] No additional sites where `|>` improves readability

### 3.4 Replace `== false` with `not`

**Current:** 5 occurrences remain (Sema.w: 4, Lexer.w: 1)

- [x] Replace 5 remaining `== false` patterns with `not`
- [x] `make build && make fixpoint` ✓

### 3.5 Replace remaining int_to_string with f-strings — DONE ✓

Generic type erasure fixed (codegen caches by sema_tid instead of
LLVM pointer). All 12 Sema.w cache key sites migrated to f-strings.
Also migrated sites in Codegen.w. Method calls extracted to
intermediate variables to avoid f-string parser interaction.

- [x] Fix generic type erasure bug (codegen sema_tid cache keys)
- [x] Convert all Sema.w and Codegen.w cache key sites to f-strings
- [x] `make build && make fixpoint`

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
- [x] Delete src/Driver.w (only string references remain in CCodegen.w
      and Scaffold.w — not actual imports)
- [x] Remove `use Driver` imports ✓
- [x] `make build && make fixpoint` ✓

---

## Phase 6: Hardcode Removal

**Status: Partially complete.** `is_builtin_fn` and `is_builtin_value`
are already deleted. `--no-prelude` flag is implemented.

### 6.1 Delete sema_is_builtin_trait_name — DONE ✓

Replaced with `lang_trait_syms` HashMap (4 language-level traits:
Copy, Drop, Send, ScopedSend). Other 13 resolve from prelude.
Orphan rule only enforced for local impl decls. Commit: `392de03`.

- [x] Replace with proper trait resolution from prelude imports
- [x] `make build && make fixpoint`

### 6.2 Reduce String-Based Dispatch in Codegen — DONE ✓

Pre-interned 36 dispatch symbols (container types, builtins, field
names) in Codegen struct. Converted all 59 string comparison sites
to O(1) symbol ID comparisons. 34 string comparisons remain
(intentionally kept: 12 primitive types, 9 ABI names, 10 runtime
C function names, 3 other).

- [x] Categorize: language primitives (must stay) vs prelude-provided
- [x] Pre-intern ~36 symbols at codegen init
- [x] Convert all 59 dispatch sites to symbol comparison
- [x] `make build && make fixpoint`

### 6.3 Verify --no-prelude Makes println Unavailable — DONE ✓

- [x] `--no-prelude` flag exists (FULL_MODE=0, CORE_MODE=1, NONE_MODE=2)
- [x] Verified manually: `--no-prelude` rejects `println`, `Vec`, and `HashMap`
- [x] Automated tests: `test/compile_errors/err_no_prelude_println.w`,
      `test/compile_errors/err_no_prelude_vec.w`
- [x] `make build && make fixpoint`

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

Codegen-level fix applied: `get_or_create_vec_type` and siblings now
cache by sema_tid instead of LLVM pointer. Sema-level types were
already correct. Remaining: remove redundant codegen parallel tracking.

- [x] Fix generic type erasure (codegen sema_tid cache keys)
- [x] Generic distinctness test (`behav_generic_distinct.w`)
- [x] Remove 5 dead cache fields (option_err_types, option_enum_syms,
      result_enum_syms, hm_type_to_is_str, hm_type_to_val)
- [ ] Instantiation cache: `(base_type, type_args)` → TypeId
- [ ] Type substitution function
- [ ] Delete remaining codegen parallel type tracking (requires threading
      sema type IDs through MIR codegen — deep refactor, 26 reverse
      lookup sites depend on LLVM type → metadata mapping)

---

## Phase II-3: Pipeline Ownership — DONE ✓

See Part I Phase 5. Driver.w deleted. main.w routes through Compilation.

---

## Phase II-4: Hardcode Removal

See Part I Phase 6. Phase 6.1 done (builtin traits → lang_trait_syms).
Phase 6.3 done (--no-prelude verified with automated tests).
Phase 6.2 (string dispatch) remains open.

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

### P2: One Source of Truth — Eliminate i32 Fallbacks — DONE ✓

Added `Codegen.type_fallback()` helper that sets `had_error = 1` and
returns i32 type. Converted 21 fallback sites where unknown types
silently defaulted to i32. 2 sites kept as-is (resolve_type for assoc
types and declare_function for generic params — resolved during
monomorphization). Remaining ~80 `wl_i32_type` uses are legitimate
(constants, GEP indices, enum tags, caching).

- [x] Convert each codegen fallback to a hard compile error (21 sites)
- [x] 2 sites intentionally kept (type resolution deferred to mono)
- [x] `make build && make fixpoint`

### P5: Determinism — HashMap Audit — DONE ✓

All 160 HashMaps are lookup-only (`.get()`, `.contains()`, `.insert()`).
No iteration (`.keys()`, `.values()`, `.entries()`, for-in-loop) found.
Fixpoint proves output determinism.

- [x] Audit all HashMap usages: all safe (lookup-only), no iteration found
- [x] `make build && make fixpoint`

### P8: Errors Are Values — Poisoned Nodes — DONE ✓

NK_POISONED_EXPR (69) already defined in Ast.w. Added
`Parser.poisoned_expr()` helper, converted 15 expression-level error
sites, added MirLower handler. Sema already returned TY_ERR.
4 new tests. Commit: `73c6116`.

- [x] Add NK_POISONED to AST for error recovery (already defined)
- [x] Update parser to emit NK_POISONED on errors
- [x] Update all downstream phases to handle gracefully
- [x] `make build && make fixpoint`

### P11: File Complexity Budget — DONE ✓

Split Codegen.w from 10,559 → 3,993 lines (well under 5,000 budget).
Two new files: CodegenDispatch.w (5,518 lines — MIR dispatch + mono +
downstream helpers) and CodegenTraits.w (1,068 lines — trait collection
+ vtable generation). Uses `use Codegen` pattern to define methods on
Codegen type from separate files.

- [x] Split Codegen.w: CodegenDispatch.w + CodegenTraits.w
- [x] Each split verified with fixpoint
- [x] Codegen.w: 3,993 lines (under 5,000 budget)
- [ ] Evaluate Sema.w for potential splits
- [x] `make build && make fixpoint`

### P12: Compile Time Tracking — DONE ✓

Baseline: ~105s self-compile. Script: `scripts/benchmark_self_compile.sh`.

- [x] Add timing to Makefile (log stage1/stage2 build times)
- [x] Create `scripts/benchmark_self_compile.sh`
- [x] Document baseline compile time (~105s)
- [x] `make build && make fixpoint`

### P13: Phase Boundary Tests — DONE ✓

13 tests covering --dump-tokens, --dump-ast, --dump-mir.
Added `expect-check-stdout` directive to test runner. Commit: `a7f22d8`.

- [x] Write phase output test infrastructure (`expect-check-stdout`)
- [x] Add tests for lexer, parser, sema, MIR dump outputs (13 tests)
- [ ] Add C backend round-trip tests
- [x] `make build && make fixpoint`

### P14: Reserved Syntax — DONE ✓

11 tests verify all reserved keywords. Commit: `3e1ef15`.

- [x] Verify all reserved keywords work or emit proper errors
- [x] Audit for any missing reservations
- [x] `make build && make fixpoint`

### P15: Seed Management

**Current:** Binary seed at `src/main` (~49MB). `make update-seed` target added.

- [x] Add `make update-seed` target (verify fixpoint → copy stage2)
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
- Phase 2.1/2.2 unblocked (`distinct` implemented) but deferred (large)
- Phase 6.2 partially depends on generics (TypeId-based dispatch)
- Phase 1 complete (all enum conversions done)
- Phase 3.5 complete (generic erasure fixed, f-strings migrated)

---

## Exit Gate

- [x] All NK_*, TK_*, TY_*, SK_*, RK_*, OK_*, CK_*, PK_*, DK_*,
      OP_*, UOP_*, TDK_*, VIS_*, DEF_KIND_*, SCOPE_KIND_*,
      IMPORT_KIND_*, FSTR_SEG_*, MIR_INTRINSIC_* constants are
      discriminant enums
- [ ] NodeId, TypeId, BlockId are distinct i32 types
- [x] No if-chains for node kind dispatch (all converted to match)
- [x] All 9 AstPool metadata lookups use O(1) HashMap
- [x] Sema scope lookup uses HashMap overlay
- [x] No magic number characters in Lexer.w
- [x] find_source_arg documented and deduplicated
- [x] Driver deleted or reduced to thin adapter
- [ ] main.w routes through compiler.Compilation
- [x] No string-based method dispatch in Codegen (pre-interned symbols)
- [x] `--no-prelude` makes println unavailable (verified + automated tests)
- [x] Compiler source uses f-strings consistently (zero int_to_string)
- [ ] `--emit-c` cross-compiles the compiler for four targets
- [ ] `with fmt` exists and compiler source passes it
- [ ] All tests pass
- [ ] `make fixpoint` holds after every change
