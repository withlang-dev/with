//! expect-stdout: ok

// D21: direct `push` calls return Unit and mutate `xs` in place. Two statements
// followed by a read leave the single receiver owner live until scope exit,
// where both elements and the Vec buffer drop exactly once.

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
