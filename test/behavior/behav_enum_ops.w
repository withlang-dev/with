//! expect-stdout: ok

// Tests: enum definition, match on enum, enum with payloads,
//        enum methods, enum equality, multiple variants

enum Direction { North | South | East | West }

fn test_enum_basic:
    let d = Direction.North
    let is_north = match d
        .North => true
        _ => false
    assert(is_north)

fn test_enum_match_all:
    assert(dir_name(Direction.North) == "north")
    assert(dir_name(Direction.South) == "south")
    assert(dir_name(Direction.East) == "east")
    assert(dir_name(Direction.West) == "west")

fn dir_name(d: Direction) -> str:
    match d
        .North => "north"
        .South => "south"
        .East => "east"
        .West => "west"

fn test_enum_equality:
    let a = Direction.East
    let b = Direction.East
    let c = Direction.West
    assert(a == b)
    assert(a != c)

enum Shape { Circle(r: f64) | Rectangle(w: f64, h: f64) | Triangle }

fn test_enum_with_payload:
    let s = Shape.Circle(5.0)
    let area = match s
        .Circle(r) => r * r
        .Rectangle(w, h) => w * h
        .Triangle => 0.0
    assert(area as i64 == 25i64)

fn test_enum_rectangle_payload:
    let s = Shape.Rectangle(3.0, 4.0)
    let area = match s
        .Circle(r) => r * r
        .Rectangle(w, h) => w * h
        .Triangle => 0.0
    assert(area as i64 == 12i64)

fn test_enum_no_payload_variant:
    let s = Shape.Triangle
    let is_triangle = match s
        .Triangle => true
        _ => false
    assert(is_triangle)

enum Weekday { Monday | Tuesday | Wednesday | Thursday | Friday | Saturday | Sunday }

fn is_weekend(d: Weekday) -> bool:
    match d
        .Saturday | .Sunday => true
        _ => false

fn test_enum_many_variants:
    assert(not is_weekend(Weekday.Monday))
    assert(not is_weekend(Weekday.Wednesday))
    assert(not is_weekend(Weekday.Friday))
    assert(is_weekend(Weekday.Saturday))
    assert(is_weekend(Weekday.Sunday))

enum Option2 { None2 | Some2(i32) }

fn test_option_like_enum:
    let a = Option2.Some2(42)
    let val = match a
        .Some2(v) => v
        .None2 => -1
    assert(val == 42)

    let b = Option2.None2
    let val2 = match b
        .Some2(v) => v
        .None2 => -1
    assert(val2 == -1)

enum Expr { Lit(i32) | Neg(i32) | Add(i32, i32) }

fn eval_expr(e: Expr) -> i32:
    match e
        .Lit(v) => v
        .Neg(v) => -v
        .Add(a, b) => a + b

fn test_enum_expression_eval:
    assert(eval_expr(Expr.Lit(5)) == 5)
    assert(eval_expr(Expr.Neg(3)) == -3)
    assert(eval_expr(Expr.Add(10, 20)) == 30)

fn main:
    test_enum_basic()
    test_enum_match_all()
    test_enum_equality()
    test_enum_with_payload()
    test_enum_rectangle_payload()
    test_enum_no_payload_variant()
    test_enum_many_variants()
    test_option_like_enum()
    test_enum_expression_eval()
    print("ok")
