//! expect-debug-alloc: leak count=0
// #952: every with_fs_* wrapper made a NUL-terminated copy of its path for the
// C call and never freed it — one leak per call, sized by the path. Ten
// wrapper calls here; the debug allocator must see none of their copies at
// exit. #951 rides along: write_file's result is asserted, and a short write
// (a full device) must report failure, never 0.
use std.fs
use std.process

fn main:
    let dir = "out/tmp/da_fs_wrappers_" ++ f"{pid()}"
    assert(mkdir_p(dir) == 0)
    let path = dir ++ "/probe.txt"
    assert(write_file(path, "payload\n") == 0)
    assert(file_exists(path))
    assert(file_exists(path))
    assert(read_file(path) == "payload\n")
    assert(list_files_text(dir).len() > 0)
    let moved = dir ++ "/moved.txt"
    assert(rename_file(path, moved) == 0)
    assert(remove_file(moved) == 0)
    assert(remove_dir(dir) == 0)
    assert(write_file("/dev/full", "payload") != 0)
