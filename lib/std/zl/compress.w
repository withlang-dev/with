// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32

pub unsafe fn compress(__param_dest: *mut u8, __param_destLen: *mut c_ulong, __param_source: *const u8, __param_sourceLen: c_ulong) -> c_int {
    return compress2(__param_dest, __param_destLen, __param_source, __param_sourceLen, (-1 as c_int))

}

pub unsafe fn compress_z(__param_dest: *mut u8, __param_destLen: *mut c_ulong, __param_source: *const u8, __param_sourceLen: c_ulong) -> c_int {
    return compress2_z(__param_dest, __param_destLen, __param_source, __param_sourceLen, (-1 as c_int))

}

pub unsafe fn compress2(__param_dest: *mut u8, __param_destLen: *mut c_ulong, __param_source: *const u8, __param_sourceLen: c_ulong, __param_level: c_int) -> c_int {
    var __local_ret: c_int

    var __local_got: c_ulong = (unsafe *__param_destLen)

    (__local_ret = ((compress2_z(__param_dest, (&raw mut __local_got as *mut c_ulong), __param_source, __param_sourceLen, __param_level) as c_int)))

    ((unsafe *__param_destLen) = __local_got)

    return __local_ret

}

pub unsafe fn compress2_z(__param_dest: *mut u8, __param_destLen: *mut c_ulong, __param_source: *const u8, __param_sourceLen: c_ulong, __param_level: c_int) -> c_int {
    var __local_sourceLen = __param_sourceLen
    var __local_stream: z_stream_s

    var __local_err: c_int

    var __local_max: c_uint = ((-1 as c_uint))

    var __local_left: c_ulong

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_sourceLen > 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_source == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_destLen == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_2: c_int = 0

        if ((if (unsafe *__param_destLen) > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __param_dest == null: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        return -2
    }


    (__local_left = (unsafe *__param_destLen))

    ((unsafe *__param_destLen) = ((0 as c_ulong)))

    (__local_stream.zalloc = ((0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)))

    (__local_stream.zfree = ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)))

    (__local_stream.opaque_ = ((0 as *mut c_void)))

    (__local_err = ((deflateInit_((&raw mut __local_stream as *mut z_stream_s), __param_level, c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        return __local_err
    }

    (__local_stream.next_out = __param_dest)

    (__local_stream.avail_out = ((0 as c_uint)))

    (__local_stream.next_in = ((__param_source as *mut u8)))

    (__local_stream.avail_in = ((0 as c_uint)))

    loop {
        if ((if (unsafe *(&raw const __local_stream as *const z_stream_s)).avail_out == 0: 1 else: 0) != 0) {
            var __ci_expr_ternary_4: c_uint = 0

            if ((if __local_left > ((4294967295 as c_ulong)): 1 else: 0) != 0) {
                (__ci_expr_ternary_4 = ((4294967295 as c_uint)))
            } else {
                (__ci_expr_ternary_4 = ((__local_left as c_uint)))
            }

            (__local_stream.avail_out = __ci_expr_ternary_4)


            (__local_left = (__local_left -% (unsafe *(&raw const __local_stream as *const z_stream_s)).avail_out))

        }

        if ((if (unsafe *(&raw const __local_stream as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0) {
            var __ci_expr_ternary_5: c_uint = 0

            if ((if __local_sourceLen > ((4294967295 as c_ulong)): 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = ((4294967295 as c_uint)))
            } else {
                (__ci_expr_ternary_5 = ((__local_sourceLen as c_uint)))
            }

            (__local_stream.avail_in = __ci_expr_ternary_5)


            (__local_sourceLen = (__local_sourceLen -% (unsafe *(&raw const __local_stream as *const z_stream_s)).avail_in))

        }

        var __ci_expr_ternary_6: c_int = 0

        if (__local_sourceLen != 0) {
            (__ci_expr_ternary_6 = ((0 as c_int)))
        } else {
            (__ci_expr_ternary_6 = ((4 as c_int)))
        }

        (__local_err = ((deflate((&raw mut __local_stream as *mut z_stream_s), __ci_expr_ternary_6) as c_int)))


        if not (((if __local_err == 0: 1 else: 0) != 0)) {
            break
        }
    }

    ((unsafe *__param_destLen) = ((((((unsafe *(&raw const __local_stream as *const z_stream_s)).next_out as usize) -% (__param_dest as usize)) / sizeof[u8]()) as c_ulong)))

    deflateEnd((&raw mut __local_stream as *mut z_stream_s))

    var __ci_expr_ternary_7: c_int = 0

    if ((if __local_err == 1: 1 else: 0) != 0) {
        (__ci_expr_ternary_7 = ((0 as c_int)))
    } else {
        (__ci_expr_ternary_7 = __local_err)
    }

    return __ci_expr_ternary_7


}

pub fn compressBound(__param_sourceLen: c_ulong) -> c_ulong {
    var __local_bound: c_ulong = ((compressBound_z(__param_sourceLen) as c_ulong))

    var __ci_expr_ternary_0: c_ulong = 0

    if ((if __local_bound != __local_bound: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((-1 as c_ulong)))
    } else {
        (__ci_expr_ternary_0 = __local_bound)
    }

    return __ci_expr_ternary_0


}

pub fn compressBound_z(__param_sourceLen: c_ulong) -> c_ulong {
    var __local_bound: c_ulong = ((((((((((__param_sourceLen as c_ulong) +% (((__param_sourceLen as c_ulong) >> (12 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (14 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (25 as c_uint)) as c_ulong)) as c_ulong) +% (13 as c_ulong)) as c_ulong))

    var __ci_expr_ternary_0: c_ulong = 0

    if ((if __local_bound < __param_sourceLen: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((-1 as c_ulong)))
    } else {
        (__ci_expr_ternary_0 = __local_bound)
    }

    return __ci_expr_ternary_0


}
