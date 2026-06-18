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

unsafe fn string_copy(__param_dst: *mut i8, __param_src: *const i8, __param_len: c_ulong) -> *mut i8 {
    var __local_dst = __param_dst
    var __local_src = __param_src
    var __local_len = __param_len
    if ((if __local_len == 0: 1 else: 0) != 0) {
        return null
    }

    while true {
        (__local_len = (__local_len -% 1))

        if (not (__local_len != 0)) {
            break
        }

        var __ci_expr_old_0: *const i8 = __local_src

        (__local_src = __local_src + 1)

        ((unsafe *__local_dst) = (((unsafe *__ci_expr_old_0) as c_char)))

        if ((if (unsafe *__local_dst) == 0: 1 else: 0) != 0) {
            return __local_dst
        }

        (__local_dst = __local_dst + 1)

    }

    ((unsafe *__local_dst) = ((0 as c_char)))

    return __local_dst

}

unsafe fn error_(__param_msg: *const i8) -> Unit {
    fprintf(__stderrp, c"%s: %s\n".ptr, prog, __param_msg)

    exit((1 as c_int))

}

unsafe fn gz_compress(__param_in_: *mut c_void, __param_out: *mut gzFile_s) -> Unit {
    var __local_buf: [16384]c_char

    var __local_len: c_int

    var __local_err: c_int

    while true {
        (__local_len = ((fread((&__local_buf[0] as *mut c_char), (1 as c_ulong), ((16384 * sizeof[c_char]()) as c_ulong), __param_in_) as c_int)))

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

unsafe fn gz_uncompress(__param_in_: *mut gzFile_s, __param_out: *mut c_void) -> Unit {
    var __local_buf: [16384]c_char

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

        if ((if ((fwrite((&__local_buf[0] as *mut c_char), (1 as c_ulong), (__local_len as c_uint), __param_out) as c_int)) != __local_len: 1 else: 0) != 0) {
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

unsafe fn file_compress(__param_file: *mut i8, __param_mode: *mut i8) -> Unit {
    var __local_outfile: [1025]c_char

    var __local_end: *mut c_char


    var __local_in_: *mut c_void

    var __local_out: *mut gzFile_s

    if ((if ((strlen((__param_file as *const i8)) as c_ulong) +% (strlen(c".gz".ptr) as c_ulong)) >= (1025 * sizeof[c_char]()): 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s: filename too long\n".ptr, prog)

        exit((1 as c_int))

    }

    (__local_end = ((string_copy((&__local_outfile[0] as *mut c_char), (__param_file as *const i8), ((1025 * sizeof[c_char]()) as c_ulong)) as *mut c_char)))

    string_copy(__local_end, c".gz".ptr, ((((1025 * sizeof[c_char]()) as c_ulong) -% (((((__local_end as usize) -% ((&__local_outfile[0] as *mut c_char) as usize)) / sizeof[c_char]()) as c_ulong) as c_ulong)) as c_ulong))

    (__local_in_ = fopen((__param_file as *const i8), c"rb".ptr))

    if ((if __local_in_ == null: 1 else: 0) != 0) {
        perror((__param_file as *const i8))

        exit((1 as c_int))

    }

    (__local_out = gzopen((&__local_outfile[0] as *mut c_char), (__param_mode as *const i8)))

    if ((if __local_out == null: 1 else: 0) != 0) {
        fclose(__local_in_)

        fprintf(__stderrp, c"%s: can't gzopen %s\n".ptr, prog, (&__local_outfile[0] as *mut c_char))

        exit((1 as c_int))

    }

    gz_compress(__local_in_, __local_out)

    unlink((__param_file as *const i8))

}

unsafe fn file_uncompress(__param_file: *mut i8) -> Unit {
    var __local_buf: [1025]c_char

    var __local_infile: *mut c_char

    var __local_outfile: *mut c_char


    var __local_out: *mut c_void

    var __local_in_: *mut gzFile_s

    var __local_len: c_ulong = ((strlen((__param_file as *const i8)) as c_ulong))

    if ((if ((__local_len as c_ulong) +% (strlen(c".gz".ptr) as c_ulong)) >= (1025 * sizeof[c_char]()): 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s: filename too long\n".ptr, prog)

        exit((1 as c_int))

    }

    string_copy((&__local_buf[0] as *mut c_char), (__param_file as *const i8), ((1025 * sizeof[c_char]()) as c_ulong))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_len > (((4 * sizeof[c_char]()) as c_ulong) -% (1 as c_ulong)): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if strcmp((((__param_file + (__local_len as usize)) - ((((4 * sizeof[c_char]()) as c_ulong) -% (1 as c_ulong)) as usize)) as *const i8), c".gz".ptr) == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_infile = ((__param_file as *mut c_char)))

        (__local_outfile = (&__local_buf[0] as *mut c_char))

        ((unsafe __local_outfile[((__local_len as c_ulong) -% (3 as c_ulong))]) = ((0 as c_char)))

    } else {
        (__local_outfile = ((__param_file as *mut c_char)))

        (__local_infile = (&__local_buf[0] as *mut c_char))

        string_copy(((&__local_buf[0] as *mut c_char) + (__local_len as usize)), c".gz".ptr, ((((1025 * sizeof[c_char]()) as c_ulong) -% (__local_len as c_ulong)) as c_ulong))

    }


    (__local_in_ = gzopen((__local_infile as *const i8), c"rb".ptr))

    if ((if __local_in_ == null: 1 else: 0) != 0) {
        fprintf(__stderrp, c"%s: can't gzopen %s\n".ptr, prog, __local_infile)

        exit((1 as c_int))

    }

    (__local_out = fopen((__local_outfile as *const i8), c"wb".ptr))

    if ((if __local_out == null: 1 else: 0) != 0) {
        gzclose(__local_in_)

        perror((__param_file as *const i8))

        exit((1 as c_int))

    }

    gz_uncompress(__local_in_, __local_out)

    unlink((__local_infile as *const i8))

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    var __local_argc = __param_argc
    var __local_argv = __param_argv
    var __local_copyout: c_int = ((0 as c_int))

    var __local_uncompr: c_int = ((0 as c_int))

    var __local_file: *mut gzFile_s

    var __local_bname: *mut c_char

    var __local_outmode: [5]c_char


    string_copy((&__local_outmode[0] as *mut c_char), c"wb6 ".ptr, ((5 * sizeof[c_char]()) as c_ulong))

    (prog = (((unsafe __local_argv[0]) as *mut c_char)))

    (__local_bname = ((strrchr(((unsafe __local_argv[0]) as *const i8), (47 as c_int)) as *mut c_char)))

    if (__local_bname != null) {
        (__local_bname = __local_bname + 1)
    } else {
        (__local_bname = (((unsafe __local_argv[0]) as *mut c_char)))
    }

    (__local_argc = __local_argc - 1)

    (__local_argv = __local_argv + 1)


    if ((if not (strcmp((__local_bname as *const i8), c"gunzip".ptr) != 0): 1 else: 0) != 0) {
        (__local_uncompr = ((1 as c_int)))
    } else {
        if ((if not (strcmp((__local_bname as *const i8), c"zcat".ptr) != 0): 1 else: 0) != 0) {
            (__local_uncompr = ((1 as c_int)))

            (__local_copyout = __local_uncompr)

        }
    }

    while ((if __local_argc > 0: 1 else: 0) != 0) {
        if ((if strcmp(((unsafe *__local_argv) as *const i8), c"-c".ptr) == 0: 1 else: 0) != 0) {
            (__local_copyout = ((1 as c_int)))
        } else {
            if ((if strcmp(((unsafe *__local_argv) as *const i8), c"-d".ptr) == 0: 1 else: 0) != 0) {
                (__local_uncompr = ((1 as c_int)))
            } else {
                if ((if strcmp(((unsafe *__local_argv) as *const i8), c"-f".ptr) == 0: 1 else: 0) != 0) {
                    (__local_outmode[3] = ((102 as c_char)))
                } else {
                    if ((if strcmp(((unsafe *__local_argv) as *const i8), c"-h".ptr) == 0: 1 else: 0) != 0) {
                        (__local_outmode[3] = ((104 as c_char)))
                    } else {
                        if ((if strcmp(((unsafe *__local_argv) as *const i8), c"-r".ptr) == 0: 1 else: 0) != 0) {
                            (__local_outmode[3] = ((82 as c_char)))
                        } else {
                            var __ci_expr_logic_2: c_int = 0

                            var __ci_expr_logic_1: c_int = 0

                            var __ci_expr_logic_0: c_int = 0

                            if ((if (unsafe (unsafe *__local_argv)[0]) == 45: 1 else: 0) != 0) {
                                (__ci_expr_logic_0 = (if (if (unsafe (unsafe *__local_argv)[1]) >= 49: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_0 != 0) {
                                (__ci_expr_logic_1 = (if (if (unsafe (unsafe *__local_argv)[1]) <= 57: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__ci_expr_logic_2 = (if (if (unsafe (unsafe *__local_argv)[2]) == 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_2 != 0) {
                                (__local_outmode[2] = (((unsafe (unsafe *__local_argv)[1]) as c_char)))
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
            (__local_file = gzdopen((fileno(__stdinp) as c_int), c"rb".ptr))

            if ((if __local_file == null: 1 else: 0) != 0) {
                error_(c"can't gzdopen stdin".ptr)
            }

            gz_uncompress(__local_file, __stdoutp)

        } else {
            (__local_file = gzdopen((fileno(__stdoutp) as c_int), (&__local_outmode[0] as *mut c_char)))

            if ((if __local_file == null: 1 else: 0) != 0) {
                error_(c"can't gzdopen stdout".ptr)
            }

            gz_compress(__stdinp, __local_file)

        }

    } else {

        loop {
            if (__local_uncompr != 0) {
                if (__local_copyout != 0) {
                    (__local_file = gzopen(((unsafe *__local_argv) as *const i8), c"rb".ptr))

                    if ((if __local_file == null: 1 else: 0) != 0) {
                        fprintf(__stderrp, c"%s: can't gzopen %s\n".ptr, prog, (unsafe *__local_argv))
                    } else {
                        gz_uncompress(__local_file, __stdoutp)
                    }

                } else {
                    file_uncompress((unsafe *__local_argv))

                }

            } else {
                if (__local_copyout != 0) {
                    var __local_in_: *mut c_void = fopen(((unsafe *__local_argv) as *const i8), c"rb".ptr)

                    if ((if __local_in_ == null: 1 else: 0) != 0) {
                        perror(((unsafe *__local_argv) as *const i8))

                    } else {
                        (__local_file = gzdopen((fileno(__stdoutp) as c_int), (&__local_outmode[0] as *mut c_char)))

                        if ((if __local_file == null: 1 else: 0) != 0) {
                            error_(c"can't gzdopen stdout".ptr)
                        }

                        gz_compress(__local_in_, __local_file)

                    }

                } else {
                    file_compress((unsafe *__local_argv), (&__local_outmode[0] as *mut c_char))

                }

            }

            var __ci_expr_old_3: *mut *mut i8 = __local_argv

            (__local_argv = __local_argv + 1)

            (__local_argc = __local_argc - 1)

            if not ((__local_argc != 0)) {
                break
            }
        }

    }

    return 0

}

var prog: *mut i8 = null
