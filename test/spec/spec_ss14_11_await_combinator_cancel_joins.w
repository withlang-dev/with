//! known-issue: #916 async caller of a cancelled sync-but-suspending callee consumes its garbage return
//! expect-stdout: ok

use std.task.Task
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

async fn tick() -> i32:
    1

async fn wait_forever(value: i32) -> i32:
    while true:
        let _ = tick().await
    value

async fn wait_forever_result(value: i32) -> Result[i32, str]:
    while true:
        let _ = tick().await
    Ok(value)

async fn await_all_parent -> i32:
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(wait_forever(1))
    tasks.push(wait_forever(2))
    let _ = tasks |> await_all
    0

async fn await_all_result_parent -> i32:
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(wait_forever_result(1))
    tasks.push(wait_forever_result(2))
    let _ = tasks |> await_all
    0

async fn await_first_parent -> i32:
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(wait_forever(1))
    tasks.push(wait_forever(2))
    let _ = tasks |> await_first
    0

async fn await_any_parent -> i32:
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(wait_forever_result(1))
    tasks.push(wait_forever_result(2))
    let _ = tasks |> await_any
    0

async fn await_settled_parent -> i32:
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(wait_forever_result(1))
    tasks.push(wait_forever_result(2))
    let _ = tasks |> await_settled
    0

fn drive_until_live_at_least(target: i32):
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < target and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= target)

fn cancel_parent_and_assert_joined(baseline: i32, parent: Task[i32]):
    drive_until_live_at_least(baseline + 3)
    parent.cancel()
    parent.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    var baseline = unsafe { with_fiber_live_fibers() }
    cancel_parent_and_assert_joined(baseline, await_all_parent())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_parent_and_assert_joined(baseline, await_all_result_parent())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_parent_and_assert_joined(baseline, await_first_parent())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_parent_and_assert_joined(baseline, await_any_parent())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_parent_and_assert_joined(baseline, await_settled_parent())
    print("ok")
