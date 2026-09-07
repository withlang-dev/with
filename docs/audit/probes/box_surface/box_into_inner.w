// T15 probe: into_inner transfers ownership — no drop at unbox, exactly one
// drop when the extracted value drops.
use std.box.Box
use std.builtins.print

global var BOX_INNER_TRACE = ""

type InnerGuard { id: str }

impl Drop for InnerGuard:
    fn drop(move self: Self):
        BOX_INNER_TRACE = BOX_INNER_TRACE ++ self.id

fn main:
    BOX_INNER_TRACE = ""
    let guard = Box.new(InnerGuard { id: "I" }).into_inner()
    assert(BOX_INNER_TRACE == "")
    drop(guard)
    assert(BOX_INNER_TRACE == "I")
    print("box-into-inner-ok")
