// Probe: Rc payload drops exactly once, when the LAST owner exits —
// intermediate clone drops must not run the payload drop.
use std.rc.Rc
use std.builtins.print

global var RC_DROP_TRACE = ""

type RcDropGuard { id: str }

impl Drop for RcDropGuard:
    fn drop(move self: Self):
        RC_DROP_TRACE = RC_DROP_TRACE ++ self.id

fn main:
    RC_DROP_TRACE = ""
    {
        let a = Rc.new(RcDropGuard { id: "G" })
        assert(RC_DROP_TRACE == "")
        {
            let b = a.clone()
            assert(RC_DROP_TRACE == "")
            assert(b.strong_count() == 2)
        }
        // Inner clone dropped: payload must still be alive.
        assert(RC_DROP_TRACE == "")
        assert(a.strong_count() == 1)
    }
    // Last owner dropped: payload drops exactly once.
    assert(RC_DROP_TRACE == "G")
    print("rc-drop-once-ok")
