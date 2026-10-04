//! expect-debug-alloc: leak count=0
//! expect-stdout: resumed=0 item_drops=0 live=0
// #2019 (§14.3, §14.7): `xs.map(f)` and `xs.fold(init, f)` are codegen
// intrinsics that call the closure once per element. When the fiber is
// cancelled while the closure is suspended in an await, the closure leaves
// by its cancellation unwind with no value; the intrinsic must stop there
// and its caller must unwind too, releasing what was built. Before, the loop
// went on, pushed the never-written values, and the caller resumed past the
// call with them.
use std.task.Task
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var resumed: Atomic[i32]
var item_drops: Atomic[i32]

type Item { data: Vec[i32] }
impl Drop for Item:
    move fn drop():
        item_drops.fetch_add(1, .SeqCst)

async fn tick() -> i32: 1

async fn forever_item(n: i32) -> Item:
    while true:
        let _ = tick().await
    Item { data: [n] }

async fn forever_value(n: i32) -> i32:
    while true:
        let _ = tick().await
    n

async fn map_parent -> i32:
    let xs: Vec[i32] = [1, 2, 3]
    let items = xs.map(n => forever_item(n).await)
    resumed.fetch_add(1, .SeqCst)
    items.len() as i32

async fn fold_parent -> i32:
    let xs: Vec[i32] = [1, 2, 3]
    let total = xs.fold(0, (acc, n) => acc + forever_value(n).await)
    resumed.fetch_add(1, .SeqCst)
    total

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
    var live = cancel_while_suspended(map_parent()) - baseline
    live = live + cancel_while_suspended(fold_parent()) - baseline
    print(f"resumed={resumed.load(.SeqCst)} item_drops={item_drops.load(.SeqCst)} live={live}")
    assert(resumed.load(.SeqCst) == 0 and item_drops.load(.SeqCst) == 0 and live == 0)
