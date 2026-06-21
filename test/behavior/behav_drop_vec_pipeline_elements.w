//! expect-stdout: ok

// [A5] #606: a pipeline of self-returning mutators over Drop elements. Each `push`
// stage moves its temp receiver's buffer forward, so only the final bound `v` owns
// the elements; `v` drops each exactly once at scope exit. (The existing pipeline
// test behav_pipeline_vec_push_chain.w is POD-only; this covers the Drop-element
// gap.) The trailing work in `main` after the call would surface any double-free.

var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn body():
    let v: Vec[W] = Vec.new() |> push(W { tag: 1 }) |> push(W { tag: 2 })

fn main:
    body()
    if COUNT == 2:
        print("ok")
    else:
        print_i32(COUNT)
