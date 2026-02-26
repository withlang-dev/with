type Expr = Num(i32) | Add(i32) | Neg(i32)

fn eval(e: Expr) -> i32 =
    match e
        Num(n) -> n
        Add(n) -> n + 1
        Neg(n) -> -n

fn main() -> i32 =
    println(eval(Num(42)))
    println(eval(Add(9)))
    println(eval(Neg(5)))
    0
