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
use std.zlib.adler32
use std.zlib.crc32
use std.libc

unsafe fn test_compress(__param_compr: *mut u8, __param_comprLen: c_ulong, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_err: c_int

    var __local_len: c_ulong = ((((strlen((&hello[0] as *mut c_char)) as c_ulong) +% (1 as c_ulong)) as c_ulong))

    (__local_err = ((compress(__param_compr, (&raw mut __param_comprLen as *mut c_ulong), (&hello[0] as *const u8), __local_len) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "compress", __local_err)

        exit((1 as c_int))

    }


    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_err = ((uncompress(__param_uncompr, (&raw mut __param_uncomprLen as *mut c_ulong), (__param_compr as *const u8), __param_comprLen) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "uncompress", __local_err)

        exit((1 as c_int))

    }


    if (strcmp((__param_uncompr as *mut c_char), (&hello[0] as *mut c_char)) != 0) {
        fprintf(__stderrp, c"bad uncompress\n".ptr)

        exit((1 as c_int))

    } else {
        printf(c"uncompress(): %s\n".ptr, (__param_uncompr as *mut c_char))

    }

}

unsafe fn test_gzio(__param_fname: *const i8, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_err: c_int

    var __local_len: c_int = ((((strlen((&hello[0] as *mut c_char)) as c_int) + 1) as c_int))

    var __local_file: *mut gzFile_s

    var __local_pos: c_longlong

    (__local_file = gzopen(__param_fname, c"wb".ptr))

    if ((if __local_file == null: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzopen error\n".ptr)

        exit((1 as c_int))

    }

    gzputc(__local_file, (104 as c_int))

    if ((if gzputs(__local_file, c"ello".ptr) != 4: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzputs err: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut c_int)))

        exit((1 as c_int))

    }

    if ((if gzprintf(__local_file, c", %s!".ptr, "hello") != 8: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzprintf err: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut c_int)))

        exit((1 as c_int))

    }

    gzseek(__local_file, (1 as c_longlong), (1 as c_int))

    gzclose(__local_file)

    (__local_file = gzopen(__param_fname, c"rb".ptr))

    if ((if __local_file == null: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzopen error\n".ptr)

        exit((1 as c_int))

    }

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    if ((if gzread(__local_file, (__param_uncompr as *mut c_void), (__param_uncomprLen as c_uint)) != __local_len: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzread err: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut c_int)))

        exit((1 as c_int))

    }

    if (strcmp((__param_uncompr as *mut c_char), (&hello[0] as *mut c_char)) != 0) {
        fprintf(__stderrp, c"bad gzread: %s\n".ptr, (__param_uncompr as *mut c_char))

        exit((1 as c_int))

    } else {
        printf(c"gzread(): %s\n".ptr, (__param_uncompr as *mut c_char))

    }

    (__local_pos = ((gzseek(__local_file, (-8 as c_longlong), (1 as c_int)) as c_longlong)))

    var __ci_expr_logic_0: c_int

    if ((if __local_pos != 6: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if gztell(__local_file) != __local_pos: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        fprintf(__stderrp, c"gzseek error, pos=%ld, gztell=%ld\n".ptr, (__local_pos as c_long), (gztell(__local_file) as c_long))

        exit((1 as c_int))

    }


    var __ci_expr_ternary_4: c_int = 0

    if (__local_file.have != 0) {
        var __ci_expr_old_1: c_uint = __local_file.have

        (__local_file.have = (__local_file.have -% 1))

        var __ci_expr_old_2: c_longlong = __local_file.pos

        (__local_file.pos = __local_file.pos + 1)

        var __ci_expr_old_3: *mut u8 = __local_file.next

        (__local_file.next = __local_file.next + 1)

        (__ci_expr_ternary_4 = (((unsafe *__ci_expr_old_3) as c_int)))

    } else {
        (__ci_expr_ternary_4 = ((gzgetc(__local_file) as c_int)))
    }

    if ((if __ci_expr_ternary_4 != 32: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzgetc error\n".ptr)

        exit((1 as c_int))

    }


    if ((if gzungetc((32 as c_int), __local_file) != 32: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzungetc error\n".ptr)

        exit((1 as c_int))

    }

    gzgets(__local_file, (__param_uncompr as *mut c_char), (__param_uncomprLen as c_int))

    if ((if strlen((__param_uncompr as *mut c_char)) != 7: 1 else: 0) != 0) {
        fprintf(__stderrp, c"gzgets err after gzseek: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut c_int)))

        exit((1 as c_int))

    }

    if (strcmp((__param_uncompr as *mut c_char), (((&hello[0] as *mut c_char) + ((6 as isize) as usize)) as *const i8)) != 0) {
        fprintf(__stderrp, c"bad gzgets after gzseek\n".ptr)

        exit((1 as c_int))

    } else {
        printf(c"gzgets() after gzseek: %s\n".ptr, (__param_uncompr as *mut c_char))

    }

    gzclose(__local_file)

}

unsafe fn test_deflate(__param_compr: *mut u8, __param_comprLen: c_ulong) -> Unit {
    var __local_c_stream: z_stream_s

    var __local_err: c_int

    var __local_len: c_ulong = ((((strlen((&hello[0] as *mut c_char)) as c_ulong) +% (1 as c_ulong)) as c_ulong))

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = ((0 as *mut c_void)))

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (-1 as c_int), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateInit", __local_err)

        exit((1 as c_int))

    }


    (__local_c_stream.next_in = (&hello[0] as *mut u8))

    (__local_c_stream.next_out = __param_compr)

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *(&raw const __local_c_stream as *const z_stream_s)).total_in != __local_len: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *(&raw const __local_c_stream as *const z_stream_s)).total_out < __param_comprLen: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_c_stream.avail_out = ((1 as c_uint)))

        (__local_c_stream.avail_in = (unsafe *(&raw const __local_c_stream as *const z_stream_s)).avail_out)

        (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

        if ((if __local_err != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

            exit((1 as c_int))

        }

    }

    while true {
        (__local_c_stream.avail_out = ((1 as c_uint)))

        (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as c_int)) as c_int)))

        if ((if __local_err == 1: 1 else: 0) != 0) {
            break
        }

        if ((if __local_err != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

            exit((1 as c_int))

        }


    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateEnd", __local_err)

        exit((1 as c_int))

    }


}

unsafe fn test_inflate(__param_compr: *mut u8, __param_comprLen: c_ulong, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_err: c_int

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = ((0 as *mut c_void)))

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((0 as c_uint)))

    (__local_d_stream.next_out = __param_uncompr)

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateInit", __local_err)

        exit((1 as c_int))

    }


    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *(&raw const __local_d_stream as *const z_stream_s)).total_out < __param_uncomprLen: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *(&raw const __local_d_stream as *const z_stream_s)).total_in < __param_comprLen: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_d_stream.avail_out = ((1 as c_uint)))

        (__local_d_stream.avail_in = (unsafe *(&raw const __local_d_stream as *const z_stream_s)).avail_out)

        (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

        if ((if __local_err == 1: 1 else: 0) != 0) {
            break
        }

        if ((if __local_err != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"%s error: %d\n".ptr, "inflate", __local_err)

            exit((1 as c_int))

        }

    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateEnd", __local_err)

        exit((1 as c_int))

    }


    if (strcmp((__param_uncompr as *mut c_char), (&hello[0] as *mut c_char)) != 0) {
        fprintf(__stderrp, c"bad inflate\n".ptr)

        exit((1 as c_int))

    } else {
        printf(c"inflate(): %s\n".ptr, (__param_uncompr as *mut c_char))

    }

}

unsafe fn test_large_deflate(__param_compr: *mut u8, __param_comprLen: c_ulong, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_c_stream: z_stream_s

    var __local_err: c_int

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = ((0 as *mut c_void)))

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (1 as c_int), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateInit", __local_err)

        exit((1 as c_int))

    }


    (__local_c_stream.next_out = __param_compr)

    (__local_c_stream.avail_out = ((__param_comprLen as c_uint)))

    (__local_c_stream.next_in = __param_uncompr)

    (__local_c_stream.avail_in = ((__param_uncomprLen as c_uint)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

        exit((1 as c_int))

    }


    if ((if (unsafe *(&raw const __local_c_stream as *const z_stream_s)).avail_in != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"deflate not greedy\n".ptr)

        exit((1 as c_int))

    }

    deflateParams((&raw mut __local_c_stream as *mut z_stream_s), (0 as c_int), (0 as c_int))

    (__local_c_stream.next_in = __param_compr)

    (__local_c_stream.avail_in = (((((__param_uncomprLen as c_uint) as c_uint) / (2 as c_uint)) as c_uint)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

        exit((1 as c_int))

    }


    deflateParams((&raw mut __local_c_stream as *mut z_stream_s), (9 as c_int), (1 as c_int))

    (__local_c_stream.next_in = __param_uncompr)

    (__local_c_stream.avail_in = ((__param_uncomprLen as c_uint)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

        exit((1 as c_int))

    }


    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as c_int)) as c_int)))

    if ((if __local_err != 1: 1 else: 0) != 0) {
        fprintf(__stderrp, c"deflate should report Z_STREAM_END\n".ptr)

        exit((1 as c_int))

    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateEnd", __local_err)

        exit((1 as c_int))

    }


}

unsafe fn test_large_inflate(__param_compr: *mut u8, __param_comprLen: c_ulong, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_err: c_int

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = ((0 as *mut c_void)))

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((__param_comprLen as c_uint)))

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateInit", __local_err)

        exit((1 as c_int))

    }


    while true {
        (__local_d_stream.next_out = __param_uncompr)

        (__local_d_stream.avail_out = ((__param_uncomprLen as c_uint)))

        (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

        if ((if __local_err == 1: 1 else: 0) != 0) {
            break
        }

        if ((if __local_err != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"%s error: %d\n".ptr, "large inflate", __local_err)

            exit((1 as c_int))

        }


    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateEnd", __local_err)

        exit((1 as c_int))

    }


    if ((if (unsafe *(&raw const __local_d_stream as *const z_stream_s)).total_out != ((((2 as c_ulong) *% (__param_uncomprLen as c_ulong)) as c_ulong) +% (((__param_uncomprLen as c_ulong) / (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
        fprintf(__stderrp, c"bad large inflate: %lu\n".ptr, (unsafe *(&raw const __local_d_stream as *const z_stream_s)).total_out)

        exit((1 as c_int))

    } else {
        printf(c"large_inflate(): OK\n".ptr)

    }

}

unsafe fn test_flush(__param_compr: *mut u8, __param_comprLen: *mut c_ulong) -> Unit {
    var __local_c_stream: z_stream_s

    var __local_err: c_int

    var __local_len: c_uint = (((((strlen((&hello[0] as *mut c_char)) as c_uint) as c_uint) +% (1 as c_uint)) as c_uint))

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = ((0 as *mut c_void)))

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (-1 as c_int), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateInit", __local_err)

        exit((1 as c_int))

    }


    (__local_c_stream.next_in = (&hello[0] as *mut u8))

    (__local_c_stream.next_out = __param_compr)

    (__local_c_stream.avail_in = ((3 as c_uint)))

    (__local_c_stream.avail_out = (((unsafe *__param_comprLen) as c_uint)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (3 as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

        exit((1 as c_int))

    }


    ((unsafe __param_compr[3]) = ((unsafe __param_compr[3]) +% 1))

    (__local_c_stream.avail_in = ((((__local_len as c_uint) -% (3 as c_uint)) as c_uint)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as c_int)) as c_int)))

    if ((if __local_err != 1: 1 else: 0) != 0) {
        if ((if __local_err != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"%s error: %d\n".ptr, "deflate", __local_err)

            exit((1 as c_int))

        }


    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateEnd", __local_err)

        exit((1 as c_int))

    }


    ((unsafe *__param_comprLen) = (unsafe *(&raw const __local_c_stream as *const z_stream_s)).total_out)

}

unsafe fn test_sync(__param_compr: *mut u8, __param_comprLen: c_ulong, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_err: c_int

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = ((0 as *mut c_void)))

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((2 as c_uint)))

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateInit", __local_err)

        exit((1 as c_int))

    }


    (__local_d_stream.next_out = __param_uncompr)

    (__local_d_stream.avail_out = ((__param_uncomprLen as c_uint)))

    (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflate", __local_err)

        exit((1 as c_int))

    }


    (__local_d_stream.avail_in = (((((__param_comprLen as c_uint) as c_uint) -% (2 as c_uint)) as c_uint)))

    (__local_err = ((inflateSync((&raw mut __local_d_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateSync", __local_err)

        exit((1 as c_int))

    }


    (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (4 as c_int)) as c_int)))

    if ((if __local_err != 1: 1 else: 0) != 0) {
        fprintf(__stderrp, c"inflate should report Z_STREAM_END\n".ptr)

        exit((1 as c_int))

    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateEnd", __local_err)

        exit((1 as c_int))

    }


    printf(c"after inflateSync(): hel%s\n".ptr, (__param_uncompr as *mut c_char))

}

unsafe fn test_dict_deflate(__param_compr: *mut u8, __param_comprLen: c_ulong) -> Unit {
    var __local_c_stream: z_stream_s

    var __local_err: c_int

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = ((0 as *mut c_void)))

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (9 as c_int), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateInit", __local_err)

        exit((1 as c_int))

    }


    (__local_err = ((deflateSetDictionary((&raw mut __local_c_stream as *mut z_stream_s), (&dictionary[0] as *const u8), (6 as c_uint)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateSetDictionary", __local_err)

        exit((1 as c_int))

    }


    (dictId = (unsafe *(&raw const __local_c_stream as *const z_stream_s)).adler)

    (__local_c_stream.next_out = __param_compr)

    (__local_c_stream.avail_out = ((__param_comprLen as c_uint)))

    (__local_c_stream.next_in = (&hello[0] as *mut u8))

    (__local_c_stream.avail_in = (((((strlen((&hello[0] as *mut c_char)) as c_uint) as c_uint) +% (1 as c_uint)) as c_uint)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as c_int)) as c_int)))

    if ((if __local_err != 1: 1 else: 0) != 0) {
        fprintf(__stderrp, c"deflate should report Z_STREAM_END\n".ptr)

        exit((1 as c_int))

    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "deflateEnd", __local_err)

        exit((1 as c_int))

    }


}

unsafe fn test_dict_inflate(__param_compr: *mut u8, __param_comprLen: c_ulong, __param_uncompr: *mut u8, __param_uncomprLen: c_ulong) -> Unit {
    var __local_err: c_int

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = ((0 as *mut c_void)))

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((__param_comprLen as c_uint)))

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as c_int)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateInit", __local_err)

        exit((1 as c_int))

    }


    (__local_d_stream.next_out = __param_uncompr)

    (__local_d_stream.avail_out = ((__param_uncomprLen as c_uint)))

    while true {
        (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as c_int)) as c_int)))

        if ((if __local_err == 1: 1 else: 0) != 0) {
            break
        }

        if ((if __local_err == 2: 1 else: 0) != 0) {
            if ((if (unsafe *(&raw const __local_d_stream as *const z_stream_s)).adler != dictId: 1 else: 0) != 0) {
                fprintf(__stderrp, c"unexpected dictionary".ptr)

                exit((1 as c_int))

            }

            (__local_err = ((inflateSetDictionary((&raw mut __local_d_stream as *mut z_stream_s), (&dictionary[0] as *const u8), (6 as c_uint)) as c_int)))

        }

        if ((if __local_err != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"%s error: %d\n".ptr, "inflate with dict", __local_err)

            exit((1 as c_int))

        }


    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as c_int)))

    if ((if __local_err != 0: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s error: %d\n".ptr, "inflateEnd", __local_err)

        exit((1 as c_int))

    }


    if (strcmp((__param_uncompr as *mut c_char), (&hello[0] as *mut c_char)) != 0) {
        fprintf(__stderrp, c"bad inflate with dict\n".ptr)

        exit((1 as c_int))

    } else {
        printf(c"inflate with dictionary: %s\n".ptr, (__param_uncompr as *mut c_char))

    }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    var __local_compr: *mut u8

    var __local_uncompr: *mut u8


    var __local_uncomprLen: c_ulong = ((20000 as c_ulong))

    var __local_comprLen: c_ulong = ((((3 as c_ulong) *% (__local_uncomprLen as c_ulong)) as c_ulong))

    var __local_myVersion: *const c_char = c"1.3.2".ptr

    if ((if (unsafe zlibVersion()[0]) != (unsafe __local_myVersion[0]): 1 else: 0) != 0) {
        fprintf(__stderrp, c"incompatible zlib version\n".ptr)

        exit((1 as c_int))

    } else {
        if ((if strcmp(zlibVersion(), c"1.3.2".ptr) != 0: 1 else: 0) != 0) {
            fprintf(__stderrp, c"warning: different zlib version linked: %s\n".ptr, zlibVersion())

        }
    }

    printf(c"zlib version %s = 0x%04x, compile flags = 0x%lx\n".ptr, "1.3.2", (4896 as c_uint), zlibCompileFlags())

    (__local_compr = (((with_alloc_zeroed(((__local_comprLen as c_uint) as i64), ((1 as c_ulong) as i64)) as *mut c_void) as *mut u8)))

    (__local_uncompr = (((with_alloc_zeroed(((__local_uncomprLen as c_uint) as i64), ((1 as c_ulong) as i64)) as *mut c_void) as *mut u8)))

    var __ci_expr_logic_0: c_int

    if ((if __local_compr == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_uncompr == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        printf(c"out of memory\n".ptr)

        exit((1 as c_int))

    }


    test_compress(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    var __ci_expr_ternary_1: *mut c_char = null

    if ((if __param_argc > 1: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = (((unsafe __param_argv[1]) as *mut c_char)))
    } else {
        (__ci_expr_ternary_1 = (("foo.gz" as *mut c_char)))
    }

    test_gzio((__ci_expr_ternary_1 as *const i8), __local_uncompr, __local_uncomprLen)


    test_deflate(__local_compr, __local_comprLen)

    test_inflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_large_deflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_large_inflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_flush(__local_compr, (&raw mut __local_comprLen as *mut c_ulong))

    test_sync(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    (__local_comprLen = ((((3 as c_ulong) *% (__local_uncomprLen as c_ulong)) as c_ulong)))

    test_dict_deflate(__local_compr, __local_comprLen)

    test_dict_inflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    with_free(((__local_compr as *mut c_void) as *mut i8))

    with_free(((__local_uncompr as *mut c_void) as *mut i8))

    return 0

}

var hello: [14]c_char = [104, 101, 108, 108, 111, 44, 32, 104, 101, 108, 108, 111, 33, 0]
let dictionary: [6]c_char = [104, 101, 108, 108, 111, 0]
var dictId: c_ulong = 0
var zalloc: unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void = (0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)
var zfree: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit = (0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)
