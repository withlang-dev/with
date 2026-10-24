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
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32
use std.libc
use std.collections

pub unsafe fn gzread(__param_file: *mut gzFile_s, __param_buf: *mut c_void, __param_len: u32) -> i32 {
    var __local_len = __param_len
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    if ((if ((__local_len as i32)) < 0: 1 else: 0) != 0) {
        gz_error(__local_state, (-2 as i32), c"request does not fit in an int".ptr)

        return -1

    }

    (__local_len = ((gz_read(__local_state, __param_buf, (__local_len as u64)) as u32)))

    if ((if __local_len == 0: 1 else: 0) != 0) {
        var __ci_expr_logic_2: i32 = 0

        if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            return -1
        }


        if ((*__local_state).again != 0) {
            gz_error(__local_state, (-1 as i32), (strerror((*(errno_ptr()))) as *const c_char))

            return -1

        }

    }

    return ((__local_len as i32))

}

pub unsafe fn gzfread(__param_buf: *mut c_void, __param_size: u64, __param_nitems: u64, __param_file: *mut gzFile_s) -> u64 {
    var __local_len: u64

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return ((0 as u64))
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        return ((0 as u64))
    }

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
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


    return (if __local_len != 0: (((gz_read(__local_state, __param_buf, __local_len) as u64) / (__param_size as u64)) as u64) else: (0 as u64))

}

pub unsafe fn gzgets(__param_file: *mut gzFile_s, __param_buf: *mut c_char, __param_len: i32) -> *mut c_char {
    var __local_buf = __param_buf
    var __local_left: u32

    var __local_n: u32


    var __local_str: *mut c_char

    var __local_eol: *mut u8

    var __local_state: *mut gz_state

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if ((if __param_file == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_buf == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_len < 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((null as *mut c_char))
    }


    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return ((null as *mut c_char))
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    var __ci_expr_logic_4: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_4 = (if (if gz_skip(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        return ((null as *mut c_char))
    }


    (__local_str = __local_buf)

    (__local_left = ((((__param_len as u32) -% (1 as u32)) as u32)))

    if (__local_left != 0) {
        loop {
            var __ci_expr_logic_6: i32 = 0

            if ((if (*(&raw const (*__local_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if gz_fetch(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                break
            }


            if ((if (*(&raw const (*__local_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
                ((*__local_state).past = ((1 as i32)))

                break

            }

            (__local_n = (((if (if (*(&raw const (*__local_state).x as *const gzFile_s)).have > __local_left: 1 else: 0) != 0: __local_left else: (*(&raw const (*__local_state).x as *const gzFile_s)).have) as u32)))

            (__local_eol = (((memchr((((*(&raw const (*__local_state).x as *const gzFile_s)).next as *const c_void) as *mut c_void), (10 as i32), ((__local_n as u64) as i64)) as *const u8) as *mut u8)))

            if ((if __local_eol != null: 1 else: 0) != 0) {
                (__local_n = ((((((((__local_eol as usize) -% ((*(&raw const (*__local_state).x as *const gzFile_s)).next as usize)) as i64) / (sizeof[u8]() as i64)) as u32) +% (1 as u32)) as u32)))
            }

            with_memcpy(((__local_buf as *mut c_void) as *mut u8), (((*(&raw const (*__local_state).x as *const gzFile_s)).next as *const c_void) as *const u8), ((__local_n as u64) as i64))

            ((*__local_state).x.have = ((*(&raw const (*__local_state).x as *const gzFile_s)).have -% __local_n))

            ((*__local_state).x.next = (*(&raw const (*__local_state).x as *const gzFile_s)).next + (__local_n as usize))

            ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos + __local_n)

            (__local_left = (__local_left -% __local_n))

            (__local_buf = __local_buf + (__local_n as usize))

            var __ci_expr_logic_5: i32 = 0

            if (__local_left != 0) {
                (__ci_expr_logic_5 = (if (if __local_eol == null: 1 else: 0) != 0: 1 else: 0))
            }

            if not ((__ci_expr_logic_5 != 0)) {
                break
            }
        }
    }

    if ((if __local_buf == __local_str: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    ((__local_buf[0]) = ((0 as c_char)))

    return __local_str

}

pub unsafe fn gzgetc(__param_file: *mut gzFile_s) -> i32 {
    var __local_buf: List[u8] = [0; 1]

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    if ((*(&raw const (*__local_state).x as *const gzFile_s)).have != 0) {
        ((*__local_state).x.have = ((*(&raw const (*__local_state).x as *const gzFile_s)).have -% 1))

        ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos + 1)

        var __ci_expr_old_2: *mut u8 = (*(&raw const (*__local_state).x as *const gzFile_s)).next

        ((*__local_state).x.next = (*(&raw const (*__local_state).x as *const gzFile_s)).next + 1)

        return (((*__ci_expr_old_2) as i32))


    }

    return (if (if gz_read(__local_state, (&__local_buf[0] as *mut u8), (1 as u64)) < 1: 1 else: 0) != 0: (-1 as i32) else: (__local_buf[0] as i32))

}

pub unsafe fn gzungetc(__param_c: i32, __param_file: *mut gzFile_s) -> i32 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).how == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (*__local_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        gz_look(__local_state)
    }


    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    if ((if (*__local_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*__local_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if (if not ((*__local_state).again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as i32), (null as *const c_char))

    var __ci_expr_logic_3: i32 = 0

    if ((*__local_state).skip != 0) {
        (__ci_expr_logic_3 = (if (if gz_skip(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return -1
    }


    if ((if __param_c < 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if (*(&raw const (*__local_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
        ((*__local_state).x.have = ((1 as u32)))

        ((*__local_state).x.next = ((*__local_state).out + ((((*__local_state).size as u32) << (1 as u32)) as usize)) - ((1 as isize) as usize))

        (((*__local_state).x.next[0]) = ((__param_c as u8)))

        ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos - 1)

        ((*__local_state).past = ((0 as i32)))

        return __param_c

    }

    if ((if (*(&raw const (*__local_state).x as *const gzFile_s)).have == (((*__local_state).size as u32) << (1 as u32)): 1 else: 0) != 0) {
        gz_error(__local_state, (-3 as i32), c"out of room to push characters".ptr)

        return -1

    }

    if ((if (*(&raw const (*__local_state).x as *const gzFile_s)).next == (*__local_state).out: 1 else: 0) != 0) {
        var __local_src: *mut u8 = ((*__local_state).out + ((*(&raw const (*__local_state).x as *const gzFile_s)).have as usize))

        var __local_dest: *mut u8 = ((*__local_state).out + ((((*__local_state).size as u32) << (1 as u32)) as usize))

        while ((if __local_src > (*__local_state).out: 1 else: 0) != 0) {
            (__local_dest = __local_dest - 1)

            (__local_src = __local_src - 1)

            ((*__local_dest) = (*__local_src))

        }

        ((*__local_state).x.next = __local_dest)

    }

    ((*__local_state).x.have = ((*(&raw const (*__local_state).x as *const gzFile_s)).have +% 1))

    ((*__local_state).x.next = (*(&raw const (*__local_state).x as *const gzFile_s)).next - 1)

    (((*__local_state).x.next[0]) = ((__param_c as u8)))

    ((*__local_state).x.pos = (*(&raw const (*__local_state).x as *const gzFile_s)).pos - 1)

    ((*__local_state).past = ((0 as i32)))

    return __param_c

}

pub unsafe fn gzdirect(__param_file: *mut gzFile_s) -> i32 {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__local_state).mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__local_state).how == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if (*(&raw const (*__local_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        gz_look(__local_state)
    }


    return (if (*__local_state).direct == 1: 1 else: 0)

}

pub unsafe fn gzclose_r(__param_file: *mut gzFile_s) -> i32 {
    var __local_ret: i32

    var __local_err: i32


    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if (*__local_state).mode != 7247: 1 else: 0) != 0) {
        return -2
    }

    if ((*__local_state).size != 0) {
        inflateEnd(((&raw const (*__local_state).strm as *const z_stream_s) as *mut z_stream_s))

        with_free((((*__local_state).out as *mut c_void) as *mut u8))

        with_free((((*__local_state).in_ as *mut c_void) as *mut u8))

    }

    (__local_err = (((if (if (*__local_state).err == -5: 1 else: 0) != 0: (-5 as i32) else: (0 as i32)) as i32)))

    gz_error(__local_state, (0 as i32), (null as *const c_char))

    with_free((((*__local_state).path as *mut c_void) as *mut u8))

    (__local_ret = ((close((*__local_state).fd) as i32)))

    with_free(((__local_state as *mut c_void) as *mut u8))

    return (if __local_ret != 0: (-1 as i32) else: __local_err)

}

pub unsafe fn gzgetc_(__param_file: *mut gzFile_s) -> i32 {
    return gzgetc(__param_file)

}

unsafe fn gz_load(__param_state: *mut gz_state, __param_buf: *mut u8, __param_len: u32, __param_have: *mut u32) -> i32 {
    var __local_ret: i32

    var __local_get: u32

    var __local_max: u32 = ((((((-1 as u32) >> (2 as u32)) as u32) +% (1 as u32)) as u32))


    ((*__param_state).again = ((0 as i32)))

    ((*(errno_ptr())) = ((0 as i32)))

    ((*__param_have) = ((0 as u32)))

    loop {
        (__local_get = ((((__param_len as u32) -% ((*__param_have) as u32)) as u32)))

        if ((if __local_get > __local_max: 1 else: 0) != 0) {
            (__local_get = __local_max)
        }

        (__local_ret = ((read((*__param_state).fd, ((__param_buf + ((*__param_have) as usize)) as *mut c_void), (__local_get as u64)) as i32)))

        if ((if __local_ret <= 0: 1 else: 0) != 0) {
            break
        }

        ((*__param_have) = ((*__param_have) +% (__local_ret as u32)))

        if not (((if (*__param_have) < __param_len: 1 else: 0) != 0)) {
            break
        }
    }

    if ((if __local_ret < 0: 1 else: 0) != 0) {
        var __ci_expr_logic_0: i32

        if ((if (*(errno_ptr())) == libc.EAGAIN: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (*(errno_ptr())) == libc.EWOULDBLOCK: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            ((*__param_state).again = ((1 as i32)))

            if ((if (*__param_have) != 0: 1 else: 0) != 0) {
                return 0
            }

        }


        gz_error(__param_state, (-1 as i32), (strerror((*(errno_ptr()))) as *const c_char))

        return -1

    }

    if ((if __local_ret == 0: 1 else: 0) != 0) {
        ((*__param_state).eof = ((1 as i32)))
    }

    return 0

}

unsafe fn gz_avail(__param_state: *mut gz_state) -> i32 {
    var __local_got: u32

    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    if ((if (*__param_state).eof == 0: 1 else: 0) != 0) {
        if ((*__local_strm).avail_in != 0) {
            var __local_p: *mut u8 = (*__param_state).in_

            var __local_q: *const u8 = (((*__local_strm).next_in as *const u8))

            if ((if __local_q != __local_p: 1 else: 0) != 0) {
                var __local_n: u32 = (*__local_strm).avail_in

                loop {
                    var __ci_expr_old_1: *mut u8 = __local_p

                    (__local_p = __local_p + 1)

                    var __ci_expr_old_2: *const u8 = __local_q

                    (__local_q = __local_q + 1)

                    ((*__ci_expr_old_1) = (*__ci_expr_old_2))


                    (__local_n = (__local_n -% 1))
                    if not ((__local_n != 0)) {
                        break
                    }
                }

            }

        }

        if ((if gz_load(__param_state, ((*__param_state).in_ + ((*__local_strm).avail_in as usize)), ((((*__param_state).size as u32) -% ((*__local_strm).avail_in as u32)) as u32), (&raw mut __local_got as *mut u32)) == -1: 1 else: 0) != 0) {
            return -1
        }

        ((*__local_strm).avail_in = ((*__local_strm).avail_in +% __local_got))

        ((*__local_strm).next_in = (*__param_state).in_)

    }

    return 0

}

unsafe fn gz_look(__param_state: *mut gz_state) -> i32 {
    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    if ((if (*__param_state).size == 0: 1 else: 0) != 0) {
        ((*__param_state).in_ = (((with_alloc((((*__param_state).want as u64) as i64)) as *mut c_void) as *mut u8)))

        ((*__param_state).out = (((with_alloc((((((*__param_state).want as u32) << (1 as u32)) as u64) as i64)) as *mut c_void) as *mut u8)))

        var __ci_expr_logic_0: i32

        if ((if (*__param_state).in_ == null: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (*__param_state).out == null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            with_free((((*__param_state).out as *mut c_void) as *mut u8))

            with_free((((*__param_state).in_ as *mut c_void) as *mut u8))

            gz_error(__param_state, (-4 as i32), c"out of memory".ptr)

            return -1

        }


        ((*__param_state).size = (*__param_state).want)

        ((*__param_state).strm.zalloc = null)

        ((*__param_state).strm.zfree = null)

        ((*__param_state).strm.opaque_ = null)

        ((*__param_state).strm.avail_in = ((0 as u32)))

        ((*__param_state).strm.next_in = null)

        if ((if inflateInit2_(((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s), ((15 + 16) as i32), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) != 0: 1 else: 0) != 0) {
            with_free((((*__param_state).out as *mut c_void) as *mut u8))

            with_free((((*__param_state).in_ as *mut c_void) as *mut u8))

            ((*__param_state).size = ((0 as u32)))

            gz_error(__param_state, (-4 as i32), c"out of memory".ptr)

            return -1

        }

    }

    var __ci_expr_logic_1: i32

    if ((if (*__param_state).direct == -1: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__param_state).junk == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        inflateReset(__local_strm)

        ((*__param_state).how = ((2 as i32)))

        ((*__param_state).junk = (((if (*__param_state).junk != -1: 1 else: 0) as i32)))

        ((*__param_state).direct = ((0 as i32)))

        return 0

    }


    if ((if gz_avail(__param_state) == -1: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_3: i32

    if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_2: i32 = 0

        if ((*__param_state).again != 0) {
            (__ci_expr_logic_2 = (if (if (*__local_strm).avail_in < 4: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        return 0
    }


    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    if ((if (*__local_strm).avail_in > 3: 1 else: 0) != 0) {
        (__ci_expr_logic_4 = (if (if ((*__local_strm).next_in[0]) == 31: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_logic_5 = (if (if ((*__local_strm).next_in[1]) == 139: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__ci_expr_logic_6 = (if (if ((*__local_strm).next_in[2]) == 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_7 = (if (if ((*__local_strm).next_in[3]) < 32: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        inflateReset(__local_strm)

        ((*__param_state).how = ((2 as i32)))

        ((*__param_state).junk = ((1 as i32)))

        ((*__param_state).direct = ((0 as i32)))

        return 0

    }


    ((*__param_state).x.next = (*__param_state).out)

    with_memcpy((((*(&raw const (*__param_state).x as *const gzFile_s)).next as *mut c_void) as *mut u8), (((*__local_strm).next_in as *const c_void) as *const u8), (((*__local_strm).avail_in as u64) as i64))

    ((*__param_state).x.have = (*__local_strm).avail_in)

    ((*__local_strm).avail_in = ((0 as u32)))

    ((*__param_state).how = ((1 as i32)))

    return 0

}

unsafe fn gz_decomp(__param_state: *mut gz_state) -> i32 {
    var __local_ret: i32 = ((0 as i32))

    var __local_had: u32

    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    (__local_had = (*__local_strm).avail_out)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if gz_avail(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_ret = (*__param_state).err)

            break

        }


        if ((if (*__local_strm).avail_in == 0: 1 else: 0) != 0) {
            if ((if not ((*__param_state).again != 0): 1 else: 0) != 0) {
                gz_error(__param_state, (-5 as i32), c"unexpected end of file".ptr)
            }

            break

        }

        (__local_ret = ((inflate(__local_strm, (0 as i32)) as i32)))

        if ((if (*__local_strm).avail_out < __local_had: 1 else: 0) != 0) {
            ((*__param_state).junk = ((0 as i32)))
        }

        var __ci_expr_logic_2: i32

        if ((if __local_ret == -2: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_ret == 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            gz_error(__param_state, (-2 as i32), c"internal error: inflate stream corrupt".ptr)

            break

        }


        if ((if __local_ret == -4: 1 else: 0) != 0) {
            gz_error(__param_state, (-4 as i32), c"out of memory".ptr)

            break

        }

        if ((if __local_ret == -3: 1 else: 0) != 0) {
            if ((if (*__param_state).junk == 1: 1 else: 0) != 0) {
                ((*__local_strm).avail_in = ((0 as u32)))

                ((*__param_state).eof = ((1 as i32)))

                ((*__param_state).how = ((0 as i32)))

                (__local_ret = ((0 as i32)))

                break

            }

            gz_error(__param_state, (-3 as i32), ((if (if (*__local_strm).msg == null: 1 else: 0) != 0: ("compressed data error" as *mut c_char) else: (*__local_strm).msg) as *const c_char))

            break

        }

        var __ci_expr_logic_0: i32 = 0

        if ((*__local_strm).avail_out != 0) {
            (__ci_expr_logic_0 = (if (if __local_ret != 1: 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    ((*__param_state).x.have = ((((__local_had as u32) -% ((*__local_strm).avail_out as u32)) as u32)))

    ((*__param_state).x.next = (*__local_strm).next_out - ((*(&raw const (*__param_state).x as *const gzFile_s)).have as usize))

    if ((if __local_ret == 1: 1 else: 0) != 0) {
        ((*__param_state).junk = ((0 as i32)))

        ((*__param_state).how = ((0 as i32)))

        return 0

    }

    return (if (if __local_ret != 0: 1 else: 0) != 0: (-1 as i32) else: (0 as i32))

}

unsafe fn gz_fetch(__param_state: *mut gz_state) -> i32 {
    var __local_strm: *mut z_stream_s = (((&raw const (*__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    loop {
        while true {
            match (*__param_state).how {
                0 => {
                    if ((if gz_look(__param_state) == -1: 1 else: 0) != 0) {
                        return -1
                    }

                    if ((if (*__param_state).how == 0: 1 else: 0) != 0) {
                        return 0
                    }

                },
                1 => {
                    if ((if gz_load(__param_state, (*__param_state).out, ((((*__param_state).size as u32) << (1 as u32)) as u32), ((&raw const (*(&raw const (*__param_state).x as *const gzFile_s)).have as *const u32) as *mut u32)) == -1: 1 else: 0) != 0) {
                        return -1
                    }

                    ((*__param_state).x.next = (*__param_state).out)

                    return 0

                },
                2 => {
                    ((*__local_strm).avail_out = (((((*__param_state).size as u32) << (1 as u32)) as u32)))

                    ((*__local_strm).next_out = (*__param_state).out)

                    if ((if gz_decomp(__param_state) == -1: 1 else: 0) != 0) {
                        return -1
                    }

                },
                _ => {
                    gz_error(__param_state, (-2 as i32), c"state corrupt".ptr)

                    return -1

                },
            }

            break

        }

        var __ci_expr_logic_1: i32 = 0

        if ((if (*(&raw const (*__param_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
            var __ci_expr_logic_0: i32

            if ((if not ((*__param_state).eof != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (*__local_strm).avail_in != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

        }

        if not ((__ci_expr_logic_1 != 0)) {
            break
        }
    }

    return 0

}

unsafe fn gz_skip(__param_state: *mut gz_state) -> i32 {
    var __local_n: u32

    loop {
        if ((*(&raw const (*__param_state).x as *const gzFile_s)).have != 0) {
            var __ci_expr_ternary_2: u32 = 0

            var __ci_expr_logic_1: i32

            var __ci_expr_logic_0: i32 = 0

            if ((if 4 == (sizeof[i64]() as usize): 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if (*(&raw const (*__param_state).x as *const gzFile_s)).have > gz_intmax(): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (((*(&raw const (*__param_state).x as *const gzFile_s)).have as i64)) > (*__param_state).skip: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_ternary_2 = (((*__param_state).skip as u32)))
            } else {
                (__ci_expr_ternary_2 = (*(&raw const (*__param_state).x as *const gzFile_s)).have)
            }

            (__local_n = __ci_expr_ternary_2)


            ((*__param_state).x.have = ((*(&raw const (*__param_state).x as *const gzFile_s)).have -% __local_n))

            ((*__param_state).x.next = (*(&raw const (*__param_state).x as *const gzFile_s)).next + (__local_n as usize))

            ((*__param_state).x.pos = (*(&raw const (*__param_state).x as *const gzFile_s)).pos + __local_n)

            ((*__param_state).skip = (*__param_state).skip - __local_n)

        } else {
            var __ci_expr_logic_3: i32 = 0

            if ((*__param_state).eof != 0) {
                (__ci_expr_logic_3 = (if (if (*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                break
            }
            if ((if gz_fetch(__param_state) == -1: 1 else: 0) != 0) {
                return -1
            }


        }

        if not (((*__param_state).skip != 0)) {
            break
        }
    }

    return 0

}

unsafe fn gz_read(__param_state: *mut gz_state, __param_buf: *mut c_void, __param_len: u64) -> u64 {
    var __local_buf = __param_buf
    var __local_len = __param_len
    var __local_got: u64

    var __local_n: u32

    var __local_err: i32

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return ((0 as u64))
    }

    var __ci_expr_logic_0: i32 = 0

    if ((*__param_state).skip != 0) {
        (__ci_expr_logic_0 = (if (if gz_skip(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((0 as u64))
    }


    (__local_got = ((0 as u64)))

    (__local_err = ((0 as i32)))

    loop {
        (__local_n = ((-1 as u32)))

        if ((if __local_n > __local_len: 1 else: 0) != 0) {
            (__local_n = ((__local_len as u32)))
        }

        if ((*(&raw const (*__param_state).x as *const gzFile_s)).have != 0) {
            if ((if (*(&raw const (*__param_state).x as *const gzFile_s)).have < __local_n: 1 else: 0) != 0) {
                (__local_n = (*(&raw const (*__param_state).x as *const gzFile_s)).have)
            }

            with_memcpy((__local_buf as *mut u8), (((*(&raw const (*__param_state).x as *const gzFile_s)).next as *const c_void) as *const u8), ((__local_n as u64) as i64))

            ((*__param_state).x.next = (*(&raw const (*__param_state).x as *const gzFile_s)).next + (__local_n as usize))

            ((*__param_state).x.have = ((*(&raw const (*__param_state).x as *const gzFile_s)).have -% __local_n))

            if ((if (*__param_state).err != 0: 1 else: 0) != 0) {
                (__local_err = ((-1 as i32)))
            }

        } else {
            var __ci_expr_logic_2: i32 = 0

            if ((*__param_state).eof != 0) {
                (__ci_expr_logic_2 = (if (if (*(&raw const (*__param_state).strm as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                break
            }
            var __ci_expr_logic_3: i32

            if ((if (*__param_state).how == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if __local_n < (((*__param_state).size as u32) << (1 as u32)): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                var __ci_expr_logic_4: i32 = 0

                if ((if gz_fetch(__param_state) == -1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if (*(&raw const (*__param_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_4 != 0) {
                    (__local_err = ((-1 as i32)))
                }


                var __ci_expr_logic_1: i32 = 0

                if (__local_len != 0) {
                    (__ci_expr_logic_1 = (if (if not (__local_err != 0): 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    continue
                }
                break


            }
            if ((if (*__param_state).how == 1: 1 else: 0) != 0) {
                (__local_err = ((gz_load(__param_state, (__local_buf as *mut u8), __local_n, (&raw mut __local_n as *mut u32)) as i32)))
            } else {
                ((*__param_state).strm.avail_out = __local_n)

                ((*__param_state).strm.next_out = ((__local_buf as *mut u8)))

                (__local_err = ((gz_decomp(__param_state) as i32)))

                (__local_n = (*(&raw const (*__param_state).x as *const gzFile_s)).have)

                ((*__param_state).x.have = ((0 as u32)))

            }


        }

        (__local_len = (__local_len -% __local_n))

        (__local_buf = ((((__local_buf as *mut c_char) + (__local_n as usize)) as *mut c_void)))

        (__local_got = (__local_got +% __local_n))

        ((*__param_state).x.pos = (*(&raw const (*__param_state).x as *const gzFile_s)).pos + __local_n)

        var __ci_expr_logic_1: i32 = 0

        if (__local_len != 0) {
            (__ci_expr_logic_1 = (if (if not (__local_err != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_1 != 0)) {
            break
        }
    }

    var __ci_expr_logic_5: i32 = 0

    if (__local_len != 0) {
        (__ci_expr_logic_5 = (if (*__param_state).eof != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        ((*__param_state).past = ((1 as i32)))
    }


    return __local_got

}
