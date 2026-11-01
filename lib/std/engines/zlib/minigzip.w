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
use std.collections

// contract: unproved:0:out-parameter a return before the write,unproved:1:read only
unsafe fn string_copy(__param_dst: *mut c_char, __param_src: *const c_char, __param_len: u64) -> *mut c_char {
    var __local_dst = __param_dst
    var __local_src = __param_src
    var __local_len = __param_len
    if (__local_len == 0) {
        return ((null as *mut c_char))
    }

    while true {
        (__local_len = (__local_len -% 1))

        if (not __local_len) {
            break
        }

        var __ci_expr_old_0: *const c_char = __local_src

        (__local_src = __local_src + 1)

        ((*__local_dst) = (*__ci_expr_old_0))

        if ((*__local_dst) == 0) {
            return __local_dst
        }

        (__local_dst = __local_dst + 1)

    }

    ((*__local_dst) = ((0 as c_char)))

    return __local_dst

}

// contract: unproved:0:read only
unsafe fn error_(__param_msg: *const c_char) {
    fprintf(libc_stderr(), c"%s: %s\n".ptr, prog, __param_msg)

    exit((1 as i32))

}

// contract: stored-unknown:0,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn gz_compress(__param_in_: *mut c_void, __param_out: *mut gzFile_s) {
    var __local_buf: List[c_char] = [0; 16384]

    var __local_len: i32

    var __local_err: i32

    while true {
        (__local_len = ((fread((&__local_buf[0] as *mut c_char), (1 as u64), ((16384 * (sizeof[c_char]() as usize)) as u64), __param_in_) as i32)))

        if ferror(__param_in_) {
            perror(c"fread".ptr)

            exit((1 as i32))

        }

        if (__local_len == 0) {
            break
        }

        if (gzwrite(__param_out, (&__local_buf[0] as *mut c_char), (__local_len as u32)) != __local_len) {
            error_(gzerror(__param_out, (&raw mut __local_err as *mut i32)))
        }

    }

    fclose(__param_in_)

    if (gzclose(__param_out) != 0) {
        error_(c"failed gzclose".ptr)
    }

}

// contract: stored-unknown:0,unproved:1:read only — stores an argument; ownership not modeled
unsafe fn gz_uncompress(__param_in_: *mut gzFile_s, __param_out: *mut c_void) {
    var __local_buf: List[c_char] = [0; 16384]

    var __local_len: i32

    var __local_err: i32

    while true {
        (__local_len = ((gzread(__param_in_, (&__local_buf[0] as *mut c_char), (16384 as u32)) as i32)))

        if (__local_len < 0) {
            error_(gzerror(__param_in_, (&raw mut __local_err as *mut i32)))
        }

        if (__local_len == 0) {
            break
        }

        if (((fwrite((&__local_buf[0] as *mut c_char), (1 as u64), ((__local_len as u32) as u64), __param_out) as i32)) != __local_len) {
            error_(c"failed fwrite".ptr)

        }

    }

    if fclose(__param_out) {
        error_(c"failed fclose".ptr)
    }

    if (gzclose(__param_in_) != 0) {
        error_(c"failed gzclose".ptr)
    }

}

// contract: stored-unknown:0,unproved:1:read only — stores an argument; ownership not modeled
unsafe fn file_compress(__param_file: *mut c_char, __param_mode: *mut c_char) -> Unit {
    var __local_outfile: List[c_char] = [0; 1025]

    var __local_end: *mut c_char


    var __local_in_: *mut c_void

    var __local_out: *mut gzFile_s

    if (((strlen((__param_file as *const c_char)) as u64) +% (strlen(c".gz".ptr) as u64)) >= (1025 * (sizeof[c_char]() as usize))) {
        fprintf(libc_stderr(), c"%s: filename too long\n".ptr, prog)

        exit((1 as i32))

    }

    (__local_end = string_copy((&__local_outfile[0] as *mut c_char), (__param_file as *const c_char), ((1025 * (sizeof[c_char]() as usize)) as u64)))

    string_copy(__local_end, c".gz".ptr, ((((1025 * (sizeof[c_char]() as usize)) as u64) -% (((((__local_end as usize) -% ((&__local_outfile[0] as *mut c_char) as usize)) as i64) / (sizeof[c_char]() as i64)) as u64)) as u64))

    (__local_in_ = fopen((__param_file as *const c_char), c"rb".ptr))

    if (__local_in_ == null) {
        perror((__param_file as *const c_char))

        exit((1 as i32))

    }

    (__local_out = gzopen((&__local_outfile[0] as *mut c_char), (__param_mode as *const c_char)))

    if (__local_out == null) {
        fclose(__local_in_)

        fprintf(libc_stderr(), c"%s: can't gzopen %s\n".ptr, prog, (&__local_outfile[0] as *mut c_char))

        exit((1 as i32))

    }

    gz_compress(__local_in_, __local_out)

    unlink((__param_file as *const c_char))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
unsafe fn file_uncompress(__param_file: *mut c_char) -> Unit {
    var __local_buf: List[c_char] = [0; 1025]

    var __local_infile: *mut c_char

    var __local_outfile: *mut c_char


    var __local_out: *mut c_void

    var __local_in_: *mut gzFile_s

    var __local_len: u64 = ((strlen((__param_file as *const c_char)) as u64))

    if (((__local_len as u64) +% (strlen(c".gz".ptr) as u64)) >= (1025 * (sizeof[c_char]() as usize))) {
        fprintf(libc_stderr(), c"%s: filename too long\n".ptr, prog)

        exit((1 as i32))

    }

    string_copy((&__local_buf[0] as *mut c_char), (__param_file as *const c_char), ((1025 * (sizeof[c_char]() as usize)) as u64))

    var __ci_expr_logic_0: i32 = 0

    if (__local_len > (((4 * (sizeof[c_char]() as usize)) as u64) -% (1 as u64))) {
        (__ci_expr_logic_0 = (if strcmp((((__param_file + (__local_len as usize)) - ((((4 * (sizeof[c_char]() as usize)) as u64) -% (1 as u64)) as usize)) as *const c_char), c".gz".ptr) == 0: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__local_infile = __param_file)

        (__local_outfile = (&__local_buf[0] as *mut c_char))

        ((__local_outfile[((__local_len as u64) -% (3 as u64))]) = ((0 as c_char)))

    } else {
        (__local_outfile = __param_file)

        (__local_infile = (&__local_buf[0] as *mut c_char))

        string_copy(((&__local_buf[0] as *mut c_char) + (__local_len as usize)), c".gz".ptr, ((((1025 * (sizeof[c_char]() as usize)) as u64) -% (__local_len as u64)) as u64))

    }


    (__local_in_ = gzopen((__local_infile as *const c_char), c"rb".ptr))

    if (__local_in_ == null) {
        fprintf(libc_stderr(), c"%s: can't gzopen %s\n".ptr, prog, __local_infile)

        exit((1 as i32))

    }

    (__local_out = fopen((__local_outfile as *const c_char), c"wb".ptr))

    if (__local_out == null) {
        gzclose(__local_in_)

        perror((__param_file as *const c_char))

        exit((1 as i32))

    }

    gz_uncompress(__local_in_, __local_out)

    unlink((__local_infile as *const c_char))

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 {
    var __local_argc = __param_argc
    var __local_argv = __param_argv
    var __local_copyout: i32 = ((0 as i32))

    var __local_uncompr: i32 = ((0 as i32))

    var __local_file: *mut gzFile_s

    var __local_bname: *mut c_char

    var __local_outmode: List[c_char] = [0; 5]


    string_copy((&__local_outmode[0] as *mut c_char), c"wb6 ".ptr, ((5 * (sizeof[c_char]() as usize)) as u64))

    (prog = (__local_argv[0]))

    (__local_bname = strrchr(((__local_argv[0]) as *const c_char), (47 as i32)))

    if (__local_bname != null) {
        (__local_bname = __local_bname + 1)
    } else {
        (__local_bname = (__local_argv[0]))
    }

    (__local_argc = __local_argc - 1)

    (__local_argv = __local_argv + 1)


    if (not strcmp((__local_bname as *const c_char), c"gunzip".ptr)) {
        (__local_uncompr = ((1 as i32)))
    } else {
        if (not strcmp((__local_bname as *const c_char), c"zcat".ptr)) {
            (__local_uncompr = ((1 as i32)))

            (__local_copyout = __local_uncompr)

        }
    }

    while (__local_argc > 0) {
        if (strcmp(((*__local_argv) as *const c_char), c"-c".ptr) == 0) {
            (__local_copyout = ((1 as i32)))
        } else {
            if (strcmp(((*__local_argv) as *const c_char), c"-d".ptr) == 0) {
                (__local_uncompr = ((1 as i32)))
            } else {
                if (strcmp(((*__local_argv) as *const c_char), c"-f".ptr) == 0) {
                    (__local_outmode[3] = ((102 as c_char)))
                } else {
                    if (strcmp(((*__local_argv) as *const c_char), c"-h".ptr) == 0) {
                        (__local_outmode[3] = ((104 as c_char)))
                    } else {
                        if (strcmp(((*__local_argv) as *const c_char), c"-r".ptr) == 0) {
                            (__local_outmode[3] = ((82 as c_char)))
                        } else {
                            var __ci_expr_logic_2: i32 = 0

                            var __ci_expr_logic_1: i32 = 0

                            var __ci_expr_logic_0: i32 = 0

                            if (((*__local_argv)[0]) == 45) {
                                (__ci_expr_logic_0 = (if ((*__local_argv)[1]) >= 49: 1 else: 0))
                            }

                            if __ci_expr_logic_0 {
                                (__ci_expr_logic_1 = (if ((*__local_argv)[1]) <= 57: 1 else: 0))
                            }

                            if __ci_expr_logic_1 {
                                (__ci_expr_logic_2 = (if ((*__local_argv)[2]) == 0: 1 else: 0))
                            }

                            if __ci_expr_logic_2 {
                                (__local_outmode[2] = ((((*__local_argv)[1]) as c_char)))
                            } else {
                                break
                            }

                        }
                    }
                }
            }
        }

        (__local_argc = __local_argc - 1)

        (__local_argv = __local_argv + 1)


    }

    if (__local_outmode[3] == 32) {
        (__local_outmode[3] = ((0 as c_char)))
    }

    if (__local_argc == 0) {


        if __local_uncompr {
            (__local_file = gzdopen(fileno(libc_stdin()), c"rb".ptr))

            if (__local_file == null) {
                error_(c"can't gzdopen stdin".ptr)
            }

            gz_uncompress(__local_file, libc_stdout())

        } else {
            (__local_file = gzdopen(fileno(libc_stdout()), (&__local_outmode[0] as *mut c_char)))

            if (__local_file == null) {
                error_(c"can't gzdopen stdout".ptr)
            }

            gz_compress(libc_stdin(), __local_file)

        }

    } else {
        if __local_copyout {

        }

        loop {
            if __local_uncompr {
                if __local_copyout {
                    (__local_file = gzopen(((*__local_argv) as *const c_char), c"rb".ptr))

                    if (__local_file == null) {
                        fprintf(libc_stderr(), c"%s: can't gzopen %s\n".ptr, prog, (*__local_argv))
                    } else {
                        gz_uncompress(__local_file, libc_stdout())
                    }

                } else {
                    file_uncompress((*__local_argv))

                }

            } else {
                if __local_copyout {
                    var __local_in_: *mut c_void = fopen(((*__local_argv) as *const c_char), c"rb".ptr)

                    if (__local_in_ == null) {
                        perror(((*__local_argv) as *const c_char))

                    } else {
                        (__local_file = gzdopen(fileno(libc_stdout()), (&__local_outmode[0] as *mut c_char)))

                        if (__local_file == null) {
                            error_(c"can't gzdopen stdout".ptr)
                        }

                        gz_compress(__local_in_, __local_file)

                    }

                } else {
                    file_compress((*__local_argv), (&__local_outmode[0] as *mut c_char))

                }

            }

            (__local_argv = __local_argv + 1)

            (__local_argc = __local_argc - 1)

            if not (__local_argc) {
                break
            }
        }

    }

    return 0

}

var prog: *mut c_char = null
