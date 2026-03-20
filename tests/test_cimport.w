// c_import comprehensive test suite
// Tests all features of the c_import translation pipeline.

// Import system headers for testing
use c_import("<stdlib.h>")
use c_import("<stdio.h>")
use c_import("<string.h>")
use c_import("<signal.h>")
use c_import("<fcntl.h>")
use c_import("<limits.h>")

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str

fn assert_true(cond: bool, msg: str):
    if not cond:
        with_eprintln("FAIL: " ++ msg)
        abort()

fn assert_eq_i32(a: i32, b: i32, msg: str):
    if a != b:
        with_eprintln("FAIL: " ++ msg ++ " (got " ++ int_to_string(a) ++ " expected " ++ int_to_string(b) ++ ")")
        abort()

fn main():
    test_function_declarations()
    test_macro_constants()
    test_enum_constants()
    test_string_functions()
    with_eprintln("All c_import tests passed!")

fn test_function_declarations():
    // stdio.h — puts
    let msg = "  c_import function call works"
    let _ = puts(msg as *const i8)

    // stdlib.h (via stdio.h) — malloc/free
    let p = malloc(64)
    assert_true(p != 0 as *mut c_void, "malloc returned non-null")
    free(p)

    with_eprintln("  OK: function declarations")

fn test_macro_constants():
    // stdio.h
    assert_true(BUFSIZ > 0, "BUFSIZ > 0")
    assert_eq_i32(EOF, 0 - 1, "EOF == -1")

    // limits.h
    assert_true(INT_MAX > 0, "INT_MAX > 0")
    assert_true(INT_MIN < 0, "INT_MIN < 0")
    assert_true(CHAR_BIT == 8, "CHAR_BIT == 8")

    // fcntl.h
    assert_true(O_RDONLY >= 0, "O_RDONLY >= 0")

    with_eprintln("  OK: macro constants")

fn test_enum_constants():
    // signal.h
    assert_true(SIGINT > 0, "SIGINT > 0")
    assert_true(SIGTERM > 0, "SIGTERM > 0")

    with_eprintln("  OK: enum constants")

fn test_string_functions():
    // string.h — strlen
    let s = "hello"
    let len = strlen(s as *const i8)
    assert_true(len == 5, "strlen works")

    with_eprintln("  OK: string functions")
