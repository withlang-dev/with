//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `later` stores or returns its parameter

// #1698 / §12.4, D63 (3): a non-move closure argument may not be captured
// by a `move ||` closure the callee returns.
fn later(f: fn() -> i32) -> fn() -> i32: move () => f() + 1
fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let g = later(() => xs.len32())
    print(g())
