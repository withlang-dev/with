//! expect-debug-alloc: leak count=0
// A7 (#606): enum-payload discards in a consuming match — a `_` payload
// pattern, a `..` payload rest, and the whole-subject `_` arm — own what they
// discard and must free each Drop payload exactly once.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

enum E { A(W, W) | B }

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn run_payload_wildcard(s: *mut i32):
    match E.A(new_w(s), new_w(s)):
        .A(a, _) => ()
        .B => ()

fn run_payload_rest(s: *mut i32):
    match E.A(new_w(s), new_w(s)):
        .A(a, ..) => ()
        .B => ()

fn run_arm_whole_wildcard(s: *mut i32):
    match E.A(new_w(s), new_w(s)):
        _ => ()

fn main:
    var c = 0
    run_payload_wildcard(&raw mut c)
    run_payload_rest(&raw mut c)
    run_arm_whole_wildcard(&raw mut c)
    print_i32(c)
