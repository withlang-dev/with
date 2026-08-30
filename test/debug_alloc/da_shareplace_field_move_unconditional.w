//! expect-debug-alloc: leak count=0
// #697: an UNCONDITIONAL field move (via a temp local) inside a mut-receiver
// method. The receiver is a share-place borrow — the owner's scope-exit drop
// runs in the CALLER, which cannot see the callee's move — so reset-on-move
// must blank the field through the receiver pointer, and the owner's member
// drop must skip the sentinel. Was: user drop double-ran on stale bits and the
// allocation double-freed. The non-zero `tag` defeats the whole-struct-zero
// accident that masked this class.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type Holder { r: Resource, tag: i32 }

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn take(r: Resource):
    let sink = r

extend Holder:
    mut fn feed():
        var tmp = move self.r
        take(move tmp)

fn main:
    var drops = 0
    {
        var h = Holder { r: new_resource(&raw mut drops), tag: 9 }
        h.feed()
    }
    assert(drops == 1)
    print_i32(drops)
