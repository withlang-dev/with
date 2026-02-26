// Test: nested enum matching and multi-payload enums
type Expr = Num(i32) | Add(i32) | Mul(i32)

fn eval(base: i32, e: Expr) -> i32:
    match e
        Num(n) -> n
        Add(n) -> base + n
        Mul(n) -> base * n

type Priority = Low | Medium | High

fn priority_value(p: Priority) -> i32:
    match p
        Low -> 1
        Medium -> 5
        High -> 10

fn classify_score(score: i32) -> Priority:
    if score < 30 then Low
    else if score < 70 then Medium
    else High

fn main -> i32:
    // Basic multi-payload matching
    let e1 = Num(42)
    let e2 = Add(10)
    let e3 = Mul(3)
    assert(eval(5, e1) == 42)
    assert(eval(5, e2) == 15)
    assert(eval(5, e3) == 15)

    // Chained evaluation
    var result: i32 = 0
    result = eval(result, Num(10))
    result = eval(result, Add(5))
    result = eval(result, Mul(3))
    assert(result == 45)

    // Priority classification
    assert(priority_value(classify_score(10)) == 1)
    assert(priority_value(classify_score(50)) == 5)
    assert(priority_value(classify_score(90)) == 10)

    // Enum accessor methods
    let x: Expr = Add(7)
    assert(x.is_Add())
    assert(not x.is_Num())
    assert(not x.is_Mul())

    println("all enum_nested_match tests passed")
