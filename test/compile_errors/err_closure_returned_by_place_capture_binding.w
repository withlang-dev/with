//! expect-check-fail: returned closure captures `xs` by place

// #1567 / §12.2: the same escape through a let-bound closure returned with
// an explicit `return`.
fn counter() -> fn() -> i32:
    var xs: Vec[i32] = Vec.new()
    let f = () =>
        xs.push(1)
        xs.len32()
    return f

fn main:
    let f = counter()
    print(f())
