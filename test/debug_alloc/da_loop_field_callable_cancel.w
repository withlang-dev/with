//! expect-debug-alloc: leak count=0
//! expect-stdout: resumed=0 live=0
// §14.3 INVARIANT 5 / §14.7: a callable held in a field and invoked inside a
// `loop:` suspends the body that holds the loop, so a cancellation while
// the callable is suspended unwinds the caller past the call. The suspend
// walk did not enter `loop:` (it entered `while`), so the body was judged
// never to suspend and its caller resumed with a never-written value.
use std.task.Task
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var resumed: Atomic[i32]

async fn tick() -> i32: 1

async fn forever_value(n: i32) -> i32:
    while true:
        let _ = tick().await
    n

type Wrap { f: fn(i32) -> i32 }

impl Wrap:
    fn apply(x: i32) -> i32:
        loop:
            match Some(x):
                None => return 0
                Some(y) => return (self.f)(y)

async fn parent -> i32:
    let w = Wrap { f: n => forever_value(n).await }
    let v = w.apply(1)
    resumed.fetch_add(1, .SeqCst)
    v

fn cancel_while_suspended(p: Task[i32]) -> i32:
    let baseline = with_fiber_live_fibers()
    var steps = 0
    while with_fiber_live_fibers() < baseline + 2 and steps < 128:
        with_runtime_run_one_step()
        steps = steps + 1
    p.cancel()
    p.join_cleanup()
    var drain = 0
    while drain < 64:
        with_runtime_run_one_step()
        drain = drain + 1
    with_fiber_live_fibers()

fn main:
    let baseline = with_fiber_live_fibers()
    let live = cancel_while_suspended(parent()) - baseline
    print(f"resumed={resumed.load(.SeqCst)} live={live}")
