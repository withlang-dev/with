//! expect-debug-alloc: leak count=0
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn mkw(s: *mut i32) -> List[W]:
    let values: List[W] = List.new()
    values.push(new_w(s))
    values.push(new_w(s))
    values

fn consume(values: List[W]):
    drop(values)

fn run(s: *mut i32):
    var values = mkw(s)
    // D5 (§3.8): consume() takes ownership, so the call site says `move`.
    // (This fixture predated the share-place flip's consume enforcement
    // and was un-compilable for two weeks — the lane ran in no battery.)
    consume(move values)
    values = mkw(s)
    let _ = values.len()

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
