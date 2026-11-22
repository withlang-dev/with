//! expect-check-fail: escaping `move` closure captures `f`, which views a local of this frame

// #1698 / §12.4: a non-move closure "may not be … captured by a `move ||`
// closure": the owned environment would hold a pointer into this frame.
fn mk() -> fn() -> i32:
    var xs: List[i32] = List.new()
    let f = () => xs.len32()
    move () => f() + 1
fn main:
    let g = mk()
    print(g())
