//! expect-stdout: page_view

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> void

async fn tick() -> i32:
    1

async fn send_analytics(event: str) -> i32:
    let _ = tick().await
    print(event)
    0

fn test_discarded_task_cancels:
    let baseline = with_fiber_live_fibers()
    let _ = send_analytics("cancelled")
    var steps = 0
    while with_fiber_live_fibers() > baseline and steps < 16:
        with_runtime_run_one_step()
        steps = steps + 1
    assert(with_fiber_live_fibers() == baseline)

fn main:
    test_discarded_task_cancels()
    spawn send_analytics("page_view")
