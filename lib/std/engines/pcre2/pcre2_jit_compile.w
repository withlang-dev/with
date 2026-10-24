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
use std.option

pub unsafe fn pcre2_jit_compile_8(__param_code: *mut pcre2_real_code_8, __param_options: u32) -> i32 {
    var __local_re: *mut pcre2_real_code_8 = __param_code

    if (((__param_options as u32) & (512 as u32)) != 0) {
        if ((if __param_options != 512: 1 else: 0) != 0) {
            return -45
        }

        return -68

    }

    if ((if __param_code == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if ((__param_options as u32) & ((~((((((1 as u32) | (2 as u32)) as u32) | (4 as u32)) as u32) | (256 as u32))) as u32)) != 0: 1 else: 0) != 0) {
        return -45
    }

    if ((if ((__param_options as u32) & (256 as u32)) != 0: 1 else: 0) != 0) {
        if ((if (((*__local_re).overall_options as u32) & (67108864 as u32)) == 0: 1 else: 0) != 0) {
            ((*__local_re).overall_options = ((*__local_re).overall_options as u32) | (67108864 as u32))

        }

    }

    return -45

}

pub unsafe fn pcre2_jit_match_8(__param_code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: u64, __param_start_offset: u64, __param_options: u32, __param_match_data: *mut pcre2_real_match_data_8, __param_mcontext: *mut pcre2_real_match_context_8) -> i32 {






    ((*__param_match_data).rc = ((-45 as i32)))

    return (*__param_match_data).rc


}

pub unsafe fn pcre2_jit_free_unused_memory_8(__param_gcontext: *mut pcre2_real_general_context_8) {
    return
}

pub unsafe fn pcre2_jit_stack_create_8(__param_startsize: u64, __param_maxsize: u64, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8 {



    return ((null as *mut pcre2_real_jit_stack_8))

}

pub unsafe fn pcre2_jit_stack_assign_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_callback: Option[unsafe extern "C" fn(*mut c_void) -> *mut pcre2_real_jit_stack_8], __param_callback_data: *mut c_void) {
    return
}

pub unsafe fn pcre2_jit_stack_free_8(__param_jit_stack: *mut pcre2_real_jit_stack_8) {
    return
}

pub unsafe fn _pcre2_jit_free_rodata_8(__param_current: *mut c_void, __param_allocator_data: *mut c_void) {
    return
}

pub unsafe fn _pcre2_jit_free_8(__param_executable_jit: *mut c_void, __param_memctl: *mut pcre2_memctl) {
    return
}

pub unsafe fn _pcre2_jit_get_size_8(__param_executable_jit: *mut c_void) -> u64 {

    return ((0 as u64))

}

pub fn _pcre2_jit_get_target_8() -> *const c_char {
    return (&"JIT is not supported"[0] as *mut c_char)

}
