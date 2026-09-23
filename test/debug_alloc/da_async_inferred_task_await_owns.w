//! expect-debug-alloc: leak count=0

// #1464: `.await` on a task local frees the result buffer when the local owns
// the task (§14.7, G3: await_task_owns_result asks for the local's scheduled
// value drop). An unannotated async fn's call was typed as the awaited i32 —
// Copy, so no drop was scheduled, the await did not own the buffer, and it
// leaked once per awaited call.
async fn double(x: i32): x * 2
async fn name(n: i32): f"n{n}"

fn main:
    let t1 = double(5)
    let t2 = name(3)
    assert(t1.await == 10)
    assert(t2.await == "n3")
    print("ok")
