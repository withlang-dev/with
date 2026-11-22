//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `wrap` stores or returns its parameter

// #1698 / §12.4, D63 (3): a non-move closure argument is ephemeral in the
// callee exactly as a `&T` parameter is — "it may be invoked and passed on,
// and may not be stored, returned, or captured by a `move ||` closure".
// `wrap` pushes its parameter into the List it returns; that is a store and a
// return, so the non-move closure is refused at the call even though `xs`
// is still alive where the result is read. `move () => ...` is the owning
// spelling.
fn wrap(f: fn() -> i32) -> List[fn() -> i32]:
    var v: List[fn() -> i32] = List.new()
    v.push(f)
    v
fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let fs = wrap(() => xs.len32())
    print((fs[0])())
