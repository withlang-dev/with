// T15 probe: Box.new must not drop at box time; payload drops exactly once
// at scope exit (guards the f50684ec double-drop fix).
use std.box.Box
use std.builtins.print

global var BOX_DROP_TRACE = ""

type BoxDropGuard { id: str }

impl Drop for BoxDropGuard:
    fn drop(move self: Self):
        BOX_DROP_TRACE = BOX_DROP_TRACE ++ self.id

fn main:
    BOX_DROP_TRACE = ""
    {
        let guard = Box.new(BoxDropGuard { id: "G" })
        assert(BOX_DROP_TRACE == "")
        assert(guard.id == "G")
    }
    assert(BOX_DROP_TRACE == "G")
    print("box-drop-once-ok")
