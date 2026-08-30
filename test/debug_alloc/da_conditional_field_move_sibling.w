//! expect-debug-alloc: leak count=0
// #697: conditional field move (temp-local idiom) out of a struct with a
// NON-ZERO sibling field. The blank lands on the moving path (#607), but the
// owner is not all-zero, so the whole-value guard passes and the member drops
// run — the blanked field's user drop must be skipped by the member-level
// sentinel guard. Was: user drop ran against the reset sentinel (a
// single-field holder only passed because it became all-zero after the blank).
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

fn run_field(cond: bool, slot: *mut i32):
    var h = Holder { r: new_resource(slot), tag: 7 }
    if cond:
        var tmp = move h.r
        take(move tmp)
    print_i32(h.tag)

fn main:
    var drops = 0
    run_field(true, &raw mut drops)    // moved path: callee drops once, owner skips blank
    assert(drops == 1)
    run_field(false, &raw mut drops)   // live path: owner drops exactly once
    assert(drops == 2)
    print_i32(drops)
