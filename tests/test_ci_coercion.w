use c_import("coercion_test.h")
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

fn assert_eq(a: i32, b: i32, msg: str):
    test_count = test_count + 1
    if a == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg ++ " (got " ++ int_to_string(a) ++ " expected " ++ int_to_string(b) ++ ")")

fn main:
    with_eprintln("=== c_import auto-coercion tests ===")

    // bool → c_int parameter coercion
    let r = coercion_bool_to_int(true)
    assert_eq(r, 1, "bool true → c_int 1")
    let r2 = coercion_bool_to_int(false)
    assert_eq(r2, 0, "bool false → c_int 0")

    // void* → str return coercion
    let s: str = coercion_get_str()
    assert_true(s.len() > 0, "void* → str non-empty")

    // null void* → empty string
    let n: str = coercion_get_null()
    assert_true(n.len() == 0, "null void* → empty str")

    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")
    if fail_count > 0:
        with_eprintln(int_to_string(fail_count) ++ " FAILURES")
        abort()
    with_eprintln("ALL PASSED")
