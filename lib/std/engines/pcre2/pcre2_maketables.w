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
use std.engines.pcre2.pcre2_tables
use std.engines.pcre2.pcre2_chartables
use std.engines.pcre2.pcre2_ucd
use std.engines.pcre2.pcre2_auto_possess
use std.engines.pcre2.pcre2_chkdint
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass
use std.libc

// contract: unproved:0:malloc is outside the corpus and not a known pure reader
pub unsafe fn pcre2_maketables_8(__param_gcontext: *mut pcre2_real_general_context_8) -> *const u8 {
    var __local_yield_: *mut u8 = (((if __param_gcontext != null: (*(&raw const (*__param_gcontext).memctl as *const pcre2_memctl)).malloc.unwrap()((1088 as u64), (*(&raw const (*__param_gcontext).memctl as *const pcre2_memctl)).memory_data) else: (with_alloc(((1088 as u64) as i64)) as *mut c_void)) as *mut u8))

    var __local_i: i32

    var __local_p: *mut u8

    if (__local_yield_ == null) {
        return ((null as *const u8))
    }

    (__local_p = __local_yield_)

    (__local_i = ((0 as i32)))

    while (__local_i < 256) {
        var __local_c: i32 = ((tolower(__local_i) as i32))

        var __ci_expr_old_0: *mut u8 = __local_p

        (__local_p = __local_p + 1)

        ((*__ci_expr_old_0) = (((if __local_c < 256: __local_c else: __local_i) as u8)))



        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as i32)))

    while (__local_i < 256) {
        var __local_c_1: i32 = (((if islower(__local_i): (toupper(__local_i) as i32) else: (tolower(__local_i) as i32)) as i32))

        var __ci_expr_old_1: *mut u8 = __local_p

        (__local_p = __local_p + 1)

        ((*__ci_expr_old_1) = (((if __local_c_1 < 256: __local_c_1 else: __local_i) as u8)))



        (__local_i = __local_i + 1)

    }


    with_memset(((__local_p as *mut c_void) as *mut u8), (0 as i32), ((320 as u64) as i64))

    (__local_i = ((0 as i32)))

    while (__local_i < 256) {
        if isdigit(__local_i) {
            ((__local_p[(64 + (__local_i / 8))]) = ((__local_p[(64 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if isupper(__local_i) {
            ((__local_p[(96 + (__local_i / 8))]) = ((__local_p[(96 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if islower(__local_i) {
            ((__local_p[(128 + (__local_i / 8))]) = ((__local_p[(128 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if isalnum(__local_i) {
            ((__local_p[(160 + (__local_i / 8))]) = ((__local_p[(160 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if (__local_i == 95) {
            ((__local_p[(160 + (__local_i / 8))]) = ((__local_p[(160 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if isspace(__local_i) {
            ((__local_p[(0 + (__local_i / 8))]) = ((__local_p[(0 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if isxdigit(__local_i) {
            ((__local_p[(32 + (__local_i / 8))]) = ((__local_p[(32 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if isgraph(__local_i) {
            ((__local_p[(192 + (__local_i / 8))]) = ((__local_p[(192 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if isprint(__local_i) {
            ((__local_p[(224 + (__local_i / 8))]) = ((__local_p[(224 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if ispunct(__local_i) {
            ((__local_p[(256 + (__local_i / 8))]) = ((__local_p[(256 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }

        if iscntrl(__local_i) {
            ((__local_p[(288 + (__local_i / 8))]) = ((__local_p[(288 + (__local_i / 8))]) as u8) | (((1 as u32) << (((__local_i as i32) & (7 as i32)) as u32)) as u8))
        }


        (__local_i = __local_i + 1)

    }


    (__local_p = __local_p + ((320 as isize) as usize))

    (__local_i = ((0 as i32)))

    while (__local_i < 256) {
        var __local_x: i32 = ((0 as i32))

        if isspace(__local_i) {
            (__local_x = __local_x + 1)
        }

        if isalpha(__local_i) {
            (__local_x = __local_x + 2)
        }

        if islower(__local_i) {
            (__local_x = __local_x + 4)
        }

        if isdigit(__local_i) {
            (__local_x = __local_x + 8)
        }

        var __ci_expr_logic_2: i32

        if isalnum(__local_i) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if __local_i == 95: 1 else: 0))
        }

        if __ci_expr_logic_2 {
            (__local_x = __local_x + 16)
        }


        var __ci_expr_old_3: *mut u8 = __local_p

        (__local_p = __local_p + 1)

        ((*__ci_expr_old_3) = ((__local_x as u8)))



        (__local_i = __local_i + 1)

    }


    return ((__local_yield_ as *const u8))

}

// contract: unproved:0:frees a part of it,unproved:1:read only
pub unsafe fn pcre2_maketables_free_8(__param_gcontext: *mut pcre2_real_general_context_8, __param_tables: *const u8) {
    if (__param_gcontext != null) {
        (*(&raw const (*__param_gcontext).memctl as *const pcre2_memctl)).free.unwrap()((__param_tables as *mut c_void), (*(&raw const (*__param_gcontext).memctl as *const pcre2_memctl)).memory_data)
    } else {
        with_free(((__param_tables as *mut c_void) as *mut u8))
    }

}
