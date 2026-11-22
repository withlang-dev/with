//! expect-stdout: page_view

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit
extern fn with_fiber_is_cancelled() -> i32

async fn tick() -> i32:
    1

async fn send_analytics(event: str) -> i32:
    let _ = tick().await
    if unsafe { with_fiber_is_cancelled() } != 0:
        print("cancelled")
    else:
        print(event)
    0

fn test_statement_task_detaches:
    let baseline = unsafe { with_fiber_live_fibers() }
    send_analytics("page_view")
    var steps = 0
    while unsafe { with_fiber_live_fibers() } > baseline and steps < 16:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } == baseline)

async fn main:
    test_statement_task_detaches()
