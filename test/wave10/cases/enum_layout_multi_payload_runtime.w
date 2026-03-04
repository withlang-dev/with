type Expr = Add(i32, i32) | Mul(i32, i32) | Lit(i32) | Zero

fn eval(e: Expr) -> i32:
    match e
        Add(a, b) -> a + b
        Mul(a, b) -> a * b
        Lit(v) -> v
        Zero -> 0

fn main -> i32:
    assert(eval(Add(10, 20)) == 30)
    assert(eval(Mul(3, 4)) == 12)
    assert(eval(Lit(42)) == 42)
    assert(eval(Zero) == 0)
