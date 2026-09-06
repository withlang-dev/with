use std.task.Task
use std.builtins.print_i32

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0

async fn tick() -> i32: 1

trait Runner:
    fn run(self: &Self) -> i32

type Suspender {}

impl Runner for Suspender:
    fn run(self: &Self) -> i32:
        while true:
            let _ = tick().await
        1

fn invoke(runner: &dyn Runner) -> i32: runner.run()

async fn parent() -> i32:
    let runner = Suspender {}
    let _ = invoke(&runner)
    unsafe { AFTER = AFTER + 1 }
    0

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let task = parent()
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < baseline + 2 and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    task.cancel()
    task.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)
    unsafe:
        print_i32(AFTER)
        assert(AFTER == 0)
