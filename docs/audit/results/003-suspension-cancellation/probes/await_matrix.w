use std.task.Task
use std.builtins.print_i32

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var DROPS: i32 = 0
var CLEANUPS: i32 = 0

type Resource { ptr: *mut u8 }

impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            DROPS = DROPS + 1

fn resource() -> Resource:
    unsafe { Resource { ptr: with_alloc(32) } }

fn consume(value: Resource): ()

async fn tick() -> i32: 1
async fn copy_value(value: i32) -> i32: value
async fn unit_value(): ()
async fn owned_value() -> Resource: resource()

async fn nested_owned() -> Resource:
    let value = owned_value().await
    value

async fn forever_owned() -> i32:
    let held = resource()
    while true:
        let _ = tick().await
    consume(held)
    0

async fn direct_parent() -> i32:
    defer: unsafe { CLEANUPS = CLEANUPS + 1 }
    let child = forever_owned()
    child.await

async fn tuple_parent() -> i32:
    defer: unsafe { CLEANUPS = CLEANUPS + 1 }
    let left = forever_owned()
    let right = forever_owned()
    let (a, b) = (left, right).await
    a + b

async fn nested_cancel(depth: i32) -> i32:
    defer: unsafe { CLEANUPS = CLEANUPS + 1 }
    if depth == 0:
        return forever_owned().await
    let child = nested_cancel(depth - 1)
    child.await

async fn await_pre_cancelled(task: Task[i32]) -> i32:
    defer: unsafe { CLEANUPS = CLEANUPS + 1 }
    task.await + 1

async fn tuple_pre_cancelled(task: Task[i32]) -> i32:
    defer: unsafe { CLEANUPS = CLEANUPS + 1 }
    let other = forever_owned()
    let (left, right) = (task, other).await
    left + right

fn drive_until_live(target: i32):
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < target and steps < 256:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= target)

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 256:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn cancel_and_join(task: Task[i32], live_delta: i32):
    let baseline = unsafe { with_fiber_live_fibers() } - 1
    drive_until_live(baseline + live_delta)
    task.cancel()
    task.join_cleanup()
    print_i32(baseline)
    print_i32(unsafe { with_fiber_live_fibers() })
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    unsafe:
        DROPS = 0
        CLEANUPS = 0

    assert(copy_value(42).await == 42)
    unit_value().await
    consume(owned_value().await)
    consume(nested_owned().await)
    let left = copy_value(20)
    let right = copy_value(22)
    let (a, b) = (left, right).await
    assert(a + b == 42)
    let owned_left = owned_value()
    let owned_right = owned_value()
    let (ra, rb) = (owned_left, owned_right).await
    consume(ra)
    consume(rb)
    unsafe { assert(DROPS == 4) }

    cancel_and_join(direct_parent(), 2)
    cancel_and_join(tuple_parent(), 3)
    cancel_and_join(nested_cancel(3), 5)

    var baseline = unsafe { with_fiber_live_fibers() }
    let cancelled = forever_owned()
    drive_until_live(baseline + 2)
    cancelled.cancel()
    drive_until_done(&cancelled)
    let observing = await_pre_cancelled(cancelled)
    drive_until_done(&observing)
    assert(observing.was_cancelled())
    let _ = observing.await
    assert(unsafe { with_fiber_live_fibers() } == baseline)

    baseline = unsafe { with_fiber_live_fibers() }
    let cancelled_tuple = forever_owned()
    drive_until_live(baseline + 2)
    cancelled_tuple.cancel()
    drive_until_done(&cancelled_tuple)
    let tuple_observer = tuple_pre_cancelled(cancelled_tuple)
    drive_until_done(&tuple_observer)
    assert(tuple_observer.was_cancelled())
    let _ = tuple_observer.await
    assert(unsafe { with_fiber_live_fibers() } == baseline)

    unsafe:
        assert(DROPS == 10)
        assert(CLEANUPS == 9)
    print("await-matrix-ok")
