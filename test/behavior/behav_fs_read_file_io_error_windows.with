//! only-on: windows
//! expect-stdout: ok
// #953 on Windows, where IoError.Os carries the Win32 code and its message
// is the system's text for it (#2773). A missing path is
// ERROR_FILE_NOT_FOUND (2); a directory is ERROR_DIRECTORY_NOT_SUPPORTED
// (336), never POSIX's EISDIR (21), which Win32 reads as ERROR_NOT_READY,
// "The device is not ready". `?` propagates; an empty file is Ok("").
use std.fs
use std.process

fn load(path: &str) -> Result[i64, IoError]:
    let text = read_file(path)?
    text.len()

fn main:
    let dir = "out/tmp/behav_fs_read_file_io_error_windows_" ++ f"{pid()}"
    assert(mkdir_p(dir) == 0)
    let missing = dir ++ "/missing.txt"
    match read_file(missing):
        Ok(_) => assert(false)
        Err(e) =>
            assert(e.message().contains("The system cannot find the file specified (os error 2)"))
            match e:
                IoError.Os(code, path) =>
                    assert(code == 2)
                    assert(path == missing)
    match read_file(dir):
        Ok(_) => assert(false)
        Err(e) =>
            assert(e.message().contains("(os error 336)"))
            assert(not e.message().contains("device is not ready"))
            match e:
                IoError.Os(code, path) =>
                    assert(code == 336)
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
