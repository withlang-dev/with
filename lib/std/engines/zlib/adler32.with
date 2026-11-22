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
use std.engines.zlib.crc32
use std.engines.zlib.inftrees

// contract: unproved:1:read only
pub unsafe fn adler32(__param_adler: u64, __param_buf: *const u8, __param_len: u32) -> u64 {
    return adler32_z(__param_adler, __param_buf, (__param_len as u64))

}

// contract: unproved:1:read only
pub unsafe fn adler32_z(__param_adler: u64, __param_buf: *const u8, __param_len: u64) -> u64 {
    var __local_adler = __param_adler
    var __local_buf = __param_buf
    var __local_len = __param_len
    var __local_sum2: u64

    var __local_n: u32

    (__local_sum2 = ((((((__local_adler as u64) >> (16 as u32)) as u64) & (65535 as u64)) as u64)))

    (__local_adler = (__local_adler as u64) & (65535 as u64))

    if (__local_len == 1) {
        (__local_adler = (__local_adler +% ((__local_buf[0]) as u64)))

        if (__local_adler >= 65521) {
            (__local_adler = (__local_adler -% 65521))
        }

        (__local_sum2 = (__local_sum2 +% __local_adler))

        if (__local_sum2 >= 65521) {
            (__local_sum2 = (__local_sum2 -% 65521))
        }

        return ((__local_adler as u64) | (((__local_sum2 as u64) << (16 as u32)) as u64))

    }

    if (__local_buf == 0) {
        return ((1 as u64))
    }

    if (__local_len < 16) {
        while true {
            var __ci_expr_old_0: u64 = __local_len

            (__local_len = (__local_len -% 1))

            if (not __ci_expr_old_0) {
                break
            }

            var __ci_expr_old_1: *const u8 = __local_buf

            (__local_buf = __local_buf + 1)

            (__local_adler = (__local_adler +% ((*__ci_expr_old_1) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))

        }

        if (__local_adler >= 65521) {
            (__local_adler = (__local_adler -% 65521))
        }

        (__local_sum2 = __local_sum2 % 65521)

        return ((__local_adler as u64) | (((__local_sum2 as u64) << (16 as u32)) as u64))

    }

    while (__local_len >= 5552) {
        (__local_len = (__local_len -% 5552))

        (__local_n = ((347 as u32)))

        loop {
            (__local_adler = (__local_adler +% ((__local_buf[0]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(0 + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[(0 + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((0 + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))





            (__local_adler = (__local_adler +% ((__local_buf[(0 + 4)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((0 + 4) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[((0 + 4) + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(((0 + 4) + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))






            (__local_adler = (__local_adler +% ((__local_buf[8]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(8 + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[(8 + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((8 + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))





            (__local_adler = (__local_adler +% ((__local_buf[(8 + 4)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((8 + 4) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[((8 + 4) + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(((8 + 4) + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))







            (__local_buf = __local_buf + ((16 as isize) as usize))

            (__local_n = (__local_n -% 1))
            if not (__local_n) {
                break
            }
        }

        (__local_adler = __local_adler % 65521)

        (__local_sum2 = __local_sum2 % 65521)

    }

    if __local_len {
        while (__local_len >= 16) {
            (__local_len = (__local_len -% 16))

            (__local_adler = (__local_adler +% ((__local_buf[0]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(0 + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[(0 + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((0 + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))





            (__local_adler = (__local_adler +% ((__local_buf[(0 + 4)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((0 + 4) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[((0 + 4) + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(((0 + 4) + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))






            (__local_adler = (__local_adler +% ((__local_buf[8]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(8 + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[(8 + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((8 + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))





            (__local_adler = (__local_adler +% ((__local_buf[(8 + 4)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[((8 + 4) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))




            (__local_adler = (__local_adler +% ((__local_buf[((8 + 4) + 2)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))



            (__local_adler = (__local_adler +% ((__local_buf[(((8 + 4) + 2) + 1)]) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))







            (__local_buf = __local_buf + ((16 as isize) as usize))

        }

        while true {
            var __ci_expr_old_2: u64 = __local_len

            (__local_len = (__local_len -% 1))

            if (not __ci_expr_old_2) {
                break
            }

            var __ci_expr_old_3: *const u8 = __local_buf

            (__local_buf = __local_buf + 1)

            (__local_adler = (__local_adler +% ((*__ci_expr_old_3) as u64)))

            (__local_sum2 = (__local_sum2 +% __local_adler))

        }

        (__local_adler = __local_adler % 65521)

        (__local_sum2 = __local_sum2 % 65521)

    }

    return ((__local_adler as u64) | (((__local_sum2 as u64) << (16 as u32)) as u64))

}

pub fn adler32_combine(__param_adler1: u64, __param_adler2: u64, __param_len2: i64) -> u64 {
    return adler32_combine_(__param_adler1, __param_adler2, __param_len2)

}

pub fn adler32_combine64(__param_adler1: u64, __param_adler2: u64, __param_len2: i64) -> u64 {
    return adler32_combine_(__param_adler1, __param_adler2, __param_len2)

}

fn adler32_combine_(__param_adler1: u64, __param_adler2: u64, __param_len2: i64) -> u64 {
    var __local_len2 = __param_len2
    var __local_sum1: u64

    var __local_sum2: u64

    var __local_rem: u32

    if (__local_len2 < 0) {
        return 4294967295
    }

    (__local_len2 = __local_len2 % 65521)

    (__local_rem = ((__local_len2 as u32)))

    (__local_sum1 = ((((__param_adler1 as u64) & (65535 as u64)) as u64)))

    (__local_sum2 = ((((__local_rem as u64) *% (__local_sum1 as u64)) as u64)))

    (__local_sum2 = __local_sum2 % 65521)

    (__local_sum1 = (__local_sum1 +% ((((((__param_adler2 as u64) & (65535 as u64)) as u64) +% (65521 as u64)) as u64) -% (1 as u64))))

    (__local_sum2 = (__local_sum2 +% ((((((((((__param_adler1 as u64) >> (16 as u32)) as u64) & (65535 as u64)) as u64) +% (((((__param_adler2 as u64) >> (16 as u32)) as u64) & (65535 as u64)) as u64)) as u64) +% (65521 as u64)) as u64) -% (__local_rem as u64))))

    if (__local_sum1 >= 65521) {
        (__local_sum1 = (__local_sum1 -% 65521))
    }

    if (__local_sum1 >= 65521) {
        (__local_sum1 = (__local_sum1 -% 65521))
    }

    if (__local_sum2 >= ((65521 as u64) << (1 as u32))) {
        (__local_sum2 = (__local_sum2 -% ((65521 as u64) << (1 as u32))))
    }

    if (__local_sum2 >= 65521) {
        (__local_sum2 = (__local_sum2 -% 65521))
    }

    return ((__local_sum1 as u64) | (((__local_sum2 as u64) << (16 as u32)) as u64))

}
