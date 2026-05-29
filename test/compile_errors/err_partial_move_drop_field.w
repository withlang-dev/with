//! expect-check-fail: partial move from Drop type

type PartialMoveFieldFile { id: str }
impl Drop for PartialMoveFieldFile:
    fn drop(move self: Self):
        let _ = self.id

type PartialMoveFieldWrapper { fd: PartialMoveFieldFile, name: str }
impl Drop for PartialMoveFieldWrapper:
    fn drop(move self: Self):
        let _ = self.name

fn bad_partial_field_move:
    let w = PartialMoveFieldWrapper {
        fd: PartialMoveFieldFile { id: "F" },
        name: "W",
    }
    let _fd = w.fd
