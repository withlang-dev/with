// Migrated from C
use std.zlib.defs
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32
use std.zlib.inftrees

pub fn zlibVersion() -> *const i8 {
    return (&"1.3.2"[0] as *mut c_char)

}

pub fn zlibCompileFlags() -> c_ulong {
    var __local_flags: c_ulong

    (__local_flags = ((0 as c_ulong)))

    while true {
        match (sizeof[c_uint]() as c_int) {
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
        match (sizeof[c_ulong]() as c_int) {
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
        match (sizeof[usize]() as c_int) {
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
        match (sizeof[i64]() as c_int) {
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

pub fn zError(__param_err: c_int) -> *const i8 {
    var __ci_expr_ternary_1: c_int = 0

    var __ci_expr_logic_0: c_int

    if ((if __param_err < -6: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_err > 2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = ((9 as c_int)))
    } else {
        (__ci_expr_ternary_1 = (((2 - __param_err) as c_int)))
    }

    return z_errmsg[__ci_expr_ternary_1]


}

pub unsafe fn zcalloc(__param_opaque_: *mut c_void, __param_items: c_uint, __param_size: c_uint) -> *mut c_void {
    __param_opaque_

    var __ci_expr_ternary_0: *mut c_void = null

    if ((if sizeof[c_uint]() > 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((with_alloc(((((__param_items as c_uint) *% (__param_size as c_uint)) as c_ulong) as i64)) as *mut c_void)))
    } else {
        (__ci_expr_ternary_0 = ((with_alloc_zeroed(((__param_items as c_ulong) as i64), ((__param_size as c_ulong) as i64)) as *mut c_void)))
    }

    return __ci_expr_ternary_0


}

pub unsafe fn zcfree(__param_opaque_: *mut c_void, __param_ptr: *mut c_void) -> Unit {
    __param_opaque_

    with_free((__param_ptr as *mut i8))

}
