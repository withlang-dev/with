use std.task.Task
use std.builtins.print_i32

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0
var CALLEE_CLEANUPS: i32 = 0

async fn tick() -> i32: 1

fn wait_unit():
    defer: unsafe { CALLEE_CLEANUPS = CALLEE_CLEANUPS + 1 }
    while true:
        let _ = tick().await

fn wait_copy() -> i32:
    defer: unsafe { CALLEE_CLEANUPS = CALLEE_CLEANUPS + 1 }
    while true:
        let _ = tick().await
    1

fn wait_generic[T](value: T) -> T:
    while true:
        let _ = tick().await
    value

type Waiter {}

fn Waiter.wait(self: &Self) -> i32:
    defer: unsafe { CALLEE_CLEANUPS = CALLEE_CLEANUPS + 1 }
    while true:
        let _ = tick().await
    1

fn invoke(cb: fn() -> i32) -> i32: cb()

async fn parent_unit() -> i32:
    wait_unit()
    unsafe { AFTER = AFTER + 1 }
    0

async fn parent_copy() -> i32:
    let _ = wait_copy()
    unsafe { AFTER = AFTER + 1 }
    0

async fn parent_generic() -> i32:
    let _ = wait_generic(7)
    unsafe { AFTER = AFTER + 1 }
    0

async fn parent_method() -> i32:
    let waiter = Waiter {}
    let _ = waiter.wait()
    unsafe { AFTER = AFTER + 1 }
    0

async fn parent_callable() -> i32:
    let cb = () => wait_copy()
    let _ = invoke(cb)
    unsafe { AFTER = AFTER + 1 }
    0

fn drive_until_live(target: i32):
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < target and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= target)

fn cancel_case(task: Task[i32]):
    let baseline = unsafe { with_fiber_live_fibers() } - 1
    drive_until_live(baseline + 2)
    task.cancel()
    task.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    unsafe:
        AFTER = 0
        CALLEE_CLEANUPS = 0
    cancel_case(parent_unit())
    cancel_case(parent_copy())
    cancel_case(parent_generic())
    cancel_case(parent_method())
    cancel_case(parent_callable())
    unsafe:
        print_i32(AFTER)
        print_i32(CALLEE_CLEANUPS)
        assert(AFTER == 0)
        assert(CALLEE_CLEANUPS == 4)
