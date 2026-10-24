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

unsafe fn string_copy(__param_dst: *mut c_char, __param_src: *const c_char, __param_len: c_ulong) -> *mut c_char {
    var __local_dst = __param_dst
    var __local_src = __param_src
    var __local_len = __param_len
    if ((if __local_len == 0: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    while true {
        (__local_len = (__local_len -% 1))

        if (not (__local_len != 0)) {
            break
        }

        var __ci_expr_old_0: *const c_char = __local_src

        (__local_src = __local_src + 1)

        ((*__local_dst) = (*__ci_expr_old_0))

        if ((if (*__local_dst) == 0: 1 else: 0) != 0) {
            return __local_dst
        }

        (__local_dst = __local_dst + 1)

    }

    ((*__local_dst) = ((0 as c_char)))

    return __local_dst

}

unsafe fn error_(__param_msg: *const c_char) {
    fprintf(libc_stderr(), c"%s: %s\n".ptr, prog, __param_msg)

    exit((1 as c_int))

}

unsafe fn gz_compress(__param_in_: *mut c_void, __param_out: *mut gzFile_s) {
    var __local_buf: List[c_char] = [0; 16384]

    var __local_len: c_int

    var __local_err: c_int

    while true {
        (__local_len = ((fread((&__local_buf[0] as *mut c_char), (1 as c_ulong), ((16384 * (sizeof[c_char]() as usize)) as c_ulong), __param_in_) as c_int)))

        if (ferror(__param_in_) != 0) {
            perror(c"fread".ptr)

            exit((1 as c_int))

        }

        if ((if __local_len == 0: 1 else: 0) != 0) {
            break
        }

        if ((if gzwrite(__param_out, (&__local_buf[0] as *mut c_char), (__local_len as c_uint)) != __local_len: 1 else: 0) != 0) {
            error_(gzerror(__param_out, (&raw mut __local_err as *mut c_int)))
        }

    }

    fclose(__param_in_)

    if ((if gzclose(__param_out) != 0: 1 else: 0) != 0) {
        error_(c"failed gzclose".ptr)
    }

}

unsafe fn gz_uncompress(__param_in_: *mut gzFile_s, __param_out: *mut c_void) {
    var __local_buf: List[c_char] = [0; 16384]

    var __local_len: c_int

    var __local_err: c_int

    while true {
        (__local_len = ((gzread(__param_in_, (&__local_buf[0] as *mut c_char), (16384 as c_uint)) as c_int)))

        if ((if __local_len < 0: 1 else: 0) != 0) {
            error_(gzerror(__param_in_, (&raw mut __local_err as *mut c_int)))
        }

        if ((if __local_len == 0: 1 else: 0) != 0) {
            break
        }

        if ((if ((fwrite((&__local_buf[0] as *mut c_char), (1 as c_ulong), ((__local_len as c_uint) as c_ulong), __param_out) as c_int)) != __local_len: 1 else: 0) != 0) {
            error_(c"failed fwrite".ptr)

        }

    }

    if (fclose(__param_out) != 0) {
        error_(c"failed fclose".ptr)
    }

    if ((if gzclose(__param_in_) != 0: 1 else: 0) != 0) {
        error_(c"failed gzclose".ptr)
    }

}

unsafe fn file_compress(__param_file: *mut c_char, __param_mode: *mut c_char) -> Unit {
    var __local_outfile: List[c_char] = [0; 1025]

    var __local_end: *mut c_char


    var __local_in_: *mut c_void

    var __local_out: *mut gzFile_s

    if ((if ((strlen((__param_file as *const c_char)) as c_ulong) +% (strlen(c".gz".ptr) as c_ulong)) >= (1025 * (sizeof[c_char]() as usize)): 1 else: 0) != 0) {
        fprintf(libc_stderr(), c"%s: filename too long\n".ptr, prog)

        exit((1 as c_int))

    }

    (__local_end = string_copy((&__local_outfile[0] as *mut c_char), (__param_file as *const c_char), ((1025 * (sizeof[c_char]() as usize)) as c_ulong)))

    string_copy(__local_end, c".gz".ptr, ((((1025 * (sizeof[c_char]() as usize)) as c_ulong) -% (((((__local_end as usize) -% ((&__local_outfile[0] as *mut c_char) as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_ulong)) as c_ulong))

    (__local_in_ = fopen((__param_file as *const c_char), c"rb".ptr))

    if ((if __local_in_ == null: 1 else: 0) != 0) {
        perror((__param_file as *const c_char))

        exit((1 as c_int))

    }

    (__local_out = gzopen((&__local_outfile[0] as *mut c_char), (__param_mode as *const c_char)))

    if ((if __local_out == null: 1 else: 0) != 0) {
        fclose(__local_in_)

        fprintf(libc_stderr(), c"%s: can't gzopen %s\n".ptr, prog, (&__local_outfile[0] as *mut c_char))

        exit((1 as c_int))

    }

    gz_compress(__local_in_, __local_out)

    unlink((__param_file as *const c_char))

}

unsafe fn file_uncompress(__param_file: *mut c_char) -> Unit {
    var __local_buf: List[c_char] = [0; 1025]

    var __local_infile: *mut c_char

    var __local_outfile: *mut c_char


    var __local_out: *mut c_void

    var __local_in_: *mut gzFile_s

    var __local_len: c_ulong = ((strlen((__param_file as *const c_char)) as c_ulong))

    if ((if ((__local_len as c_ulong) +% (strlen(c".gz".ptr) as c_ulong)) >= (1025 * (sizeof[c_char]() as usize)): 1 else: 0) != 0) {
        fprintf(libc_stderr(), c"%s: filename too long\n".ptr, prog)

        exit((1 as c_int))

    }

    string_copy((&__local_buf[0] as *mut c_char), (__param_file as *const c_char), ((1025 * (sizeof[c_char]() as usize)) as c_ulong))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_len > (((4 * (sizeof[c_char]() as usize)) as c_ulong) -% (1 as c_ulong)): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if strcmp((((__param_file + (__local_len as usize)) - ((((4 * (sizeof[c_char]() as usize)) as c_ulong) -% (1 as c_ulong)) as usize)) as *const c_char), c".gz".ptr) == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_infile = __param_file)

        (__local_outfile = (&__local_buf[0] as *mut c_char))

        ((__local_outfile[((__local_len as c_ulong) -% (3 as c_ulong))]) = ((0 as c_char)))

    } else {
        (__local_outfile = __param_file)

        (__local_infile = (&__local_buf[0] as *mut c_char))

        string_copy(((&__local_buf[0] as *mut c_char) + (__local_len as usize)), c".gz".ptr, ((((1025 * (sizeof[c_char]() as usize)) as c_ulong) -% (__local_len as c_ulong)) as c_ulong))

    }


    (__local_in_ = gzopen((__local_infile as *const c_char), c"rb".ptr))

    if ((if __local_in_ == null: 1 else: 0) != 0) {
        fprintf(libc_stderr(), c"%s: can't gzopen %s\n".ptr, prog, __local_infile)

        exit((1 as c_int))

    }

    (__local_out = fopen((__local_outfile as *const c_char), c"wb".ptr))

    if ((if __local_out == null: 1 else: 0) != 0) {
        gzclose(__local_in_)

        perror((__param_file as *const c_char))

        exit((1 as c_int))

    }

    gz_uncompress(__local_in_, __local_out)

    unlink((__local_infile as *const c_char))

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut c_char) -> c_int {
    var __local_argc = __param_argc
    var __local_argv = __param_argv
    var __local_copyout: c_int = ((0 as c_int))

    var __local_uncompr: c_int = ((0 as c_int))

    var __local_file: *mut gzFile_s

    var __local_bname: *mut c_char

    var __local_outmode: List[c_char] = [0; 5]


    string_copy((&__local_outmode[0] as *mut c_char), c"wb6 ".ptr, ((5 * (sizeof[c_char]() as usize)) as c_ulong))

    (prog = (__local_argv[0]))

    (__local_bname = strrchr(((__local_argv[0]) as *const c_char), (47 as c_int)))

    if (__local_bname != null) {
        (__local_bname = __local_bname + 1)
    } else {
        (__local_bname = (__local_argv[0]))
    }

    (__local_argc = __local_argc - 1)

    (__local_argv = __local_argv + 1)


    if ((if not (strcmp((__local_bname as *const c_char), c"gunzip".ptr) != 0): 1 else: 0) != 0) {
        (__local_uncompr = ((1 as c_int)))
    } else {
        if ((if not (strcmp((__local_bname as *const c_char), c"zcat".ptr) != 0): 1 else: 0) != 0) {
            (__local_uncompr = ((1 as c_int)))

            (__local_copyout = __local_uncompr)

        }
    }

    while ((if __local_argc > 0: 1 else: 0) != 0) {
        if ((if strcmp(((*__local_argv) as *const c_char), c"-c".ptr) == 0: 1 else: 0) != 0) {
            (__local_copyout = ((1 as c_int)))
        } else {
            if ((if strcmp(((*__local_argv) as *const c_char), c"-d".ptr) == 0: 1 else: 0) != 0) {
                (__local_uncompr = ((1 as c_int)))
            } else {
                if ((if strcmp(((*__local_argv) as *const c_char), c"-f".ptr) == 0: 1 else: 0) != 0) {
                    (__local_outmode[3] = ((102 as c_char)))
                } else {
                    if ((if strcmp(((*__local_argv) as *const c_char), c"-h".ptr) == 0: 1 else: 0) != 0) {
                        (__local_outmode[3] = ((104 as c_char)))
                    } else {
                        if ((if strcmp(((*__local_argv) as *const c_char), c"-r".ptr) == 0: 1 else: 0) != 0) {
                            (__local_outmode[3] = ((82 as c_char)))
                        } else {
                            var __ci_expr_logic_2: c_int = 0

                            var __ci_expr_logic_1: c_int = 0

                            var __ci_expr_logic_0: c_int = 0

                            if ((if ((*__local_argv)[0]) == 45: 1 else: 0) != 0) {
                                (__ci_expr_logic_0 = (if (if ((*__local_argv)[1]) >= 49: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_0 != 0) {
                                (__ci_expr_logic_1 = (if (if ((*__local_argv)[1]) <= 57: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__ci_expr_logic_2 = (if (if ((*__local_argv)[2]) == 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_2 != 0) {
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

    if ((if __local_outmode[3] == 32: 1 else: 0) != 0) {
        (__local_outmode[3] = ((0 as c_char)))
    }

    if ((if __local_argc == 0: 1 else: 0) != 0) {


        if (__local_uncompr != 0) {
            (__local_file = gzdopen((fileno(libc_stdin()) as c_int), c"rb".ptr))

            if ((if __local_file == null: 1 else: 0) != 0) {
                error_(c"can't gzdopen stdin".ptr)
            }

            gz_uncompress(__local_file, libc_stdout())

        } else {
            (__local_file = gzdopen((fileno(libc_stdout()) as c_int), (&__local_outmode[0] as *mut c_char)))

            if ((if __local_file == null: 1 else: 0) != 0) {
                error_(c"can't gzdopen stdout".ptr)
            }

            gz_compress(libc_stdin(), __local_file)

        }

    } else {
        if (__local_copyout != 0) {

        }

        loop {
            if (__local_uncompr != 0) {
                if (__local_copyout != 0) {
                    (__local_file = gzopen(((*__local_argv) as *const c_char), c"rb".ptr))

                    if ((if __local_file == null: 1 else: 0) != 0) {
                        fprintf(libc_stderr(), c"%s: can't gzopen %s\n".ptr, prog, (*__local_argv))
                    } else {
                        gz_uncompress(__local_file, libc_stdout())
                    }

                } else {
                    file_uncompress((*__local_argv))

                }

            } else {
                if (__local_copyout != 0) {
                    var __local_in_: *mut c_void = fopen(((*__local_argv) as *const c_char), c"rb".ptr)

                    if ((if __local_in_ == null: 1 else: 0) != 0) {
                        perror(((*__local_argv) as *const c_char))

                    } else {
                        (__local_file = gzdopen((fileno(libc_stdout()) as c_int), (&__local_outmode[0] as *mut c_char)))

                        if ((if __local_file == null: 1 else: 0) != 0) {
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

            if not ((__local_argc != 0)) {
                break
            }
        }

    }

    return 0

}

var prog: *mut c_char = null
