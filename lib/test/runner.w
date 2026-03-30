// lib/test/runner — With test runner
//
// Provides test lifecycle management.
// Test functions should call abort() on failure (via assert_* from testing.w).
// If a test function returns normally, it passed.

use c_import("stdio.h")

// ── Test runner ─────────────────────────────────────────────────

// Print test session header.
pub fn begin() -> void:
    write("--- Test Session ---")

// Run a single test function. Prints name and "ok" on success.
// If the test calls abort(), the process exits before "ok" is printed.
pub fn run_test(name: str, test_fn: fn() -> void) -> void:
    write("  ")
    write(name)
    write("... ")
    test_fn()
    write("ok")

// Print session footer with the given counts.
pub fn summary(passed: i32, total: i32) -> i32:
    write("---")
    write(passed)
    write(" passed, ")
    write(total - passed)
    write(" failed, ")
    write(total)
    write(" total")
    if passed == total then 0 else 1
