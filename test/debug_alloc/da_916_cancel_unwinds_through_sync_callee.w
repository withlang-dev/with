//! expect-debug-alloc: leak count=0
//! expect-stdout: resumed=0 batch_drops=0 live=0
// #916 (§14.7): an async caller cancelled while it is suspended inside a SYNC
// callee (one that awaits) must unwind through the call. The callee leaves
// by its cancellation unwind and never produces its value, so the caller
// neither resumes past the call nor drops the result. Before the fix the
// caller resumed and dropped the never-written return slot (a garbage `len`,
// or an invalid free when the garbage looked like a pointer). Covered: a
// direct call, and a generic callee reached through a pipeline stage.
use std.task.Task
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var resumed: Atomic[i32]
var batch_drops: Atomic[i32]

type Batch { values: List[i32] }
impl Drop for Batch:
    move fn drop():
        batch_drops.fetch_add(1, .SeqCst)

async fn tick() -> i32: 1

async fn wait_forever(value: i32) -> i32:
    while true:
        let _ = tick().await
    value

// Sync fns that suspend: they await each task.
fn eat(tasks: List[Task[i32]]) -> Batch:
    let pending = tasks
    defer:
        while pending.len() > 0: pending.remove(0).join_cleanup()
    let values: List[i32] = List.new()
    while pending.len() > 0:
        values.push(pending.remove(0).await)
    Batch { values }

fn eat_all[T](tasks: List[Task[T]]) -> List[T]:
    let pending = tasks
    defer:
        while pending.len() > 0: pending.remove(0).join_cleanup()
    let values: List[T] = List.new()
    while pending.len() > 0:
        values.push(pending.remove(0).await)
    values

async fn parent -> i32:
    let tasks: List[Task[i32]] = List.new()
    tasks.push(wait_forever(1))
    tasks.push(wait_forever(2))
    let batch = eat(tasks)
    resumed.fetch_add(1, .SeqCst)
    batch.values.len() as i32

async fn generic_parent -> i32:
    let tasks: List[Task[i32]] = List.new()
    tasks.push(wait_forever(1))
    tasks.push(wait_forever(2))
    let values = tasks |> eat_all
    resumed.fetch_add(1, .SeqCst)
    values.len() as i32

fn cancel_while_suspended(p: Task[i32]) -> i32:
    let baseline = with_fiber_live_fibers()
    var steps = 0
    while with_fiber_live_fibers() < baseline + 3 and steps < 128:
        with_runtime_run_one_step()
        steps = steps + 1
    p.cancel()
    p.join_cleanup()
    with_fiber_live_fibers()

fn main:
    let baseline = with_fiber_live_fibers()
    let a = cancel_while_suspended(parent())
    let b = cancel_while_suspended(generic_parent())
    let live = a + b - 2 * baseline
    print(f"resumed={resumed.load(.SeqCst)} batch_drops={batch_drops.load(.SeqCst)} live={live}")
    assert(resumed.load(.SeqCst) == 0 and batch_drops.load(.SeqCst) == 0 and live == 0)
