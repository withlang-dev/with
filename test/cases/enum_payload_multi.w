// Test enum variants with multiple payloads
type Expr = enum {
    Num(i32),
    Add(i32, i32),
    Neg(i32),
}

fn eval(e: Expr) -> i32 =
    match e
        Expr.Num(n) -> n
        Expr.Add(a, b) -> a + b
        Expr.Neg(n) -> 0 - n

fn main() -> i32 =
    println(eval(Expr.Num(42)))
    println(eval(Expr.Add(10, 20)))
    println(eval(Expr.Neg(5)))
    0
