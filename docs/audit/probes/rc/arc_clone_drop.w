// Probe: Arc clone/drop counting + exactly-once payload drop.
use std.rc.Arc
use std.builtins.print

global var ARC_DROP_TRACE = ""

type ArcDropGuard { id: str }

impl Drop for ArcDropGuard:
    fn drop(move self: Self):
        ARC_DROP_TRACE = ARC_DROP_TRACE ++ self.id

fn main:
    ARC_DROP_TRACE = ""
    {
        let a = Arc.new(ArcDropGuard { id: "A" })
        assert(a.strong_count() == 1)
        assert(ARC_DROP_TRACE == "")
        {
            let b = a.clone()
            let c = a.clone()
            assert(a.strong_count() == 3)
            assert(b.strong_count() == 3)
            assert(c.strong_count() == 3)
        }
        assert(a.strong_count() == 1)
        assert(ARC_DROP_TRACE == "")
    }
    assert(ARC_DROP_TRACE == "A")
    print("arc-clone-drop-ok")
