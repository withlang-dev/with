// Spec test: Section 9.7 — Pattern Matching
// Executable subset: or-patterns, range arms, nested variants, if-let
// (slice patterns not yet supported).

enum Day:
    Mon
    Tue
    Sat
    Sun

fn classify(d: Day) -> str:
    match d:
        .Mon | .Tue => "weekday"
        .Sat | .Sun => "weekend"

enum Expr:
    Lit(i32)
    Neg(i32)

type Point {
    x: i32,
    y: i32,
}

fn eval(e: Expr) -> i32:
    match e:
        .Lit(0) => 1000
        .Lit(n) => n
        .Neg(n) => 0 - n

fn category(code: i32) -> str:
    match code:
        200 => "ok"
        400..=499 => "client error"
        _ => "unknown"

fn test_or_patterns:
    assert(classify(Day.Tue) == "weekday")
    assert(classify(Day.Sun) == "weekend")

fn test_nested_variant_patterns:
    assert(eval(Expr.Lit(0)) == 1000)
    assert(eval(Expr.Lit(42)) == 42)
    assert(eval(Expr.Neg(5)) == -5)

fn test_range_arm:
    assert(category(404) == "client error")
    assert(category(200) == "ok")
    assert(category(999) == "unknown")

fn test_if_let:
    let o: Option[i32] = Some(7)
    var got = 0
    if let Some(x) = o: got = x
    assert(got == 7)

fn test_positional_struct_pattern:
    let point = Point { x: 3, y: 4 }
    match point:
        Point(x, y) => assert(x + y == 7)
