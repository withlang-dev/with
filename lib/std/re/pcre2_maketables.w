// Migrated from C
use std.re.defs
use std.re.pcre2_config
use std.re.pcre2_context
use std.re.pcre2_convert
use std.re.pcre2_compile
use std.re.pcre2_pattern_info
use std.re.pcre2_match_data
use std.re.pcre2_dfa_match
use std.re.pcre2_match
use std.re.pcre2_match_next
use std.re.pcre2_substring
use std.re.pcre2_serialize
use std.re.pcre2_substitute
use std.re.pcre2_jit_compile
use std.re.pcre2_error
use std.re.pcre2_tables
use std.re.pcre2_chartables
use std.re.pcre2_ucd
use std.re.pcre2_auto_possess
use std.re.pcre2_chkdint
use std.re.pcre2_extuni
use std.re.pcre2_find_bracket
use std.re.pcre2_newline
use std.re.pcre2_ord2utf
use std.re.pcre2_script_run
use std.re.pcre2_string_utils
use std.re.pcre2_study
use std.re.pcre2_valid_utf
use std.re.pcre2_xclass
use std.libc

pub unsafe fn pcre2_maketables_8(__param_gcontext: *mut pcre2_real_general_context_8) -> *const u8 {
    var __local_yield_: *mut u8 = with 0 as __ci_expr_seq_9 {
        var __ci_expr_ternary_0: *mut c_void = null
        if ((if __param_gcontext != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (unsafe *(&raw const (unsafe *__param_gcontext).memctl as *const pcre2_memctl)).malloc(1088, (unsafe *(&raw const (unsafe *__param_gcontext).memctl as *const pcre2_memctl)).memory_data))
        } else {
            (__ci_expr_ternary_0 = ((with_alloc(((1088 as c_ulong) as i64)) as *mut c_void)))
        }
        (__ci_expr_ternary_0 as *mut u8)
    }

    var __local_i: c_int

    var __local_p: *mut u8

    if ((if __local_yield_ == null: 1 else: 0) != 0) {
        return ((null as *const u8))
    }

    (__local_p = __local_yield_)

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 256: 1 else: 0) != 0) {
        var __local_c: c_int = ((tolower(__local_i) as c_int))

        var __ci_expr_old_1: *mut u8 = __local_p

        (__local_p = __local_p + 1)

        var __ci_expr_ternary_2: c_int = 0

        if ((if __local_c < 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = __local_c)
        } else {
            (__ci_expr_ternary_2 = __local_i)
        }

        ((unsafe *__ci_expr_old_1) = ((__ci_expr_ternary_2 as u8)))



        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 256: 1 else: 0) != 0) {
        var __local_c_1: c_int = with 0 as __ci_expr_seq_60 {
            var __ci_expr_ternary_3: c_int = 0
            if (islower(__local_i) != 0) {
                (__ci_expr_ternary_3 = ((toupper(__local_i) as c_int)))
            } else {
                (__ci_expr_ternary_3 = ((tolower(__local_i) as c_int)))
            }
            __ci_expr_ternary_3
        }

        var __ci_expr_old_4: *mut u8 = __local_p

        (__local_p = __local_p + 1)

        var __ci_expr_ternary_5: c_int = 0

        if ((if __local_c_1 < 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = __local_c_1)
        } else {
            (__ci_expr_ternary_5 = __local_i)
        }

        ((unsafe *__ci_expr_old_4) = ((__ci_expr_ternary_5 as u8)))



        (__local_i = __local_i + 1)

    }


    with_memset(((__local_p as *mut c_void) as *mut u8), (0 as c_int), ((320 as c_ulong) as i64))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 256: 1 else: 0) != 0) {
        if (isdigit(__local_i) != 0) {
            ((unsafe __local_p[(64 + (__local_i / 8))]) = ((unsafe __local_p[(64 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (isupper(__local_i) != 0) {
            ((unsafe __local_p[(96 + (__local_i / 8))]) = ((unsafe __local_p[(96 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (islower(__local_i) != 0) {
            ((unsafe __local_p[(128 + (__local_i / 8))]) = ((unsafe __local_p[(128 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (isalnum(__local_i) != 0) {
            ((unsafe __local_p[(160 + (__local_i / 8))]) = ((unsafe __local_p[(160 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if ((if __local_i == 95: 1 else: 0) != 0) {
            ((unsafe __local_p[(160 + (__local_i / 8))]) = ((unsafe __local_p[(160 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (isspace(__local_i) != 0) {
            ((unsafe __local_p[(0 + (__local_i / 8))]) = ((unsafe __local_p[(0 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (isxdigit(__local_i) != 0) {
            ((unsafe __local_p[(32 + (__local_i / 8))]) = ((unsafe __local_p[(32 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (isgraph(__local_i) != 0) {
            ((unsafe __local_p[(192 + (__local_i / 8))]) = ((unsafe __local_p[(192 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (isprint(__local_i) != 0) {
            ((unsafe __local_p[(224 + (__local_i / 8))]) = ((unsafe __local_p[(224 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (ispunct(__local_i) != 0) {
            ((unsafe __local_p[(256 + (__local_i / 8))]) = ((unsafe __local_p[(256 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }

        if (iscntrl(__local_i) != 0) {
            ((unsafe __local_p[(288 + (__local_i / 8))]) = ((unsafe __local_p[(288 + (__local_i / 8))]) as u8) | (((1 as c_uint) << (((__local_i as c_int) & (7 as c_int)) as c_uint)) as u8))
        }


        (__local_i = __local_i + 1)

    }


    (__local_p = __local_p + ((320 as isize) as usize))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 256: 1 else: 0) != 0) {
        var __local_x: c_int = ((0 as c_int))

        if (isspace(__local_i) != 0) {
            (__local_x = __local_x + 1)
        }

        if (isalpha(__local_i) != 0) {
            (__local_x = __local_x + 2)
        }

        if (islower(__local_i) != 0) {
            (__local_x = __local_x + 4)
        }

        if (isdigit(__local_i) != 0) {
            (__local_x = __local_x + 8)
        }

        var __ci_expr_logic_6: c_int

        if (isalnum(__local_i) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if __local_i == 95: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__local_x = __local_x + 16)
        }


        var __ci_expr_old_7: *mut u8 = __local_p

        (__local_p = __local_p + 1)

        ((unsafe *__ci_expr_old_7) = ((__local_x as u8)))



        (__local_i = __local_i + 1)

    }


    return ((__local_yield_ as *const u8))

}

pub unsafe fn pcre2_maketables_free_8(__param_gcontext: *mut pcre2_real_general_context_8, __param_tables: *const u8) -> Unit {
    if ((if __param_gcontext != null: 1 else: 0) != 0) {
        (unsafe *(&raw const (unsafe *__param_gcontext).memctl as *const pcre2_memctl)).free((__param_tables as *mut c_void), (unsafe *(&raw const (unsafe *__param_gcontext).memctl as *const pcre2_memctl)).memory_data)
    } else {
        with_free(((__param_tables as *mut c_void) as *mut u8))
    }

}
