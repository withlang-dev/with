//! expect-stdout: ok
fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main:
    var total = 0
    let result = apply(
        (x: i32) =>
            total = total + x
            total
        , 10)
    assert(result == 10)
    assert(total == 0)
    print("ok")
