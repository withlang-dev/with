//! args: --dump-drop-plan
//! expect-check-stdout: drop-plan module
//! expect-check-stdout: storage-dead local=_2 remaining=_2=Init, _2.0=Reset, _2.1=Reset
// Reset-on-move (§2.5.1): a moved-out field is blanked (const zst) and reads
// Reset, the sentinel that owns nothing (#1384, #1488). A move out of a
// sub-place vacates only that sub-place (#1394), so the tuple itself stays
// Init. It gets no drop row, and a blanked W never runs drop glue: each
// moved-out W drops exactly once via its destination local. The dump covers
// every body, std's included, so the "no drop of `_2`" half is pinned on
// `run` alone by trace_ownership_tuple_fields_moved.w. (#1529: these
// expectations sat below the directive header and were never read; the
// fixture pinned `_2=Maybe` long after the lattice changed.)

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
