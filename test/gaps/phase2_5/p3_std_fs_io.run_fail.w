// Phase 3 gap: std.fs runtime coverage incomplete
use std.fs

fn main() -> i32 =
    let path = "/tmp/with_fs_gap.txt"
    let w = write_file(path, "abc")
    if w != 0 then return 1
    let text = read_file(path)
    if text.len() == 3 then 0 else 1
