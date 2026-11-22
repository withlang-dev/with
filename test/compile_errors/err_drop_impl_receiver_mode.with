//! expect-check-fail: Drop.drop receiver must be 'move self: Self'
// §2.4/#642: a destructor always consumes; non-move receivers in a Drop impl
// are rejected at check time (previously they died in codegen).
type W { id: i32 }

impl Drop for W:
    fn drop(mut self) -> Unit:
        ()

fn main:
    let w = W { id: 1 }
    let _ = w.id
