//! expect-stdout: ok

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> void

async fn tick() -> i32:
    1

async fn borrow_until_cancel(value: &i32) -> i32:
    assert(*value == 41)
    while true:
        let _ = tick().await
    0

async fn owned_until_cancel(value: i32) -> i32:
    assert(value == 42)
    while true:
        let _ = tick().await
    0

async fn owned_once(value: i32) -> i32:
    value + 1

fn return_task_from_tail -> Task[i32]:
    let task = owned_once(10)
    task

fn return_task_from_statement -> Task[i32]:
    let task = owned_once(20)
    return task

async fn test_ephemeral_task_drop_joins:
    let baseline = unsafe { with_fiber_live_fibers() }
    let value = 41
    let _ = borrow_until_cancel(&value)
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_non_ephemeral_task_drop_cancels:
    let baseline = unsafe { with_fiber_live_fibers() }
    let _ = owned_until_cancel(42)
    var steps = 0
    while unsafe { with_fiber_live_fibers() } > baseline and steps < 32:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_returned_task_is_not_dropped:
    let tail_task = return_task_from_tail()
    assert(tail_task.await == 11)
    let statement_task = return_task_from_statement()
    assert(statement_task.await == 21)

async fn main:
    test_ephemeral_task_drop_joins().await
    test_non_ephemeral_task_drop_cancels()
    test_returned_task_is_not_dropped()
    print("ok")
