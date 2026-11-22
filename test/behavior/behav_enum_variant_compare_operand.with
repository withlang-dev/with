//! expect-stdout: ok

// #634: an enum-variant constructor used as a comparison operand
// (`r == Some(2)`) must build its aggregate with its own enum type, not the
// comparison's bool type. Exercise both operand orders and Option/Result.
fn main:
    let r: Option[i32] = Some(2)
    assert(r == Some(2))
    assert(r != Some(3))
    assert(Some(2) == r)

    let e: Result[i32, i32] = Ok(5)
    assert(e == Ok(5))
    assert(e != Err(5))
    print("ok")
