use std.task.Task

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

type Big { a: i64, b: i64, c: i64, d: i64 }
type Waiter { marker: i32 }

async fn tick() -> i32: 1

async fn forever_i32() -> i32:
    while true:
        let _ = tick().await
    7

async fn forever_big() -> Big:
    while true:
        let _ = tick().await
    Big { a: 1, b: 2, c: 3, d: 4 }

fn wait_scalar(task: Task[i32]) -> i32: task.await
fn wait_unit(task: Task[i32]): let _ = task.await
fn wait_big(task: Task[Big]) -> Big: task.await
fn wait_generic[T](task: Task[T]) -> T: task.await

impl Waiter:
    fn wait(task: Task[i32]) -> i32: task.await

trait DynWait:
    fn wait_dyn(self: &Self, task: Task[i32]) -> i32

impl DynWait for Waiter:
    fn wait_dyn(task: Task[i32]) -> i32: task.await

fn call_dyn(waiter: &dyn DynWait, task: Task[i32]) -> i32: waiter.wait_dyn(task)
fn invoke(callback: fn(Task[i32]) -> i32, task: Task[i32]) -> i32: callback(task)
fn invoke_raw(callback: *const fn(Task[i32]) -> i32, task: Task[i32]) -> i32: callback(task)

async fn parent_direct() -> i32:
    wait_scalar(forever_i32())
    print("continued-direct")
    0

async fn parent_unit() -> i32:
    wait_unit(forever_i32())
    print("continued-unit")
    0

async fn parent_big() -> i32:
    wait_big(forever_big())
    print("continued-big")
    0

async fn parent_generic() -> i32:
    wait_generic(forever_i32())
    print("continued-generic")
    0

async fn parent_method() -> i32:
    let waiter = Waiter { marker: 0 }
    waiter.wait(forever_i32())
    print("continued-method")
    0

async fn parent_closure() -> i32:
    let offset = 0
    invoke(task => task.await + offset, forever_i32())
    print("continued-closure")
    0

async fn parent_raw() -> i32:
    invoke_raw(&wait_scalar, forever_i32())
    print("continued-raw")
    0

async fn parent_dyn() -> i32:
    let waiter = Waiter { marker: 0 }
    call_dyn(&waiter, forever_i32())
    print("continued-dyn")
    0

fn drive_until_live_at_least(target: i32):
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < target and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= target)

fn cancel_and_join(baseline: i32, parent: Task[i32]):
    drive_until_live_at_least(baseline + 2)
    parent.cancel()
    parent.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    var baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_direct())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_unit())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_big())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_generic())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_method())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_closure())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_raw())
    baseline = unsafe { with_fiber_live_fibers() }
    cancel_and_join(baseline, parent_dyn())
    print("completion-matrix-done")
