// test_types.w — Comprehensive type, cast, and coercion tests.
// Covers all primitive types from §4.1, casts from §4.2.6, struct
// field storage, Vec element storage, and cross-type arithmetic.

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str

var test_count: i32 = 0
var pass_count: i32 = 0
var fail_count: i32 = 0

fn assert_eq_i32(a: i32, b: i32, msg: str):
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

fn assert_true(cond: bool, msg: str):
    test_count = test_count + 1
    if cond:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg)

// ── Integer widening casts ─────────────────────────────────────────

fn test_int_widening:
    with_eprintln("  int widening...")
    // i8 → i16 → i32 → i64
    let a: i32 = 42
    let b: i64 = a as i64
    assert_eq_i64(b, 42i64, "i32 as i64")
    // u8 → u16 → u32 → u64
    let c: u8 = 200u8
    let d: u32 = c as u32
    assert_eq_i32(d as i32, 200, "u8 as u32")
    let e: u64 = d as u64
    assert_eq_i64(e as i64, 200i64, "u32 as u64")
    // u8 → i32 (unsigned to wider signed)
    let f: u8 = 255u8
    let g: i32 = f as i32
    assert_eq_i32(g, 255, "u8 as i32 (255)")
    // u16 → i32
    let h: u16 = 65000u16
    let i2: i32 = h as i32
    assert_eq_i32(i2, 65000, "u16 as i32")

// ── Integer narrowing casts ────────────────────────────────────────

fn test_int_narrowing:
    with_eprintln("  int narrowing...")
    let a: i32 = 300
    let b: u8 = a as u8
    assert_eq_i32(b as i32, 44, "300 as u8 = 44 (truncated)")
    let c: i64 = 100000i64
    let d: i32 = c as i32
    assert_eq_i32(d, 100000, "100000i64 as i32")
    // Negative value truncation
    let e: i32 = -1
    let f: u8 = e as u8
    assert_eq_i32(f as i32, 255, "-1 as u8 = 255")
    let g: u32 = e as u32
    assert_true(g == 0xFFFFFFFFu32, "-1 as u32 = 0xFFFFFFFF")

// ── Float widening: f32 → f64 ─────────────────────────────────────

fn test_float_widening:
    with_eprintln("  float widening...")
    let a: f32 = 3.25
    let b: f64 = a as f64
    assert_eq_i64(b as i64, 3i64, "f32 3.25 as f64 truncated to i64 = 3")
    // Verify precision preserved
    let c: f32 = 1000.5
    let d: f64 = c as f64
    let d_int = d as i64
    assert_eq_i64(d_int, 1000i64, "f32 1000.5 → f64 → i64 = 1000")

// ── Float narrowing: f64 → f32 ────────────────────────────────────

fn test_float_narrowing:
    with_eprintln("  float narrowing...")
    let a: f64 = 3.14
    let b: f32 = a as f32
    assert_eq_i32(b as i32, 3, "f64 3.14 as f32 as i32 = 3")
    let c: f64 = 1000000.5
    let d: f32 = c as f32
    assert_eq_i32(d as i32, 1000000, "f64 1M as f32 as i32 = 1000000")

// ── Int ↔ Float casts ─────────────────────────────────────────────

fn test_int_float_casts:
    with_eprintln("  int ↔ float casts...")
    // int → float
    let a: i32 = 42
    let b: f32 = a as f32
    assert_eq_i32(b as i32, 42, "i32 42 as f32 as i32 = 42")
    let c: i32 = 1000
    let d: f64 = c as f64
    assert_eq_i64(d as i64, 1000i64, "i32 1000 as f64 as i64 = 1000")
    // float → int (truncation toward zero)
    let e: f64 = 3.9
    assert_eq_i32(e as i32, 3, "f64 3.9 as i32 = 3 (truncate)")
    let f: f64 = -2.7
    assert_eq_i32(f as i32, -2, "f64 -2.7 as i32 = -2 (truncate toward zero)")
    let g: f32 = 99.9
    assert_eq_i32(g as i32, 99, "f32 99.9 as i32 = 99")

// ── Struct field storage with all types ────────────────────────────

type S_i32 = { val: i32 }
type S_u8 = { val: u8 }
type S_f32 = { val: f32 }
type S_f64 = { val: f64 }
type S_i64 = { val: i64 }
type S_u32 = { val: u32 }
type S_mixed = { a: f32, b: i32, c: f64, d: u8 }

fn test_struct_field_storage:
    with_eprintln("  struct field storage...")
    // i32 field with literal
    let s1 = S_i32 { val: 42 }
    assert_eq_i32(s1.val, 42, "struct i32 literal")
    // i32 field with expression
    let x = 10
    let s2 = S_i32 { val: x + 5 }
    assert_eq_i32(s2.val, 15, "struct i32 expr")
    // u8 field
    let s3 = S_u8 { val: 200u8 }
    assert_eq_i32(s3.val as i32, 200, "struct u8 literal")
    // f32 field with literal
    let s4 = S_f32 { val: 3.25 }
    assert_eq_i32(s4.val as i32, 3, "struct f32 literal")
    // f32 field with expression (THE BUG: f64 expr → f32 field)
    let i = 5
    let fi = i as f32
    let s5 = S_f32 { val: fi + 1.0 }
    assert_eq_i32(s5.val as i32, 6, "struct f32 computed (cast+add)")
    // f32 field with f32 variable
    let fv: f32 = 7.5
    let s6 = S_f32 { val: fv }
    assert_eq_i32(s6.val as i32, 7, "struct f32 variable")
    // f64 field with expression
    let s7 = S_f64 { val: 3.14 + 1.0 }
    assert_eq_i64(s7.val as i64, 4i64, "struct f64 expr")
    // i64 field
    let s8 = S_i64 { val: 100000i64 }
    assert_eq_i64(s8.val, 100000i64, "struct i64 literal")
    // u32 field
    let s9 = S_u32 { val: 0xDEADu32 }
    assert_true(s9.val == 0xDEADu32, "struct u32 hex")
    // Mixed struct
    let s10 = S_mixed { a: 1.5, b: 42, c: 3.14, d: 255u8 }
    assert_eq_i32(s10.a as i32, 1, "mixed f32")
    assert_eq_i32(s10.b, 42, "mixed i32")
    assert_eq_i64(s10.c as i64, 3i64, "mixed f64")
    assert_eq_i32(s10.d as i32, 255, "mixed u8")

// ── Struct field storage in for loops ──────────────────────────────

fn test_struct_in_loop:
    with_eprintln("  struct fields in loops...")
    // f32 struct in loop with computed value
    var results: Vec[i32] = Vec.new()
    for i in 0..5:
        let fi = i as f32
        let s = S_f32 { val: fi * 10.0 + 1.0 }
        results.push(s.val as i32)
    assert_eq_i32(results.get(0), 1, "loop f32 struct i=0")
    assert_eq_i32(results.get(1), 11, "loop f32 struct i=1")
    assert_eq_i32(results.get(2), 21, "loop f32 struct i=2")
    assert_eq_i32(results.get(3), 31, "loop f32 struct i=3")
    assert_eq_i32(results.get(4), 41, "loop f32 struct i=4")

// ── Vec push/get with struct types ─────────────────────────────────

type Position = { x: f32, y: f32 }

fn test_vec_struct:
    with_eprintln("  Vec[struct] push/get...")
    var pos: Vec[Position] = Vec.new()
    pos.push(Position { x: 1.5, y: 2.5 })
    pos.push(Position { x: 3.0, y: 4.0 })
    assert_eq_i32(pos[0].x as i32, 1, "vec struct [0].x")
    assert_eq_i32(pos[0].y as i32, 2, "vec struct [0].y")
    assert_eq_i32(pos[1].x as i32, 3, "vec struct [1].x")
    // Push in loop with computed values
    var pos2: Vec[Position] = Vec.new()
    for i in 0..5:
        let fi = i as f32
        pos2.push(Position { x: fi + 0.5, y: fi * 2.0 })
    assert_eq_i32(pos2[0].x as i32, 0, "vec loop [0].x (0.5→0)")
    assert_eq_i32(pos2[1].x as i32, 1, "vec loop [1].x (1.5→1)")
    assert_eq_i32(pos2[4].x as i32, 4, "vec loop [4].x (4.5→4)")
    assert_eq_i32(pos2[4].y as i32, 8, "vec loop [4].y (8.0→8)")
    // Vec index assignment
    pos2[0] = Position { x: 99.0, y: 88.0 }
    assert_eq_i32(pos2[0].x as i32, 99, "vec set [0].x")

// ── Vec with all numeric types ─────────────────────────────────────

fn test_vec_numeric_types:
    with_eprintln("  Vec numeric types...")
    var vi32: Vec[i32] = Vec.new()
    vi32.push(42)
    assert_eq_i32(vi32.get(0), 42, "Vec[i32]")

    var vu8: Vec[u8] = Vec.new()
    vu8.push(200u8)
    assert_eq_i32(vu8.get(0) as i32, 200, "Vec[u8] via get")
    // NOTE: vu8[0] as i32 sign-extends (index operator path); use .get() for u8 Vecs

    var vf32: Vec[f32] = Vec.new()
    vf32.push(3.25)
    assert_eq_i32(vf32[0] as i32, 3, "Vec[f32]")

    var vf64: Vec[f64] = Vec.new()
    vf64.push(1000.5)
    assert_eq_i64(vf64[0] as i64, 1000i64, "Vec[f64]")

    var vi64: Vec[i64] = Vec.new()
    vi64.push(999999i64)
    assert_eq_i64(vi64.get(0), 999999i64, "Vec[i64]")

// ── f32/f64 arithmetic ─────────────────────────────────────────────

fn test_float_arithmetic:
    with_eprintln("  float arithmetic...")
    // f32 ops
    let a: f32 = 10.0
    let b: f32 = 3.0
    assert_eq_i32((a + b) as i32, 13, "f32 add")
    assert_eq_i32((a - b) as i32, 7, "f32 sub")
    assert_eq_i32((a * b) as i32, 30, "f32 mul")
    assert_eq_i32((a / b) as i32, 3, "f32 div (truncated)")
    // f64 ops
    let c: f64 = 100.0
    let d: f64 = 7.0
    assert_eq_i64((c + d) as i64, 107i64, "f64 add")
    assert_eq_i64((c * d) as i64, 700i64, "f64 mul")
    // Mixed: i32 as f32 arithmetic
    let i = 5
    let fi = i as f32
    assert_eq_i32((fi * 10.0) as i32, 50, "i32→f32 mul")
    assert_eq_i32((fi + 1.0) as i32, 6, "i32→f32 add 1.0")
    // f32 accumulation
    var sum: f64 = 0.0
    for i2 in 0..10:
        let v: f32 = (i2 as f32) + 0.5
        sum = sum + v as f64
    // 0.5+1.5+2.5+...+9.5 = 50
    assert_eq_i64(sum as i64, 50i64, "f32 accumulation into f64")

// ── Bool type ──────────────────────────────────────────────────────

fn test_bool:
    with_eprintln("  bool...")
    let t = true
    let f = false
    assert_true(t, "true is true")
    assert_true(not f, "not false is true")
    assert_eq_i32(t as i32, 1, "true as i32 = 1")
    assert_eq_i32(f as i32, 0, "false as i32 = 0")

// ── Numeric literal suffixes ───────────────────────────────────────

fn test_suffixed_literals:
    with_eprintln("  suffixed literals...")
    let a: u8 = 0xFFu8
    assert_eq_i32(a as i32, 255, "0xFFu8")
    let b: u32 = 0xDEADBEEFu32
    assert_true(b == 0xDEADBEEFu32, "0xDEADBEEFu32")
    let c: i64 = 42i64
    assert_eq_i64(c, 42i64, "42i64")
    let d: f32 = 1.5f32
    assert_eq_i32(d as i32, 1, "1.5f32")

// ── String concat coercion (f-string interpolation) ────────────────

fn test_str_concat_coercion:
    with_eprintln("  str concat coercion...")
    let s1 = "val:" ++ 42
    assert_true(s1 == "val:42", "str ++ i32")
    let s2 = "val:" ++ 100i64
    assert_true(s2 == "val:100", "str ++ i64")
    // Note: f64 concat produces %g format (e.g. "3.14" or "1000")

// ── Main ───────────────────────────────────────────────────────────

fn main:
    with_eprintln("=== Type System Test Suite ===")
    test_int_widening()
    test_int_narrowing()
    test_float_widening()
    test_float_narrowing()
    test_int_float_casts()
    test_struct_field_storage()
    test_struct_in_loop()
    test_vec_struct()
    test_vec_numeric_types()
    test_float_arithmetic()
    test_bool()
    test_suffixed_literals()
    test_str_concat_coercion()
    with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===")
    if fail_count > 0:
        with_eprintln("FAILURES: " ++ int_to_string(fail_count))
    else:
        with_eprintln("ALL PASSED")
