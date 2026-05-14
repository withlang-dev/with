// Migrated from PCRE2
use std.re.defs

fn pcre2_match_data_create_8(__param_oveccount: c_uint, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var __local_oveccount = __param_oveccount
    var __local_yield_: *mut pcre2_real_match_data_8

    if ((if __local_oveccount < 1: 1 else: 0) != 0) {
        (__local_oveccount = 1)
    }

    if ((if __local_oveccount > 65535: 1 else: 0) != 0) {
        (__local_oveccount = 65535)
    }

    (__local_yield_ = ((_pcre2_memctl_malloc_8(((120 as c_ulong) +% (((((2 as c_uint) *% (__local_oveccount as c_uint)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong)), (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_data_8)))

    if ((if __local_yield_ == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe: *__local_yield_).oveccount = __local_oveccount)

    ((unsafe: *__local_yield_).flags = 0)

    ((unsafe: *__local_yield_).heapframes = ((null as *mut heapframe)))

    ((unsafe: *__local_yield_).heapframes_size = 0)

    return __local_yield_

}

fn pcre2_match_data_create_from_pattern_8(__param_code: *const pcre2_real_code_8, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var __local_gcontext = __param_gcontext
    if ((if __param_code == null: 1 else: 0) != 0) {
        return null
    }

    if ((if __local_gcontext == null: 1 else: 0) != 0) {
        (__local_gcontext = ((__param_code as *mut pcre2_real_general_context_8)))
    }

    return pcre2_match_data_create_8(((__param_code.top_bracket as c_int) + 1), __local_gcontext)

}

fn pcre2_match_data_free_8(__param_match_data: *mut pcre2_real_match_data_8) {
    if ((if __param_match_data != null: 1 else: 0) != 0) {
        if ((if __param_match_data.heapframes != null: 1 else: 0) != 0) {
            (&raw const (unsafe: *__param_match_data).memctl as *const pcre2_memctl).free(__param_match_data.heapframes, (&raw const (unsafe: *__param_match_data).memctl as *const pcre2_memctl).memory_data)
        }

        if ((if (((__param_match_data.flags as c_int) as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (&raw const (unsafe: *__param_match_data).memctl as *const pcre2_memctl).free((__param_match_data.subject as *mut c_void), (&raw const (unsafe: *__param_match_data).memctl as *const pcre2_memctl).memory_data)
        }

        (&raw const (unsafe: *__param_match_data).memctl as *const pcre2_memctl).free(__param_match_data, (&raw const (unsafe: *__param_match_data).memctl as *const pcre2_memctl).memory_data)

    }

}

fn pcre2_get_mark_8(__param_match_data: *mut pcre2_real_match_data_8) -> *const u8 {
    return __param_match_data.mark

}

fn pcre2_get_match_data_size_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return ((120 as c_ulong) +% ((((2 * (__param_match_data.oveccount as c_int)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong))

}

fn pcre2_get_match_data_heapframes_size_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return __param_match_data.heapframes_size

}

fn pcre2_get_ovector_count_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_uint {
    return __param_match_data.oveccount

}

fn pcre2_get_ovector_pointer_8(__param_match_data: *mut pcre2_real_match_data_8) -> *mut c_ulong {
    return (&(unsafe: __param_match_data.ovector[0]) as *mut c_ulong)

}

fn pcre2_get_startchar_8(__param_match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return __param_match_data.startchar

}
