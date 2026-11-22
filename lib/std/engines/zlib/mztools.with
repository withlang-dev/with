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
use std.engines.zlib.ioapi
use std.engines.zlib.unzip
use std.libc
use std.collections

// contract: unproved:0:read only,unproved:1:read only,stored-unknown:2,unproved:3:out-parameter read before the write,unproved:4:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn unzRepair(__param_file: *const c_char, __param_fileOut: *const c_char, __param_fileOutTmp: *const c_char, __param_nRecovered: *mut u64, __param_bytesRecovered: *mut u64) -> i32 {
    var __local_err: i32 = ((0 as i32))

    var __local_fpZip: *mut c_void = fopen(__param_file, c"rb".ptr)

    var __local_fpOut: *mut c_void = fopen(__param_fileOut, c"wb".ptr)

    var __local_fpOutCD: *mut c_void = fopen(__param_fileOutTmp, c"wb".ptr)

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if (__local_fpZip != null) {
        (__ci_expr_logic_0 = (if __local_fpOut != null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_logic_1 = (if __local_fpOutCD != null: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        var __local_entries: i32 = ((0 as i32))

        var __local_totalBytes: u64 = ((0 as u64))

        var __local_header: List[c_char] = [0; 30]

        var __local_filename: List[c_char] = [0; 1024]

        var __local_extra: List[c_char] = [0; 1024]

        var __local_offset: i32 = ((0 as i32))

        var __local_offsetCD: i32 = ((0 as i32))

        while (fread((&__local_header[0] as *mut c_char), (1 as u64), (30 as u64), __local_fpZip) == 30) {
            var __local_currentOffset: i32 = __local_offset

            if (((((((*(&__local_header[0] as *mut c_char)) as u8) as i32) | (((((*((&__local_header[0] as *mut c_char) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) | (((((((*((&__local_header[0] as *mut c_char) + ((2 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) << (16 as u32)) as i32)) == 67324752) {
                var __local_version: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((4 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((4 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                var __local_gpflag: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((6 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((6 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                var __local_method: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((8 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((8 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                var __local_filetime: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((10 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((10 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                var __local_filedate: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((12 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((12 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                var __local_crc: u32 = ((((((((*((&__local_header[0] as *mut c_char) + ((14 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((14 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) | (((((((*(((&__local_header[0] as *mut c_char) + ((14 as isize) as usize)) + ((2 as isize) as usize))) as u8) as i32) | (((((*((((&__local_header[0] as *mut c_char) + ((14 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) << (16 as u32)) as i32)) as u32))

                var __local_cpsize: u32 = ((((((((*((&__local_header[0] as *mut c_char) + ((18 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((18 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) | (((((((*(((&__local_header[0] as *mut c_char) + ((18 as isize) as usize)) + ((2 as isize) as usize))) as u8) as i32) | (((((*((((&__local_header[0] as *mut c_char) + ((18 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) << (16 as u32)) as i32)) as u32))

                var __local_uncpsize: u32 = ((((((((*((&__local_header[0] as *mut c_char) + ((22 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((22 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) | (((((((*(((&__local_header[0] as *mut c_char) + ((22 as isize) as usize)) + ((2 as isize) as usize))) as u8) as i32) | (((((*((((&__local_header[0] as *mut c_char) + ((22 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as i32) << (16 as u32)) as i32)) as u32))

                var __local_fnsize: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((26 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((26 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                var __local_extsize: u32 = ((((((*((&__local_header[0] as *mut c_char) + ((28 as isize) as usize))) as u8) as i32) | (((((*(((&__local_header[0] as *mut c_char) + ((28 as isize) as usize)) + ((1 as isize) as usize))) as u8) as i32) << (8 as u32)) as i32)) as u32))

                (__local_extra[0] = ((0 as c_char)))

                (__local_filename[0] = ((__local_extra[0] as c_char)))


                if (fwrite((&__local_header[0] as *mut c_char), (1 as u64), (30 as u64), __local_fpOut) == 30) {
                    (__local_offset = __local_offset + 30)

                } else {
                    (__local_err = ((-1 as i32)))

                    break

                }

                if (__local_fnsize > 0) {
                    if (__local_fnsize < (1024 * (sizeof[c_char]() as usize))) {
                        if (fread((&__local_filename[0] as *mut c_char), (1 as u64), (__local_fnsize as u64), __local_fpZip) == __local_fnsize) {
                            if (fwrite((&__local_filename[0] as *mut c_char), (1 as u64), (__local_fnsize as u64), __local_fpOut) == __local_fnsize) {
                                (__local_offset = ((((__local_offset as u32) + __local_fnsize) as i32)))

                            } else {
                                (__local_err = ((-1 as i32)))

                                break

                            }

                        } else {
                            (__local_err = ((-1 as i32)))

                            break

                        }

                    } else {
                        (__local_err = ((-1 as i32)))

                        break

                    }

                } else {
                    (__local_err = ((-2 as i32)))

                    break

                }

                if (__local_extsize > 0) {
                    if (__local_extsize < (1024 * (sizeof[c_char]() as usize))) {
                        if (fread((&__local_extra[0] as *mut c_char), (1 as u64), (__local_extsize as u64), __local_fpZip) == __local_extsize) {
                            if (fwrite((&__local_extra[0] as *mut c_char), (1 as u64), (__local_extsize as u64), __local_fpOut) == __local_extsize) {
                                (__local_offset = ((((__local_offset as u32) + __local_extsize) as i32)))

                            } else {
                                (__local_err = ((-1 as i32)))

                                break

                            }

                        } else {
                            (__local_err = ((-1 as i32)))

                            break

                        }

                    } else {
                        (__local_err = ((-1 as i32)))

                        break

                    }

                }

                var __local_dataSize: i32 = ((__local_cpsize as i32))

                if (__local_dataSize == 0) {
                    (__local_dataSize = ((__local_uncpsize as i32)))

                }

                if (__local_dataSize > 0) {
                    var __local_data: *mut c_char = (((with_alloc(((__local_dataSize as u64) as i64)) as *mut c_void) as *mut c_char))

                    if (__local_data != null) {
                        if (((fread((__local_data as *mut c_void), (1 as u64), (__local_dataSize as u64), __local_fpZip) as i32)) == __local_dataSize) {
                            if (((fwrite((__local_data as *const c_void), (1 as u64), (__local_dataSize as u64), __local_fpOut) as i32)) == __local_dataSize) {
                                (__local_offset = __local_offset + __local_dataSize)

                                (__local_totalBytes = (__local_totalBytes +% (__local_dataSize as u64)))

                            } else {
                                (__local_err = ((-1 as i32)))

                            }

                        } else {
                            (__local_err = ((-1 as i32)))

                        }

                        with_free(((__local_data as *mut c_void) as *mut u8))

                        if (__local_err != 0) {
                            break

                        }

                    } else {
                        (__local_err = ((-4 as i32)))

                        break

                    }

                }


                var __local_central: List[c_char] = [0; 46]

                var __local_comment: *mut c_char = (("" as *mut c_char))

                var __local_comsize: i32 = ((strlen((__local_comment as *const c_char)) as i32))

                loop {
                    loop {
                        loop {
                            ((*(&__local_central[0] as *mut u8)) = ((((((33639248 as i32) & (65535 as i32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*((&__local_central[0] as *mut u8) + ((1 as isize) as usize))) = ((((((((33639248 as i32) & (65535 as i32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((&__local_central[0] as *mut u8) + ((2 as isize) as usize))) = ((((((33639248 as i32) >> (16 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*(((&__local_central[0] as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((33639248 as i32) >> (16 as u32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8)) = ((((__local_version as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_version as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8)) = ((((__local_version as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_version as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8)) = ((((__local_gpflag as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_gpflag as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8)) = ((((__local_method as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_method as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8)) = ((((__local_filetime as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_filetime as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((14 as isize) as usize)) as *mut u8)) = ((((__local_filedate as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((14 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_filedate as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8)) = ((((((__local_crc as u32) & (65535 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_crc as u32) & (65535 as u32)) as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_crc as u32) >> (16 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_crc as u32) >> (16 as u32)) as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8)) = ((((((__local_cpsize as u32) & (65535 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_cpsize as u32) & (65535 as u32)) as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_cpsize as u32) >> (16 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_cpsize as u32) >> (16 as u32)) as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8)) = ((((((__local_uncpsize as u32) & (65535 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_uncpsize as u32) & (65535 as u32)) as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_uncpsize as u32) >> (16 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((24 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_uncpsize as u32) >> (16 as u32)) as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((28 as isize) as usize)) as *mut u8)) = ((((__local_fnsize as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((28 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_fnsize as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((30 as isize) as usize)) as *mut u8)) = ((((__local_extsize as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((30 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_extsize as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((32 as isize) as usize)) as *mut u8)) = ((((__local_comsize as i32) & (255 as i32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((32 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_comsize as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((34 as isize) as usize)) as *mut u8)) = ((((0 as i32) & (255 as i32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((34 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        ((*(((&__local_central[0] as *mut c_char) + ((36 as isize) as usize)) as *mut u8)) = ((((0 as i32) & (255 as i32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        ((*((((&__local_central[0] as *mut c_char) + ((36 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8)) = ((((((0 as i32) & (65535 as i32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((0 as i32) & (65535 as i32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((0 as i32) >> (16 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((38 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((0 as i32) >> (16 as u32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                loop {
                    loop {
                        loop {
                            ((*(((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8)) = ((((((__local_currentOffset as i32) & (65535 as i32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_currentOffset as i32) & (65535 as i32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    loop {
                        loop {
                            ((*((((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_currentOffset as i32) >> (16 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        loop {
                            ((*(((((&__local_central[0] as *mut c_char) + ((42 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_currentOffset as i32) >> (16 as u32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                            if not (false) {
                                break
                            }
                        }

                        if not (false) {
                            break
                        }
                    }

                    if not (false) {
                        break
                    }
                }

                if (fwrite((&__local_central[0] as *mut c_char), (1 as u64), (46 as u64), __local_fpOutCD) == 46) {
                    (__local_offsetCD = __local_offsetCD + 46)

                    if (__local_fnsize > 0) {
                        if (fwrite((&__local_filename[0] as *mut c_char), (1 as u64), (__local_fnsize as u64), __local_fpOutCD) == __local_fnsize) {
                            (__local_offsetCD = ((((__local_offsetCD as u32) + __local_fnsize) as i32)))

                        } else {
                            (__local_err = ((-1 as i32)))

                            break

                        }

                    } else {
                        (__local_err = ((-2 as i32)))

                        break

                    }

                    if (__local_extsize > 0) {
                        if (fwrite((&__local_extra[0] as *mut c_char), (1 as u64), (__local_extsize as u64), __local_fpOutCD) == __local_extsize) {
                            (__local_offsetCD = ((((__local_offsetCD as u32) + __local_extsize) as i32)))

                        } else {
                            (__local_err = ((-1 as i32)))

                            break

                        }

                    }

                    if (__local_comsize > 0) {
                        if (((fwrite((__local_comment as *const c_void), (1 as u64), (__local_comsize as u64), __local_fpOutCD) as i32)) == __local_comsize) {
                            (__local_offsetCD = __local_offsetCD + __local_comsize)

                        } else {
                            (__local_err = ((-1 as i32)))

                            break

                        }

                    }

                } else {
                    (__local_err = ((-1 as i32)))

                    break

                }


                (__local_entries = __local_entries + 1)

            } else {
                break

            }

        }

        var __local_entriesZip: i32 = __local_entries

        var __local_end: List[c_char] = [0; 22]

        var __local_comment_1: *mut c_char = (("" as *mut c_char))

        var __local_comsize_1: i32 = ((strlen((__local_comment_1 as *const c_char)) as i32))

        if (__local_entriesZip > 65535) {
            (__local_entriesZip = ((65535 as i32)))

        }

        loop {
            loop {
                loop {
                    ((*(&__local_end[0] as *mut u8)) = ((((((101010256 as i32) & (65535 as i32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                loop {
                    ((*((&__local_end[0] as *mut u8) + ((1 as isize) as usize))) = ((((((((101010256 as i32) & (65535 as i32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                if not (false) {
                    break
                }
            }

            loop {
                loop {
                    ((*((&__local_end[0] as *mut u8) + ((2 as isize) as usize))) = ((((((101010256 as i32) >> (16 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                loop {
                    ((*(((&__local_end[0] as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((101010256 as i32) >> (16 as u32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8)) = ((((0 as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((4 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8)) = ((((0 as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((6 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((0 as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8)) = ((((__local_entriesZip as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((8 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_entriesZip as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8)) = ((((__local_entriesZip as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((10 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_entriesZip as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                loop {
                    ((*(((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8)) = ((((((__local_offsetCD as i32) & (65535 as i32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_offsetCD as i32) & (65535 as i32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                if not (false) {
                    break
                }
            }

            loop {
                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_offsetCD as i32) >> (16 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                loop {
                    ((*(((((&__local_end[0] as *mut c_char) + ((12 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_offsetCD as i32) >> (16 as u32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                loop {
                    ((*(((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8)) = ((((((__local_offset as i32) & (65535 as i32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((((__local_offset as i32) & (65535 as i32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                if not (false) {
                    break
                }
            }

            loop {
                loop {
                    ((*((((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize))) = ((((((__local_offset as i32) >> (16 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                loop {
                    ((*(((((&__local_end[0] as *mut c_char) + ((16 as isize) as usize)) as *mut u8) + ((2 as isize) as usize)) + ((1 as isize) as usize))) = ((((((((__local_offset as i32) >> (16 as u32)) as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                    if not (false) {
                        break
                    }
                }

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        loop {
            loop {
                ((*(((&__local_end[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8)) = ((((__local_comsize_1 as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            loop {
                ((*((((&__local_end[0] as *mut c_char) + ((20 as isize) as usize)) as *mut u8) + ((1 as isize) as usize))) = ((((((__local_comsize_1 as i32) >> (8 as u32)) as i32) & (255 as i32)) as u8)))

                if not (false) {
                    break
                }
            }

            if not (false) {
                break
            }
        }

        if (fwrite((&__local_end[0] as *mut c_char), (1 as u64), (22 as u64), __local_fpOutCD) == 22) {
            if (__local_comsize_1 > 0) {
                if (((fwrite((__local_comment_1 as *const c_void), (1 as u64), (__local_comsize_1 as u64), __local_fpOutCD) as i32)) != __local_comsize_1) {
                    (__local_err = ((-1 as i32)))

                }

            }

        } else {
            (__local_err = ((-1 as i32)))

        }


        fclose(__local_fpOutCD)

        if (__local_err == 0) {
            (__local_fpOutCD = fopen(__param_fileOutTmp, c"rb".ptr))

            if (__local_fpOutCD != null) {
                var __local_nRead: i32

                var __local_buffer: List[c_char] = [0; 8192]

                while true {
                    (__local_nRead = ((fread((&__local_buffer[0] as *mut c_char), (1 as u64), ((8192 * (sizeof[c_char]() as usize)) as u64), __local_fpOutCD) as i32)))

                    if (not (__local_nRead > 0)) {
                        break
                    }

                    if (((fwrite((&__local_buffer[0] as *mut c_char), (1 as u64), (__local_nRead as u64), __local_fpOut) as i32)) != __local_nRead) {
                        (__local_err = ((-1 as i32)))

                        break

                    }

                }

                fclose(__local_fpOutCD)

            }

        }

        fclose(__local_fpZip)

        fclose(__local_fpOut)

        remove(__param_fileOutTmp)

        if (__local_err == 0) {
            if (__param_nRecovered != null) {
                ((*__param_nRecovered) = ((__local_entries as u64)))

            }

            if (__param_bytesRecovered != null) {
                ((*__param_bytesRecovered) = __local_totalBytes)

            }

        }

    } else {
        if (__local_fpOutCD != null) {
            fclose(__local_fpOutCD)
        }

        if (__local_fpZip != null) {
            fclose(__local_fpZip)
        }

        if (__local_fpOut != null) {
            fclose(__local_fpOut)
        }

        (__local_err = ((-2 as i32)))

    }


    return __local_err

}
