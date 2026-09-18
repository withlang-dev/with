use std.task.Task

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var DROPS: i32 = 0

type Resource { ptr: *mut u8 }

impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            DROPS = DROPS + 1

fn consume(value: Resource): ()
async fn tick() -> i32: 1

async fn forever_copy() -> i32:
    while true:
        let _ = tick().await
    1

async fn forever_unit():
    while true:
        let _ = tick().await

async fn forever_owned() -> Resource:
    let held = unsafe { Resource { ptr: with_alloc(32) } }
    while true:
        let _ = tick().await
    consume(held)
    unsafe { Resource { ptr: with_alloc(32) } }

async fn parent_copy() -> i32: forever_copy().await

async fn parent_unit() -> i32:
    forever_unit().await
    0

async fn parent_owned() -> i32:
    let value = forever_owned().await
    consume(value)
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
    unsafe { DROPS = 0 }
    print("copy")
    cancel_case(parent_copy())
    print("unit")
    cancel_case(parent_unit())
    print("owned")
    cancel_case(parent_owned())
    unsafe { assert(DROPS == 1) }
    print("direct-shapes-cancel-ok")
