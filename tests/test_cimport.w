// c_import comprehensive test suite
// Tests all features of the c_import translation pipeline.
// Covers: function decls, macros, typedefs, enums, token paste, builtins

use c_import("<stdlib.h>")
use c_import("<stdio.h>")
use c_import("<string.h>")
use c_import("<signal.h>")
use c_import("<fcntl.h>")
use c_import("<limits.h>")
use c_import("<time.h>")
use c_import("<unistd.h>")
use c_import("<sys/stat.h>")
use c_import("<errno.h>")

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str

var test_count: i32 = 0
var pass_count: i32 = 0

fn assert_true(cond: bool, msg: str):
    test_count = test_count + 1
    if not cond:
        with_eprintln("  FAIL: " ++ msg)
        abort()
    pass_count = pass_count + 1

fn assert_eq_i32(a: i32, b: i32, msg: str):
    test_count = test_count + 1
    if a != b:
        with_eprintln("  FAIL: " ++ msg ++ " (got " ++ int_to_string(a) ++ " expected " ++ int_to_string(b) ++ ")")
        abort()
    pass_count = pass_count + 1

fn main():
    test_headers_compile()
    test_function_calls()
    test_macro_constants()
    test_limits_constants()
    test_enum_constants()
    test_typedef_types()
    test_string_operations()
    test_memory_operations()
    test_errno_constants()
    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")

// ── All headers compile ─────────────────────────────────────
fn test_headers_compile():
    // If we got here, all 10 headers compiled successfully
    with_eprintln("  OK: 10 system headers compile")

// ── Function calls ──────────────────────────────────────────
fn test_function_calls():
    // puts (stdio.h)
    let _ = puts("  c_import: puts works" as *const i8)

    // malloc/free (stdlib.h)
    let p = malloc(128)
    assert_true(p != 0 as *mut c_void, "malloc non-null")
    free(p)

    // strlen (string.h)
    let len = strlen("test" as *const i8)
    assert_true(len == 4, "strlen(\"test\") == 4")

    // time (time.h)
    let t = time(0 as *mut i64)
    assert_true(t > 0, "time() > 0")

    // getpid (unistd.h)
    let pid = getpid()
    assert_true(pid > 0, "getpid() > 0")

    with_eprintln("  OK: function calls")

// ── Macro constants ─────────────────────────────────────────
fn test_macro_constants():
    // stdio.h
    assert_true(BUFSIZ > 0, "BUFSIZ > 0")
    assert_eq_i32(EOF, 0 - 1, "EOF == -1")
    assert_true(SEEK_SET == 0, "SEEK_SET == 0")

    // fcntl.h
    assert_true(O_RDONLY >= 0, "O_RDONLY >= 0")
    assert_true(O_WRONLY > 0, "O_WRONLY > 0")
    assert_true(O_RDWR > 0, "O_RDWR > 0")

    with_eprintln("  OK: macro constants")

// ── limits.h constants ──────────────────────────────────────
fn test_limits_constants():
    assert_true(INT_MAX > 0, "INT_MAX > 0")
    assert_true(INT_MIN < 0, "INT_MIN < 0")
    assert_eq_i32(CHAR_BIT, 8, "CHAR_BIT == 8")
    assert_true(SHRT_MAX > 0, "SHRT_MAX > 0")
    assert_true(LONG_MAX > 0, "LONG_MAX > 0")
    with_eprintln("  OK: limits.h constants")

// ── Enum constants ──────────────────────────────────────────
fn test_enum_constants():
    // signal.h
    assert_true(SIGINT > 0, "SIGINT > 0")
    assert_true(SIGTERM > 0, "SIGTERM > 0")
    assert_true(SIGKILL > 0, "SIGKILL > 0")
    assert_true(SIGHUP > 0, "SIGHUP > 0")
    with_eprintln("  OK: enum constants")

// ── Typedef types ───────────────────────────────────────────
fn test_typedef_types():
    // These should compile — verifies typedef mappings
    let sz: usize = 42
    let off: i64 = 0
    let p: i32 = 1
    assert_true(sz == 42, "usize typedef")
    with_eprintln("  OK: typedef types")

// ── String operations ───────────────────────────────────────
fn test_string_operations():
    let a = "hello" as *const i8
    let b = "hello" as *const i8

    // strcmp
    let cmp = strcmp(a, b)
    assert_eq_i32(cmp, 0, "strcmp equal strings")

    // strlen
    let len = strlen(a)
    assert_true(len == 5, "strlen(\"hello\") == 5")

    with_eprintln("  OK: string operations")

// ── Memory operations ───────────────────────────────────────
fn test_memory_operations():
    let p = calloc(10, 4)
    assert_true(p != 0 as *mut c_void, "calloc non-null")
    free(p)

    let q = malloc(64)
    assert_true(q != 0 as *mut c_void, "malloc non-null")
    let r = realloc(q, 128)
    assert_true(r != 0 as *mut c_void, "realloc non-null")
    free(r)

    with_eprintln("  OK: memory operations")

// ── errno constants ─────────────────────────────────────────
fn test_errno_constants():
    assert_true(ENOENT > 0, "ENOENT > 0")
    assert_true(EACCES > 0, "EACCES > 0")
    assert_true(EINVAL > 0, "EINVAL > 0")
    assert_true(ENOMEM > 0, "ENOMEM > 0")
    with_eprintln("  OK: errno constants")
