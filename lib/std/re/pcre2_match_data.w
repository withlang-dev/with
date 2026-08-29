// Migrated from C
use std.re.defs
use std.re.pcre2_config
use std.re.pcre2_context
use std.re.pcre2_convert
use std.re.pcre2_compile
use std.re.pcre2_pattern_info
use std.re.pcre2_dfa_match
use std.re.pcre2_match
use std.re.pcre2_match_next
use std.re.pcre2_substring
use std.re.pcre2_serialize
use std.re.pcre2_substitute
use std.re.pcre2_jit_compile
use std.re.pcre2_error
use std.re.pcre2_maketables
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

pub unsafe fn pcre2_match_data_create_8(__param_oveccount: c_uint, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var __local_oveccount = __param_oveccount
    var __local_yield_: *mut pcre2_real_match_data_8

    if ((if __local_oveccount < 1: 1 else: 0) != 0) {
        (__local_oveccount = ((1 as c_uint)))
    }

    if ((if __local_oveccount > 65535: 1 else: 0) != 0) {
        (__local_oveccount = ((65535 as c_uint)))
    }

    (__local_yield_ = ((_pcre2_memctl_malloc_8((((120 as c_ulong) +% (((((2 as c_uint) *% (__local_oveccount as c_uint)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong)) as c_ulong), (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_data_8)))

    if ((if __local_yield_ == null: 1 else: 0) != 0) {
        return ((null as *mut pcre2_real_match_data_8))
    }

    ((unsafe *__local_yield_).oveccount = ((__local_oveccount as c_ushort)))

    ((unsafe *__local_yield_).flags = ((0 as u8)))

    ((unsafe *__local_yield_).heapframes = ((null as *mut heapframe)))

    ((unsafe *__local_yield_).heapframes_size = ((0 as c_ulong)))

    return __local_yield_

}

pub unsafe fn pcre2_match_data_create_from_pattern_8(__param_code: *const pcre2_real_code_8, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var __local_gcontext = __param_gcontext
    if ((if __param_code == null: 1 else: 0) != 0) {
        return ((null as *mut pcre2_real_match_data_8))
    }

    if ((if __local_gcontext == null: 1 else: 0) != 0) {
        (__local_gcontext = ((__param_code as *mut pcre2_real_general_context_8)))
    }

    return ((pcre2_match_data_create_8(((((unsafe *__param_code).top_bracket as c_int) + 1) as c_uint), __local_gcontext) as *mut pcre2_real_match_data_8))

}

pub unsafe fn pcre2_match_data_free_8(__param_match_data: *mut pcre2_real_match_data_8) -> Unit {
    if ((if __param_match_data != null: 1 else: 0) != 0) {
        if ((if (unsafe *__param_match_data).heapframes != null: 1 else: 0) != 0) {
            (unsafe *(&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl)).free((unsafe *__param_match_data).heapframes, (unsafe *(&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl)).memory_data)
        }

        if ((if ((((unsafe *__param_match_data).flags as c_int) as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (unsafe *(&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl)).free(((unsafe *__param_match_data).subject as *mut c_void), (unsafe *(&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl)).memory_data)
        }

        (unsafe *(&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl)).free(__param_match_data, (unsafe *(&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl)).memory_data)

    }

}

pub unsafe fn pcre2_get_mark_8(__param_match_data: *mut pcre2_real_match_data_8) -> *const u8 {
    return (unsafe *__param_match_data).mark

}

pub unsafe fn pcre2_get_match_data_size_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return ((120 as c_ulong) +% ((((2 * ((unsafe *__param_match_data).oveccount as c_int)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong))

}

pub unsafe fn pcre2_get_match_data_heapframes_size_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return (unsafe *__param_match_data).heapframes_size

}

pub unsafe fn pcre2_get_ovector_count_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_uint {
    return (((unsafe *__param_match_data).oveccount as c_uint))

}

pub unsafe fn pcre2_get_ovector_pointer_8(__param_match_data: *mut pcre2_real_match_data_8) -> *mut c_ulong {
    return (&(unsafe *__param_match_data).ovector[0] as *mut c_ulong)

}

pub unsafe fn pcre2_get_startchar_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return (unsafe *__param_match_data).startchar

}
