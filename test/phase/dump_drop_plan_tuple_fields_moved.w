//! args: --dump-drop-plan
//! expect-check-stdout: drop-plan module
// Post-#691 reset-on-move: a moved-out field is blanked (const zst) and
// truthfully reads Init, while the aggregate itself gets NO drop row — a
// blanked W must never run drop glue. Each moved-out W drops exactly once
// via its destination local.
//! expect-check-stdout: remaining=_2=Maybe, _2.0=Init, _2.1=Init
//! expect-check-stdout-not: place=_2 

type W { slot: *mut i32 }

impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    var pair = (W { slot: slot }, W { slot: slot })
    let a = move pair.0
    let b = move pair.1
    let _ = a
    let _ = b

fn main:
    var count = 0
    run(&raw mut count)
