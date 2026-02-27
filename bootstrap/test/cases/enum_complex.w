// Test: Complex enum patterns with single payloads
type Op = Add(i32) | Mul(i32) | Lit(i32)

fn apply(op: Op, x: i32) -> i32:
    match op
        Lit(n) -> n
        Add(n) -> x + n
        Mul(n) -> x * n

fn main -> i32:
    let e1 = Lit(10)
    let e2 = Add(12)
    let e3 = Mul(2)

    let v1 = apply(e1, 0)
    assert(v1 == 10)

    let v2 = apply(e2, 20)
    assert(v2 == 32)

    let v3 = apply(e3, 21)
    assert(v3 == 42)

