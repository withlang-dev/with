// #1919: this module's own `extern fn unlink` — the C symbol — beside
// std.libc's `pub fn unlink`, which another module of the program imports.
extern fn unlink(path: *const u8) -> i32

pub fn extern_owner_remove(p: *const u8) -> i32:
    unsafe { unlink(p) }
