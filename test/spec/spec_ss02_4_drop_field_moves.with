// Spec test: Section 2.4 — Drop Field Moves (formerly 25.80)

var DROP_FIELD_MOVE_TRACE = ""

type DropFieldMoveFile { id: str }
impl Drop for DropFieldMoveFile:
    fn drop(move self: Self):
        DROP_FIELD_MOVE_TRACE = DROP_FIELD_MOVE_TRACE ++ self.id

type DropFieldMoveName { id: str }
impl Drop for DropFieldMoveName:
    fn drop(move self: Self):
        DROP_FIELD_MOVE_TRACE = DROP_FIELD_MOVE_TRACE ++ self.id

type DropFieldMoveWrapper { fd: DropFieldMoveFile, name: DropFieldMoveName }
impl Drop for DropFieldMoveWrapper:
    fn drop(move self: Self):
        let taken = self.fd
        DROP_FIELD_MOVE_TRACE = DROP_FIELD_MOVE_TRACE ++ "W"

fn drop_field_move_make_wrapper:
    let _w = DropFieldMoveWrapper {
        fd: DropFieldMoveFile { id: "F" },
        name: DropFieldMoveName { id: "N" },
    }

// PASS: field moves are allowed inside drop, and only remaining fields are dropped after the body.
fn test_drop_field_move_inside_drop:
    DROP_FIELD_MOVE_TRACE = ""
    drop_field_move_make_wrapper()
    assert(DROP_FIELD_MOVE_TRACE == "WFN")
