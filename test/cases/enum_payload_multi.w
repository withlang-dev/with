// Test enum variants with multiple payloads
type Expr = Num(i32) | Add(i32, i32) | Neg(i32)

fn eval(e: Expr) -> i32 =
    match e
        Num(n) -> n
        Add(a, b) -> a + b
        Neg(n) -> 0 - n

fn main() -> i32 =
    println(eval(Num(42)))
    println(eval(Add(10, 20)))
    println(eval(Neg(5)))
    0
