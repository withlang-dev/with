// Migrated from PCRE2
use std.re.defs

fn pcre2_jit_compile_8(__param_code: *mut pcre2_real_code_8, __param_options: c_uint) -> c_int {
    var __local_re: *mut pcre2_real_code_8 = __param_code

    if (((__param_options as c_uint) & (512 as c_uint)) != 0) {
        if ((if __param_options != 512: 1 else: 0) != 0) {
            return -45
        }

        return -68

    }

    if ((if __param_code == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if ((__param_options as c_uint) & ((~((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint)) as c_uint) | (256 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
        return -45
    }

    if ((if ((__param_options as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0) {
        if ((if ((__local_re.overall_options as c_uint) & (67108864 as c_uint)) == 0: 1 else: 0) != 0) {
            ((unsafe *__local_re).overall_options = __local_re.overall_options | 67108864)

        }

    }

    return -45

}

fn pcre2_jit_match_8(__param_code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, __param_start_offset: c_ulong, __param_options: c_uint, __param_match_data: *mut pcre2_real_match_data_8, __param_mcontext: *mut pcre2_real_match_context_8) -> c_int {
    __param_code

    __param_subject

    __param_length

    __param_start_offset

    __param_options

    __param_mcontext

    ((unsafe *__param_match_data).rc = -45)

    return __param_match_data.rc


}

fn pcre2_jit_free_unused_memory_8(__param_gcontext: *mut pcre2_real_general_context_8) {
    __param_gcontext

}

fn pcre2_jit_stack_create_8(__param_startsize: c_ulong, __param_maxsize: c_ulong, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8 {
    __param_gcontext

    __param_startsize

    __param_maxsize

    return null

}

fn pcre2_jit_stack_assign_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_callback: *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8, __param_callback_data: *mut c_void) {
    __param_mcontext

    __param_callback

    __param_callback_data

}

fn pcre2_jit_stack_free_8(__param_jit_stack: *mut pcre2_real_jit_stack_8) {
    __param_jit_stack

}

fn _pcre2_jit_free_rodata_8(__param_current: *mut c_void, __param_allocator_data: *mut c_void) {
    __param_current

    __param_allocator_data

}

fn _pcre2_jit_free_8(__param_executable_jit: *mut c_void, __param_memctl: *mut pcre2_memctl) {
    __param_executable_jit

    __param_memctl

}

fn _pcre2_jit_get_size_8(__param_executable_jit: *mut c_void) -> c_ulong {
    __param_executable_jit

    return 0

}

fn _pcre2_jit_get_target_8() -> *const i8 {
    return (&(unsafe "JIT is not supported"[0]) as *mut c_char)

}
