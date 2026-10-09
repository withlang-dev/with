//! expect-debug-alloc: leak count=0
//! expect-stdout: resumed=0 item_drops=0 live=0
// #2019 (§14.3 INVARIANT 5, §14.7): a lazy adapter (`xs.iter().map(f)`)
// holds its closure; the closure runs inside whatever drives the adapter.
// When the fiber is cancelled while that closure is suspended, the driving
// call — collect, fold, count, find, any, for_each, reduce, next, directly
// or through a binding — must stop there and its caller must unwind,
// releasing what was built. Before, the terminal went on with the
// never-written value (a double free of garbage Items) and the caller
// resumed past the call.
use std.task.Task
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var resumed: Atomic[i32]
var item_drops: Atomic[i32]

type Item { data: List[i32] }
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

fn sink(n: i32): resumed.fetch_add(n, .SeqCst)

async fn collect_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let items: List[Item] = xs.iter().map(n => forever_item(n).await).collect()
    resumed.fetch_add(1, .SeqCst)
    items.len() as i32

async fn bound_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let chain = xs.iter().map(n => forever_item(n).await)
    let items: List[Item] = chain.collect()
    resumed.fetch_add(1, .SeqCst)
    items.len() as i32

async fn next_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    var chain = xs.iter().map(n => forever_item(n).await)
    let first = chain.next()
    resumed.fetch_add(1, .SeqCst)
    if first.is_some(): 1 else: 0

async fn fold_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let total = xs.iter().fold(0, (acc, n) => acc + forever_value(n).await)
    resumed.fetch_add(1, .SeqCst)
    total

async fn map_fold_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let total = xs.iter().map(n => forever_value(n).await).fold(0, (a, b) => a + b)
    resumed.fetch_add(1, .SeqCst)
    total

async fn reduce_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let total = xs.iter().map(n => forever_value(n).await).reduce((a, b) => a + b)
    resumed.fetch_add(1, .SeqCst)
    if total.is_some(): 1 else: 0

async fn filter_count_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let n = xs.iter().filter(n => forever_value(n).await > 0).count()
    resumed.fetch_add(1, .SeqCst)
    n as i32

async fn find_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let found = xs.iter().find(n => forever_value(n).await > 0)
    resumed.fetch_add(1, .SeqCst)
    if found.is_some(): 1 else: 0

async fn any_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    let hit = xs.iter().any(n => forever_value(n).await > 0)
    resumed.fetch_add(1, .SeqCst)
    if hit: 1 else: 0

async fn for_each_parent -> i32:
    let xs: List[i32] = [1, 2, 3]
    xs.iter().for_each(n => sink(forever_value(n).await))
    resumed.fetch_add(1, .SeqCst)
    0

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
    var live = cancel_while_suspended(collect_parent()) - baseline
    live = live + cancel_while_suspended(bound_parent()) - baseline
    live = live + cancel_while_suspended(next_parent()) - baseline
    live = live + cancel_while_suspended(fold_parent()) - baseline
    live = live + cancel_while_suspended(map_fold_parent()) - baseline
    live = live + cancel_while_suspended(reduce_parent()) - baseline
    live = live + cancel_while_suspended(filter_count_parent()) - baseline
    live = live + cancel_while_suspended(find_parent()) - baseline
    live = live + cancel_while_suspended(any_parent()) - baseline
    live = live + cancel_while_suspended(for_each_parent()) - baseline
    print(f"resumed={resumed.load(.SeqCst)} item_drops={item_drops.load(.SeqCst)} live={live}")
    assert(resumed.load(.SeqCst) == 0 and item_drops.load(.SeqCst) == 0 and live == 0)
