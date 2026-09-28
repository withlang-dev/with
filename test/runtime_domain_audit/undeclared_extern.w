//! expect-violation: foreign extern 'rt_libc_setlocale' (C symbol 'setlocale') has no domain row
// runtime-domain-audit negative fixture (ruling §52): a libc seam added to a
// runtime file without a row in its facade. The lane must name the extern,
// its C symbol, and the facade the row belongs in.
use std.builtins.c_void

@[link_name("write")]
extern fn rt_libc_write(fd: i32, buf: *const u8, len: u64) -> i64
@[link_name("setlocale")]
extern fn rt_libc_setlocale(category: i32, locale: *const u8) -> *mut u8
extern fn rt_helper(x: i32) -> i32
extern fn with_alloc(size: i64) -> *mut u8

c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    fn rt_libc_write
        preserves domain environ
        preserves domain locale
