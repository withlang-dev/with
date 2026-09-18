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

fn resource() -> Resource: unsafe { Resource { ptr: with_alloc(32) } }
fn consume(value: Resource): ()
async fn ready() -> Resource: resource()

fn drive_until_done(task: &Task[Resource]):
    var steps = 0
    while not task.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn drop_completed_task():
    let task = ready()
    drive_until_done(&task)

fn main:
    unsafe { DROPS = 0 }
    let baseline = unsafe { with_fiber_live_fibers() }

    let awaited = ready()
    consume(awaited.await)
    unsafe { assert(DROPS == 1) }

    let joined = ready()
    drive_until_done(&joined)
    joined.join_cleanup()
    unsafe { assert(DROPS == 2) }

    drop_completed_task()
    unsafe:
        assert(DROPS == 3)
        assert(with_fiber_live_fibers() == baseline)
    print("cleanup-result-ownership-ok")
