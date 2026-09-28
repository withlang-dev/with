//! expect-check-fail: closure argument holds `xs` by place — a view of this frame — and `add` stores or returns its parameter

// #1698 / #1783: a `mut fn` storing its callable parameter into the
// receiver stores it; a non-move closure may not reach it.
type Reg { fs: Vec[fn() -> i32] }
impl Reg:
    mut fn add(f: fn() -> i32): self.fs.push(f)
fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    var r = Reg { fs: Vec.new() }
    r.add(() => xs.len32())
    print((r.fs[0])())
