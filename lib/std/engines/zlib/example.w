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
use std.libc
use std.option
use std.collections

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn test_compress(__param_compr: *mut u8, __param_comprLen: u64, __param_uncompr: *mut u8, __param_uncomprLen: u64) -> Unit {
    var __local_err: i32

    var __local_len: u64 = ((((strlen((&hello[0] as *mut c_char)) as u64) +% (1 as u64)) as u64))

    (__local_err = ((compress(__param_compr, (&raw mut __param_comprLen as *mut u64), (&hello[0] as *const u8), __local_len) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"compress".ptr, __local_err)

        exit((1 as i32))

    }



    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_err = ((uncompress(__param_uncompr, (&raw mut __param_uncomprLen as *mut u64), (__param_compr as *const u8), __param_comprLen) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"uncompress".ptr, __local_err)

        exit((1 as i32))

    }



    if strcmp(((__param_uncompr as *mut c_char) as *const c_char), (&hello[0] as *mut c_char)) {
        fprintf(libc_stderr(), c"bad uncompress\n".ptr)

        exit((1 as i32))

    } else {
        printf(c"uncompress(): %s\n".ptr, (__param_uncompr as *mut c_char))

    }

}

// contract: unproved:0:read only,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn test_gzio(__param_fname: *const c_char, __param_uncompr: *mut u8, __param_uncomprLen: u64) -> Unit {
    var __local_err: i32

    var __local_len: i32 = ((((strlen((&hello[0] as *mut c_char)) as i32) + 1) as i32))

    var __local_file: *mut gzFile_s

    var __local_pos: i64

    (__local_file = gzopen(__param_fname, c"wb".ptr))

    if (__local_file == null) {
        fprintf(libc_stderr(), c"gzopen error\n".ptr)

        exit((1 as i32))

    }

    gzputc(__local_file, (104 as i32))

    if (gzputs(__local_file, c"ello".ptr) != 4) {
        fprintf(libc_stderr(), c"gzputs err: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut i32)))

        exit((1 as i32))

    }

    if (gzprintf(__local_file, c", %s!".ptr, c"hello".ptr) != 8) {
        fprintf(libc_stderr(), c"gzprintf err: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut i32)))

        exit((1 as i32))

    }

    gzseek(__local_file, (1 as i64), (libc.SEEK_CUR as i32))

    gzclose(__local_file)

    (__local_file = gzopen(__param_fname, c"rb".ptr))

    if (__local_file == null) {
        fprintf(libc_stderr(), c"gzopen error\n".ptr)

        exit((1 as i32))

    }

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    if (gzread(__local_file, (__param_uncompr as *mut c_void), (__param_uncomprLen as u32)) != __local_len) {
        fprintf(libc_stderr(), c"gzread err: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut i32)))

        exit((1 as i32))

    }

    if strcmp(((__param_uncompr as *mut c_char) as *const c_char), (&hello[0] as *mut c_char)) {
        fprintf(libc_stderr(), c"bad gzread: %s\n".ptr, (__param_uncompr as *mut c_char))

        exit((1 as i32))

    } else {
        printf(c"gzread(): %s\n".ptr, (__param_uncompr as *mut c_char))

    }

    (__local_pos = ((gzseek(__local_file, (-8 as i64), (libc.SEEK_CUR as i32)) as i64)))

    var __ci_expr_logic_0: i32

    if (__local_pos != 6) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if gztell(__local_file) != __local_pos: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        fprintf(libc_stderr(), c"gzseek error, pos=%ld, gztell=%ld\n".ptr, __local_pos, gztell(__local_file))

        exit((1 as i32))

    }


    var __ci_expr_ternary_2: i32 = 0

    if (*__local_file).have {
        ((*__local_file).have = ((*__local_file).have -% 1))

        ((*__local_file).pos = (*__local_file).pos + 1)

        var __ci_expr_old_1: *mut u8 = (*__local_file).next

        ((*__local_file).next = (*__local_file).next + 1)

        (__ci_expr_ternary_2 = (((*__ci_expr_old_1) as i32)))

    } else {
        (__ci_expr_ternary_2 = ((gzgetc(__local_file) as i32)))
    }

    if (__ci_expr_ternary_2 != 32) {
        fprintf(libc_stderr(), c"gzgetc error\n".ptr)

        exit((1 as i32))

    }


    if (gzungetc((32 as i32), __local_file) != 32) {
        fprintf(libc_stderr(), c"gzungetc error\n".ptr)

        exit((1 as i32))

    }

    gzgets(__local_file, (__param_uncompr as *mut c_char), (__param_uncomprLen as i32))

    if (strlen(((__param_uncompr as *mut c_char) as *const c_char)) != 7) {
        fprintf(libc_stderr(), c"gzgets err after gzseek: %s\n".ptr, gzerror(__local_file, (&raw mut __local_err as *mut i32)))

        exit((1 as i32))

    }

    if strcmp(((__param_uncompr as *mut c_char) as *const c_char), (((&hello[0] as *mut c_char) + ((6 as isize) as usize)) as *const c_char)) {
        fprintf(libc_stderr(), c"bad gzgets after gzseek\n".ptr)

        exit((1 as i32))

    } else {
        printf(c"gzgets() after gzseek: %s\n".ptr, (__param_uncompr as *mut c_char))

    }

    gzclose(__local_file)

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
unsafe fn test_deflate(__param_compr: *mut u8, __param_comprLen: u64) {
    var __local_c_stream: z_stream_s

    var __local_err: i32

    var __local_len: u64 = ((((strlen((&hello[0] as *mut c_char)) as u64) +% (1 as u64)) as u64))

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = null)

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (-1 as i32), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_c_stream.next_in = (&hello[0] as *mut u8))

    (__local_c_stream.next_out = __param_compr)

    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((*(&raw const __local_c_stream as *const z_stream_s)).total_in != __local_len) {
            (__ci_expr_logic_0 = (if (*(&raw const __local_c_stream as *const z_stream_s)).total_out < __param_comprLen: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_c_stream.avail_out = ((1 as u32)))

        (__local_c_stream.avail_in = (*(&raw const __local_c_stream as *const z_stream_s)).avail_out)

        (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as i32)) as i32)))

        if (__local_err != 0) {
            fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

            exit((1 as i32))

        }

    }

    while true {
        (__local_c_stream.avail_out = ((1 as u32)))

        (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as i32)) as i32)))

        if (__local_err == 1) {
            break
        }

        if (__local_err != 0) {
            fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

            exit((1 as i32))

        }



    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn test_inflate(__param_compr: *mut u8, __param_comprLen: u64, __param_uncompr: *mut u8, __param_uncomprLen: u64) -> Unit {
    var __local_err: i32

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = null)

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((0 as u32)))

    (__local_d_stream.next_out = __param_uncompr)

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((*(&raw const __local_d_stream as *const z_stream_s)).total_out < __param_uncomprLen) {
            (__ci_expr_logic_0 = (if (*(&raw const __local_d_stream as *const z_stream_s)).total_in < __param_comprLen: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_d_stream.avail_out = ((1 as u32)))

        (__local_d_stream.avail_in = (*(&raw const __local_d_stream as *const z_stream_s)).avail_out)

        (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as i32)) as i32)))

        if (__local_err == 1) {
            break
        }

        if (__local_err != 0) {
            fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflate".ptr, __local_err)

            exit((1 as i32))

        }

    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



    if strcmp(((__param_uncompr as *mut c_char) as *const c_char), (&hello[0] as *mut c_char)) {
        fprintf(libc_stderr(), c"bad inflate\n".ptr)

        exit((1 as i32))

    } else {
        printf(c"inflate(): %s\n".ptr, (__param_uncompr as *mut c_char))

    }

}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn test_large_deflate(__param_compr: *mut u8, __param_comprLen: u64, __param_uncompr: *mut u8, __param_uncomprLen: u64) {
    var __local_c_stream: z_stream_s

    var __local_err: i32

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = null)

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (1 as i32), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_c_stream.next_out = __param_compr)

    (__local_c_stream.avail_out = ((__param_comprLen as u32)))

    (__local_c_stream.next_in = __param_uncompr)

    (__local_c_stream.avail_in = ((__param_uncomprLen as u32)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

        exit((1 as i32))

    }



    if ((*(&raw const __local_c_stream as *const z_stream_s)).avail_in != 0) {
        fprintf(libc_stderr(), c"deflate not greedy\n".ptr)

        exit((1 as i32))

    }

    deflateParams((&raw mut __local_c_stream as *mut z_stream_s), (0 as i32), (0 as i32))

    (__local_c_stream.next_in = __param_compr)

    (__local_c_stream.avail_in = ((((__param_uncomprLen as u32) / (2 as u32)) as u32)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

        exit((1 as i32))

    }



    deflateParams((&raw mut __local_c_stream as *mut z_stream_s), (9 as i32), (1 as i32))

    (__local_c_stream.next_in = __param_uncompr)

    (__local_c_stream.avail_in = ((__param_uncomprLen as u32)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (0 as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as i32)) as i32)))

    if (__local_err != 1) {
        fprintf(libc_stderr(), c"deflate should report Z_STREAM_END\n".ptr)

        exit((1 as i32))

    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn test_large_inflate(__param_compr: *mut u8, __param_comprLen: u64, __param_uncompr: *mut u8, __param_uncomprLen: u64) -> Unit {
    var __local_err: i32

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = null)

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((__param_comprLen as u32)))

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    while true {
        (__local_d_stream.next_out = __param_uncompr)

        (__local_d_stream.avail_out = ((__param_uncomprLen as u32)))

        (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as i32)) as i32)))

        if (__local_err == 1) {
            break
        }

        if (__local_err != 0) {
            fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"large inflate".ptr, __local_err)

            exit((1 as i32))

        }



    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



    if ((*(&raw const __local_d_stream as *const z_stream_s)).total_out != ((((2 as u64) *% (__param_uncomprLen as u64)) as u64) +% (((__param_uncomprLen as u64) / (2 as u64)) as u64))) {
        fprintf(libc_stderr(), c"bad large inflate: %lu\n".ptr, (*(&raw const __local_d_stream as *const z_stream_s)).total_out)

        exit((1 as i32))

    } else {
        printf(c"large_inflate(): OK\n".ptr)

    }

}

// contract: stored-unknown:0,unproved:1:out-parameter read before the write — stores an argument; ownership not modeled
unsafe fn test_flush(__param_compr: *mut u8, __param_comprLen: *mut u64) {
    var __local_c_stream: z_stream_s

    var __local_err: i32

    var __local_len: u32 = ((((strlen((&hello[0] as *mut c_char)) as u32) +% (1 as u32)) as u32))

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = null)

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (-1 as i32), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_c_stream.next_in = (&hello[0] as *mut u8))

    (__local_c_stream.next_out = __param_compr)

    (__local_c_stream.avail_in = ((3 as u32)))

    (__local_c_stream.avail_out = (((*__param_comprLen) as u32)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (3 as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

        exit((1 as i32))

    }



    ((__param_compr[3]) = ((__param_compr[3]) +% 1))

    (__local_c_stream.avail_in = ((((__local_len as u32) -% (3 as u32)) as u32)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as i32)) as i32)))

    if (__local_err != 1) {
        if (__local_err != 0) {
            fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflate".ptr, __local_err)

            exit((1 as i32))

        }



    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



    ((*__param_comprLen) = (*(&raw const __local_c_stream as *const z_stream_s)).total_out)

}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn test_sync(__param_compr: *mut u8, __param_comprLen: u64, __param_uncompr: *mut u8, __param_uncomprLen: u64) -> Unit {
    var __local_err: i32

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = null)

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((2 as u32)))

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_d_stream.next_out = __param_uncompr)

    (__local_d_stream.avail_out = ((__param_uncomprLen as u32)))

    (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflate".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_d_stream.avail_in = ((((__param_comprLen as u32) -% (2 as u32)) as u32)))

    (__local_err = ((inflateSync((&raw mut __local_d_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateSync".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (4 as i32)) as i32)))

    if (__local_err != 1) {
        fprintf(libc_stderr(), c"inflate should report Z_STREAM_END\n".ptr)

        exit((1 as i32))

    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



    printf(c"after inflateSync(): hel%s\n".ptr, (__param_uncompr as *mut c_char))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
unsafe fn test_dict_deflate(__param_compr: *mut u8, __param_comprLen: u64) {
    var __local_c_stream: z_stream_s

    var __local_err: i32

    (__local_c_stream.zalloc = zalloc)

    (__local_c_stream.zfree = zfree)

    (__local_c_stream.opaque_ = null)

    (__local_err = ((deflateInit_((&raw mut __local_c_stream as *mut z_stream_s), (9 as i32), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_err = ((deflateSetDictionary((&raw mut __local_c_stream as *mut z_stream_s), (&dictionary[0] as *const u8), (6 as u32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateSetDictionary".ptr, __local_err)

        exit((1 as i32))

    }



    (dictId = (*(&raw const __local_c_stream as *const z_stream_s)).adler)

    (__local_c_stream.next_out = __param_compr)

    (__local_c_stream.avail_out = ((__param_comprLen as u32)))

    (__local_c_stream.next_in = (&hello[0] as *mut u8))

    (__local_c_stream.avail_in = ((((strlen((&hello[0] as *mut c_char)) as u32) +% (1 as u32)) as u32)))

    (__local_err = ((deflate((&raw mut __local_c_stream as *mut z_stream_s), (4 as i32)) as i32)))

    if (__local_err != 1) {
        fprintf(libc_stderr(), c"deflate should report Z_STREAM_END\n".ptr)

        exit((1 as i32))

    }

    (__local_err = ((deflateEnd((&raw mut __local_c_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"deflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn test_dict_inflate(__param_compr: *mut u8, __param_comprLen: u64, __param_uncompr: *mut u8, __param_uncomprLen: u64) -> Unit {
    var __local_err: i32

    var __local_d_stream: z_stream_s

    strcpy((__param_uncompr as *mut c_char), c"garbage".ptr)

    (__local_d_stream.zalloc = zalloc)

    (__local_d_stream.zfree = zfree)

    (__local_d_stream.opaque_ = null)

    (__local_d_stream.next_in = __param_compr)

    (__local_d_stream.avail_in = ((__param_comprLen as u32)))

    (__local_err = ((inflateInit_((&raw mut __local_d_stream as *mut z_stream_s), c"1.3.2".ptr, (sizeof[z_stream_s]() as i32)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateInit".ptr, __local_err)

        exit((1 as i32))

    }



    (__local_d_stream.next_out = __param_uncompr)

    (__local_d_stream.avail_out = ((__param_uncomprLen as u32)))

    while true {
        (__local_err = ((inflate((&raw mut __local_d_stream as *mut z_stream_s), (0 as i32)) as i32)))

        if (__local_err == 1) {
            break
        }

        if (__local_err == 2) {
            if ((*(&raw const __local_d_stream as *const z_stream_s)).adler != dictId) {
                fprintf(libc_stderr(), c"unexpected dictionary".ptr)

                exit((1 as i32))

            }

            (__local_err = ((inflateSetDictionary((&raw mut __local_d_stream as *mut z_stream_s), (&dictionary[0] as *const u8), (6 as u32)) as i32)))

        }

        if (__local_err != 0) {
            fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflate with dict".ptr, __local_err)

            exit((1 as i32))

        }



    }

    (__local_err = ((inflateEnd((&raw mut __local_d_stream as *mut z_stream_s)) as i32)))

    if (__local_err != 0) {
        fprintf(libc_stderr(), c"%s error: %d\n".ptr, c"inflateEnd".ptr, __local_err)

        exit((1 as i32))

    }



    if strcmp(((__param_uncompr as *mut c_char) as *const c_char), (&hello[0] as *mut c_char)) {
        fprintf(libc_stderr(), c"bad inflate with dict\n".ptr)

        exit((1 as i32))

    } else {
        printf(c"inflate with dictionary: %s\n".ptr, (__param_uncompr as *mut c_char))

    }

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 {
    var __local_compr: *mut u8

    var __local_uncompr: *mut u8


    var __local_uncomprLen: u64 = ((20000 as u64))

    var __local_comprLen: u64 = ((((3 as u64) *% (__local_uncomprLen as u64)) as u64))

    var __local_myVersion: *const c_char = c"1.3.2".ptr

    if ((zlibVersion()[0]) != (__local_myVersion[0])) {
        fprintf(libc_stderr(), c"incompatible zlib version\n".ptr)

        exit((1 as i32))

    } else {
        if (strcmp(zlibVersion(), c"1.3.2".ptr) != 0) {
            fprintf(libc_stderr(), c"warning: different zlib version linked: %s\n".ptr, zlibVersion())

        }
    }

    printf(c"zlib version %s = 0x%04x, compile flags = 0x%lx\n".ptr, c"1.3.2".ptr, (4896 as u32), zlibCompileFlags())

    (__local_compr = (((with_alloc_zeroed((((__local_comprLen as u32) as u64) as i64), ((1 as u64) as i64)) as *mut c_void) as *mut u8)))

    (__local_uncompr = (((with_alloc_zeroed((((__local_uncomprLen as u32) as u64) as i64), ((1 as u64) as i64)) as *mut c_void) as *mut u8)))

    var __ci_expr_logic_0: i32

    if (__local_compr == 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_uncompr == 0: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        printf(c"out of memory\n".ptr)

        exit((1 as i32))

    }


    test_compress(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_gzio(((if __param_argc > 1: (__param_argv[1]) else: ("foo.gz" as *mut c_char)) as *const c_char), __local_uncompr, __local_uncomprLen)

    test_deflate(__local_compr, __local_comprLen)

    test_inflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_large_deflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_large_inflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    test_flush(__local_compr, (&raw mut __local_comprLen as *mut u64))

    test_sync(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    (__local_comprLen = ((((3 as u64) *% (__local_uncomprLen as u64)) as u64)))

    test_dict_deflate(__local_compr, __local_comprLen)

    test_dict_inflate(__local_compr, __local_comprLen, __local_uncompr, __local_uncomprLen)

    with_free(((__local_compr as *mut c_void) as *mut u8))

    with_free(((__local_uncompr as *mut c_void) as *mut u8))

    return 0

}

let hello: List[c_char] = [104, 101, 108, 108, 111, 44, 32, 104, 101, 108, 108, 111, 33, 0]
let dictionary: List[c_char] = [104, 101, 108, 108, 111, 0]
var dictId: u64 = 0
var zalloc: Option[unsafe extern "C" fn(*mut c_void, u32, u32) -> *mut c_void] = null
var zfree: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit] = null
