// test_operators.w — Tests for operators, string interpolation, drop, and overloading.

use c_import("<stdlib.h>")

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str

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

fn assert_eq_str(a: str, b: str, msg: str):
    test_count = test_count + 1
    if a == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg ++ " (got '" ++ a ++ "' expected '" ++ b ++ "')")

// ── Bitwise NOT ─────────────────────────────────────────────────

fn test_bitwise_not:
    assert_eq(~0, -1, "~0 == -1")
    assert_eq(~(-1), 0, "~(-1) == 0")
    assert_eq(~0xFF, -256, "~0xFF")

// ── Compound assignment ─────────────────────────────────────────

fn test_compound_assign:
    // Bitwise compound assignment
    var x = 0xFF
    x &= 0x0F
    assert_eq(x, 0x0F, "&= operator")
    x |= 0xF0
    assert_eq(x, 0xFF, "|= operator")
    x ^= 0x0F
    assert_eq(x, 0xF0, "^= operator")
    x <<= 4
    assert_eq(x, 0xF00, "<<= operator")
    x >>= 8
    assert_eq(x, 0x0F, ">>= operator")

    // Arithmetic compound assignment
    var y = 10
    y += 5
    assert_eq(y, 15, "+= operator")
    y -= 3
    assert_eq(y, 12, "-= operator")
    y *= 2
    assert_eq(y, 24, "*= operator")
    y /= 6
    assert_eq(y, 4, "/= operator")
    y %= 3
    assert_eq(y, 1, "%= operator")

// ── Wrapping operators ──────────────────────────────────────────

fn test_wrapping:
    let max: i32 = 2147483647
    let wrapped = max +% 1
    assert_eq(wrapped, -2147483648, "+% wrapping overflow")

    let min: i32 = -2147483648
    let wrapped2 = min -% 1
    assert_eq(wrapped2, 2147483647, "-% wrapping underflow")

// ── String interpolation (f-strings) ────────────────────────────

fn test_fstrings:
    let name = "world"
    assert_eq_str(f"hello {name}!", "hello world!", "f-string variable")

    let a = "foo"
    let b = "bar"
    assert_eq_str(f"{a} and {b}", "foo and bar", "f-string multiple vars")

    // Plain strings don't interpolate
    let plain = "hello {name}"
    assert_eq_str(plain, "hello {name}", "plain string no interpolation")

// ── Operator overloading ────────────────────────────────────────

type V2 = { x: i32, y: i32 }

fn V2.add(self: V2, other: V2) -> V2:
    V2 { x: self.x + other.x, y: self.y + other.y }

fn V2.sub(self: V2, other: V2) -> V2:
    V2 { x: self.x - other.x, y: self.y - other.y }

fn test_op_overload:
    let a = V2 { x: 1, y: 2 }
    let b = V2 { x: 3, y: 4 }
    let c = a + b
    assert_eq(c.x, 4, "overloaded + x")
    assert_eq(c.y, 6, "overloaded + y")
    let d = b - a
    assert_eq(d.x, 2, "overloaded - x")
    assert_eq(d.y, 2, "overloaded - y")

// ── Drop on var reassignment ────────────────────────────────────

var drop_count: i32 = 0

type Tracked = { id: i32 }

fn Tracked.drop(self: Tracked):
    drop_count = drop_count + 1

fn test_drop_reassign:
    drop_count = 0
    var t = Tracked { id: 1 }
    t = Tracked { id: 2 }  // should drop first Tracked
    assert_eq(drop_count, 1, "drop on var reassignment")

// ── Main ────────────────────────────────────────────────────────

fn main:
    with_eprintln("=== operator/feature test suite ===")

    test_bitwise_not()
    test_compound_assign()
    test_wrapping()
    test_fstrings()
    test_op_overload()
    test_drop_reassign()

    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")
    if fail_count > 0:
        with_eprintln(int_to_string(fail_count) ++ " FAILURES")
        abort()
    with_eprintln("ALL PASSED")
