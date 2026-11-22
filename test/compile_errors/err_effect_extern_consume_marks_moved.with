//! expect-check-fail: use of moved value

// §16.3d / G1: an extern fn declared `@[effect(handle: consume)]` takes
// ownership of the argument, so it must be transferred with `move`; using
// `handle` afterwards is a use-after-move.

type Handle { id: i32 }
impl Handle:
    fn drop(move self: Self): ()

@[effect(handle: consume)]
extern "C" fn close_external(handle: Handle) -> Unit

fn main:
    let handle = Handle { id: 1 }
    unsafe { close_external(move handle) }
    let _ = handle.id
