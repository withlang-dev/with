use std.process

extern fn with_fs_write_file(path: &str, data: &str) -> i32

fn main -> i32:
    let argv = args()
    if argv.len() != 2:
        return 2
    unsafe { with_fs_write_file(argv.get(1), "B") }
