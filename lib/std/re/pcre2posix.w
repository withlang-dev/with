// Migrated from PCRE2
use std.re.defs
use std.libc

@[c_export("pcre2_regcomp")]
fn pcre2_regcomp(__param_preg: *mut regex_t, __param_pattern: *const i8, __param_cflags: c_int) -> c_int {
    var __local_erroffset: c_ulong

    var __local_patlen: c_ulong

    var __local_errorcode: c_int

    var __local_options: c_int = 0

    var __local_re_nsub: c_int = 0

    ((unsafe: *__param_preg).re_match_data = null)

    ((unsafe: *__param_preg).re_pcre2_code = null)

    var __ci_expr_ternary_0: c_ulong = 0

    if ((if (__param_cflags & 2048) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = (((((__param_preg.re_endp as usize) -% (__param_pattern as usize)) / sizeof[c_char]()) as c_ulong)))
    } else {
        (__ci_expr_ternary_0 = (~(0 as c_ulong)))
    }

    (__local_patlen = __ci_expr_ternary_0)


    if ((if (__param_cflags & 1) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 8)
    }

    if ((if (__param_cflags & 2) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 1024)
    }

    if ((if (__param_cflags & 16) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 32)
    }

    if ((if (__param_cflags & 4096) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 33554432)
    }

    if ((if (__param_cflags & 64) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 524288)
    }

    if ((if (__param_cflags & 1024) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 131072)
    }

    if ((if (__param_cflags & 512) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 262144)
    }

    ((unsafe: *__param_preg).re_cflags = __param_cflags)

    ((unsafe: *__param_preg).re_pcre2_code = ((pcre2_compile_8((__param_pattern as *const u8), __local_patlen, __local_options, (&raw mut __local_errorcode as *mut c_int), (&raw mut __local_erroffset as *mut c_ulong), null) as *mut c_void)))

    ((unsafe: *__param_preg).re_erroffset = __local_erroffset)

    if ((if __param_preg.re_pcre2_code == null: 1 else: 0) != 0) {
        var __local_i: c_uint

        if ((if __local_errorcode < 100: 1 else: 0) != 0) {
            return REG_BADPAT
        }

        (__local_errorcode = __local_errorcode - 100)

        if ((if __local_errorcode < (((((24 * sizeof[c_int]()) as c_ulong) / (4 as c_ulong)) as c_int)): 1 else: 0) != 0) {
            return eint1[__local_errorcode]
        }

        (__local_i = 0)

        while ((if __local_i < (((16 * sizeof[c_int]()) as c_ulong) / (4 as c_ulong)): 1 else: 0) != 0) {
            if ((if __local_errorcode == eint2[__local_i]: 1 else: 0) != 0) {
                return eint2[((__local_i as c_uint) +% (1 as c_uint))]
            }

            (__local_i = __local_i + 2)

        }


        return REG_BADPAT

    }

    pcre2_pattern_info_8((__param_preg.re_pcre2_code as *const pcre2_real_code_8), 4, (&raw mut __local_re_nsub as *mut c_int))

    ((unsafe: *__param_preg).re_nsub = ((__local_re_nsub as c_ulong)))

    ((unsafe: *__param_preg).re_match_data = ((pcre2_match_data_create_8((__local_re_nsub + 1), null) as *mut c_void)))

    ((unsafe: *__param_preg).re_erroffset = ((-1 as c_ulong)))

    if ((if __param_preg.re_match_data == null: 1 else: 0) != 0) {
        pcre2_code_free_8(__param_preg.re_pcre2_code)

        ((unsafe: *__param_preg).re_pcre2_code = null)

        return REG_ESPACE

    }

    return 0

}

@[c_export("pcre2_regexec")]
fn pcre2_regexec(__param_preg: *const regex_t, __param_string: *const i8, __param_nmatch: c_ulong, __param_pmatch: *mut regmatch_t, __param_eflags: c_int) -> c_int {
    var __local_nmatch = __param_nmatch
    var __local_rc: c_int

    var __local_so: c_int

    var __local_eo: c_int


    var __local_options: c_int = 0

    var __local_md: *mut pcre2_real_match_data_8 = ((__param_preg.re_match_data as *mut pcre2_real_match_data_8))

    if ((if __param_string == null: 1 else: 0) != 0) {
        return REG_INVARG
    }

    if ((if (__param_eflags & 4) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 1)
    }

    if ((if (__param_eflags & 8) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 2)
    }

    if ((if (__param_eflags & 256) != 0: 1 else: 0) != 0) {
        (__local_options = __local_options | 4)
    }

    var __ci_expr_logic_0: c_int

    if ((if (__param_preg.re_cflags & 32) != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (&(unsafe: __param_pmatch[0]) as *mut c_void) == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_nmatch = 0)
    }


    if ((if (__param_eflags & 128) != 0: 1 else: 0) != 0) {
        if ((if (&(unsafe: __param_pmatch[0]) as *mut c_void) == null: 1 else: 0) != 0) {
            return REG_INVARG
        }

        (__local_so = (unsafe: __param_pmatch[0]).rm_so)

        (__local_eo = (unsafe: __param_pmatch[0]).rm_eo)

    } else {
        (__local_so = 0)

        (__local_eo = ((string_len(__param_string) as c_int)))

    }

    (__local_rc = pcre2_match_8((__param_preg.re_pcre2_code as *const pcre2_real_code_8), ((__param_string as *const u8) + ((__local_so as isize) as usize)), (__local_eo - __local_so), 0, __local_options, __local_md, null))

    if ((if __local_rc >= 0: 1 else: 0) != 0) {
        var __local_i: c_ulong

        var __local_ovector: *mut c_ulong = pcre2_get_ovector_pointer_8(__local_md)

        if ((if ((__local_rc as c_ulong)) > __local_nmatch: 1 else: 0) != 0) {
            (__local_rc = ((__local_nmatch as c_int)))
        }

        (__local_i = 0)

        while ((if __local_i < ((__local_rc as c_ulong)): 1 else: 0) != 0) {
            var __ci_expr_ternary_1: c_int = 0

            if ((if (unsafe: __local_ovector[((__local_i as c_ulong) *% (2 as c_ulong))]) == (~(0 as c_ulong)): 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = -1)
            } else {
                (__ci_expr_ternary_1 = (((((unsafe: __local_ovector[((__local_i as c_ulong) *% (2 as c_ulong))]) as c_ulong) +% (__local_so as c_ulong)) as c_int)))
            }

            ((unsafe: __param_pmatch[__local_i]).rm_so = __ci_expr_ternary_1)


            var __ci_expr_ternary_2: c_int = 0

            if ((if (unsafe: __local_ovector[((((__local_i as c_ulong) *% (2 as c_ulong)) as c_ulong) +% (1 as c_ulong))]) == (~(0 as c_ulong)): 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = -1)
            } else {
                (__ci_expr_ternary_2 = (((((unsafe: __local_ovector[((((__local_i as c_ulong) *% (2 as c_ulong)) as c_ulong) +% (1 as c_ulong))]) as c_ulong) +% (__local_so as c_ulong)) as c_int)))
            }

            ((unsafe: __param_pmatch[__local_i]).rm_eo = __ci_expr_ternary_2)



            (__local_i = __local_i + 1)

        }


        while ((if __local_i < __local_nmatch: 1 else: 0) != 0) {
            ((unsafe: __param_pmatch[__local_i]).rm_eo = -1)

            ((unsafe: __param_pmatch[__local_i]).rm_so = (unsafe: __param_pmatch[__local_i]).rm_eo)


            (__local_i = __local_i + 1)

        }

        return 0

    }

    var __ci_expr_logic_3: c_int = 0

    if ((if __local_rc <= -3: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if (if __local_rc >= -23: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return REG_INVARG
    }


    match __local_rc {
        -63 => {
            return REG_ESPACE
        },
        -1 => {
            return REG_NOMATCH
        },
        -32 => {
            return REG_INVARG
        },
        -31 => {
            return REG_INVARG
        },
        -34 => {
            return REG_INVARG
        },
        -36 => {
            return REG_INVARG
        },
        -47 => {
            return REG_ESPACE
        },
        -48 => {
            return REG_ESPACE
        },
        -51 => {
            return REG_INVARG
        },
        _ => {
            return REG_ASSERT
        },
    }

}

@[c_export("pcre2_regerror")]
fn pcre2_regerror(__param_errcode: c_int, __param_preg: *const regex_t, __param_errbuf: *mut i8, __param_errbuf_size: c_ulong) -> c_ulong {
    var __local_message: *const c_char

    var __local_offset_buf: [23]c_char

    var __local_snprintf_rc: c_int

    var __local_have_offset: c_int = 0


    var __local_i: c_ulong

    var __ci_expr_ternary_1: *const c_char = null

    var __ci_expr_logic_0: c_int

    if ((if __param_errcode <= 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_errcode >= (((((18 * sizeof[usize]()) as c_ulong) / (sizeof[usize]() as c_ulong)) as c_int)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = (("unknown error code" as *const c_char)))
    } else {
        (__ci_expr_ternary_1 = ((pstring[__param_errcode] as *const c_char)))
    }

    (__local_message = ((__ci_expr_ternary_1 as *const c_char)))


    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    if ((if __param_preg != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __param_preg.re_erroffset != ((-1 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__local_snprintf_rc = snprintf((&(unsafe: __local_offset_buf[0]) as *mut c_char), (23 * sizeof[c_char]()), " at offset %d", (__param_preg.re_erroffset as c_int)))

        (__ci_expr_logic_3 = (if (if __local_snprintf_rc > 0: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if (if __local_snprintf_rc < (((23 * sizeof[c_char]()) as c_int)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__local_have_offset = 1)

        (__local_offset_buf[(((23 * sizeof[c_char]()) as c_ulong) -% (1 as c_ulong))] = 0)

    }


    (__local_i = 0)

    while ((if (unsafe: *__local_message) != 0: 1 else: 0) != 0) {
        if ((if ((__local_i as c_ulong) +% (1 as c_ulong)) < __param_errbuf_size: 1 else: 0) != 0) {
            ((unsafe: __param_errbuf[__local_i]) = (unsafe: *__local_message))
        }

        (__local_i = __local_i + 1)

        (__local_message = __local_message + 1)


    }


    if (__local_have_offset != 0) {
        (__local_message = (&(unsafe: __local_offset_buf[0]) as *const c_char))

        while ((if (unsafe: *__local_message) != 0: 1 else: 0) != 0) {
            if ((if ((__local_i as c_ulong) +% (1 as c_ulong)) < __param_errbuf_size: 1 else: 0) != 0) {
                ((unsafe: __param_errbuf[__local_i]) = (unsafe: *__local_message))
            }

            (__local_i = __local_i + 1)

            (__local_message = __local_message + 1)


        }


    }

    if ((if __param_errbuf_size > 0: 1 else: 0) != 0) {
        var __ci_expr_ternary_5: c_ulong = 0

        if ((if __local_i < __param_errbuf_size: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = __local_i)
        } else {
            (__ci_expr_ternary_5 = ((__param_errbuf_size as c_ulong) -% (1 as c_ulong)))
        }

        ((unsafe: __param_errbuf[__ci_expr_ternary_5]) = 0)

    }

    (__local_i = __local_i + 1)

    return ((__local_i as c_int))

}

@[c_export("pcre2_regfree")]
fn pcre2_regfree(__param_preg: *mut regex_t) {
    pcre2_match_data_free_8(__param_preg.re_match_data)

    pcre2_code_free_8(__param_preg.re_pcre2_code)

}

let eint1: [24]c_int = [0, REG_EESCAPE, REG_EESCAPE, REG_EESCAPE, REG_BADBR, REG_BADBR, REG_EBRACK, REG_ECTYPE, REG_ERANGE, REG_BADRPT, REG_ASSERT, REG_BADPAT, REG_BADPAT, REG_BADPAT, REG_EPAREN, REG_ESUBREG, REG_INVARG, REG_INVARG, REG_EPAREN, REG_ESIZE, REG_ESIZE, REG_ESPACE, REG_EPAREN, REG_ASSERT]
let eint2: [16]c_int = [30, REG_ECTYPE, 32, REG_INVARG, 37, REG_EESCAPE, 56, REG_INVARG, 92, REG_INVARG, 98, REG_EESCAPE, 99, REG_EESCAPE, 102, REG_EESCAPE]
let pstring: [18]*const i8 = [(("" as *mut c_char) as *const c_char), (("internal error" as *mut c_char) as *const c_char), (("invalid repeat counts in {}" as *mut c_char) as *const c_char), (("pattern error" as *mut c_char) as *const c_char), (("? * + invalid" as *mut c_char) as *const c_char), (("unbalanced {}" as *mut c_char) as *const c_char), (("unbalanced []" as *mut c_char) as *const c_char), (("collation error - not relevant" as *mut c_char) as *const c_char), (("bad class" as *mut c_char) as *const c_char), (("bad escape sequence" as *mut c_char) as *const c_char), (("empty expression" as *mut c_char) as *const c_char), (("unbalanced ()" as *mut c_char) as *const c_char), (("bad range inside []" as *mut c_char) as *const c_char), (("expression too big" as *mut c_char) as *const c_char), (("failed to get memory" as *mut c_char) as *const c_char), (("bad back reference" as *mut c_char) as *const c_char), (("bad argument" as *mut c_char) as *const c_char), (("match failed" as *mut c_char) as *const c_char)]
