var RC_ARC_DROP_TRACE = ""

type RefCountGuard { id: str }

impl Drop for RefCountGuard:
    fn drop(move self: Self):
        RC_ARC_DROP_TRACE = RC_ARC_DROP_TRACE ++ self.id

type RefCountPayload {
    name: str,
    score: i32,
}

impl RefCountPayload:
    fn label(self: &Self) -> str:
        self.name

fn test_rc_clone_count_and_last_drop:
    RC_ARC_DROP_TRACE = ""
    {
        let a = Rc.new(RefCountGuard { id: "R" })
        assert(a.strong_count() == 1)
        {
            let b = a.clone()
            assert(a.strong_count() == 2)
            assert(b.strong_count() == 2)
            assert(RC_ARC_DROP_TRACE == "")
        }
        assert(a.strong_count() == 1)
        assert(RC_ARC_DROP_TRACE == "")
    }
    assert(RC_ARC_DROP_TRACE == "R")

fn test_arc_clone_count_and_last_drop:
    RC_ARC_DROP_TRACE = ""
    {
        let a = Arc.new(RefCountGuard { id: "A" })
        assert(a.strong_count() == 1)
        {
            let b = a.clone()
            assert(a.strong_count() == 2)
            assert(b.strong_count() == 2)
            assert(RC_ARC_DROP_TRACE == "")
        }
        assert(a.strong_count() == 1)
        assert(RC_ARC_DROP_TRACE == "")
    }
    assert(RC_ARC_DROP_TRACE == "A")

fn test_rc_arc_auto_deref:
    let rc = Rc.new(RefCountPayload { name: "Ada", score: 3 })
    let arc = Arc.new(RefCountPayload { name: "Grace", score: 5 })
    assert(rc.name == "Ada")
    assert(rc.label() == "Ada")
    assert(arc.name == "Grace")
    assert(arc.label() == "Grace")
