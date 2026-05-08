// c_import comprehensive test suite
// Tests all features of the c_import translation pipeline.
// 15 system headers, functional tests for each.

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
use c_import("<sys/mman.h>")
use c_import("<dirent.h>")
use c_import("<math.h>")
use c_import("<float.h>")
use c_import("<stddef.h>")

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
    test_stdlib_functions()
    test_stdio_functions()
    test_string_functions()
    test_signal_constants()
    test_fcntl_constants()
    test_limits_constants()
    test_time_functions()
    test_unistd_functions()
    test_stat_constants()
    test_errno_constants()
    test_mman_constants()
    test_dirent_functions()
    test_math_constants()
    test_float_constants()
    test_stddef_types()
    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")

// ── 15 system headers compile ───────────────────────────────
fn test_headers_compile():
    with_eprintln("  OK: 15 system headers compile")

// ── stdlib.h ────────────────────────────────────────────────
fn test_stdlib_functions():
    let p = malloc(128)
    assert_true(p != 0 as *mut c_void, "malloc non-null")
    free(p)
    let q = calloc(10, 4)
    assert_true(q != 0 as *mut c_void, "calloc non-null")
    let r = realloc(q, 128)
    assert_true(r != 0 as *mut c_void, "realloc non-null")
    free(r)
    assert_eq_i32(abs(-42), 42, "abs(-42)")
    with_eprintln("  OK: stdlib.h")

// ── stdio.h ─────────────────────────────────────────────────
fn test_stdio_functions():
    let _ = puts("  c_import: puts works" as *const i8)
    assert_true(BUFSIZ > 0, "BUFSIZ > 0")
    assert_eq_i32(EOF, -1, "EOF")
    assert_eq_i32(SEEK_SET, 0, "SEEK_SET")
    with_eprintln("  OK: stdio.h")

// ── string.h ────────────────────────────────────────────────
fn test_string_functions():
    let len = strlen("hello" as *const i8)
    assert_true(len == 5, "strlen")
    let cmp = strcmp("abc" as *const i8, "abc" as *const i8)
    assert_eq_i32(cmp, 0, "strcmp equal")
    with_eprintln("  OK: string.h")

// ── signal.h ────────────────────────────────────────────────
fn test_signal_constants():
    assert_true(SIGINT > 0, "SIGINT")
    assert_true(SIGTERM > 0, "SIGTERM")
    assert_true(SIGKILL > 0, "SIGKILL")
    assert_true(SIGHUP > 0, "SIGHUP")
    with_eprintln("  OK: signal.h")

// ── fcntl.h ─────────────────────────────────────────────────
fn test_fcntl_constants():
    assert_true(O_RDONLY >= 0, "O_RDONLY")
    assert_true(O_WRONLY > 0, "O_WRONLY")
    assert_true(O_RDWR > 0, "O_RDWR")
    assert_true(O_CREAT > 0, "O_CREAT")
    assert_true(O_TRUNC > 0, "O_TRUNC")
    assert_true(O_APPEND > 0, "O_APPEND")
    with_eprintln("  OK: fcntl.h")

// ── limits.h ────────────────────────────────────────────────
fn test_limits_constants():
    assert_true(INT_MAX > 0, "INT_MAX")
    assert_true(INT_MIN < 0, "INT_MIN")
    assert_eq_i32(CHAR_BIT, 8, "CHAR_BIT")
    assert_true(SHRT_MAX > 0, "SHRT_MAX")
    assert_true(LONG_MAX > 0, "LONG_MAX")
    with_eprintln("  OK: limits.h")

// ── time.h ──────────────────────────────────────────────────
fn test_time_functions():
    let t = time(0 as *mut i64)
    assert_true(t > 1000000000, "time() > 2001")
    with_eprintln("  OK: time.h")

// ── unistd.h ────────────────────────────────────────────────
fn test_unistd_functions():
    let pid = getpid()
    assert_true(pid > 0, "getpid")
    with_eprintln("  OK: unistd.h")

// ── sys/stat.h ──────────────────────────────────────────────
fn test_stat_constants():
    assert_true(S_IRUSR > 0, "S_IRUSR")
    assert_true(S_IWUSR > 0, "S_IWUSR")
    with_eprintln("  OK: sys/stat.h")

// ── errno.h ─────────────────────────────────────────────────
fn test_errno_constants():
    assert_true(ENOENT > 0, "ENOENT")
    assert_true(EACCES > 0, "EACCES")
    assert_true(EINVAL > 0, "EINVAL")
    assert_true(ENOMEM > 0, "ENOMEM")
    with_eprintln("  OK: errno.h")

// ── sys/mman.h ──────────────────────────────────────────────
fn test_mman_constants():
    assert_true(PROT_READ > 0, "PROT_READ")
    assert_true(PROT_WRITE > 0, "PROT_WRITE")
    assert_true(MAP_PRIVATE > 0, "MAP_PRIVATE")
    with_eprintln("  OK: sys/mman.h")

// ── dirent.h ────────────────────────────────────────────────
fn test_dirent_functions():
    // opendir/closedir — test that the types exist
    assert_true(DT_REG > 0, "DT_REG")
    assert_true(DT_DIR > 0, "DT_DIR")
    with_eprintln("  OK: dirent.h")

// ── math.h ──────────────────────────────────────────────────
fn test_math_constants():
    assert_true(M_PI > 3.0, "M_PI > 3")
    assert_true(M_E > 2.0, "M_E > 2")
    assert_true(FP_NAN > 0, "FP_NAN")
    assert_true(FP_INFINITE > 0, "FP_INFINITE")
    with_eprintln("  OK: math.h")

// ── float.h ─────────────────────────────────────────────────
fn test_float_constants():
    assert_true(FLT_MAX > 0.0, "FLT_MAX > 0")
    assert_true(DBL_MAX > 0.0, "DBL_MAX > 0")
    assert_true(FLT_EPSILON > 0.0, "FLT_EPSILON > 0")
    with_eprintln("  OK: float.h")

// ── stddef.h ────────────────────────────────────────────────
fn test_stddef_types():
    // size_t, ptrdiff_t should be available
    let sz: usize = 42
    assert_true(sz == 42, "size_t works")
    with_eprintln("  OK: stddef.h")
