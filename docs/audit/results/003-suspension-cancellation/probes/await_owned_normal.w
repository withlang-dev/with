extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

var DROPS: i32 = 0

type Resource { ptr: *mut u8 }

impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            DROPS = DROPS + 1

fn resource() -> Resource: unsafe { Resource { ptr: with_alloc(32) } }
fn consume(value: Resource): ()
async fn owned() -> Resource: resource()

async fn nested() -> Resource:
    let value = owned().await
    value

fn main:
    unsafe { DROPS = 0 }
    consume(owned().await)
    consume(nested().await)
    let left = owned()
    let right = owned()
    let (a, b) = (left, right).await
    consume(a)
    consume(b)
    unsafe { assert(DROPS == 4) }
    print("await-owned-normal-ok")
