type Expr =
    Add(i32, i32)
    | Mul(i32, i32)
    | Neg(i32)
    | Lit(i32)

fn eval(e: Expr) -> i32:
    match e
        Add(a, b) -> a + b
        Mul(a, b) -> a * b
        Neg(x) -> 0 - x
        Lit(v) -> v

fn main -> i32:
    let x = Add(10, 20)
    let y = Mul(3, 4)
    let z = Neg(5)
    let w = Lit(42)

    let r1 = eval(x)
    let r2 = eval(y)
    let r3 = eval(z)
    let r4 = eval(w)

    assert(r1 == 30)
    assert(r2 == 12)
    assert(r3 == -5)
    assert(r4 == 42)

    println("{r1}")
    println("{r2}")
    println("{r3}")
    println("{r4}")
