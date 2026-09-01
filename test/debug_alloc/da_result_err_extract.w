//! expect-debug-alloc: leak count=0

// The ok()/err() eliminators TRANSFER the payload out of an owned Result:
// the receiver's scheduled drop must skip what the Option now owns, and
// the un-extracted other-variant payload must still drop once. Before the
// fix, r.err().unwrap() extracted the payload while r's enum drop still
// freed it (double free / freed-payload reads — the #724 acceptance chase).
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, drops: *mut i32, n: i32 }

impl Drop for W:
    move fn drop():
        unsafe:
            with_free(self.ptr)
            *self.drops = *self.drops + 1

fn new_w(drops: *mut i32, n: i32) -> W:
    unsafe { W { ptr: with_alloc(24), drops, n } }

fn make_err(drops: *mut i32, n: i32) -> Result[i32, W]:
    Err(new_w(drops, n))

fn make_ok(drops: *mut i32, n: i32) -> Result[W, i32]:
    Ok(new_w(drops, n))

fn main:
    var drops = 0
    // err() extracts: exactly one owner, exactly one drop
    let r1 = make_err(&raw mut drops, 1)
    var e = r1.err().unwrap()
    assert(e.n == 1)
    assert(drops == 0)
    drop(move e)
    assert(drops == 1)
    // ok() twin
    let r2 = make_ok(&raw mut drops, 2)
    var o = r2.ok().unwrap()
    assert(o.n == 2)
    drop(move o)
    assert(drops == 2)
    // wrong-variant eliminator: the un-extracted payload still drops once
    let r3 = make_err(&raw mut drops, 3)
    let none = r3.ok()
    assert(none.is_none())
    assert(drops == 3)
    print_i32(drops)
