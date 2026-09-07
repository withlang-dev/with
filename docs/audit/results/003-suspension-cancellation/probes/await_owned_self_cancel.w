extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

type Resource { ptr: *mut u8 }

impl Drop for Resource:
    fn drop(move self: Self): unsafe { with_free(self.ptr) }

fn consume(value: Resource): ()
async fn tick() -> i32: 1

async fn child() -> Resource:
    let held = unsafe { Resource { ptr: with_alloc(32) } }
    while true:
        let _ = tick().await
    consume(held)
    unsafe { Resource { ptr: with_alloc(32) } }

async fn parent() -> i32:
    let value = child().await
    consume(value)
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
    print("owned-self-cancel-ok")
