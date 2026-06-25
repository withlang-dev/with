//! args: --dump-drop-plan
//! expect-check-stdout: drop-plan module
//! expect-check-stdout: _2.0=Moved
//! expect-check-stdout: _2.1=Moved

type W { slot: *mut i32 }

impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let pair = (W { slot: slot }, W { slot: slot })
    let a = pair.0
    let b = pair.1
    let _ = a
    let _ = b

fn main:
    var count = 0
    run(&raw mut count)
