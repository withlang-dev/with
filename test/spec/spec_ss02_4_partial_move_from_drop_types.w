// Spec test: Section 2.4 — Partial Move from Drop Types (formerly 25.64)

var PARTIAL_MOVE_DROP_TRACE = ""

type PartialMoveFile { id: str }
impl Drop for PartialMoveFile:
    fn drop(move self: Self):
        PARTIAL_MOVE_DROP_TRACE = PARTIAL_MOVE_DROP_TRACE ++ self.id

type PartialMoveWrapper { fd: PartialMoveFile, name: str }
impl Drop for PartialMoveWrapper:
    fn drop(move self: Self):
        PARTIAL_MOVE_DROP_TRACE = PARTIAL_MOVE_DROP_TRACE ++ self.name

fn partial_move_make_wrapper:
    let _w = PartialMoveWrapper {
        fd: PartialMoveFile { id: "F" },
        name: "W",
    }

// PASS: constructing and dropping the whole Drop value is allowed.
fn test_partial_move_whole_value_ok:
    PARTIAL_MOVE_DROP_TRACE = ""
    partial_move_make_wrapper()
    assert(PARTIAL_MOVE_DROP_TRACE == "WF")
