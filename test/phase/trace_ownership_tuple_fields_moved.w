//! args: --trace-ownership run:_2
//! expect-check-stdout: trace-ownership run:_2
//! expect-check-stdout: after=_2=Init, _2.0=Reset, _2.1=Init text="_2.0 = const zst(
//! expect-check-stdout: event=storage-dead before=_2=Init, _2.0=Reset, _2.1=Reset
//! expect-check-stdout-not: event=drop
// The `run` half of dump_drop_plan_tuple_fields_moved.w (#1529): after both
// fields move out and are blanked, the tuple reaches its StorageDead with no
// drop of `_2` or its fields — a blanked W never runs drop glue.

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
