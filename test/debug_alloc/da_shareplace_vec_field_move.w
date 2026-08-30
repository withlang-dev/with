//! expect-debug-alloc: leak count=0
// #697: a Vec field (Drop-bearing elements) moved out through a share-place
// receiver via the temp-local idiom, no restore. The caller's scope-exit drop
// must see a blanked header — not the stale one — or the elements double-drop
// and the buffer double-frees.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type HolderV { items: Vec[Resource], tag: i32 }

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn eat(v: Vec[Resource]):
    let w = v

extend HolderV:
    mut fn feed():
        var tmp = move self.items
        eat(move tmp)

fn main:
    var drops = 0
    {
        var h = HolderV { items: Vec.new(), tag: 5 }
        h.items.push(new_resource(&raw mut drops))
        h.items.push(new_resource(&raw mut drops))
        h.feed()
    }
    assert(drops == 2)
    print_i32(drops)
