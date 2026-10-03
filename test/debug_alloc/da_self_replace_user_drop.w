//! expect-debug-alloc: leak count=0
// D12: bare-self replacement in a `mut fn` on a user-Drop owner must drop
// the OLD value exactly once (through the share-place ref param — the same
// assign-site drop path locals use) and leave the new value owned by the
// caller. slot counts drops; ptr is a real allocation so over/under-drop
// shows up as leak or double-free.

use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type R { id: i32, ptr: *mut u8, slot: *mut i32 }
impl Drop for R:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id
            with_free(self.ptr)

fn make(id: i32, slot: *mut i32) -> R:
    unsafe { R { id: id, ptr: with_alloc(16), slot: slot } }

extend R:
    mut fn replace(new_id: i32):
        self = make(new_id, self.slot)
    mut fn replace_if(new_id: i32, go: bool):
        if not go:
            return
        self.replace(new_id)

fn main:
    var drops: i32 = 0
    let slot = &raw mut drops
    // Straight line: old (id=1) drops at replacement.
    var r = make(1, slot)
    r.replace(2)
    assert(drops == 1)
    assert(r.id == 2)

    // Branch: only the taken path replaces.
    r.replace_if(3, false)
    assert(drops == 1)
    r.replace_if(3, true)
    assert(drops == 3)

    // Loop: each predecessor drops exactly once (ids 3, 10, 11 drop:
    // 3 + 3 + 10 + 11 = 27).
    for i in 0..3:
        r.replace(10 + i)
    assert(drops == 27)
    print_i32(drops)
