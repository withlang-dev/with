//! expect-check-fail: use of moved value

type Handle { id: i32 }
impl Handle:
    fn drop(move self: Self): ()

@[effect(handle: consume)]
extern "C" fn close_external(handle: Handle) -> Unit

fn main:
    let handle = Handle { id: 1 }
    unsafe { close_external(handle) }
    let _ = handle.id
