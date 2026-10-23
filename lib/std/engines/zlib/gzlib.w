// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
use std.engines.zlib.deflate
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.compress
use std.engines.zlib.uncompr
use std.engines.zlib.gzwrite
use std.engines.zlib.gzread
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32
use std.libc

pub unsafe fn gzdopen(__param_fd: i32, __param_mode: *const c_char) -> *mut gzFile_s {
    var __local_path: *mut c_char

    var __local_gz: *mut gzFile_s

    var __ci_expr_logic_0: i32

    if ((if __param_fd == -1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__local_path = (((with_alloc(((((7 as u64) +% (((3 as u64) *% (sizeof[i32]() as u64)) as u64)) as u64) as i64)) as *mut c_void) as *mut c_char)))

        (__ci_expr_logic_0 = (if (if __local_path == null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((null as *mut gzFile_s))
    }


    snprintf(__local_path, (((7 as u64) +% (((3 as u64) *% (sizeof[i32]() as u64)) as u64)) as u64), c"<fd:%d>".ptr, __param_fd)

    (__local_gz = gz_open((__local_path as *const c_void), __param_fd, __param_mode))

    with_free(((__local_path as *mut c_void) as *mut u8))

    return __local_gz

}

pub unsafe fn gzbuffer(__param_file: *mut gzFile_s, __param_size: u32) -> i32 {
    var __local_size = __param_size
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    if ((if (*__local_state).size != 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if ((__local_size as u32) << (1 as u32)) < __local_size: 1 else: 0) != 0) {
        return -1
    }

    if ((if __local_size < 8: 1 else: 0) != 0) {
        (__local_size = ((8 as u32)))
    }

    ((*__local_state).want = __local_size)

    return 0

}

pub unsafe fn gzrewind(__param_file: *mut gzFile_s) -> i32 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    if ((if lseek((*__local_state).fd, (*__local_state).start, (libc.SEEK_SET as i32)) == -1: 1 else: 0) != 0) {
        return -1
    }

    gz_reset(__local_state)

    return 0

}

pub unsafe fn gzeof(__param_file: *mut gzFile_s) -> i32 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0
    }


    return (if (if (*__local_state).mode == 7247: 1 else: 0) != 0: (*__local_state).past else: (0 as i32))

}

pub unsafe fn gzerror(__param_file: *mut gzFile_s, __param_errnum: *mut i32) -> *const c_char {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((null as *const c_char))
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((null as *const c_char))
    }


    if ((if __param_errnum != null: 1 else: 0) != 0) {
        ((*__param_errnum) = (*__local_state).err)
    }

    return (((if (if (*__local_state).err == -4: 1 else: 0) != 0: ("out of memory" as *mut c_char) else: (if (if (*__local_state).msg == null: 1 else: 0) != 0: ("" as *mut c_char) else: (*__local_state).msg)) as *const c_char))

}

pub unsafe fn gzclearerr(__param_file: *mut gzFile_s) {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return
    }


    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        ((*__local_state).eof = ((0 as i32)))

        ((*__local_state).past = ((0 as i32)))

    }

    gz_error(__local_state, (0 as i32), (null as *const c_char))

}

pub unsafe fn gzopen(__param_path: *const c_char, __param_mode: *const c_char) -> *mut gzFile_s {
    return ((gz_open((__param_path as *const c_void), (-1 as i32), __param_mode) as *mut gzFile_s))

}

pub unsafe fn gzseek(__param_file: *mut gzFile_s, __param_offset: i64, __param_whence: i32) -> i64 {
    var __local_ret: i64

    (__local_ret = ((gzseek64(__param_file, __param_offset, __param_whence) as i64)))

    return (if (if __local_ret == __local_ret: 1 else: 0) != 0: __local_ret else: (-1 as i64))

}

pub unsafe fn gztell(__param_file: *mut gzFile_s) -> i64 {
    var __local_ret: i64

    (__local_ret = ((gztell64(__param_file) as i64)))

    return (if (if __local_ret == __local_ret: 1 else: 0) != 0: __local_ret else: (-1 as i64))

}

pub unsafe fn gzoffset(__param_file: *mut gzFile_s) -> i64 {
    var __local_ret: i64

    (__local_ret = ((gzoffset64(__param_file) as i64)))

    return (if (if __local_ret == __local_ret: 1 else: 0) != 0: __local_ret else: (-1 as i64))

}

pub unsafe fn gzopen64(__param_path: *const c_char, __param_mode: *const c_char) -> *mut gzFile_s {
    return ((gz_open((__param_path as *const c_void), (-1 as i32), __param_mode) as *mut gzFile_s))

}

pub unsafe fn gzseek64(__param_file: *mut gzFile_s, __param_offset: i64, __param_whence: i32) -> i64 {
    var __local_offset = __param_offset
    var __local_n: u32

    var __local_ret: i64

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((-1 as i64))
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((-1 as i64))
    }


    var __ci_expr_logic_1: i32 = 0

    if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((-1 as i64))
    }


    var __ci_expr_logic_2: i32 = 0

    if ((if __param_whence != libc.SEEK_SET: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __param_whence != libc.SEEK_CUR: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return ((-1 as i64))
    }


    if ((if __param_whence == libc.SEEK_SET: 1 else: 0) != 0) {
        (__local_offset = __local_offset - (*(&raw const (*__local_state).x as *const gzFile_s)).pos)
    } else {
        (__local_offset = __local_offset + (if (*__local_state).past != 0: (0 as i64) else: (*__local_state).skip))

        ((*__local_state).skip = ((0 as i64)))

    }

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if (if (*__local_state).how == 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if (if ((*(&raw const (*__local_state).x as *const gzFile_s)).pos + __local_offset) >= 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__local_ret = ((lseek((*__local_state).fd, ((__local_offset - ((*(&raw const (*__local_state).x as *const gzFile_s)).have as i64)) as i64), (libc.SEEK_CUR as i32)) as i64)))

        if ((if __local_ret == -1: 1 else: 0) != 0) {
            return ((-1 as i64))
        }

        ((*__local_state).x.have = ((0 as u32)))

        ((*__local_state).eof = ((0 as i32)))

        ((*__local_state).past = ((0 as i32)))

        ((*__local_state).skip = ((0 as i64)))

        gz_error(__local_state, (0 as i32), (null as *const c_char))

        ((*__local_state).strm.avail_in = ((0 as u32)))

        ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos + __local_offset)

        return (*(&raw const (*__local_state).x as *const gzFile_s)).pos

    }


    if ((if __local_offset < 0: 1 else: 0) != 0) {
        if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
            return ((-1 as i64))
        }

        (__local_offset = __local_offset + (*(&raw const (*__local_state).x as *const gzFile_s)).pos)

        if ((if __local_offset < 0: 1 else: 0) != 0) {
            return ((-1 as i64))
        }

        if ((if gzrewind(__param_file) == -1: 1 else: 0) != 0) {
            return ((-1 as i64))
        }

    }

    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        var __ci_expr_ternary_7: u32 = 0

        var __ci_expr_logic_6: i32

        var __ci_expr_logic_5: i32 = 0

        if ((if 4 == (sizeof[i64]() as usize): 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if (*(&raw const (*__local_state).x as *const gzFile_s)).have > gz_intmax(): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if (((*(&raw const (*__local_state).x as *const gzFile_s)).have as i64)) > __local_offset: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_ternary_7 = ((__local_offset as u32)))
        } else {
            (__ci_expr_ternary_7 = (*(&raw const (*__local_state).x as *const gzFile_s)).have)
        }

        (__local_n = __ci_expr_ternary_7)


        ((*__local_state).x.have = ((*(&raw const (*__local_state).x as *const gzFile_s)).have -% __local_n))

        ((*__local_state).x.next = (*(&raw const (*__local_state).x as *const gzFile_s)).next + (__local_n as usize))

        ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos + __local_n)

        (__local_offset = __local_offset - __local_n)

    }

    ((*__local_state).skip = __local_offset)

    return ((*(&raw const (*__local_state).x as *const gzFile_s)).pos + __local_offset)

}

pub unsafe fn gztell64(__param_file: *mut gzFile_s) -> i64 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((-1 as i64))
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((-1 as i64))
    }


    return ((*(&raw const (*__local_state).x as *const gzFile_s)).pos + (if (*__local_state).past != 0: (0 as i64) else: (*__local_state).skip))

}

pub unsafe fn gzoffset64(__param_file: *mut gzFile_s) -> i64 {
    var __local_offset: i64

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((-1 as i64))
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).mode != 31153: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((-1 as i64))
    }


    (__local_offset = ((lseek((*__local_state).fd, (0 as i64), (libc.SEEK_CUR as i32)) as i64)))

    if ((if __local_offset == -1: 1 else: 0) != 0) {
        return ((-1 as i64))
    }

    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        (__local_offset = __local_offset - (*(&raw const (*__local_state).strm as *const z_stream_s)).avail_in)
    }

    return __local_offset

}

pub unsafe fn gz_error(__param_state: *mut gz_state, __param_err: i32, __param_msg: *const c_char) -> Unit {
    if ((if (*__param_state).msg != null: 1 else: 0) != 0) {
        if ((if (*__param_state).err != -4: 1 else: 0) != 0) {
            with_free((((*__param_state).msg as *mut c_void) as *mut u8))
        }

        ((*__param_state).msg = ((null as *mut c_char)))

    }

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if ((if __param_err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not ((*__param_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((*__param_state).x.have = ((0 as u32)))
    }


    ((*__param_state).err = __param_err)

    if ((if __param_msg == null: 1 else: 0) != 0) {
        return
    }

    if ((if __param_err == -4: 1 else: 0) != 0) {
        return
    }

    ((*__param_state).msg = (((with_alloc(((((((strlen(((*__param_state).path as *const c_char)) as u64) +% (strlen(__param_msg) as u64)) as u64) +% (3 as u64)) as u64) as i64)) as *mut c_void) as *mut c_char)))

    if ((if (*__param_state).msg == null: 1 else: 0) != 0) {
        ((*__param_state).err = ((-4 as i32)))

        return

    }


    snprintf((*__param_state).msg, (((((strlen(((*__param_state).path as *const c_char)) as u64) +% (strlen(__param_msg) as u64)) as u64) +% (3 as u64)) as u64), c"%s%s%s".ptr, (*__param_state).path, c": ".ptr, __param_msg)

}

pub fn gz_intmax() -> u32 {
    return ((2147483647 as u32))

}

unsafe fn gz_reset(__param_state: *mut gz_state) {
    ((*__param_state).x.have = ((0 as u32)))

    if ((if (*__param_state).mode == 7247: 1 else: 0) != 0) {
        ((*__param_state).eof = ((0 as i32)))

        ((*__param_state).past = ((0 as i32)))

        ((*__param_state).how = ((0 as i32)))

        ((*__param_state).junk = ((-1 as i32)))

    } else {
        ((*__param_state).reset = ((0 as i32)))
    }

    ((*__param_state).again = ((0 as i32)))

    ((*__param_state).skip = ((0 as i64)))

    gz_error(__param_state, (0 as i32), (null as *const c_char))

    ((*__param_state).x.pos = ((0 as i64)))

    ((*__param_state).strm.avail_in = ((0 as u32)))

}

unsafe fn gz_open(__param_path: *const c_void, __param_fd: i32, __param_mode: *const c_char) -> *mut gzFile_s {
    var __local_mode = __param_mode
    var __local_state: *mut gz_state

    var __local_len: u64

    var __local_oflag: i32 = ((0 as i32))

    var __local_exclusive: i32 = ((0 as i32))

    var __ci_expr_logic_0: i32

    if ((if __param_path == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_mode == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((null as *mut gzFile_s))
    }


    (__local_state = (((with_alloc(((sizeof[gz_state]() as u64) as i64)) as *mut c_void) as *mut gz_state)))

    if ((if __local_state == null: 1 else: 0) != 0) {
        return ((null as *mut gzFile_s))
    }

    ((*__local_state).size = ((0 as u32)))

    ((*__local_state).want = ((8192 as u32)))

    ((*__local_state).err = ((0 as i32)))

    ((*__local_state).msg = ((null as *mut c_char)))

    ((*__local_state).mode = ((0 as i32)))

    ((*__local_state).level = ((-1 as i32)))

    ((*__local_state).strategy = ((0 as i32)))

    ((*__local_state).direct = ((0 as i32)))

    while ((*__local_mode) != 0) {
        var __ci_expr_logic_1: i32 = 0

        if ((if (*__local_mode) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__local_mode) <= 57: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            ((*__local_state).level = ((((*__local_mode) - 48) as i32)))
        } else {
            while true {
                match (*__local_mode) {
                    114 => {
                        ((*__local_state).mode = ((7247 as i32)))
                    },
                    119 => {
                        ((*__local_state).mode = ((31153 as i32)))
                    },
                    97 => {
                        ((*__local_state).mode = ((1 as i32)))
                    },
                    43 => {
                        with_free(((__local_state as *mut c_void) as *mut u8))

                        return ((null as *mut gzFile_s))

                    },
                    98 => {
                        0
                    },
                    101 => {
                        (__local_oflag = (__local_oflag as i32) | (libc.O_CLOEXEC as i32))
                    },
                    120 => {
                        (__local_exclusive = ((1 as i32)))
                    },
                    102 => {
                        ((*__local_state).strategy = ((1 as i32)))
                    },
                    104 => {
                        ((*__local_state).strategy = ((2 as i32)))
                    },
                    82 => {
                        ((*__local_state).strategy = ((3 as i32)))
                    },
                    70 => {
                        ((*__local_state).strategy = ((4 as i32)))
                    },
                    71 => {
                        ((*__local_state).direct = ((-1 as i32)))
                    },
                    78 => {
                        (__local_oflag = (__local_oflag as i32) | (libc.O_NONBLOCK as i32))
                    },
                    84 => {
                        ((*__local_state).direct = ((1 as i32)))
                    },
                }

                break

            }
        }


        (__local_mode = __local_mode + 1)

    }

    if ((if (*__local_state).mode == 0: 1 else: 0) != 0) {
        with_free(((__local_state as *mut c_void) as *mut u8))

        return ((null as *mut gzFile_s))

    }

    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        if ((if (*__local_state).direct == 1: 1 else: 0) != 0) {
            with_free(((__local_state as *mut c_void) as *mut u8))

            return ((null as *mut gzFile_s))

        }

        if ((if (*__local_state).direct == 0: 1 else: 0) != 0) {
            ((*__local_state).direct = ((1 as i32)))
        }

    } else {
        if ((if (*__local_state).direct == -1: 1 else: 0) != 0) {
            with_free(((__local_state as *mut c_void) as *mut u8))

            return ((null as *mut gzFile_s))

        }
    }

    (__local_len = ((strlen((__param_path as *const c_char)) as u64)))

    ((*__local_state).path = (((with_alloc(((((__local_len as u64) +% (1 as u64)) as u64) as i64)) as *mut c_void) as *mut c_char)))

    if ((if (*__local_state).path == null: 1 else: 0) != 0) {
        with_free(((__local_state as *mut c_void) as *mut u8))

        return ((null as *mut gzFile_s))

    }

    snprintf((*__local_state).path, (((__local_len as u64) +% (1 as u64)) as u64), c"%s".ptr, (__param_path as *const c_char))


    (__local_oflag = (__local_oflag as i32) | ((if (if (*__local_state).mode == 7247: 1 else: 0) != 0: (libc.O_RDONLY as i32) else: (((((((libc.O_WRONLY as i32) | (libc.O_CREAT as i32)) as i32) | ((if __local_exclusive != 0: (libc.O_EXCL as i32) else: (0 as i32)) as i32)) as i32) | ((if (if (*__local_state).mode == 31153: 1 else: 0) != 0: (libc.O_TRUNC as i32) else: (libc.O_APPEND as i32)) as i32)) as i32)) as i32))

    if ((if __param_fd == -1: 1 else: 0) != 0) {
        ((*__local_state).fd = ((open((__param_path as *const c_char), __local_oflag, 438) as i32)))
    } else {
        if (((__local_oflag as i32) & (libc.O_NONBLOCK as i32)) != 0) {
            fcntl(__param_fd, (libc.F_SETFL as i32), ((fcntl(__param_fd, (libc.F_GETFL as i32)) as i32) | (libc.O_NONBLOCK as i32)))
        }

        if (((__local_oflag as i32) & (libc.O_CLOEXEC as i32)) != 0) {
            fcntl(__param_fd, (libc.F_SETFD as i32), ((fcntl(__param_fd, (libc.F_GETFD as i32)) as i32) | (libc.O_CLOEXEC as i32)))
        }

        ((*__local_state).fd = __param_fd)

    }

    if ((if (*__local_state).fd == -1: 1 else: 0) != 0) {
        with_free((((*__local_state).path as *mut c_void) as *mut u8))

        with_free(((__local_state as *mut c_void) as *mut u8))

        return ((null as *mut gzFile_s))

    }

    if ((if (*__local_state).mode == 1: 1 else: 0) != 0) {
        lseek((*__local_state).fd, (0 as i64), (libc.SEEK_END as i32))

        ((*__local_state).mode = ((31153 as i32)))

    }

    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        ((*__local_state).start = ((lseek((*__local_state).fd, (0 as i64), (libc.SEEK_CUR as i32)) as i64)))

        if ((if (*__local_state).start == -1: 1 else: 0) != 0) {
            ((*__local_state).start = ((0 as i64)))
        }

    }

    gz_reset(__local_state)

    return ((__local_state as *mut gzFile_s))

}
