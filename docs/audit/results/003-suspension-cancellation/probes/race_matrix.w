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

async fn staged() -> i32:
    let held = unsafe { Resource { ptr: with_alloc(24) } }
    let _ = tick().await
    let _ = tick().await
    let _ = tick().await
    consume(held)
    7

fn drive_steps(count: i32):
    var i = 0
    while i < count:
        unsafe { with_runtime_run_one_step() }
        i = i + 1

fn main:
    unsafe { DROPS = 0 }
    let baseline = unsafe { with_fiber_live_fibers() }
    for offset in 0..10:
        let task = staged()
        drive_steps(offset)
        task.cancel()
        task.cancel()
        task.join_cleanup()
        assert(unsafe { with_fiber_live_fibers() } == baseline)
    unsafe { assert(DROPS == 10) }
    print("race-matrix-ok")
