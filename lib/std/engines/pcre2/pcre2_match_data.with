// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
use std.engines.pcre2.pcre2_compile
use std.engines.pcre2.pcre2_pattern_info
use std.engines.pcre2.pcre2_dfa_match
use std.engines.pcre2.pcre2_match
use std.engines.pcre2.pcre2_match_next
use std.engines.pcre2.pcre2_substring
use std.engines.pcre2.pcre2_serialize
use std.engines.pcre2.pcre2_substitute
use std.engines.pcre2.pcre2_jit_compile
use std.engines.pcre2.pcre2_error
use std.engines.pcre2.pcre2_maketables
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

// contract: unproved:1:read only
pub unsafe fn pcre2_match_data_create_8(__param_oveccount: u32, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var __local_oveccount = __param_oveccount
    var __local_yield_: *mut pcre2_real_match_data_8

    if (__local_oveccount < 1) {
        (__local_oveccount = ((1 as u32)))
    }

    if (__local_oveccount > 65535) {
        (__local_oveccount = ((65535 as u32)))
    }

    (__local_yield_ = ((_pcre2_memctl_malloc_8(((((offsetof[pcre2_real_match_data_8](ovector) as usize) as u64) +% (((((2 as u32) *% (__local_oveccount as u32)) as u64) *% (sizeof[u64]() as u64)) as u64)) as u64), (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_data_8)))

    if (__local_yield_ == null) {
        return ((null as *mut pcre2_real_match_data_8))
    }

    ((*__local_yield_).oveccount = ((__local_oveccount as u16)))

    ((*__local_yield_).flags = ((0 as u8)))

    ((*__local_yield_).heapframes = ((null as *mut heapframe)))

    ((*__local_yield_).heapframes_size = ((0 as u64)))

    return __local_yield_

}

// contract: stored-unknown:0,unproved:1:read only — stores an argument; ownership not modeled
pub unsafe fn pcre2_match_data_create_from_pattern_8(__param_code: *const pcre2_real_code_8, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var __local_gcontext = __param_gcontext
    if (__param_code == null) {
        return ((null as *mut pcre2_real_match_data_8))
    }

    if (__local_gcontext == null) {
        (__local_gcontext = ((__param_code as *mut pcre2_real_general_context_8)))
    }

    return ((pcre2_match_data_create_8(((((*__param_code).top_bracket as i32) + 1) as u32), __local_gcontext) as *mut pcre2_real_match_data_8))

}

// contract: unproved:0:frees a part of it
pub unsafe fn pcre2_match_data_free_8(__param_match_data: *mut pcre2_real_match_data_8) {
    if (__param_match_data != null) {
        if ((*__param_match_data).heapframes != null) {
            (*(&raw const (*__param_match_data).memctl as *const pcre2_memctl)).free.unwrap()(((*__param_match_data).heapframes as *mut c_void), (*(&raw const (*__param_match_data).memctl as *const pcre2_memctl)).memory_data)
        }

        if (((((*__param_match_data).flags as i32) as u32) & (1 as u32)) != 0) {
            (*(&raw const (*__param_match_data).memctl as *const pcre2_memctl)).free.unwrap()(((*__param_match_data).subject as *mut c_void), (*(&raw const (*__param_match_data).memctl as *const pcre2_memctl)).memory_data)
        }

        (*(&raw const (*__param_match_data).memctl as *const pcre2_memctl)).free.unwrap()((__param_match_data as *mut c_void), (*(&raw const (*__param_match_data).memctl as *const pcre2_memctl)).memory_data)

    }

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn pcre2_get_mark_8(__param_match_data: *mut pcre2_real_match_data_8) -> *const u8 {
    return (*__param_match_data).mark

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn pcre2_get_ovector_pointer_8(__param_match_data: *mut pcre2_real_match_data_8) -> *mut u64 {
    return (&(*__param_match_data).ovector[0] as *mut u64)

}

impl pcre2_real_match_data_8 {
    pub fn pcre2_get_match_data_size_8() -> u64 {
        let __param_match_data: *mut pcre2_real_match_data_8 = (self as *const pcre2_real_match_data_8) as *mut pcre2_real_match_data_8
        return (((offsetof[pcre2_real_match_data_8](ovector) as usize) as u64) +% ((((2 * ((unsafe *__param_match_data).oveccount as i32)) as u64) *% (sizeof[u64]() as u64)) as u64))

    }

    pub fn pcre2_get_match_data_heapframes_size_8() -> u64 {
        let __param_match_data: *mut pcre2_real_match_data_8 = (self as *const pcre2_real_match_data_8) as *mut pcre2_real_match_data_8
        return (unsafe *__param_match_data).heapframes_size

    }

    pub fn pcre2_get_ovector_count_8() -> u32 {
        let __param_match_data: *mut pcre2_real_match_data_8 = (self as *const pcre2_real_match_data_8) as *mut pcre2_real_match_data_8
        return (((unsafe *__param_match_data).oveccount as u32))

    }

    pub fn pcre2_get_startchar_8() -> u64 {
        let __param_match_data: *mut pcre2_real_match_data_8 = (self as *const pcre2_real_match_data_8) as *mut pcre2_real_match_data_8
        return (unsafe *__param_match_data).startchar

    }

}
