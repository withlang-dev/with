//! expect-check-fail: closure argument holds `n` by place — a view of this frame — and `add` stores or returns its parameter

// #1698: the callable parameter is pushed into an owned parameter that is
// returned — stored and returned; the loop local `n` would dangle.
type Reg { fs: Vec[fn() -> i32] }
fn add(r: Reg, f: fn() -> i32) -> Reg:
    var out = r
    out.fs.push(f)
    out
fn main:
    var r = Reg { fs: Vec.new() }
    for i in 0..3:
        let n = i * 10
        r = add(r, () => n)
    print((r.fs[0])())
