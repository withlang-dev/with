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
use std.zl.ioapi

pub unsafe fn unzStringFileNameCompare(__param_fileName1: *const i8, __param_fileName2: *const i8, __param_iCaseSensitivity: c_int) -> c_int {
    var __local_iCaseSensitivity = __param_iCaseSensitivity
    if ((if __local_iCaseSensitivity == 0: 1 else: 0) != 0) {
        (__local_iCaseSensitivity = ((2 as c_int)))
    }

    if ((if __local_iCaseSensitivity == 1: 1 else: 0) != 0) {
        return strcmp(__param_fileName1, __param_fileName2)
    }

    return strcmpcasenosensitive_internal(__param_fileName1, __param_fileName2)

}

pub unsafe fn unzOpen(__param_path: *const i8) -> *mut c_void {
    return ((unzOpenInternal((__param_path as *const c_void), (null as *mut zlib_filefunc64_32_def_s), (0 as c_int)) as *mut c_void))

}

pub unsafe fn unzOpen64(__param_path: *const c_void) -> *mut c_void {
    return ((unzOpenInternal(__param_path, (null as *mut zlib_filefunc64_32_def_s), (1 as c_int)) as *mut c_void))

}

pub unsafe fn unzOpen2(__param_path: *const i8, __param_pzlib_filefunc32_def: *mut zlib_filefunc_def_s) -> *mut c_void {
    if ((if __param_pzlib_filefunc32_def != null: 1 else: 0) != 0) {
        var __local_zlib_filefunc64_32_def_fill: zlib_filefunc64_32_def_s

        fill_zlib_filefunc64_32_def_from_filefunc32((&raw mut __local_zlib_filefunc64_32_def_fill as *mut zlib_filefunc64_32_def_s), (__param_pzlib_filefunc32_def as *const zlib_filefunc_def_s))

        return ((unzOpenInternal((__param_path as *const c_void), (&raw mut __local_zlib_filefunc64_32_def_fill as *mut zlib_filefunc64_32_def_s), (0 as c_int)) as *mut c_void))

    }
    return ((unzOpenInternal((__param_path as *const c_void), (null as *mut zlib_filefunc64_32_def_s), (0 as c_int)) as *mut c_void))

}

pub unsafe fn unzOpen2_64(__param_path: *const c_void, __param_pzlib_filefunc_def: *mut zlib_filefunc64_def_s) -> *mut c_void {
    if ((if __param_pzlib_filefunc_def != null: 1 else: 0) != 0) {
        var __local_zlib_filefunc64_32_def_fill: zlib_filefunc64_32_def_s

        with_memcpy((&raw mut __local_zlib_filefunc64_32_def_fill.zfile_func64 as *mut u8), (&raw const (*__param_pzlib_filefunc_def) as *const u8), sizeof[zlib_filefunc64_def_s]())

        (__local_zlib_filefunc64_32_def_fill.zopen32_file = null)

        (__local_zlib_filefunc64_32_def_fill.ztell32_file = null)

        (__local_zlib_filefunc64_32_def_fill.zseek32_file = null)

        return ((unzOpenInternal(__param_path, (&raw mut __local_zlib_filefunc64_32_def_fill as *mut zlib_filefunc64_32_def_s), (1 as c_int)) as *mut c_void))

    }
    return ((unzOpenInternal(__param_path, (null as *mut zlib_filefunc64_32_def_s), (1 as c_int)) as *mut c_void))

}

pub unsafe fn unzClose(__param_file: *mut c_void) -> c_int {
    var __local_s: *mut unz64_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if (*__local_s).pfile_in_zip_read != null: 1 else: 0) != 0) {
        unzCloseCurrentFile(__param_file)
    }

    (*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zclose_file((*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_s).filestream)

    with_free(((__local_s as *mut c_void) as *mut u8))

    return 0

}

pub unsafe fn unzGetGlobalInfo(__param_file: *mut c_void, __param_pglobal_info32: *mut unz_global_info_s) -> c_int {
    var __local_s: *mut unz64_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    ((*__param_pglobal_info32).number_entry = (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry)

    ((*__param_pglobal_info32).size_comment = (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).size_comment)

    return 0

}

pub unsafe fn unzGetGlobalInfo64(__param_file: *mut c_void, __param_pglobal_info: *mut unz_global_info64_s) -> c_int {
    var __local_s: *mut unz64_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    with_memcpy((&raw mut (*__param_pglobal_info) as *mut u8), (&raw const (*__local_s).gi as *const u8), sizeof[unz_global_info64_s]())

    return 0

}

pub unsafe fn unzGetGlobalComment(__param_file: *mut c_void, __param_szComment: *mut i8, __param_uSizeBuf: c_ulong) -> c_int {
    var __local_s: *mut unz64_s

    var __local_uReadThis: c_ulong

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_uReadThis = __param_uSizeBuf)

    if ((if __local_uReadThis > (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).size_comment: 1 else: 0) != 0) {
        (__local_uReadThis = (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).size_comment)
    }

    if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((((*__local_s).central_pos as c_ulong) +% (22 as c_ulong)) as c_ulong), (0 as c_int)) != 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if __local_uReadThis > 0: 1 else: 0) != 0) {
        ((*__param_szComment) = ((0 as c_char)))

        if ((if (*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_s).filestream, (__param_szComment as *mut c_void), __local_uReadThis) != __local_uReadThis: 1 else: 0) != 0) {
            return -1
        }

    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_szComment != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_uSizeBuf > (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).size_comment: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*(__param_szComment + ((*(&raw const (*__local_s).gi as *const unz_global_info64_s)).size_comment as usize))) = ((0 as c_char)))
    }


    return ((__local_uReadThis as c_int))

}

pub unsafe fn unzGoToFirstFile(__param_file: *mut c_void) -> c_int {
    var __local_err: c_int = ((0 as c_int))

    var __local_s: *mut unz64_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    ((*__local_s).pos_in_central_dir = (*__local_s).offset_central_dir)

    ((*__local_s).num_file = ((0 as c_ulong)))

    (__local_err = ((unz64local_GetCurrentFileInfoInternal(__param_file, ((&raw const (*__local_s).cur_file_info as *const unz_file_info64_s) as *mut unz_file_info64_s), ((&raw const (*__local_s).cur_file_info_internal as *const unz_file_info64_internal_s) as *mut unz_file_info64_internal_s), (null as *mut i8), (0 as c_ulong), null, (0 as c_ulong), (null as *mut i8), (0 as c_ulong)) as c_int)))

    ((*__local_s).current_file_ok = (((if __local_err == 0: 1 else: 0) as c_ulong)))

    return __local_err

}

pub unsafe fn unzGoToNextFile(__param_file: *mut c_void) -> c_int {
    var __local_s: *mut unz64_s

    var __local_err: c_int

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if not ((*__local_s).current_file_ok != 0): 1 else: 0) != 0) {
        return -100
    }

    if ((if (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry != 65535: 1 else: 0) != 0) {
        if ((if (((*__local_s).num_file as c_ulong) +% (1 as c_ulong)) == (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry: 1 else: 0) != 0) {
            return -100
        }
    }

    ((*__local_s).pos_in_central_dir = ((*__local_s).pos_in_central_dir +% ((((((46 as c_ulong) +% ((*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).size_filename as c_ulong)) as c_ulong) +% ((*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).size_file_extra as c_ulong)) as c_ulong) +% ((*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).size_file_comment as c_ulong))))

    ((*__local_s).num_file = ((*__local_s).num_file +% 1))

    (__local_err = ((unz64local_GetCurrentFileInfoInternal(__param_file, ((&raw const (*__local_s).cur_file_info as *const unz_file_info64_s) as *mut unz_file_info64_s), ((&raw const (*__local_s).cur_file_info_internal as *const unz_file_info64_internal_s) as *mut unz_file_info64_internal_s), (null as *mut i8), (0 as c_ulong), null, (0 as c_ulong), (null as *mut i8), (0 as c_ulong)) as c_int)))

    ((*__local_s).current_file_ok = (((if __local_err == 0: 1 else: 0) as c_ulong)))

    return __local_err

}

pub unsafe fn unzLocateFile(__param_file: *mut c_void, __param_szFileName: *const i8, __param_iCaseSensitivity: c_int) -> c_int {
    var __local_s: *mut unz64_s

    var __local_err: c_int

    var __local_cur_file_infoSaved: unz_file_info64_s

    var __local_cur_file_info_internalSaved: unz_file_info64_internal_s

    var __local_num_fileSaved: c_ulong

    var __local_pos_in_central_dirSaved: c_ulong

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    if ((if strlen(__param_szFileName) >= 256: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if not ((*__local_s).current_file_ok != 0): 1 else: 0) != 0) {
        return -100
    }

    (__local_num_fileSaved = (*__local_s).num_file)

    (__local_pos_in_central_dirSaved = (*__local_s).pos_in_central_dir)

    with_memcpy((&raw mut __local_cur_file_infoSaved as *mut u8), (&raw const (*__local_s).cur_file_info as *const u8), sizeof[unz_file_info64_s]())

    with_memcpy((&raw mut __local_cur_file_info_internalSaved as *mut u8), (&raw const (*__local_s).cur_file_info_internal as *const u8), sizeof[unz_file_info64_internal_s]())

    (__local_err = ((unzGoToFirstFile(__param_file) as c_int)))

    while ((if __local_err == 0: 1 else: 0) != 0) {
        var __local_szCurrentFileName: [257]c_char

        (__local_err = ((unzGetCurrentFileInfo64(__param_file, (null as *mut unz_file_info64_s), (&__local_szCurrentFileName[0] as *mut c_char), ((((257 * sizeof[c_char]()) as c_ulong) -% (1 as c_ulong)) as c_ulong), null, (0 as c_ulong), (null as *mut i8), (0 as c_ulong)) as c_int)))

        if ((if __local_err == 0: 1 else: 0) != 0) {
            if ((if unzStringFileNameCompare((&__local_szCurrentFileName[0] as *mut c_char), __param_szFileName, __param_iCaseSensitivity) == 0: 1 else: 0) != 0) {
                return 0
            }

            (__local_err = ((unzGoToNextFile(__param_file) as c_int)))

        }

    }

    ((*__local_s).num_file = __local_num_fileSaved)

    ((*__local_s).pos_in_central_dir = __local_pos_in_central_dirSaved)

    with_memcpy((&raw mut (*__local_s).cur_file_info as *mut u8), (&raw const __local_cur_file_infoSaved as *const u8), sizeof[unz_file_info64_s]())

    with_memcpy((&raw mut (*__local_s).cur_file_info_internal as *mut u8), (&raw const __local_cur_file_info_internalSaved as *const u8), sizeof[unz_file_info64_internal_s]())

    return __local_err

}

pub unsafe fn unzGetFilePos(__param_file: *mut c_void, __param_file_pos: *mut unz_file_pos_s) -> c_int {
    var __local_file_pos64: unz64_file_pos_s

    var __local_err: c_int = ((unzGetFilePos64(__param_file, (&raw mut __local_file_pos64 as *mut unz64_file_pos_s)) as c_int))

    if ((if __local_err == 0: 1 else: 0) != 0) {
        ((*__param_file_pos).pos_in_zip_directory = (*(&raw const __local_file_pos64 as *const unz64_file_pos_s)).pos_in_zip_directory)

        ((*__param_file_pos).num_of_file = (*(&raw const __local_file_pos64 as *const unz64_file_pos_s)).num_of_file)

    }

    return __local_err

}

pub unsafe fn unzGoToFilePos(__param_file: *mut c_void, __param_file_pos: *mut unz_file_pos_s) -> c_int {
    var __local_file_pos64: unz64_file_pos_s

    if ((if __param_file_pos == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_file_pos64.pos_in_zip_directory = (*__param_file_pos).pos_in_zip_directory)

    (__local_file_pos64.num_of_file = (*__param_file_pos).num_of_file)

    return unzGoToFilePos64(__param_file, ((&raw mut __local_file_pos64 as *mut unz64_file_pos_s) as *const unz64_file_pos_s))

}

pub unsafe fn unzGetFilePos64(__param_file: *mut c_void, __param_file_pos: *mut unz64_file_pos_s) -> c_int {
    var __local_s: *mut unz64_s

    var __ci_expr_logic_0: c_int

    if ((if __param_file == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_file_pos == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -102
    }


    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if not ((*__local_s).current_file_ok != 0): 1 else: 0) != 0) {
        return -100
    }

    ((*__param_file_pos).pos_in_zip_directory = (*__local_s).pos_in_central_dir)

    ((*__param_file_pos).num_of_file = (*__local_s).num_file)

    return 0

}

pub unsafe fn unzGoToFilePos64(__param_file: *mut c_void, __param_file_pos: *const unz64_file_pos_s) -> c_int {
    var __local_s: *mut unz64_s

    var __local_err: c_int

    var __ci_expr_logic_0: c_int

    if ((if __param_file == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_file_pos == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -102
    }


    (__local_s = ((__param_file as *mut unz64_s)))

    ((*__local_s).pos_in_central_dir = (*__param_file_pos).pos_in_zip_directory)

    ((*__local_s).num_file = (*__param_file_pos).num_of_file)

    (__local_err = ((unz64local_GetCurrentFileInfoInternal(__param_file, ((&raw const (*__local_s).cur_file_info as *const unz_file_info64_s) as *mut unz_file_info64_s), ((&raw const (*__local_s).cur_file_info_internal as *const unz_file_info64_internal_s) as *mut unz_file_info64_internal_s), (null as *mut i8), (0 as c_ulong), null, (0 as c_ulong), (null as *mut i8), (0 as c_ulong)) as c_int)))

    ((*__local_s).current_file_ok = (((if __local_err == 0: 1 else: 0) as c_ulong)))

    return __local_err

}

pub unsafe fn unzGetCurrentFileInfo64(__param_file: *mut c_void, __param_pfile_info: *mut unz_file_info64_s, __param_szFileName: *mut i8, __param_fileNameBufferSize: c_ulong, __param_extraField: *mut c_void, __param_extraFieldBufferSize: c_ulong, __param_szComment: *mut i8, __param_commentBufferSize: c_ulong) -> c_int {
    return unz64local_GetCurrentFileInfoInternal(__param_file, __param_pfile_info, (null as *mut unz_file_info64_internal_s), __param_szFileName, __param_fileNameBufferSize, __param_extraField, __param_extraFieldBufferSize, __param_szComment, __param_commentBufferSize)

}

pub unsafe fn unzGetCurrentFileInfo(__param_file: *mut c_void, __param_pfile_info: *mut unz_file_info_s, __param_szFileName: *mut i8, __param_fileNameBufferSize: c_ulong, __param_extraField: *mut c_void, __param_extraFieldBufferSize: c_ulong, __param_szComment: *mut i8, __param_commentBufferSize: c_ulong) -> c_int {
    var __local_err: c_int

    var __local_file_info64: unz_file_info64_s

    (__local_err = ((unz64local_GetCurrentFileInfoInternal(__param_file, (&raw mut __local_file_info64 as *mut unz_file_info64_s), (null as *mut unz_file_info64_internal_s), __param_szFileName, __param_fileNameBufferSize, __param_extraField, __param_extraFieldBufferSize, __param_szComment, __param_commentBufferSize) as c_int)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_pfile_info != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__param_pfile_info).version = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).version)

        ((*__param_pfile_info).version_needed = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).version_needed)

        ((*__param_pfile_info).flag = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).flag)

        ((*__param_pfile_info).compression_method = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).compression_method)

        ((*__param_pfile_info).dosDate = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).dosDate)

        ((*__param_pfile_info).crc = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).crc)

        ((*__param_pfile_info).size_filename = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).size_filename)

        ((*__param_pfile_info).size_file_extra = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).size_file_extra)

        ((*__param_pfile_info).size_file_comment = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).size_file_comment)

        ((*__param_pfile_info).disk_num_start = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).disk_num_start)

        ((*__param_pfile_info).internal_fa = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).internal_fa)

        ((*__param_pfile_info).external_fa = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).external_fa)

        with_memcpy((&raw mut (*__param_pfile_info).tmu_date as *mut u8), (&raw const __local_file_info64.tmu_date as *const u8), sizeof[tm_unz_s]())

        ((*__param_pfile_info).compressed_size = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).compressed_size)

        ((*__param_pfile_info).uncompressed_size = (*(&raw const __local_file_info64 as *const unz_file_info64_s)).uncompressed_size)

    }


    return __local_err

}

pub unsafe fn unzGetCurrentFileZStreamPos64(__param_file: *mut c_void) -> c_ulong {
    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return 0
    }

    return (((*__local_pfile_in_zip_read_info).pos_in_zipfile as c_ulong) +% ((*__local_pfile_in_zip_read_info).byte_before_the_zipfile as c_ulong))

}

pub unsafe fn unzOpenCurrentFile(__param_file: *mut c_void) -> c_int {
    return unzOpenCurrentFile3(__param_file, (null as *mut c_int), (null as *mut c_int), (0 as c_int), (null as *const i8))

}

pub unsafe fn unzOpenCurrentFilePassword(__param_file: *mut c_void, __param_password: *const i8) -> c_int {
    return unzOpenCurrentFile3(__param_file, (null as *mut c_int), (null as *mut c_int), (0 as c_int), __param_password)

}

pub unsafe fn unzOpenCurrentFile2(__param_file: *mut c_void, __param_method: *mut c_int, __param_level: *mut c_int, __param_raw: c_int) -> c_int {
    return unzOpenCurrentFile3(__param_file, __param_method, __param_level, __param_raw, (null as *const i8))

}

pub unsafe fn unzOpenCurrentFile3(__param_file: *mut c_void, __param_method: *mut c_int, __param_level: *mut c_int, __param_raw: c_int, __param_password: *const i8) -> c_int {
    var __local_err: c_int = ((0 as c_int))

    var __local_iSizeVar: c_uint

    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    var __local_offset_local_extrafield: c_ulong

    var __local_size_local_extrafield: c_uint

    var __local_source: [12]c_char

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if not ((*__local_s).current_file_ok != 0): 1 else: 0) != 0) {
        return -102
    }

    if ((if (*__local_s).pfile_in_zip_read != null: 1 else: 0) != 0) {
        unzCloseCurrentFile(__param_file)
    }

    if ((if unz64local_CheckCurrentFileCoherencyHeader(__local_s, (&raw mut __local_iSizeVar as *mut c_uint), (&raw mut __local_offset_local_extrafield as *mut c_ulong), (&raw mut __local_size_local_extrafield as *mut c_uint)) != 0: 1 else: 0) != 0) {
        return -103
    }

    (__local_pfile_in_zip_read_info = (((with_alloc(((sizeof[file_in_zip64_read_info_s]() as c_ulong) as i64)) as *mut c_void) as *mut file_in_zip64_read_info_s)))

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return -104
    }

    ((*__local_pfile_in_zip_read_info).read_buffer = (((with_alloc(((16384 as c_ulong) as i64)) as *mut c_void) as *mut c_char)))

    ((*__local_pfile_in_zip_read_info).offset_local_extrafield = __local_offset_local_extrafield)

    ((*__local_pfile_in_zip_read_info).size_local_extrafield = __local_size_local_extrafield)

    ((*__local_pfile_in_zip_read_info).pos_local_extrafield = ((0 as c_ulong)))

    ((*__local_pfile_in_zip_read_info).raw = __param_raw)

    if ((if (*__local_pfile_in_zip_read_info).read_buffer == null: 1 else: 0) != 0) {
        with_free(((__local_pfile_in_zip_read_info as *mut c_void) as *mut u8))

        return -104

    }

    ((*__local_pfile_in_zip_read_info).stream_initialised = ((0 as c_ulong)))

    if ((if __param_method != null: 1 else: 0) != 0) {
        ((*__param_method) = (((*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method as c_int)))
    }

    if ((if __param_level != null: 1 else: 0) != 0) {
        ((*__param_level) = ((6 as c_int)))

        while true {
            match (((*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).flag as c_ulong) & (6 as c_ulong)) {
                6 => {
                    ((*__param_level) = ((1 as c_int)))
                },
                4 => {
                    ((*__param_level) = ((2 as c_int)))
                },
                2 => {
                    ((*__param_level) = ((9 as c_int)))
                },
            }

            break

        }

    }

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    if ((if (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method != 12: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if (if (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method != 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__local_err = ((-103 as c_int)))
    }


    ((*__local_pfile_in_zip_read_info).crc32_wait = (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).crc)

    ((*__local_pfile_in_zip_read_info).crc32 = ((0 as c_ulong)))

    ((*__local_pfile_in_zip_read_info).total_out_64 = ((0 as c_ulong)))

    ((*__local_pfile_in_zip_read_info).compression_method = (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method)

    ((*__local_pfile_in_zip_read_info).filestream = (*__local_s).filestream)

    with_memcpy((&raw mut (*__local_pfile_in_zip_read_info).z_filefunc as *mut u8), (&raw const (*__local_s).z_filefunc as *const u8), sizeof[zlib_filefunc64_32_def_s]())

    ((*__local_pfile_in_zip_read_info).byte_before_the_zipfile = (*__local_s).byte_before_the_zipfile)

    ((*__local_pfile_in_zip_read_info).stream.total_out = ((0 as c_ulong)))

    var __ci_expr_logic_3: c_int = 0

    if ((if (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method == 12: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if (if not (__param_raw != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        ((*__local_pfile_in_zip_read_info).raw = ((1 as c_int)))

    } else {
        var __ci_expr_logic_4: c_int = 0

        if ((if (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compression_method == 8: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if not (__param_raw != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            ((*__local_pfile_in_zip_read_info).stream.zalloc = ((0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)))

            ((*__local_pfile_in_zip_read_info).stream.zfree = ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)))

            ((*__local_pfile_in_zip_read_info).stream.opaque_ = ((0 as *mut c_void)))

            ((*__local_pfile_in_zip_read_info).stream.next_in = null)

            ((*__local_pfile_in_zip_read_info).stream.avail_in = ((0 as c_uint)))

            (__local_err = ((inflateInit2_(((&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s) as *mut z_stream_s), (-15 as c_int), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

            if ((if __local_err == 0: 1 else: 0) != 0) {
                ((*__local_pfile_in_zip_read_info).stream_initialised = ((8 as c_ulong)))
            } else {
                with_free((((*__local_pfile_in_zip_read_info).read_buffer as *mut c_void) as *mut u8))

                with_free(((__local_pfile_in_zip_read_info as *mut c_void) as *mut u8))

                return __local_err

            }

        }

    }


    ((*__local_pfile_in_zip_read_info).rest_read_compressed = (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).compressed_size)

    ((*__local_pfile_in_zip_read_info).rest_read_uncompressed = (*(&raw const (*__local_s).cur_file_info as *const unz_file_info64_s)).uncompressed_size)

    ((*__local_pfile_in_zip_read_info).pos_in_zipfile = (((((((*(&raw const (*__local_s).cur_file_info_internal as *const unz_file_info64_internal_s)).offset_curfile as c_ulong) +% (30 as c_ulong)) as c_ulong) +% (__local_iSizeVar as c_ulong)) as c_ulong)))

    ((*__local_pfile_in_zip_read_info).stream.avail_in = ((0 as c_uint)))

    ((*__local_s).pfile_in_zip_read = __local_pfile_in_zip_read_info)

    ((*__local_s).encrypted = ((0 as c_int)))

    if ((if __param_password != null: 1 else: 0) != 0) {
        var __local_i: c_int

        ((*__local_s).pcrc_32_tab = get_crc_table())

        init_keys(__param_password, (&(*__local_s).keys[0] as *mut c_ulong), (*__local_s).pcrc_32_tab)

        if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((((*(*__local_s).pfile_in_zip_read).pos_in_zipfile as c_ulong) +% ((*(*__local_s).pfile_in_zip_read).byte_before_the_zipfile as c_ulong)) as c_ulong), (0 as c_int)) != 0: 1 else: 0) != 0) {
            return -104
        }

        if ((if (*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_s).filestream, (&__local_source[0] as *mut c_char), (12 as c_ulong)) < 12: 1 else: 0) != 0) {
            return -104
        }

        (__local_i = ((0 as c_int)))

        while ((if __local_i < 12: 1 else: 0) != 0) {
            (__local_source[__local_i] = (__local_source[__local_i] as c_char) ^ (decrypt_byte((&(*__local_s).keys[0] as *mut c_ulong), (*__local_s).pcrc_32_tab) as c_char))

            update_keys((&(*__local_s).keys[0] as *mut c_ulong), (*__local_s).pcrc_32_tab, (__local_source[__local_i] as c_int))


            (__local_i = __local_i + 1)

        }


        ((*(*__local_s).pfile_in_zip_read).pos_in_zipfile = ((*(*__local_s).pfile_in_zip_read).pos_in_zipfile +% 12))

        ((*__local_s).encrypted = ((1 as c_int)))

    }

    return 0

}

pub unsafe fn unzCloseCurrentFile(__param_file: *mut c_void) -> c_int {
    var __local_err: c_int = ((0 as c_int))

    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return -102
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__local_pfile_in_zip_read_info).rest_read_uncompressed == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not ((*__local_pfile_in_zip_read_info).raw != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        if ((if (*__local_pfile_in_zip_read_info).crc32 != (*__local_pfile_in_zip_read_info).crc32_wait: 1 else: 0) != 0) {
            (__local_err = ((-105 as c_int)))
        }

    }


    with_free((((*__local_pfile_in_zip_read_info).read_buffer as *mut c_void) as *mut u8))

    ((*__local_pfile_in_zip_read_info).read_buffer = ((null as *mut c_char)))

    if ((if (*__local_pfile_in_zip_read_info).stream_initialised == 8: 1 else: 0) != 0) {
        inflateEnd(((&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s) as *mut z_stream_s))
    }

    ((*__local_pfile_in_zip_read_info).stream_initialised = ((0 as c_ulong)))

    with_free(((__local_pfile_in_zip_read_info as *mut c_void) as *mut u8))

    ((*__local_s).pfile_in_zip_read = ((null as *mut file_in_zip64_read_info_s)))

    return __local_err

}

pub unsafe fn unzReadCurrentFile(__param_file: *mut c_void, __param_buf: *mut c_void, __param_len: c_uint) -> c_int {
    var __local_err: c_int = ((0 as c_int))

    var __local_iRead: c_uint = ((0 as c_uint))

    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return -102
    }

    if ((if (*__local_pfile_in_zip_read_info).read_buffer == null: 1 else: 0) != 0) {
        return -100
    }

    if ((if __param_len == 0: 1 else: 0) != 0) {
        return 0
    }

    ((*__local_pfile_in_zip_read_info).stream.next_out = ((__param_buf as *mut u8)))

    ((*__local_pfile_in_zip_read_info).stream.avail_out = __param_len)

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_len > (*__local_pfile_in_zip_read_info).rest_read_uncompressed: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not ((*__local_pfile_in_zip_read_info).raw != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__local_pfile_in_zip_read_info).stream.avail_out = (((*__local_pfile_in_zip_read_info).rest_read_uncompressed as c_uint)))
    }


    var __ci_expr_logic_1: c_int = 0

    if ((if __param_len > (((*__local_pfile_in_zip_read_info).rest_read_compressed as c_ulong) +% ((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in as c_ulong)): 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (*__local_pfile_in_zip_read_info).raw != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((*__local_pfile_in_zip_read_info).stream.avail_out = ((((((*__local_pfile_in_zip_read_info).rest_read_compressed as c_uint) as c_uint) +% ((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in as c_uint)) as c_uint)))
    }


    while ((if (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_out > 0: 1 else: 0) != 0) {
        var __ci_expr_logic_2: c_int = 0

        if ((if (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (*__local_pfile_in_zip_read_info).rest_read_compressed > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            var __local_uReadThis: c_uint = ((16384 as c_uint))

            if ((if (*__local_pfile_in_zip_read_info).rest_read_compressed < __local_uReadThis: 1 else: 0) != 0) {
                (__local_uReadThis = (((*__local_pfile_in_zip_read_info).rest_read_compressed as c_uint)))
            }

            if ((if __local_uReadThis == 0: 1 else: 0) != 0) {
                return 0
            }

            if ((if call_zseek64((((&raw const (*__local_pfile_in_zip_read_info).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_pfile_in_zip_read_info).filestream, ((((*__local_pfile_in_zip_read_info).pos_in_zipfile as c_ulong) +% ((*__local_pfile_in_zip_read_info).byte_before_the_zipfile as c_ulong)) as c_ulong), (0 as c_int)) != 0: 1 else: 0) != 0) {
                return -1
            }

            if ((if (*(&raw const (*__local_pfile_in_zip_read_info).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_pfile_in_zip_read_info).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_pfile_in_zip_read_info).filestream, ((*__local_pfile_in_zip_read_info).read_buffer as *mut c_void), (__local_uReadThis as c_ulong)) != __local_uReadThis: 1 else: 0) != 0) {
                return -1
            }

            if ((*__local_s).encrypted != 0) {
                var __local_i: c_uint

                (__local_i = ((0 as c_uint)))

                while ((if __local_i < __local_uReadThis: 1 else: 0) != 0) {
                    (((*__local_pfile_in_zip_read_info).read_buffer[__local_i]) = (((*__local_pfile_in_zip_read_info).read_buffer[__local_i]) as c_char) ^ (decrypt_byte((&(*__local_s).keys[0] as *mut c_ulong), (*__local_s).pcrc_32_tab) as c_char))

                    (((*__local_pfile_in_zip_read_info).read_buffer[__local_i]) = ((update_keys((&(*__local_s).keys[0] as *mut c_ulong), (*__local_s).pcrc_32_tab, (((*__local_pfile_in_zip_read_info).read_buffer[__local_i]) as c_int)) as c_char)))


                    (__local_i = (__local_i +% 1))

                }


            }

            ((*__local_pfile_in_zip_read_info).pos_in_zipfile = ((*__local_pfile_in_zip_read_info).pos_in_zipfile +% __local_uReadThis))

            ((*__local_pfile_in_zip_read_info).rest_read_compressed = ((*__local_pfile_in_zip_read_info).rest_read_compressed -% __local_uReadThis))

            ((*__local_pfile_in_zip_read_info).stream.next_in = (((*__local_pfile_in_zip_read_info).read_buffer as *mut u8)))

            ((*__local_pfile_in_zip_read_info).stream.avail_in = __local_uReadThis)

        }


        var __ci_expr_logic_3: c_int

        if ((if (*__local_pfile_in_zip_read_info).compression_method == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (*__local_pfile_in_zip_read_info).raw != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            var __local_uDoCopy: c_uint

            var __local_i_1: c_uint


            var __ci_expr_logic_4: c_int = 0

            if ((if (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if (*__local_pfile_in_zip_read_info).rest_read_compressed == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                var __ci_expr_ternary_5: c_int = 0

                if ((if __local_iRead == 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_5 = ((0 as c_int)))
                } else {
                    (__ci_expr_ternary_5 = ((__local_iRead as c_int)))
                }

                return __ci_expr_ternary_5

            }


            if ((if (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_out < (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in: 1 else: 0) != 0) {
                (__local_uDoCopy = (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_out)
            } else {
                (__local_uDoCopy = (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in)
            }

            (__local_i_1 = ((0 as c_uint)))

            while ((if __local_i_1 < __local_uDoCopy: 1 else: 0) != 0) {
                ((*((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).next_out + (__local_i_1 as usize))) = (*((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).next_in + (__local_i_1 as usize))))

                (__local_i_1 = (__local_i_1 +% 1))

            }


            ((*__local_pfile_in_zip_read_info).total_out_64 = (((((*__local_pfile_in_zip_read_info).total_out_64 as c_ulong) +% (__local_uDoCopy as c_ulong)) as c_ulong)))

            ((*__local_pfile_in_zip_read_info).crc32 = ((crc32((*__local_pfile_in_zip_read_info).crc32, ((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).next_out as *const u8), __local_uDoCopy) as c_ulong)))

            ((*__local_pfile_in_zip_read_info).rest_read_uncompressed = ((*__local_pfile_in_zip_read_info).rest_read_uncompressed -% __local_uDoCopy))

            ((*__local_pfile_in_zip_read_info).stream.avail_in = ((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_in -% __local_uDoCopy))

            ((*__local_pfile_in_zip_read_info).stream.avail_out = ((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).avail_out -% __local_uDoCopy))

            ((*__local_pfile_in_zip_read_info).stream.next_out = (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).next_out + (__local_uDoCopy as usize))

            ((*__local_pfile_in_zip_read_info).stream.next_in = (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).next_in + (__local_uDoCopy as usize))

            ((*__local_pfile_in_zip_read_info).stream.total_out = ((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).total_out +% __local_uDoCopy))

            (__local_iRead = (__local_iRead +% __local_uDoCopy))

        } else {
            if (not ((if (*__local_pfile_in_zip_read_info).compression_method == 12: 1 else: 0) != 0)) {
                var __local_uTotalOutBefore: c_ulong

                var __local_uTotalOutAfter: c_ulong


                var __local_bufBefore: *const u8

                var __local_uOutThis: c_ulong

                var __local_flush: c_int = ((2 as c_int))

                (__local_uTotalOutBefore = (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).total_out)

                (__local_bufBefore = (((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).next_out as *const u8)))

                (__local_err = ((inflate(((&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s) as *mut z_stream_s), __local_flush) as c_int)))

                var __ci_expr_logic_6: c_int = 0

                if ((if __local_err >= 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_6 = (if (if (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).msg != null: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_6 != 0) {
                    (__local_err = ((-3 as c_int)))
                }


                (__local_uTotalOutAfter = (*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).total_out)

                if ((if __local_uTotalOutAfter < __local_uTotalOutBefore: 1 else: 0) != 0) {
                    (__local_uTotalOutAfter = (__local_uTotalOutAfter +% (4294967296 as c_ulong)))
                }

                (__local_uOutThis = ((((__local_uTotalOutAfter as c_ulong) -% (__local_uTotalOutBefore as c_ulong)) as c_ulong)))

                ((*__local_pfile_in_zip_read_info).total_out_64 = (((((*__local_pfile_in_zip_read_info).total_out_64 as c_ulong) +% (__local_uOutThis as c_ulong)) as c_ulong)))

                ((*__local_pfile_in_zip_read_info).crc32 = ((crc32((*__local_pfile_in_zip_read_info).crc32, __local_bufBefore, (__local_uOutThis as c_uint)) as c_ulong)))

                ((*__local_pfile_in_zip_read_info).rest_read_uncompressed = ((*__local_pfile_in_zip_read_info).rest_read_uncompressed -% __local_uOutThis))

                (__local_iRead = (__local_iRead +% (((__local_uTotalOutAfter as c_ulong) -% (__local_uTotalOutBefore as c_ulong)) as c_uint)))

                if ((if __local_err == 1: 1 else: 0) != 0) {
                    var __ci_expr_ternary_7: c_int = 0

                    if ((if __local_iRead == 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_7 = ((0 as c_int)))
                    } else {
                        (__ci_expr_ternary_7 = ((__local_iRead as c_int)))
                    }

                    return __ci_expr_ternary_7

                }

                if ((if __local_err != 0: 1 else: 0) != 0) {
                    break
                }

            }
        }


    }

    if ((if __local_err == 0: 1 else: 0) != 0) {
        return ((__local_iRead as c_int))
    }

    return __local_err

}

pub unsafe fn unztell(__param_file: *mut c_void) -> c_longlong {
    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return -102
    }

    return (((*(&raw const (*__local_pfile_in_zip_read_info).stream as *const z_stream_s)).total_out as c_longlong))

}

pub unsafe fn unztell64(__param_file: *mut c_void) -> c_ulong {
    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    return (*__local_pfile_in_zip_read_info).total_out_64

}

pub unsafe fn unzeof(__param_file: *mut c_void) -> c_int {
    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return -102
    }

    if ((if (*__local_pfile_in_zip_read_info).rest_read_uncompressed == 0: 1 else: 0) != 0) {
        return 1
    }
    return 0

}

pub unsafe fn unzGetLocalExtrafield(__param_file: *mut c_void, __param_buf: *mut c_void, __param_len: c_uint) -> c_int {
    var __local_s: *mut unz64_s

    var __local_pfile_in_zip_read_info: *mut file_in_zip64_read_info_s

    var __local_read_now: c_uint

    var __local_size_to_read: c_ulong

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    (__local_pfile_in_zip_read_info = (*__local_s).pfile_in_zip_read)

    if ((if __local_pfile_in_zip_read_info == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_size_to_read = (((((*__local_pfile_in_zip_read_info).size_local_extrafield as c_ulong) -% ((*__local_pfile_in_zip_read_info).pos_local_extrafield as c_ulong)) as c_ulong)))

    if ((if __param_buf == null: 1 else: 0) != 0) {
        return ((__local_size_to_read as c_int))
    }

    if ((if __param_len > __local_size_to_read: 1 else: 0) != 0) {
        (__local_read_now = ((__local_size_to_read as c_uint)))
    } else {
        (__local_read_now = __param_len)
    }

    if ((if __local_read_now == 0: 1 else: 0) != 0) {
        return 0
    }

    if ((if call_zseek64((((&raw const (*__local_pfile_in_zip_read_info).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_pfile_in_zip_read_info).filestream, ((((*__local_pfile_in_zip_read_info).offset_local_extrafield as c_ulong) +% ((*__local_pfile_in_zip_read_info).pos_local_extrafield as c_ulong)) as c_ulong), (0 as c_int)) != 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if (*(&raw const (*__local_pfile_in_zip_read_info).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_pfile_in_zip_read_info).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_pfile_in_zip_read_info).filestream, __param_buf, (__local_read_now as c_ulong)) != __local_read_now: 1 else: 0) != 0) {
        return -1
    }

    return ((__local_read_now as c_int))

}

pub unsafe fn unzGetOffset64(__param_file: *mut c_void) -> c_ulong {
    var __local_s: *mut unz64_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if not ((*__local_s).current_file_ok != 0): 1 else: 0) != 0) {
        return 0
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry != 65535: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        if ((if (*__local_s).num_file == (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry: 1 else: 0) != 0) {
            return 0
        }
    }


    return (*__local_s).pos_in_central_dir

}

pub unsafe fn unzGetOffset(__param_file: *mut c_void) -> c_ulong {
    var __local_offset64: c_ulong

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_offset64 = ((unzGetOffset64(__param_file) as c_ulong)))

    return __local_offset64

}

pub unsafe fn unzSetOffset64(__param_file: *mut c_void, __param_pos: c_ulong) -> c_int {
    var __local_s: *mut unz64_s

    var __local_err: c_int

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    ((*__local_s).pos_in_central_dir = __param_pos)

    ((*__local_s).num_file = (*(&raw const (*__local_s).gi as *const unz_global_info64_s)).number_entry)

    (__local_err = ((unz64local_GetCurrentFileInfoInternal(__param_file, ((&raw const (*__local_s).cur_file_info as *const unz_file_info64_s) as *mut unz_file_info64_s), ((&raw const (*__local_s).cur_file_info_internal as *const unz_file_info64_internal_s) as *mut unz_file_info64_internal_s), (null as *mut i8), (0 as c_ulong), null, (0 as c_ulong), (null as *mut i8), (0 as c_ulong)) as c_int)))

    ((*__local_s).current_file_ok = (((if __local_err == 0: 1 else: 0) as c_ulong)))

    return __local_err

}

pub unsafe fn unzSetOffset(__param_file: *mut c_void, __param_pos: c_ulong) -> c_int {
    return unzSetOffset64(__param_file, __param_pos)

}

unsafe fn decrypt_byte(__param_pkeys: *mut c_ulong, __param_pcrc_32_tab: *const c_uint) -> c_int {
    var __local_temp: c_uint

    __param_pcrc_32_tab

    (__local_temp = ((((((((*(__param_pkeys + ((2 as isize) as usize))) as c_uint) as c_uint) & (65535 as c_uint)) as c_uint) | (2 as c_uint)) as c_uint)))

    return ((((((((__local_temp as c_uint) *% (((__local_temp as c_uint) ^ (1 as c_uint)) as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as c_int))

}

unsafe fn update_keys(__param_pkeys: *mut c_ulong, __param_pcrc_32_tab: *const c_uint, __param_c: c_int) -> c_int {
    ((*(__param_pkeys + ((0 as isize) as usize))) = (((((*(__param_pcrc_32_tab + ((((((((*(__param_pkeys + ((0 as isize) as usize))) as c_int) as c_int) ^ (__param_c as c_int)) as c_int) & (255 as c_int)) as isize) as usize))) as c_ulong) ^ ((((*(__param_pkeys + ((0 as isize) as usize))) as c_ulong) >> (8 as c_uint)) as c_ulong)) as c_ulong)))

    ((*(__param_pkeys + ((1 as isize) as usize))) = ((*(__param_pkeys + ((1 as isize) as usize))) +% (((*(__param_pkeys + ((0 as isize) as usize))) as c_ulong) & (255 as c_ulong))))

    ((*(__param_pkeys + ((1 as isize) as usize))) = (((((((*(__param_pkeys + ((1 as isize) as usize))) as c_ulong) *% (134775813 as c_ulong)) as c_ulong) +% (1 as c_ulong)) as c_ulong)))

    var __local_keyshift: c_int = (((((*(__param_pkeys + ((1 as isize) as usize))) as c_ulong) >> (24 as c_uint)) as c_int))

    ((*(__param_pkeys + ((2 as isize) as usize))) = (((((*(__param_pcrc_32_tab + ((((((((*(__param_pkeys + ((2 as isize) as usize))) as c_int) as c_int) ^ (__local_keyshift as c_int)) as c_int) & (255 as c_int)) as isize) as usize))) as c_ulong) ^ ((((*(__param_pkeys + ((2 as isize) as usize))) as c_ulong) >> (8 as c_uint)) as c_ulong)) as c_ulong)))


    return __param_c

}

unsafe fn init_keys(__param_passwd: *const i8, __param_pkeys: *mut c_ulong, __param_pcrc_32_tab: *const c_uint) -> Unit {
    var __local_passwd = __param_passwd
    ((*(__param_pkeys + ((0 as isize) as usize))) = ((305419896 as c_ulong)))

    ((*(__param_pkeys + ((1 as isize) as usize))) = ((591751049 as c_ulong)))

    ((*(__param_pkeys + ((2 as isize) as usize))) = ((878082192 as c_ulong)))

    while ((if (*__local_passwd) != 0: 1 else: 0) != 0) {
        update_keys(__param_pkeys, __param_pcrc_32_tab, ((*__local_passwd) as c_int))

        (__local_passwd = __local_passwd + 1)

    }

}

unsafe fn unz64local_getShort(__param_pzlib_filefunc_def: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void, __param_pX: *mut c_ulong) -> c_int {
    var __local_c: [2]u8

    var __local_err: c_int = (((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, (&__local_c[0] as *mut u8), (2 as c_ulong)) as c_int))

    if ((if __local_err == 2: 1 else: 0) != 0) {
        ((*__param_pX) = (((((__local_c[0] as c_int) as c_ulong) | ((((__local_c[1] as c_ulong) as c_ulong) << (8 as c_uint)) as c_ulong)) as c_ulong)))

        return 0

    }
    ((*__param_pX) = ((0 as c_ulong)))

    if ((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zerror_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream) != 0) {
        return -1
    }
    return 0


}

unsafe fn unz64local_getLong(__param_pzlib_filefunc_def: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void, __param_pX: *mut c_ulong) -> c_int {
    var __local_c: [4]u8

    var __local_err: c_int = (((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, (&__local_c[0] as *mut u8), (4 as c_ulong)) as c_int))

    if ((if __local_err == 4: 1 else: 0) != 0) {
        ((*__param_pX) = (((((((((__local_c[0] as c_int) as c_ulong) | ((((__local_c[1] as c_ulong) as c_ulong) << (8 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[2] as c_ulong) as c_ulong) << (16 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[3] as c_ulong) as c_ulong) << (24 as c_uint)) as c_ulong)) as c_ulong)))

        return 0

    }
    ((*__param_pX) = ((0 as c_ulong)))

    if ((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zerror_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream) != 0) {
        return -1
    }
    return 0


}

unsafe fn unz64local_getLong64(__param_pzlib_filefunc_def: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void, __param_pX: *mut c_ulong) -> c_int {
    var __local_c: [8]u8

    var __local_err: c_int = (((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, (&__local_c[0] as *mut u8), (8 as c_ulong)) as c_int))

    if ((if __local_err == 8: 1 else: 0) != 0) {
        ((*__param_pX) = (((((((((((((((((__local_c[0] as c_int) as c_ulong) | ((((__local_c[1] as c_ulong) as c_ulong) << (8 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[2] as c_ulong) as c_ulong) << (16 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[3] as c_ulong) as c_ulong) << (24 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[4] as c_ulong) as c_ulong) << (32 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[5] as c_ulong) as c_ulong) << (40 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[6] as c_ulong) as c_ulong) << (48 as c_uint)) as c_ulong)) as c_ulong) | ((((__local_c[7] as c_ulong) as c_ulong) << (56 as c_uint)) as c_ulong)) as c_ulong)))

        return 0

    }
    ((*__param_pX) = ((0 as c_ulong)))

    if ((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zerror_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream) != 0) {
        return -1
    }
    return 0


}

unsafe fn strcmpcasenosensitive_internal(__param_fileName1: *const i8, __param_fileName2: *const i8) -> c_int {
    var __local_fileName1 = __param_fileName1
    var __local_fileName2 = __param_fileName2
    while true {
        var __local_c1: c_char = with 0 as __ci_expr_seq_7 {
            var __ci_expr_old_0: *const i8 = __local_fileName1
            (__local_fileName1 = __local_fileName1 + 1)
            ((*__ci_expr_old_0) as c_char)
        }

        var __local_c2: c_char = with 0 as __ci_expr_seq_14 {
            var __ci_expr_old_1: *const i8 = __local_fileName2
            (__local_fileName2 = __local_fileName2 + 1)
            ((*__ci_expr_old_1) as c_char)
        }

        var __ci_expr_logic_2: c_int = 0

        if ((if __local_c1 >= 97: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_c1 <= 122: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__local_c1 = __local_c1 - 32)
        }


        var __ci_expr_logic_3: c_int = 0

        if ((if __local_c2 >= 97: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __local_c2 <= 122: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__local_c2 = __local_c2 - 32)
        }


        if ((if __local_c1 == 0: 1 else: 0) != 0) {
            var __ci_expr_ternary_4: c_int = 0

            if ((if __local_c2 == 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_4 = ((0 as c_int)))
            } else {
                (__ci_expr_ternary_4 = ((-1 as c_int)))
            }

            return __ci_expr_ternary_4

        }

        if ((if __local_c2 == 0: 1 else: 0) != 0) {
            return 1
        }

        if ((if __local_c1 < __local_c2: 1 else: 0) != 0) {
            return -1
        }

        if ((if __local_c1 > __local_c2: 1 else: 0) != 0) {
            return 1
        }

    }

}

unsafe fn unz64local_SearchCentralDir(__param_pzlib_filefunc_def: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void) -> c_ulong {
    var __local_buf: *mut u8

    var __local_uSizeFile: c_ulong

    var __local_uBackRead: c_ulong

    var __local_uMaxBack: c_ulong = ((65535 as c_ulong))

    var __local_uPosFound: c_ulong = ((-1 as c_ulong))

    if ((if call_zseek64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream, (0 as c_ulong), (2 as c_int)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    (__local_uSizeFile = ((call_ztell64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream) as c_ulong)))

    if ((if __local_uMaxBack > __local_uSizeFile: 1 else: 0) != 0) {
        (__local_uMaxBack = __local_uSizeFile)
    }

    (__local_buf = (((with_alloc(((1028 as c_ulong) as i64)) as *mut c_void) as *mut u8)))

    if ((if __local_buf == null: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    (__local_uBackRead = ((4 as c_ulong)))

    while ((if __local_uBackRead < __local_uMaxBack: 1 else: 0) != 0) {
        var __local_uReadSize: c_ulong

        var __local_uReadPos: c_ulong

        var __local_i: c_int

        if ((if ((__local_uBackRead as c_ulong) +% (1024 as c_ulong)) > __local_uMaxBack: 1 else: 0) != 0) {
            (__local_uBackRead = __local_uMaxBack)
        } else {
            (__local_uBackRead = (__local_uBackRead +% 1024))
        }

        (__local_uReadPos = ((((__local_uSizeFile as c_ulong) -% (__local_uBackRead as c_ulong)) as c_ulong)))

        var __ci_expr_ternary_0: c_ulong = 0

        if ((if 1028 < ((__local_uSizeFile as c_ulong) -% (__local_uReadPos as c_ulong)): 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((1028 as c_ulong)))
        } else {
            (__ci_expr_ternary_0 = ((((__local_uSizeFile as c_ulong) -% (__local_uReadPos as c_ulong)) as c_ulong)))
        }

        (__local_uReadSize = __ci_expr_ternary_0)


        if ((if call_zseek64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream, __local_uReadPos, (0 as c_int)) != 0: 1 else: 0) != 0) {
            break
        }

        if ((if (*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, (__local_buf as *mut c_void), __local_uReadSize) != __local_uReadSize: 1 else: 0) != 0) {
            break
        }

        (__local_i = ((((__local_uReadSize as c_int) - 3) as c_int)))

        while true {
            var __ci_expr_old_1: c_int = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_1 > 0: 1 else: 0) != 0)) {
                break
            }

            var __ci_expr_logic_4: c_int = 0

            var __ci_expr_logic_3: c_int = 0

            var __ci_expr_logic_2: c_int = 0

            if ((if (*(__local_buf + ((__local_i as isize) as usize))) == 80: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if (*((__local_buf + ((__local_i as isize) as usize)) + ((1 as isize) as usize))) == 75: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if (if (*((__local_buf + ((__local_i as isize) as usize)) + ((2 as isize) as usize))) == 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if (if (*((__local_buf + ((__local_i as isize) as usize)) + ((3 as isize) as usize))) == 6: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__local_uPosFound = ((((__local_uReadPos as c_ulong) +% ((__local_i as c_uint) as c_ulong)) as c_ulong)))

                break

            }

        }


        if ((if __local_uPosFound != ((-1 as c_ulong)): 1 else: 0) != 0) {
            break
        }

    }

    with_free(((__local_buf as *mut c_void) as *mut u8))

    return __local_uPosFound

}

unsafe fn unz64local_SearchCentralDir64(__param_pzlib_filefunc_def: *const zlib_filefunc64_32_def_s, __param_filestream: *mut c_void) -> c_ulong {
    var __local_buf: *mut u8

    var __local_uSizeFile: c_ulong

    var __local_uBackRead: c_ulong

    var __local_uMaxBack: c_ulong = ((65535 as c_ulong))

    var __local_uPosFound: c_ulong = ((-1 as c_ulong))

    var __local_uL: c_ulong

    var __local_relativeOffset: c_ulong

    if ((if call_zseek64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream, (0 as c_ulong), (2 as c_int)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    (__local_uSizeFile = ((call_ztell64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream) as c_ulong)))

    if ((if __local_uMaxBack > __local_uSizeFile: 1 else: 0) != 0) {
        (__local_uMaxBack = __local_uSizeFile)
    }

    (__local_buf = (((with_alloc(((1028 as c_ulong) as i64)) as *mut c_void) as *mut u8)))

    if ((if __local_buf == null: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    (__local_uBackRead = ((4 as c_ulong)))

    while ((if __local_uBackRead < __local_uMaxBack: 1 else: 0) != 0) {
        var __local_uReadSize: c_ulong

        var __local_uReadPos: c_ulong

        var __local_i: c_int

        if ((if ((__local_uBackRead as c_ulong) +% (1024 as c_ulong)) > __local_uMaxBack: 1 else: 0) != 0) {
            (__local_uBackRead = __local_uMaxBack)
        } else {
            (__local_uBackRead = (__local_uBackRead +% 1024))
        }

        (__local_uReadPos = ((((__local_uSizeFile as c_ulong) -% (__local_uBackRead as c_ulong)) as c_ulong)))

        var __ci_expr_ternary_0: c_ulong = 0

        if ((if 1028 < ((__local_uSizeFile as c_ulong) -% (__local_uReadPos as c_ulong)): 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((1028 as c_ulong)))
        } else {
            (__ci_expr_ternary_0 = ((((__local_uSizeFile as c_ulong) -% (__local_uReadPos as c_ulong)) as c_ulong)))
        }

        (__local_uReadSize = __ci_expr_ternary_0)


        if ((if call_zseek64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream, __local_uReadPos, (0 as c_int)) != 0: 1 else: 0) != 0) {
            break
        }

        if ((if (*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__param_pzlib_filefunc_def).zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, __param_filestream, (__local_buf as *mut c_void), __local_uReadSize) != __local_uReadSize: 1 else: 0) != 0) {
            break
        }

        (__local_i = ((((__local_uReadSize as c_int) - 3) as c_int)))

        while true {
            var __ci_expr_old_1: c_int = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_1 > 0: 1 else: 0) != 0)) {
                break
            }

            var __ci_expr_logic_4: c_int = 0

            var __ci_expr_logic_3: c_int = 0

            var __ci_expr_logic_2: c_int = 0

            if ((if (*(__local_buf + ((__local_i as isize) as usize))) == 80: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if (*((__local_buf + ((__local_i as isize) as usize)) + ((1 as isize) as usize))) == 75: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if (if (*((__local_buf + ((__local_i as isize) as usize)) + ((2 as isize) as usize))) == 6: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if (if (*((__local_buf + ((__local_i as isize) as usize)) + ((3 as isize) as usize))) == 7: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__local_uPosFound = ((((__local_uReadPos as c_ulong) +% ((__local_i as c_uint) as c_ulong)) as c_ulong)))

                break

            }

        }


        if ((if __local_uPosFound != ((-1 as c_ulong)): 1 else: 0) != 0) {
            break
        }

    }

    with_free(((__local_buf as *mut c_void) as *mut u8))

    if ((if __local_uPosFound == ((-1 as c_ulong)): 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if call_zseek64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream, __local_uPosFound, (0 as c_int)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if unz64local_getLong(__param_pzlib_filefunc_def, __param_filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if unz64local_getLong(__param_pzlib_filefunc_def, __param_filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if __local_uL != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if unz64local_getLong64(__param_pzlib_filefunc_def, __param_filestream, (&raw mut __local_relativeOffset as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if unz64local_getLong(__param_pzlib_filefunc_def, __param_filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if __local_uL != 1: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if call_zseek64((&raw const (*__param_pzlib_filefunc_def) as *const zlib_filefunc64_32_def_s), __param_filestream, __local_relativeOffset, (0 as c_int)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if unz64local_getLong(__param_pzlib_filefunc_def, __param_filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    if ((if __local_uL != 101075792: 1 else: 0) != 0) {
        return ((-1 as c_ulong))
    }

    return __local_relativeOffset

}

unsafe fn unzOpenInternal(__param_path: *const c_void, __param_pzlib_filefunc64_32_def: *mut zlib_filefunc64_32_def_s, __param_is64bitOpenFunction: c_int) -> *mut c_void {
    var __local_us: unz64_s

    var __local_s: *mut unz64_s

    var __local_central_pos: c_ulong

    var __local_uL: c_ulong

    var __local_number_disk: c_ulong

    var __local_number_disk_with_CD: c_ulong

    var __local_number_entry_CD: c_ulong

    var __local_err: c_int = ((0 as c_int))

    if ((if 32 != 32: 1 else: 0) != 0) {
        return null
    }

    (__local_us.z_filefunc.zseek32_file = null)

    (__local_us.z_filefunc.ztell32_file = null)

    if ((if __param_pzlib_filefunc64_32_def == null: 1 else: 0) != 0) {
        fill_fopen64_filefunc(((&raw const (*(&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s)).zfile_func64 as *const zlib_filefunc64_def_s) as *mut zlib_filefunc64_def_s))
    } else {
        with_memcpy((&raw mut __local_us.z_filefunc as *mut u8), (&raw const (*__param_pzlib_filefunc64_32_def) as *const u8), sizeof[zlib_filefunc64_32_def_s]())
    }

    (__local_us.is64bitOpenFunction = __param_is64bitOpenFunction)

    (__local_us.filestream = call_zopen64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), __param_path, (((1 as c_int) | (4 as c_int)) as c_int)))

    if ((if (*(&raw const __local_us as *const unz64_s)).filestream == null: 1 else: 0) != 0) {
        return null
    }

    (__local_central_pos = ((unz64local_SearchCentralDir64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream) as c_ulong)))

    if ((if __local_central_pos != ((-1 as c_ulong)): 1 else: 0) != 0) {
        var __local_uS: c_ulong

        var __local_uL64: c_ulong

        (__local_us.isZip64 = ((1 as c_int)))

        if ((if call_zseek64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, __local_central_pos, (0 as c_int)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL64 as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uS as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uS as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_number_disk as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_number_disk_with_CD as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, ((&raw const (*(&raw const (*(&raw const __local_us as *const unz64_s)).gi as *const unz_global_info64_s)).number_entry as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_number_entry_CD as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        var __ci_expr_logic_1: c_int

        var __ci_expr_logic_0: c_int

        if ((if __local_number_entry_CD != (*(&raw const __local_us.gi as *const unz_global_info64_s)).number_entry: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_number_disk_with_CD != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_number_disk != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_err = ((-103 as c_int)))
        }


        if ((if unz64local_getLong64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, ((&raw const (*(&raw const __local_us as *const unz64_s)).size_central_dir as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, ((&raw const (*(&raw const __local_us as *const unz64_s)).offset_central_dir as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        (__local_us.gi.size_comment = ((0 as c_ulong)))

    } else {
        (__local_central_pos = ((unz64local_SearchCentralDir((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream) as c_ulong)))

        if ((if __local_central_pos == ((-1 as c_ulong)): 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        (__local_us.isZip64 = ((0 as c_int)))

        if ((if call_zseek64((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, __local_central_pos, (0 as c_int)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getLong((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_number_disk as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_number_disk_with_CD as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        (__local_us.gi.number_entry = __local_uL)

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        (__local_number_entry_CD = __local_uL)

        var __ci_expr_logic_3: c_int

        var __ci_expr_logic_2: c_int

        if ((if __local_number_entry_CD != (*(&raw const __local_us.gi as *const unz_global_info64_s)).number_entry: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_number_disk_with_CD != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_number_disk != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__local_err = ((-103 as c_int)))
        }


        if ((if unz64local_getLong((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        (__local_us.size_central_dir = __local_uL)

        if ((if unz64local_getLong((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

        (__local_us.offset_central_dir = __local_uL)

        if ((if unz64local_getShort((((&raw const (*(&raw const __local_us as *const unz64_s)).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*(&raw const __local_us as *const unz64_s)).filestream, ((&raw const (*(&raw const (*(&raw const __local_us as *const unz64_s)).gi as *const unz_global_info64_s)).size_comment as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        }

    }

    var __ci_expr_logic_4: c_int = 0

    if ((if __local_central_pos < (((*(&raw const __local_us as *const unz64_s)).offset_central_dir as c_ulong) +% ((*(&raw const __local_us as *const unz64_s)).size_central_dir as c_ulong)): 1 else: 0) != 0) {
        (__ci_expr_logic_4 = (if (if __local_err == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__local_err = ((-103 as c_int)))
    }


    if ((if __local_err != 0: 1 else: 0) != 0) {
        (*(&raw const __local_us.z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zclose_file((*(&raw const __local_us.z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*(&raw const __local_us as *const unz64_s)).filestream)

        return null

    }

    (__local_us.byte_before_the_zipfile = ((((__local_central_pos as c_ulong) -% ((((*(&raw const __local_us as *const unz64_s)).offset_central_dir as c_ulong) +% ((*(&raw const __local_us as *const unz64_s)).size_central_dir as c_ulong)) as c_ulong)) as c_ulong)))

    (__local_us.central_pos = __local_central_pos)

    (__local_us.pfile_in_zip_read = ((null as *mut file_in_zip64_read_info_s)))

    (__local_us.encrypted = ((0 as c_int)))

    (__local_s = (((with_alloc(((sizeof[unz64_s]() as c_ulong) as i64)) as *mut c_void) as *mut unz64_s)))

    if ((if __local_s != null: 1 else: 0) != 0) {
        with_memcpy((&raw mut (*__local_s) as *mut u8), (&raw const __local_us as *const u8), sizeof[unz64_s]())

        unzGoToFirstFile((__local_s as *mut c_void))

    }

    return ((__local_s as *mut c_void))

}

unsafe fn unz64local_DosDateToTmuDate(__param_ulDosDate: c_ulong, __param_ptm: *mut tm_unz_s) -> Unit {
    var __local_uDate: c_ulong

    (__local_uDate = ((((__param_ulDosDate as c_ulong) >> (16 as c_uint)) as c_ulong)))

    ((*__param_ptm).tm_mday = ((((__local_uDate as c_ulong) & (31 as c_ulong)) as c_int)))

    ((*__param_ptm).tm_mon = ((((((((__local_uDate as c_ulong) & (480 as c_ulong)) as c_ulong) / (32 as c_ulong)) as c_ulong) -% (1 as c_ulong)) as c_int)))

    ((*__param_ptm).tm_year = ((((((((__local_uDate as c_ulong) & (65024 as c_ulong)) as c_ulong) / (512 as c_ulong)) as c_ulong) +% (1980 as c_ulong)) as c_int)))

    ((*__param_ptm).tm_hour = ((((((__param_ulDosDate as c_ulong) & (63488 as c_ulong)) as c_ulong) / (2048 as c_ulong)) as c_int)))

    ((*__param_ptm).tm_min = ((((((__param_ulDosDate as c_ulong) & (2016 as c_ulong)) as c_ulong) / (32 as c_ulong)) as c_int)))

    ((*__param_ptm).tm_sec = ((((2 as c_ulong) *% (((__param_ulDosDate as c_ulong) & (31 as c_ulong)) as c_ulong)) as c_int)))

}

unsafe fn unz64local_GetCurrentFileInfoInternal(__param_file: *mut c_void, __param_pfile_info: *mut unz_file_info64_s, __param_pfile_info_internal: *mut unz_file_info64_internal_s, __param_szFileName: *mut i8, __param_fileNameBufferSize: c_ulong, __param_extraField: *mut c_void, __param_extraFieldBufferSize: c_ulong, __param_szComment: *mut i8, __param_commentBufferSize: c_ulong) -> c_int {
    var __local_s: *mut unz64_s

    var __local_file_info: unz_file_info64_s

    var __local_file_info_internal: unz_file_info64_internal_s

    var __local_err: c_int = ((0 as c_int))

    var __local_uMagic: c_ulong

    var __local_lSeek: c_long = ((0 as c_long))

    var __local_uL: c_ulong

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -102
    }

    (__local_s = ((__param_file as *mut unz64_s)))

    if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((((*__local_s).pos_in_central_dir as c_ulong) +% ((*__local_s).byte_before_the_zipfile as c_ulong)) as c_ulong), (0 as c_int)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if __local_err == 0: 1 else: 0) != 0) {
        if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (&raw mut __local_uMagic as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        } else {
            if ((if __local_uMagic != 33639248: 1 else: 0) != 0) {
                (__local_err = ((-103 as c_int)))
            }
        }

    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).version as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).version_needed as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).flag as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).compression_method as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).dosDate as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    unz64local_DosDateToTmuDate((*(&raw const __local_file_info as *const unz_file_info64_s)).dosDate, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).tmu_date as *const tm_unz_s) as *mut tm_unz_s))

    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).crc as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    (__local_file_info.compressed_size = __local_uL)

    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    (__local_file_info.uncompressed_size = __local_uL)

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).size_filename as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).disk_num_start as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).internal_fa as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).external_fa as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (&raw mut __local_uL as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    (__local_file_info_internal.offset_curfile = __local_uL)

    (__local_lSeek = __local_lSeek + (*(&raw const __local_file_info as *const unz_file_info64_s)).size_filename)

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_szFileName != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_uSizeRead: c_ulong

        if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_filename < __param_fileNameBufferSize: 1 else: 0) != 0) {
            ((*(__param_szFileName + ((*(&raw const __local_file_info as *const unz_file_info64_s)).size_filename as usize))) = ((0 as c_char)))

            (__local_uSizeRead = (*(&raw const __local_file_info as *const unz_file_info64_s)).size_filename)

        } else {
            (__local_uSizeRead = __param_fileNameBufferSize)
        }

        var __ci_expr_logic_1: c_int = 0

        if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_filename > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __param_fileNameBufferSize > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            if ((if (*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_s).filestream, (__param_szFileName as *mut c_void), __local_uSizeRead) != __local_uSizeRead: 1 else: 0) != 0) {
                (__local_err = ((-1 as c_int)))
            }
        }


        (__local_lSeek = __local_lSeek - __local_uSizeRead)

    }


    var __ci_expr_logic_2: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __param_extraField != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        var __local_uSizeRead_1: c_ulong

        if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra < __param_extraFieldBufferSize: 1 else: 0) != 0) {
            (__local_uSizeRead_1 = (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra)
        } else {
            (__local_uSizeRead_1 = __param_extraFieldBufferSize)
        }

        if ((if __local_lSeek != 0: 1 else: 0) != 0) {
            if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (__local_lSeek as c_ulong), (1 as c_int)) == 0: 1 else: 0) != 0) {
                (__local_lSeek = ((0 as c_long)))
            } else {
                (__local_err = ((-1 as c_int)))
            }

        }

        var __ci_expr_logic_3: c_int = 0

        if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __param_extraFieldBufferSize > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            if ((if (*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_s).filestream, __param_extraField, __local_uSizeRead_1) != __local_uSizeRead_1: 1 else: 0) != 0) {
                (__local_err = ((-1 as c_int)))
            }
        }


        (__local_lSeek = __local_lSeek + (((*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra as c_ulong) -% (__local_uSizeRead_1 as c_ulong)))

    } else {
        (__local_lSeek = __local_lSeek + (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra)
    }


    var __ci_expr_logic_4: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_4 = (if (if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        var __local_acc: c_ulong = ((0 as c_ulong))

        (__local_lSeek = __local_lSeek - (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra)

        if ((if __local_lSeek != 0: 1 else: 0) != 0) {
            if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (__local_lSeek as c_ulong), (1 as c_int)) == 0: 1 else: 0) != 0) {
                (__local_lSeek = ((0 as c_long)))
            } else {
                (__local_err = ((-1 as c_int)))
            }

        }

        while ((if __local_acc < (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_extra: 1 else: 0) != 0) {
            var __local_headerId: c_ulong

            var __local_dataSize: c_ulong

            if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (&raw mut __local_headerId as *mut c_ulong)) != 0: 1 else: 0) != 0) {
                (__local_err = ((-1 as c_int)))
            }

            if ((if unz64local_getShort((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (&raw mut __local_dataSize as *mut c_ulong)) != 0: 1 else: 0) != 0) {
                (__local_err = ((-1 as c_int)))
            }

            if ((if __local_headerId == 1: 1 else: 0) != 0) {
                if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).uncompressed_size == 4294967295: 1 else: 0) != 0) {
                    if ((if unz64local_getLong64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).uncompressed_size as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
                        (__local_err = ((-1 as c_int)))
                    }

                }

                if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).compressed_size == 4294967295: 1 else: 0) != 0) {
                    if ((if unz64local_getLong64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).compressed_size as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
                        (__local_err = ((-1 as c_int)))
                    }

                }

                if ((if (*(&raw const __local_file_info_internal as *const unz_file_info64_internal_s)).offset_curfile == 4294967295: 1 else: 0) != 0) {
                    if ((if unz64local_getLong64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info_internal as *const unz_file_info64_internal_s)).offset_curfile as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
                        (__local_err = ((-1 as c_int)))
                    }

                }

                if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).disk_num_start == 65535: 1 else: 0) != 0) {
                    if ((if unz64local_getLong((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, ((&raw const (*(&raw const __local_file_info as *const unz_file_info64_s)).disk_num_start as *const c_ulong) as *mut c_ulong)) != 0: 1 else: 0) != 0) {
                        (__local_err = ((-1 as c_int)))
                    }

                }

            } else {
                if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, __local_dataSize, (1 as c_int)) != 0: 1 else: 0) != 0) {
                    (__local_err = ((-1 as c_int)))
                }

            }

            (__local_acc = (__local_acc +% ((4 as c_ulong) +% (__local_dataSize as c_ulong))))

        }

    }


    var __ci_expr_logic_5: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_5 = (if (if __param_szComment != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        var __local_uSizeRead_2: c_ulong

        if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment < __param_commentBufferSize: 1 else: 0) != 0) {
            ((*(__param_szComment + ((*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment as usize))) = ((0 as c_char)))

            (__local_uSizeRead_2 = (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment)

        } else {
            (__local_uSizeRead_2 = __param_commentBufferSize)
        }

        if ((if __local_lSeek != 0: 1 else: 0) != 0) {
            if ((if call_zseek64((((&raw const (*__local_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__local_s).filestream, (__local_lSeek as c_ulong), (1 as c_int)) == 0: 1 else: 0) != 0) {
                (__local_lSeek = ((0 as c_long)))
            } else {
                (__local_err = ((-1 as c_int)))
            }

        }

        var __ci_expr_logic_6: c_int = 0

        if ((if (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if __param_commentBufferSize > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            if ((if (*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).zread_file((*(&raw const (*__local_s).z_filefunc.zfile_func64 as *const zlib_filefunc64_def_s)).opaque_, (*__local_s).filestream, (__param_szComment as *mut c_void), __local_uSizeRead_2) != __local_uSizeRead_2: 1 else: 0) != 0) {
                (__local_err = ((-1 as c_int)))
            }
        }


        (__local_lSeek = __local_lSeek + (((*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment as c_ulong) -% (__local_uSizeRead_2 as c_ulong)))

    } else {
        (__local_lSeek = __local_lSeek + (*(&raw const __local_file_info as *const unz_file_info64_s)).size_file_comment)
    }


    var __ci_expr_logic_7: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_7 = (if (if __param_pfile_info != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        with_memcpy((&raw mut (*__param_pfile_info) as *mut u8), (&raw const __local_file_info as *const u8), sizeof[unz_file_info64_s]())
    }


    var __ci_expr_logic_8: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_8 = (if (if __param_pfile_info_internal != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_8 != 0) {
        with_memcpy((&raw mut (*__param_pfile_info_internal) as *mut u8), (&raw const __local_file_info_internal as *const u8), sizeof[unz_file_info64_internal_s]())
    }


    return __local_err

}

unsafe fn unz64local_CheckCurrentFileCoherencyHeader(__param_s: *mut unz64_s, __param_piSizeVar: *mut c_uint, __param_poffset_local_extrafield: *mut c_ulong, __param_psize_local_extrafield: *mut c_uint) -> c_int {
    var __local_uMagic: c_ulong

    var __local_uData: c_ulong

    var __local_uFlags: c_ulong


    var __local_size_filename: c_ulong

    var __local_size_extra_field: c_ulong

    var __local_err: c_int = ((0 as c_int))

    ((*__param_piSizeVar) = ((0 as c_uint)))

    ((*__param_poffset_local_extrafield) = ((0 as c_ulong)))

    ((*__param_psize_local_extrafield) = ((0 as c_uint)))

    if ((if call_zseek64((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, ((((*(&raw const (*__param_s).cur_file_info_internal as *const unz_file_info64_internal_s)).offset_curfile as c_ulong) +% ((*__param_s).byte_before_the_zipfile as c_ulong)) as c_ulong), (0 as c_int)) != 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if __local_err == 0: 1 else: 0) != 0) {
        if ((if unz64local_getLong((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uMagic as *mut c_ulong)) != 0: 1 else: 0) != 0) {
            (__local_err = ((-1 as c_int)))
        } else {
            if ((if __local_uMagic != 67324752: 1 else: 0) != 0) {
                (__local_err = ((-103 as c_int)))
            }
        }

    }

    if ((if unz64local_getShort((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uData as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uFlags as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getShort((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uData as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_err == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_uData != (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).compression_method: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_err = ((-103 as c_int)))
        }

    }

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    if ((if __local_err == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).compression_method != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if (if (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).compression_method != 12: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if (if (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).compression_method != 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__local_err = ((-103 as c_int)))
    }


    if ((if unz64local_getLong((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uData as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    if ((if unz64local_getLong((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uData as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    } else {
        var __ci_expr_logic_5: c_int = 0

        var __ci_expr_logic_4: c_int = 0

        if ((if __local_err == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_uData != (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).crc: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if ((__local_uFlags as c_ulong) & (8 as c_ulong)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__local_err = ((-103 as c_int)))
        }

    }

    if ((if unz64local_getLong((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uData as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    } else {
        var __ci_expr_logic_8: c_int = 0

        var __ci_expr_logic_7: c_int = 0

        var __ci_expr_logic_6: c_int = 0

        if ((if __local_uData != 4294967295: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if __local_err == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_logic_7 = (if (if __local_uData != (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).compressed_size: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_logic_8 = (if (if ((__local_uFlags as c_ulong) & (8 as c_ulong)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__local_err = ((-103 as c_int)))
        }

    }

    if ((if unz64local_getLong((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_uData as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    } else {
        var __ci_expr_logic_11: c_int = 0

        var __ci_expr_logic_10: c_int = 0

        var __ci_expr_logic_9: c_int = 0

        if ((if __local_uData != 4294967295: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if __local_err == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_9 != 0) {
            (__ci_expr_logic_10 = (if (if __local_uData != (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).uncompressed_size: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if ((__local_uFlags as c_ulong) & (8 as c_ulong)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_11 != 0) {
            (__local_err = ((-103 as c_int)))
        }

    }

    if ((if unz64local_getShort((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_size_filename as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    } else {
        var __ci_expr_logic_12: c_int = 0

        if ((if __local_err == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if (if __local_size_filename != (*(&raw const (*__param_s).cur_file_info as *const unz_file_info64_s)).size_filename: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_12 != 0) {
            (__local_err = ((-103 as c_int)))
        }

    }

    ((*__param_piSizeVar) = ((*__param_piSizeVar) +% (__local_size_filename as c_uint)))

    if ((if unz64local_getShort((((&raw const (*__param_s).z_filefunc as *const zlib_filefunc64_32_def_s) as *mut zlib_filefunc64_32_def_s) as *const zlib_filefunc64_32_def_s), (*__param_s).filestream, (&raw mut __local_size_extra_field as *mut c_ulong)) != 0: 1 else: 0) != 0) {
        (__local_err = ((-1 as c_int)))
    }

    ((*__param_poffset_local_extrafield) = (((((((*(&raw const (*__param_s).cur_file_info_internal as *const unz_file_info64_internal_s)).offset_curfile as c_ulong) +% (30 as c_ulong)) as c_ulong) +% (__local_size_filename as c_ulong)) as c_ulong)))

    ((*__param_psize_local_extrafield) = ((__local_size_extra_field as c_uint)))

    ((*__param_piSizeVar) = ((*__param_piSizeVar) +% (__local_size_extra_field as c_uint)))

    return __local_err

}
