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

// contract: unproved:0:read only,unproved:2:out-parameter written conditionally,unproved:3:out-parameter written conditionally,unproved:4:read only
pub unsafe fn pcre2_serialize_encode_8(__param_codes: *mut *const pcre2_real_code_8, __param_number_of_codes: i32, __param_serialized_bytes: *mut *mut u8, __param_serialized_size: *mut u64, __param_gcontext: *mut pcre2_real_general_context_8) -> i32 {
    var __local_bytes: *mut u8

    var __local_dst_bytes: *mut u8

    var __local_i: i32

    var __local_total_size: u64

    var __local_re: *const pcre2_real_code_8

    var __local_tables: *const u8

    var __local_data: *mut pcre2_serialized_data

    var __local_memctl: *const pcre2_memctl = (((if __param_gcontext != null: ((&raw const (*__param_gcontext).memctl as *const pcre2_memctl) as *mut pcre2_memctl) else: ((&raw const (*(&raw const _pcre2_default_compile_context_8 as *const pcre2_real_compile_context_8)).memctl as *const pcre2_memctl) as *mut pcre2_memctl)) as *const pcre2_memctl))

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if (__param_codes == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_serialized_bytes == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if __param_serialized_size == null: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        return -51
    }


    if (__param_number_of_codes <= 0) {
        return -29
    }

    (__local_total_size = ((((sizeof[pcre2_serialized_data]() as u64) +% (1088 as u64)) as u64)))

    (__local_tables = ((null as *const u8)))

    (__local_i = ((0 as i32)))

    while (__local_i < __param_number_of_codes) {
        if ((__param_codes[__local_i]) == null) {
            return -51
        }

        (__local_re = (__param_codes[__local_i]))

        if ((*__local_re).magic_number != 1346589253) {
            return -31
        }

        if (__local_tables == null) {
            (__local_tables = (*__local_re).tables)
        } else {
            if (__local_tables != (*__local_re).tables) {
                return -30
            }
        }

        (__local_total_size = (__local_total_size +% (*__local_re).blocksize))


        (__local_i = __local_i + 1)

    }


    (__local_bytes = (((*__local_memctl).malloc.unwrap()((((__local_total_size as u64) +% (sizeof[pcre2_memctl]() as u64)) as u64), (*__local_memctl).memory_data) as *mut u8)))

    if (__local_bytes == null) {
        return -48
    }

    with_memcpy(((__local_bytes as *mut c_void) as *mut u8), ((__local_memctl as *const c_void) as *const u8), ((sizeof[pcre2_memctl]() as u64) as i64))

    (__local_bytes = __local_bytes + (sizeof[pcre2_memctl]() as usize))

    (__local_data = ((__local_bytes as *mut pcre2_serialized_data)))

    ((*__local_data).magic = ((1347564115 as u32)))

    ((*__local_data).version = ((3080202 as u32)))

    ((*__local_data).config = ((526337 as u32)))

    ((*__local_data).number_of_codes = __param_number_of_codes)

    (__local_dst_bytes = __local_bytes + (sizeof[pcre2_serialized_data]() as usize))

    with_memcpy(((__local_dst_bytes as *mut c_void) as *mut u8), ((__local_tables as *const c_void) as *const u8), ((1088 as u64) as i64))

    (__local_dst_bytes = __local_dst_bytes + ((((512 + 320) + 256) as isize) as usize))

    (__local_i = ((0 as i32)))

    while (__local_i < __param_number_of_codes) {
        (__local_re = (__param_codes[__local_i]))

        with_memcpy(((__local_dst_bytes as *mut c_void) as *mut u8), (((__local_re as *const c_char) as *const c_void) as *const u8), ((*__local_re).blocksize as i64))

        with_memset((((__local_dst_bytes + ((offsetof[pcre2_real_code_8](memctl) as usize) as usize)) as *mut c_void) as *mut u8), (0 as i32), ((sizeof[pcre2_memctl]() as u64) as i64))

        with_memset((((__local_dst_bytes + ((offsetof[pcre2_real_code_8](tables) as usize) as usize)) as *mut c_void) as *mut u8), (0 as i32), ((sizeof[usize]() as u64) as i64))

        with_memset((((__local_dst_bytes + ((offsetof[pcre2_real_code_8](executable_jit) as usize) as usize)) as *mut c_void) as *mut u8), (0 as i32), ((sizeof[usize]() as u64) as i64))

        (__local_dst_bytes = __local_dst_bytes + ((*__local_re).blocksize as usize))


        (__local_i = __local_i + 1)

    }


    ((*__param_serialized_bytes) = __local_bytes)

    ((*__param_serialized_size) = __local_total_size)

    return __param_number_of_codes

}

// contract: unproved:0:out-parameter written conditionally,unproved:2:read only,unproved:3:read only
pub unsafe fn pcre2_serialize_decode_8(__param_codes: *mut *mut pcre2_real_code_8, __param_number_of_codes: i32, __param_bytes: *const u8, __param_gcontext: *mut pcre2_real_general_context_8) -> i32 {
    var __local_number_of_codes = __param_number_of_codes
    var __local_data: *const pcre2_serialized_data = ((__param_bytes as *const pcre2_serialized_data))

    var __local_memctl: *const pcre2_memctl = (((if __param_gcontext != null: ((&raw const (*__param_gcontext).memctl as *const pcre2_memctl) as *mut pcre2_memctl) else: ((&raw const (*(&raw const _pcre2_default_compile_context_8 as *const pcre2_real_compile_context_8)).memctl as *const pcre2_memctl) as *mut pcre2_memctl)) as *const pcre2_memctl))

    var __local_src_bytes: *const u8

    var __local_dst_re: *mut pcre2_real_code_8

    var __local_tables: *mut u8

    var __local_i: i32

    var __local_j: i32


    var __ci_expr_logic_0: i32

    if (__local_data == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_codes == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        return -51
    }


    if (__local_number_of_codes <= 0) {
        return -29
    }

    if ((*__local_data).number_of_codes <= 0) {
        return -62
    }

    if ((*__local_data).magic != 1347564115) {
        return -31
    }

    if ((*__local_data).version != 3080202) {
        return -32
    }

    if ((*__local_data).config != ((((sizeof[u8]() as u64) | (((8 as u64) << (8 as u32)) as u64)) as u64) | (((sizeof[u64]() as u64) << (16 as u32)) as u64))) {
        return -32
    }

    if (__local_number_of_codes > (*__local_data).number_of_codes) {
        (__local_number_of_codes = (*__local_data).number_of_codes)
    }

    (__local_src_bytes = __param_bytes + (sizeof[pcre2_serialized_data]() as usize))

    (__local_tables = (((*__local_memctl).malloc.unwrap()((((1088 as u64) +% (sizeof[u64]() as u64)) as u64), (*__local_memctl).memory_data) as *mut u8)))

    if (__local_tables == null) {
        return -48
    }

    with_memcpy(((__local_tables as *mut c_void) as *mut u8), ((__local_src_bytes as *const c_void) as *const u8), ((1088 as u64) as i64))

    ((*((__local_tables + ((((512 + 320) + 256) as isize) as usize)) as *mut u64)) = ((__local_number_of_codes as u64)))

    (__local_src_bytes = __local_src_bytes + ((((512 + 320) + 256) as isize) as usize))

    (__local_i = ((0 as i32)))

    while (__local_i < __local_number_of_codes) {
        var __local_blocksize: u64

        with_memcpy((((&raw mut __local_blocksize as *mut u64) as *mut c_void) as *mut u8), (((__local_src_bytes + ((offsetof[pcre2_real_code_8](blocksize) as usize) as usize)) as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        if (__local_blocksize <= (sizeof[pcre2_real_code_8]() as usize)) {
            return -62
        }

        (__local_dst_re = ((_pcre2_memctl_malloc_8(__local_blocksize, (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_code_8)))

        if (__local_dst_re == null) {
            (*__local_memctl).free.unwrap()((__local_tables as *mut c_void), (*__local_memctl).memory_data)

            (__local_j = ((0 as i32)))

            while (__local_j < __local_i) {
                (*__local_memctl).free.unwrap()(((__param_codes[__local_j]) as *mut c_void), (*__local_memctl).memory_data)

                ((__param_codes[__local_j]) = ((null as *mut pcre2_real_code_8)))


                (__local_j = __local_j + 1)

            }


            return -48

        }

        with_memcpy(((((__local_dst_re as *mut u8) + (sizeof[pcre2_memctl]() as usize)) as *mut c_void) as *mut u8), (((__local_src_bytes + (sizeof[pcre2_memctl]() as usize)) as *const c_void) as *const u8), ((((__local_blocksize as u64) -% (sizeof[pcre2_memctl]() as u64)) as u64) as i64))

        var __ci_expr_logic_2: i32

        var __ci_expr_logic_1: i32

        if ((*__local_dst_re).magic_number != 1346589253) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (*__local_dst_re).name_entry_size > ((128 + 2) + 1): 1 else: 0))
        }

        if __ci_expr_logic_1 {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (*__local_dst_re).name_count > 10000: 1 else: 0))
        }

        if __ci_expr_logic_2 {
            (*__local_memctl).free.unwrap()((__local_dst_re as *mut c_void), (*__local_memctl).memory_data)

            return -62

        }


        ((*__local_dst_re).tables = ((__local_tables as *const u8)))

        ((*__local_dst_re).executable_jit = null)

        ((*__local_dst_re).flags = ((*__local_dst_re).flags as u32) | (262144 as u32))

        ((__param_codes[__local_i]) = __local_dst_re)

        (__local_src_bytes = __local_src_bytes + (__local_blocksize as usize))


        (__local_i = __local_i + 1)

    }


    return __local_number_of_codes

}

// contract: unproved:0:read only
pub unsafe fn pcre2_serialize_get_number_of_codes_8(__param_bytes: *const u8) -> i32 {
    var __local_data: *const pcre2_serialized_data = ((__param_bytes as *const pcre2_serialized_data))

    if (__local_data == null) {
        return -51
    }

    if ((*__local_data).magic != 1347564115) {
        return -31
    }

    if ((*__local_data).version != 3080202) {
        return -32
    }

    if ((*__local_data).config != ((((sizeof[u8]() as u64) | (((8 as u64) << (8 as u32)) as u64)) as u64) | (((sizeof[u64]() as u64) << (16 as u32)) as u64))) {
        return -32
    }

    return (*__local_data).number_of_codes

}

// contract: unproved:0:read only
pub unsafe fn pcre2_serialize_free_8(__param_bytes: *mut u8) {
    if (__param_bytes != null) {
        var __local_memctl: *mut pcre2_memctl = (((__param_bytes - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        (*__local_memctl).free.unwrap()((__local_memctl as *mut c_void), (*__local_memctl).memory_data)

    }

}
