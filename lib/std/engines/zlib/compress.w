// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
use std.engines.zlib.deflate
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.uncompr
use std.engines.zlib.gzlib
use std.engines.zlib.gzwrite
use std.engines.zlib.gzread
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32

pub unsafe fn compress(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: u64) -> i32 {
    return compress2(__param_dest, __param_destLen, __param_source, __param_sourceLen, (-1 as i32))

}

pub unsafe fn compress_z(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: u64) -> i32 {
    return compress2_z(__param_dest, __param_destLen, __param_source, __param_sourceLen, (-1 as i32))

}

pub unsafe fn compress2(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: u64, __param_level: i32) -> i32 {
    var __local_ret: i32

    var __local_got: u64 = (*__param_destLen)

    (__local_ret = ((compress2_z(__param_dest, (&raw mut __local_got as *mut u64), __param_source, __param_sourceLen, __param_level) as i32)))

    ((*__param_destLen) = __local_got)

    return __local_ret

}

pub unsafe fn compress2_z(__param_dest: *mut u8, __param_destLen: *mut u64, __param_source: *const u8, __param_sourceLen: u64, __param_level: i32) -> i32 {
    var __local_sourceLen = __param_sourceLen
    var __local_stream: z_stream_s

    var __local_err: i32

    var __local_max: u32 = ((-1 as u32))

    var __local_left: u64

    var __ci_expr_logic_3: i32

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32 = 0

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
        var __ci_expr_logic_2: i32 = 0

        if ((if (*__param_destLen) > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __param_dest == null: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        return -2
    }


    (__local_left = (*__param_destLen))

    ((*__param_destLen) = ((0 as u64)))

    (__local_stream.zalloc = null)

    (__local_stream.zfree = null)

    (__local_stream.opaque_ = null)

    (__local_err = ((deflateInit_((&raw mut __local_stream as *mut z_stream_s), __param_level, c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        return __local_err
    }

    (__local_stream.next_out = __param_dest)

    (__local_stream.avail_out = ((0 as u32)))

    (__local_stream.next_in = ((__param_source as *mut u8)))

    (__local_stream.avail_in = ((0 as u32)))

    loop {
        if ((if (*(&raw const __local_stream as *const z_stream_s)).avail_out == 0: 1 else: 0) != 0) {
            (__local_stream.avail_out = (((if (if __local_left > ((4294967295 as u64)): 1 else: 0) != 0: (4294967295 as u32) else: (__local_left as u32)) as u32)))

            (__local_left = (__local_left -% (*(&raw const __local_stream as *const z_stream_s)).avail_out))

        }

        if ((if (*(&raw const __local_stream as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0) {
            (__local_stream.avail_in = (((if (if __local_sourceLen > ((4294967295 as u64)): 1 else: 0) != 0: (4294967295 as u32) else: (__local_sourceLen as u32)) as u32)))

            (__local_sourceLen = (__local_sourceLen -% (*(&raw const __local_stream as *const z_stream_s)).avail_in))

        }

        (__local_err = ((deflate((&raw mut __local_stream as *mut z_stream_s), ((if __local_sourceLen != 0: (0 as i32) else: (4 as i32)) as i32)) as i32)))

        if not (((if __local_err == 0: 1 else: 0) != 0)) {
            break
        }
    }

    ((*__param_destLen) = (((((((*(&raw const __local_stream as *const z_stream_s)).next_out as usize) -% (__param_dest as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))

    deflateEnd((&raw mut __local_stream as *mut z_stream_s))

    return (if (if __local_err == 1: 1 else: 0) != 0: (0 as i32) else: __local_err)

}

pub fn compressBound(__param_sourceLen: u64) -> u64 {
    var __local_bound: u64 = ((compressBound_z(__param_sourceLen) as u64))

    return (if (if __local_bound != __local_bound: 1 else: 0) != 0: (-1 as u64) else: __local_bound)

}

pub fn compressBound_z(__param_sourceLen: u64) -> u64 {
    var __local_bound: u64 = ((((((((((__param_sourceLen as u64) +% (((__param_sourceLen as u64) >> (12 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (14 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (25 as u32)) as u64)) as u64) +% (13 as u64)) as u64))

    return (if (if __local_bound < __param_sourceLen: 1 else: 0) != 0: (-1 as u64) else: __local_bound)

}
