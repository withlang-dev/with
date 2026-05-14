// Migrated from PCRE2
use std.re.defs

fn pcre2_general_context_copy_8(__param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8 {
    var __local_newcontext: *mut pcre2_real_general_context_8 = (((&raw const (unsafe: *__param_gcontext).memctl as *const pcre2_memctl).malloc(sizeof[pcre2_real_general_context_8](), (&raw const (unsafe: *__param_gcontext).memctl as *const pcre2_memctl).memory_data) as *mut pcre2_real_general_context_8))

    if ((if __local_newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((__local_newcontext as *i8), (__param_gcontext as *i8), (sizeof[pcre2_real_general_context_8]() as i64))

    return __local_newcontext

}

fn pcre2_general_context_create_8(__param_private_malloc: *const fn(c_ulong, *mut c_void) -> *mut c_void, __param_private_free: *const fn(*mut c_void, *mut c_void) -> void, __param_memory_data: *mut c_void) -> *mut pcre2_real_general_context_8 {
    var __local_private_malloc = __param_private_malloc
    var __local_private_free = __param_private_free
    var __local_gcontext: *mut pcre2_real_general_context_8

    if ((if __local_private_malloc == null: 1 else: 0) != 0) {
        (__local_private_malloc = ((default_malloc as *mut fn(c_ulong, *mut c_void) -> *mut c_void)))
    }

    if ((if __local_private_free == null: 1 else: 0) != 0) {
        (__local_private_free = ((default_free as *mut fn(*mut c_void, *mut c_void) -> void)))
    }

    (__local_gcontext = ((__local_private_malloc(sizeof[pcre2_real_general_context_8](), __param_memory_data) as *mut pcre2_real_general_context_8)))

    if ((if __local_gcontext == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe: *__local_gcontext).memctl.malloc = ((__local_private_malloc as *mut fn(c_ulong, *mut c_void) -> *mut c_void)))

    ((unsafe: *__local_gcontext).memctl.free = ((__local_private_free as *mut fn(*mut c_void, *mut c_void) -> void)))

    ((unsafe: *__local_gcontext).memctl.memory_data = __param_memory_data)

    return __local_gcontext

}

fn pcre2_general_context_free_8(__param_gcontext: *mut pcre2_real_general_context_8) {
    if ((if __param_gcontext != null: 1 else: 0) != 0) {
        (&raw const (unsafe: *__param_gcontext).memctl as *const pcre2_memctl).free(__param_gcontext, (&raw const (unsafe: *__param_gcontext).memctl as *const pcre2_memctl).memory_data)
    }

}

fn pcre2_compile_context_copy_8(__param_ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8 {
    var __local_newcontext: *mut pcre2_real_compile_context_8 = (((&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).malloc(sizeof[pcre2_real_compile_context_8](), (&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).memory_data) as *mut pcre2_real_compile_context_8))

    if ((if __local_newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((__local_newcontext as *i8), (__param_ccontext as *i8), (sizeof[pcre2_real_compile_context_8]() as i64))

    return __local_newcontext

}

fn pcre2_compile_context_create_8(__param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8 {
    var __local_ccontext: *mut pcre2_real_compile_context_8 = ((_pcre2_memctl_malloc_8(sizeof[pcre2_real_compile_context_8](), (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_compile_context_8))

    if ((if __local_ccontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((&raw mut (unsafe: *__local_ccontext) as *i8), (&raw const _pcre2_default_compile_context_8 as *i8), sizeof[pcre2_real_compile_context_8]())

    if ((if __param_gcontext != null: 1 else: 0) != 0) {
        with_memcpy((&raw mut (unsafe: *(__local_ccontext as *mut pcre2_memctl)) as *i8), (&raw const (unsafe: *(__param_gcontext as *mut pcre2_memctl)) as *i8), sizeof[pcre2_memctl]())
    }

    return __local_ccontext

}

fn pcre2_compile_context_free_8(__param_ccontext: *mut pcre2_real_compile_context_8) {
    if ((if __param_ccontext != null: 1 else: 0) != 0) {
        (&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).free(__param_ccontext, (&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).memory_data)
    }

}

fn pcre2_set_bsr_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_value: c_uint) -> c_int {
    match __param_value {
        2 => {
            ((unsafe: *__param_ccontext).bsr_convention = __param_value)

            return 0

        },
        1 => {
            ((unsafe: *__param_ccontext).bsr_convention = __param_value)

            return 0

        },
        _ => {
            return -29
        },
    }

}

fn pcre2_set_character_tables_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_tables: *const u8) -> c_int {
    ((unsafe: *__param_ccontext).tables = __param_tables)

    return 0

}

fn pcre2_set_compile_extra_options_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_options: c_uint) -> c_int {
    ((unsafe: *__param_ccontext).extra_options = __param_options)

    return 0

}

fn pcre2_set_max_pattern_length_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_length: c_ulong) -> c_int {
    ((unsafe: *__param_ccontext).max_pattern_length = __param_length)

    return 0

}

fn pcre2_set_max_pattern_compiled_length_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_length: c_ulong) -> c_int {
    ((unsafe: *__param_ccontext).max_pattern_compiled_length = __param_length)

    return 0

}

fn pcre2_set_max_varlookbehind_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_limit: c_uint) -> c_int {
    ((unsafe: *__param_ccontext).max_varlookbehind = __param_limit)

    return 0

}

fn pcre2_set_newline_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_newline: c_uint) -> c_int {
    match __param_newline {
        1 => {
            ((unsafe: *__param_ccontext).newline_convention = __param_newline)

            return 0

        },
        2 => {
            ((unsafe: *__param_ccontext).newline_convention = __param_newline)

            return 0

        },
        3 => {
            ((unsafe: *__param_ccontext).newline_convention = __param_newline)

            return 0

        },
        4 => {
            ((unsafe: *__param_ccontext).newline_convention = __param_newline)

            return 0

        },
        5 => {
            ((unsafe: *__param_ccontext).newline_convention = __param_newline)

            return 0

        },
        6 => {
            ((unsafe: *__param_ccontext).newline_convention = __param_newline)

            return 0

        },
        _ => {
            return -29
        },
    }

}

fn pcre2_set_parens_nest_limit_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_limit: c_uint) -> c_int {
    ((unsafe: *__param_ccontext).parens_nest_limit = __param_limit)

    return 0

}

fn pcre2_set_compile_recursion_guard_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_guard: *const fn(c_uint, *mut c_void) -> c_int, __param_user_data: *mut c_void) -> c_int {
    ((unsafe: *__param_ccontext).stack_guard = ((__param_guard as *mut fn(c_uint, *mut c_void) -> c_int)))

    ((unsafe: *__param_ccontext).stack_guard_data = __param_user_data)

    return 0

}

fn pcre2_set_optimize_8(__param_ccontext: *mut pcre2_real_compile_context_8, __param_directive: c_uint) -> c_int {
    if ((if __param_ccontext == null: 1 else: 0) != 0) {
        return -51
    }

    while true {
        match __param_directive {
            0 => {
                ((unsafe: *__param_ccontext).optimization_flags = 0)
            },
            1 => {
                ((unsafe: *__param_ccontext).optimization_flags = 7)
            },
            _ => {
                var __ci_expr_logic_0: c_int = 0

                if ((if __param_directive >= 64: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __param_directive <= 69: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    if ((if ((__param_directive as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
                        ((unsafe: *__param_ccontext).optimization_flags = __param_ccontext.optimization_flags & (~((1 as c_uint) << (((((__param_directive as c_uint) >> (1 as c_uint)) as c_uint) -% (32 as c_uint)) as c_uint))))
                    } else {
                        ((unsafe: *__param_ccontext).optimization_flags = __param_ccontext.optimization_flags | ((1 as c_uint) << (((((__param_directive as c_uint) >> (1 as c_uint)) as c_uint) -% (32 as c_uint)) as c_uint)))
                    }

                    return 0

                }


                return -34

            },
        }

        break

    }

    return 0

}

fn pcre2_convert_context_copy_8(__param_ccontext: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8 {
    var __local_newcontext: *mut pcre2_real_convert_context_8 = (((&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).malloc(sizeof[pcre2_real_convert_context_8](), (&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).memory_data) as *mut pcre2_real_convert_context_8))

    if ((if __local_newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((__local_newcontext as *i8), (__param_ccontext as *i8), (sizeof[pcre2_real_convert_context_8]() as i64))

    return __local_newcontext

}

fn pcre2_convert_context_create_8(__param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8 {
    var __local_ccontext: *mut pcre2_real_convert_context_8 = ((_pcre2_memctl_malloc_8(sizeof[pcre2_real_convert_context_8](), (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_convert_context_8))

    if ((if __local_ccontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((&raw mut (unsafe: *__local_ccontext) as *i8), (&raw const _pcre2_default_convert_context_8 as *i8), sizeof[pcre2_real_convert_context_8]())

    if ((if __param_gcontext != null: 1 else: 0) != 0) {
        with_memcpy((&raw mut (unsafe: *(__local_ccontext as *mut pcre2_memctl)) as *i8), (&raw const (unsafe: *(__param_gcontext as *mut pcre2_memctl)) as *i8), sizeof[pcre2_memctl]())
    }

    return __local_ccontext

}

fn pcre2_convert_context_free_8(__param_ccontext: *mut pcre2_real_convert_context_8) {
    if ((if __param_ccontext != null: 1 else: 0) != 0) {
        (&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).free(__param_ccontext, (&raw const (unsafe: *__param_ccontext).memctl as *const pcre2_memctl).memory_data)
    }

}

fn pcre2_set_glob_escape_8(__param_ccontext: *mut pcre2_real_convert_context_8, __param_escape: c_uint) -> c_int {
    var __ci_expr_logic_1: c_int

    if ((if __param_escape > 255: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0

        if ((if __param_escape != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if string_find_char(globpunct, __param_escape) == null: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -29
    }


    ((unsafe: *__param_ccontext).glob_escape = __param_escape)

    return 0

}

fn pcre2_set_glob_separator_8(__param_ccontext: *mut pcre2_real_convert_context_8, __param_separator: c_uint) -> c_int {
    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_separator != 47: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_separator != 92: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if __param_separator != 46: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -29
    }


    ((unsafe: *__param_ccontext).glob_separator = __param_separator)

    return 0

}

fn pcre2_match_context_copy_8(__param_mcontext: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8 {
    var __local_newcontext: *mut pcre2_real_match_context_8 = (((&raw const (unsafe: *__param_mcontext).memctl as *const pcre2_memctl).malloc(sizeof[pcre2_real_match_context_8](), (&raw const (unsafe: *__param_mcontext).memctl as *const pcre2_memctl).memory_data) as *mut pcre2_real_match_context_8))

    if ((if __local_newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((__local_newcontext as *i8), (__param_mcontext as *i8), (sizeof[pcre2_real_match_context_8]() as i64))

    return __local_newcontext

}

fn pcre2_match_context_create_8(__param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8 {
    var __local_mcontext: *mut pcre2_real_match_context_8 = ((_pcre2_memctl_malloc_8(sizeof[pcre2_real_match_context_8](), (__param_gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_context_8))

    if ((if __local_mcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((&raw mut (unsafe: *__local_mcontext) as *i8), (&raw const _pcre2_default_match_context_8 as *i8), sizeof[pcre2_real_match_context_8]())

    if ((if __param_gcontext != null: 1 else: 0) != 0) {
        with_memcpy((&raw mut (unsafe: *(__local_mcontext as *mut pcre2_memctl)) as *i8), (&raw const (unsafe: *(__param_gcontext as *mut pcre2_memctl)) as *i8), sizeof[pcre2_memctl]())
    }

    return __local_mcontext

}

fn pcre2_match_context_free_8(__param_mcontext: *mut pcre2_real_match_context_8) {
    if ((if __param_mcontext != null: 1 else: 0) != 0) {
        (&raw const (unsafe: *__param_mcontext).memctl as *const pcre2_memctl).free(__param_mcontext, (&raw const (unsafe: *__param_mcontext).memctl as *const pcre2_memctl).memory_data)
    }

}

fn pcre2_set_callout_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, __param_callout_data: *mut c_void) -> c_int {
    ((unsafe: *__param_mcontext).callout = ((__param_callout as *mut fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int)))

    ((unsafe: *__param_mcontext).callout_data = __param_callout_data)

    return 0

}

fn pcre2_set_substitute_callout_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, __param_substitute_callout_data: *mut c_void) -> c_int {
    ((unsafe: *__param_mcontext).substitute_callout = ((__param_substitute_callout as *mut fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int)))

    ((unsafe: *__param_mcontext).substitute_callout_data = __param_substitute_callout_data)

    return 0

}

fn pcre2_set_substitute_case_callout_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, __param_substitute_case_callout_data: *mut c_void) -> c_int {
    ((unsafe: *__param_mcontext).substitute_case_callout = ((__param_substitute_case_callout as *mut fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)))

    ((unsafe: *__param_mcontext).substitute_case_callout_data = __param_substitute_case_callout_data)

    return 0

}

fn pcre2_set_depth_limit_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_limit: c_uint) -> c_int {
    ((unsafe: *__param_mcontext).depth_limit = __param_limit)

    return 0

}

fn pcre2_set_heap_limit_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_limit: c_uint) -> c_int {
    ((unsafe: *__param_mcontext).heap_limit = __param_limit)

    return 0

}

fn pcre2_set_match_limit_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_limit: c_uint) -> c_int {
    ((unsafe: *__param_mcontext).match_limit = __param_limit)

    return 0

}

fn pcre2_set_offset_limit_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_limit: c_ulong) -> c_int {
    ((unsafe: *__param_mcontext).offset_limit = __param_limit)

    return 0

}

fn pcre2_set_recursion_limit_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_limit: c_uint) -> c_int {
    return pcre2_set_depth_limit_8(__param_mcontext, __param_limit)

}

fn pcre2_set_recursion_memory_management_8(__param_mcontext: *mut pcre2_real_match_context_8, __param_mymalloc: *const fn(c_ulong, *mut c_void) -> *mut c_void, __param_myfree: *const fn(*mut c_void, *mut c_void) -> void, __param_mydata: *mut c_void) -> c_int {
    __param_mcontext

    __param_mymalloc

    __param_myfree

    __param_mydata

    return 0

}

fn _pcre2_memctl_malloc_8(__param_size: c_ulong, __param_memctl: *mut pcre2_memctl) -> *mut c_void {
    var __local_newmemctl: *mut pcre2_memctl

    var __local_yield_: *mut c_void = with 0 as __ci_expr_seq_10 {
        var __ci_expr_ternary_0: *mut c_void = null
        if ((if __param_memctl == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((with_alloc((__param_size as i64)) as *mut c_void)))
        } else {
            (__ci_expr_ternary_0 = __param_memctl.malloc(__param_size, __param_memctl.memory_data))
        }
        __ci_expr_ternary_0
    }

    if ((if __local_yield_ == null: 1 else: 0) != 0) {
        return null
    }

    (__local_newmemctl = ((__local_yield_ as *mut pcre2_memctl)))

    if ((if __param_memctl == null: 1 else: 0) != 0) {
        ((unsafe: *__local_newmemctl).malloc = ((default_malloc as *mut fn(c_ulong, *mut c_void) -> *mut c_void)))

        ((unsafe: *__local_newmemctl).free = ((default_free as *mut fn(*mut c_void, *mut c_void) -> void)))

        ((unsafe: *__local_newmemctl).memory_data = null)

    } else {
        with_memcpy((&raw mut (unsafe: *__local_newmemctl) as *i8), (&raw const (unsafe: *__param_memctl) as *i8), sizeof[pcre2_memctl]())
    }

    return __local_yield_

}

fn default_malloc(__param_size: c_ulong, __param_data: *mut c_void) -> *mut c_void {
    __param_data

    return ((with_alloc((__param_size as i64)) as *mut c_void))

}

fn default_free(__param_block: *mut c_void, __param_data: *mut c_void) {
    __param_data

    with_free((__param_block as *mut i8))

}

var globpunct: *const i8 = "\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x3a\x3b\x3c\x3d\x3e\x3f\x40\x5b\x5c\x5d\x5e\x5f\x60\x7b\x7c\x7d\x7e"
