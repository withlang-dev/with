//! zutil probe: version string, compile flags, error strings, allocator.
//! Oracle: C zlib semantics (version "1.3.2", flags 169 on LP64,
//! z_errmsg table, malloc-backed zcalloc).

use std.zlib.zutil
use std.zlib.defs

fn main:
    // version string is exactly "1.3.2"
    assert(strcmp(zlibVersion(), c"1.3.2".ptr) == 0)
    print("ok zutil version")

    // LP64 flags: u32=4 -> 1, ulong=8 -> 8, usize=8 -> 32, i64=8 -> 128
    assert(zlibCompileFlags() == 169 as c_ulong)
    print("ok zutil flags")

    // error strings follow the z_errmsg table (index 2-err)
    assert(strcmp(zError(1), c"stream end".ptr) == 0)
    assert(strcmp(zError(-2), c"stream error".ptr) == 0)
    assert(strcmp(zError(-3), c"data error".ptr) == 0)
    assert(strcmp(zError(-4), c"insufficient memory".ptr) == 0)
    assert(strcmp(zError(-5), c"buffer error".ptr) == 0)
    assert(strcmp(zError(-6), c"incompatible version".ptr) == 0)
    // out-of-range errors fall back to ""
    assert(strcmp(zError(99), c"".ptr) == 0)
    assert(strcmp(zError(-99), c"".ptr) == 0)
    print("ok zutil zerror")

    // allocator pair: zcalloc hands out usable memory, zcfree takes it back
    let p = unsafe { zcalloc(0 as *mut c_void, 16 as c_uint, 4 as c_uint) }
    assert(p as i64 != 0)
    unsafe { *(p as *mut u8) = 42 as u8 }
    assert(unsafe { *(p as *mut u8) } == 42 as u8)
    unsafe { zcfree(0 as *mut c_void, p) }
    print("ok zutil alloc")
