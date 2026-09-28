//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `wrap` stores or returns its parameter

// #1698 / §12.4 (rule 10): `Some(f)` returns the callable parameter.
fn wrap(f: fn() -> i32) -> Option[fn() -> i32]: Some(f)
fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let g = wrap(() => xs.len32())
    print(g.unwrap()())
