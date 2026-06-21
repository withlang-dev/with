//! expect-stdout: ok

// [A5] #606: a self-returning mutator (`xs.push`) used as a *statement* discards
// its aliasing result, leaving the receiver live and reusable. Two pushes then
// further use of `xs` must drop each element exactly once at scope exit (no
// premature drop, no double-free).

var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn body() -> i64:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })
    xs.push(W { tag: 2 })
    // receiver still live and reusable after the push statements:
    xs.len()

fn main:
    let n = body()
    if COUNT == 2 and n == 2:
        print("ok")
    else:
        print_i32(COUNT)
