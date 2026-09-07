use std.task.Task
use std.builtins.print_i32

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var ARM: i32 = 0

async fn tick() -> i32: 1

async fn forever() -> i32:
    while true:
        let _ = tick().await
    0

async fn ready() -> i32: 9

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

async fn choose(cancelled: Task[i32]) -> i32:
    let normal = ready()
    select await biased:
        value = cancelled =>
            unsafe { ARM = 1 }
            value
        value = normal =>
            unsafe { ARM = 2 }
            value

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let victim = forever()
    victim.cancel()
    drive_until_done(&victim)
    let parent = choose(victim)
    drive_until_done(&parent)
    unsafe { print_i32(ARM) }
    print_i32(if parent.was_cancelled(): 1 else: 0)
    let _ = parent.await
    assert(unsafe { with_fiber_live_fibers() } == baseline)
    unsafe { assert(ARM == 0) }
