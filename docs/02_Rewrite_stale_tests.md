# 02 — Rewrite Stale Tests

Goal: Convert every test in `test/cases/` that imports internal
compiler modules into an end-to-end test using CLI directives.
No compiler changes. Only test files.

Scope: 27 stale tests in `test/cases/`. Wave 1–3 tests are
separate (they test the `compiler.foundation.*` rewrite and will
be addressed when that work lands).

---

## How the Test Runner Works

`scripts/run_tests.sh` scans `test/cases/*.w` and parses header
directives:

```
//! expect-stdout: <text>        build+run, check stdout substring
//! expect-check-fail: <msg>     check must fail, stderr contains <msg>
//! expect-error: <msg>          alias for expect-check-fail
//! expect-build-fail: <msg>     build must fail, stderr contains <msg>
//! check-only                   check only, no build/run
//! args: <flags>                extra compiler flags
```

Every new test must use these directives. No test may import
internal compiler modules (`use Ast`, `use Sema`, `use Types`,
`use Mir`, `use Codegen`, `use Driver`, etc.).

---

## Pass 1: Delete Redundant Tests

These tests verify internal constants or data structures already
validated by fixpoint (`stage2 == stage3`). Delete outright.

- [ ] Delete `test/cases/ast_test.w` (tests AstPool node storage internals)
- [ ] Delete `test/cases/intern_test.w` (tests InternPool symbol dedup internals)
- [ ] Delete `test/cases/codegen_test.w` (tests LLVM type IDs, instruction opcodes)
- [ ] Delete `test/cases/mir_test.w` (tests MirBody, basic blocks, terminators)
- [ ] Delete `test/cases/safety_checks.w` (tests MIR terminator kind constants)
- [ ] Delete `test/cases/driver_test.w` (tests SourceFile, CImport, render, Driver internals)
- [ ] Delete `test/cases/err_diag_codes.w` (tests `E_UNDECLARED == 1` etc.)
- [ ] Delete `test/cases/lexer_test.w` (redundant with hundreds of behavior tests)
- [ ] Delete `test/cases/parser_test.w` (redundant — fixpoint is ultimate parser validation)
- [ ] Run `./scripts/run_tests.sh` — confirm no regressions after deletions

---

## Pass 2: Rewrite Error Tests

Each test currently constructs Sema/TypeTable/AstPool objects
directly. Rewrite as a `.w` program the user would write that
triggers the same error via `//! expect-check-fail`.

### 2.1 err_assign_immutable.w

Current: Creates Sema, calls `define_var` with `is_mut=0`, checks `var_is_mut`.

- [ ] Read current `test/cases/err_assign_immutable.w`
- [ ] Rewrite as program that assigns to immutable variable:
      `//! expect-check-fail: immutable` + `let x = 5` then `x = 10`
- [ ] Optionally create `behav_mutability.w` for the success case
      (`let mut x = 5; x = 10; println("{x}")` → `//! expect-stdout: 10`)
- [ ] Run `./scripts/run_tests.sh test/cases/err_assign_immutable.w` — passes

### 2.2 err_binop_types.w

Current: Constructs AST nodes for `i32 + i32`, `i32 == i32`, `bool && bool`, checks types.

- [ ] Read current `test/cases/err_binop_types.w`
- [ ] Rewrite as end-to-end program exercising binary operations:
      `//! expect-stdout: 3` + arithmetic, comparison, logical ops
- [ ] Run `./scripts/run_tests.sh test/cases/err_binop_types.w` — passes

### 2.3 err_borrow_conflict.w

Current: Constructs MirBody, adds borrows, runs BorrowChecker, checks error counts.

- [ ] Read current `test/cases/err_borrow_conflict.w`
- [ ] Rewrite as program with borrow conflict:
      `//! expect-check-fail: borrow` + shared ref then mutation
- [ ] If compiler doesn't detect this yet, use `//! expect-stdout` test
      showing borrows work + add TODO comment for negative test
- [ ] Run `./scripts/run_tests.sh test/cases/err_borrow_conflict.w` — passes

### 2.4 err_invalid_cast.w

Current: Calls `cast_instruction(types, TYPE_I32, TYPE_I64)`, checks return values.

- [ ] Read current `test/cases/err_invalid_cast.w`
- [ ] Rewrite as program with invalid cast:
      `//! expect-check-fail: cast` + `let s = "hello"; let x = s as i32`
- [ ] Run `./scripts/run_tests.sh test/cases/err_invalid_cast.w` — passes

### 2.5 err_match_str_exhaust.w

Current: Checks `TypeTable.is_enum`, `TypeTable.is_bool`, pattern node kind constants.

- [ ] Read current `test/cases/err_match_str_exhaust.w`
- [ ] Rewrite as program with non-exhaustive match on string:
      `//! expect-check-fail: exhaustive` + match with no wildcard
- [ ] Run `./scripts/run_tests.sh test/cases/err_match_str_exhaust.w` — passes

### 2.6 err_return_type.w

Current: Sets `s.current_return_type = TYPE_I32`, checks `types_compatible`.

- [ ] Read current `test/cases/err_return_type.w`
- [ ] Rewrite as program with return type mismatch:
      `//! expect-check-fail: type` + `fn get_num() -> i32: "not a number"`
- [ ] Run `./scripts/run_tests.sh test/cases/err_return_type.w` — passes

### 2.7 err_trait_bound.w

Current: Creates TraitSolver, adds traits/impls, checks resolve and obligations.

- [ ] Read current `test/cases/err_trait_bound.w`
- [ ] Rewrite as program with trait bound violation:
      `//! expect-check-fail: trait` + call requiring trait not implemented
- [ ] If compiler doesn't produce this error yet, use simpler trait test
      + add TODO for the negative case
- [ ] Run `./scripts/run_tests.sh test/cases/err_trait_bound.w` — passes

### 2.8 err_type_mismatch.w

Current: Checks `types_compatible(TYPE_I32, TYPE_STR)` etc.

- [ ] Read current `test/cases/err_type_mismatch.w`
- [ ] Rewrite as program with type mismatch:
      `//! expect-check-fail: type` + `let x: i32 = "hello"`
- [ ] Run `./scripts/run_tests.sh test/cases/err_type_mismatch.w` — passes

### 2.9 err_undefined_fn.w

Current: Checks `Sema.find_fn(s, "foo") == -1`.

- [ ] Read current `test/cases/err_undefined_fn.w`
- [ ] Rewrite as program calling undefined function:
      `//! expect-check-fail: undefined` + `fn main: foo()`
- [ ] Run `./scripts/run_tests.sh test/cases/err_undefined_fn.w` — passes

### 2.10 err_undefined_type.w

Current: Checks `TypeTable.lookup(types, "NoSuchType") == -1`.

- [ ] Read current `test/cases/err_undefined_type.w`
- [ ] Rewrite as program using undefined type:
      `//! expect-check-fail: undefined` + `let x: NoSuchType = 42`
- [ ] Run `./scripts/run_tests.sh test/cases/err_undefined_type.w` — passes

### 2.11 err_undefined_var.w

Current: Constructs AST ident for "unknown", checks `TYPE_ERROR`.

- [ ] Read current `test/cases/err_undefined_var.w`
- [ ] Rewrite as program using undefined variable:
      `//! expect-check-fail: undefined` + `fn main: println(x)`
- [ ] Run `./scripts/run_tests.sh test/cases/err_undefined_var.w` — passes

### 2.12 err_wrong_arg_count.w

Current: Registers function with 2 params, checks `fn_param_counts`.

- [ ] Read current `test/cases/err_wrong_arg_count.w`
- [ ] Rewrite as program calling function with wrong arg count:
      `//! expect-check-fail: argument` + `fn add(a: i32, b: i32) -> i32: a + b`
      then `add(1)`
- [ ] Run `./scripts/run_tests.sh test/cases/err_wrong_arg_count.w` — passes

### Pass 2 verification

- [ ] Run `./scripts/run_tests.sh` — all error tests pass

---

## Pass 3: Rewrite Internal & Integration Tests

### 3.1 sema_test.w → behav_sema_basics.w

Current: 10 test functions checking builtin types, scope chains, function
registration, type compatibility, expression type checking, variant lookup.

- [ ] Read current `test/cases/sema_test.w`
- [ ] Write `test/cases/behav_sema_basics.w` exercising scope chains:
      `//! expect-stdout: 10` + nested scope with let bindings
- [ ] Add variant lookup test: enum declaration, match, correct output
- [ ] Delete `test/cases/sema_test.w`
- [ ] Run `./scripts/run_tests.sh test/cases/behav_sema_basics.w` — passes

### 3.2 type_test.w → behav_type_system.w

Current: 18 test functions covering struct/enum/array/slice/tuple/fn/ptr/ref/
alias/option/result types, equality, generics, trait objects, scopes.

- [ ] Read current `test/cases/type_test.w`
- [ ] Write `test/cases/behav_type_system.w` with struct test:
      type declaration, field access, `//! expect-stdout` verification
- [ ] Add enum test: variant construction, match, payload extraction
- [ ] Add tuple test: tuple literal, field access by index
- [ ] Add array test: array literal, `.len()` call
- [ ] Delete `test/cases/type_test.w`
- [ ] Run `./scripts/run_tests.sh test/cases/behav_type_system.w` — passes

### 3.3 borrow_test.w → behav_borrow_basic.w

Current: Tests BorrowInfo, NllRegion, BorrowChecker on manually-constructed MIR.

- [ ] Read current `test/cases/borrow_test.w`
- [ ] Write `test/cases/behav_borrow_basic.w` exercising borrows:
      `//! expect-stdout: ok` + shared borrow that compiles and runs
- [ ] If borrow checker catches conflicts at check time, add negative test
      `err_borrow_mut.w` with `//! expect-check-fail: borrow`
- [ ] Delete `test/cases/borrow_test.w`
- [ ] Run `./scripts/run_tests.sh test/cases/behav_borrow_basic.w` — passes

### 3.4 traits_test.w → behav_trait_basics.w

Current: Tests TraitSolver (trait definition, impl registration, resolve,
coherence, obligation lists).

- [ ] Read current `test/cases/traits_test.w`
- [ ] Write `test/cases/behav_trait_basics.w` with trait + impl + method call:
      `//! expect-stdout: hello` + trait definition, struct impl, method call
- [ ] Delete `test/cases/traits_test.w`
- [ ] Run `./scripts/run_tests.sh test/cases/behav_trait_basics.w` — passes

### 3.5 integ_full_pipeline.w — rewrite in place

Current: Manually constructs AST, runs each compiler phase, checks results.

- [ ] Read current `test/cases/integ_full_pipeline.w`
- [ ] Rewrite as real program exercising the full pipeline:
      `//! expect-stdout: 42` + nested function, if/else, arithmetic
- [ ] Run `./scripts/run_tests.sh test/cases/integ_full_pipeline.w` — passes

### 3.6 integ_multi_module.w — rewrite in place

Current: Imports every compiler module, creates one instance of each.

- [ ] Read current `test/cases/integ_multi_module.w`
- [ ] Check how existing multi-file tests work (e.g., `shadow_helper.w`)
- [ ] Create `test/cases/integ_helper_module.w` with `//! check-only` +
      `pub fn add(a: i32, b: i32) -> i32: a + b`
- [ ] Rewrite `test/cases/integ_multi_module.w`:
      `//! expect-stdout: 3` + `use integ_helper_module` + `println("{add(1, 2)}")`
- [ ] If `use` path resolution doesn't support relative test imports,
      make it a single-file test instead
- [ ] Run `./scripts/run_tests.sh test/cases/integ_multi_module.w` — passes

### Pass 3 verification

- [ ] Run `./scripts/run_tests.sh` — all tests pass

---

## Final Verification

- [ ] Run: `grep -r "^use " test/cases/*.w | grep -E "(Ast|Sema|Types|Mir|Codegen|Driver|BorrowCfg|Lexer|Token|Parser|InternPool|Source|CImport|render|Span|Diag|MirLower)"` — prints nothing
- [ ] Run `./scripts/run_tests.sh` — zero failures
- [ ] Every rewritten error test triggers the expected diagnostic through normal compilation
- [ ] Every rewritten behavior test builds, runs, and produces correct output
