// Migrated from C
use std.zl.defs
use std.zl.zutil
use std.zl.deflate
use std.zl.inflate
use std.zl.infback
use std.zl.compress
use std.zl.uncompr
use std.zl.gzlib
use std.zl.gzwrite
use std.zl.gzread
use std.zl.gzclose
use std.zl.adler32
use std.zl.crc32
use std.libc

pub unsafe fn fill_fopen64_filefunc(__param_pzlib_filefunc_def: *mut zlib_filefunc64_def_s) -> Unit {
    ((*__param_pzlib_filefunc_def).zopen64_file = fopen64_file_func)

    ((*__param_pzlib_filefunc_def).zread_file = fread_file_func)

    ((*__param_pzlib_filefunc_def).zwrite_file = fwrite_file_func)

    ((*__param_pzlib_filefunc_def).ztell64_file = ftell64_file_func)

    ((*__param_pzlib_filefunc_def).zseek64_file = fseek64_file_func)

    ((*__param_pzlib_filefunc_def).zclose_file = fclose_file_func)

    ((*__param_pzlib_filefunc_def).zerror_file = ferror_file_func)

    ((*__param_pzlib_filefunc_def).opaque_ = null)

}

pub unsafe fn fill_fopen_filefunc(__param_pzlib_filefunc_def: *mut zlib_filefunc_def_s) -> Unit {
    ((*__param_pzlib_filefunc_def).zopen_file = fopen_file_func)

    ((*__param_pzlib_filefunc_def).zread_file = fread_file_func)

    ((*__param_pzlib_filefunc_def).zwrite_file = fwrite_file_func)

    ((*__param_pzlib_filefunc_def).ztell_file = ftell_file_func)

    ((*__param_pzlib_filefunc_def).zseek_file = fseek_file_func)

    ((*__param_pzlib_filefunc_def).zclose_file = fclose_file_func)

    ((*__param_pzlib_filefunc_def).zerror_file = ferror_file_func)

    ((*__param_pzlib_filefunc_def).opaque_ = null)

}

pub unsafe fn call_zopen64(__param_pfilefunc: *const zlib_filefunc64_32_def_s, __param_filename: *const c_void, __param_mode: c_int) -> *mut c_void {
    if ((if (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zopen64_file != null: 1 else: 0) != 0) {
        return (((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zopen64_file((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filename, __param_mode) as *mut c_void))
    }
    return (((*__param_pfilefunc).zopen32_file((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (__param_filename as *const c_char), __param_mode) as *mut c_void))


}

pub unsafe fn call_zseek64(__param_pfilefunc: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void, __param_offset: c_ulong, __param_origin: c_int) -> c_long {
    if ((if (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zseek64_file != null: 1 else: 0) != 0) {
        return (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zseek64_file((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, __param_offset, __param_origin)
    }
    var __local_offsetTruncated: c_ulong = __param_offset

    if ((if __local_offsetTruncated != __param_offset: 1 else: 0) != 0) {
        return -1
    }
    return (*__param_pfilefunc).zseek32_file((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, __local_offsetTruncated, __param_origin)


}

pub unsafe fn call_ztell64(__param_pfilefunc: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void) -> c_ulong {
    if ((if (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).zseek64_file != null: 1 else: 0) != 0) {
        return (*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).ztell64_file((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream)
    }
    var __local_tell_uLong: c_ulong = (((*__param_pfilefunc).ztell32_file((*(&raw const (*__param_pfilefunc).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream) as c_ulong))

    if ((if __local_tell_uLong == 4294967295: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }
    return __local_tell_uLong


}

pub unsafe fn fill_zlib_filefunc64_32_def_from_filefunc32(__param_p_filefunc64_32: *mut zlib_filefunc64_32_def_s, __param_p_filefunc32: *const zlib_filefunc_def_s) -> Unit {
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

unsafe fn fopen_file_func(__param_opaque_: *mut c_void, __param_filename: *const i8, __param_mode: c_int) -> *mut c_void {
    var __local_file: *mut c_void = null

    var __local_mode_fopen: *const c_char = ((null as *const c_char))

    __param_opaque_

    if ((if ((__param_mode as c_int) & (3 as c_int)) == 1: 1 else: 0) != 0) {
        (__local_mode_fopen = c"rb".ptr)
    } else {
        if (((__param_mode as c_int) & (4 as c_int)) != 0) {
            (__local_mode_fopen = c"r+b".ptr)
        } else {
            if (((__param_mode as c_int) & (8 as c_int)) != 0) {
                (__local_mode_fopen = c"wb".ptr)
            }
        }
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_filename != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_mode_fopen != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_file = fopen(__param_filename, __local_mode_fopen))
    }


    return __local_file

}

unsafe fn fopen64_file_func(__param_opaque_: *mut c_void, __param_filename: *const c_void, __param_mode: c_int) -> *mut c_void {
    var __local_file: *mut c_void = null

    var __local_mode_fopen: *const c_char = ((null as *const c_char))

    __param_opaque_

    if ((if ((__param_mode as c_int) & (3 as c_int)) == 1: 1 else: 0) != 0) {
        (__local_mode_fopen = c"rb".ptr)
    } else {
        if (((__param_mode as c_int) & (4 as c_int)) != 0) {
            (__local_mode_fopen = c"r+b".ptr)
        } else {
            if (((__param_mode as c_int) & (8 as c_int)) != 0) {
                (__local_mode_fopen = c"wb".ptr)
            }
        }
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_filename != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_mode_fopen != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_file = fopen(((__param_filename as *const c_char) as *const i8), __local_mode_fopen))
    }


    return __local_file

}

unsafe fn fread_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_buf: *mut c_void, __param_size: c_ulong) -> c_ulong {
    var __local_ret: c_ulong

    __param_opaque_

    (__local_ret = ((fread(__param_buf, (1 as c_ulong), __param_size, __param_stream) as c_ulong)))

    return __local_ret

}

unsafe fn fwrite_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_buf: *const c_void, __param_size: c_ulong) -> c_ulong {
    var __local_ret: c_ulong

    __param_opaque_

    (__local_ret = ((fwrite(__param_buf, (1 as c_ulong), __param_size, __param_stream) as c_ulong)))

    return __local_ret

}

unsafe fn ftell_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> c_long {
    var __local_ret: c_long

    __param_opaque_

    (__local_ret = ((ftell(__param_stream) as c_long)))

    return __local_ret

}

unsafe fn ftell64_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> c_ulong {
    var __local_ret: c_ulong

    __param_opaque_

    (__local_ret = ((ftell(__param_stream) as c_ulong)))

    return __local_ret

}

unsafe fn fseek_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_offset: c_ulong, __param_origin: c_int) -> c_long {
    var __local_fseek_origin: c_int = ((0 as c_int))

    var __local_ret: c_long

    __param_opaque_

    while true {
        match __param_origin {
            1 => {
                (__local_fseek_origin = ((1 as c_int)))
            },
            2 => {
                (__local_fseek_origin = ((2 as c_int)))
            },
            0 => {
                (__local_fseek_origin = ((0 as c_int)))
            },
            _ => {
                return -1
            },
        }

        break

    }

    (__local_ret = ((0 as c_long)))

    if ((if fseek(__param_stream, (__param_offset as c_long), __local_fseek_origin) != 0: 1 else: 0) != 0) {
        (__local_ret = ((-1 as c_long)))
    }

    return __local_ret

}

unsafe fn fseek64_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void, __param_offset: c_ulong, __param_origin: c_int) -> c_long {
    var __local_fseek_origin: c_int = ((0 as c_int))

    var __local_ret: c_long

    __param_opaque_

    while true {
        match __param_origin {
            1 => {
                (__local_fseek_origin = ((1 as c_int)))
            },
            2 => {
                (__local_fseek_origin = ((2 as c_int)))
            },
            0 => {
                (__local_fseek_origin = ((0 as c_int)))
            },
            _ => {
                return -1
            },
        }

        break

    }

    (__local_ret = ((0 as c_long)))

    if ((if fseek(__param_stream, ((__param_offset as c_longlong) as c_long), __local_fseek_origin) != 0: 1 else: 0) != 0) {
        (__local_ret = ((-1 as c_long)))
    }

    return __local_ret

}

unsafe fn fclose_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> c_int {
    var __local_ret: c_int

    __param_opaque_

    (__local_ret = ((fclose(__param_stream) as c_int)))

    return __local_ret

}

unsafe fn ferror_file_func(__param_opaque_: *mut c_void, __param_stream: *mut c_void) -> c_int {
    var __local_ret: c_int

    __param_opaque_

    (__local_ret = ((ferror(__param_stream) as c_int)))

    return __local_ret

}
