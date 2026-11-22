//! args: --validate-all
//! expect-check-stdout: validate-all: ok

type FileId = distinct i32

fn root_file -> FileId:
    return FileId(0)

fn file_from_view(value: &i32) -> FileId:
    FileId(value)

fn main:
    let raw_file_id = 7
    assert((root_file() as i32) == 0)
    assert((file_from_view(raw_file_id) as i32) == 7)
