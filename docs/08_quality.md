# 07 — Quality Pass Implementation Plan

The compiler reached fixpoint on March 6, 2026. Stage 2 and
Stage 3 are byte-identical. The bootstrap is dead. Everything
from here is the compiler improving itself.

This plan turns the quality pass manifesto into trackable work
items. It covers the 6 phases, the 15 principles, and the
non-negotiables. Work defined in detail in other docs is
cross-referenced, not duplicated.

---

## Phase 1: Idiomatic Rewrite

**Detailed plan:** `docs/06_idiomatic.md`

Summary of work (see 06 for full checkboxes):

- [ ] Enum conversions: NK_* (60 constants, 690 if-chains),
      TK_* (141), TY_* (19), MIR groups (36+), OP_*/UOP_*/TDK_*/VIS_*
- [ ] Handle types: NodeId, TypeId, BlockId as `distinct i32`
- [ ] Idiomatic patterns: `it`, `?`, `|>` where appropriate
- [ ] Verify: compiler source reads as idiomatic With

---

## Phase 2: Type System Completion

**Detailed plan:** `docs/05_Generics.md`

Summary of work (see 05 for full checkboxes):

- [ ] Add TY_GENERIC_INST to TypeKind
- [ ] Instantiation cache: `(base_type, type_args)` → TypeId
- [ ] Fix `resolve_type_expr` (stop returning 0 for generics)
- [ ] Type substitution function (single function, used everywhere)
- [ ] Update trait/impl resolution with instantiation keys
- [ ] Delete codegen parallel type tracking (~2000 lines)
- [ ] Verify: `Vec[i32] != Vec[str]` enforced in sema

---

## Phase 3: Pipeline Ownership

**Detailed plan:** `docs/06_idiomatic.md` Phase 5

Summary of work (see 06 for full checkboxes):

- [ ] Move state from Driver to Zcu
- [ ] Route main.w through compiler.Compilation
- [ ] Delete Driver or reduce to thin adapter
- [ ] Verify: no semantic or codegen logic outside `src/compiler/*`

---

## Phase 4: Hardcode Removal

**Detailed plan:** `docs/06_idiomatic.md` Phase 6

Summary of work (see 06 for full checkboxes):

- [ ] Delete `is_builtin_fn`, `is_builtin_value` from sema
- [ ] Delete name-based dispatch from codegen (133+ string comparisons)
- [ ] Wire prelude as sole source of ambient names
- [ ] Verify: `--no-prelude` makes `println` unavailable

---

## Phase 5: C Backend Completion

**Current state:** CCodegen.w is functional (3,749 lines). Reads
MIR. `--emit-c` flag works. Runtime files exist (with_runtime.h,
with_runtime.c, helpers.c, fiber.c, fiber_asm for x86_64 and
aarch64). Not yet capable of cross-compiling the compiler itself
for 4 targets.

**Files:** `src/CCodegen.w`, `runtime/`, `src/compiler/Link.w`

### 5.1 Audit CCodegen Coverage Gaps

- [ ] Read src/CCodegen.w (3,749 lines) end-to-end to identify
      MIR constructs not yet translated to C
- [ ] Compile a simple test program with `--emit-c`, verify output
      compiles with `cc` and produces correct results
- [ ] Compile a more complex test program (Vec, HashMap, Option,
      closures, traits) with `--emit-c` and verify
- [ ] List all MIR intrinsics (17 total) and verify CCodegen handles
      each one (MIR_INTRINSIC_VEC_NEW through MIR_INTRINSIC_OPT_UNWRAP)
- [ ] List all runtime functions called by CCodegen and verify they
      exist in with_runtime.c / helpers.c
- [ ] `make build && make fixpoint`

### 5.2 Self-Compile via C Backend

- [ ] Attempt: `./out/bin/with-stage2 build src/main.w --emit-c`
      to emit the compiler as C
- [ ] Catalog all CCodegen failures/errors during self-compile
- [ ] Fix CCodegen gaps one at a time (each gap is a sub-task):
- [ ] Gap fix 1: (to be determined by audit)
- [ ] Gap fix 2: (to be determined by audit)
- [ ] Gap fix 3: (to be determined by audit)
- [ ] After each fix: `make build && make fixpoint`
- [ ] Verify: `with-stage2 build src/main.w --emit-c` completes
      without errors and produces `out/main.c`

### 5.3 Compile Emitted C to Working Binary

- [ ] Compile `out/main.c` with host C compiler (LLVM clang):
      `clang -O2 -I runtime out/main.c runtime/with_runtime.c
      runtime/helpers.c runtime/fiber.c runtime/fiber_asm_aarch64.s
      -o out/bin/with-from-c`
- [ ] Run `out/bin/with-from-c check src/main.w` — must succeed
- [ ] Run `out/bin/with-from-c build src/main.w` — must produce
      a working binary
- [ ] Compare output of C-compiled compiler vs LLVM-compiled compiler:
      both must produce identical output for the same input
- [ ] `make fixpoint` with C-compiled binary as seed

### 5.4 Cross-Compilation for 4 Targets

- [ ] Define target triples:
      `aarch64-apple-darwin`, `x86_64-unknown-linux-gnu`,
      `aarch64-unknown-linux-gnu`, `x86_64-apple-darwin`
- [ ] For each target, verify CCodegen emits platform-appropriate C:
      - Correct integer sizes and alignment
      - Correct fiber assembly selection (x86_64 vs aarch64)
      - Correct system library dependencies
- [ ] Cross-compile with `zig cc -target <triple>` for each target
- [ ] Verify each cross-compiled binary runs correctly on its target
      (use QEMU for Linux targets if on macOS)
- [ ] Document cross-compilation workflow in CONTRIBUTING.md

### 5.5 Ship with_compiler.c as New Seed

- [ ] Generate `with_compiler.c` from self-compile via C backend
- [ ] Verify `with_compiler.c` compiles to a working compiler on
      a clean machine with only a C compiler
- [ ] Add `with_compiler.c` to repository (replaces binary `src/main`
      as auditable, platform-independent seed)
- [ ] Update Makefile to support building from C seed:
      `make bootstrap-from-c`
- [ ] Update CONTRIBUTING.md with C seed bootstrap instructions
- [ ] Preserve previous binary seed as release artifact
- [ ] `make build && make fixpoint`

---

## Phase 6: Tooling

### 6.1 `with fmt` — Code Formatter

**Current state:** Stub in main.w (prints "not yet available").

- [ ] Design formatting rules:
      - Indentation: 4 spaces (match compiler source convention)
      - Line width: 80 columns (match manifesto prose style)
      - Trailing whitespace: removed
      - Trailing newline: required
      - Blank lines: at most 2 consecutive
      - Import grouping: std imports first, then local
- [ ] Implement formatter as AST round-trip:
      parse → walk AST → emit formatted source
- [ ] Create `src/Formatter.w` (or extend render.w)
- [ ] Wire `with fmt` command in main.w (replace stub)
- [ ] Write test: format a messy file, verify output matches expected
- [ ] Run `with fmt` on compiler source — catalog all changes
- [ ] Fix any formatting rule conflicts found by formatting
      compiler source
- [ ] Verify: `with fmt` is idempotent (format twice = same output)
- [ ] Verify: formatted compiler source still passes fixpoint
- [ ] `make build && make fixpoint`

### 6.2 `with test` — Zero-Config Test Runner

**Current state:** Basic implementation compiles and runs binary.
No `@[test]` attribute discovery.

- [ ] Design `@[test]` attribute support:
      - Parser recognizes `@[test]` attribute on functions
      - Test functions have signature `fn test_name()` (no args, no return)
      - `with test <file>` discovers and runs all `@[test]` functions
      - `with test <dir>` discovers all `.w` files recursively
- [ ] Implement `@[test]` function collection in sema
- [ ] Implement test runner codegen: generate `main` that calls all
      test functions, reports pass/fail per function
- [ ] Add `--filter <pattern>` flag to run subset of tests
- [ ] Add output: test name, pass/fail, duration, summary
- [ ] Write test for the test runner itself
- [ ] `make build && make fixpoint`

### 6.3 `with bench` — Zero-Config Benchmarking

**Current state:** No command handler exists.

- [ ] Design `@[bench]` attribute support:
      - `@[bench]` functions receive iteration count parameter
      - Runner warms up, then measures N iterations
      - Reports: min, median, mean, std dev per benchmark
- [ ] Implement `@[bench]` function collection
- [ ] Implement benchmark runner with timing infrastructure
- [ ] Add `with bench` command to main.w
- [ ] Write benchmark for compiler self-compile time
- [ ] `make build && make fixpoint`

### 6.4 Error Messages with Suggestions

**Current state:** Diagnostic type supports notes and helps fields
(src/Diagnostic.w). Quality varies — some errors include
suggestions, many don't.

- [ ] Audit error messages in src/Sema.w: catalog errors missing
      source locations, suggestions, or fix hints
- [ ] Audit error messages in src/Parser.w: same
- [ ] For each common error, add a help suggestion:
- [ ] "undefined variable X" → "did you mean Y?" (Levenshtein)
- [ ] "type mismatch: expected X, got Y" → show both locations
- [ ] "missing return" → "add return statement or change return type"
- [ ] "immutable variable" → "add `mut` to the declaration"
- [ ] "wrong argument count" → show function signature
- [ ] Verify: every error has a file and line (non-negotiable #6)
- [ ] `make build && make fixpoint`

---

## Principle Enforcement

These items enforce the 15 manifesto principles. They are not
tied to a single phase — they are cross-cutting concerns.

### P2: One Source of Truth — Eliminate i32 Fallbacks

**Current state:** Codegen.w has multiple `wl_i32_type` fallbacks
(lines 4036, 4079, 4122, 4150, 4155). Sema.w returns 0 from
type resolution in 30+ places.

**Detailed plan for codegen fallbacks:** `docs/01_Codegen_Bug_Fixes.md`
Priority 5 (i32 Fallback Elimination)

- [ ] Audit all `wl_i32_type` fallback sites in Codegen.w
- [ ] Convert each fallback to a hard compile error
- [ ] Audit all `return 0` in Sema.w type resolution
- [ ] Replace sentinel 0 returns with proper error propagation
- [ ] Verify: no silent i32 defaults remain (non-negotiable #3)
- [ ] `make build && make fixpoint`

### P5: Determinism — HashMap Audit

**Current state:** 243 HashMap declarations across the compiler.
OrderedMap does not exist. The manifesto requires ordered maps.

**Critical insight:** The compiler currently achieves fixpoint
WITH HashMaps, meaning iteration order is currently deterministic
enough (or iteration over HashMaps doesn't affect output order).
This must be verified, not assumed.

- [ ] Audit all 243 HashMap usages and categorize:
      - **Safe:** HashMap used only for lookup, never iterated
        (key→value queries only). These are fine.
      - **Unsafe:** HashMap iterated (for-in loop over keys/values).
        These must be replaced with ordered structures.
      - **Unknown:** Need investigation.
- [ ] Count unsafe (iterated) HashMaps:
      - Codegen.w: 172 HashMap declarations
      - Sema.w: 38 HashMap declarations
      - CCodegen.w: 16 HashMap declarations
      - Other files: 17 HashMap declarations
- [ ] Design OrderedMap type:
      - Option A: Vec of (key, value) pairs with linear scan
        (simple, good for small maps)
      - Option B: Vec of entries + HashMap index for O(1) lookup
        with deterministic iteration order
      - Option C: BTreeMap-style sorted map
- [ ] Implement OrderedMap in `lib/std/collections.w`
- [ ] Replace unsafe (iterated) HashMaps with OrderedMap
- [ ] Verify: fixpoint still holds after each replacement
- [ ] Verify: no HashMap iteration remains in compiler source
- [ ] `make build && make fixpoint`

### P8: Errors Are Values — Poisoned Nodes

**Current state:** No Poisoned node type. Error recovery uses
token skipping + sentinel values (0, -1). Downstream phases
receive invalid data from error cases.

- [ ] Design NK_POISONED node kind:
      - Represents an AST subtree that had errors
      - Carries the original error diagnostic
      - All downstream phases must handle NK_POISONED gracefully
        (skip it, don't crash)
- [ ] Add NK_POISONED to src/Ast.w
- [ ] Update src/Parser.w: emit NK_POISONED on parse errors
      instead of returning 0 or skipping
- [ ] Update src/Resolve.w: propagate NK_POISONED (don't resolve
      names inside poisoned subtrees)
- [ ] Update src/Sema.w: propagate NK_POISONED (return TY_ERR
      for poisoned nodes without emitting duplicate errors)
- [ ] Update src/Codegen.w: skip NK_POISONED nodes (emit nothing)
- [ ] Verify: a file with parse errors produces diagnostics but
      doesn't crash in later phases
- [ ] `make build && make fixpoint`

### P11: File Complexity Budget

**Current state:** Codegen.w is 10,821 lines (2x the 5,000 line
budget). Sema.w is 5,820 lines (borderline).

- [ ] Audit Codegen.w for natural split boundaries:
      - String method codegen (~200 lines) → `src/CodegenStr.w`
      - Vec method codegen (~300 lines) → `src/CodegenVec.w`
      - HashMap method codegen (~200 lines) → `src/CodegenHashMap.w`
      - Option/Result codegen (~200 lines) → `src/CodegenOption.w`
      - Closure codegen (~800 lines) → `src/CodegenClosure.w`
      - Match codegen (~500 lines) → `src/CodegenMatch.w`
      - Async codegen → already in AsyncLower.w
- [ ] Split Codegen.w into main file + extracted modules
      (each split is a separate step with fixpoint verification)
- [ ] Split 1: extract string methods to CodegenStr.w
- [ ] `make build && make fixpoint`
- [ ] Split 2: extract Vec methods to CodegenVec.w
- [ ] `make build && make fixpoint`
- [ ] Split 3: extract HashMap methods to CodegenHashMap.w
- [ ] `make build && make fixpoint`
- [ ] Split 4: extract Option/Result methods to CodegenOption.w
- [ ] `make build && make fixpoint`
- [ ] Split 5: extract closure codegen to CodegenClosure.w
- [ ] `make build && make fixpoint`
- [ ] Split 6: extract match codegen to CodegenMatch.w
- [ ] `make build && make fixpoint`
- [ ] Verify: Codegen.w is under 5,000 lines after splits
- [ ] Audit Sema.w (5,820 lines) for potential splits if needed
- [ ] `make build && make fixpoint`

### P12: Measure, Then Optimize — Compile Time Tracking

**Current state:** No timing infrastructure. No CI.

- [ ] Add timing to Makefile: wrap stage1 and stage2 builds with
      `time` and log to `out/log/build_times.txt`
- [ ] Create `scripts/benchmark_self_compile.sh`:
      - Runs `time ./out/bin/with-stage2 build src/main.w` 3 times
      - Reports min/median/mean wall-clock time
      - Appends to `out/log/compile_time_history.csv`
- [ ] Add git hook or Makefile target to record compile time on
      each successful fixpoint
- [ ] Document baseline compile time in CONTRIBUTING.md
- [ ] Set regression threshold: warn if compile time increases >2%
      vs baseline
- [ ] `make build && make fixpoint`

### P13: Tests Verify Contracts — Phase Boundary Tests

**Current state:** All 6 dump flags implemented (--dump-tokens,
--dump-ast, --dump-resolved, --dump-typed, --dump-mir,
--dump-async-mir). No systematic phase output tests.

- [ ] Write phase output test infrastructure:
      `//! expect-dump-ast: <substring>` directive in test runner
- [ ] Add `expect-dump-ast` support to scripts/run_tests.sh
- [ ] Write 3 phase output tests for lexer (--dump-tokens):
      - Verify keyword tokens produced correctly
      - Verify string interpolation tokens
      - Verify indentation tokens
- [ ] Write 3 phase output tests for parser (--dump-ast):
      - Verify if-else AST structure
      - Verify match arm structure
      - Verify function declaration structure
- [ ] Write 3 phase output tests for sema (--dump-typed):
      - Verify type annotations on expressions
      - Verify inferred types
      - Verify error type propagation
- [ ] Write 3 phase output tests for MIR (--dump-mir):
      - Verify basic block structure
      - Verify drop insertion
      - Verify control flow flattening
- [ ] Write round-trip tests:
      `--emit-c` → C compiler → run vs LLVM backend → run
      must produce identical stdout
- [ ] Create `test/cases/roundtrip_*.w` test files:
- [ ] roundtrip_arithmetic.w — basic math
- [ ] roundtrip_strings.w — string operations
- [ ] roundtrip_structs.w — struct creation and field access
- [ ] roundtrip_enums.w — enum match and variant access
- [ ] roundtrip_closures.w — closure capture and call
- [ ] Add roundtrip test support to scripts/run_tests.sh:
      `//! roundtrip` directive compiles both ways and compares
- [ ] `make build && make fixpoint`

### P14: Reserved Syntax

**Current state:** All 5 keywords reserved (const, it, errdefer,
move, where). `const` and `it` are implemented. `where` has
parser support. `errdefer` and `move` emit errors.

- [ ] Verify `const` fully works (compile-time constants):
      write test with `const X: i32 = 42` + `println("{X}")`
- [ ] Verify `it` fully works: write test with `v.filter(it > 0)`
- [ ] Verify `where` clause parsing works or emits proper error
- [ ] Verify `errdefer` emits "reserved for future use" error
- [ ] Verify `move` closures emit "reserved for future use" error
- [ ] Audit for any other syntax that should be reserved
      (e.g., `async`, `await`, `yield`, `macro`)
- [ ] Reserve any missing keywords
- [ ] `make build && make fixpoint`

### P15: Seed Management

**Current state:** Binary seed at `src/main` (~49MB). Manual
update process. No C seed yet.

- [ ] Document current seed update process:
      1. `make fixpoint` succeeds
      2. Copy `out/bin/with-stage2` to `src/main`
      3. Commit with message "update seed"
- [ ] Add `make update-seed` target to Makefile:
      verifies fixpoint, copies stage2 to src/main
- [ ] Add safety check: refuse to update seed if tests fail
- [ ] Preserve previous seed as `src/main.prev` before overwrite
- [ ] When C backend can self-compile (Phase 5.5):
      replace binary seed with `with_compiler.c`
- [ ] `make build && make fixpoint`

---

## Non-Negotiable Verification

These must hold at all times. Run after every change.

- [ ] **Fixpoint holds:** `make fixpoint` (stage2 == stage3)
- [ ] **Tests pass:** `./scripts/run_tests.sh` — zero failures
- [ ] **No i32 fallbacks:** grep for `wl_i32_type.*fallback` in
      Codegen.w returns zero results
- [ ] **No hardcoded user-facing names:** `is_builtin_fn` and
      `is_builtin_value` deleted from sema
- [ ] **Deterministic output:** same input → same binary
      (verified by fixpoint)
- [ ] **Every error has a location:** grep for `emit_error` calls
      without span/node argument returns zero results

---

## Execution Protocol

For each change:

1. Read the relevant source before editing.
2. Make one logical change.
3. `make build`
4. Run specific test(s) if applicable.
5. Run full test suite: `./scripts/run_tests.sh`
6. `make fixpoint`

If the build breaks, stop and bisect. Do not batch changes.

**Recommended order across all docs:**

1. `docs/01_Codegen_Bug_Fixes.md` — fix silent miscompilations
2. `docs/02_Rewrite_stale_tests.md` — clean test suite
3. `docs/04_complete_partial_implementations.md` — finish features
4. `docs/06_idiomatic.md` Phase 4 — compiler quality (HashMaps,
   scope lookup, lexer cleanup)
5. `docs/05_Generics.md` — type system completion
6. `docs/06_idiomatic.md` Phases 1-3 — enum conversions, handle
   types, idiomatic patterns
7. `docs/06_idiomatic.md` Phases 5-6 — pipeline ownership,
   hardcode removal
8. `docs/07_quality.md` Phase 5 — C backend completion
9. `docs/07_quality.md` Phase 6 — tooling
10. `docs/07_quality.md` principle enforcement — determinism,
    poisoned nodes, file splits, timing

---

## Exit Gate: When Is the Quality Pass Done?

- [ ] 1. Compiler source reads as idiomatic With — enums, const,
      match, pipelines, distinct types, `it`
- [ ] 2. `Vec[i32] != Vec[str]` enforced in sema, not worked
      around in codegen
- [ ] 3. `Driver` is deleted
- [ ] 4. `--emit-c` cross-compiles the compiler for four targets
      from one machine
- [ ] 5. `with fmt` exists and the compiler source passes it
- [ ] 6. A new contributor can clone, build, test, and submit a
      fix in under 30 minutes using only CONTRIBUTING.md
- [ ] All 6 non-negotiables verified
- [ ] All tests pass under `./scripts/run_tests.sh`
- [ ] `make fixpoint` holds
