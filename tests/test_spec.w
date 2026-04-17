// test_spec.w — Spec-driven test suite
// Tests language features described in the With specification v6.5.
// Focuses on features most likely to have implementation gaps.

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

// ── §4.1 Primitive types and basic arithmetic ───────────────────

fn test_primitives:
    // Integer types
    let a: i32 = 42
    let b: i64 = 100
    assert_eq(a, 42, "i32 literal")
    assert_eq_i64(b, 100, "i64 literal")

    // Boolean
    let t: bool = true
    let f: bool = false
    assert_true(t, "bool true")
    assert_true(not f, "bool false negated")

    // Arithmetic
    assert_eq(3 + 4, 7, "addition")
    assert_eq(10 - 3, 7, "subtraction")
    assert_eq(6 * 7, 42, "multiplication")
    assert_eq(10 / 3, 3, "integer division")
    assert_eq(10 % 3, 1, "modulo")

    // Unary negate
    assert_eq(0 - 5, -5, "unary negate via subtraction")

    // Comparison operators
    assert_true(3 < 5, "less than")
    assert_true(5 > 3, "greater than")
    assert_true(3 <= 3, "less or equal")
    assert_true(5 >= 5, "greater or equal")
    assert_true(5 == 5, "equality")
    assert_true(5 != 6, "inequality")

// ── §4.2 Explicit cast with `as` ────────────────────────────────

fn test_casts:
    let big: i64 = 1000
    let small: i32 = big as i32
    assert_eq(small, 1000, "i64 as i32")

    let x: i32 = 255
    let y: i64 = x as i64
    assert_eq_i64(y, 255, "i32 as i64")

// ── §4.3 Structs ────────────────────────────────────────────────

type Point = { x: i32, y: i32 }

fn test_structs:
    let p = Point { x: 10, y: 20 }
    assert_eq(p.x, 10, "struct field x")
    assert_eq(p.y, 20, "struct field y")

    // Record update syntax (§4.3, §7.4)
    let p2 = { p with x: 30 }
    assert_eq(p2.x, 30, "record update x")
    assert_eq(p2.y, 20, "record update y preserved")

    // Field shorthand (§4.3)
    let x = 5
    let y = 15
    let p3 = Point { x, y }
    assert_eq(p3.x, 5, "field shorthand x")
    assert_eq(p3.y, 15, "field shorthand y")

// ── §4.4a Discriminant enums ────────────────────────────────────

type Color: i32 =
    Red = 1
    Green = 2
    Blue = 4

type Status: i32 =
    Pending = 0
    Active
    Suspended = 10
    Archived

fn test_disc_enums:
    // Explicit values
    assert_eq(Color.Red as i32, 1, "disc enum Red=1")
    assert_eq(Color.Green as i32, 2, "disc enum Green=2")
    assert_eq(Color.Blue as i32, 4, "disc enum Blue=4")

    // Auto-increment (§4.4a)
    assert_eq(Status.Pending as i32, 0, "disc enum Pending=0")
    assert_eq(Status.Active as i32, 1, "disc enum Active=1 auto")
    assert_eq(Status.Suspended as i32, 10, "disc enum Suspended=10")
    assert_eq(Status.Archived as i32, 11, "disc enum Archived=11 auto")

// ── §4.5 Distinct types ────────────────────────────────────────

type Meters = distinct f64

fn test_distinct:
    let m = Meters(3.14)
    // distinct type .value access
    assert_true(m.value > 3.0, "distinct type .value access")

// ── §9.1b const declarations ────────────────────────────────────

const MAX_SIZE: i32 = 1024
const HALF: i32 = MAX_SIZE / 2
const WIDTH: i32 = 80
const HEIGHT: i32 = 24
const AREA: i32 = WIDTH * HEIGHT

fn test_const:
    assert_eq(MAX_SIZE, 1024, "const literal")
    assert_eq(HALF, 512, "const division")
    assert_eq(WIDTH, 80, "const WIDTH")
    assert_eq(AREA, 1920, "const computed AREA")

// ── §9.1 Functions (various forms) ─────────────────────────────

fn no_args_no_return:
    let _ = 1  // just a body

fn no_args_with_return -> i32:
    42

fn with_args(a: i32, b: i32) -> i32:
    a + b

fn test_functions:
    no_args_no_return()
    assert_eq(no_args_with_return(), 42, "no-args with return")
    assert_eq(with_args(3, 4), 7, "fn with args")

// ── §9.3 Closures ───────────────────────────────────────────────

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn test_closures:
    let double = (x: i32) -> i32 => x * 2
    assert_eq(double(5), 10, "closure double")
    assert_eq(apply((x: i32) -> i32 => x + 1, 10), 11, "closure passed to fn")

    // Closure capturing local variable
    let offset = 100
    let add_offset = (x: i32) -> i32 => x + offset
    assert_eq(add_offset(5), 105, "closure capture")

// ── §9.6 Shift and bitwise operators ────────────────────────────

fn test_bitwise:
    // Shift operators (§9.6)
    assert_eq(1 << 0, 1, "1 << 0")
    assert_eq(1 << 3, 8, "1 << 3")
    assert_eq(16 >> 2, 4, "16 >> 2")

    // Bitwise AND, OR, XOR
    assert_eq(0xFF & 0x0F, 0x0F, "bitwise AND")
    assert_eq(0xF0 | 0x0F, 0xFF, "bitwise OR")
    assert_eq(0xFF ^ 0x0F, 0xF0, "bitwise XOR")

// ── §9.7 Pattern matching ───────────────────────────────────────

fn classify(x: i32) -> str:
    match x:
        0 => "zero"
        1 => "one"
        _ => "other"

fn test_match:
    assert_eq_str(classify(0), "zero", "match literal 0")
    assert_eq_str(classify(1), "one", "match literal 1")
    assert_eq_str(classify(99), "other", "match wildcard")

    // Match with guards
    let v = 42
    let label = match v:
        x if x > 0 => "positive"
        x if x < 0 => "negative"
        _ => "zero"
    assert_eq_str(label, "positive", "match guard positive")

    // Tuple pattern matching
    let pair = (10, 20)
    let sum = match pair:
        (a, b) => a + b
    assert_eq(sum, 30, "tuple match destructure")

// ── §9.10 for-else (if implemented) ─────────────────────────────

fn test_for_loops:
    // Basic for loop with range
    var sum = 0
    for i in 0..5:
        sum = sum + i
    assert_eq(sum, 10, "for range sum 0..5")

    // While loop
    var count = 0
    while count < 5:
        count = count + 1
    assert_eq(count, 5, "while loop count")

    // Nested for loops
    var product = 0
    for i in 0..3:
        for j in 0..3:
            product = product + 1
    assert_eq(product, 9, "nested for 3x3")

// ── §9.9 Boolean logic ─────────────────────────────────────────

fn test_logic:
    assert_true(true and true, "and: T T")
    assert_true(not (true and false), "and: T F")
    assert_true(not (false and true), "and: F T")
    assert_true(not (false and false), "and: F F")

    assert_true(true or false, "or: T F")
    assert_true(false or true, "or: F T")
    assert_true(not (false or false), "or: F F")

    assert_true(not false, "not false")
    assert_true(not (not true), "double not")

// ── §4.3 Struct methods via extension blocks (§9.5) ─────────────

type Vec2 = { x: i32, y: i32 }

fn Vec2.length_sq(self: Vec2) -> i32:
    self.x * self.x + self.y * self.y

fn Vec2.add(self: Vec2, other: Vec2) -> Vec2:
    Vec2 { x: self.x + other.x, y: self.y + other.y }

fn test_methods:
    let v = Vec2 { x: 3, y: 4 }
    assert_eq(v.length_sq(), 25, "method call length_sq")

    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 3, y: 4 }
    let c = a.add(b)
    assert_eq(c.x, 4, "method add x")
    assert_eq(c.y, 6, "method add y")

// ── String operations ───────────────────────────────────────────

fn test_strings:
    // String concatenation
    let a = "hello"
    let b = " world"
    let c = a ++ b
    assert_eq_str(c, "hello world", "string concat")

    // String length
    assert_eq("hello".len() as i32, 5, "string length")
    assert_eq("".len() as i32, 0, "empty string length")

// ── §7.2/7.3 with blocks (scoped mutation, scoped binding) ──────

fn test_with_blocks:
    // Form 3: scoped binding
    let result = with 10 + 20 as total:
        total * 2
    assert_eq(result, 60, "with scoped binding")

    // Form 2: scoped mutation (builder) §7.2
    let p = with Point { x: 0, y: 0 } as mut pt:
        pt.x = 42
        pt.y = 99
    assert_eq(p.x, 42, "with mut builder x")
    assert_eq(p.y, 99, "with mut builder y")

// ── §9.4 Partial application ────────────────────────────────────

fn add3(a: i32, b: i32) -> i32:
    a + b

fn test_partial_application:
    let add5 = add3(5, _)
    assert_eq(add5(3), 8, "partial application add5(3)")
    assert_eq(add5(0), 5, "partial application add5(0)")

// ── §4.8 Tuples ─────────────────────────────────────────────────

fn swap(a: i32, b: i32) -> (i32, i32):
    (b, a)

fn test_tuples:
    let pair = (10, 20)
    let (a, b) = pair
    assert_eq(a, 10, "tuple destructure a")
    assert_eq(b, 20, "tuple destructure b")

    let (x, y) = swap(1, 2)
    assert_eq(x, 2, "swap first")
    assert_eq(y, 1, "swap second")

// ── §9.6 Pipeline operator ──────────────────────────────────────

fn double_val(x: i32) -> i32: x * 2
fn add_one(x: i32) -> i32: x + 1

fn test_pipeline:
    let result = 5 |> double_val |> add_one
    assert_eq(result, 11, "pipeline 5 |> double |> add_one")

// ── §2.2 Move semantics / §2.3 Copy types ──────────────────────

fn test_copy_types:
    // Integers are Copy — both remain valid
    let a: i32 = 42
    let b = a
    assert_eq(a, 42, "copy: original valid")
    assert_eq(b, 42, "copy: copy valid")

    // Booleans are Copy
    let t = true
    let t2 = t
    assert_true(t, "copy bool original")
    assert_true(t2, "copy bool copy")

// ── if/else expressions ─────────────────────────────────────────

fn abs_val(x: i32) -> i32:
    if x < 0: 0 - x else: x

fn test_if_expr:
    assert_eq(abs_val(5), 5, "if expr positive")
    assert_eq(abs_val(-3), 3, "if expr negative")
    assert_eq(abs_val(0), 0, "if expr zero")

    // Inline if-else as expression
    let sign = if 10 > 0: 1 else: -1
    assert_eq(sign, 1, "inline if expr")

// ── Var mutability ──────────────────────────────────────────────

fn test_var:
    var x = 10
    assert_eq(x, 10, "var initial")
    x = 20
    assert_eq(x, 20, "var mutated")
    x = x + 5
    assert_eq(x, 25, "var += 5")

// ── Nested struct field access ──────────────────────────────────

type Rect = { origin: Point, size: Point }

fn test_nested_structs:
    let r = Rect {
        origin: Point { x: 1, y: 2 },
        size: Point { x: 100, y: 200 },
    }
    assert_eq(r.origin.x, 1, "nested struct origin.x")
    assert_eq(r.size.y, 200, "nested struct size.y")

// ── Multiple return / early return ──────────────────────────────

fn find_first_positive(a: i32, b: i32, c: i32) -> i32:
    if a > 0:
        return a
    if b > 0:
        return b
    if c > 0:
        return c
    0

fn test_early_return:
    assert_eq(find_first_positive(-1, -2, 3), 3, "early return third")
    assert_eq(find_first_positive(1, 2, 3), 1, "early return first")
    assert_eq(find_first_positive(-1, 2, 3), 2, "early return second")
    assert_eq(find_first_positive(-1, -2, -3), 0, "early return default")

// ── Vec operations ──────────────────────────────────────────────

fn test_vec:
    var v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert_eq(v.len() as i32, 3, "vec length")
    assert_eq(v.get(0) as i32, 10, "vec get 0")
    assert_eq(v.get(1) as i32, 20, "vec get 1")
    assert_eq(v.get(2) as i32, 30, "vec get 2")

// ── HashMap operations ──────────────────────────────────────────

fn test_hashmap:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 100)
    m.insert(2, 200)
    m.insert(3, 300)
    assert_true(m.contains(1), "hashmap contains 1")
    assert_true(m.contains(2), "hashmap contains 2")
    assert_true(not m.contains(99), "hashmap not contains 99")
    assert_eq(m.get(1).unwrap(), 100, "hashmap get 1")
    assert_eq(m.get(2).unwrap(), 200, "hashmap get 2")

// ── Main ────────────────────────────────────────────────────────

fn main:
    with_eprintln("=== spec-driven test suite ===")

    with_eprintln("  primitives...")
    test_primitives()
    with_eprintln("  casts...")
    test_casts()
    with_eprintln("  structs...")
    test_structs()
    with_eprintln("  disc_enums...")
    test_disc_enums()
    with_eprintln("  distinct...")
    test_distinct()
    with_eprintln("  const...")
    test_const()
    with_eprintln("  functions...")
    test_functions()
    with_eprintln("  closures...")
    test_closures()
    with_eprintln("  bitwise...")
    test_bitwise()
    with_eprintln("  match...")
    test_match()
    with_eprintln("  for_loops...")
    test_for_loops()
    with_eprintln("  logic...")
    test_logic()
    with_eprintln("  methods...")
    test_methods()
    with_eprintln("  strings...")
    test_strings()
    with_eprintln("  with_blocks...")
    test_with_blocks()
    with_eprintln("  partial_app...")
    test_partial_application()
    with_eprintln("  tuples...")
    test_tuples()
    with_eprintln("  pipeline...")
    test_pipeline()
    with_eprintln("  copy_types...")
    test_copy_types()
    with_eprintln("  if_expr...")
    test_if_expr()
    with_eprintln("  var...")
    test_var()
    with_eprintln("  nested_structs...")
    test_nested_structs()
    with_eprintln("  early_return...")
    test_early_return()
    with_eprintln("  vec...")
    test_vec()
    with_eprintln("  hashmap...")
    test_hashmap()

    with_eprintln(int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " tests passed")
    if fail_count > 0:
        with_eprintln(int_to_string(fail_count) ++ " FAILURES")
        abort()
    with_eprintln("ALL PASSED")
