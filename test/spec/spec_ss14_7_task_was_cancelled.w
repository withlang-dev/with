//! expect-stdout: ok

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
    assert(not task.was_cancelled())

fn test_cancelled_task_observation:
    let task = wait_until_cancelled()
    assert(not task.was_cancelled())
    task.cancel()
    drive_until_done(&task)
    let _ = task.await
    assert(task.was_cancelled())

fn test_scoped_task_observation:
    async scope s =>:
        let task = s.track(complete(42))
        assert(not task.was_cancelled())
        assert(task.await == 42)
        assert(not task.was_cancelled())
        0

fn main:
    test_normal_task_observation()
    test_cancelled_task_observation()
    test_scoped_task_observation()
    print("ok")
