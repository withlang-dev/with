//! expect-debug-alloc: leak count=0
//! expect-stdout: res_drops=2 after_loop=0 live=0
// #1986 (§14.7): a `break` (or `continue`) unwinds the scopes it leaves —
// each scope's defers, then its drops, innermost first. When a defer in an
// outer scope awaits and the fiber is cancelled at that await, the
// cancellation unwind runs only the cleanup still pending on that path: the
// inner scope's locals the break already dropped are not dropped again.
use std.task.Task
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var res_drops: Atomic[i32]
var after_loop: Atomic[i32]

type Res { data: Vec[i32] }
impl Drop for Res:
    move fn drop():
        res_drops.fetch_add(1, .SeqCst)

async fn tick() -> i32: 1

async fn wait_forever() -> i32:
    while true:
        let _ = tick().await
    0

async fn break_parent -> i32:
    var i = 0
    while i < 3:
        defer:
            let _ = wait_forever().await
        if i == 0:
            let r = Res { data: [1, 2, 3] }
            if r.data.len() > 0:
                break
        i = i + 1
    after_loop.fetch_add(1, .SeqCst)
    i

async fn continue_parent -> i32:
    var i = 0
    while i < 3:
        i = i + 1
        defer:
            let _ = wait_forever().await
        if i == 1:
            let r = Res { data: [4, 5] }
            if r.data.len() > 0:
                continue
    after_loop.fetch_add(1, .SeqCst)
    i

fn cancel_while_suspended(p: Task[i32]) -> i32:
    let baseline = with_fiber_live_fibers()
    var steps = 0
    while with_fiber_live_fibers() < baseline + 2 and steps < 128:
        with_runtime_run_one_step()
        steps = steps + 1
    p.cancel()
    p.join_cleanup()
    with_fiber_live_fibers()

fn main:
    let baseline = with_fiber_live_fibers()
    var live = cancel_while_suspended(break_parent()) - baseline
    live = live + cancel_while_suspended(continue_parent()) - baseline
    print(f"res_drops={res_drops.load(.SeqCst)} after_loop={after_loop.load(.SeqCst)} live={live}")
    assert(res_drops.load(.SeqCst) == 2 and after_loop.load(.SeqCst) == 0 and live == 0)
