// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
use std.engines.pcre2.pcre2_compile
use std.engines.pcre2.pcre2_pattern_info
use std.engines.pcre2.pcre2_match_data
use std.engines.pcre2.pcre2_dfa_match
use std.engines.pcre2.pcre2_match
use std.engines.pcre2.pcre2_match_next
use std.engines.pcre2.pcre2_substring
use std.engines.pcre2.pcre2_serialize
use std.engines.pcre2.pcre2_substitute
use std.engines.pcre2.pcre2_jit_compile
use std.engines.pcre2.pcre2_error
use std.engines.pcre2.pcre2_maketables
use std.libc
use std.collections

pub unsafe fn pcre2_regcomp(__param_preg: *mut regex_t, __param_pattern: *const c_char, __param_cflags: i32) -> i32 writes _pcre2_default_compile_context_8 {
    var __local_erroffset: u64

    var __local_patlen: u64

    var __local_errorcode: i32

    var __local_options: i32 = ((0 as i32))

    var __local_re_nsub: i32 = ((0 as i32))

    ((*__param_preg).re_match_data = null)

    ((*__param_preg).re_pcre2_code = null)

    (__local_patlen = (((if (if ((__param_cflags as i32) & (2048 as i32)) != 0: 1 else: 0) != 0: ((((((*__param_preg).re_endp as usize) -% (__param_pattern as usize)) as i64) / (sizeof[c_char]() as i64)) as u64) else: ((~(0 as u64)) as u64)) as u64)))

    if ((if ((__param_cflags as i32) & (1 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (8 as i32))
    }

    if ((if ((__param_cflags as i32) & (2 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (1024 as i32))
    }

    if ((if ((__param_cflags as i32) & (16 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (32 as i32))
    }

    if ((if ((__param_cflags as i32) & (4096 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (33554432 as i32))
    }

    if ((if ((__param_cflags as i32) & (64 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (524288 as i32))
    }

    if ((if ((__param_cflags as i32) & (1024 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (131072 as i32))
    }

    if ((if ((__param_cflags as i32) & (512 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (262144 as i32))
    }

    ((*__param_preg).re_cflags = __param_cflags)

    ((*__param_preg).re_pcre2_code = ((pcre2_compile_8((__param_pattern as *const u8), __local_patlen, (__local_options as u32), (&raw mut __local_errorcode as *mut i32), (&raw mut __local_erroffset as *mut u64), (null as *mut pcre2_real_compile_context_8)) as *mut c_void)))

    ((*__param_preg).re_erroffset = __local_erroffset)

    if ((if (*__param_preg).re_pcre2_code == null: 1 else: 0) != 0) {
        var __local_i: u32

        if ((if __local_errorcode < 100: 1 else: 0) != 0) {
            return REG_BADPAT
        }

        (__local_errorcode = __local_errorcode - 100)

        if ((if __local_errorcode < (((((24 * (sizeof[i32]() as usize)) as u64) / (4 as u64)) as i32)): 1 else: 0) != 0) {
            return eint1[__local_errorcode]
        }

        (__local_i = ((0 as u32)))

        while ((if __local_i < (((16 * (sizeof[i32]() as usize)) as u64) / (4 as u64)): 1 else: 0) != 0) {
            if ((if __local_errorcode == eint2[__local_i]: 1 else: 0) != 0) {
                return eint2[((__local_i as u32) +% (1 as u32))]
            }

            (__local_i = (__local_i +% 2))

        }


        return REG_BADPAT

    }

    pcre2_pattern_info_8(((*__param_preg).re_pcre2_code as *const pcre2_real_code_8), (4 as u32), ((&raw mut __local_re_nsub as *mut i32) as *mut c_void))

    ((*__param_preg).re_nsub = ((__local_re_nsub as u64)))

    ((*__param_preg).re_match_data = ((pcre2_match_data_create_8(((__local_re_nsub + 1) as u32), (null as *mut pcre2_real_general_context_8)) as *mut c_void)))

    ((*__param_preg).re_erroffset = ((-1 as u64)))

    if ((if (*__param_preg).re_match_data == null: 1 else: 0) != 0) {
        pcre2_code_free_8(((*__param_preg).re_pcre2_code as *mut pcre2_real_code_8))

        ((*__param_preg).re_pcre2_code = null)

        return REG_ESPACE

    }

    return 0

}

pub unsafe fn pcre2_regexec(__param_preg: *const regex_t, __param_string: *const c_char, __param_nmatch: u64, __param_pmatch: *mut regmatch_t, __param_eflags: i32) -> i32 writes _pcre2_default_match_context_8 {
    var __local_nmatch = __param_nmatch
    var __local_rc: i32

    var __local_so: i32

    var __local_eo: i32


    var __local_options: i32 = ((0 as i32))

    var __local_md: *mut pcre2_real_match_data_8 = (((*__param_preg).re_match_data as *mut pcre2_real_match_data_8))

    if ((if __param_string == null: 1 else: 0) != 0) {
        return REG_INVARG
    }

    if ((if ((__param_eflags as i32) & (4 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (1 as i32))
    }

    if ((if ((__param_eflags as i32) & (8 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (2 as i32))
    }

    if ((if ((__param_eflags as i32) & (256 as i32)) != 0: 1 else: 0) != 0) {
        (__local_options = (__local_options as i32) | (4 as i32))
    }

    var __ci_expr_logic_0: i32

    if ((if (((*__param_preg).re_cflags as i32) & (32 as i32)) != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (&(__param_pmatch[0]) as *mut c_void) == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_nmatch = ((0 as u64)))
    }


    if ((if ((__param_eflags as i32) & (128 as i32)) != 0: 1 else: 0) != 0) {
        if ((if (&(__param_pmatch[0]) as *mut c_void) == null: 1 else: 0) != 0) {
            return REG_INVARG
        }

        (__local_so = (__param_pmatch[0]).rm_so)

        (__local_eo = (__param_pmatch[0]).rm_eo)

    } else {
        (__local_so = ((0 as i32)))

        (__local_eo = ((strlen(__param_string) as i32)))

    }

    (__local_rc = ((pcre2_match_8(((*__param_preg).re_pcre2_code as *const pcre2_real_code_8), ((__param_string as *const u8) + ((__local_so as isize) as usize)), ((__local_eo - __local_so) as u64), (0 as u64), (__local_options as u32), __local_md, (null as *mut pcre2_real_match_context_8)) as i32)))

    if ((if __local_rc >= 0: 1 else: 0) != 0) {
        var __local_i: u64

        var __local_ovector: *mut u64 = pcre2_get_ovector_pointer_8(__local_md)

        if ((if ((__local_rc as u64)) > __local_nmatch: 1 else: 0) != 0) {
            (__local_rc = ((__local_nmatch as i32)))
        }

        (__local_i = ((0 as u64)))

        while ((if __local_i < ((__local_rc as u64)): 1 else: 0) != 0) {
            ((__param_pmatch[__local_i]).rm_so = (((if (if (__local_ovector[((__local_i as u64) *% (2 as u64))]) == (~(0 as u64)): 1 else: 0) != 0: (-1 as i32) else: ((((__local_ovector[((__local_i as u64) *% (2 as u64))]) as u64) +% (__local_so as u64)) as i32)) as i32)))

            ((__param_pmatch[__local_i]).rm_eo = (((if (if (__local_ovector[((((__local_i as u64) *% (2 as u64)) as u64) +% (1 as u64))]) == (~(0 as u64)): 1 else: 0) != 0: (-1 as i32) else: ((((__local_ovector[((((__local_i as u64) *% (2 as u64)) as u64) +% (1 as u64))]) as u64) +% (__local_so as u64)) as i32)) as i32)))


            (__local_i = (__local_i +% 1))

        }


        while ((if __local_i < __local_nmatch: 1 else: 0) != 0) {
            ((__param_pmatch[__local_i]).rm_eo = ((-1 as i32)))

            ((__param_pmatch[__local_i]).rm_so = (__param_pmatch[__local_i]).rm_eo)


            (__local_i = (__local_i +% 1))

        }

        return 0

    }

    var __ci_expr_logic_1: i32 = 0

    if ((if __local_rc <= -3: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __local_rc >= -23: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
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

pub unsafe fn pcre2_regerror(__param_errcode: i32, __param_preg: *const regex_t, __param_errbuf: *mut c_char, __param_errbuf_size: u64) -> u64 {
    var __local_message: *const c_char

    var __local_offset_buf: List[c_char] = [0; 23]

    var __local_snprintf_rc: i32

    var __local_have_offset: i32 = ((0 as i32))


    var __local_i: u64

    var __ci_expr_ternary_1: *const c_char = null

    var __ci_expr_logic_0: i32

    if ((if __param_errcode <= 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_errcode >= (((((18 * (sizeof[usize]() as usize)) as u64) / (sizeof[usize]() as u64)) as i32)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = c"unknown error code".ptr)
    } else {
        (__ci_expr_ternary_1 = pstring[__param_errcode])
    }

    (__local_message = __ci_expr_ternary_1)


    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    if ((if __param_preg != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (*__param_preg).re_erroffset != ((-1 as u64)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__local_snprintf_rc = ((snprintf((&__local_offset_buf[0] as *mut c_char), ((23 * (sizeof[c_char]() as usize)) as u64), c" at offset %d".ptr, ((*__param_preg).re_erroffset as i32)) as i32)))

        (__ci_expr_logic_3 = (if (if __local_snprintf_rc > 0: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if (if __local_snprintf_rc < (((23 * (sizeof[c_char]() as usize)) as i32)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__local_have_offset = ((1 as i32)))

        (__local_offset_buf[(((23 * (sizeof[c_char]() as usize)) as u64) -% (1 as u64))] = ((0 as c_char)))

    }


    (__local_i = ((0 as u64)))

    while ((if (*__local_message) != 0: 1 else: 0) != 0) {
        if ((if ((__local_i as u64) +% (1 as u64)) < __param_errbuf_size: 1 else: 0) != 0) {
            ((__param_errbuf[__local_i]) = (*__local_message))
        }

        (__local_i = (__local_i +% 1))

        (__local_message = __local_message + 1)


    }


    if (__local_have_offset != 0) {
        (__local_message = (&__local_offset_buf[0] as *const c_char))

        while ((if (*__local_message) != 0: 1 else: 0) != 0) {
            if ((if ((__local_i as u64) +% (1 as u64)) < __param_errbuf_size: 1 else: 0) != 0) {
                ((__param_errbuf[__local_i]) = (*__local_message))
            }

            (__local_i = (__local_i +% 1))

            (__local_message = __local_message + 1)


        }


    }

    if ((if __param_errbuf_size > 0: 1 else: 0) != 0) {
        ((__param_errbuf[(if (if __local_i < __param_errbuf_size: 1 else: 0) != 0: __local_i else: (((__param_errbuf_size as u64) -% (1 as u64)) as u64))]) = ((0 as c_char)))
    }

    (__local_i = (__local_i +% 1))

    return (((__local_i as i32) as u64))

}

pub unsafe fn pcre2_regfree(__param_preg: *mut regex_t) {
    pcre2_match_data_free_8(((*__param_preg).re_match_data as *mut pcre2_real_match_data_8))

    pcre2_code_free_8(((*__param_preg).re_pcre2_code as *mut pcre2_real_code_8))

}

let eint1: List[i32] = [0, REG_EESCAPE, REG_EESCAPE, REG_EESCAPE, REG_BADBR, REG_BADBR, REG_EBRACK, REG_ECTYPE, REG_ERANGE, REG_BADRPT, REG_ASSERT, REG_BADPAT, REG_BADPAT, REG_BADPAT, REG_EPAREN, REG_ESUBREG, REG_INVARG, REG_INVARG, REG_EPAREN, REG_ESIZE, REG_ESIZE, REG_ESPACE, REG_EPAREN, REG_ASSERT]
let eint2: List[i32] = [30, REG_ECTYPE, 32, REG_INVARG, 37, REG_EESCAPE, 56, REG_INVARG, 92, REG_INVARG, 98, REG_EESCAPE, 99, REG_EESCAPE, 102, REG_EESCAPE]
let pstring: List[*const c_char] = [(("" as *mut c_char) as *const c_char), (("internal error" as *mut c_char) as *const c_char), (("invalid repeat counts in {}" as *mut c_char) as *const c_char), (("pattern error" as *mut c_char) as *const c_char), (("? * + invalid" as *mut c_char) as *const c_char), (("unbalanced {}" as *mut c_char) as *const c_char), (("unbalanced []" as *mut c_char) as *const c_char), (("collation error - not relevant" as *mut c_char) as *const c_char), (("bad class" as *mut c_char) as *const c_char), (("bad escape sequence" as *mut c_char) as *const c_char), (("empty expression" as *mut c_char) as *const c_char), (("unbalanced ()" as *mut c_char) as *const c_char), (("bad range inside []" as *mut c_char) as *const c_char), (("expression too big" as *mut c_char) as *const c_char), (("failed to get memory" as *mut c_char) as *const c_char), (("bad back reference" as *mut c_char) as *const c_char), (("bad argument" as *mut c_char) as *const c_char), (("match failed" as *mut c_char) as *const c_char)]
