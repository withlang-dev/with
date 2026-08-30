//! expect-debug-alloc: leak count=0
// #697: conditional move of a Box FIELD with a non-zero sibling field. On the
// moving path the field is blanked (null Box); the owner's member drop must
// skip it via the member-level guard rather than calling the concrete Box drop
// on null. Was: SIGSEGV in Box.drop dereferencing the blanked pointer.
use std.box.Box
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type HolderB { b: Box[Resource], tag: i32 }

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn take_box(x: Box[Resource]):
    let sink = x

fn run_box_field(cond: bool, slot: *mut i32):
    var h = HolderB { b: Box.new(new_resource(slot)), tag: 3 }
    if cond:
        var tmp = move h.b
        take_box(move tmp)
    print_i32(h.tag)

fn main:
    var drops = 0
    run_box_field(true, &raw mut drops)
    assert(drops == 1)
    run_box_field(false, &raw mut drops)
    assert(drops == 2)
    print_i32(drops)
