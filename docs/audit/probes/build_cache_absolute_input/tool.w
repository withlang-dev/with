use std.process

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32

fn main -> i32:
    let argv = args()
    if argv.len() != 3:
        return 2
    let data = unsafe { with_fs_read_file(argv.get(1)) }
    unsafe { with_fs_write_file(argv.get(2), data) }
