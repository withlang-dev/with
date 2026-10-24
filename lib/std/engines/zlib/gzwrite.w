// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
use std.engines.zlib.deflate
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.compress
use std.engines.zlib.uncompr
use std.engines.zlib.gzlib
use std.engines.zlib.gzread
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32
use std.libc
use std.collections

pub unsafe fn gzsetparams(__param_file: *mut gzFile_s, __param_level: i32, __param_strategy: i32) -> i32 {
    var __local_state: *mut gz_state

    var __local_strm: *mut z_stream_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    (__local_strm = (((&raw const (*__local_state).strm as *const z_stream_s) as *mut z_stream_s)))

    var __ci_expr_logic_2: i32

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (*__local_state).direct != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -2
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    var __ci_expr_logic_3: i32 = 0

    if ((if __param_level == (*__local_state).level: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if (if __param_strategy == (*__local_state).strategy: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return 0
    }


    var __ci_expr_logic_4: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_4 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        return (*__local_state).err
    }


    if ((*__local_state).size != 0) {
        var __ci_expr_logic_5: i32 = 0

        if ((*__local_strm).avail_in != 0) {
            (__ci_expr_logic_5 = (if (if gz_comp(__local_state, (5 as i32)) == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            return (*__local_state).err
        }


        deflateParams(__local_strm, __param_level, __param_strategy)

    }

    ((*__local_state).level = __param_level)

    ((*__local_state).strategy = __param_strategy)

    return 0

}

pub unsafe fn gzwrite(__param_file: *mut gzFile_s, __param_buf: *const c_void, __param_len: u32) -> i32 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return 0
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    if ((if ((__param_len as i32)) < 0: 1 else: 0) != 0) {
        gz_error(__local_state, (-3 as i32), c"requested length does not fit in int".ptr)

        return 0

    }

    return ((gz_write(__local_state, __param_buf, (__param_len as u64)) as i32))

}

pub unsafe fn gzfwrite(__param_buf: *const c_void, __param_size: u64, __param_nitems: u64, __param_file: *mut gzFile_s) -> u64 {
    var __local_len: u64

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((0 as u64))
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return ((0 as u64))
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    (__local_len = ((((__param_nitems as u64) *% (__param_size as u64)) as u64)))

    var __ci_expr_logic_2: i32 = 0

    if (__param_size != 0) {
        (__ci_expr_logic_2 = (if (if ((__local_len as u64) / (__param_size as u64)) != __param_nitems: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        gz_error(__local_state, (-2 as i32), c"request does not fit in a size_t".ptr)

        return ((0 as u64))

    }


    return (if __local_len != 0: (((gz_write(__local_state, __param_buf, __local_len) as u64) / (__param_size as u64)) as u64) else: (0 as u64))

}

pub unsafe fn gzprintf(__param_file: *mut gzFile_s, __param_format: *const c_char, ...) -> i32 {

    var __local_ret: i32

    var __local_va: c_va_list = va_start()

    (__local_ret = ((gzvprintf(__param_file, __param_format, __local_va) as i32)))


    return __local_ret

}

pub unsafe fn gzputs(__param_file: *mut gzFile_s, __param_s: *const c_char) -> i32 {
    var __local_len: u64

    var __local_put: u64


    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    (__local_len = ((strlen(__param_s) as u64)))

    var __ci_expr_logic_2: i32

    if ((if ((__local_len as i32)) < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if ((__local_len as u32)) != __local_len: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        gz_error(__local_state, (-2 as i32), c"string length does not fit in int".ptr)

        return -1

    }


    (__local_put = ((gz_write(__local_state, (__param_s as *const c_void), __local_len) as u64)))

    var __ci_expr_ternary_4: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    if (__local_len != 0) {
        (__ci_expr_logic_3 = (if (if __local_put == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_ternary_4 = ((-1 as i32)))
    } else {
        (__ci_expr_ternary_4 = ((__local_put as i32)))
    }

    return __ci_expr_ternary_4


}

pub unsafe fn gzputc(__param_file: *mut gzFile_s, __param_c: i32) -> i32 {
    var __local_have: u32

    var __local_buf: List[u8] = [0; 1]

    var __local_state: *mut gz_state

    var __local_strm: *mut z_stream_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    (__local_strm = (((&raw const (*__local_state).strm as *const z_stream_s) as *mut z_stream_s)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    var __ci_expr_logic_2: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_2 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -1
    }


    if ((*__local_state).size != 0) {
        if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
            ((*__local_strm).next_in = (*__local_state).in_)
        }

        (__local_have = ((((((((*__local_strm).next_in + ((*__local_strm).avail_in as usize)) as usize) -% ((*__local_state).in_ as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

        if ((if __local_have < (*__local_state).size: 1 else: 0) != 0) {
            (((*__local_state).in_[__local_have]) = ((__param_c as u8)))

            ((*__local_strm).avail_in = ((*__local_strm).avail_in +% 1))

            ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos + 1)

            return ((__param_c as i32) & (255 as i32))

        }

    }

    (__local_buf[0] = ((__param_c as u8)))

    if ((if gz_write(__local_state, (&__local_buf[0] as *mut u8), (1 as u64)) != 1: 1 else: 0) != 0) {
        return -1
    }

    return ((__param_c as i32) & (255 as i32))

}

pub unsafe fn gzflush(__param_file: *mut gzFile_s, __param_flush: i32) -> i32 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -2
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    var __ci_expr_logic_2: i32

    if ((if __param_flush < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __param_flush > 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -2
    }


    var __ci_expr_logic_3: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_3 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return (*__local_state).err
    }


    gz_comp(__local_state, __param_flush)

    return (*__local_state).err

}

pub unsafe fn gzclose_w(__param_file: *mut gzFile_s) -> i32 {
    var __local_ret: i32 = ((0 as i32))

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        return -2
    }

    var __ci_expr_logic_0: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_0 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_ret = (*__local_state).err)
    }


    if ((if gz_comp(__local_state, (4 as i32)) == -1: 1 else: 0) != 0) {
        (__local_ret = (*__local_state).err)
    }

    if ((*__local_state).size != 0) {
        if ((if not ((*__local_state).direct != 0): 1 else: 0) != 0) {
            deflateEnd(((&raw const (*__local_state).strm as *const z_stream_s) as *mut z_stream_s))

            with_free((((*__local_state).out as *mut c_void) as *mut u8))

        }

        with_free((((*__local_state).in_ as *mut c_void) as *mut u8))

    }

    gz_error(__local_state, (0 as i32), (null as *const c_char))

    with_free((((*__local_state).path as *mut c_void) as *mut u8))

    if ((if close((*__local_state).fd) == -1: 1 else: 0) != 0) {
        (__local_ret = ((-1 as i32)))
    }

    with_free(((__local_state as *mut c_void) as *mut u8))

    return __local_ret

}

pub unsafe fn gzvprintf(__param_file: *mut gzFile_s, __param_format: *const c_char, __param_va: c_va_list) -> i32 {
    var __local_len: i32

    var __local_ret: i32


    var __local_next: *mut c_char

    var __local_state: *mut gz_state

    var __local_strm: *mut z_stream_s

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    (__local_strm = (((&raw const (*__local_state).strm as *const z_stream_s) as *mut z_stream_s)))

    var __ci_expr_logic_1: i32

    if ((if (*__local_state).mode != 31153: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -2
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    var __ci_expr_logic_2: i32 = 0

    if ((if (*__local_state).size == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if gz_init(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return (*__local_state).err
    }


    var __ci_expr_logic_3: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_3 = (if (if gz_zero(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return (*__local_state).err
    }


    (__local_ret = ((gz_vacate(__local_state) as i32)))

    if ((*__local_state).err != 0) {
        var __ci_expr_logic_4: i32 = 0

        if (__local_ret != 0) {
            (__ci_expr_logic_4 = (if (*__local_state).again != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            gz_error(__local_state, (-5 as i32), c"stalled write on gzprintf".ptr)

        }


        if ((if not ((*__local_state).again != 0): 1 else: 0) != 0) {
            return (*__local_state).err
        }

    }

    if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
        ((*__local_strm).next_in = (*__local_state).in_)
    }

    (__local_next = (((((*__local_state).in_ + (((((((*__local_strm).next_in as usize) -% ((*__local_state).in_ as usize)) as i64) / (sizeof[u8]() as i64)) as isize) as usize)) + ((*__local_strm).avail_in as usize)) as *mut c_char)))

    ((__local_next[(((*__local_state).size as u32) -% (1 as u32))]) = ((0 as c_char)))

    (__local_len = ((vsnprintf(__local_next, ((*__local_state).size as u64), __param_format, __param_va) as i32)))

    var __ci_expr_logic_6: i32

    var __ci_expr_logic_5: i32

    if ((if __local_len == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_5 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_5 = (if (if ((__local_len as u32)) >= (*__local_state).size: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__ci_expr_logic_6 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_6 = (if (if (__local_next[(((*__local_state).size as u32) -% (1 as u32))]) != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        return 0
    }


    ((*__local_strm).avail_in = ((*__local_strm).avail_in +% (__local_len as u32)))

    ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos + __local_len)

    (__local_ret = ((gz_vacate(__local_state) as i32)))

    var __ci_expr_logic_7: i32 = 0

    if ((*__local_state).err != 0) {
        (__ci_expr_logic_7 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        return (*__local_state).err
    }


    return __local_len

}

unsafe fn gz_init(__param_state: *mut gz_state) -> i32 {
    var __local_ret: i32

    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    ((*__param_state).in_ = (((with_alloc((((((*__param_state).want as u32) << (1 as u32)) as u64) as i64)) as *mut c_void) as *mut u8)))

    if ((if (*__param_state).in_ == null: 1 else: 0) != 0) {
        gz_error(__param_state, (-4 as i32), c"out of memory".ptr)

        return -1

    }

    if ((if not ((*__param_state).direct != 0): 1 else: 0) != 0) {
        ((*__param_state).out = (((with_alloc((((*__param_state).want as u64) as i64)) as *mut c_void) as *mut u8)))

        if ((if (*__param_state).out == null: 1 else: 0) != 0) {
            with_free((((*__param_state).in_ as *mut c_void) as *mut u8))

            gz_error(__param_state, (-4 as i32), c"out of memory".ptr)

            return -1

        }

        ((*__local_strm).zalloc = null)

        ((*__local_strm).zfree = null)

        ((*__local_strm).opaque_ = null)

        (__local_ret = ((deflateInit2_(__local_strm, (*__param_state).level, (8 as i32), ((15 + 16) as i32), (8 as i32), (*__param_state).strategy, c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

        if ((if __local_ret != 0: 1 else: 0) != 0) {
            with_free((((*__param_state).out as *mut c_void) as *mut u8))

            with_free((((*__param_state).in_ as *mut c_void) as *mut u8))

            gz_error(__param_state, (-4 as i32), c"out of memory".ptr)

            return -1

        }

        ((*__local_strm).next_in = ((null as *mut u8)))

    }

    ((*__param_state).size = (*__param_state).want)

    if ((if not ((*__param_state).direct != 0): 1 else: 0) != 0) {
        ((*__local_strm).avail_out = (*__param_state).size)

        ((*__local_strm).next_out = (*__param_state).out)

        ((*__param_state).x.next = (*__local_strm).next_out)

    }

    return 0

}

unsafe fn gz_comp(__param_state: *mut gz_state, __param_flush: i32) -> i32 {
    var __local_ret: i32

    var __local_writ: i32


    var __local_have: u32

    var __local_put: u32

    var __local_max: u32 = ((((((-1 as u32) >> (2 as u32)) as u32) +% (1 as u32)) as u32))


    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_state).size == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if gz_init(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    if ((*__param_state).direct != 0) {
        while ((*__local_strm).avail_in != 0) {
            ((*(errno_ptr())) = ((0 as i32)))

            ((*__param_state).again = ((0 as i32)))

            (__local_put = (((if (if (*__local_strm).avail_in > __local_max: 1 else: 0) != 0: __local_max else: (*__local_strm).avail_in) as u32)))

            (__local_writ = ((write((*__param_state).fd, ((*__local_strm).next_in as *const c_void), (__local_put as u64)) as i32)))

            if ((if __local_writ < 0: 1 else: 0) != 0) {
                var __ci_expr_logic_1: i32

                if ((if (*(errno_ptr())) == libc.EAGAIN: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if (*(errno_ptr())) == libc.EWOULDBLOCK: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    ((*__param_state).again = ((1 as i32)))
                }


                gz_error(__param_state, (-1 as i32), (strerror((*(errno_ptr()))) as *const c_char))

                return -1

            }

            ((*__local_strm).avail_in = ((*__local_strm).avail_in -% (__local_writ as u32)))

            ((*__local_strm).next_in = (*__local_strm).next_in + ((__local_writ as isize) as usize))

        }

        return 0

    }

    if ((*__param_state).reset != 0) {
        var __ci_expr_logic_2: i32 = 0

        if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            return 0
        }


        deflateReset(__local_strm)

        ((*__param_state).reset = ((0 as i32)))

    }

    (__local_ret = ((0 as i32)))

    loop {
        var __ci_expr_logic_5: i32

        if ((if (*__local_strm).avail_out == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_4: i32 = 0

            if ((if __param_flush != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_3: i32

                if ((if __param_flush != 4: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if (if __local_ret == 1: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

            }

            (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_5 != 0) {
            while ((if (*__local_strm).next_out > (*(&raw const (*__param_state).x as *const gzFile_s)).next: 1 else: 0) != 0) {
                ((*(errno_ptr())) = ((0 as i32)))

                ((*__param_state).again = ((0 as i32)))

                (__local_put = (((if (if (((((*__local_strm).next_out as usize) -% ((*(&raw const (*__param_state).x as *const gzFile_s)).next as usize)) as i64) / (sizeof[u8]() as i64)) > ((__local_max as i32)): 1 else: 0) != 0: __local_max else: ((((((*__local_strm).next_out as usize) -% ((*(&raw const (*__param_state).x as *const gzFile_s)).next as usize)) as i64) / (sizeof[u8]() as i64)) as u32)) as u32)))

                (__local_writ = ((write((*__param_state).fd, ((*(&raw const (*__param_state).x as *const gzFile_s)).next as *const c_void), (__local_put as u64)) as i32)))

                if ((if __local_writ < 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_6: i32

                    if ((if (*(errno_ptr())) == libc.EAGAIN: 1 else: 0) != 0) {
                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_6 = (if (if (*(errno_ptr())) == libc.EWOULDBLOCK: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_6 != 0) {
                        ((*__param_state).again = ((1 as i32)))
                    }


                    gz_error(__param_state, (-1 as i32), (strerror((*(errno_ptr()))) as *const c_char))

                    return -1

                }

                ((*__param_state).x.next = (*(&raw const (*__param_state).x as *const gzFile_s)).next + ((__local_writ as isize) as usize))

            }

            if ((if (*__local_strm).avail_out == 0: 1 else: 0) != 0) {
                ((*__local_strm).avail_out = (*__param_state).size)

                ((*__local_strm).next_out = (*__param_state).out)

                ((*__param_state).x.next = (*__param_state).out)

            }

        }


        (__local_have = (*__local_strm).avail_out)

        (__local_ret = ((deflate(__local_strm, __param_flush) as i32)))

        if ((if __local_ret == -2: 1 else: 0) != 0) {
            gz_error(__param_state, (-2 as i32), c"internal error: deflate stream corrupt".ptr)

            return -1

        }

        (__local_have = (__local_have -% (*__local_strm).avail_out))

        if not ((__local_have != 0)) {
            break
        }
    }

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        ((*__param_state).reset = ((1 as i32)))
    }

    return 0

}

unsafe fn gz_zero(__param_state: *mut gz_state) -> i32 {
    var __local_first: i32

    var __local_ret: i32


    var __local_n: u32

    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    var __ci_expr_logic_0: i32 = 0

    if ((*__local_strm).avail_in != 0) {
        (__ci_expr_logic_0 = (if (if gz_comp(__param_state, (0 as i32)) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    (__local_first = ((1 as i32)))

    loop {
        var __ci_expr_ternary_3: u32 = 0

        var __ci_expr_logic_2: i32

        var __ci_expr_logic_1: i32 = 0

        if ((if 4 == (sizeof[i64]() as usize): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__param_state).size > gz_intmax(): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (((*__param_state).size as i64)) > (*__param_state).skip: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_ternary_3 = (((*__param_state).skip as u32)))
        } else {
            (__ci_expr_ternary_3 = (*__param_state).size)
        }

        (__local_n = __ci_expr_ternary_3)


        if (__local_first != 0) {
            with_memset((((*__param_state).in_ as *mut c_void) as *mut u8), (0 as i32), ((__local_n as u64) as i64))

            (__local_first = ((0 as i32)))

        }

        ((*__local_strm).avail_in = __local_n)

        ((*__local_strm).next_in = (*__param_state).in_)

        (__local_ret = ((gz_comp(__param_state, (0 as i32)) as i32)))

        (__local_n = (__local_n -% (*__local_strm).avail_in))

        ((*__param_state).x.pos = (*(&raw const (*__param_state).x as *const gzFile_s)).pos + __local_n)

        ((*__param_state).skip = (*__param_state).skip - __local_n)

        if ((if __local_ret == -1: 1 else: 0) != 0) {
            return -1
        }

        if not (((*__param_state).skip != 0)) {
            break
        }
    }

    return 0

}

unsafe fn gz_write(__param_state: *mut gz_state, __param_buf: *const c_void, __param_len: u64) -> u64 {
    var __local_buf = __param_buf
    var __local_len = __param_len
    var __local_put: u64 = __local_len

    var __local_ret: i32

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return ((0 as u64))
    }

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_state).size == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if gz_init(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((0 as u64))
    }


    var __ci_expr_logic_1: i32 = 0

    if ((*__param_state).skip != 0) {
        (__ci_expr_logic_1 = (if (if gz_zero(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((0 as u64))
    }


    if ((if __local_len < (*__param_state).size: 1 else: 0) != 0) {
        while true {
            var __local_have: u32

            var __local_copy_: u32


            if ((if (*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0) {
                ((*__param_state).strm.next_in = (*__param_state).in_)
            }

            (__local_have = ((((((((*(&raw const (*__param_state).strm as *const z_stream_s)).next_in + ((*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in as usize)) as usize) -% ((*__param_state).in_ as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            (__local_copy_ = (((((*__param_state).size as u32) -% (__local_have as u32)) as u32)))

            if ((if __local_copy_ > __local_len: 1 else: 0) != 0) {
                (__local_copy_ = ((__local_len as u32)))
            }

            with_memcpy(((((*__param_state).in_ + (__local_have as usize)) as *mut c_void) as *mut u8), (__local_buf as *const u8), ((__local_copy_ as u64) as i64))

            ((*__param_state).strm.avail_in = ((*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in +% __local_copy_))

            ((*__param_state).x.pos = (*(&raw const (*__param_state).x as *const gzFile_s)).pos + __local_copy_)

            (__local_buf = ((((__local_buf as *const c_char) + (__local_copy_ as usize)) as *const c_void)))

            (__local_len = (__local_len -% __local_copy_))

            if ((if __local_len == 0: 1 else: 0) != 0) {
                break
            }

            if ((if gz_comp(__param_state, (0 as i32)) == -1: 1 else: 0) != 0) {
                return (if (*__param_state).again != 0: (((__local_put as u64) -% (__local_len as u64)) as u64) else: (0 as u64))
            }

        }

    } else {
        var __ci_expr_logic_2: i32 = 0

        if ((*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in != 0) {
            (__ci_expr_logic_2 = (if (if gz_comp(__param_state, (0 as i32)) == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            return ((0 as u64))
        }


        ((*__param_state).strm.next_in = ((__local_buf as *mut u8)))

        loop {
            var __local_n: u32 = ((-1 as u32))

            if ((if __local_n > __local_len: 1 else: 0) != 0) {
                (__local_n = ((__local_len as u32)))
            }

            ((*__param_state).strm.avail_in = __local_n)

            (__local_ret = ((gz_comp(__param_state, (0 as i32)) as i32)))

            (__local_n = (__local_n -% (*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in))

            ((*__param_state).x.pos = (*(&raw const (*__param_state).x as *const gzFile_s)).pos + __local_n)

            (__local_len = (__local_len -% __local_n))

            if ((if __local_ret == -1: 1 else: 0) != 0) {
                return (if (*__param_state).again != 0: (((__local_put as u64) -% (__local_len as u64)) as u64) else: (0 as u64))
            }

            if not ((__local_len != 0)) {
                break
            }
        }

    }

    return __local_put

}

unsafe fn gz_vacate(__param_state: *mut gz_state) -> i32 {
    var __local_strm: *mut z_stream_s

    (__local_strm = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s)))

    if ((if ((*__local_strm).next_in + ((*__local_strm).avail_in as usize)) <= ((*__param_state).in_ + ((*__param_state).size as usize)): 1 else: 0) != 0) {
        return 0
    }

    gz_comp(__param_state, (0 as i32))

    if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
        ((*__local_strm).next_in = (*__param_state).in_)

        return 0

    }

    with_memmove((((*__param_state).in_ as *mut c_void) as *mut u8), (((*__local_strm).next_in as *const c_void) as *const u8), (((*__local_strm).avail_in as u64) as i64))

    ((*__local_strm).next_in = (*__param_state).in_)

    return (if (*__local_strm).avail_in > (*__param_state).size: 1 else: 0)

}
