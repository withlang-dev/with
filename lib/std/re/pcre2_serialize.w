// Migrated from PCRE2
use std.re.defs

fn pcre2_serialize_encode_8(__param_codes: *mut *const pcre2_real_code_8, __param_number_of_codes: c_int, __param_serialized_bytes: *mut *mut u8, __param_serialized_size: *mut c_ulong, __param_gcontext: *mut pcre2_real_general_context_8) -> c_int {
    var __local_bytes: *mut u8

    var __local_dst_bytes: *mut u8

    var __local_i: c_int

    var __local_total_size: c_ulong

    var __local_re: *const pcre2_real_code_8

    var __local_tables: *const u8

    var __local_data: *mut pcre2_serialized_data

    var __local_memctl: *const pcre2_memctl = with 0 as __ci_expr_seq_16 {
        var __ci_expr_ternary_0: *mut pcre2_memctl = null
        if ((if __param_gcontext != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((&raw const (unsafe: *__param_gcontext).memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
        } else {
            (__ci_expr_ternary_0 = (((&raw const (unsafe: *(&raw const _pcre2_default_compile_context_8 as *const pcre2_real_compile_context_8)).memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
        }
        (__ci_expr_ternary_0 as *const pcre2_memctl)
    }

    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    if ((if __param_codes == null: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_serialized_bytes == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __param_serialized_size == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -51
    }


    if ((if __param_number_of_codes <= 0: 1 else: 0) != 0) {
        return -29
    }

    (__local_total_size = ((sizeof[pcre2_serialized_data]() as c_ulong) +% (1088 as c_ulong)))

    (__local_tables = ((null as *const u8)))

    (__local_i = 0)

    while ((if __local_i < __param_number_of_codes: 1 else: 0) != 0) {
        if ((if (unsafe: __param_codes[__local_i]) == null: 1 else: 0) != 0) {
            return -51
        }

        (__local_re = (unsafe: __param_codes[__local_i]))

        if ((if __local_re.magic_number != 1346589253: 1 else: 0) != 0) {
            return -31
        }

        if ((if __local_tables == null: 1 else: 0) != 0) {
            (__local_tables = __local_re.tables)
        } else {
            if ((if __local_tables != __local_re.tables: 1 else: 0) != 0) {
                return -30
            }
        }

        (__local_total_size = __local_total_size + __local_re.blocksize)


        (__local_i = __local_i + 1)

    }


    (__local_bytes = ((__local_memctl.malloc(((__local_total_size as c_ulong) +% (sizeof[pcre2_memctl]() as c_ulong)), __local_memctl.memory_data) as *mut u8)))

    if ((if __local_bytes == null: 1 else: 0) != 0) {
        return -48
    }

    with_memcpy((__local_bytes as *i8), (__local_memctl as *i8), (sizeof[pcre2_memctl]() as i64))

    (__local_bytes = __local_bytes + (sizeof[pcre2_memctl]() as usize))

    (__local_data = ((__local_bytes as *mut pcre2_serialized_data)))

    ((unsafe: *__local_data).magic = 1347564115)

    ((unsafe: *__local_data).version = 3080202)

    ((unsafe: *__local_data).config = 526337)

    ((unsafe: *__local_data).number_of_codes = __param_number_of_codes)

    (__local_dst_bytes = __local_bytes + (sizeof[pcre2_serialized_data]() as usize))

    with_memcpy((__local_dst_bytes as *i8), (__local_tables as *i8), (1088 as i64))

    (__local_dst_bytes = __local_dst_bytes + ((((512 + 320) + 256) as isize) as usize))

    (__local_i = 0)

    while ((if __local_i < __param_number_of_codes: 1 else: 0) != 0) {
        (__local_re = (unsafe: __param_codes[__local_i]))

        with_memcpy((__local_dst_bytes as *i8), ((__local_re as *const c_char) as *i8), (__local_re.blocksize as i64))

        with_memset(((__local_dst_bytes + (0 as usize)) as *i8), 0, (sizeof[pcre2_memctl]() as i64))

        with_memset(((__local_dst_bytes + (24 as usize)) as *i8), 0, (sizeof[usize]() as i64))

        with_memset(((__local_dst_bytes + (32 as usize)) as *i8), 0, (sizeof[usize]() as i64))

        (__local_dst_bytes = __local_dst_bytes + (__local_re.blocksize as usize))


        (__local_i = __local_i + 1)

    }


    ((unsafe: *__param_serialized_bytes) = __local_bytes)

    ((unsafe: *__param_serialized_size) = __local_total_size)

    return __param_number_of_codes

}

fn pcre2_serialize_decode_8(__param_codes: *mut *mut pcre2_real_code_8, __param_number_of_codes: c_int, __param_bytes: *const u8, __param_gcontext: *mut pcre2_real_general_context_8) -> c_int {
    var __local_number_of_codes = __param_number_of_codes
    var __local_data: *const pcre2_serialized_data = ((__param_bytes as *const pcre2_serialized_data))

    var __local_memctl: *const pcre2_memctl = with 0 as __ci_expr_seq_10 {
        var __ci_expr_ternary_0: *mut pcre2_memctl = null
        if ((if __param_gcontext != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((&raw const (unsafe: *__param_gcontext).memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
        } else {
            (__ci_expr_ternary_0 = (((&raw const (unsafe: *(&raw const _pcre2_default_compile_context_8 as *const pcre2_real_compile_context_8)).memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
        }
        (__ci_expr_ternary_0 as *const pcre2_memctl)
    }

    var __local_src_bytes: *const u8

    var __local_dst_re: *mut pcre2_real_code_8

    var __local_tables: *mut u8

    var __local_i: c_int

    var __local_j: c_int


    var __ci_expr_logic_1: c_int

    if ((if __local_data == null: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_codes == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -51
    }


    if ((if __local_number_of_codes <= 0: 1 else: 0) != 0) {
        return -29
    }

    if ((if __local_data.number_of_codes <= 0: 1 else: 0) != 0) {
        return -62
    }

    if ((if __local_data.magic != 1347564115: 1 else: 0) != 0) {
        return -31
    }

    if ((if __local_data.version != 3080202: 1 else: 0) != 0) {
        return -32
    }

    if ((if __local_data.config != ((2049 as c_ulong) | (524288 as c_ulong)): 1 else: 0) != 0) {
        return -32
    }

    if ((if __local_number_of_codes > __local_data.number_of_codes: 1 else: 0) != 0) {
        (__local_number_of_codes = __local_data.number_of_codes)
    }

    (__local_src_bytes = __param_bytes + (sizeof[pcre2_serialized_data]() as usize))

    (__local_tables = ((__local_memctl.malloc(((1088 as c_ulong) +% (sizeof[usize]() as c_ulong)), __local_memctl.memory_data) as *mut u8)))

    if ((if __local_tables == null: 1 else: 0) != 0) {
        return -48
    }

    with_memcpy((__local_tables as *i8), (__local_src_bytes as *i8), (1088 as i64))

    ((unsafe: *((__local_tables + ((((512 + 320) + 256) as isize) as usize)) as *mut c_ulong)) = __local_number_of_codes)

    (__local_src_bytes = __local_src_bytes + ((((512 + 320) + 256) as isize) as usize))

    (__local_i = 0)

    while ((if __local_i < __local_number_of_codes: 1 else: 0) != 0) {
        var __local_blocksize: c_ulong

        with_memcpy(((&raw mut __local_blocksize as *mut c_ulong) as *i8), ((__local_src_bytes + (72 as usize)) as *i8), (sizeof[c_ulong]() as i64))

        if ((if __local_blocksize <= sizeof[pcre2_real_code_8](): 1 else: 0) != 0) {
            return -62
        }

        (__local_dst_re = ((_pcre2_memctl_malloc_8(__local_blocksize, (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_code_8)))

        if ((if __local_dst_re == null: 1 else: 0) != 0) {
            __local_memctl.free(__local_tables, __local_memctl.memory_data)

            (__local_j = 0)

            while ((if __local_j < __local_i: 1 else: 0) != 0) {
                __local_memctl.free((unsafe: __param_codes[__local_j]), __local_memctl.memory_data)

                ((unsafe: __param_codes[__local_j]) = ((null as *mut pcre2_real_code_8)))


                (__local_j = __local_j + 1)

            }


            return -48

        }

        with_memcpy((((__local_dst_re as *mut u8) + (sizeof[pcre2_memctl]() as usize)) as *i8), ((__local_src_bytes + (sizeof[pcre2_memctl]() as usize)) as *i8), (((__local_blocksize as c_ulong) -% (sizeof[pcre2_memctl]() as c_ulong)) as i64))

        var __ci_expr_logic_3: c_int

        var __ci_expr_logic_2: c_int

        if ((if __local_dst_re.magic_number != 1346589253: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_dst_re.name_entry_size > ((128 + 2) + 1): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_dst_re.name_count > 10000: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            __local_memctl.free(__local_dst_re, __local_memctl.memory_data)

            return -62

        }


        ((unsafe: *__local_dst_re).tables = ((__local_tables as *const u8)))

        ((unsafe: *__local_dst_re).executable_jit = null)

        ((unsafe: *__local_dst_re).flags = __local_dst_re.flags | 262144)

        ((unsafe: __param_codes[__local_i]) = __local_dst_re)

        (__local_src_bytes = __local_src_bytes + (__local_blocksize as usize))


        (__local_i = __local_i + 1)

    }


    return __local_number_of_codes

}

fn pcre2_serialize_get_number_of_codes_8(__param_bytes: *const u8) -> c_int {
    var __local_data: *const pcre2_serialized_data = ((__param_bytes as *const pcre2_serialized_data))

    if ((if __local_data == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if __local_data.magic != 1347564115: 1 else: 0) != 0) {
        return -31
    }

    if ((if __local_data.version != 3080202: 1 else: 0) != 0) {
        return -32
    }

    if ((if __local_data.config != ((2049 as c_ulong) | (524288 as c_ulong)): 1 else: 0) != 0) {
        return -32
    }

    return __local_data.number_of_codes

}

fn pcre2_serialize_free_8(__param_bytes: *mut u8) {
    if ((if __param_bytes != null: 1 else: 0) != 0) {
        var __local_memctl: *mut pcre2_memctl = (((__param_bytes - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        __local_memctl.free(__local_memctl, __local_memctl.memory_data)

    }

}
