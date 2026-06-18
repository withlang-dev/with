// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32
use std.libc

pub unsafe fn gzsetparams(__param_file: *mut gzFile_s, __param_level: c_int, __param_strategy: c_int) -> c_int {
    var __local_state: *mut gz_state

    var __local_strm: *mut z_stream_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    (__local_strm = (((&raw const __local_state.strm as *const z_stream_s) as *mut z_stream_s)))

    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if __local_state.direct != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -2
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    var __ci_expr_logic_3: c_int = 0

    if ((if __param_level == __local_state.level: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if (if __param_strategy == __local_state.strategy: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return 0
    }


    var __ci_expr_logic_4: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_4 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        return __local_state.err
    }


    if (__local_state.size != 0) {
        var __ci_expr_logic_5: c_int = 0

        if (__local_strm.avail_in != 0) {
            (__ci_expr_logic_5 = (if (if gz_comp(__local_state, (5 as c_int)) == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            return __local_state.err
        }


        deflateParams(__local_strm, __param_level, __param_strategy)

    }

    (__local_state.level = __param_level)

    (__local_state.strategy = __param_strategy)

    return 0

}

pub unsafe fn gzwrite(__param_file: *mut gzFile_s, __param_buf: *const c_void, __param_len: c_uint) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return 0
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    if ((if ((__param_len as c_int)) < 0: 1 else: 0) != 0) {
        gz_error(__local_state, (-3 as c_int), c"requested length does not fit in int".ptr)

        return 0

    }

    return ((gz_write(__local_state, __param_buf, (__param_len as c_ulong)) as c_int))

}

pub unsafe fn gzfwrite(__param_buf: *const c_void, __param_size: c_ulong, __param_nitems: c_ulong, __param_file: *mut gzFile_s) -> c_ulong {
    var __local_len: c_ulong

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return 0
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    (__local_len = ((((__param_nitems as c_ulong) *% (__param_size as c_ulong)) as c_ulong)))

    var __ci_expr_logic_2: c_int = 0

    if (__param_size != 0) {
        (__ci_expr_logic_2 = (if (if ((__local_len as c_ulong) / (__param_size as c_ulong)) != __param_nitems: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        gz_error(__local_state, (-2 as c_int), c"request does not fit in a size_t".ptr)

        return 0

    }


    var __ci_expr_ternary_3: c_ulong = 0

    if (__local_len != 0) {
        (__ci_expr_ternary_3 = ((((gz_write(__local_state, __param_buf, __local_len) as c_ulong) / (__param_size as c_ulong)) as c_ulong)))
    } else {
        (__ci_expr_ternary_3 = ((0 as c_ulong)))
    }

    return __ci_expr_ternary_3


}

pub unsafe fn gzprintf(__param_file: *mut gzFile_s, __param_format: *const i8, ...) -> c_int {
    var __local_va: *mut i8

    var __local_ret: c_int

    with_va_start((&raw mut __local_va as *mut i8))

    (__local_ret = ((gzvprintf(__param_file, __param_format, __local_va) as c_int)))

    with_va_end((&raw mut __local_va as *mut i8))

    return __local_ret

}

pub unsafe fn gzputs(__param_file: *mut gzFile_s, __param_s: *const i8) -> c_int {
    var __local_len: c_ulong

    var __local_put: c_ulong


    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    (__local_len = ((strlen(__param_s) as c_ulong)))

    var __ci_expr_logic_2: c_int

    if ((if ((__local_len as c_int)) < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if ((__local_len as c_uint)) != __local_len: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        gz_error(__local_state, (-2 as c_int), c"string length does not fit in int".ptr)

        return -1

    }


    (__local_put = ((gz_write(__local_state, (__param_s as *const c_void), __local_len) as c_ulong)))

    var __ci_expr_ternary_4: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    if (__local_len != 0) {
        (__ci_expr_logic_3 = (if (if __local_put == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_ternary_4 = ((-1 as c_int)))
    } else {
        (__ci_expr_ternary_4 = ((__local_put as c_int)))
    }

    return __ci_expr_ternary_4


}

pub unsafe fn gzputc(__param_file: *mut gzFile_s, __param_c: c_int) -> c_int {
    var __local_have: c_uint

    var __local_buf: [1]u8

    var __local_state: *mut gz_state

    var __local_strm: *mut z_stream_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    (__local_strm = (((&raw const __local_state.strm as *const z_stream_s) as *mut z_stream_s)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    var __ci_expr_logic_2: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_2 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -1
    }


    if (__local_state.size != 0) {
        if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
            (__local_strm.next_in = __local_state.in_)
        }

        (__local_have = ((((((__local_strm.next_in + (__local_strm.avail_in as usize)) as usize) -% (__local_state.in_ as usize)) / sizeof[u8]()) as c_uint)))

        if ((if __local_have < __local_state.size: 1 else: 0) != 0) {
            ((unsafe __local_state.in_[__local_have]) = ((__param_c as u8)))

            (__local_strm.avail_in = (__local_strm.avail_in +% 1))

            (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + 1)

            return ((__param_c as c_int) & (255 as c_int))

        }

    }

    (__local_buf[0] = ((__param_c as u8)))

    if ((if gz_write(__local_state, (&__local_buf[0] as *mut u8), (1 as c_ulong)) != 1: 1 else: 0) != 0) {
        return -1
    }

    return ((__param_c as c_int) & (255 as c_int))

}

pub unsafe fn gzflush(__param_file: *mut gzFile_s, __param_flush: c_int) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -2
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    var __ci_expr_logic_2: c_int

    if ((if __param_flush < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __param_flush > 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -2
    }


    var __ci_expr_logic_3: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_3 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return __local_state.err
    }


    gz_comp(__local_state, __param_flush)

    return __local_state.err

}

pub unsafe fn gzclose_w(__param_file: *mut gzFile_s) -> c_int {
    var __local_ret: c_int = ((0 as c_int))

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        return -2
    }

    var __ci_expr_logic_0: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_0 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_ret = __local_state.err)
    }


    if ((if gz_comp(__local_state, (4 as c_int)) == -1: 1 else: 0) != 0) {
        (__local_ret = __local_state.err)
    }

    if (__local_state.size != 0) {
        if ((if not (__local_state.direct != 0): 1 else: 0) != 0) {
            deflateEnd(((&raw const __local_state.strm as *const z_stream_s) as *mut z_stream_s))

            with_free(((__local_state.out as *mut c_void) as *mut i8))

        }

        with_free(((__local_state.in_ as *mut c_void) as *mut i8))

    }

    gz_error(__local_state, (0 as c_int), (null as *const i8))

    with_free(((__local_state.path as *mut c_void) as *mut i8))

    if ((if close(__local_state.fd) == -1: 1 else: 0) != 0) {
        (__local_ret = ((-1 as c_int)))
    }

    with_free(((__local_state as *mut c_void) as *mut i8))

    return __local_ret

}

pub unsafe fn gzvprintf(__param_file: *mut gzFile_s, __param_format: *const i8, __param_va: *mut i8) -> c_int {
    var __local_len: c_int

    var __local_ret: c_int


    var __local_next: *mut c_char

    var __local_state: *mut gz_state

    var __local_strm: *mut z_stream_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    (__local_strm = (((&raw const __local_state.strm as *const z_stream_s) as *mut z_stream_s)))

    var __ci_expr_logic_1: c_int

    if ((if __local_state.mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -2
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_state.size == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if gz_init(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return __local_state.err
    }


    var __ci_expr_logic_3: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_3 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return __local_state.err
    }


    (__local_ret = ((gz_vacate(__local_state) as c_int)))

    if (__local_state.err != 0) {
        var __ci_expr_logic_4: c_int = 0

        if (__local_ret != 0) {
            (__ci_expr_logic_4 = (if __local_state.again != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            gz_error(__local_state, (-5 as c_int), c"stalled write on gzprintf".ptr)

        }


        if ((if not (__local_state.again != 0): 1 else: 0) != 0) {
            return __local_state.err
        }

    }

    if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
        (__local_strm.next_in = __local_state.in_)
    }

    (__local_next = ((((__local_state.in_ + (((((__local_strm.next_in as usize) -% (__local_state.in_ as usize)) / sizeof[u8]()) as isize) as usize)) + (__local_strm.avail_in as usize)) as *mut c_char)))

    ((unsafe __local_next[((__local_state.size as c_uint) -% (1 as c_uint))]) = ((0 as c_char)))

    (__local_len = ((vsnprintf(__local_next, (__local_state.size as c_ulong), __param_format, __param_va) as c_int)))

    var __ci_expr_logic_6: c_int

    var __ci_expr_logic_5: c_int

    if ((if __local_len == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_5 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_5 = (if (if ((__local_len as c_uint)) >= __local_state.size: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__ci_expr_logic_6 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_6 = (if (if (unsafe __local_next[((__local_state.size as c_uint) -% (1 as c_uint))]) != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        return 0
    }


    (__local_strm.avail_in = (__local_strm.avail_in +% (__local_len as c_uint)))

    (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __local_len)

    (__local_ret = ((gz_vacate(__local_state) as c_int)))

    var __ci_expr_logic_7: c_int = 0

    if (__local_state.err != 0) {
        (__ci_expr_logic_7 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        return __local_state.err
    }


    return __local_len

}

unsafe fn gz_init(__param_state: *mut gz_state) -> c_int {
    var __local_ret: c_int

    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    ((unsafe *__param_state).in_ = (((with_alloc((((((unsafe *__param_state).want as c_uint) << (1 as c_uint)) as c_ulong) as i64)) as *mut c_void) as *mut u8)))

    if ((if (unsafe *__param_state).in_ == null: 1 else: 0) != 0) {
        gz_error(__param_state, (-4 as c_int), c"out of memory".ptr)

        return -1

    }

    if ((if not ((unsafe *__param_state).direct != 0): 1 else: 0) != 0) {
        ((unsafe *__param_state).out = (((with_alloc((((unsafe *__param_state).want as c_ulong) as i64)) as *mut c_void) as *mut u8)))

        if ((if (unsafe *__param_state).out == null: 1 else: 0) != 0) {
            with_free((((unsafe *__param_state).in_ as *mut c_void) as *mut i8))

            gz_error(__param_state, (-4 as c_int), c"out of memory".ptr)

            return -1

        }

        (__local_strm.zalloc = null)

        (__local_strm.zfree = null)

        (__local_strm.opaque_ = null)

        (__local_ret = ((deflateInit2_(__local_strm, (unsafe *__param_state).level, (8 as c_int), ((15 + 16) as c_int), (8 as c_int), (unsafe *__param_state).strategy, c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

        if ((if __local_ret != 0: 1 else: 0) != 0) {
            with_free((((unsafe *__param_state).out as *mut c_void) as *mut i8))

            with_free((((unsafe *__param_state).in_ as *mut c_void) as *mut i8))

            gz_error(__param_state, (-4 as c_int), c"out of memory".ptr)

            return -1

        }

        (__local_strm.next_in = ((null as *mut u8)))

    }

    ((unsafe *__param_state).size = (unsafe *__param_state).want)

    if ((if not ((unsafe *__param_state).direct != 0): 1 else: 0) != 0) {
        (__local_strm.avail_out = (unsafe *__param_state).size)

        (__local_strm.next_out = (unsafe *__param_state).out)

        ((unsafe *__param_state).x.next = __local_strm.next_out)

    }

    return 0

}

unsafe fn gz_comp(__param_state: *mut gz_state, __param_flush: c_int) -> c_int {
    var __local_ret: c_int

    var __local_writ: c_int


    var __local_have: c_uint

    var __local_put: c_uint

    var __local_max: c_uint = (((((((-1 as c_uint) as c_uint) >> (2 as c_uint)) as c_uint) +% (1 as c_uint)) as c_uint))


    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__param_state).size == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if gz_init(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    if ((unsafe *__param_state).direct != 0) {
        while (__local_strm.avail_in != 0) {
            ((unsafe *(__error())) = ((0 as c_int)))

            ((unsafe *__param_state).again = ((0 as c_int)))

            var __ci_expr_ternary_1: c_uint = 0

            if ((if __local_strm.avail_in > __local_max: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = __local_max)
            } else {
                (__ci_expr_ternary_1 = __local_strm.avail_in)
            }

            (__local_put = __ci_expr_ternary_1)


            (__local_writ = ((write((unsafe *__param_state).fd, (__local_strm.next_in as *const c_void), (__local_put as c_ulong)) as c_int)))

            if ((if __local_writ < 0: 1 else: 0) != 0) {
                var __ci_expr_logic_2: c_int

                if ((if (unsafe *(__error())) == 35: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (if (unsafe *(__error())) == 35: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    ((unsafe *__param_state).again = ((1 as c_int)))
                }


                gz_error(__param_state, (-1 as c_int), (strerror(((unsafe *(__error())) as c_int)) as *const i8))

                return -1

            }

            (__local_strm.avail_in = (__local_strm.avail_in -% (__local_writ as c_uint)))

            (__local_strm.next_in = __local_strm.next_in + ((__local_writ as isize) as usize))

        }

        return 0

    }

    if ((unsafe *__param_state).reset != 0) {
        var __ci_expr_logic_3: c_int = 0

        if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            return 0
        }


        deflateReset(__local_strm)

        ((unsafe *__param_state).reset = ((0 as c_int)))

    }

    (__local_ret = ((0 as c_int)))

    loop {
        var __ci_expr_logic_6: c_int

        if ((if __local_strm.avail_out == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_5: c_int = 0

            if ((if __param_flush != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_4: c_int

                if ((if __param_flush != 4: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_4 = (if (if __local_ret == 1: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

            }

            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_6 != 0) {
            while ((if __local_strm.next_out > (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next: 1 else: 0) != 0) {
                ((unsafe *(__error())) = ((0 as c_int)))

                ((unsafe *__param_state).again = ((0 as c_int)))

                var __ci_expr_ternary_7: c_uint = 0

                if ((if (((__local_strm.next_out as usize) -% ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next as usize)) / sizeof[u8]()) > ((__local_max as c_int)): 1 else: 0) != 0) {
                    (__ci_expr_ternary_7 = __local_max)
                } else {
                    (__ci_expr_ternary_7 = (((((__local_strm.next_out as usize) -% ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next as usize)) / sizeof[u8]()) as c_uint)))
                }

                (__local_put = __ci_expr_ternary_7)


                (__local_writ = ((write((unsafe *__param_state).fd, ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next as *const c_void), (__local_put as c_ulong)) as c_int)))

                if ((if __local_writ < 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_8: c_int

                    if ((if (unsafe *(__error())) == 35: 1 else: 0) != 0) {
                        (__ci_expr_logic_8 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_8 = (if (if (unsafe *(__error())) == 35: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_8 != 0) {
                        ((unsafe *__param_state).again = ((1 as c_int)))
                    }


                    gz_error(__param_state, (-1 as c_int), (strerror(((unsafe *(__error())) as c_int)) as *const i8))

                    return -1

                }

                ((unsafe *__param_state).x.next = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next + ((__local_writ as isize) as usize))

            }

            if ((if __local_strm.avail_out == 0: 1 else: 0) != 0) {
                (__local_strm.avail_out = (unsafe *__param_state).size)

                (__local_strm.next_out = (unsafe *__param_state).out)

                ((unsafe *__param_state).x.next = (unsafe *__param_state).out)

            }

        }


        (__local_have = __local_strm.avail_out)

        (__local_ret = ((deflate(__local_strm, __param_flush) as c_int)))

        if ((if __local_ret == -2: 1 else: 0) != 0) {
            gz_error(__param_state, (-2 as c_int), c"internal error: deflate stream corrupt".ptr)

            return -1

        }

        (__local_have = (__local_have -% __local_strm.avail_out))

        if not ((__local_have != 0)) {
            break
        }
    }

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        ((unsafe *__param_state).reset = ((1 as c_int)))
    }

    return 0

}

unsafe fn gz_zero(__param_state: *mut gz_state) -> c_int {
    var __local_first: c_int

    var __local_ret: c_int


    var __local_n: c_uint

    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    var __ci_expr_logic_0: c_int = 0

    if (__local_strm.avail_in != 0) {
        (__ci_expr_logic_0 = (if (if gz_comp(__param_state, (0 as c_int)) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    (__local_first = ((1 as c_int)))

    loop {
        var __ci_expr_ternary_3: c_uint = 0

        var __ci_expr_logic_2: c_int

        var __ci_expr_logic_1: c_int = 0

        if ((if 4 == sizeof[c_longlong](): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe *__param_state).size > gz_intmax(): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (((unsafe *__param_state).size as c_longlong)) > (unsafe *__param_state).skip: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_ternary_3 = (((unsafe *__param_state).skip as c_uint)))
        } else {
            (__ci_expr_ternary_3 = (unsafe *__param_state).size)
        }

        (__local_n = __ci_expr_ternary_3)


        if (__local_first != 0) {
            with_memset((((unsafe *__param_state).in_ as *mut c_void) as *i8), (0 as c_int), ((__local_n as c_ulong) as i64))

            (__local_first = ((0 as c_int)))

        }

        (__local_strm.avail_in = __local_n)

        (__local_strm.next_in = (unsafe *__param_state).in_)

        (__local_ret = ((gz_comp(__param_state, (0 as c_int)) as c_int)))

        (__local_n = (__local_n -% __local_strm.avail_in))

        ((unsafe *__param_state).x.pos = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).pos + __local_n)

        ((unsafe *__param_state).skip = (unsafe *__param_state).skip - __local_n)

        if ((if __local_ret == -1: 1 else: 0) != 0) {
            return -1
        }

        if not (((unsafe *__param_state).skip != 0)) {
            break
        }
    }

    return 0

}

unsafe fn gz_write(__param_state: *mut gz_state, __param_buf: *const c_void, __param_len: c_ulong) -> c_ulong {
    var __local_buf = __param_buf
    var __local_len = __param_len
    var __local_put: c_ulong = __local_len

    var __local_ret: c_int

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return 0
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__param_state).size == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if gz_init(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0
    }


    var __ci_expr_logic_1: c_int = 0

    if ((unsafe *__param_state).skip != 0) {
        (__ci_expr_logic_1 = (if (if gz_zero(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return 0
    }


    if ((if __local_len < (unsafe *__param_state).size: 1 else: 0) != 0) {
        while true {
            var __local_have: c_uint

            var __local_copy_: c_uint


            if ((if (unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0) {
                ((unsafe *__param_state).strm.next_in = (unsafe *__param_state).in_)
            }

            (__local_have = (((((((unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).next_in + ((unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in as usize)) as usize) -% ((unsafe *__param_state).in_ as usize)) / sizeof[u8]()) as c_uint)))

            (__local_copy_ = (((((unsafe *__param_state).size as c_uint) -% (__local_have as c_uint)) as c_uint)))

            if ((if __local_copy_ > __local_len: 1 else: 0) != 0) {
                (__local_copy_ = ((__local_len as c_uint)))
            }

            with_memcpy(((((unsafe *__param_state).in_ + (__local_have as usize)) as *mut c_void) as *i8), (__local_buf as *i8), ((__local_copy_ as c_ulong) as i64))

            ((unsafe *__param_state).strm.avail_in = ((unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in +% __local_copy_))

            ((unsafe *__param_state).x.pos = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).pos + __local_copy_)

            (__local_buf = ((((__local_buf as *const c_char) + (__local_copy_ as usize)) as *const c_void)))

            (__local_len = (__local_len -% __local_copy_))

            if ((if __local_len == 0: 1 else: 0) != 0) {
                break
            }

            if ((if gz_comp(__param_state, (0 as c_int)) == -1: 1 else: 0) != 0) {
                var __ci_expr_ternary_2: c_ulong = 0

                if ((unsafe *__param_state).again != 0) {
                    (__ci_expr_ternary_2 = ((((__local_put as c_ulong) -% (__local_len as c_ulong)) as c_ulong)))
                } else {
                    (__ci_expr_ternary_2 = ((0 as c_ulong)))
                }

                return __ci_expr_ternary_2

            }

        }

    } else {
        var __ci_expr_logic_3: c_int = 0

        if ((unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in != 0) {
            (__ci_expr_logic_3 = (if (if gz_comp(__param_state, (0 as c_int)) == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            return 0
        }


        ((unsafe *__param_state).strm.next_in = ((__local_buf as *mut u8)))

        loop {
            var __local_n: c_uint = ((-1 as c_uint))

            if ((if __local_n > __local_len: 1 else: 0) != 0) {
                (__local_n = ((__local_len as c_uint)))
            }

            ((unsafe *__param_state).strm.avail_in = __local_n)

            (__local_ret = ((gz_comp(__param_state, (0 as c_int)) as c_int)))

            (__local_n = (__local_n -% (unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in))

            ((unsafe *__param_state).x.pos = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).pos + __local_n)

            (__local_len = (__local_len -% __local_n))

            if ((if __local_ret == -1: 1 else: 0) != 0) {
                var __ci_expr_ternary_4: c_ulong = 0

                if ((unsafe *__param_state).again != 0) {
                    (__ci_expr_ternary_4 = ((((__local_put as c_ulong) -% (__local_len as c_ulong)) as c_ulong)))
                } else {
                    (__ci_expr_ternary_4 = ((0 as c_ulong)))
                }

                return __ci_expr_ternary_4

            }

            if not ((__local_len != 0)) {
                break
            }
        }

    }

    return __local_put

}

unsafe fn gz_vacate(__param_state: *mut gz_state) -> c_int {
    var __local_strm: *mut z_stream_s

    (__local_strm = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s)))

    if ((if (__local_strm.next_in + (__local_strm.avail_in as usize)) <= ((unsafe *__param_state).in_ + ((unsafe *__param_state).size as usize)): 1 else: 0) != 0) {
        return 0
    }

    gz_comp(__param_state, (0 as c_int))

    if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
        (__local_strm.next_in = (unsafe *__param_state).in_)

        return 0

    }

    with_memmove((((unsafe *__param_state).in_ as *mut c_void) as *i8), ((__local_strm.next_in as *const c_void) as *i8), ((__local_strm.avail_in as c_ulong) as i64))

    (__local_strm.next_in = (unsafe *__param_state).in_)

    return (if __local_strm.avail_in > (unsafe *__param_state).size: 1 else: 0)

}
