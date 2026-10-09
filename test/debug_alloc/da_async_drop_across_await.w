//! expect-debug-alloc: leak count=0
// M8 (Slice F): a Drop value held live across a suspend (await) must be preserved
// and dropped exactly once. With's async is fiber-based, so the value stays on the
// fiber stack across the suspend (no copy/zero of generator state); the niche
// drops it normally at scope exit / on move.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn consume(r: Resource): ()

async fn ping() -> i32:
    1

async fn struct_across(slot: *mut i32) -> i32:
    let r = new_resource(slot)   // Drop value, provably live across the suspend
    let x = ping().await
    consume(r)                   // moved + dropped after the suspend
    x

async fn list_across(slot: *mut i32) -> i32:
    var v: List[Resource] = List.new()
    v.push(new_resource(slot))
    v.push(new_resource(slot))
    let x = ping().await         // List[Drop] live across the suspend
    v.len() as i32               // dropped (elements + buffer) at scope exit

async fn main:
    var drops = 0
    let a = struct_across(&raw mut drops).await
    let b = list_across(&raw mut drops).await
    print_i32(drops)             // 3: one struct + two List elements
