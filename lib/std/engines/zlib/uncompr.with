// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
use std.engines.zlib.deflate
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.compress
use std.engines.zlib.gzlib
use std.engines.zlib.gzwrite
use std.engines.zlib.gzread
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32

// contract: stored-unknown:0,unproved:1:out-parameter written conditionally,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn uncompress(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: u64) -> i32 {
    var __local_used: u64 = __param_sourceLen

    return uncompress2(__param_dest, __param_destLen, __param_source, (&raw mut __local_used as *mut u64))

}

// contract: stored-unknown:0,unproved:1:out-parameter written conditionally,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn uncompress_z(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: u64) -> i32 {
    var __local_used: u64 = __param_sourceLen

    return uncompress2_z(__param_dest, __param_destLen, __param_source, (&raw mut __local_used as *mut u64))

}

// contract: stored-unknown:0,unproved:1:out-parameter read before the write,stored-unknown:2,unproved:3:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn uncompress2(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: *mut u64) -> i32 {
    var __local_ret: i32

    var __local_got: u64 = (*__param_destLen)

    var __local_used: u64 = (*__param_sourceLen)


    (__local_ret = ((uncompress2_z(__param_dest, (&raw mut __local_got as *mut u64), __param_source, (&raw mut __local_used as *mut u64)) as i32)))

    ((*__param_sourceLen) = __local_used)

    ((*__param_destLen) = __local_got)

    return __local_ret

}

// contract: stored-unknown:0,unproved:1:out-parameter written conditionally,stored-unknown:2,unproved:3:out-parameter written conditionally — stores an argument; ownership not modeled
pub unsafe fn uncompress2_z(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: *mut u64) -> i32 {
    var __local_dest = __param_dest
    var __local_stream: z_stream_s

    var __local_err: i32

    var __local_max: u32 = ((-1 as u32))

    var __local_len: u64

    var __local_left: u64


    var __ci_expr_logic_4: i32

    var __ci_expr_logic_2: i32

    var __ci_expr_logic_1: i32

    if (__param_sourceLen == null) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((*__param_sourceLen) > 0) {
            (__ci_expr_logic_0 = (if __param_source == null: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0: 1 else: 0))

    }

    if __ci_expr_logic_1 {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if __param_destLen == null: 1 else: 0))
    }

    if __ci_expr_logic_2 {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_3: i32 = 0

        if ((*__param_destLen) > 0) {
            (__ci_expr_logic_3 = (if __local_dest == null: 1 else: 0))
        }

        (__ci_expr_logic_4 = (if __ci_expr_logic_3: 1 else: 0))

    }

    if __ci_expr_logic_4 {
        return -2
    }


    (__local_len = (*__param_sourceLen))

    (__local_left = (*__param_destLen))

    var __ci_expr_logic_5: i32 = 0

    if (__local_left == 0) {
        (__ci_expr_logic_5 = (if __local_dest == 0: 1 else: 0))
    }

    if __ci_expr_logic_5 {
        (__local_dest = ((((&raw const (*(&raw const __local_stream as *const z_stream_s)).reserved as *const u64) as *mut u64) as *mut u8)))
    }


    (__local_stream.next_in = ((__param_source as *mut u8)))

    (__local_stream.avail_in = ((0 as u32)))

    (__local_stream.zalloc = null)

    (__local_stream.zfree = null)

    (__local_stream.opaque_ = null)

    (__local_err = ((inflateInit_((&raw mut __local_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        return __local_err
    }

    (__local_stream.next_out = __local_dest)

    (__local_stream.avail_out = ((0 as u32)))

    loop {
        if ((*(&raw const __local_stream as *const z_stream_s)).avail_out == 0) {
            (__local_stream.avail_out = (((if __local_left > ((4294967295 as u64)): (4294967295 as u32) else: (__local_left as u32)) as u32)))

            (__local_left = (__local_left -% (*(&raw const __local_stream as *const z_stream_s)).avail_out))

        }

        if ((*(&raw const __local_stream as *const z_stream_s)).avail_in == 0) {
            (__local_stream.avail_in = (((if __local_len > ((4294967295 as u64)): (4294967295 as u32) else: (__local_len as u32)) as u32)))

            (__local_len = (__local_len -% (*(&raw const __local_stream as *const z_stream_s)).avail_in))

        }

        (__local_err = ((inflate((&raw mut __local_stream as *mut z_stream_s), (0 as i32)) as i32)))

        if not ((__local_err == 0)) {
            break
        }
    }

    (__local_len = (__local_len +% (*(&raw const __local_stream as *const z_stream_s)).avail_in))

    (__local_left = (__local_left +% (*(&raw const __local_stream as *const z_stream_s)).avail_out))

    ((*__param_sourceLen) = ((*__param_sourceLen) -% __local_len))

    ((*__param_destLen) = ((*__param_destLen) -% __local_left))

    inflateEnd((&raw mut __local_stream as *mut z_stream_s))

    var __ci_expr_ternary_9: i32 = 0

    if (__local_err == 1) {
        (__ci_expr_ternary_9 = ((0 as i32)))
    } else {
        var __ci_expr_ternary_8: i32 = 0

        if (__local_err == 2) {
            (__ci_expr_ternary_8 = ((-3 as i32)))
        } else {
            var __ci_expr_ternary_7: i32 = 0

            var __ci_expr_logic_6: i32 = 0

            if (__local_err == -5) {
                (__ci_expr_logic_6 = (if __local_len == 0: 1 else: 0))
            }

            if __ci_expr_logic_6 {
                (__ci_expr_ternary_7 = ((-3 as i32)))
            } else {
                (__ci_expr_ternary_7 = __local_err)
            }

            (__ci_expr_ternary_8 = __ci_expr_ternary_7)

        }

        (__ci_expr_ternary_9 = __ci_expr_ternary_8)

    }

    return __ci_expr_ternary_9


}
