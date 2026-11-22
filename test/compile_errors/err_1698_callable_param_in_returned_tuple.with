//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `wrap` stores or returns its parameter

// #1698 / §12.4 (rule 10): a tuple returns the callable parameter.
fn wrap(f: fn() -> i32) -> (i32, fn() -> i32): (1, f)
fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let (a, g) = wrap(() => xs.len32())
    print(g() + a)
