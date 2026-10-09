//! expect-debug-alloc: leak count=0

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_w(slot: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot } }

fn bare_chain(slot: *mut i32):
    // The receiver remains the final pipeline value but is not captured, so
    // the hidden place and both live elements drop at statement end.
    List[W].new() |> push(new_w(slot)) |> push(new_w(slot))

fn run(slot: *mut i32):
    // `push` keeps carrying the hidden List place; `pop` switches the carried
    // value to Option[W]. The List temporary therefore drops at statement end,
    // while `item` owns the removed W until this scope exits.
    let item: Option[W] = List[W].new() |> push(new_w(slot)) |> pop()
    assert(item.is_some())

fn main:
    var drops = 0
    bare_chain(&raw mut drops)
    assert(drops == 2)
    run(&raw mut drops)
    assert(drops == 3)
