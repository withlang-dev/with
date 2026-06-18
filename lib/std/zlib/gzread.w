// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32
use std.libc

pub unsafe fn gzread(__param_file: *mut gzFile_s, __param_buf: *mut c_void, __param_len: c_uint) -> c_int {
    var __local_len = __param_len
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    if ((if ((__local_len as c_int)) < 0: 1 else: 0) != 0) {
        gz_error(__local_state, (-2 as c_int), c"request does not fit in an int".ptr)

        return -1

    }

    (__local_len = ((gz_read(__local_state, __param_buf, (__local_len as c_ulong)) as c_uint)))

    if ((if __local_len == 0: 1 else: 0) != 0) {
        var __ci_expr_logic_2: c_int = 0

        if ((if __local_state.err != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            return -1
        }


        if (__local_state.again != 0) {
            gz_error(__local_state, (-1 as c_int), (strerror(((unsafe *(__error())) as c_int)) as *const i8))

            return -1

        }

    }

    return ((__local_len as c_int))

}

pub unsafe fn gzfread(__param_buf: *mut c_void, __param_size: c_ulong, __param_nitems: c_ulong, __param_file: *mut gzFile_s) -> c_ulong {
    var __local_len: c_ulong

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        return 0
    }

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
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
        (__ci_expr_ternary_3 = ((((gz_read(__local_state, __param_buf, __local_len) as c_ulong) / (__param_size as c_ulong)) as c_ulong)))
    } else {
        (__ci_expr_ternary_3 = ((0 as c_ulong)))
    }

    return __ci_expr_ternary_3


}

pub unsafe fn gzgets(__param_file: *mut gzFile_s, __param_buf: *mut i8, __param_len: c_int) -> *mut i8 {
    var __local_buf = __param_buf
    var __local_left: c_uint

    var __local_n: c_uint


    var __local_str: *mut c_char

    var __local_eol: *mut u8

    var __local_state: *mut gz_state

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

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
        return null
    }


    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        return null
    }

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_state.err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return null
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    var __ci_expr_logic_4: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_4 = (if (if gz_skip(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        return null
    }


    (__local_str = ((__local_buf as *mut c_char)))

    (__local_left = (((((__param_len as c_uint) as c_uint) -% (1 as c_uint)) as c_uint)))

    if (__local_left != 0) {
        loop {
            var __ci_expr_logic_6: c_int = 0

            if ((if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if gz_fetch(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                break
            }


            if ((if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
                (__local_state.past = ((1 as c_int)))

                break

            }

            var __ci_expr_ternary_7: c_uint = 0

            if ((if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have > __local_left: 1 else: 0) != 0) {
                (__ci_expr_ternary_7 = __local_left)
            } else {
                (__ci_expr_ternary_7 = (unsafe *(&raw const __local_state.x as *const gzFile_s)).have)
            }

            (__local_n = __ci_expr_ternary_7)


            (__local_eol = (((memchr((((unsafe *(&raw const __local_state.x as *const gzFile_s)).next as *const c_void) as *mut c_void), (10 as c_int), (__local_n as c_ulong)) as *const u8) as *mut u8)))

            if ((if __local_eol != null: 1 else: 0) != 0) {
                (__local_n = ((((((((__local_eol as usize) -% ((unsafe *(&raw const __local_state.x as *const gzFile_s)).next as usize)) / sizeof[u8]()) as c_uint) as c_uint) +% (1 as c_uint)) as c_uint)))
            }

            with_memcpy(((__local_buf as *mut c_void) as *i8), (((unsafe *(&raw const __local_state.x as *const gzFile_s)).next as *const c_void) as *i8), ((__local_n as c_ulong) as i64))

            (__local_state.x.have = ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have -% __local_n))

            (__local_state.x.next = (unsafe *(&raw const __local_state.x as *const gzFile_s)).next + (__local_n as usize))

            (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + __local_n)

            (__local_left = (__local_left -% __local_n))

            (__local_buf = __local_buf + (__local_n as usize))

            var __ci_expr_logic_5: c_int = 0

            if (__local_left != 0) {
                (__ci_expr_logic_5 = (if (if __local_eol == null: 1 else: 0) != 0: 1 else: 0))
            }

            if not ((__ci_expr_logic_5 != 0)) {
                break
            }
        }
    }

    if ((if __local_buf == __local_str: 1 else: 0) != 0) {
        return null
    }

    ((unsafe __local_buf[0]) = ((0 as c_char)))

    return __local_str

}

pub unsafe fn gzgetc(__param_file: *mut gzFile_s) -> c_int {
    var __local_buf: [1]u8

    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    if ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have != 0) {
        (__local_state.x.have = ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have -% 1))

        (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos + 1)

        var __ci_expr_old_2: *mut u8 = (unsafe *(&raw const __local_state.x as *const gzFile_s)).next

        (__local_state.x.next = (unsafe *(&raw const __local_state.x as *const gzFile_s)).next + 1)

        return (unsafe *__ci_expr_old_2)


    }

    var __ci_expr_ternary_3: c_int = 0

    if ((if gz_read(__local_state, (&__local_buf[0] as *mut u8), (1 as c_ulong)) < 1: 1 else: 0) != 0) {
        (__ci_expr_ternary_3 = ((-1 as c_int)))
    } else {
        (__ci_expr_ternary_3 = ((__local_buf[0] as c_int)))
    }

    return __ci_expr_ternary_3


}

pub unsafe fn gzungetc(__param_c: c_int, __param_file: *mut gzFile_s) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -1
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.how == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        gz_look(__local_state)
    }


    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    if ((if __local_state.err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __local_state.err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if (if not (__local_state.again != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -1
    }


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    var __ci_expr_logic_3: c_int = 0

    if (__local_state.skip != 0) {
        (__ci_expr_logic_3 = (if (if gz_skip(__local_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return -1
    }


    if ((if __param_c < 0: 1 else: 0) != 0) {
        return -1
    }

    if ((if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
        (__local_state.x.have = ((1 as c_uint)))

        (__local_state.x.next = (__local_state.out + (((__local_state.size as c_uint) << (1 as c_uint)) as usize)) - ((1 as isize) as usize))

        ((unsafe __local_state.x.next[0]) = ((__param_c as u8)))

        (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos - 1)

        (__local_state.past = ((0 as c_int)))

        return __param_c

    }

    if ((if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have == ((__local_state.size as c_uint) << (1 as c_uint)): 1 else: 0) != 0) {
        gz_error(__local_state, (-3 as c_int), c"out of room to push characters".ptr)

        return -1

    }

    if ((if (unsafe *(&raw const __local_state.x as *const gzFile_s)).next == __local_state.out: 1 else: 0) != 0) {
        var __local_src: *mut u8 = (__local_state.out + ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have as usize))

        var __local_dest: *mut u8 = (__local_state.out + (((__local_state.size as c_uint) << (1 as c_uint)) as usize))

        while ((if __local_src > __local_state.out: 1 else: 0) != 0) {
            (__local_dest = __local_dest - 1)

            (__local_src = __local_src - 1)

            ((unsafe *__local_dest) = (unsafe *__local_src))

        }

        (__local_state.x.next = __local_dest)

    }

    (__local_state.x.have = ((unsafe *(&raw const __local_state.x as *const gzFile_s)).have +% 1))

    (__local_state.x.next = (unsafe *(&raw const __local_state.x as *const gzFile_s)).next - 1)

    ((unsafe __local_state.x.next[0]) = ((__param_c as u8)))

    (__local_state.x.pos = (unsafe *(&raw const __local_state.x as *const gzFile_s)).pos - 1)

    (__local_state.past = ((0 as c_int)))

    return __param_c

}

pub unsafe fn gzdirect(__param_file: *mut gzFile_s) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_state.how == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if (unsafe *(&raw const __local_state.x as *const gzFile_s)).have == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        gz_look(__local_state)
    }


    return (if __local_state.direct == 1: 1 else: 0)

}

pub unsafe fn gzclose_r(__param_file: *mut gzFile_s) -> c_int {
    var __local_ret: c_int

    var __local_err: c_int


    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    if ((if __local_state.mode != 7247: 1 else: 0) != 0) {
        return -2
    }

    if (__local_state.size != 0) {
        inflateEnd(((&raw const __local_state.strm as *const z_stream_s) as *mut z_stream_s))

        with_free(((__local_state.out as *mut c_void) as *mut i8))

        with_free(((__local_state.in_ as *mut c_void) as *mut i8))

    }

    var __ci_expr_ternary_0: c_int = 0

    if ((if __local_state.err == -5: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((-5 as c_int)))
    } else {
        (__ci_expr_ternary_0 = ((0 as c_int)))
    }

    (__local_err = __ci_expr_ternary_0)


    gz_error(__local_state, (0 as c_int), (null as *const i8))

    with_free(((__local_state.path as *mut c_void) as *mut i8))

    (__local_ret = ((close(__local_state.fd) as c_int)))

    with_free(((__local_state as *mut c_void) as *mut i8))

    var __ci_expr_ternary_1: c_int = 0

    if (__local_ret != 0) {
        (__ci_expr_ternary_1 = ((-1 as c_int)))
    } else {
        (__ci_expr_ternary_1 = __local_err)
    }

    return __ci_expr_ternary_1


}

pub unsafe fn gzgetc_(__param_file: *mut gzFile_s) -> c_int {
    return gzgetc(__param_file)

}

unsafe fn gz_load(__param_state: *mut gz_state, __param_buf: *mut u8, __param_len: c_uint, __param_have: *mut c_uint) -> c_int {
    var __local_ret: c_int

    var __local_get: c_uint

    var __local_max: c_uint = (((((((-1 as c_uint) as c_uint) >> (2 as c_uint)) as c_uint) +% (1 as c_uint)) as c_uint))


    ((unsafe *__param_state).again = ((0 as c_int)))

    ((unsafe *(__error())) = ((0 as c_int)))

    ((unsafe *__param_have) = ((0 as c_uint)))

    loop {
        (__local_get = ((((__param_len as c_uint) -% ((unsafe *__param_have) as c_uint)) as c_uint)))

        if ((if __local_get > __local_max: 1 else: 0) != 0) {
            (__local_get = __local_max)
        }

        (__local_ret = ((read((unsafe *__param_state).fd, ((__param_buf + ((unsafe *__param_have) as usize)) as *mut c_void), (__local_get as c_ulong)) as c_int)))

        if ((if __local_ret <= 0: 1 else: 0) != 0) {
            break
        }

        ((unsafe *__param_have) = ((unsafe *__param_have) +% (__local_ret as c_uint)))

        if not (((if (unsafe *__param_have) < __param_len: 1 else: 0) != 0)) {
            break
        }
    }

    if ((if __local_ret < 0: 1 else: 0) != 0) {
        var __ci_expr_logic_0: c_int

        if ((if (unsafe *(__error())) == 35: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe *(__error())) == 35: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            ((unsafe *__param_state).again = ((1 as c_int)))

            if ((if (unsafe *__param_have) != 0: 1 else: 0) != 0) {
                return 0
            }

        }


        gz_error(__param_state, (-1 as c_int), (strerror(((unsafe *(__error())) as c_int)) as *const i8))

        return -1

    }

    if ((if __local_ret == 0: 1 else: 0) != 0) {
        ((unsafe *__param_state).eof = ((1 as c_int)))
    }

    return 0

}

unsafe fn gz_avail(__param_state: *mut gz_state) -> c_int {
    var __local_got: c_uint

    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__param_state).err != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_state).err != -5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -1
    }


    if ((if (unsafe *__param_state).eof == 0: 1 else: 0) != 0) {
        if (__local_strm.avail_in != 0) {
            var __local_p: *mut u8 = (unsafe *__param_state).in_

            var __local_q: *const u8 = ((__local_strm.next_in as *const u8))

            if ((if __local_q != __local_p: 1 else: 0) != 0) {
                var __local_n: c_uint = __local_strm.avail_in

                loop {
                    var __ci_expr_old_1: *mut u8 = __local_p

                    (__local_p = __local_p + 1)

                    var __ci_expr_old_2: *const u8 = __local_q

                    (__local_q = __local_q + 1)

                    ((unsafe *__ci_expr_old_1) = (unsafe *__ci_expr_old_2))


                    (__local_n = (__local_n -% 1))
                    if not ((__local_n != 0)) {
                        break
                    }
                }

            }

        }

        if ((if gz_load(__param_state, ((unsafe *__param_state).in_ + (__local_strm.avail_in as usize)), ((((unsafe *__param_state).size as c_uint) -% (__local_strm.avail_in as c_uint)) as c_uint), (&raw mut __local_got as *mut c_uint)) == -1: 1 else: 0) != 0) {
            return -1
        }

        (__local_strm.avail_in = (__local_strm.avail_in +% __local_got))

        (__local_strm.next_in = (unsafe *__param_state).in_)

    }

    return 0

}

unsafe fn gz_look(__param_state: *mut gz_state) -> c_int {
    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    if ((if (unsafe *__param_state).size == 0: 1 else: 0) != 0) {
        ((unsafe *__param_state).in_ = (((with_alloc((((unsafe *__param_state).want as c_ulong) as i64)) as *mut c_void) as *mut u8)))

        ((unsafe *__param_state).out = (((with_alloc((((((unsafe *__param_state).want as c_uint) << (1 as c_uint)) as c_ulong) as i64)) as *mut c_void) as *mut u8)))

        var __ci_expr_logic_0: c_int

        if ((if (unsafe *__param_state).in_ == null: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe *__param_state).out == null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            with_free((((unsafe *__param_state).out as *mut c_void) as *mut i8))

            with_free((((unsafe *__param_state).in_ as *mut c_void) as *mut i8))

            gz_error(__param_state, (-4 as c_int), c"out of memory".ptr)

            return -1

        }


        ((unsafe *__param_state).size = (unsafe *__param_state).want)

        ((unsafe *__param_state).strm.zalloc = null)

        ((unsafe *__param_state).strm.zfree = null)

        ((unsafe *__param_state).strm.opaque_ = null)

        ((unsafe *__param_state).strm.avail_in = ((0 as c_uint)))

        ((unsafe *__param_state).strm.next_in = null)

        if ((if inflateInit2_(((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s), ((15 + 16) as c_int), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) != 0: 1 else: 0) != 0) {
            with_free((((unsafe *__param_state).out as *mut c_void) as *mut i8))

            with_free((((unsafe *__param_state).in_ as *mut c_void) as *mut i8))

            ((unsafe *__param_state).size = ((0 as c_uint)))

            gz_error(__param_state, (-4 as c_int), c"out of memory".ptr)

            return -1

        }

    }

    var __ci_expr_logic_1: c_int

    if ((if (unsafe *__param_state).direct == -1: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__param_state).junk == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        inflateReset(__local_strm)

        ((unsafe *__param_state).how = ((2 as c_int)))

        ((unsafe *__param_state).junk = (((if (unsafe *__param_state).junk != -1: 1 else: 0) as c_int)))

        ((unsafe *__param_state).direct = ((0 as c_int)))

        return 0

    }


    if ((if gz_avail(__param_state) == -1: 1 else: 0) != 0) {
        return -1
    }

    var __ci_expr_logic_3: c_int

    if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_2: c_int = 0

        if ((unsafe *__param_state).again != 0) {
            (__ci_expr_logic_2 = (if (if __local_strm.avail_in < 4: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        return 0
    }


    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    if ((if __local_strm.avail_in > 3: 1 else: 0) != 0) {
        (__ci_expr_logic_4 = (if (if (unsafe __local_strm.next_in[0]) == 31: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_logic_5 = (if (if (unsafe __local_strm.next_in[1]) == 139: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__ci_expr_logic_6 = (if (if (unsafe __local_strm.next_in[2]) == 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_7 = (if (if (unsafe __local_strm.next_in[3]) < 32: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        inflateReset(__local_strm)

        ((unsafe *__param_state).how = ((2 as c_int)))

        ((unsafe *__param_state).junk = ((1 as c_int)))

        ((unsafe *__param_state).direct = ((0 as c_int)))

        return 0

    }


    ((unsafe *__param_state).x.next = (unsafe *__param_state).out)

    with_memcpy((((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next as *mut c_void) as *i8), ((__local_strm.next_in as *const c_void) as *i8), ((__local_strm.avail_in as c_ulong) as i64))

    ((unsafe *__param_state).x.have = __local_strm.avail_in)

    (__local_strm.avail_in = ((0 as c_uint)))

    ((unsafe *__param_state).how = ((1 as c_int)))

    return 0

}

unsafe fn gz_decomp(__param_state: *mut gz_state) -> c_int {
    var __local_ret: c_int = ((0 as c_int))

    var __local_had: c_uint

    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    (__local_had = __local_strm.avail_out)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if gz_avail(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_ret = (unsafe *__param_state).err)

            break

        }


        if ((if __local_strm.avail_in == 0: 1 else: 0) != 0) {
            if ((if not ((unsafe *__param_state).again != 0): 1 else: 0) != 0) {
                gz_error(__param_state, (-5 as c_int), c"unexpected end of file".ptr)
            }

            break

        }

        (__local_ret = ((inflate(__local_strm, (0 as c_int)) as c_int)))

        if ((if __local_strm.avail_out < __local_had: 1 else: 0) != 0) {
            ((unsafe *__param_state).junk = ((0 as c_int)))
        }

        var __ci_expr_logic_2: c_int

        if ((if __local_ret == -2: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_ret == 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            gz_error(__param_state, (-2 as c_int), c"internal error: inflate stream corrupt".ptr)

            break

        }


        if ((if __local_ret == -4: 1 else: 0) != 0) {
            gz_error(__param_state, (-4 as c_int), c"out of memory".ptr)

            break

        }

        if ((if __local_ret == -3: 1 else: 0) != 0) {
            if ((if (unsafe *__param_state).junk == 1: 1 else: 0) != 0) {
                (__local_strm.avail_in = ((0 as c_uint)))

                ((unsafe *__param_state).eof = ((1 as c_int)))

                ((unsafe *__param_state).how = ((0 as c_int)))

                (__local_ret = ((0 as c_int)))

                break

            }

            var __ci_expr_ternary_3: *mut c_char = null

            if ((if __local_strm.msg == null: 1 else: 0) != 0) {
                (__ci_expr_ternary_3 = (("compressed data error" as *mut c_char)))
            } else {
                (__ci_expr_ternary_3 = ((__local_strm.msg as *mut c_char)))
            }

            gz_error(__param_state, (-3 as c_int), (__ci_expr_ternary_3 as *const i8))


            break

        }

        var __ci_expr_logic_0: c_int = 0

        if (__local_strm.avail_out != 0) {
            (__ci_expr_logic_0 = (if (if __local_ret != 1: 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    ((unsafe *__param_state).x.have = ((((__local_had as c_uint) -% (__local_strm.avail_out as c_uint)) as c_uint)))

    ((unsafe *__param_state).x.next = __local_strm.next_out - ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have as usize))

    if ((if __local_ret == 1: 1 else: 0) != 0) {
        ((unsafe *__param_state).junk = ((0 as c_int)))

        ((unsafe *__param_state).how = ((0 as c_int)))

        return 0

    }

    var __ci_expr_ternary_4: c_int = 0

    if ((if __local_ret != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_4 = ((-1 as c_int)))
    } else {
        (__ci_expr_ternary_4 = ((0 as c_int)))
    }

    return __ci_expr_ternary_4


}

unsafe fn gz_fetch(__param_state: *mut gz_state) -> c_int {
    var __local_strm: *mut z_stream_s = (((&raw const (unsafe *__param_state).strm as *const z_stream_s) as *mut z_stream_s))

    loop {
        while true {
            match (unsafe *__param_state).how {
                0 => {
                    if ((if gz_look(__param_state) == -1: 1 else: 0) != 0) {
                        return -1
                    }

                    if ((if (unsafe *__param_state).how == 0: 1 else: 0) != 0) {
                        return 0
                    }

                },
                1 => {
                    if ((if gz_load(__param_state, (unsafe *__param_state).out, ((((unsafe *__param_state).size as c_uint) << (1 as c_uint)) as c_uint), ((&raw const (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have as *const c_uint) as *mut c_uint)) == -1: 1 else: 0) != 0) {
                        return -1
                    }

                    ((unsafe *__param_state).x.next = (unsafe *__param_state).out)

                    return 0

                },
                2 => {
                    (__local_strm.avail_out = (((((unsafe *__param_state).size as c_uint) << (1 as c_uint)) as c_uint)))

                    (__local_strm.next_out = (unsafe *__param_state).out)

                    if ((if gz_decomp(__param_state) == -1: 1 else: 0) != 0) {
                        return -1
                    }

                },
                _ => {
                    gz_error(__param_state, (-2 as c_int), c"state corrupt".ptr)

                    return -1

                },
            }

            break

        }

        var __ci_expr_logic_1: c_int = 0

        if ((if (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int

            if ((if not ((unsafe *__param_state).eof != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if __local_strm.avail_in != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

        }

        if not ((__ci_expr_logic_1 != 0)) {
            break
        }
    }

    return 0

}

unsafe fn gz_skip(__param_state: *mut gz_state) -> c_int {
    var __local_n: c_uint

    loop {
        if ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have != 0) {
            var __ci_expr_ternary_2: c_uint = 0

            var __ci_expr_logic_1: c_int

            var __ci_expr_logic_0: c_int = 0

            if ((if 4 == sizeof[c_longlong](): 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have > gz_intmax(): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have as c_longlong)) > (unsafe *__param_state).skip: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_ternary_2 = (((unsafe *__param_state).skip as c_uint)))
            } else {
                (__ci_expr_ternary_2 = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have)
            }

            (__local_n = __ci_expr_ternary_2)


            ((unsafe *__param_state).x.have = ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have -% __local_n))

            ((unsafe *__param_state).x.next = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next + (__local_n as usize))

            ((unsafe *__param_state).x.pos = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).pos + __local_n)

            ((unsafe *__param_state).skip = (unsafe *__param_state).skip - __local_n)

        } else {
            var __ci_expr_logic_3: c_int = 0

            if ((unsafe *__param_state).eof != 0) {
                (__ci_expr_logic_3 = (if (if (unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                break
            }
            if ((if gz_fetch(__param_state) == -1: 1 else: 0) != 0) {
                return -1
            }


        }

        if not (((unsafe *__param_state).skip != 0)) {
            break
        }
    }

    return 0

}

unsafe fn gz_read(__param_state: *mut gz_state, __param_buf: *mut c_void, __param_len: c_ulong) -> c_ulong {
    var __local_buf = __param_buf
    var __local_len = __param_len
    var __local_got: c_ulong

    var __local_n: c_uint

    var __local_err: c_int

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return 0
    }

    var __ci_expr_logic_0: c_int = 0

    if ((unsafe *__param_state).skip != 0) {
        (__ci_expr_logic_0 = (if (if gz_skip(__param_state) == -1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0
    }


    (__local_got = ((0 as c_ulong)))

    (__local_err = ((0 as c_int)))

    loop {
        (__local_n = ((-1 as c_uint)))

        if ((if __local_n > __local_len: 1 else: 0) != 0) {
            (__local_n = ((__local_len as c_uint)))
        }

        if ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have != 0) {
            if ((if (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have < __local_n: 1 else: 0) != 0) {
                (__local_n = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have)
            }

            with_memcpy((__local_buf as *i8), (((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next as *const c_void) as *i8), ((__local_n as c_ulong) as i64))

            ((unsafe *__param_state).x.next = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).next + (__local_n as usize))

            ((unsafe *__param_state).x.have = ((unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have -% __local_n))

            if ((if (unsafe *__param_state).err != 0: 1 else: 0) != 0) {
                (__local_err = ((-1 as c_int)))
            }

        } else {
            var __ci_expr_logic_2: c_int = 0

            if ((unsafe *__param_state).eof != 0) {
                (__ci_expr_logic_2 = (if (if (unsafe *(&raw const (unsafe *__param_state).strm as *const z_stream_s)).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                break
            }
            var __ci_expr_logic_3: c_int

            if ((if (unsafe *__param_state).how == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if __local_n < (((unsafe *__param_state).size as c_uint) << (1 as c_uint)): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                var __ci_expr_logic_4: c_int = 0

                if ((if gz_fetch(__param_state) == -1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_4 != 0) {
                    (__local_err = ((-1 as c_int)))
                }


                var __ci_expr_logic_1: c_int = 0

                if (__local_len != 0) {
                    (__ci_expr_logic_1 = (if (if not (__local_err != 0): 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    continue
                }
                break


            }
            if ((if (unsafe *__param_state).how == 1: 1 else: 0) != 0) {
                (__local_err = ((gz_load(__param_state, (__local_buf as *mut u8), __local_n, (&raw mut __local_n as *mut c_uint)) as c_int)))
            } else {
                ((unsafe *__param_state).strm.avail_out = __local_n)

                ((unsafe *__param_state).strm.next_out = ((__local_buf as *mut u8)))

                (__local_err = ((gz_decomp(__param_state) as c_int)))

                (__local_n = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).have)

                ((unsafe *__param_state).x.have = ((0 as c_uint)))

            }


        }

        (__local_len = (__local_len -% __local_n))

        (__local_buf = ((((__local_buf as *mut c_char) + (__local_n as usize)) as *mut c_void)))

        (__local_got = (__local_got +% __local_n))

        ((unsafe *__param_state).x.pos = (unsafe *(&raw const (unsafe *__param_state).x as *const gzFile_s)).pos + __local_n)

        var __ci_expr_logic_1: c_int = 0

        if (__local_len != 0) {
            (__ci_expr_logic_1 = (if (if not (__local_err != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_1 != 0)) {
            break
        }
    }

    var __ci_expr_logic_5: c_int = 0

    if (__local_len != 0) {
        (__ci_expr_logic_5 = (if (unsafe *__param_state).eof != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        ((unsafe *__param_state).past = ((1 as c_int)))
    }


    return __local_got

}
