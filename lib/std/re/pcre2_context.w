// Migrated from PCRE2
use std.re.defs

fn pcre2_general_context_copy_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8 {
    var newcontext: *mut pcre2_real_general_context_8 = ((gcontext.memctl.malloc(sizeof[pcre2_real_general_context_8](), gcontext.memctl.memory_data) as *mut pcre2_real_general_context_8))

    if ((if newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((newcontext as *i8), (gcontext as *i8), (sizeof[pcre2_real_general_context_8]() as i64))

    return newcontext

}

fn pcre2_general_context_create_8(__param_private_malloc: *const fn(c_ulong, *mut c_void) -> *mut c_void, __param_private_free: *const fn(*mut c_void, *mut c_void) -> void, memory_data: *mut c_void) -> *mut pcre2_real_general_context_8 {
    var private_malloc = __param_private_malloc
    var private_free = __param_private_free
    var gcontext: *mut pcre2_real_general_context_8

    if ((if private_malloc == null: 1 else: 0) != 0) {
        (private_malloc = ((default_malloc as *mut fn(c_ulong, *mut c_void) -> *mut c_void)))
    }

    if ((if private_free == null: 1 else: 0) != 0) {
        (private_free = ((default_free as *mut fn(*mut c_void, *mut c_void) -> void)))
    }

    (gcontext = ((private_malloc(sizeof[pcre2_real_general_context_8](), memory_data) as *mut pcre2_real_general_context_8)))

    if ((if gcontext == null: 1 else: 0) != 0) {
        return null
    }

    (gcontext.memctl.malloc = ((private_malloc as *mut fn(c_ulong, *mut c_void) -> *mut c_void)))

    (gcontext.memctl.free = ((private_free as *mut fn(*mut c_void, *mut c_void) -> void)))

    (gcontext.memctl.memory_data = memory_data)

    return gcontext

}

fn pcre2_general_context_free_8(gcontext: *mut pcre2_real_general_context_8) {
    if ((if gcontext != null: 1 else: 0) != 0) {
        gcontext.memctl.free(gcontext, gcontext.memctl.memory_data)
    }

}

fn pcre2_compile_context_copy_8(ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8 {
    var newcontext: *mut pcre2_real_compile_context_8 = ((ccontext.memctl.malloc(sizeof[pcre2_real_compile_context_8](), ccontext.memctl.memory_data) as *mut pcre2_real_compile_context_8))

    if ((if newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((newcontext as *i8), (ccontext as *i8), (sizeof[pcre2_real_compile_context_8]() as i64))

    return newcontext

}

fn pcre2_compile_context_create_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8 {
    var ccontext: *mut pcre2_real_compile_context_8 = ((_pcre2_memctl_malloc_8(sizeof[pcre2_real_compile_context_8](), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_compile_context_8))

    if ((if ccontext == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe: *ccontext) = _pcre2_default_compile_context_8)

    if ((if gcontext != null: 1 else: 0) != 0) {
        ((unsafe: *(ccontext as *mut pcre2_memctl)) = (unsafe: *(gcontext as *mut pcre2_memctl)))
    }

    return ccontext

}

fn pcre2_compile_context_free_8(ccontext: *mut pcre2_real_compile_context_8) {
    if ((if ccontext != null: 1 else: 0) != 0) {
        ccontext.memctl.free(ccontext, ccontext.memctl.memory_data)
    }

}

fn pcre2_set_bsr_8(ccontext: *mut pcre2_real_compile_context_8, value: c_uint) -> c_int {
    match value:
        2 | 1 =>
            (ccontext.bsr_convention = value)
            
            return 0
            
            return -29
            
        _ =>
            return -29

}

fn pcre2_set_character_tables_8(ccontext: *mut pcre2_real_compile_context_8, tables: *const u8) -> c_int {
    (ccontext.tables = tables)

    return 0

}

fn pcre2_set_compile_extra_options_8(ccontext: *mut pcre2_real_compile_context_8, options: c_uint) -> c_int {
    (ccontext.extra_options = options)

    return 0

}

fn pcre2_set_max_pattern_length_8(ccontext: *mut pcre2_real_compile_context_8, length: c_ulong) -> c_int {
    (ccontext.max_pattern_length = length)

    return 0

}

fn pcre2_set_max_pattern_compiled_length_8(ccontext: *mut pcre2_real_compile_context_8, length: c_ulong) -> c_int {
    (ccontext.max_pattern_compiled_length = length)

    return 0

}

fn pcre2_set_max_varlookbehind_8(ccontext: *mut pcre2_real_compile_context_8, limit: c_uint) -> c_int {
    (ccontext.max_varlookbehind = limit)

    return 0

}

fn pcre2_set_newline_8(ccontext: *mut pcre2_real_compile_context_8, newline: c_uint) -> c_int {
    match newline:
        1 | 2 | 3 | 4 | 5 | 6 =>
            (ccontext.newline_convention = newline)
            
            return 0
            
            return -29
            
        _ =>
            return -29

}

fn pcre2_set_parens_nest_limit_8(ccontext: *mut pcre2_real_compile_context_8, limit: c_uint) -> c_int {
    (ccontext.parens_nest_limit = limit)

    return 0

}

fn pcre2_set_compile_recursion_guard_8(ccontext: *mut pcre2_real_compile_context_8, guard: *const fn(c_uint, *mut c_void) -> c_int, user_data: *mut c_void) -> c_int {
    (ccontext.stack_guard = ((guard as *mut fn(c_uint, *mut c_void) -> c_int)))

    (ccontext.stack_guard_data = user_data)

    return 0

}

fn pcre2_set_optimize_8(ccontext: *mut pcre2_real_compile_context_8, directive: c_uint) -> c_int {
    if ((if ccontext == null: 1 else: 0) != 0) {
        return -51
    }

    match directive:
        0 =>
            (ccontext.optimization_flags = 0)
        1 =>
            (ccontext.optimization_flags = 7)
        _ =>
            var __ci_expr_logic_0: c_int = 0
            
            if ((if directive >= 64: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if directive <= 69: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_0 != 0) {
                if ((if (directive & 1) != 0: 1 else: 0) != 0) {
                    (ccontext.optimization_flags = ccontext.optimization_flags & (~(1 << ((directive >> 1) -% 32))))
                } else {
                    (ccontext.optimization_flags = ccontext.optimization_flags | (1 << ((directive >> 1) -% 32)))
                }
                
                return 0
                
            }
            
            
            return -34
            

    return 0

}

fn pcre2_convert_context_copy_8(ccontext: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8 {
    var newcontext: *mut pcre2_real_convert_context_8 = ((ccontext.memctl.malloc(sizeof[pcre2_real_convert_context_8](), ccontext.memctl.memory_data) as *mut pcre2_real_convert_context_8))

    if ((if newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((newcontext as *i8), (ccontext as *i8), (sizeof[pcre2_real_convert_context_8]() as i64))

    return newcontext

}

fn pcre2_convert_context_create_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8 {
    var ccontext: *mut pcre2_real_convert_context_8 = ((_pcre2_memctl_malloc_8(sizeof[pcre2_real_convert_context_8](), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_convert_context_8))

    if ((if ccontext == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe: *ccontext) = _pcre2_default_convert_context_8)

    if ((if gcontext != null: 1 else: 0) != 0) {
        ((unsafe: *(ccontext as *mut pcre2_memctl)) = (unsafe: *(gcontext as *mut pcre2_memctl)))
    }

    return ccontext

}

fn pcre2_convert_context_free_8(ccontext: *mut pcre2_real_convert_context_8) {
    if ((if ccontext != null: 1 else: 0) != 0) {
        ccontext.memctl.free(ccontext, ccontext.memctl.memory_data)
    }

}

fn pcre2_set_glob_escape_8(ccontext: *mut pcre2_real_convert_context_8, escape: c_uint) -> c_int {
    var __ci_expr_logic_1: c_int
    
    if ((if escape > 255: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_0: c_int = 0
        
        if ((if escape != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if string_find_char(globpunct, escape) == null: 1 else: 0) != 0: 1 else: 0))
        }
        
        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))
        
    }
    
    if (__ci_expr_logic_1 != 0) {
        return -29
    }
    

    (ccontext.glob_escape = escape)

    return 0

}

fn pcre2_set_glob_separator_8(ccontext: *mut pcre2_real_convert_context_8, separator: c_uint) -> c_int {
    var __ci_expr_logic_1: c_int = 0
    
    var __ci_expr_logic_0: c_int = 0
    
    if ((if separator != 47: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if separator != 92: 1 else: 0) != 0: 1 else: 0))
    }
    
    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if separator != 46: 1 else: 0) != 0: 1 else: 0))
    }
    
    if (__ci_expr_logic_1 != 0) {
        return -29
    }
    

    (ccontext.glob_separator = separator)

    return 0

}

fn pcre2_match_context_copy_8(mcontext: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8 {
    var newcontext: *mut pcre2_real_match_context_8 = ((mcontext.memctl.malloc(sizeof[pcre2_real_match_context_8](), mcontext.memctl.memory_data) as *mut pcre2_real_match_context_8))

    if ((if newcontext == null: 1 else: 0) != 0) {
        return null
    }

    with_memcpy((newcontext as *i8), (mcontext as *i8), (sizeof[pcre2_real_match_context_8]() as i64))

    return newcontext

}

fn pcre2_match_context_create_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8 {
    var mcontext: *mut pcre2_real_match_context_8 = ((_pcre2_memctl_malloc_8(sizeof[pcre2_real_match_context_8](), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_context_8))

    if ((if mcontext == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe: *mcontext) = _pcre2_default_match_context_8)

    if ((if gcontext != null: 1 else: 0) != 0) {
        ((unsafe: *(mcontext as *mut pcre2_memctl)) = (unsafe: *(gcontext as *mut pcre2_memctl)))
    }

    return mcontext

}

fn pcre2_match_context_free_8(mcontext: *mut pcre2_real_match_context_8) {
    if ((if mcontext != null: 1 else: 0) != 0) {
        mcontext.memctl.free(mcontext, mcontext.memctl.memory_data)
    }

}

fn pcre2_set_callout_8(mcontext: *mut pcre2_real_match_context_8, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, callout_data: *mut c_void) -> c_int {
    (mcontext.callout = ((callout as *mut fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int)))

    (mcontext.callout_data = callout_data)

    return 0

}

fn pcre2_set_substitute_callout_8(mcontext: *mut pcre2_real_match_context_8, substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, substitute_callout_data: *mut c_void) -> c_int {
    (mcontext.substitute_callout = ((substitute_callout as *mut fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int)))

    (mcontext.substitute_callout_data = substitute_callout_data)

    return 0

}

fn pcre2_set_substitute_case_callout_8(mcontext: *mut pcre2_real_match_context_8, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, substitute_case_callout_data: *mut c_void) -> c_int {
    (mcontext.substitute_case_callout = ((substitute_case_callout as *mut fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)))

    (mcontext.substitute_case_callout_data = substitute_case_callout_data)

    return 0

}

fn pcre2_set_depth_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int {
    (mcontext.depth_limit = limit)

    return 0

}

fn pcre2_set_heap_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int {
    (mcontext.heap_limit = limit)

    return 0

}

fn pcre2_set_match_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int {
    (mcontext.match_limit = limit)

    return 0

}

fn pcre2_set_offset_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_ulong) -> c_int {
    (mcontext.offset_limit = limit)

    return 0

}

fn pcre2_set_recursion_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int {
    return pcre2_set_depth_limit_8(mcontext, limit)

}

fn pcre2_set_recursion_memory_management_8(mcontext: *mut pcre2_real_match_context_8, mymalloc: *const fn(c_ulong, *mut c_void) -> *mut c_void, myfree: *const fn(*mut c_void, *mut c_void) -> void, mydata: *mut c_void) -> c_int {
    mcontext

    mymalloc

    myfree

    mydata

    return 0

}

fn _pcre2_memctl_malloc_8(size: c_ulong, memctl: *mut pcre2_memctl) -> *mut c_void {
    var newmemctl: *mut pcre2_memctl

    var yield_: *mut c_void = with 0 as __ci_expr_seq_10 {
        var __ci_expr_ternary_0: *mut c_void = null
        if ((if memctl == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((with_alloc((size as i64)) as *mut c_void)))
        } else {
            (__ci_expr_ternary_0 = memctl.malloc(size, memctl.memory_data))
        }
        __ci_expr_ternary_0
    }

    if ((if yield_ == null: 1 else: 0) != 0) {
        return null
    }

    (newmemctl = ((yield_ as *mut pcre2_memctl)))

    if ((if memctl == null: 1 else: 0) != 0) {
        (newmemctl.malloc = ((default_malloc as *mut fn(c_ulong, *mut c_void) -> *mut c_void)))
        
        (newmemctl.free = ((default_free as *mut fn(*mut c_void, *mut c_void) -> void)))
        
        (newmemctl.memory_data = null)
        
    } else {
        ((unsafe: *newmemctl) = (unsafe: *memctl))
    }

    return yield_

}

fn default_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void {
    data

    return ((with_alloc((size as i64)) as *mut c_void))

}

fn default_free(block: *mut c_void, data: *mut c_void) {
    data

    with_free((block as *mut i8))

}

