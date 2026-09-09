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
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.crc32
use std.zlib.inftrees

pub unsafe fn adler32(__param_adler: c_ulong, __param_buf: *const u8, __param_len: c_uint) -> c_ulong {
    return adler32_z(__param_adler, __param_buf, (__param_len as c_ulong))

}

pub unsafe fn adler32_z(__param_adler: c_ulong, __param_buf: *const u8, __param_len: c_ulong) -> c_ulong {
    var __local_adler = __param_adler
    var __local_buf = __param_buf
    var __local_len = __param_len
    var __local_sum2: c_ulong

    var __local_n: c_uint

    (__local_sum2 = ((((((__local_adler as c_ulong) >> (16 as c_uint)) as c_ulong) & (65535 as c_ulong)) as c_ulong)))

    (__local_adler = (__local_adler as c_ulong) & (65535 as c_ulong))

    if ((if __local_len == 1: 1 else: 0) != 0) {
        (__local_adler = (__local_adler +% ((unsafe __local_buf[0]) as c_int)))

        if ((if __local_adler >= 65521: 1 else: 0) != 0) {
            (__local_adler = (__local_adler -% 65521))
        }

        (__local_sum2 = (__local_sum2 +% __local_adler))

        if ((if __local_sum2 >= 65521: 1 else: 0) != 0) {
            (__local_sum2 = (__local_sum2 -% 65521))
        }

        return ((__local_adler as c_ulong) | (((__local_sum2 as c_ulong) << (16 as c_uint)) as c_ulong))

    }

    if ((if __local_buf == 0: 1 else: 0) != 0) {
        return 1
    }

    if ((if __local_len < 16: 1 else: 0) != 0) {
        while true {
            var __ci_expr_old_0: c_ulong = __local_len

            (__local_len = (__local_len -% 1))

            if (not (__ci_expr_old_0 != 0)) {
                break
            }

            var __ci_expr_old_1: *const u8 = __local_buf

            (__local_buf = __local_buf + 1)

            (__local_adler = (__local_adler +% ((unsafe *__ci_expr_old_1) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))

        }

        if ((if __local_adler >= 65521: 1 else: 0) != 0) {
            (__local_adler = (__local_adler -% 65521))
        }

        (__local_sum2 = __local_sum2 % 65521)

        return ((__local_adler as c_ulong) | (((__local_sum2 as c_ulong) << (16 as c_uint)) as c_ulong))

    }

    while ((if __local_len >= 5552: 1 else: 0) != 0) {
        (__local_len = (__local_len -% 5552))

        (__local_n = ((347 as c_uint)))

        loop {
            (__local_adler = (__local_adler +% ((unsafe __local_buf[0]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(0 + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(0 + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((0 + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(0 + 4)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((0 + 4) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((0 + 4) + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(((0 + 4) + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[8]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(8 + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(8 + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((8 + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(8 + 4)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((8 + 4) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((8 + 4) + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(((8 + 4) + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_buf = __local_buf + ((16 as isize) as usize))

            (__local_n = (__local_n -% 1))
            if not ((__local_n != 0)) {
                break
            }
        }

        (__local_adler = __local_adler % 65521)

        (__local_sum2 = __local_sum2 % 65521)

    }

    if (__local_len != 0) {
        while ((if __local_len >= 16: 1 else: 0) != 0) {
            (__local_len = (__local_len -% 16))

            (__local_adler = (__local_adler +% ((unsafe __local_buf[0]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(0 + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(0 + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((0 + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(0 + 4)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((0 + 4) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((0 + 4) + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(((0 + 4) + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[8]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(8 + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(8 + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((8 + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(8 + 4)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((8 + 4) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[((8 + 4) + 2)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_adler = (__local_adler +% ((unsafe __local_buf[(((8 + 4) + 2) + 1)]) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))


            (__local_buf = __local_buf + ((16 as isize) as usize))

        }

        while true {
            var __ci_expr_old_2: c_ulong = __local_len

            (__local_len = (__local_len -% 1))

            if (not (__ci_expr_old_2 != 0)) {
                break
            }

            var __ci_expr_old_3: *const u8 = __local_buf

            (__local_buf = __local_buf + 1)

            (__local_adler = (__local_adler +% ((unsafe *__ci_expr_old_3) as c_int)))

            (__local_sum2 = (__local_sum2 +% __local_adler))

        }

        (__local_adler = __local_adler % 65521)

        (__local_sum2 = __local_sum2 % 65521)

    }

    return ((__local_adler as c_ulong) | (((__local_sum2 as c_ulong) << (16 as c_uint)) as c_ulong))

}

pub fn adler32_combine(__param_adler1: c_ulong, __param_adler2: c_ulong, __param_len2: c_longlong) -> c_ulong {
    return adler32_combine_(__param_adler1, __param_adler2, __param_len2)

}

pub fn adler32_combine64(__param_adler1: c_ulong, __param_adler2: c_ulong, __param_len2: c_longlong) -> c_ulong {
    return adler32_combine_(__param_adler1, __param_adler2, __param_len2)

}

fn adler32_combine_(__param_adler1: c_ulong, __param_adler2: c_ulong, __param_len2: c_longlong) -> c_ulong {
    var __local_len2 = __param_len2
    var __local_sum1: c_ulong

    var __local_sum2: c_ulong

    var __local_rem: c_uint

    if ((if __local_len2 < 0: 1 else: 0) != 0) {
        return 4294967295
    }

    (__local_len2 = __local_len2 % 65521)

    (__local_rem = ((__local_len2 as c_uint)))

    (__local_sum1 = ((((__param_adler1 as c_ulong) & (65535 as c_ulong)) as c_ulong)))

    (__local_sum2 = ((((__local_rem as c_ulong) *% (__local_sum1 as c_ulong)) as c_ulong)))

    (__local_sum2 = __local_sum2 % 65521)

    (__local_sum1 = (__local_sum1 +% ((((((__param_adler2 as c_ulong) & (65535 as c_ulong)) as c_ulong) +% (65521 as c_ulong)) as c_ulong) -% (1 as c_ulong))))

    (__local_sum2 = (__local_sum2 +% ((((((((((__param_adler1 as c_ulong) >> (16 as c_uint)) as c_ulong) & (65535 as c_ulong)) as c_ulong) +% (((((__param_adler2 as c_ulong) >> (16 as c_uint)) as c_ulong) & (65535 as c_ulong)) as c_ulong)) as c_ulong) +% (65521 as c_ulong)) as c_ulong) -% (__local_rem as c_ulong))))

    if ((if __local_sum1 >= 65521: 1 else: 0) != 0) {
        (__local_sum1 = (__local_sum1 -% 65521))
    }

    if ((if __local_sum1 >= 65521: 1 else: 0) != 0) {
        (__local_sum1 = (__local_sum1 -% 65521))
    }

    if ((if __local_sum2 >= (((65521 as c_ulong) as c_ulong) << (1 as c_uint)): 1 else: 0) != 0) {
        (__local_sum2 = (__local_sum2 -% (((65521 as c_ulong) as c_ulong) << (1 as c_uint))))
    }

    if ((if __local_sum2 >= 65521: 1 else: 0) != 0) {
        (__local_sum2 = (__local_sum2 -% 65521))
    }

    return ((__local_sum1 as c_ulong) | (((__local_sum2 as c_ulong) << (16 as c_uint)) as c_ulong))

}
