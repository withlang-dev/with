//! expect-stdout: read 18 bytes: line one|line two|
//! expect-stdout: exists=true
//! expect-stdout: exists after=false

use std.fs

fn main:
    let path = "wasm_fs_fixture_scratch.txt"
    write_file(path, "line one\nline two\n")
    let text = read_file(path) ?? ""
    print(f"read {text.len()} bytes: {text.replace("\n", "|")}")
    print(f"exists={file_exists(path)}")
    remove_file(path)
    print(f"exists after={file_exists(path)}")
