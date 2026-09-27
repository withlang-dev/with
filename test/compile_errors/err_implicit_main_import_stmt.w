//! expect-build-fail: module 'test/compile_errors/lib/implicit_main/bad_import.w' holds an executable statement at its top level
// §18.5b (D74): an imported module may not hold executable statements; the
// error names the module and the statement.

use implicit_main.bad_import

fn main:
    print("ok")
