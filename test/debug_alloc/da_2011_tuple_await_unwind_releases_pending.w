//! expect-debug-alloc: leak count=0
//! expect-stdout: resumed=0 live=0
// #2011 (§14.7): a tuple await `(left, right).await` awaits its tasks in
// order. When the parent is cancelled while it is suspended on `left`, the
// cancellation unwind must cancel and join `right` too: it is still owned
// here and nothing else will release it. Before, the unwind released only
// `left` and `right`'s fiber lived on (and its result buffer leaked).
use std.task.Task
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var resumed: Atomic[i32]

async fn tick() -> i32: 1

async fn wait_forever(value: i32) -> Vec[i32]:
    while true:
        let _ = tick().await
    [value]

async fn parent -> i32:
    let left = wait_forever(1)
    let right = wait_forever(2)
    let (a, b) = (left, right).await
    resumed.fetch_add(1, .SeqCst)
    (a.len() + b.len()) as i32

fn main:
    let baseline = with_fiber_live_fibers()
    let p = parent()
    var steps = 0
    while with_fiber_live_fibers() < baseline + 3 and steps < 128:
        with_runtime_run_one_step()
        steps = steps + 1
    p.cancel()
    p.join_cleanup()
    var drain = 0
    while drain < 64:
        with_runtime_run_one_step()
        drain = drain + 1
    let live = with_fiber_live_fibers() - baseline
    print(f"resumed={resumed.load(.SeqCst)} live={live}")
    assert(resumed.load(.SeqCst) == 0 and live == 0)
