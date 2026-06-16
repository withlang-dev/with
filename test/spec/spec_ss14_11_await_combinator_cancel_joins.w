//! expect-stdout: ok

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

fn cancel_parent_and_assert_joined(parent: Task[i32]):
    let baseline = unsafe { with_fiber_live_fibers() }
    drive_until_live_at_least(baseline + 3)
    parent.cancel()
    let _ = parent.await
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    cancel_parent_and_assert_joined(await_all_parent())
    cancel_parent_and_assert_joined(await_first_parent())
    cancel_parent_and_assert_joined(await_any_parent())
    cancel_parent_and_assert_joined(await_settled_parent())
    print("ok")
