//! expect-check-fail: returned closure captures `xs` by place

// #1567 / §12.2: a non-move closure holds `xs` by place — a view of this
// frame's local — so returning it would let the closure outlive `xs`.
fn counter() -> fn() -> i32:
    var xs: Vec[i32] = Vec.new()
    () =>
        xs.push(1)
        xs.len32()

fn main:
    let f = counter()
    print(f())
