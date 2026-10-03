//! expect-stdout: ok

// D21: a direct `push` tail has Unit type. The receiver remains the sole owner,
// so `xs` drops its element and buffer exactly once locally. The trailing work
// in `main` would expose premature or duplicate cleanup via heap corruption.

var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn body():
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })

fn main:
    body()
    if COUNT == 1:
        print("ok")
    else:
        print_i32(COUNT)
