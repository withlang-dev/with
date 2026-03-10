Rewrite Stale Tests
Goal: Convert 31 tests that import internal compiler modules
into end-to-end tests using the test runner's directive system.
Scope: Only test files. No compiler changes. This is mechanical
rewriting.
Pattern: Each old test calls internal APIs to invoke sema/codegen
and checks results programmatically. Each new test is a .w file
with //! directives that the test runner validates.
How to convert
Error message tests (16 tests: err_assign_immutable,
err_binop_types, err_borrow_conflict, etc.):
Write a .w file that triggers the error, use directive:
//! expect-check-fail
//! expect-error: assign to immutable variable
let x = 5
x = 10
Compiler internal tests (13 tests: ast_test, lexer_test,
parser_test, sema_test, etc.):
Convert to end-to-end tests that compile and run programs
exercising the relevant feature:
//! expect-stdout: 42
fn main:
    let x = 40 + 2
    println("{x}")
For tests that specifically test internal data structures (intern
pool, arena, etc.), either delete them (the fixpoint test proves
these work) or convert to programs that exercise the behavior
from the outside.
Integration tests (2 tests: integ_full_pipeline,
integ_multi_module):
Convert to multi-file build tests that compile and run programs
with multiple modules.
Checklist

 Convert all 16 err_* tests to //! expect-check-fail tests
 Convert all 13 compiler internal tests to end-to-end tests
 Convert 2 integration tests to multi-file build tests
 Delete any tests that are now redundant (e.g., ast_test
testing pool internals that fixpoint already validates)
 All 31 converted tests pass under scripts/run_tests.sh

Exit gate
Zero stale-API test failures. All converted tests exercise real
compiler behavior through the CLI.