// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzwrite
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32
use std.libc

pub unsafe fn gzdopen(__param_fd: c_int, __param_mode: *const i8) -> *mut gzFile_s {
    var __local_path: *mut c_char

    var __local_gz: *mut gzFile_s

    var __ci_expr_logic_0: c_int

    if ((if __param_fd == -1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__local_path = (((with_alloc(((((7 as c_ulong) +% (((3 as c_ulong) *% (sizeof[c_int]() as c_ulong)) as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut c_char)))

        (__ci_expr_logic_0 = (if (if __local_path == null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return null
    }


    snprintf(__local_path, (((7 as c_ulong) +% (((3 as c_ulong) *% (sizeof[c_int]() as c_ulong)) as c_ulong)) as c_ulong), c"<fd:%d>".ptr, __param_fd)

    (__local_gz = gz_open((__local_path as *const c_void), __param_fd, __param_mode))

    with_free(((__local_path as *mut c_void) as *mut i8))

    return __local_gz

}

pub unsafe fn gzbuffer(__param_file: *mut gzFile_s, __param_size: c_uint) -> c_int {
    var __local_size = __param_size
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    if ((if __local_state.size != 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if ((__local_size as c_uint) << (1 as c_uint)) < __local_size: 1 else: 0) != 0) {
        return -1
    }

    if ((if __local_size < 8: 1 else: 0) != 0) {
        (__local_size = ((8 as c_uint)))
    }

    (__local_state.want = __local_size)

    return 0

}

pub unsafe fn gzrewind(__param_file: *mut gzFile_s) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    if ((if lseek(__local_state.fd, __local_state.start, (0 as c_int)) == -1: 1 else: 0) != 0) {
        return -1
    }

    gz_reset(__local_state)

    return 0

}

pub unsafe fn gzeof(__param_file: *mut gzFile_s) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0
    }


    var __ci_expr_ternary_1: c_int = 0

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = __local_state.past)
    } else {
        (__ci_expr_ternary_1 = ((0 as c_int)))
    }

    return __ci_expr_ternary_1


}

pub unsafe fn gzerror(__param_file: *mut gzFile_s, __param_errnum: *mut c_int) -> *const i8 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return null
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return null
    }


    if ((if __param_errnum != null: 1 else: 0) != 0) {
        ((unsafe *__param_errnum) = __local_state.err)
    }

    var __ci_expr_ternary_2: *mut c_char = null

    if ((if __local_state.err == -4: 1 else: 0) != 0) {
        (__ci_expr_ternary_2 = (("out of memory" as *mut c_char)))
    } else {
        var __ci_expr_ternary_1: *mut c_char = null

        if ((if __local_state.msg == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = (("" as *mut c_char)))
        } else {
            (__ci_expr_ternary_1 = ((__local_state.msg as *mut c_char)))
        }

        (__ci_expr_ternary_2 = ((__ci_expr_ternary_1 as *mut c_char)))

    }

    return __ci_expr_ternary_2


}

pub unsafe fn gzclearerr(__param_file: *mut gzFile_s) -> Unit {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return
    }


    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__local_state.eof = ((0 as c_int)))

        (__local_state.past = ((0 as c_int)))

    }

    gz_error(__local_state, (0 as c_int), (null as *const i8))

}

pub unsafe fn gzopen(__param_path: *const i8, __param_mode: *const i8) -> *mut gzFile_s {
    return gz_open((__param_path as *const c_void), (-1 as c_int), __param_mode)

}

pub unsafe fn gzseek(__param_file: *mut gzFile_s, __param_offset: c_longlong, __param_whence: c_int) -> c_longlong {
    var __local_ret: c_longlong

    (__local_ret = ((gzseek64(__param_file, __param_offset, __param_whence) as c_longlong)))

    var __ci_expr_ternary_0: c_longlong = 0

    if ((if __local_ret == __local_ret: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = __local_ret)
    } else {
        (__ci_expr_ternary_0 = ((-1 as c_longlong)))
    }

    return __ci_expr_ternary_0


}

pub unsafe fn gztell(__param_file: *mut gzFile_s) -> c_longlong {
    var __local_ret: c_longlong

    (__local_ret = ((gztell64(__param_file) as c_longlong)))

    var __ci_expr_ternary_0: c_longlong = 0

    if ((if __local_ret == __local_ret: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = __local_ret)
    } else {
        (__ci_expr_ternary_0 = ((-1 as c_longlong)))
    }

    return __ci_expr_ternary_0


}

pub unsafe fn gzoffset(__param_file: *mut gzFile_s) -> c_longlong {
    var __local_ret: c_longlong

    (__local_ret = ((gzoffset64(__param_file) as c_longlong)))

    var __ci_expr_ternary_0: c_longlong = 0

    if ((if __local_ret == __local_ret: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = __local_ret)
    } else {
        (__ci_expr_ternary_0 = ((-1 as c_longlong)))
    }

    return __ci_expr_ternary_0


}

pub unsafe fn gzopen64(__param_path: *const i8, __param_mode: *const i8) -> *mut gzFile_s {
    return gz_open((__param_path as *const c_void), (-1 as c_int), __param_mode)

}

pub unsafe fn gzseek64(__param_file: *mut gzFile_s, __param_offset: c_longlong, __param_whence: c_int) -> c_longlong {
    var __local_offset = __param_offset
    var __local_n: c_uint

    var __local_ret: c_longlong

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    var __ci_expr_logic_1: c_int = 0

    if ((if __local_state.err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    var __ci_expr_logic_2: c_int = 0

    if ((if __param_whence != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __param_whence != 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -1
    }


    if ((if __param_whence == 0: 1 else: 0) != 0) {
        (__local_offset = __local_offset - (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos)
    } else {
        var __ci_expr_ternary_3: c_longlong = 0

        if (__local_state.past != 0) {
            (__ci_expr_ternary_3 = ((0 as c_longlong)))
        } else {
            (__ci_expr_ternary_3 = __local_state.skip)
        }

        (__local_offset = __local_offset + __ci_expr_ternary_3)


        (__local_state.skip = ((0 as c_longlong)))

    }

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_4 = (if (if __local_state.how == 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_logic_5 = (if (if ((unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __local_offset) >= 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__local_ret = ((lseek(__local_state.fd, ((__local_offset - ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have as c_longlong)) as c_longlong), (1 as c_int)) as c_longlong)))

        if ((if __local_ret == -1: 1 else: 0) != 0) {
            return -1
        }

        (__local_state.x.have = ((0 as c_uint)))

        (__local_state.eof = ((0 as c_int)))

        (__local_state.past = ((0 as c_int)))

        (__local_state.skip = ((0 as c_longlong)))

        gz_error(__local_state, (0 as c_int), (null as *const i8))

        (__local_state.strm.avail_in = ((0 as c_uint)))

        (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __local_offset)

        return (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos

    }


    if ((if __local_offset < 0: 1 else: 0) != 0) {
        if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
            return -1
        }

        (__local_offset = __local_offset + (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos)

        if ((if __local_offset < 0: 1 else: 0) != 0) {
            return -1
        }

        if ((if gzrewind(__param_file) == -1: 1 else: 0) != 0) {
            return -1
        }

    }

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        var __ci_expr_ternary_8: c_uint = 0

        var __ci_expr_logic_7: c_int

        var __ci_expr_logic_6: c_int = 0

        if ((if 4 == sizeof[c_longlong](): 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have > gz_intmax(): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_logic_7 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_7 = (if (if (((unsafe *(&raw const __local_state.x as *const gzFile_s)).have as c_longlong)) > __local_offset: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_ternary_8 = ((__local_offset as c_uint)))
        } else {
            (__ci_expr_ternary_8 = (unsafe *(&raw const __local_state.x as *const gzFile_s)).have)
        }

        (__local_n = __ci_expr_ternary_8)


        (__local_state.x.have = ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have -% __local_n))

        (__local_state.x.next = (unsafe *(&raw const __local_state.x as *const gzFile_s)).next + (__local_n as usize))

        (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __local_n)

        (__local_offset = __local_offset - __local_n)

    }

    (__local_state.skip = __local_offset)

    return ((unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __local_offset)

}

pub unsafe fn gztell64(__param_file: *mut gzFile_s) -> c_longlong {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    var __ci_expr_ternary_1: c_longlong = 0

    if (__local_state.past != 0) {
        (__ci_expr_ternary_1 = ((0 as c_longlong)))
    } else {
        (__ci_expr_ternary_1 = __local_state.skip)
    }

    return ((unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __ci_expr_ternary_1)


}

pub unsafe fn gzoffset64(__param_file: *mut gzFile_s) -> c_longlong {
    var __local_offset: c_longlong

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    (__local_offset = ((lseek(__local_state.fd, (0 as c_longlong), (1 as c_int)) as c_longlong)))

    if ((if __local_offset == -1: 1 else: 0) != 0) {
        return -1
    }

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__local_offset = __local_offset - (unsafe *(&raw const __local_state.strm as *const z_stream_s)).avail_in)
    }

    return __local_offset

}

pub unsafe fn gz_error(__param_state: *mut gz_state, __param_err: c_int, __param_msg: *const i8) -> Unit {
    if ((if (unsafe *__param_state).msg != null: 1 else: 0) != 0) {
        if ((if (unsafe *__param_state).err != -4: 1 else: 0) != 0) {
            with_free((((unsafe *__param_state).msg as *mut c_void) as *mut i8))
        }

        ((unsafe *__param_state).msg = ((null as *mut c_char)))

    }

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not ((unsafe *__param_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((unsafe *__param_state).x.have = ((0 as c_uint)))
    }


    ((unsafe *__param_state).err = __param_err)

    if ((if __param_msg == null: 1 else: 0) != 0) {
        return
    }

    if ((if __param_err == -4: 1 else: 0) != 0) {
        return
    }

    ((unsafe *__param_state).msg = (((with_alloc(((((((strlen(((unsafe *__param_state).path as *const i8)) as c_ulong) +% (strlen(__param_msg) as c_ulong)) as c_ulong) +% (3 as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut c_char)))

    if ((if (unsafe *__param_state).msg == null: 1 else: 0) != 0) {
        ((unsafe *__param_state).err = ((-4 as c_int)))

        return

    }


    snprintf((unsafe *__param_state).msg, (((((strlen(((unsafe *__param_state).path as *const i8)) as c_ulong) +% (strlen(__param_msg) as c_ulong)) as c_ulong) +% (3 as c_ulong)) as c_ulong), c"%s%s%s".ptr, (unsafe *__param_state).path, ": ", __param_msg)

}

pub fn gz_intmax() -> c_uint {
    return 2147483647

}

unsafe fn gz_reset(__param_state: *mut gz_state) -> Unit {
    ((unsafe *__param_state).x.have = ((0 as c_uint)))

    if ((if (unsafe *__param_state).mode == 7247: 1 else: 0) != 0) {
        ((unsafe *__param_state).eof = ((0 as c_int)))

        ((unsafe *__param_state).past = ((0 as c_int)))

        ((unsafe *__param_state).how = ((0 as c_int)))

        ((unsafe *__param_state).junk = ((-1 as c_int)))

    } else {
        ((unsafe *__param_state).reset = ((0 as c_int)))
    }

    ((unsafe *__param_state).again = ((0 as c_int)))

    ((unsafe *__param_state).skip = ((0 as c_longlong)))

    gz_error(__param_state, (0 as c_int), (null as *const i8))

    ((unsafe *__param_state).x.pos = ((0 as c_longlong)))

    ((unsafe *__param_state).strm.avail_in = ((0 as c_uint)))

}

unsafe fn gz_open(__param_path: *const c_void, __param_fd: c_int, __param_mode: *const i8) -> *mut gzFile_s {
    var __local_mode = __param_mode
    var __local_state: *mut gz_state

    var __local_len: c_ulong

    var __local_oflag: c_int = ((0 as c_int))

    var __local_exclusive: c_int = ((0 as c_int))

    var __ci_expr_logic_0: c_int

    if ((if __param_path == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_mode == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return null
    }


    (__local_state = (((with_alloc(((sizeof[gz_state]() as c_ulong) as i64)) as *mut c_void) as *mut gz_state)))

    if ((if __local_state == null: 1 else: 0) != 0) {
        return null
    }

    (__local_state.size = ((0 as c_uint)))

    (__local_state.want = ((8192 as c_uint)))

    (__local_state.err = ((0 as c_int)))

    (__local_state.msg = ((null as *mut c_char)))

    (__local_state.mode = ((0 as c_int)))

    (__local_state.level = ((-1 as c_int)))

    (__local_state.strategy = ((0 as c_int)))

    (__local_state.direct = ((0 as c_int)))

    while ((unsafe *__local_mode) != 0) {
        var __ci_expr_logic_1: c_int = 0

        if ((if (unsafe *__local_mode) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe *__local_mode) <= 57: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_state.level = (((((unsafe *__local_mode) as c_int) - 48) as c_int)))
        } else {
            while true {
                match (unsafe *__local_mode) {
                    114 => {
                        (__local_state.mode = ((7247 as c_int)))
                    },
                    119 => {
                        (__local_state.mode = ((31153 as c_int)))
                    },
                    97 => {
                        (__local_state.mode = ((1 as c_int)))
                    },
                    43 => {
                        with_free(((__local_state as *mut c_void) as *mut i8))

                        return null

                    },
                    98 => {
                        0
                    },
                    101 => {
                        (__local_oflag = (__local_oflag as c_int) | (16777216 as c_int))
                    },
                    120 => {
                        (__local_exclusive = ((1 as c_int)))
                    },
                    102 => {
                        (__local_state.strategy = ((1 as c_int)))
                    },
                    104 => {
                        (__local_state.strategy = ((2 as c_int)))
                    },
                    82 => {
                        (__local_state.strategy = ((3 as c_int)))
                    },
                    70 => {
                        (__local_state.strategy = ((4 as c_int)))
                    },
                    71 => {
                        (__local_state.direct = ((-1 as c_int)))
                    },
                    78 => {
                        (__local_oflag = (__local_oflag as c_int) | (4 as c_int))
                    },
                    84 => {
                        (__local_state.direct = ((1 as c_int)))
                    },
                }

                break

            }
        }


        (__local_mode = __local_mode + 1)

    }

    if ((if __local_state.mode == 0: 1 else: 0) != 0) {
        with_free(((__local_state as *mut c_void) as *mut i8))

        return null

    }

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        if ((if __local_state.direct == 1: 1 else: 0) != 0) {
            with_free(((__local_state as *mut c_void) as *mut i8))

            return null

        }

        if ((if __local_state.direct == 0: 1 else: 0) != 0) {
            (__local_state.direct = ((1 as c_int)))
        }

    } else {
        if ((if __local_state.direct == -1: 1 else: 0) != 0) {
            with_free(((__local_state as *mut c_void) as *mut i8))

            return null

        }
    }

    (__local_len = ((strlen((__param_path as *const c_char)) as c_ulong)))

    (__local_state.path = (((with_alloc(((((__local_len as c_ulong) +% (1 as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut c_char)))

    if ((if __local_state.path == null: 1 else: 0) != 0) {
        with_free(((__local_state as *mut c_void) as *mut i8))

        return null

    }

    snprintf(__local_state.path, (((__local_len as c_ulong) +% (1 as c_ulong)) as c_ulong), c"%s".ptr, (__param_path as *const c_char))


    var __ci_expr_ternary_5: c_int = 0

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_ternary_5 = ((0 as c_int)))
    } else {
        var __ci_expr_ternary_3: c_int = 0

        if (__local_exclusive != 0) {
            (__ci_expr_ternary_3 = ((2048 as c_int)))
        } else {
            (__ci_expr_ternary_3 = ((0 as c_int)))
        }

        var __ci_expr_ternary_4: c_int = 0

        if ((if __local_state.mode == 31153: 1 else: 0) != 0) {
            (__ci_expr_ternary_4 = ((1024 as c_int)))
        } else {
            (__ci_expr_ternary_4 = ((8 as c_int)))
        }

        (__ci_expr_ternary_5 = ((((((((1 as c_int) | (512 as c_int)) as c_int) | (__ci_expr_ternary_3 as c_int)) as c_int) | (__ci_expr_ternary_4 as c_int)) as c_int)))

    }

    (__local_oflag = (__local_oflag as c_int) | (__ci_expr_ternary_5 as c_int))


    if ((if __param_fd == -1: 1 else: 0) != 0) {
        (__local_state.fd = ((open((__param_path as *const c_char), __local_oflag, 438) as c_int)))
    } else {
        if (((__local_oflag as c_int) & (4 as c_int)) != 0) {
            fcntl(__param_fd, (4 as c_int), ((fcntl(__param_fd, (3 as c_int)) as c_int) | (4 as c_int)))
        }

        if (((__local_oflag as c_int) & (16777216 as c_int)) != 0) {
            fcntl(__param_fd, (2 as c_int), ((fcntl(__param_fd, (1 as c_int)) as c_int) | (16777216 as c_int)))
        }

        (__local_state.fd = __param_fd)

    }

    if ((if __local_state.fd == -1: 1 else: 0) != 0) {
        with_free(((__local_state.path as *mut c_void) as *mut i8))

        with_free(((__local_state as *mut c_void) as *mut i8))

        return null

    }

    if ((if __local_state.mode == 1: 1 else: 0) != 0) {
        lseek(__local_state.fd, (0 as c_longlong), (2 as c_int))

        (__local_state.mode = ((31153 as c_int)))

    }

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__local_state.start = ((lseek(__local_state.fd, (0 as c_longlong), (1 as c_int)) as c_longlong)))

        if ((if __local_state.start == -1: 1 else: 0) != 0) {
            (__local_state.start = ((0 as c_longlong)))
        }

    }

    gz_reset(__local_state)

    return ((__local_state as *mut gzFile_s))

}
