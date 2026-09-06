extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_runtime_run_one_step() -> Unit
extern fn with_fiber_request_cancel_self() -> Unit

type Resource { ptr: *mut u8 }

impl Drop for Resource:
    fn drop(move self: Self): unsafe { with_free(self.ptr) }

fn consume(value: Resource): ()
async fn tick() -> i32: 1

async fn self_cancel() -> Resource:
    unsafe { with_fiber_request_cancel_self() }
    let _ = tick().await
    unsafe { Resource { ptr: with_alloc(32) } }

async fn ready() -> Resource: unsafe { Resource { ptr: with_alloc(32) } }

async fn choose() -> i32:
    let cancelled = self_cancel()
    let normal = ready()
    select await biased:
        value = cancelled =>
            consume(value)
            1
        value = normal =>
            consume(value)
            2

fn main:
    let parent = choose()
    var steps = 0
    while not parent.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(parent.is_done())
    assert(parent.was_cancelled())
    let _ = parent.await
