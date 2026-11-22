//! expect-debug-alloc: leak count=0
// D27 supersedes A8's implicit index-extraction surface: array reads are views.
// Observing one or every element, including through a returned view, leaves the
// array as sole owner and drops every allocation-bearing sibling exactly once.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn run_observe_one(s: *mut i32):
    let arr = [new_w(s), new_w(s)]
    let first = arr[0]
    assert(first.slot == s)

fn run_observe_all(s: *mut i32):
    let arr = [new_w(s), new_w(s)]
    let first = arr[0]
    let second = arr[1]
    assert(first.slot == s)
    assert(second.slot == s)

fn first(arr: &[2]W): arr[0]

fn run_returned_view(s: *mut i32):
    let arr = [new_w(s), new_w(s)]
    let view = first(arr)
    assert(view.slot == s)

fn main:
    var c = 0
    run_observe_one(&raw mut c)
    run_observe_all(&raw mut c)
    run_returned_view(&raw mut c)
    assert(c == 6)
    print_i32(c)
