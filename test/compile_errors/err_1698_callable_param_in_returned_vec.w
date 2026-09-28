//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `wrap` stores or returns its parameter

// #1698 / §12.4, D63 (3): a non-move closure argument is ephemeral in the
// callee exactly as a `&T` parameter is — "it may be invoked and passed on,
// and may not be stored, returned, or captured by a `move ||` closure".
// `wrap` pushes its parameter into the Vec it returns; that is a store and a
// return, so the non-move closure is refused at the call even though `xs`
// is still alive where the result is read. `move () => ...` is the owning
// spelling.
fn wrap(f: fn() -> i32) -> Vec[fn() -> i32]:
    var v: Vec[fn() -> i32] = Vec.new()
    v.push(f)
    v
fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let fs = wrap(() => xs.len32())
    print((fs[0])())
