//! expect-stdout: ok
// #953 (spec §10.2 `read_file(path)?`), closing #909: read_file reports the
// OS error instead of "". A missing path is Err(IoError.Os(2, path)) whose
// message has the spec's shape, a directory is EISDIR, `?` propagates the
// error, and an empty file is Ok("") — never confused with a failure.
use std.fs
use std.process

fn load(path: &str) -> Result[i64, IoError]:
    let text = read_file(path)?
    text.len()

fn main:
    let dir = "out/tmp/behav_fs_read_file_io_error_" ++ f"{pid()}"
    assert(mkdir_p(dir) == 0)
    let missing = dir ++ "/missing.txt"
    match read_file(missing):
        Ok(_) => assert(false)
        Err(e) =>
            // message() first: the destructuring match below consumes e (#1040)
            assert(e.message().contains("No such file or directory (os error 2)"))
            match e:
                IoError.Os(code, path) =>
                    assert(code == 2)
                    assert(path == missing)
    match read_file(dir):
        Ok(_) => assert(false)
        Err(IoError.Os(code, path)) =>
            assert(code == 21)  // EISDIR
            assert(path == dir)
    match load(missing):
        Ok(_) => assert(false)
        Err(IoError.Os(code, path)) =>
            assert(code == 2)
            assert(path == missing)
    let empty = dir ++ "/empty.txt"
    assert(write_file(empty, "") == 0)
    assert(read_file(empty).unwrap() == "")
    let full = dir ++ "/full.txt"
    assert(write_file(full, "payload\n") == 0)
    assert(load(full).unwrap() == 8)
    assert(remove_file(empty) == 0)
    assert(remove_file(full) == 0)
    assert(remove_dir(dir) == 0)
    print("ok")
