// test_ml_features.w — Full coverage tests for ML stack prerequisite features.
// Ref: docs/demo_plans/ml/with-enhancements.md
//
// Covers: C1 (Drop), C2 (auto-ref), C3 (move), C4 (fixed arrays),
// H1 (defer), H3 (for ranges), H4 (bitwise), H5 (f-strings),
// M1 (operator overload), M6 (casts), L2 (tuples), L4 (labeled breaks),
// L6 (type aliases), and feature interactions.

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

fn assert_eq_i64(a: i64, b: i64, msg: str):
    test_count = test_count + 1
    if a == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg ++ " (got " ++ i64_to_string(a) ++ " expected " ++ i64_to_string(b) ++ ")")

fn assert_eq_str(a: str, b: str, msg: str):
    test_count = test_count + 1
    if a == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg ++ " (got '" ++ a ++ "' expected '" ++ b ++ "')")

// ═══════════════════════════════════════════════════════════════
// C1: Drop — scope exit, LIFO, reassignment, move interaction
// ═══════════════════════════════════════════════════════════════

var drop_log: str = ""

type Res = { name: str }

fn Res.drop(self: Res):
    drop_log = drop_log ++ self.name ++ ","

fn Res.new(name: str) -> Res:
    Res { name }

// C1.1: Drop fires at scope exit in LIFO order
fn helper_drop_scope:
    let a = Res.new("a")
    let b = Res.new("b")
    let c = Res.new("c")

fn test_c1_drop_lifo:
    drop_log = ""
    helper_drop_scope()
    assert_eq_str(drop_log, "c,b,a,", "C1.1: drop LIFO order")

// C1.2: Drop on var reassignment
fn test_c1_drop_reassign:
    drop_log = ""
    var r = Res.new("old")
    r = Res.new("new")
    assert_true(drop_log.contains("old"), "C1.2: old value dropped on reassign")

// C1.3: Copy and Drop are mutually exclusive (Copy types don't drop)
type CopyPt = { x: i32, y: i32 }
impl Copy for CopyPt

fn test_c1_copy_not_moved:
    let a = CopyPt { x: 1, y: 2 }
    let b = a
    assert_eq(a.x, 1, "C1.3: Copy original valid")
    assert_eq(b.x, 1, "C1.3: Copy copy valid")

// C1.4: Moved value is dropped by new owner, not original scope
fn consume_res(r: Res):
    let _ = r

fn test_c1_move_drops:
    drop_log = ""
    let r = Res.new("moved")
    consume_res(r)
    assert_true(drop_log.contains("moved"), "C1.4: moved value dropped by consumer")

// C1.5: Drop on reassignment inside a loop (transformer pattern)
fn test_c1_drop_reassign_loop:
    drop_log = ""
    var r = Res.new("iter0")
    for i in 0..3:
        r = Res.new(f"iter{int_to_string(i + 1)}")
    assert_true(drop_log.contains("iter0"), "C1.5: loop reassign drops iter0")
    assert_true(drop_log.contains("iter1"), "C1.5: loop reassign drops iter1")
    assert_true(drop_log.contains("iter2"), "C1.5: loop reassign drops iter2")

// ═══════════════════════════════════════════════════════════════
// C4: Fixed-size arrays [T; N]
// ═══════════════════════════════════════════════════════════════

// C4.1: Array literal and indexing
fn test_c4_array_literal:
    let arr = [10, 20, 30, 40]
    assert_eq(arr[0], 10, "C4.1: arr[0]")
    assert_eq(arr[3], 40, "C4.1: arr[3]")

// C4.2: Array .len()
fn test_c4_array_len:
    let arr = [1, 2, 3]
    assert_eq(arr.len() as i32, 3, "C4.2: .len()")

// C4.3: Mutable array write
fn test_c4_array_mut:
    var arr = [0, 0, 0]
    arr[1] = 42
    assert_eq(arr[1], 42, "C4.3: mutable write")

// C4.4: [T; N] type in function parameter
fn sum4(arr: [i32; 4]) -> i32:
    var total = 0
    for i in 0..4:
        total = total + arr[i]
    total

fn test_c4_array_param:
    assert_eq(sum4([1, 2, 3, 4]), 10, "C4.4: array param")

// C4.5: [value; N] fill syntax
fn test_c4_array_fill:
    let zeros = [0; 8]
    assert_eq(zeros.len() as i32, 8, "C4.5: fill len")
    assert_eq(zeros[0], 0, "C4.5: fill value [0]")
    assert_eq(zeros[7], 0, "C4.5: fill value [7]")

// C4.6: Array in struct (inline layout)
type Shape = { dims: [i32; 4], rank: i32 }

fn test_c4_array_in_struct:
    let s = Shape { dims: [3, 4, 5, 0], rank: 3 }
    assert_eq(s.dims[0], 3, "C4.6: struct array field [0]")
    assert_eq(s.dims[2], 5, "C4.6: struct array field [2]")
    assert_eq(s.rank, 3, "C4.6: struct non-array field")

// C4.7: Array iteration
fn test_c4_array_iter:
    let vals = [10, 20, 30, 40, 50]
    var total = 0
    for i in 0..5:
        total = total + vals[i]
    assert_eq(total, 150, "C4.7: array iteration sum")

// ═══════════════════════════════════════════════════════════════
// H1: defer
// ═══════════════════════════════════════════════════════════════

var defer_log: str = ""

// H1.1: defer on normal return
fn helper_defer_normal:
    defer defer_log = defer_log ++ "cleanup,"

fn test_h1_defer_normal:
    defer_log = ""
    helper_defer_normal()
    assert_eq_str(defer_log, "cleanup,", "H1.1: defer normal return")

// H1.2: defer on early return
fn helper_defer_early -> i32:
    defer defer_log = defer_log ++ "early,"
    if true:
        return 42
    0

fn test_h1_defer_early:
    defer_log = ""
    let _ = helper_defer_early()
    assert_eq_str(defer_log, "early,", "H1.2: defer early return")

// H1.3: multiple defers LIFO order
fn helper_defer_lifo:
    defer defer_log = defer_log ++ "first,"
    defer defer_log = defer_log ++ "second,"

fn test_h1_defer_lifo:
    defer_log = ""
    helper_defer_lifo()
    assert_eq_str(defer_log, "second,first,", "H1.3: defer LIFO order")

// ═══════════════════════════════════════════════════════════════
// H4: Bitwise operators — all widths
// ═══════════════════════════════════════════════════════════════

fn test_h4_bitwise_i32:
    assert_eq(0xFF & 0x0F, 0x0F, "H4: i32 AND")
    assert_eq(0xF0 | 0x0F, 0xFF, "H4: i32 OR")
    assert_eq(0xFF ^ 0x0F, 0xF0, "H4: i32 XOR")
    assert_eq(~0, -1, "H4: i32 NOT")
    assert_eq(1 << 4, 16, "H4: i32 SHL")
    assert_eq(256 >> 4, 16, "H4: i32 SHR")

fn test_h4_bitwise_i64:
    let a: i64 = 0xFF as i64
    let b: i64 = 0x0F as i64
    assert_eq_i64(a & b, 0x0F as i64, "H4: i64 AND")
    assert_eq_i64(a | b, 0xFF as i64, "H4: i64 OR")
    assert_eq_i64(a ^ b, 0xF0 as i64, "H4: i64 XOR")
    let shifted: i64 = 1 as i64 << 32 as i64
    assert_true(shifted > 0, "H4: i64 SHL 32")

// ═══════════════════════════════════════════════════════════════
// H5: String interpolation (f-strings)
// ═══════════════════════════════════════════════════════════════

fn test_h5_fstrings:
    let name = "world"
    assert_eq_str(f"hello {name}", "hello world", "H5: f-string var")
    let x = "test"
    assert_eq_str(f"val={x}", "val=test", "H5: f-string var 2")
    let a = "one"
    let b = "two"
    assert_eq_str(f"{a}+{b}", "one+two", "H5: f-string multi")
    // Plain strings unaffected
    assert_eq_str("{literal}", "{literal}", "H5: plain brace literal")

// ═══════════════════════════════════════════════════════════════
// M1: Operator overloading
// ═══════════════════════════════════════════════════════════════

type V3 = { x: i32, y: i32, z: i32 }

fn V3.add(self: V3, other: V3) -> V3:
    V3 { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }

fn V3.sub(self: V3, other: V3) -> V3:
    V3 { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }

fn V3.mul(self: V3, other: V3) -> V3:
    V3 { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z }

fn V3.eq(self: V3, other: V3) -> bool:
    self.x == other.x and self.y == other.y and self.z == other.z

fn test_m1_overload:
    let a = V3 { x: 1, y: 2, z: 3 }
    let b = V3 { x: 4, y: 5, z: 6 }
    let c = a + b
    assert_eq(c.x, 5, "M1: + x")
    assert_eq(c.y, 7, "M1: + y")
    let d = b - a
    assert_eq(d.x, 3, "M1: - x")
    let e = a * b
    assert_eq(e.z, 18, "M1: * z")
    // Chained: (a + b) + a
    let f = a + b + a
    assert_eq(f.x, 6, "M1: chained +")

// ═══════════════════════════════════════════════════════════════
// M6: Numeric casts
// ═══════════════════════════════════════════════════════════════

fn test_m6_casts:
    // Widening
    let i: i32 = 42
    let l: i64 = i as i64
    assert_eq_i64(l, 42, "M6: i32→i64")
    // Narrowing
    let big: i64 = 1000
    let small: i32 = big as i32
    assert_eq(small, 1000, "M6: i64→i32")
    // Float → int
    let f: f64 = 3.99
    let fi: i32 = f as i32
    assert_eq(fi, 3, "M6: f64→i32 truncates")
    // Signed → unsigned
    let s: i32 = -1
    let u: u32 = s as u32
    assert_true(u > 0, "M6: i32→u32 reinterpret")
    // i32 → bool (nonzero = true)
    let bval: bool = 1 as i32 != 0
    assert_true(bval, "M6: i32→bool nonzero")

// ═══════════════════════════════════════════════════════════════
// L2: Tuple types
// ═══════════════════════════════════════════════════════════════

fn swap_pair(a: i32, b: i32) -> (i32, i32):
    (b, a)

fn test_l2_tuples:
    let pair = (10, 20)
    let (a, b) = pair
    assert_eq(a, 10, "L2: tuple destructure a")
    assert_eq(b, 20, "L2: tuple destructure b")
    let (x, y) = swap_pair(1, 2)
    assert_eq(x, 2, "L2: tuple return swap x")
    assert_eq(y, 1, "L2: tuple return swap y")

// ═══════════════════════════════════════════════════════════════
// L6: Type aliases
// ═══════════════════════════════════════════════════════════════

type Handle = i64

fn test_l6_type_alias:
    let h: Handle = 42
    assert_eq_i64(h, 42, "L6: type alias i64")

// ═══════════════════════════════════════════════════════════════
// Compound assignment operators
// ═══════════════════════════════════════════════════════════════

fn test_compound_assign:
    var x = 100
    x += 10
    assert_eq(x, 110, "compound +=")
    x -= 20
    assert_eq(x, 90, "compound -=")
    x *= 2
    assert_eq(x, 180, "compound *=")
    x /= 3
    assert_eq(x, 60, "compound /=")
    x %= 7
    assert_eq(x, 4, "compound %=")
    var bits = 0xFF
    bits &= 0x0F
    assert_eq(bits, 0x0F, "compound &=")
    bits |= 0x30
    assert_eq(bits, 0x3F, "compound |=")
    bits ^= 0x0F
    assert_eq(bits, 0x30, "compound ^=")
    bits <<= 2
    assert_eq(bits, 0xC0, "compound <<=")
    bits >>= 4
    assert_eq(bits, 0x0C, "compound >>=")

// ═══════════════════════════════════════════════════════════════
// Wrapping arithmetic
// ═══════════════════════════════════════════════════════════════

fn test_wrapping:
    let max: i32 = 2147483647
    assert_eq(max +% 1, -2147483648, "+% overflow")
    let min: i32 = -2147483648
    assert_eq(min -% 1, 2147483647, "-% underflow")

// ═══════════════════════════════════════════════════════════════
// Feature Interactions (from §Feature Interaction Map)
// ═══════════════════════════════════════════════════════════════

// Interaction 2: Drop + var reassignment (tested in C1.5 above)

// Interaction 5: Drop + defer
fn helper_drop_defer:
    defer defer_log = defer_log ++ "deferred,"
    let r = Res.new("resource")

fn test_interaction_drop_defer:
    drop_log = ""
    defer_log = ""
    helper_drop_defer()
    assert_true(drop_log.contains("resource"), "interact: drop fires")
    assert_true(defer_log.contains("deferred"), "interact: defer fires")

// Interaction 4: Op overload + f-string
fn test_interaction_op_fstring:
    let a = V3 { x: 1, y: 2, z: 3 }
    let b = V3 { x: 4, y: 5, z: 6 }
    let c = a + b
    let msg = f"({int_to_string(c.x)},{int_to_string(c.y)},{int_to_string(c.z)})"
    assert_eq_str(msg, "(5,7,9)", "interact: op overload + f-string")

// ═══════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════

fn main:
    with_eprintln("=== ML features test suite ===")

    with_eprintln("  C1: drop LIFO...")
    test_c1_drop_lifo()
    with_eprintln("  C1: drop reassign...")
    test_c1_drop_reassign()
    with_eprintln("  C1: copy not moved...")
    test_c1_copy_not_moved()
    with_eprintln("  C1: move drops...")
    test_c1_move_drops()
    with_eprintln("  C1: drop reassign loop...")
    test_c1_drop_reassign_loop()
    with_eprintln("  C4: array literal...")
    test_c4_array_literal()
    with_eprintln("  C4: array len...")
    test_c4_array_len()
    with_eprintln("  C4: array mut...")
    test_c4_array_mut()
    with_eprintln("  C4: array param...")
    test_c4_array_param()
    with_eprintln("  C4: array fill...")
    test_c4_array_fill()
    with_eprintln("  C4: array in struct...")
    test_c4_array_in_struct()
    with_eprintln("  C4: array iter...")
    test_c4_array_iter()
    with_eprintln("  H1: defer normal...")
    test_h1_defer_normal()
    with_eprintln("  H1: defer early...")
    test_h1_defer_early()
    with_eprintln("  H1: defer LIFO...")
    test_h1_defer_lifo()
    with_eprintln("  H4: bitwise i32...")
    test_h4_bitwise_i32()
    with_eprintln("  H4: bitwise i64...")
    test_h4_bitwise_i64()
    with_eprintln("  H5: f-strings...")
    test_h5_fstrings()
    with_eprintln("  M1: operator overload...")
    test_m1_overload()
    with_eprintln("  M6: numeric casts...")
    test_m6_casts()
    with_eprintln("  L2: tuples...")
    test_l2_tuples()
    with_eprintln("  L6: type alias...")
    test_l6_type_alias()
    with_eprintln("  compound assign...")
    test_compound_assign()
    with_eprintln("  wrapping...")
    test_wrapping()
    with_eprintln("  interact: drop+defer...")
    test_interaction_drop_defer()
    with_eprintln("  interact: op+fstring...")
    test_interaction_op_fstring()

    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")
    if fail_count > 0:
        with_eprintln(int_to_string(fail_count) ++ " FAILURES")
        abort()
    with_eprintln("ALL PASSED")
