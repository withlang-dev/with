// Migrated from PCRE2
use std.re.defs

type BOOL = c_int
type PCRE2_UCHAR8 = u8
type PCRE2_SPTR8 = *const u8
type pcre2_general_context_8 = pcre2_real_general_context_8
type pcre2_compile_context_8 = pcre2_real_compile_context_8
type pcre2_match_context_8 = pcre2_real_match_context_8
type pcre2_convert_context_8 = pcre2_real_convert_context_8
type pcre2_code_8 = pcre2_real_code_8
type pcre2_match_data_8 = pcre2_real_match_data_8
type pcre2_jit_stack_8 = pcre2_real_jit_stack_8
type pcre2_jit_callback_8 = *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8
type pcre2_callout_block_8 { version: c_uint = 0, callout_number: c_uint = 0, capture_top: c_uint = 0, capture_last: c_uint = 0, offset_vector: *mut c_ulong = null, mark: *const u8 = null, subject: *const u8 = null, subject_length: c_ulong = 0, start_match: c_ulong = 0, current_position: c_ulong = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null, callout_flags: c_uint = 0 }
type struct_pcre2_callout_block_8 = pcre2_callout_block_8
type pcre2_callout_enumerate_block_8 { version: c_uint = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_number: c_uint = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null }
type struct_pcre2_callout_enumerate_block_8 = pcre2_callout_enumerate_block_8
type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong = [0 as c_ulong; 2], ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
type struct_pcre2_substitute_callout_block_8 = pcre2_substitute_callout_block_8
extern fn pcre2_config_8(p0: c_uint, p1: *mut c_void) -> c_int
fn pcre2_general_context_copy_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8:
    var newcontext: *mut pcre2_real_general_context_8 = (gcontext.memctl.malloc(sizeof[pcre2_real_general_context_8](), gcontext.memctl.memory_data) as *mut pcre2_real_general_context_8)
    if (newcontext == (null as *mut pcre2_real_general_context_8)):
        return (null as *mut pcre2_real_general_context_8)

    with_memcpy((newcontext as *mut c_void) as *i8, (gcontext as *const c_void) as *i8, sizeof[pcre2_real_general_context_8]() as i64)
    return newcontext

fn pcre2_general_context_create_8(__param_private_malloc: *const fn(c_ulong, *mut c_void) -> *mut c_void, __param_private_free: *const fn(*mut c_void, *mut c_void) -> void, memory_data: *mut c_void) -> *mut pcre2_real_general_context_8:
    var private_malloc = __param_private_malloc
    var private_free = __param_private_free
    var gcontext: *mut pcre2_real_general_context_8
    if (private_malloc == (null as *const fn(c_ulong, *mut c_void) -> *mut c_void)):
        (private_malloc = default_malloc)

    if (private_free == (null as *const fn(*mut c_void, *mut c_void) -> void)):
        (private_free = default_free)

    (gcontext = (private_malloc(sizeof[pcre2_real_general_context_8](), memory_data) as *mut pcre2_real_general_context_8))
    if (gcontext == (null as *mut pcre2_real_general_context_8)):
        return (null as *mut pcre2_real_general_context_8)

    (gcontext.memctl.malloc = private_malloc)
    (gcontext.memctl.free = private_free)
    (gcontext.memctl.memory_data = memory_data)
    return gcontext

fn pcre2_general_context_free_8(gcontext: *mut pcre2_real_general_context_8):
    if (gcontext != (null as *mut pcre2_real_general_context_8)):
        gcontext.memctl.free((gcontext as *mut c_void), gcontext.memctl.memory_data)


fn pcre2_compile_context_copy_8(ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8:
    var newcontext: *mut pcre2_real_compile_context_8 = (ccontext.memctl.malloc(sizeof[pcre2_real_compile_context_8](), ccontext.memctl.memory_data) as *mut pcre2_real_compile_context_8)
    if (newcontext == (null as *mut pcre2_real_compile_context_8)):
        return (null as *mut pcre2_real_compile_context_8)

    with_memcpy((newcontext as *mut c_void) as *i8, (ccontext as *const c_void) as *i8, sizeof[pcre2_real_compile_context_8]() as i64)
    return newcontext

fn pcre2_compile_context_create_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8:
    var ccontext: *mut pcre2_real_compile_context_8 = (_pcre2_memctl_malloc_8(sizeof[pcre2_real_compile_context_8](), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_compile_context_8)
    if (ccontext == (null as *mut pcre2_real_compile_context_8)):
        return (null as *mut pcre2_real_compile_context_8)

    ((unsafe: *ccontext) = _pcre2_default_compile_context_8)
    if (gcontext != (null as *mut pcre2_real_general_context_8)):
        ((unsafe: *((ccontext as *mut pcre2_memctl))) = (unsafe: *((gcontext as *mut pcre2_memctl))))

    return ccontext

fn pcre2_compile_context_free_8(ccontext: *mut pcre2_real_compile_context_8):
    if (ccontext != (null as *mut pcre2_real_compile_context_8)):
        ccontext.memctl.free((ccontext as *mut c_void), ccontext.memctl.memory_data)


fn pcre2_set_bsr_8(ccontext: *mut pcre2_real_compile_context_8, value: c_uint) -> c_int:
    match value
        2 =>
            return 0
        _ =>
            return (-29)


fn pcre2_set_character_tables_8(ccontext: *mut pcre2_real_compile_context_8, tables: *const u8) -> c_int:
    (ccontext.tables = tables)
    return 0

fn pcre2_set_compile_extra_options_8(ccontext: *mut pcre2_real_compile_context_8, options: c_uint) -> c_int:
    (ccontext.extra_options = options)
    return 0

fn pcre2_set_max_pattern_length_8(ccontext: *mut pcre2_real_compile_context_8, length: c_ulong) -> c_int:
    (ccontext.max_pattern_length = length)
    return 0

fn pcre2_set_max_pattern_compiled_length_8(ccontext: *mut pcre2_real_compile_context_8, length: c_ulong) -> c_int:
    (ccontext.max_pattern_compiled_length = length)
    return 0

fn pcre2_set_max_varlookbehind_8(ccontext: *mut pcre2_real_compile_context_8, limit: c_uint) -> c_int:
    (ccontext.max_varlookbehind = limit)
    return 0

fn pcre2_set_newline_8(ccontext: *mut pcre2_real_compile_context_8, newline: c_uint) -> c_int:
    match newline
        1 =>
            return 0
        _ =>
            return (-29)


fn pcre2_set_parens_nest_limit_8(ccontext: *mut pcre2_real_compile_context_8, limit: c_uint) -> c_int:
    (ccontext.parens_nest_limit = limit)
    return 0

fn pcre2_set_compile_recursion_guard_8(ccontext: *mut pcre2_real_compile_context_8, guard: *const fn(c_uint, *mut c_void) -> c_int, user_data: *mut c_void) -> c_int:
    (ccontext.stack_guard = guard)
    (ccontext.stack_guard_data = user_data)
    return 0

fn pcre2_set_optimize_8(ccontext: *mut pcre2_real_compile_context_8, directive: c_uint) -> c_int:
    if (ccontext == (null as *mut pcre2_real_compile_context_8)):
        return (-51)

    match directive
        0 =>
            (ccontext.optimization_flags = 0)
        1 =>
            (ccontext.optimization_flags = 7)
        _ =>
            if ((directive >= 64) and (directive <= 69)):
                if (((directive & 1)) != 0):
                    ccontext.optimization_flags = ccontext.optimization_flags & (0 - ((1 << ((((directive >> 1)) -% 32)))) - 1)
                else:
                    ccontext.optimization_flags = ccontext.optimization_flags | (1 << ((((directive >> 1)) -% 32)))
                
                return 0
            return (-34)

    return 0

fn pcre2_convert_context_copy_8(ccontext: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8:
    var newcontext: *mut pcre2_real_convert_context_8 = (ccontext.memctl.malloc(sizeof[pcre2_real_convert_context_8](), ccontext.memctl.memory_data) as *mut pcre2_real_convert_context_8)
    if (newcontext == (null as *mut pcre2_real_convert_context_8)):
        return (null as *mut pcre2_real_convert_context_8)

    with_memcpy((newcontext as *mut c_void) as *i8, (ccontext as *const c_void) as *i8, sizeof[pcre2_real_convert_context_8]() as i64)
    return newcontext

fn pcre2_convert_context_create_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8:
    var ccontext: *mut pcre2_real_convert_context_8 = (_pcre2_memctl_malloc_8(sizeof[pcre2_real_convert_context_8](), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_convert_context_8)
    if (ccontext == (null as *mut pcre2_real_convert_context_8)):
        return (null as *mut pcre2_real_convert_context_8)

    ((unsafe: *ccontext) = _pcre2_default_convert_context_8)
    if (gcontext != (null as *mut pcre2_real_general_context_8)):
        ((unsafe: *((ccontext as *mut pcre2_memctl))) = (unsafe: *((gcontext as *mut pcre2_memctl))))

    return ccontext

fn pcre2_convert_context_free_8(ccontext: *mut pcre2_real_convert_context_8):
    if (ccontext != (null as *mut pcre2_real_convert_context_8)):
        ccontext.memctl.free((ccontext as *mut c_void), ccontext.memctl.memory_data)


fn pcre2_set_glob_escape_8(ccontext: *mut pcre2_real_convert_context_8, escape: c_uint) -> c_int:
    if ((escape > 255) or ((escape != 0) and (string_find_char(globpunct, escape) == (null as *mut i8)))):
        return (-29)

    (ccontext.glob_escape = escape)
    return 0

fn pcre2_set_glob_separator_8(ccontext: *mut pcre2_real_convert_context_8, separator: c_uint) -> c_int:
    if (((separator != 47) and (separator != 92)) and (separator != 46)):
        return (-29)

    (ccontext.glob_separator = separator)
    return 0

extern fn pcre2_pattern_convert_8(p0: *const u8, p1: c_ulong, p2: c_uint, p3: *mut *mut u8, p4: *mut c_ulong, p5: *mut pcre2_real_convert_context_8) -> c_int
extern fn pcre2_converted_pattern_free_8(p0: *mut u8) -> void
fn pcre2_match_context_copy_8(mcontext: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8:
    var newcontext: *mut pcre2_real_match_context_8 = (mcontext.memctl.malloc(sizeof[pcre2_real_match_context_8](), mcontext.memctl.memory_data) as *mut pcre2_real_match_context_8)
    if (newcontext == (null as *mut pcre2_real_match_context_8)):
        return (null as *mut pcre2_real_match_context_8)

    with_memcpy((newcontext as *mut c_void) as *i8, (mcontext as *const c_void) as *i8, sizeof[pcre2_real_match_context_8]() as i64)
    return newcontext

fn pcre2_match_context_create_8(gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8:
    var mcontext: *mut pcre2_real_match_context_8 = (_pcre2_memctl_malloc_8(sizeof[pcre2_real_match_context_8](), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_context_8)
    if (mcontext == (null as *mut pcre2_real_match_context_8)):
        return (null as *mut pcre2_real_match_context_8)

    ((unsafe: *mcontext) = _pcre2_default_match_context_8)
    if (gcontext != (null as *mut pcre2_real_general_context_8)):
        ((unsafe: *((mcontext as *mut pcre2_memctl))) = (unsafe: *((gcontext as *mut pcre2_memctl))))

    return mcontext

fn pcre2_match_context_free_8(mcontext: *mut pcre2_real_match_context_8):
    if (mcontext != (null as *mut pcre2_real_match_context_8)):
        mcontext.memctl.free((mcontext as *mut c_void), mcontext.memctl.memory_data)


fn pcre2_set_callout_8(mcontext: *mut pcre2_real_match_context_8, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, callout_data: *mut c_void) -> c_int:
    (mcontext.callout = callout)
    (mcontext.callout_data = callout_data)
    return 0

fn pcre2_set_substitute_callout_8(mcontext: *mut pcre2_real_match_context_8, substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, substitute_callout_data: *mut c_void) -> c_int:
    (mcontext.substitute_callout = substitute_callout)
    (mcontext.substitute_callout_data = substitute_callout_data)
    return 0

fn pcre2_set_substitute_case_callout_8(mcontext: *mut pcre2_real_match_context_8, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, substitute_case_callout_data: *mut c_void) -> c_int:
    (mcontext.substitute_case_callout = substitute_case_callout)
    (mcontext.substitute_case_callout_data = substitute_case_callout_data)
    return 0

fn pcre2_set_depth_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int:
    (mcontext.depth_limit = limit)
    return 0

fn pcre2_set_heap_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int:
    (mcontext.heap_limit = limit)
    return 0

fn pcre2_set_match_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int:
    (mcontext.match_limit = limit)
    return 0

fn pcre2_set_offset_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_ulong) -> c_int:
    (mcontext.offset_limit = limit)
    return 0

fn pcre2_set_recursion_limit_8(mcontext: *mut pcre2_real_match_context_8, limit: c_uint) -> c_int:
    return pcre2_set_depth_limit_8(mcontext, limit)

fn pcre2_set_recursion_memory_management_8(mcontext: *mut pcre2_real_match_context_8, mymalloc: *const fn(c_ulong, *mut c_void) -> *mut c_void, myfree: *const fn(*mut c_void, *mut c_void) -> void, mydata: *mut c_void) -> c_int:
    mcontext
    mymalloc
    myfree
    mydata
    return 0

extern fn pcre2_compile_8(p0: *const u8, p1: c_ulong, p2: c_uint, p3: *mut c_int, p4: *mut c_ulong, p5: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8
extern fn pcre2_code_free_8(p0: *mut pcre2_real_code_8) -> void
extern fn pcre2_code_copy_8(p0: *const pcre2_real_code_8) -> *mut pcre2_real_code_8
extern fn pcre2_code_copy_with_tables_8(p0: *const pcre2_real_code_8) -> *mut pcre2_real_code_8
extern fn pcre2_pattern_info_8(p0: *const pcre2_real_code_8, p1: c_uint, p2: *mut c_void) -> c_int
extern fn pcre2_callout_enumerate_8(p0: *const pcre2_real_code_8, p1: *const fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_match_data_create_8(p0: c_uint, p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_create_from_pattern_8(p0: *const pcre2_real_code_8, p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_free_8(p0: *mut pcre2_real_match_data_8) -> void
extern fn pcre2_dfa_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8, p7: *mut c_int, p8: c_ulong) -> c_int
extern fn pcre2_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_get_mark_8(p0: *mut pcre2_real_match_data_8) -> *const u8
extern fn pcre2_get_match_data_size_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_match_data_heapframes_size_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_ovector_count_8(p0: *mut pcre2_real_match_data_8) -> c_uint
extern fn pcre2_get_ovector_pointer_8(p0: *mut pcre2_real_match_data_8) -> *mut c_ulong
extern fn pcre2_get_startchar_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_next_match_8(p0: *mut pcre2_real_match_data_8, p1: *mut c_ulong, p2: *mut c_uint) -> c_int
extern fn pcre2_substring_copy_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_copy_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_free_8(p0: *mut u8) -> void
extern fn pcre2_substring_get_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_get_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_length_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut c_ulong) -> c_int
extern fn pcre2_substring_length_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut c_ulong) -> c_int
extern fn pcre2_substring_nametable_scan_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: *mut *const u8, p3: *mut *const u8) -> c_int
extern fn pcre2_substring_number_from_name_8(p0: *const pcre2_real_code_8, p1: *const u8) -> c_int
extern fn pcre2_substring_list_free_8(p0: *mut *mut u8) -> void
extern fn pcre2_substring_list_get_8(p0: *mut pcre2_real_match_data_8, p1: *mut *mut *mut u8, p2: *mut *mut c_ulong) -> c_int
extern fn pcre2_serialize_encode_8(p0: *mut *const pcre2_real_code_8, p1: c_int, p2: *mut *mut u8, p3: *mut c_ulong, p4: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_decode_8(p0: *mut *mut pcre2_real_code_8, p1: c_int, p2: *const u8, p3: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_get_number_of_codes_8(p0: *const u8) -> c_int
extern fn pcre2_serialize_free_8(p0: *mut u8) -> void
extern fn pcre2_substitute_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8, p7: *const u8, p8: c_ulong, p9: *mut u8, p10: *mut c_ulong) -> c_int
extern fn pcre2_jit_compile_8(p0: *mut pcre2_real_code_8, p1: c_uint) -> c_int
extern fn pcre2_jit_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_jit_free_unused_memory_8(p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_jit_stack_create_8(p0: c_ulong, p1: c_ulong, p2: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8
extern fn pcre2_jit_stack_assign_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8, p2: *mut c_void) -> void
extern fn pcre2_jit_stack_free_8(p0: *mut pcre2_real_jit_stack_8) -> void
extern fn pcre2_get_error_message_8(p0: c_int, p1: *mut u8, p2: c_ulong) -> c_int
extern fn pcre2_maketables_8(p0: *mut pcre2_real_general_context_8) -> *const u8
extern fn pcre2_maketables_free_8(p0: *mut pcre2_real_general_context_8, p1: *const u8) -> void
type pcre2_memctl { malloc: *const fn(c_ulong, *mut c_void) -> *mut c_void = null, free: *const fn(*mut c_void, *mut c_void) -> void = null, memory_data: *mut c_void = null }
type struct_pcre2_memctl = pcre2_memctl
type open_capitem { next: *mut open_capitem = null, number: c_ushort = 0, assert_depth: c_ushort = 0 }
type struct_open_capitem = open_capitem
type ucp_type_table { name_offset: c_ushort = 0, type_: c_ushort = 0, value: c_ushort = 0 }
type struct_ucp_type_table = ucp_type_table
type ucd_record { script: u8 = 0, chartype: u8 = 0, gbprop: u8 = 0, caseset: u8 = 0, other_case: c_int = 0, scriptx_bidiclass: c_ushort = 0, bprops: c_ushort = 0 }
type struct_ucd_record = ucd_record
type pcre2_serialized_data { magic: c_uint = 0, version: c_uint = 0, config: c_uint = 0, number_of_codes: c_int = 0 }
type struct_pcre2_serialized_data = pcre2_serialized_data
extern var _pcre2_utf8_table1: *c_int
extern let _pcre2_utf8_table1_size: c_uint
extern var _pcre2_utf8_table2: *c_int
extern var _pcre2_utf8_table3: *c_int
extern var _pcre2_utf8_table4: *u8
extern var _pcre2_OP_lengths_8: *u8
extern var _pcre2_callout_end_delims_8: *c_uint
extern var _pcre2_callout_start_delims_8: *c_uint
extern var _pcre2_default_compile_context_8: pcre2_real_compile_context_8
extern var _pcre2_default_convert_context_8: pcre2_real_convert_context_8
extern var _pcre2_default_match_context_8: pcre2_real_match_context_8
extern var _pcre2_default_tables_8: *u8
extern var _pcre2_hspace_list_8: *c_uint
extern var _pcre2_vspace_list_8: *c_uint
extern var _pcre2_ucd_boolprop_sets_8: *c_uint
extern var _pcre2_ucd_caseless_sets_8: *c_uint
extern let _pcre2_ucd_turkish_dotted_i_caseset_8: c_uint
extern var _pcre2_ucd_nocase_ranges_8: *c_uint
extern let _pcre2_ucd_nocase_ranges_size_8: c_uint
extern var _pcre2_ucd_digit_sets_8: *c_uint
extern var _pcre2_ucd_script_sets_8: *c_uint
extern var _pcre2_ucd_records_8: *ucd_record
extern var _pcre2_ucd_stage1_8: *c_ushort
extern var _pcre2_ucd_stage2_8: *c_ushort
extern var _pcre2_ucp_gbtable_8: *c_uint
extern var _pcre2_ucp_gentype_8: *c_uint
extern var _pcre2_unicode_version_8: *const i8
extern var _pcre2_utt_8: *ucp_type_table
extern var _pcre2_utt_names_8: *c_char
extern let _pcre2_utt_size_8: c_ulong
extern var _pcre2_ebcdic_1047_to_ascii_8: *u8
extern var _pcre2_ascii_to_ebcdic_1047_8: *u8
type pcre2_real_general_context_8 { memctl: pcre2_memctl }
type struct_pcre2_real_general_context_8 = pcre2_real_general_context_8
type pcre2_real_compile_context_8 { memctl: pcre2_memctl, stack_guard: *const fn(c_uint, *mut c_void) -> c_int = null, stack_guard_data: *mut c_void = null, tables: *const u8 = null, max_pattern_length: c_ulong = 0, max_pattern_compiled_length: c_ulong = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, parens_nest_limit: c_uint = 0, extra_options: c_uint = 0, max_varlookbehind: c_uint = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_compile_context_8 = pcre2_real_compile_context_8
type pcre2_real_match_context_8 { memctl: pcre2_memctl, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, callout_data: *mut c_void = null, substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int = null, substitute_callout_data: *mut c_void = null, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null, substitute_case_callout_data: *mut c_void = null, offset_limit: c_ulong = 0, heap_limit: c_uint = 0, match_limit: c_uint = 0, depth_limit: c_uint = 0 }
type struct_pcre2_real_match_context_8 = pcre2_real_match_context_8
type pcre2_real_convert_context_8 { memctl: pcre2_memctl, glob_separator: c_uint = 0, glob_escape: c_uint = 0 }
type struct_pcre2_real_convert_context_8 = pcre2_real_convert_context_8
type pcre2_real_code_8 { memctl: pcre2_memctl, tables: *const u8 = null, executable_jit: *mut c_void = null, start_bitmap: [32]u8 = [0 as u8; 32], blocksize: c_ulong = 0, code_start: c_ulong = 0, magic_number: c_uint = 0, compile_options: c_uint = 0, overall_options: c_uint = 0, extra_options: c_uint = 0, flags: c_uint = 0, limit_heap: c_uint = 0, limit_match: c_uint = 0, limit_depth: c_uint = 0, first_codeunit: c_uint = 0, last_codeunit: c_uint = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, max_lookbehind: c_ushort = 0, minlength: c_ushort = 0, top_bracket: c_ushort = 0, top_backref: c_ushort = 0, name_entry_size: c_ushort = 0, name_count: c_ushort = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_code_8 = pcre2_real_code_8
type pcre2_real_match_data_8 { memctl: pcre2_memctl, code: *const pcre2_real_code_8 = null, subject: *const u8 = null, mark: *const u8 = null, heapframes: *mut heapframe = null, heapframes_size: c_ulong = 0, subject_length: c_ulong = 0, start_offset: c_ulong = 0, leftchar: c_ulong = 0, rightchar: c_ulong = 0, startchar: c_ulong = 0, matchedby: u8 = 0, flags: u8 = 0, oveccount: c_ushort = 0, options: c_uint = 0, rc: c_int = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
type struct_pcre2_real_match_data_8 = pcre2_real_match_data_8
type recurse_check { prev: *mut recurse_check = null, group: *const u8 = null }
type struct_recurse_check = recurse_check
type parsed_recurse_check { prev: *mut parsed_recurse_check = null, groupptr: *mut c_uint = null }
type struct_parsed_recurse_check = parsed_recurse_check
type recurse_cache { group: *const u8 = null, groupnumber: c_int = 0 }
type struct_recurse_cache = recurse_cache
type branch_chain_8 { outer: *mut branch_chain_8 = null, current_branch: *mut u8 = null }
type struct_branch_chain_8 = branch_chain_8
type named_group_8 { name: *const u8 = null, number: c_uint = 0, length: c_ushort = 0, hash_dup: c_ushort = 0 }
type struct_named_group_8 = named_group_8
type compile_data { next: *mut compile_data = null }
type struct_compile_data = compile_data
type class_ranges { header: compile_data, char_lists_size: c_ulong = 0, char_lists_start: c_ulong = 0, range_list_size: c_ushort = 0, char_lists_types: c_ushort = 0 }
type struct_class_ranges = class_ranges
type recurse_arguments { header: compile_data, size: c_ulong = 0, skip_size: c_ulong = 0 }
type struct_recurse_arguments = recurse_arguments
// union
type class_bits_storage { classbits: [32]u8 = [0 as u8; 32], classwords: [8]c_uint = [0 as c_uint; 8] }
type struct_class_bits_storage = class_bits_storage
type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong = [0 as c_ulong; 10], erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], class_op_used: [15]u8 = [0 as u8; 15], req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null }
type struct_compile_block_8 = compile_block_8
type pcre2_real_jit_stack_8 { memctl: pcre2_memctl, stack: *mut c_void = null }
type struct_pcre2_real_jit_stack_8 = pcre2_real_jit_stack_8
type dfa_recursion_info { prevrec: *mut dfa_recursion_info = null, subject_position: *const u8 = null, last_used_ptr: *const u8 = null, group_num: c_uint = 0 }
type struct_dfa_recursion_info = dfa_recursion_info
// union
type heapframe_fields_char_repeat_oc { oc: c_uint = 0, occu: [4]u8 = [0 as u8; 4] }
type heapframe_fields_char_repeat { start_eptr: *const u8 = null, charptr: *const u8 = null, min: c_uint = 0, max: c_uint = 0, c: c_uint = 0, oc: heapframe_fields_char_repeat_oc }
type heapframe_fields_charnot_repeat { start_eptr: *const u8 = null, min: c_uint = 0, max: c_uint = 0, c: c_uint = 0, oc: c_uint = 0 }
type heapframe_fields_class_repeat { start_eptr: *const u8 = null, byte_map_address: *const u8 = null, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_xclass_repeat { start_eptr: *const u8 = null, xclass_data: *const u8 = null, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_eclass_repeat { start_eptr: *const u8 = null, eclass_data: *const u8 = null, eclass_len: c_ulong = 0, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_type_repeat { start_eptr: *const u8 = null, min: c_uint = 0, max: c_uint = 0, ctype: c_uint = 0, propvalue: c_uint = 0 }
type heapframe_fields_ref_repeat { start: *const u8 = null, offset: c_ulong = 0, length: c_ulong = 0, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_op_bra { frame_type: c_uint = 0 }
type heapframe_fields_op_brapos { start_eptr: *const u8 = null, start_group: *const u8 = null, frame_type: c_uint = 0 }
type heapframe_fields_op_recurse { start_branch: *const u8 = null, frame_type: c_uint = 0 }
type heapframe_fields_op_assert_scs { saved_end_subject: *const u8 = null, saved_eptr: *const u8 = null, true_end_extra: c_ulong = 0, saved_moptions: c_uint = 0 }
type heapframe_fields_op_cond { start_branch: *const u8 = null, length: c_ulong = 0 }
type heapframe_fields_op_vreverse { min: c_uint = 0, max: c_uint = 0 }
// union
type heapframe_fields { char_repeat: heapframe_fields_char_repeat, charnot_repeat: heapframe_fields_charnot_repeat, class_repeat: heapframe_fields_class_repeat, xclass_repeat: heapframe_fields_xclass_repeat, eclass_repeat: heapframe_fields_eclass_repeat, type_repeat: heapframe_fields_type_repeat, ref_repeat: heapframe_fields_ref_repeat, op_bra: heapframe_fields_op_bra, op_brapos: heapframe_fields_op_brapos, op_recurse: heapframe_fields_op_recurse, op_assert_scs: heapframe_fields_op_assert_scs, op_cond: heapframe_fields_op_cond, op_vreverse: heapframe_fields_op_vreverse }
type heapframe { ecode: *const u8 = null, back_frame: c_ulong = 0, rdepth: c_uint = 0, group_frame_type: c_uint = 0, return_id: u8 = 0, op: u8 = 0, byte1: u8 = 0, byte2: u8 = 0, fields: heapframe_fields, eptr: *const u8 = null, start_match: *const u8 = null, mark: *const u8 = null, recurse_last_used: *const u8 = null, current_recurse: c_uint = 0, capture_last: c_uint = 0, last_group_offset: c_ulong = 0, offset_top: c_ulong = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
type heapframe_align { unalign: c_char = 0, frame: heapframe }
type struct_heapframe_align = heapframe_align
type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null }
type struct_match_block_8 = match_block_8
type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8 = [0 as u8; 4], bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, recursive: *mut dfa_recursion_info = null }
type struct_dfa_match_block_8 = dfa_match_block_8
extern fn _pcre2_auto_possessify_8(p0: *mut u8, p1: *const compile_block_8) -> c_int
extern fn _pcre2_check_escape_8(p0: *mut *const u8, p1: *const u8, p2: *mut c_uint, p3: *mut c_int, p4: c_uint, p5: c_uint, p6: c_uint, p7: c_int, p8: *mut compile_block_8) -> c_int
extern fn _pcre2_ckd_smul_8(p0: *mut c_ulong, p1: c_int, p2: c_int) -> c_int
extern fn _pcre2_extuni_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int, p5: *mut c_int) -> *const u8
extern fn _pcre2_find_bracket_8(p0: *const u8, p1: c_int, p2: c_int) -> *const u8
extern fn _pcre2_is_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_jit_free_rodata_8(p0: *mut c_void, p1: *mut c_void) -> void
extern fn _pcre2_jit_free_8(p0: *mut c_void, p1: *mut pcre2_memctl) -> void
extern fn _pcre2_jit_get_size_8(p0: *mut c_void) -> c_ulong
extern fn _pcre2_jit_get_target_8() -> *const i8
fn _pcre2_memctl_malloc_8(size: c_ulong, memctl: *mut pcre2_memctl) -> *mut c_void:
    var newmemctl: *mut pcre2_memctl
    var yield_: *mut c_void = (if (memctl == (null as *mut pcre2_memctl)): (with_alloc(size as i64) as *mut c_void) else: memctl.malloc(size, memctl.memory_data))
    if (yield_ == null):
        return null

    (newmemctl = (yield_ as *mut pcre2_memctl))
    if (memctl == (null as *mut pcre2_memctl)):
        (newmemctl.malloc = default_malloc)
        (newmemctl.free = default_free)
        (newmemctl.memory_data = null)
    else:
        ((unsafe: *newmemctl) = (unsafe: *memctl))

    return yield_

extern fn _pcre2_ord2utf_8(p0: c_uint, p1: *mut u8) -> c_uint
extern fn _pcre2_script_run_8(p0: *const u8, p1: *const u8, p2: c_int) -> c_int
extern fn _pcre2_strcmp_8(p0: *const u8, p1: *const u8) -> c_int
extern fn _pcre2_strcmp_c8_8(p0: *const u8, p1: *const i8) -> c_int
extern fn _pcre2_strcpy_c8_8(p0: *mut u8, p1: *const i8) -> c_ulong
extern fn _pcre2_strlen_8(p0: *const u8) -> c_ulong
extern fn _pcre2_strncmp_8(p0: *const u8, p1: *const u8, p2: c_ulong) -> c_int
extern fn _pcre2_strncmp_c8_8(p0: *const u8, p1: *const i8, p2: c_ulong) -> c_int
extern fn _pcre2_study_8(p0: *mut pcre2_real_code_8) -> c_int
extern fn _pcre2_valid_utf_8(p0: *const u8, p1: c_ulong, p2: *mut c_ulong) -> c_int
extern fn _pcre2_was_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_xclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: c_int) -> c_int
extern fn _pcre2_eclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int) -> c_int
fn default_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    data
    return (with_alloc(size as i64) as *mut c_void)

fn default_free(block: *mut c_void, data: *mut c_void):
    data
    with_free(block as *i8)

var globpunct: *const i8
