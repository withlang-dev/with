//! expect-stdout: ok

// [A5] #606: a self-returning mutator (`xs.push`) as the *tail* of a helper with
// no return annotation. The aliasing result does not escape into a captured owner,
// so the local `xs` drops its element exactly once locally — no leak, no
// double-free. The trailing work in `main` (after the call returns) would expose
// any double-free via heap corruption; it must stay clean.

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
