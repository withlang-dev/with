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
use std.zl.unzip
use std.libc

pub unsafe fn unzRepair(__param_file: *const i8, __param_fileOut: *const i8, __param_fileOutTmp: *const i8, __param_nRecovered: *mut c_ulong, __param_bytesRecovered: *mut c_ulong) -> c_int {
    var __local_err: c_int = ((0 as c_int))

    var __local_fpZip: *mut c_void = fopen(__param_file, c"rb".ptr)

    var __local_fpOut: *mut c_void = fopen(__param_fileOut, c"wb".ptr)

    var __local_fpOutCD: *mut c_void = fopen(__param_fileOutTmp, c"wb".ptr)

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_fpZip != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_fpOut != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if __local_fpOutCD != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        var __local_entries: c_int = ((0 as c_int))

        var __local_totalBytes: c_ulong = ((0 as c_ulong))

        var __local_header: [30]c_char

        var __local_filename: [1024]c_char

        var __local_extra: [1024]c_char

        var __local_offset: c_int = ((0 as c_int))

        var __local_offsetCD: c_int = ((0 as c_int))

        while ((if fread((&__local_header[0] as *mut c_char), (1 as c_ulong), (30 as c_ulong), __local_fpZip) == 30: 1 else: 0) != 0) {
            var __local_currentOffset: c_int = __local_offset

            if ((if (((((((*(&__local_header[0] as *mut c_char)) as u8) as c_int) as c_int) | (((((*((&__local_header[0] as *mut c_char) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) | ((((((((*((&__local_header[0] as *mut c_char) + ((2 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) << (16 as c_uint)) as c_int)) == 67324752: 1 else: 0) != 0) {
                var __local_version: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((4 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((4 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                var __local_gpflag: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((6 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((6 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                var __local_method: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((8 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((8 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                var __local_filetime: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((10 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((10 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                var __local_filedate: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((12 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((12 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                var __local_crc: c_uint = (((((((((*((&__local_header[0] as *mut c_char) + ((14 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((14 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) | ((((((((*(((&__local_header[0] as *mut c_char) + ((14 as isize) as usize)) + ((2 as isize) as usize))) as u8) as c_int) as c_int) | (((((*((((&__local_header[0] as *mut c_char) + ((14 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) << (16 as c_uint)) as c_int)) as c_uint))

                var __local_cpsize: c_uint = (((((((((*((&__local_header[0] as *mut c_char) + ((18 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((18 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) | ((((((((*(((&__local_header[0] as *mut c_char) + ((18 as isize) as usize)) + ((2 as isize) as usize))) as u8) as c_int) as c_int) | (((((*((((&__local_header[0] as *mut c_char) + ((18 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) << (16 as c_uint)) as c_int)) as c_uint))

                var __local_uncpsize: c_uint = (((((((((*((&__local_header[0] as *mut c_char) + ((22 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((22 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) | ((((((((*(((&__local_header[0] as *mut c_char) + ((22 as isize) as usize)) + ((2 as isize) as usize))) as u8) as c_int) as c_int) | (((((*((((&__local_header[0] as *mut c_char) + ((22 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_int) << (16 as c_uint)) as c_int)) as c_uint))

                var __local_fnsize: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((26 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((26 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                var __local_extsize: c_uint = (((((((*((&__local_header[0] as *mut c_char) + ((28 as isize) as usize))) as u8) as c_int) as c_int) | (((((*(((&__local_header[0] as *mut c_char) + ((28 as isize) as usize)) + ((1 as isize) as usize))) as u8) as c_int) << (8 as c_uint)) as c_int)) as c_uint))

                (__local_extra[0] = ((0 as c_char)))

                (__local_filename[0] = ((__local_extra[0] as c_char)))


                if ((if fwrite((&__local_header[0] as *mut c_char), (1 as c_ulong), (30 as c_ulong), __local_fpOut) == 30: 1 else: 0) != 0) {
                    (__local_offset = __local_offset + 30)

                } else {
                    (__local_err = ((-1 as c_int)))

                    break

                }

                if ((if __local_fnsize > 0: 1 else: 0) != 0) {
                    if ((if __local_fnsize < (1024 * sizeof[c_char]()): 1 else: 0) != 0) {
                        if ((if fread((&__local_filename[0] as *mut c_char), (1 as c_ulong), (__local_fnsize as c_ulong), __local_fpZip) == __local_fnsize: 1 else: 0) != 0) {
                            if ((if fwrite((&__local_filename[0] as *mut c_char), (1 as c_ulong), (__local_fnsize as c_ulong), __local_fpOut) == __local_fnsize: 1 else: 0) != 0) {
                                (__local_offset = __local_offset + __local_fnsize)

                            } else {
                                (__local_err = ((-1 as c_int)))

                                break

                            }

                        } else {
                            (__local_err = ((-1 as c_int)))

                            break

                        }

                    } else {
                        (__local_err = ((-1 as c_int)))

                        break

                    }

                } else {
                    (__local_err = ((-2 as c_int)))

                    break

                }

                if ((if __local_extsize > 0: 1 else: 0) != 0) {
                    if ((if __local_extsize < (1024 * sizeof[c_char]()): 1 else: 0) != 0) {
                        if ((if fread((&__local_extra[0] as *mut c_char), (1 as c_ulong), (__local_extsize as c_ulong), __local_fpZip) == __local_extsize: 1 else: 0) != 0) {
                            if ((if fwrite((&__local_extra[0] as *mut c_char), (1 as c_ulong), (__local_extsize as c_ulong), __local_fpOut) == __local_extsize: 1 else: 0) != 0) {
                                (__local_offset = __local_offset + __local_extsize)

                            } else {
                                (__local_err = ((-1 as c_int)))

                                break

                            }

                        } else {
                            (__local_err = ((-1 as c_int)))

                            break

                        }

                    } else {
                        (__local_err = ((-1 as c_int)))

                        break

                    }

                }

                var __local_dataSize: c_int = ((__local_cpsize as c_int))

                if ((if __local_dataSize == 0: 1 else: 0) != 0) {
                    (__local_dataSize = ((__local_uncpsize as c_int)))

                }

                if ((if __local_dataSize > 0: 1 else: 0) != 0) {
                    var __local_data: *mut c_char = (((with_alloc(((__local_dataSize as c_ulong) as i64)) as *mut c_void) as *mut c_char))

                    if ((if __local_data != null: 1 else: 0) != 0) {
                        if ((if ((fread((__local_data as *mut c_void), (1 as c_ulong), (__local_dataSize as c_ulong), __local_fpZip) as c_int)) == __local_dataSize: 1 else: 0) != 0) {
                            if ((if ((fwrite((__local_data as *const c_void), (1 as c_ulong), (__local_dataSize as c_ulong), __local_fpOut) as c_int)) == __local_dataSize: 1 else: 0) != 0) {
                                (__local_offset = __local_offset + __local_dataSize)

                                (__local_totalBytes = (__local_totalBytes +% __local_dataSize))

                            } else {
                                (__local_err = ((-1 as c_int)))

                            }

                        } else {
                            (__local_err = ((-1 as c_int)))

                        }

                        with_free(((__local_data as *mut c_void) as *mut u8))

                        if ((if __local_err != 0: 1 else: 0) != 0) {
                            break

                        }

                    } else {
                        (__local_err = ((-4 as c_int)))

                        break

                    }

                }


                var __local_central: [46]c_char

                var __local_comment: *mut c_char = (("" as *mut c_char))

                var __local_comsize: c_int = ((strlen((__local_comment as *const i8)) as c_int))

                loop {
                    loop {
                        loop {
                            ((*(&__local_central[0] as *mut u8)) = ((((((33639248 as c_int) & (65535 as c_int)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*((&__local_central[0] as *mut u8) + ((1 as isize) as usize))) = ((((((((33639248 as c_int) & (65535 as c_int)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((&__local_central[0] as *mut u8) + ((2 as isize) as usize))) = ((((((33639248 as c_int) >> (16 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*(((&__local_central[0] as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((33639248 as c_int) >> (16 as c_uint)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8)) = ((((__local_version as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_version as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8)) = ((((__local_version as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_version as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8)) = ((((__local_gpflag as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_gpflag as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8)) = ((((__local_method as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_method as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8)) = ((((__local_filetime as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_filetime as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((14 as isize) as usize)) as *mut u8)) = ((((__local_filedate as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((14 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_filedate as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8)) = ((((((__local_crc as c_uint) & (65535 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_crc as c_uint) & (65535 as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_crc as c_uint) >> (16 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_crc as c_uint) >> (16 as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8)) = ((((((__local_cpsize as c_uint) & (65535 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_cpsize as c_uint) & (65535 as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_cpsize as c_uint) >> (16 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_cpsize as c_uint) >> (16 as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8)) = ((((((__local_uncpsize as c_uint) & (65535 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_uncpsize as c_uint) & (65535 as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_uncpsize as c_uint) >> (16 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_uncpsize as c_uint) >> (16 as c_uint)) as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((28 as isize) as usize)) as *mut u8)) = ((((__local_fnsize as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((28 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_fnsize as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((30 as isize) as usize)) as *mut u8)) = ((((__local_extsize as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((30 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_extsize as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((32 as isize) as usize)) as *mut u8)) = ((((__local_comsize as c_int) & (255 as c_int)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((32 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_comsize as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((34 as isize) as usize)) as *mut u8)) = ((((0 as c_int) & (255 as c_int)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((34 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((36 as isize) as usize)) as *mut u8)) = ((((0 as c_int) & (255 as c_int)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((36 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8)) = ((((((0 as c_int) & (65535 as c_int)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((0 as c_int) & (65535 as c_int)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((0 as c_int) >> (16 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((0 as c_int) >> (16 as c_uint)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8)) = ((((((__local_currentOffset as c_int) & (65535 as c_int)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_currentOffset as c_int) & (65535 as c_int)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_currentOffset as c_int) >> (16 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_currentOffset as c_int) >> (16 as c_uint)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if not ((0 != 0)) {
                            break
                        }
                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                if ((if fwrite((&__local_central[0] as *mut c_char), (1 as c_ulong), (46 as c_ulong), __local_fpOutCD) == 46: 1 else: 0) != 0) {
                    (__local_offsetCD = __local_offsetCD + 46)

                    if ((if __local_fnsize > 0: 1 else: 0) != 0) {
                        if ((if fwrite((&__local_filename[0] as *mut c_char), (1 as c_ulong), (__local_fnsize as c_ulong), __local_fpOutCD) == __local_fnsize: 1 else: 0) != 0) {
                            (__local_offsetCD = __local_offsetCD + __local_fnsize)

                        } else {
                            (__local_err = ((-1 as c_int)))

                            break

                        }

                    } else {
                        (__local_err = ((-2 as c_int)))

                        break

                    }

                    if ((if __local_extsize > 0: 1 else: 0) != 0) {
                        if ((if fwrite((&__local_extra[0] as *mut c_char), (1 as c_ulong), (__local_extsize as c_ulong), __local_fpOutCD) == __local_extsize: 1 else: 0) != 0) {
                            (__local_offsetCD = __local_offsetCD + __local_extsize)

                        } else {
                            (__local_err = ((-1 as c_int)))

                            break

                        }

                    }

                    if ((if __local_comsize > 0: 1 else: 0) != 0) {
                        if ((if ((fwrite((__local_comment as *const c_void), (1 as c_ulong), (__local_comsize as c_ulong), __local_fpOutCD) as c_int)) == __local_comsize: 1 else: 0) != 0) {
                            (__local_offsetCD = __local_offsetCD + __local_comsize)

                        } else {
                            (__local_err = ((-1 as c_int)))

                            break

                        }

                    }

                } else {
                    (__local_err = ((-1 as c_int)))

                    break

                }


                (__local_entries = __local_entries + 1)

            } else {
                break

            }

        }

        var __local_entriesZip: c_int = __local_entries

        var __local_end: [22]c_char

        var __local_comment_1: *mut c_char = (("" as *mut c_char))

        var __local_comsize_1: c_int = ((strlen((__local_comment_1 as *const i8)) as c_int))

        if ((if __local_entriesZip > 65535: 1 else: 0) != 0) {
            (__local_entriesZip = ((65535 as c_int)))

        }

        loop {
            loop {
                loop {
                    ((*(&__local_end[0] as *mut u8)) = ((((((101010256 as c_int) & (65535 as c_int)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    ((*((&__local_end[0] as *mut u8) + ((1 as isize) as usize))) = ((((((((101010256 as c_int) & (65535 as c_int)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                loop {
                    ((*((&__local_end[0] as *mut u8) + ((2 as isize) as usize))) = ((((((101010256 as c_int) >> (16 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    ((*(((&__local_end[0] as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((101010256 as c_int) >> (16 as c_uint)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8)) = ((((0 as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8)) = ((((0 as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8)) = ((((__local_entriesZip as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_entriesZip as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8)) = ((((__local_entriesZip as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_entriesZip as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                loop {
                    ((*(((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8)) = ((((((__local_offsetCD as c_int) & (65535 as c_int)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_offsetCD as c_int) & (65535 as c_int)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_offsetCD as c_int) >> (16 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    ((*(((((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_offsetCD as c_int) >> (16 as c_uint)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                loop {
                    ((*(((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8)) = ((((((__local_offset as c_int) & (65535 as c_int)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_offset as c_int) & (65535 as c_int)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_offset as c_int) >> (16 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    ((*(((((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_offset as c_int) >> (16 as c_uint)) as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                    if not ((0 != 0)) {
                        break
                    }
                }

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8)) = ((((__local_comsize_1 as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_comsize_1 as c_int) >> (8 as c_uint)) as c_int) & (255 as c_int)) as u8)))

                if not ((0 != 0)) {
                    break
                }
            }

            if not ((0 != 0)) {
                break
            }
        }

        if ((if fwrite((&__local_end[0] as *mut c_char), (1 as c_ulong), (22 as c_ulong), __local_fpOutCD) == 22: 1 else: 0) != 0) {
            if ((if __local_comsize_1 > 0: 1 else: 0) != 0) {
                if ((if ((fwrite((__local_comment_1 as *const c_void), (1 as c_ulong), (__local_comsize_1 as c_ulong), __local_fpOutCD) as c_int)) != __local_comsize_1: 1 else: 0) != 0) {
                    (__local_err = ((-1 as c_int)))

                }

            }

        } else {
            (__local_err = ((-1 as c_int)))

        }


        fclose(__local_fpOutCD)

        if ((if __local_err == 0: 1 else: 0) != 0) {
            (__local_fpOutCD = fopen(__param_fileOutTmp, c"rb".ptr))

            if ((if __local_fpOutCD != null: 1 else: 0) != 0) {
                var __local_nRead: c_int

                var __local_buffer: [8192]c_char

                while true {
                    (__local_nRead = ((fread((&__local_buffer[0] as *mut c_char), (1 as c_ulong), ((8192 * sizeof[c_char]()) as c_ulong), __local_fpOutCD) as c_int)))

                    if (not ((if __local_nRead > 0: 1 else: 0) != 0)) {
                        break
                    }

                    if ((if ((fwrite((&__local_buffer[0] as *mut c_char), (1 as c_ulong), (__local_nRead as c_ulong), __local_fpOut) as c_int)) != __local_nRead: 1 else: 0) != 0) {
                        (__local_err = ((-1 as c_int)))

                        break

                    }

                }

                fclose(__local_fpOutCD)

            }

        }

        fclose(__local_fpZip)

        fclose(__local_fpOut)

        remove(__param_fileOutTmp)

        if ((if __local_err == 0: 1 else: 0) != 0) {
            if ((if __param_nRecovered != null: 1 else: 0) != 0) {
                ((*__param_nRecovered) = ((__local_entries as c_ulong)))

            }

            if ((if __param_bytesRecovered != null: 1 else: 0) != 0) {
                ((*__param_bytesRecovered) = __local_totalBytes)

            }

        }

    } else {
        if ((if __local_fpOutCD != null: 1 else: 0) != 0) {
            fclose(__local_fpOutCD)
        }

        if ((if __local_fpZip != null: 1 else: 0) != 0) {
            fclose(__local_fpZip)
        }

        if ((if __local_fpOut != null: 1 else: 0) != 0) {
            fclose(__local_fpOut)
        }

        (__local_err = ((-2 as c_int)))

    }


    return __local_err

}
