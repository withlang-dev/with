// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.deflate
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.compress
use std.engines.zlib.uncompr
use std.engines.zlib.gzlib
use std.engines.zlib.gzwrite
use std.engines.zlib.gzread
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32
use std.engines.zlib.inftrees

pub fn zlibVersion() -> *const c_char {
    return (&"1.3.2"[0] as *mut c_char)

}

pub fn zlibCompileFlags() -> u64 {
    var __local_flags: u64

    (__local_flags = ((0 as u64)))

    while true {
        match (sizeof[u32]() as i32) {
            2 => {
                0
            },
            4 => {
                (__local_flags = (__local_flags +% 1))
            },
            8 => {
                (__local_flags = (__local_flags +% 2))
            },
            _ => {
                (__local_flags = (__local_flags +% 3))
            },
        }

        break

    }

    while true {
        match (sizeof[u64]() as i32) {
            2 => {
                0
            },
            4 => {
                (__local_flags = (__local_flags +% 4))
            },
            8 => {
                (__local_flags = (__local_flags +% 8))
            },
            _ => {
                (__local_flags = (__local_flags +% 12))
            },
        }

        break

    }

    while true {
        match (sizeof[usize]() as i32) {
            2 => {
                0
            },
            4 => {
                (__local_flags = (__local_flags +% 16))
            },
            8 => {
                (__local_flags = (__local_flags +% 32))
            },
            _ => {
                (__local_flags = (__local_flags +% 48))
            },
        }

        break

    }

    while true {
        match (sizeof[i64]() as i32) {
            2 => {
                0
            },
            4 => {
                (__local_flags = (__local_flags +% 64))
            },
            8 => {
                (__local_flags = (__local_flags +% 128))
            },
            _ => {
                (__local_flags = (__local_flags +% 192))
            },
        }

        break

    }

    return __local_flags

}

pub fn zError(__param_err: i32) -> *const c_char {
    var __ci_expr_ternary_1: i32 = 0

    var __ci_expr_logic_0: i32

    if (__param_err < -6) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_err > 2: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_ternary_1 = ((9 as i32)))
    } else {
        (__ci_expr_ternary_1 = (((2 - __param_err) as i32)))
    }

    return ((z_errmsg[__ci_expr_ternary_1] as *const c_char))


}

// contract: unproved:0:read only
pub unsafe fn zcalloc(__param_opaque_: *mut c_void, __param_items: u32, __param_size: u32) -> *mut c_void {

    return (((if (sizeof[u32]() as usize) > 2: (with_alloc(((((__param_items as u32) *% (__param_size as u32)) as u64) as i64)) as *mut c_void) else: (with_alloc_zeroed(((__param_items as u64) as i64), ((__param_size as u64) as i64)) as *mut c_void)) as *mut c_void))

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn zcfree(__param_opaque_: *mut c_void, __param_ptr: *mut c_void) {

    with_free((__param_ptr as *mut u8))

}
