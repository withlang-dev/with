//! expect-debug-alloc: leak count=0

// A read-only accessor into Vec[Drop] returns a view of the element owned by
// the Vec. Materializing an owned copy here would free the element's storage
// once at the accessor caller's scope exit and again with the Vec.
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, drops: *mut i32 }

impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.drops = *self.drops + 1

type Body { values: Vec[W] }

fn new_w(drops: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), drops } }

fn body_at(bodies: &Vec[Body], index: i64) -> &Body:
    assert(index >= 0 and index < bodies.len())
    unsafe { (bodies.as_ptr() + (index as usize)) as &Body }

fn main:
    var drops = 0
    let values: Vec[W] = Vec.new()
    values.push(new_w(&raw mut drops))
    let bodies: Vec[Body] = Vec.new()
    bodies.push(Body { values })
    let body = body_at(&bodies, 0)
    assert(body.values.len() == 1)
