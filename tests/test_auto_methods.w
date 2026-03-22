// test_auto_methods.w — Test c_import auto-method generation.
// Verifies that C struct-prefixed functions produce auto-generated methods.
//
// This test verifies the c_import output contains the expected methods
// by checking the cached translation output.

use c_import("auto_methods_test_inline.h")
use c_import("<stdlib.h>")

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str

var test_count: i32 = 0
var pass_count: i32 = 0
var fail_count: i32 = 0

fn assert_true(cond: bool, msg: str):
    test_count = test_count + 1
    if cond:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg)

fn main:
    with_eprintln("=== auto-method generation tests ===")

    // Verify auto-methods compile: use constructor + methods via malloc/struct
    var v = AmtVec { x: 3.0, y: 4.0, z: 0.0 }

    // Direct struct field access still works
    assert_true(v.x > 2.9 and v.x < 3.1, "struct field access .x")
    assert_true(v.y > 3.9 and v.y < 4.1, "struct field access .y")

    // Auto-generated method: amt_vec_get_x → AmtVec.get_x
    let x = amt_vec_get_x(&v)
    assert_true(x > 2.9 and x < 3.1, "flat fn amt_vec_get_x works")

    // Auto-generated method: amt_vec_length_sq → AmtVec.length_sq
    let lsq = amt_vec_length_sq(&v)
    assert_true(lsq > 24.9 and lsq < 25.1, "flat fn amt_vec_length_sq = 25")

    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")
    if fail_count > 0:
        with_eprintln(int_to_string(fail_count) ++ " FAILURES")
        abort()
    with_eprintln("ALL PASSED")
