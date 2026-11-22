//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `wrap` stores or returns its parameter

// #1698 / §12.4, D63 (3): `wrap` returns its callable parameter inside a
// struct; a non-move closure may not be returned by the callee.
type Cnt { f: fn() -> i32 }
fn wrap(f: fn() -> i32) -> Cnt: Cnt { f: f }
fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let c = wrap(() => xs.len32())
    print(c.f())
