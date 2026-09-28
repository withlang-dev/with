//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `relay` stores or returns its parameter

// #1698: `relay` passes its parameter on to `wrap`, which returns it in a
// struct; the escape reaches `relay`'s summary through the effect fixpoint
// whatever the declaration order.
type Cnt { f: fn() -> i32 }
fn relay(f: fn() -> i32) -> Cnt: wrap(f)
fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let c = relay(() => xs.len32())
    print(c.f())
fn wrap(f: fn() -> i32) -> Cnt: Cnt { f: f }
