//! expect-debug-alloc: leak count=0
// M8 (Slice F): a Drop value live across a suspend must drop exactly once whether
// the task COMPLETES or is CANCELLED. `select await` cancels the loser; the slow
// task holds a Drop local across its suspend. Either outcome (slow wins → consume
// drops it; fast wins → slow's fiber unwinds and drops it) must be leak-free.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn consume(r: Resource): ()

async fn inner1() -> i32: 1
async fn inner2() -> i32: 2

async fn deep() -> i32:
    let a = inner1().await
    let b = inner2().await
    a + b

async fn slow(slot: *mut i32) -> i32:
    let r = new_resource(slot)   // Drop local live across the suspend below
    let d = deep().await
    consume(r)
    d

async fn fast() -> i32: 1

async fn main:
    var drops = 0
    let st = slow(&raw mut drops)
    let ft = fast()
    select await:
        x = ft => ()
        y = st => ()
    print_i32(drops)
