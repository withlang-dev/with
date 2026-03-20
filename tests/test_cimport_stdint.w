// Test stdint.h separately (can conflict with stdlib.h due to transitive includes)
// Tests: token pasting macros (INT64_C, UINT32_C, UINT64_C)

use c_import("<stdint.h>")
use c_import("<stdlib.h>")

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str

var test_count: i32 = 0
var pass_count: i32 = 0

fn assert_true(cond: bool, msg: str):
    test_count = test_count + 1
    if not cond:
        with_eprintln("  FAIL: " ++ msg)
        abort()
    pass_count = pass_count + 1

fn main():
    // Token paste macros (## suffix patterns)
    let a = INT64_C(42)
    assert_true(a == 42, "INT64_C(42) == 42")

    let b = UINT32_C(100)
    assert_true(b == 100, "UINT32_C(100) == 100")

    let c = UINT64_C(999)
    assert_true(c == 999, "UINT64_C(999) == 999")

    // Stdint type size constants
    assert_true(INT8_MAX == 127, "INT8_MAX == 127")
    assert_true(INT16_MAX == 32767, "INT16_MAX == 32767")
    assert_true(INT32_MAX == 2147483647, "INT32_MAX == 2147483647")
    assert_true(UINT8_MAX == 255, "UINT8_MAX == 255")
    assert_true(UINT16_MAX == 65535, "UINT16_MAX == 65535")

    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " stdint tests passed")
