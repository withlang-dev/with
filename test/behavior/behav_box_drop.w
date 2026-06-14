var BOX_DROP_TRACE = ""

type BoxDropGuard { id: str }

impl Drop for BoxDropGuard:
    fn drop(move self: Self):
        BOX_DROP_TRACE = BOX_DROP_TRACE ++ self.id

fn test_box_drops_payload_at_scope_exit:
    BOX_DROP_TRACE = ""
    {
        let guard = Box.new(BoxDropGuard { id: "G" })
        assert(BOX_DROP_TRACE == "")
        assert(guard.id == "G")
    }
    assert(BOX_DROP_TRACE == "G")

fn test_box_into_inner_returns_payload:
    BOX_DROP_TRACE = ""
    let guard = Box.new(BoxDropGuard { id: "I" }).into_inner()
    assert(BOX_DROP_TRACE == "")
    drop(guard)
    assert(BOX_DROP_TRACE == "I")
