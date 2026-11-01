// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
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
use std.libc
use std.option

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn call_zopen64(__param_pfilefunc: *const zlib_filefunc64_32_def_s, __param_filename: *const c_void, __param_mode: i32) -> *mut c_void {
    if ((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zopen64_file != null) {
        return (((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zopen64_file.unwrap()((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filename, __param_mode) as *mut c_void))
    }
    return (((*__param_pfilefunc).zopen32_file.unwrap()((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (__param_filename as *const c_char), __param_mode) as *mut c_void))


}

// contract: receiver:zlib_filefunc64_32_def_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn call_zseek64(__param_pfilefunc: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void, __param_offset: u64, __param_origin: i32) -> i64 {
    if ((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zseek64_file != null) {
        return (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zseek64_file.unwrap()((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, __param_offset, __param_origin)
    }
    var __local_offsetTruncated: u64 = __param_offset

    if (__local_offsetTruncated != __param_offset) {
        return ((-1 as i64))
    }
    return (*__param_pfilefunc).zseek32_file.unwrap()((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, __local_offsetTruncated, __param_origin)


}

// contract: receiver:zlib_filefunc64_32_def_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn call_ztell64(__param_pfilefunc: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void) -> u64 {
    if ((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zseek64_file != null) {
        return (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).ztell64_file.unwrap()((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream)
    }
    var __local_tell_uLong: u64 = (((*__param_pfilefunc).ztell32_file.unwrap()((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream) as u64))

    if (__local_tell_uLong == 4294967295) {
        return ((-1 as u64))
    }
    return __local_tell_uLong


}

// contract: receiver-mut:zlib_filefunc64_32_def_s,unproved:1:read only
pub unsafe fn fill_zlib_filefunc64_32_def_from_filefunc32(__param_p_filefunc64_32: *mut zlib_filefunc64_32_def_s, __param_p_filefunc32: *const zlib_filefunc_def_s) {
    ((*__param_p_filefunc64_32).zfile_func64.zopen64_file = null)

    ((*__param_p_filefunc64_32).zopen32_file = (*__param_p_filefunc32).zopen_file)

    ((*__param_p_filefunc64_32).zfile_func64.zread_file = (*__param_p_filefunc32).zread_file)

    ((*__param_p_filefunc64_32).zfile_func64.zwrite_file = (*__param_p_filefunc32).zwrite_file)

    ((*__param_p_filefunc64_32).zfile_func64.ztell64_file = null)

    ((*__param_p_filefunc64_32).zfile_func64.zseek64_file = null)

    ((*__param_p_filefunc64_32).zfile_func64.zclose_file = (*__param_p_filefunc32).zclose_file)

    ((*__param_p_filefunc64_32).zfile_func64.zerror_file = (*__param_p_filefunc32).zerror_file)

    ((*__param_p_filefunc64_32).zfile_func64.opaque_ = (*__param_p_filefunc32).opaque_)

    ((*__param_p_filefunc64_32).zseek32_file = (*__param_p_filefunc32).zseek_file)

    ((*__param_p_filefunc64_32).ztell32_file = (*__param_p_filefunc32).ztell_file)

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn fopen_file_func(__param_opaque_: *mut c_void, __param_filename: *const c_char, __param_mode: i32) -> *mut c_void {
    var __local_file: *mut c_void = null

    var __local_mode_fopen: *const c_char = ((null as *const c_char))


    if (((__param_mode as i32) & (3 as i32)) == 1) {
        (__local_mode_fopen = c"rb".ptr)
    } else {
        if ((__param_mode as i32) & (4 as i32)) {
            (__local_mode_fopen = c"r+b".ptr)
        } else {
            if ((__param_mode as i32) & (8 as i32)) {
                (__local_mode_fopen = c"wb".ptr)
            }
        }
    }

    var __ci_expr_logic_0: i32 = 0

    if (__param_filename != null) {
        (__ci_expr_logic_0 = (if __local_mode_fopen != null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__local_file = fopen(__param_filename, __local_mode_fopen))
    }


    return __local_file

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn fopen64_file_func(__param_opaque_: *mut c_void, __param_filename: *const c_void, __param_mode: i32) -> *mut c_void {
    var __local_file: *mut c_void = null

    var __local_mode_fopen: *const c_char = ((null as *const c_char))


    if (((__param_mode as i32) & (3 as i32)) == 1) {
        (__local_mode_fopen = c"rb".ptr)
    } else {
        if ((__param_mode as i32) & (4 as i32)) {
            (__local_mode_fopen = c"r+b".ptr)
        } else {
            if ((__param_mode as i32) & (8 as i32)) {
                (__local_mode_fopen = c"wb".ptr)
            }
        }
    }

    var __ci_expr_logic_0: i32 = 0

    if (__param_filename != null) {
        (__ci_expr_logic_0 = (if __local_mode_fopen != null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__local_file = fopen((__param_filename as *const c_char), __local_mode_fopen))
    }


    return __local_file

}

// contract: unproved:0:read only,unproved:1:read only,unproved:2:read only
unsafe fn fread_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_buf: *mut c_void, __param_size: u64) -> u64 {
    var __local_ret: u64


    (__local_ret = fread(__param_buf, (1 as u64), __param_size, __param_stream))

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only,unproved:2:read only
unsafe fn fwrite_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_buf: *const c_void, __param_size: u64) -> u64 {
    var __local_ret: u64


    (__local_ret = fwrite(__param_buf, (1 as u64), __param_size, __param_stream))

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn ftell_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> i64 {
    var __local_ret: i64


    (__local_ret = ftell(__param_stream))

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn ftell64_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> u64 {
    var __local_ret: u64


    (__local_ret = ((ftell(__param_stream) as u64)))

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn fseek_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_offset: u64, __param_origin: i32) -> i64 {
    var __local_fseek_origin: i32 = ((0 as i32))

    var __local_ret: i64


    while true {
        match __param_origin {
            1 => {
                (__local_fseek_origin = ((libc.SEEK_CUR as i32)))
            },
            2 => {
                (__local_fseek_origin = ((libc.SEEK_END as i32)))
            },
            0 => {
                (__local_fseek_origin = ((libc.SEEK_SET as i32)))
            },
            _ => {
                return ((-1 as i64))
            },
        }

        break

    }

    (__local_ret = ((0 as i64)))

    if (fseek(__param_stream, (__param_offset as i64), __local_fseek_origin) != 0) {
        (__local_ret = ((-1 as i64)))
    }

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn fseek64_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_offset: u64, __param_origin: i32) -> i64 {
    var __local_fseek_origin: i32 = ((0 as i32))

    var __local_ret: i64


    while true {
        match __param_origin {
            1 => {
                (__local_fseek_origin = ((libc.SEEK_CUR as i32)))
            },
            2 => {
                (__local_fseek_origin = ((libc.SEEK_END as i32)))
            },
            0 => {
                (__local_fseek_origin = ((libc.SEEK_SET as i32)))
            },
            _ => {
                return ((-1 as i64))
            },
        }

        break

    }

    (__local_ret = ((0 as i64)))

    if (fseek(__param_stream, (__param_offset as i64), __local_fseek_origin) != 0) {
        (__local_ret = ((-1 as i64)))
    }

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn fclose_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> i32 {
    var __local_ret: i32


    (__local_ret = fclose(__param_stream))

    return __local_ret

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn ferror_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> i32 {
    var __local_ret: i32


    (__local_ret = ferror(__param_stream))

    return __local_ret

}

impl zlib_filefunc64_def_s {
    pub mut fn fill_fopen64_filefunc() {
        let __param_pzlib_filefunc_def: *mut zlib_filefunc64_def_s = self as *mut zlib_filefunc64_def_s
        ((unsafe *__param_pzlib_filefunc_def).zopen64_file = Some(fopen64_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zread_file = Some(fread_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zwrite_file = Some(fwrite_file_func))

        ((unsafe *__param_pzlib_filefunc_def).ztell64_file = Some(ftell64_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zseek64_file = Some(fseek64_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zclose_file = Some(fclose_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zerror_file = Some(ferror_file_func))

        ((unsafe *__param_pzlib_filefunc_def).opaque_ = null)

    }

}

impl zlib_filefunc_def_s {
    pub mut fn fill_fopen_filefunc() {
        let __param_pzlib_filefunc_def: *mut zlib_filefunc_def_s = self as *mut zlib_filefunc_def_s
        ((unsafe *__param_pzlib_filefunc_def).zopen_file = Some(fopen_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zread_file = Some(fread_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zwrite_file = Some(fwrite_file_func))

        ((unsafe *__param_pzlib_filefunc_def).ztell_file = Some(ftell_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zseek_file = Some(fseek_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zclose_file = Some(fclose_file_func))

        ((unsafe *__param_pzlib_filefunc_def).zerror_file = Some(ferror_file_func))

        ((unsafe *__param_pzlib_filefunc_def).opaque_ = null)

    }

}
