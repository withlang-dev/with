//! expect-check-fail: = help: write `move fn drop()`
// §2.4: a destructor always consumes, and the error on any other receiver
// mode carries the fix-it the spec promises. (A bare `fn drop()` inherits
// the trait's move receiver and is fine.)
type W { id: i32 }

impl Drop for W:
    mut fn drop():
        ()

fn main:
    let w = W { id: 1 }
    let _ = w.id
