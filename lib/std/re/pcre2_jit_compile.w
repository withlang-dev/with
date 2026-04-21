// Migrated from PCRE2
use std.re.defs

fn pcre2_jit_compile_8(code: *mut pcre2_real_code_8, options: c_uint) -> c_int {
    var re: *mut pcre2_real_code_8 = code

    if ((options & 512) != 0) {
        if ((if options != 512: 1 else: 0) != 0) {
            return -45
        }
        
        return -68
        
    }

    if ((if code == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if (options & (~(((1 | 2) | 4) | 256))) != 0: 1 else: 0) != 0) {
        return -45
    }

    if ((if (options & 256) != 0: 1 else: 0) != 0) {
        if ((if (re.overall_options & 67108864) == 0: 1 else: 0) != 0) {
            (re.overall_options = re.overall_options | 67108864)
            
        }
        
    }

    return -45

}

fn pcre2_jit_match_8(code: *const pcre2_real_code_8, subject: *const u8, length: c_ulong, start_offset: c_ulong, options: c_uint, match_data: *mut pcre2_real_match_data_8, mcontext: *mut pcre2_real_match_context_8) -> c_int {
    code

    subject

    length

    start_offset

    options

    mcontext

    (match_data.rc = -45)
    
    return match_data.rc
    

}

fn pcre2_jit_free_unused_memory_8(gcontext: *mut pcre2_real_general_context_8) {
    gcontext

}

fn pcre2_jit_stack_create_8(startsize: c_ulong, maxsize: c_ulong, gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8 {
    gcontext

    startsize

    maxsize

    return null

}

fn pcre2_jit_stack_assign_8(mcontext: *mut pcre2_real_match_context_8, callback: *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8, callback_data: *mut c_void) {
    mcontext

    callback

    callback_data

}

fn pcre2_jit_stack_free_8(jit_stack: *mut pcre2_real_jit_stack_8) {
    jit_stack

}

fn _pcre2_jit_free_rodata_8(current: *mut c_void, allocator_data: *mut c_void) {
    current

    allocator_data

}

fn _pcre2_jit_free_8(executable_jit: *mut c_void, memctl: *mut pcre2_memctl) {
    executable_jit

    memctl

}

fn _pcre2_jit_get_size_8(executable_jit: *mut c_void) -> c_ulong {
    executable_jit

    return 0

}

fn _pcre2_jit_get_target_8() -> *const i8 {
    return (&"JIT is not supported"[0] as *mut c_char)

}

