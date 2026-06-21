//! expect-stdout: ok

// [A5] #606: a pipeline of self-returning mutators over Drop elements, BOUND to a
// var that is then USED (and followed by trailing code). Each `push` stage's temp
// receiver is consumed into the next stage, so only the final bound `v` owns the
// elements; `v` drops each exactly once. This exercises the path that previously
// double-freed: when `let v = <pipeline>` is not the last statement, the pipeline's
// intermediate temp receivers must not be dropped (they alias the buffer the result
// carries forward). The POD test behav_pipeline_vec_push_chain.w can't catch this.

var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn body() -> i64:
    let v: Vec[W] = Vec.new() |> push(W { tag: 1 }) |> push(W { tag: 2 })
    // bind, then USE v with trailing code — the shape that was double-freeing:
    v.len()

fn main:
    let n = body()
    if COUNT == 2 and n == 2:
        print("ok")
    else:
        print_i32(COUNT)
