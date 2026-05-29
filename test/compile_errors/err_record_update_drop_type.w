//! expect-check-fail: partial move from Drop type

type RecordUpdateDropFile { id: str }
impl Drop for RecordUpdateDropFile:
    fn drop(move self: Self):
        let _ = self.id

type RecordUpdateDropWrapper { fd: RecordUpdateDropFile, name: str }
impl Drop for RecordUpdateDropWrapper:
    fn drop(move self: Self):
        let _ = self.name

fn bad_record_update:
    let w = RecordUpdateDropWrapper {
        fd: RecordUpdateDropFile { id: "F" },
        name: "A",
    }
    let _w2 = { w with name: "B" }
