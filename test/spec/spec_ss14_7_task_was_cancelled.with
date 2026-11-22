//! expect-stdout: ok

use std.task.Task
extern fn with_runtime_run_one_step() -> Unit

async fn tick() -> i32:
    1

async fn complete(value: i32) -> i32:
    value

async fn wait_until_cancelled() -> i32:
    while true:
        let _ = tick().await
    0

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 64:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn test_normal_task_observation:
    let task = complete(41)
    no_suspend:
        assert(not task.was_cancelled())
    assert(task.await == 41)

// The handle is observed before the await that consumes it (§14.7's
// example; §22 `t.await // OK: consumes the task`, #2011).
fn test_cancelled_task_observation:
    let task = wait_until_cancelled()
    assert(not task.was_cancelled())
    task.cancel()
    drive_until_done(&task)
    assert(task.was_cancelled())
    let _ = task.await

fn test_scoped_task_observation:
    async scope s =>:
        let task = s.track(complete(42))
        assert(not task.was_cancelled())
        assert(task.await == 42)
        0

fn main:
    test_normal_task_observation()
    test_cancelled_task_observation()
    test_scoped_task_observation()
    print("ok")
