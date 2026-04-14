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
extern fn pcre2_general_context_copy_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_create_8(p0: *const fn(c_ulong, *mut c_void) -> *mut c_void, p1: *const fn(*mut c_void, *mut c_void) -> void, p2: *mut c_void) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_free_8(p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_compile_context_copy_8(p0: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_free_8(p0: *mut pcre2_real_compile_context_8) -> void
extern fn pcre2_set_bsr_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_character_tables_8(p0: *mut pcre2_real_compile_context_8, p1: *const u8) -> c_int
extern fn pcre2_set_compile_extra_options_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_max_pattern_length_8(p0: *mut pcre2_real_compile_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_max_pattern_compiled_length_8(p0: *mut pcre2_real_compile_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_max_varlookbehind_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_newline_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_parens_nest_limit_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_compile_recursion_guard_8(p0: *mut pcre2_real_compile_context_8, p1: *const fn(c_uint, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_optimize_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_convert_context_copy_8(p0: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_free_8(p0: *mut pcre2_real_convert_context_8) -> void
extern fn pcre2_set_glob_escape_8(p0: *mut pcre2_real_convert_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_glob_separator_8(p0: *mut pcre2_real_convert_context_8, p1: c_uint) -> c_int
fn pcre2_pattern_convert_8(__param_pattern: *const u8, __param_plength: c_ulong, options: c_uint, buffptr: *mut *mut u8, bufflenptr: *mut c_ulong, __param_ccontext: *mut pcre2_real_convert_context_8) -> c_int:
    var pattern = __param_pattern
    var plength = __param_plength
    var ccontext = __param_ccontext
    var rc: c_int

    var null_str: [1]u8 = [205]

    var dummy_buffer: [100]u8

    var use_buffer: *mut u8 = (&dummy_buffer[0] as *mut u8)

    var use_length: c_ulong = 100

    var utf: c_int = (if ((options & 1)) != 0: 1 else: 0)

    var pattype: c_uint = (options & (((16 | 4) | 8)))

    if ((pattern == null) and (plength == 0)):
        (pattern = ((&null_str[0] as *mut u8) as *const u8))

    if ((pattern == null) or (bufflenptr == null)):
        if (bufflenptr != null):
            ((unsafe: *bufflenptr) = 0)
        
        return (-51)
        

    if (((((options & (0 - (((((1 | 2) | 48) | 80) | (((16 | 4) | 8)))) - 1))) != 0) or (((pattype & (((0 - pattype - 1) +% 1)))) != pattype)) or (pattype == 0)):
        ((unsafe: *bufflenptr) = 0)
        
        return (-34)
        

    if (plength == ((0 - (0 as c_ulong) - 1))):
        (plength = _pcre2_strlen_8(pattern))

    if (ccontext == null):
        (ccontext = ((&mut _pcre2_default_convert_context_8 as *mut pcre2_real_convert_context_8)))

    if ((utf != 0) and (((options & 2)) == 0)):
        var erroroffset: c_ulong
        
        (rc = _pcre2_valid_utf_8(pattern, plength, (&mut erroroffset as *mut c_ulong)))
        
        if (rc != 0):
            ((unsafe: *bufflenptr) = erroroffset)
            
            return rc
            
        

    if ((buffptr != null) and ((unsafe: *buffptr) != null)):
        (use_buffer = (unsafe: *buffptr))
        
        (use_length = (unsafe: *bufflenptr))
        

    var i: c_int = 0
    
    while (i < 2):
        var allocated: *mut u8
        
        var dummyrun: c_int = (if (buffptr == null) or ((unsafe: *buffptr) == null): 1 else: 0)
        
        match pattype
            16 =>
                (rc = convert_glob((options & (0 - 16 - 1)), pattern, plength, utf, use_buffer, use_length, bufflenptr, dummyrun, ccontext))
            4 =>
                (rc = convert_posix(pattype, pattern, plength, utf, use_buffer, use_length, bufflenptr, dummyrun, ccontext))
            8 =>
                (rc = convert_posix(pattype, pattern, plength, utf, use_buffer, use_length, bufflenptr, dummyrun, ccontext))
            _ =>
                ((unsafe: *bufflenptr) = 0)
                return (-44)
        
        if (((rc != 0) or (buffptr == null)) or ((unsafe: *buffptr) != null)):
            return rc
        
        (allocated = (_pcre2_memctl_malloc_8((sizeof[pcre2_memctl]() +% ((((unsafe: *bufflenptr) +% 1)) *% 8)), (ccontext as *mut pcre2_memctl)) as *mut u8))
        
        if (allocated == null):
            ((unsafe: *bufflenptr) = 0)
            
            return (-48)
            
        
        ((unsafe: *buffptr) = (((((allocated as *mut i8)) + sizeof[pcre2_memctl]())) as *mut u8))
        
        (use_buffer = (unsafe: *buffptr))
        
        (use_length = ((unsafe: *bufflenptr) +% 1))
        
        
        var __ci_expr_old_0: c_int = i
        (i = i + 1)
        
    

    while true:
        
        if not ((0 != 0)):
            break
        

    ((unsafe: *bufflenptr) = 0)

    return (-44)


fn pcre2_converted_pattern_free_8(converted: *mut u8):
    if (converted != null):
        var memctl: *mut pcre2_memctl = ((((converted as *mut i8) - sizeof[pcre2_memctl]())) as *mut pcre2_memctl)
        
        memctl.free((memctl as *mut c_void), memctl.memory_data)
        


extern fn pcre2_match_context_copy_8(p0: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_free_8(p0: *mut pcre2_real_match_context_8) -> void
extern fn pcre2_set_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_case_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, p2: *mut c_void) -> c_int
extern fn pcre2_set_depth_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_heap_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_match_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_offset_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_recursion_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_recursion_memory_management_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(c_ulong, *mut c_void) -> *mut c_void, p2: *const fn(*mut c_void, *mut c_void) -> void, p3: *mut c_void) -> c_int
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
type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong = [0 as c_ulong; 10], erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], class_op_used: [15]u8 = [0 as u8; 15], req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null, char_lists_size: c_ulong = 0 }
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
extern fn _pcre2_memctl_malloc_8(p0: c_ulong, p1: *mut pcre2_memctl) -> *mut c_void
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
let POSIX_START_REGEX: c_uint = 0
let POSIX_ANCHORED: c_uint = 1
let POSIX_NOT_BRACKET: c_uint = 2
let POSIX_CLASS_NOT_STARTED: c_uint = 3
let POSIX_CLASS_STARTING: c_uint = 4
let POSIX_CLASS_STARTED: c_uint = 5
fn convert_posix(pattype: c_uint, pattern: *const u8, __param_plength: c_ulong, utf: c_int, use_buffer: *mut u8, use_length: c_ulong, bufflenptr: *mut c_ulong, dummyrun: c_int, ccontext: *mut pcre2_real_convert_context_8) -> c_int:
    var plength = __param_plength
    var posix__goto_154_12: *const u8 = null
    var p__goto_155_14: *mut u8 = null
    var pp__goto_156_14: *mut u8 = null
    var endp__goto_157_14: *mut u8 = null
    var convlength__goto_158_12: c_ulong = 0
    var bracount__goto_160_10: c_uint = 0
    var posix_state__goto_161_10: c_uint = 0
    var lastspecial__goto_162_10: c_uint = 0
    var extended__goto_163_6: c_int = 0
    var nextisliteral__goto_164_6: c_int = 0
    var s__goto_172_1: *const i8 = null
    var c__goto_178_12: c_uint = 0
    var sc__goto_178_15: c_uint = 0
    var clength__goto_179_7: c_int = 0
    var s__goto_208_7: *const i8 = null
    var s__goto_224_11: *const i8 = null
    var s__goto_241_32: *const i8 = null
    var s__goto_253_5: *const i8 = null
    var s__goto_291_9: *const i8 = null
    var s__goto_297_9: *const i8 = null
    var s__goto_308_51: *const i8 = null
    var s__goto_367_7: *const i8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                posix__goto_154_12 = pattern
                p__goto_155_14 = use_buffer
                pp__goto_156_14 = p__goto_155_14
                endp__goto_157_14 = ((p__goto_155_14 + use_length) - (1 as isize as usize))
                convlength__goto_158_12 = 0
                bracount__goto_160_10 = 0
                posix_state__goto_161_10 = 0
                lastspecial__goto_162_10 = 0
                extended__goto_163_6 = (if ((pattype & 8)) != 0: 1 else: 0)
                nextisliteral__goto_164_6 = 0
                utf
                if __goto_pending != 0:
                    continue
                ccontext
                if __goto_pending != 0:
                    continue
                ((unsafe: *bufflenptr) = plength)
                if __goto_pending != 0:
                    continue
                while ((unsafe: *s__goto_172_1) != 0):
                    if (p__goto_155_14 >= endp__goto_157_14):
                        return (-48)
                    if __goto_pending != 0:
                        break
                    var __ci_expr_old_1: *mut u8 = p__goto_155_14
                    (p__goto_155_14 = p__goto_155_14 + 1)
                    ((unsafe: *__ci_expr_old_1) = (unsafe: *s__goto_172_1))
                    if __goto_pending != 0:
                        break
                    var __ci_expr_old_0: *const i8 = s__goto_172_1
                (s__goto_172_1 = s__goto_172_1 + 1)
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                if __goto_pending != 0:
                    continue
                while (plength > 0):
                    clength__goto_179_7 = 1
                    if __goto_pending != 0:
                        break
                    (convlength__goto_158_12 = convlength__goto_158_12 + ((p__goto_155_14 as usize -% pp__goto_156_14 as usize) / sizeof[u8]()))
                    if __goto_pending != 0:
                        break
                    if (dummyrun != 0):
                        (p__goto_155_14 = use_buffer)
                    if __goto_pending != 0:
                        break
                    (pp__goto_156_14 = p__goto_155_14)
                    if __goto_pending != 0:
                        break
                    (c__goto_178_12 = (unsafe: *posix__goto_154_12))
                    if __goto_pending != 0:
                        break
                    if ((utf != 0) and (c__goto_178_12 >= 192)):
                        if (((c__goto_178_12 & 32)) == 0):
                            (c__goto_178_12 = (((((c__goto_178_12 & 31)) << 6)) | ((posix__goto_154_12[1] & 63))))
                            if __goto_pending != 0:
                                break
                            var __ci_expr_old_2: c_int = clength__goto_179_7
                            (clength__goto_179_7 = clength__goto_179_7 + 1)
                            if __goto_pending != 0:
                                break
                        else:
                            if (((c__goto_178_12 & 16)) == 0):
                                (c__goto_178_12 = ((((((c__goto_178_12 & 15)) << 12)) | ((((posix__goto_154_12[1] & 63)) << 6))) | ((posix__goto_154_12[2] & 63))))
                                if __goto_pending != 0:
                                    break
                                (clength__goto_179_7 = clength__goto_179_7 + 2)
                                if __goto_pending != 0:
                                    break
                            else:
                                if (((c__goto_178_12 & 8)) == 0):
                                    (c__goto_178_12 = (((((((c__goto_178_12 & 7)) << 18)) | ((((posix__goto_154_12[1] & 63)) << 12))) | ((((posix__goto_154_12[2] & 63)) << 6))) | ((posix__goto_154_12[3] & 63))))
                                    if __goto_pending != 0:
                                        break
                                    (clength__goto_179_7 = clength__goto_179_7 + 3)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (((c__goto_178_12 & 4)) == 0):
                                        (c__goto_178_12 = ((((((((c__goto_178_12 & 3)) << 24)) | ((((posix__goto_154_12[1] & 63)) << 18))) | ((((posix__goto_154_12[2] & 63)) << 12))) | ((((posix__goto_154_12[3] & 63)) << 6))) | ((posix__goto_154_12[4] & 63))))
                                        if __goto_pending != 0:
                                            break
                                        (clength__goto_179_7 = clength__goto_179_7 + 4)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (c__goto_178_12 = (((((((((c__goto_178_12 & 1)) << 30)) | ((((posix__goto_154_12[1] & 63)) << 24))) | ((((posix__goto_154_12[2] & 63)) << 18))) | ((((posix__goto_154_12[3] & 63)) << 12))) | ((((posix__goto_154_12[4] & 63)) << 6))) | ((posix__goto_154_12[5] & 63))))
                                        if __goto_pending != 0:
                                            break
                                        (clength__goto_179_7 = clength__goto_179_7 + 5)
                                        if __goto_pending != 0:
                                            break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    (posix__goto_154_12 = posix__goto_154_12 + clength__goto_179_7)
                    if __goto_pending != 0:
                        break
                    (plength = plength - clength__goto_179_7)
                    if __goto_pending != 0:
                        break
                    (sc__goto_178_15 = (if (nextisliteral__goto_164_6 != 0): 0 else: c__goto_178_12))
                    if __goto_pending != 0:
                        break
                    (nextisliteral__goto_164_6 = 0)
                    if __goto_pending != 0:
                        break
                    if (posix_state__goto_161_10 >= 3):
                        if (c__goto_178_12 == 93):
                            while ((unsafe: *s__goto_208_7) != 0):
                                if (p__goto_155_14 >= endp__goto_157_14):
                                    return (-48)
                                if __goto_pending != 0:
                                    break
                                var __ci_expr_old_4: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_4) = (unsafe: *s__goto_208_7))
                                if __goto_pending != 0:
                                    break
                                var __ci_expr_old_3: *const i8 = s__goto_208_7
                            (s__goto_208_7 = s__goto_208_7 + 1)
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                            (posix_state__goto_161_10 = 2)
                            if __goto_pending != 0:
                                break
                        else:
                            match posix_state__goto_161_10
                                5 =>
                                    if (((c__goto_178_12) >= 97) and ((c__goto_178_12) <= 122)):
                                        break
                                    (posix_state__goto_161_10 = 3)
                                    if (((c__goto_178_12 == 58) and (plength > 0)) and ((unsafe: *posix__goto_154_12) == 93)):
                                        while ((unsafe: *s__goto_224_11) != 0):
                                            if (p__goto_155_14 >= endp__goto_157_14):
                                                return (-48)
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_6: *mut u8 = p__goto_155_14
                                            (p__goto_155_14 = p__goto_155_14 + 1)
                                            ((unsafe: *__ci_expr_old_6) = (unsafe: *s__goto_224_11))
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_5: *const i8 = s__goto_224_11
                                        (s__goto_224_11 = s__goto_224_11 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_7: c_ulong = plength
                                        (plength = plength - 1)
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_8: *const u8 = posix__goto_154_12
                                        (posix__goto_154_12 = posix__goto_154_12 + 1)
                                        if __goto_pending != 0:
                                            break
                                        continue
                                        if __goto_pending != 0:
                                            break
                                    if (c__goto_178_12 == 91):
                                        (posix_state__goto_161_10 = 4)
                                3 =>
                                    if (c__goto_178_12 == 91):
                                        (posix_state__goto_161_10 = 4)
                                4 =>
                                    if (c__goto_178_12 == 58):
                                        (posix_state__goto_161_10 = 5)
                                _ => 0
                            if __goto_pending != 0:
                                break
                            if (c__goto_178_12 == 92):
                                while ((unsafe: *s__goto_241_32) != 0):
                                    if (p__goto_155_14 >= endp__goto_157_14):
                                        return (-48)
                                    if __goto_pending != 0:
                                        break
                                    var __ci_expr_old_10: *mut u8 = p__goto_155_14
                                    (p__goto_155_14 = p__goto_155_14 + 1)
                                    ((unsafe: *__ci_expr_old_10) = (unsafe: *s__goto_241_32))
                                    if __goto_pending != 0:
                                        break
                                    var __ci_expr_old_9: *const i8 = s__goto_241_32
                                (s__goto_241_32 = s__goto_241_32 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if ((p__goto_155_14 + (clength__goto_179_7 as isize as usize)) > endp__goto_157_14):
                                return (-48)
                            if __goto_pending != 0:
                                break
                            with_memcpy((p__goto_155_14 as *mut c_void) as *i8, ((posix__goto_154_12 - (clength__goto_179_7 as isize as usize)) as *const c_void) as *i8, (((clength__goto_179_7) * (((8 / 8))))) as i64)
                            if __goto_pending != 0:
                                break
                            (p__goto_155_14 = p__goto_155_14 + clength__goto_179_7)
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                    else:
                        match sc__goto_178_15
                            91 =>
                                while ((unsafe: *s__goto_253_5) != 0):
                                    if (p__goto_155_14 >= endp__goto_157_14):
                                        return (-48)
                                    if __goto_pending != 0:
                                        break
                                    var __ci_expr_old_12: *mut u8 = p__goto_155_14
                                    (p__goto_155_14 = p__goto_155_14 + 1)
                                    ((unsafe: *__ci_expr_old_12) = (unsafe: *s__goto_253_5))
                                    if __goto_pending != 0:
                                        break
                                    var __ci_expr_old_11: *const i8 = s__goto_253_5
                                (s__goto_253_5 = s__goto_253_5 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (posix_state__goto_161_10 = 3)
                                if (plength > 0):
                                    if ((unsafe: *posix__goto_154_12) == 94):
                                        var __ci_expr_old_13: *const u8 = posix__goto_154_12
                                        (posix__goto_154_12 = posix__goto_154_12 + 1)
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_14: c_ulong = plength
                                        (plength = plength - 1)
                                        if __goto_pending != 0:
                                            break
                                        while ((unsafe: *s__goto_291_9) != 0):
                                            if (p__goto_155_14 >= endp__goto_157_14):
                                                return (-48)
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_16: *mut u8 = p__goto_155_14
                                            (p__goto_155_14 = p__goto_155_14 + 1)
                                            ((unsafe: *__ci_expr_old_16) = (unsafe: *s__goto_291_9))
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_15: *const i8 = s__goto_291_9
                                        (s__goto_291_9 = s__goto_291_9 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if ((plength > 0) and ((unsafe: *posix__goto_154_12) == 93)):
                                        var __ci_expr_old_17: *const u8 = posix__goto_154_12
                                        (posix__goto_154_12 = posix__goto_154_12 + 1)
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_18: c_ulong = plength
                                        (plength = plength - 1)
                                        if __goto_pending != 0:
                                            break
                                        while ((unsafe: *s__goto_297_9) != 0):
                                            if (p__goto_155_14 >= endp__goto_157_14):
                                                return (-48)
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_20: *mut u8 = p__goto_155_14
                                            (p__goto_155_14 = p__goto_155_14 + 1)
                                            ((unsafe: *__ci_expr_old_20) = (unsafe: *s__goto_297_9))
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_19: *const i8 = s__goto_297_9
                                        (s__goto_297_9 = s__goto_297_9 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            92 =>
                                if (plength == 0):
                                    return 101
                                if (extended__goto_163_6 != 0):
                                    (nextisliteral__goto_164_6 = 1)
                                else:
                                    if (((unsafe: *posix__goto_154_12) < 255) and (string_find_char(posix_meta_escapes, (unsafe: *posix__goto_154_12)) != (null as *mut i8))):
                                        if (((unsafe: *posix__goto_154_12) >= 48) and ((unsafe: *posix__goto_154_12) <= 57)):
                                            while ((unsafe: *s__goto_308_51) != 0):
                                                if (p__goto_155_14 >= endp__goto_157_14):
                                                    return (-48)
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_22: *mut u8 = p__goto_155_14
                                                (p__goto_155_14 = p__goto_155_14 + 1)
                                                ((unsafe: *__ci_expr_old_22) = (unsafe: *s__goto_308_51))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_21: *const i8 = s__goto_308_51
                                            (s__goto_308_51 = s__goto_308_51 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                            return (-48)
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_23: *mut u8 = p__goto_155_14
                                        (p__goto_155_14 = p__goto_155_14 + 1)
                                        var __ci_expr_old_24: *const u8 = posix__goto_154_12
                                        (posix__goto_154_12 = posix__goto_154_12 + 1)
                                        ((unsafe: *__ci_expr_old_23) = (unsafe: *__ci_expr_old_24))
                                        (lastspecial__goto_162_10 = (unsafe: *__ci_expr_old_23))
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_25: c_ulong = plength
                                        (plength = plength - 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (nextisliteral__goto_164_6 = 1)
                                    if __goto_pending != 0:
                                        break
                            41 =>
                                if ((not ((extended__goto_163_6 != 0))) or (bracount__goto_160_10 == 0)):
                                    __pc = 2
                                    __goto_pending = 1
                                var __ci_expr_old_26: c_uint = bracount__goto_160_10
                                (bracount__goto_160_10 = bracount__goto_160_10 - 1)
                                __pc = 1
                                __goto_pending = 1
                            40 =>
                                var __ci_expr_old_27: c_uint = bracount__goto_160_10
                                (bracount__goto_160_10 = bracount__goto_160_10 + 1)
                                if (not ((extended__goto_163_6 != 0))):
                                    __pc = 2
                                    __goto_pending = 1
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            63 =>
                                if (not ((extended__goto_163_6 != 0))):
                                    __pc = 2
                                    __goto_pending = 1
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            43 =>
                                if (not ((extended__goto_163_6 != 0))):
                                    __pc = 2
                                    __goto_pending = 1
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            123 =>
                                if (not ((extended__goto_163_6 != 0))):
                                    __pc = 2
                                    __goto_pending = 1
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            125 =>
                                if (not ((extended__goto_163_6 != 0))):
                                    __pc = 2
                                    __goto_pending = 1
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            124 =>
                                if (not ((extended__goto_163_6 != 0))):
                                    __pc = 2
                                    __goto_pending = 1
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            46 =>
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            36 =>
                                (posix_state__goto_161_10 = 2)
                                (lastspecial__goto_162_10 = c__goto_178_12)
                                if ((p__goto_155_14 + (1 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                var __ci_expr_old_28: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_28) = c__goto_178_12)
                            42 =>
                                if (lastspecial__goto_162_10 != 42):
                                    if ((not ((extended__goto_163_6 != 0))) and ((posix_state__goto_161_10 < 2) or (lastspecial__goto_162_10 == 40))):
                                        __pc = 2
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                            94 =>
                                if (extended__goto_163_6 != 0):
                                    __pc = 1
                                    __goto_pending = 1
                                if ((posix_state__goto_161_10 == 0) or (lastspecial__goto_162_10 == 40)):
                                    (posix_state__goto_161_10 = 1)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                if ((c__goto_178_12 < 255) and (string_find_char(pcre2_escaped_literals, c__goto_178_12) != (null as *mut i8))):
                                    while ((unsafe: *s__goto_367_7) != 0):
                                        if (p__goto_155_14 >= endp__goto_157_14):
                                            return (-48)
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_30: *mut u8 = p__goto_155_14
                                        (p__goto_155_14 = p__goto_155_14 + 1)
                                        ((unsafe: *__ci_expr_old_30) = (unsafe: *s__goto_367_7))
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_29: *const i8 = s__goto_367_7
                                    (s__goto_367_7 = s__goto_367_7 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                (lastspecial__goto_162_10 = 255)
                                if ((p__goto_155_14 + (clength__goto_179_7 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                with_memcpy((p__goto_155_14 as *mut c_void) as *i8, ((posix__goto_154_12 - (clength__goto_179_7 as isize as usize)) as *const c_void) as *i8, (((clength__goto_179_7) * (((8 / 8))))) as i64)
                                (p__goto_155_14 = p__goto_155_14 + clength__goto_179_7)
                                (posix_state__goto_161_10 = 2)
                            _ =>
                                if ((c__goto_178_12 < 255) and (string_find_char(pcre2_escaped_literals, c__goto_178_12) != (null as *mut i8))):
                                    while ((unsafe: *s__goto_367_7) != 0):
                                        if (p__goto_155_14 >= endp__goto_157_14):
                                            return (-48)
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_30: *mut u8 = p__goto_155_14
                                        (p__goto_155_14 = p__goto_155_14 + 1)
                                        ((unsafe: *__ci_expr_old_30) = (unsafe: *s__goto_367_7))
                                        if __goto_pending != 0:
                                            break
                                        var __ci_expr_old_29: *const i8 = s__goto_367_7
                                    (s__goto_367_7 = s__goto_367_7 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                (lastspecial__goto_162_10 = 255)
                                if ((p__goto_155_14 + (clength__goto_179_7 as isize as usize)) > endp__goto_157_14):
                                    return (-48)
                                with_memcpy((p__goto_155_14 as *mut c_void) as *i8, ((posix__goto_154_12 - (clength__goto_179_7 as isize as usize)) as *const c_void) as *i8, (((clength__goto_179_7) * (((8 / 8))))) as i64)
                                (p__goto_155_14 = p__goto_155_14 + clength__goto_179_7)
                                (posix_state__goto_161_10 = 2)
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                if (posix_state__goto_161_10 >= 3):
                    return 106
                if __goto_pending != 0:
                    continue
                (convlength__goto_158_12 = convlength__goto_158_12 + ((p__goto_155_14 as usize -% pp__goto_156_14 as usize) / sizeof[u8]()))
                if __goto_pending != 0:
                    continue
                ((unsafe: *bufflenptr) = convlength__goto_158_12)
                if __goto_pending != 0:
                    continue
                var __ci_expr_old_31: *mut u8 = p__goto_155_14
                (p__goto_155_14 = p__goto_155_14 + 1)
                ((unsafe: *__ci_expr_old_31) = 0)
                if __goto_pending != 0:
                    continue
                return 0
                if __goto_pending != 0:
                    continue
            _ => break

type pcre2_output_context { output: *mut u8 = null, output_end: *const u8 = null, output_size: c_ulong = 0, out_str: [8]u8 = [0 as u8; 8] }
type struct_pcre2_output_context = pcre2_output_context
fn convert_glob_write(out: *mut pcre2_output_context, chr: u8):
    (out.output_size = out.output_size + 1)

    if (out.output < out.output_end):
        var __ci_expr_old_0: *mut u8 = out.output
        (out.output = out.output + 1)
        ((unsafe: *__ci_expr_old_0) = chr)


fn convert_glob_write_str(out: *mut pcre2_output_context, __param_length: c_ulong):
    var length = __param_length
    var out_str: *mut u8 = (&out.out_str[0] as *mut u8)

    var output: *mut u8 = out.output

    var output_end: *const u8 = out.output_end

    var output_size: c_ulong = out.output_size

    while true:
        var __ci_expr_old_0: c_ulong = output_size
        (output_size = output_size + 1)
        
        if (output < (output_end as *mut u8)):
            var __ci_expr_old_1: *mut u8 = output
            (output = output + 1)
            var __ci_expr_old_2: *mut u8 = out_str
            (out_str = out_str + 1)
            ((unsafe: *__ci_expr_old_1) = (unsafe: *__ci_expr_old_2))
        
        var __ci_cond_do_3: bool = false
        (length = length - 1)
        (__ci_cond_do_3 = ((if length != 0: 1 else: 0) != 0))
        if not (__ci_cond_do_3):
            break

    (out.output = output)

    (out.output_size = output_size)


fn convert_glob_print_separator(out: *mut pcre2_output_context, separator: u8, with_escape: c_int):
    if (with_escape != 0):
        convert_glob_write(out, 92)

    convert_glob_write(out, separator)


fn convert_glob_print_wildcard(out: *mut pcre2_output_context, separator: u8, with_escape: c_int):
    (out.out_str[0] = 91)

    (out.out_str[1] = 94)

    convert_glob_write_str(out, 2)

    convert_glob_print_separator(out, separator, with_escape)

    convert_glob_write(out, 93)


fn convert_glob_parse_class(from: *mut *const u8, pattern_end: *const u8, out: *mut pcre2_output_context) -> c_int:
    var start: *const u8 = ((unsafe: *from) + (1 as isize as usize))

    var pattern: *const u8 = start

    var class_ptr: *const i8

    var c: u8

    var class_index: c_int

    while (1 != 0):
        if (pattern >= pattern_end):
            return 0
        
        var __ci_expr_old_0: *const u8 = pattern
        (pattern = pattern + 1)
        (c = (unsafe: *__ci_expr_old_0))
        
        if ((c < 97) or (c > 122)):
            break
        

    if (((c != 58) or (pattern >= pattern_end)) or ((unsafe: *pattern) != 93)):
        return 0

    (class_ptr = posix_classes)

    (class_index = 1)

    while (1 != 0):
        if ((unsafe: *class_ptr) == 0):
            return 0
        
        (pattern = start)
        
        while ((unsafe: *pattern) == ((unsafe: *class_ptr) as u8)):
            if ((unsafe: *pattern) == 58):
                pattern = pattern + 2
                
                start = start - 2
                
                while true:
                    var __ci_expr_old_1: *const u8 = start
                    (start = start + 1)
                    
                    if not ((start < pattern)):
                        break
                    
                
                ((unsafe: *from) = pattern)
                
                return class_index
                
            
            (pattern = pattern + 1)
            
            (class_ptr = class_ptr + 1)
            
        
        while ((unsafe: *class_ptr) != 58):
            (class_ptr = class_ptr + 1)
        
        (class_ptr = class_ptr + 1)
        
        (class_index = class_index + 1)
        


fn convert_glob_char_in_class(class_index: c_int, c: u8) -> c_int:
    var cbits: *const u8 = ((&_pcre2_default_tables_8[0] as *mut u8) + (512 as isize as usize))

    var cbit: c_int

    match class_index
        1 =>
            if (c == 95):
                return 0
            if (((((cbits + (64 as isize as usize)))[(c / 8)] & ((1 << ((c & 7)))))) != 0):
                return 0
            (cbit = 160)
        2 =>
            (cbit = 128)
        3 =>
            (cbit = 96)
        4 =>
            if (c == 95):
                return 0
            (cbit = 160)
        5 =>
            if (((((cbits + (288 as isize as usize)))[(c / 8)] & ((1 << ((c & 7)))))) != 0):
                return 1
            (cbit = 224)
        6 =>
            if ((((c == 10) or (c == 11)) or (c == 12)) or (c == 13)):
                return 0
            (cbit = 0)
        7 =>
            (cbit = 288)
        8 =>
            (cbit = 64)
        9 =>
            (cbit = 192)
        10 =>
            (cbit = 224)
        11 =>
            (cbit = 256)
        12 =>
            (cbit = 0)
        13 =>
            (cbit = 160)
        14 =>
            (cbit = 32)
        _ =>
            return 0

    return (if ((((cbits + (cbit as isize as usize)))[(c / 8)] & ((1 << ((c & 7)))))) != 0: 1 else: 0)


fn convert_glob_parse_range(from: *mut *const u8, pattern_end: *const u8, out: *mut pcre2_output_context, utf: c_int, separator: u8, with_escape: c_int, escape: u8, no_wildsep: c_int) -> c_int:
    var is_negative: c_int = 0

    var separator_seen: c_int = 0

    var has_prev_c: c_int

    var pattern: *const u8 = (unsafe: *from)

    var char_start: *const u8 = (null as *const u8)

    var c: c_uint
    var prev_c: c_uint

    var len: c_int
    var class_index: c_int

    utf

    if (pattern >= pattern_end):
        ((unsafe: *from) = pattern)
        
        return 106
        

    if (((unsafe: *pattern) == 33) or ((unsafe: *pattern) == 94)):
        (pattern = pattern + 1)
        
        if (pattern >= pattern_end):
            ((unsafe: *from) = pattern)
            
            return 106
            
        
        (is_negative = 1)
        
        (out.out_str[0] = 91)
        
        (out.out_str[1] = 94)
        
        (len = 2)
        
        if (not ((no_wildsep != 0))):
            if (with_escape != 0):
                (out.out_str[len] = 92)
                
                (len = len + 1)
                
            
            (out.out_str[len] = separator)
            
        
        convert_glob_write_str(out, (len + 1))
        
    else:
        convert_glob_write(out, 91)

    (has_prev_c = 0)

    (prev_c = 0)

    if ((unsafe: *pattern) == 93):
        (out.out_str[0] = 92)
        
        (out.out_str[1] = 93)
        
        convert_glob_write_str(out, 2)
        
        (has_prev_c = 1)
        
        (prev_c = 93)
        
        (pattern = pattern + 1)
        

    while (pattern < pattern_end):
        (char_start = pattern)
        
        var __ci_expr_old_0: *const u8 = pattern
        (pattern = pattern + 1)
        (c = (unsafe: *__ci_expr_old_0))
        
        if ((utf != 0) and (c >= 192)):
            if (((c & 32)) == 0):
                var __ci_expr_old_1: *const u8 = pattern
                (pattern = pattern + 1)
                (c = (((((c & 31)) << 6)) | (((unsafe: *__ci_expr_old_1) & 63))))
            else:
                if (((c & 16)) == 0):
                    (c = ((((((c & 15)) << 12)) | (((((unsafe: *pattern) & 63)) << 6))) | ((pattern[1] & 63))))
                    
                    pattern = pattern + 2
                    
                else:
                    if (((c & 8)) == 0):
                        (c = (((((((c & 7)) << 18)) | (((((unsafe: *pattern) & 63)) << 12))) | ((((pattern[1] & 63)) << 6))) | ((pattern[2] & 63))))
                        
                        pattern = pattern + 3
                        
                    else:
                        if (((c & 4)) == 0):
                            (c = ((((((((c & 3)) << 24)) | (((((unsafe: *pattern) & 63)) << 18))) | ((((pattern[1] & 63)) << 12))) | ((((pattern[2] & 63)) << 6))) | ((pattern[3] & 63))))
                            
                            pattern = pattern + 4
                            
                        else:
                            (c = (((((((((c & 1)) << 30)) | (((((unsafe: *pattern) & 63)) << 24))) | ((((pattern[1] & 63)) << 18))) | ((((pattern[2] & 63)) << 12))) | ((((pattern[3] & 63)) << 6))) | ((pattern[4] & 63))))
                            
                            pattern = pattern + 5
                            
            
        
        if (c == 93):
            convert_glob_write(out, c)
            
            if (((not ((is_negative != 0))) and (not ((no_wildsep != 0)))) and (separator_seen != 0)):
                (out.out_str[0] = 40)
                
                (out.out_str[1] = 63)
                
                (out.out_str[2] = 60)
                
                (out.out_str[3] = 33)
                
                convert_glob_write_str(out, 4)
                
                convert_glob_print_separator(out, separator, with_escape)
                
                convert_glob_write(out, 41)
                
            
            ((unsafe: *from) = pattern)
            
            return 0
            
        
        if (pattern >= pattern_end):
            break
        
        if ((c == 91) and ((unsafe: *pattern) == 58)):
            ((unsafe: *from) = pattern)
            
            (class_index = convert_glob_parse_class(from, pattern_end, out))
            
            if (class_index != 0):
                (pattern = (unsafe: *from))
                
                (has_prev_c = 0)
                
                (prev_c = 0)
                
                if ((not ((is_negative != 0))) and (convert_glob_char_in_class(class_index, separator) != 0)):
                    (separator_seen = 1)
                
                continue
                
            
        else:
            if (((c == 45) and (has_prev_c != 0)) and ((unsafe: *pattern) != 93)):
                convert_glob_write(out, 45)
                
                (char_start = pattern)
                
                var __ci_expr_old_2: *const u8 = pattern
                (pattern = pattern + 1)
                (c = (unsafe: *__ci_expr_old_2))
                
                if ((utf != 0) and (c >= 192)):
                    if (((c & 32)) == 0):
                        var __ci_expr_old_3: *const u8 = pattern
                        (pattern = pattern + 1)
                        (c = (((((c & 31)) << 6)) | (((unsafe: *__ci_expr_old_3) & 63))))
                    else:
                        if (((c & 16)) == 0):
                            (c = ((((((c & 15)) << 12)) | (((((unsafe: *pattern) & 63)) << 6))) | ((pattern[1] & 63))))
                            
                            pattern = pattern + 2
                            
                        else:
                            if (((c & 8)) == 0):
                                (c = (((((((c & 7)) << 18)) | (((((unsafe: *pattern) & 63)) << 12))) | ((((pattern[1] & 63)) << 6))) | ((pattern[2] & 63))))
                                
                                pattern = pattern + 3
                                
                            else:
                                if (((c & 4)) == 0):
                                    (c = ((((((((c & 3)) << 24)) | (((((unsafe: *pattern) & 63)) << 18))) | ((((pattern[1] & 63)) << 12))) | ((((pattern[2] & 63)) << 6))) | ((pattern[3] & 63))))
                                    
                                    pattern = pattern + 4
                                    
                                else:
                                    (c = (((((((((c & 1)) << 30)) | (((((unsafe: *pattern) & 63)) << 24))) | ((((pattern[1] & 63)) << 18))) | ((((pattern[2] & 63)) << 12))) | ((((pattern[3] & 63)) << 6))) | ((pattern[4] & 63))))
                                    
                                    pattern = pattern + 5
                                    
                    
                
                if (pattern >= pattern_end):
                    break
                
                if ((escape != 0) and (c == escape)):
                    (char_start = pattern)
                    
                    var __ci_expr_old_4: *const u8 = pattern
                    (pattern = pattern + 1)
                    (c = (unsafe: *__ci_expr_old_4))
                    
                    if ((utf != 0) and (c >= 192)):
                        if (((c & 32)) == 0):
                            var __ci_expr_old_5: *const u8 = pattern
                            (pattern = pattern + 1)
                            (c = (((((c & 31)) << 6)) | (((unsafe: *__ci_expr_old_5) & 63))))
                        else:
                            if (((c & 16)) == 0):
                                (c = ((((((c & 15)) << 12)) | (((((unsafe: *pattern) & 63)) << 6))) | ((pattern[1] & 63))))
                                
                                pattern = pattern + 2
                                
                            else:
                                if (((c & 8)) == 0):
                                    (c = (((((((c & 7)) << 18)) | (((((unsafe: *pattern) & 63)) << 12))) | ((((pattern[1] & 63)) << 6))) | ((pattern[2] & 63))))
                                    
                                    pattern = pattern + 3
                                    
                                else:
                                    if (((c & 4)) == 0):
                                        (c = ((((((((c & 3)) << 24)) | (((((unsafe: *pattern) & 63)) << 18))) | ((((pattern[1] & 63)) << 12))) | ((((pattern[2] & 63)) << 6))) | ((pattern[3] & 63))))
                                        
                                        pattern = pattern + 4
                                        
                                    else:
                                        (c = (((((((((c & 1)) << 30)) | (((((unsafe: *pattern) & 63)) << 24))) | ((((pattern[1] & 63)) << 18))) | ((((pattern[2] & 63)) << 12))) | ((((pattern[3] & 63)) << 6))) | ((pattern[4] & 63))))
                                        
                                        pattern = pattern + 5
                                        
                        
                    
                else:
                    if ((c == 91) and ((unsafe: *pattern) == 58)):
                        ((unsafe: *from) = pattern)
                        
                        return (-64)
                        
                
                if (prev_c > c):
                    ((unsafe: *from) = pattern)
                    
                    return (-64)
                    
                
                if ((prev_c < separator) and (separator < c)):
                    (separator_seen = 1)
                
                (has_prev_c = 0)
                
                (prev_c = 0)
                
            else:
                if ((escape != 0) and (c == escape)):
                    (char_start = pattern)
                    
                    var __ci_expr_old_6: *const u8 = pattern
                    (pattern = pattern + 1)
                    (c = (unsafe: *__ci_expr_old_6))
                    
                    if ((utf != 0) and (c >= 192)):
                        if (((c & 32)) == 0):
                            var __ci_expr_old_7: *const u8 = pattern
                            (pattern = pattern + 1)
                            (c = (((((c & 31)) << 6)) | (((unsafe: *__ci_expr_old_7) & 63))))
                        else:
                            if (((c & 16)) == 0):
                                (c = ((((((c & 15)) << 12)) | (((((unsafe: *pattern) & 63)) << 6))) | ((pattern[1] & 63))))
                                
                                pattern = pattern + 2
                                
                            else:
                                if (((c & 8)) == 0):
                                    (c = (((((((c & 7)) << 18)) | (((((unsafe: *pattern) & 63)) << 12))) | ((((pattern[1] & 63)) << 6))) | ((pattern[2] & 63))))
                                    
                                    pattern = pattern + 3
                                    
                                else:
                                    if (((c & 4)) == 0):
                                        (c = ((((((((c & 3)) << 24)) | (((((unsafe: *pattern) & 63)) << 18))) | ((((pattern[1] & 63)) << 12))) | ((((pattern[2] & 63)) << 6))) | ((pattern[3] & 63))))
                                        
                                        pattern = pattern + 4
                                        
                                    else:
                                        (c = (((((((((c & 1)) << 30)) | (((((unsafe: *pattern) & 63)) << 24))) | ((((pattern[1] & 63)) << 18))) | ((((pattern[2] & 63)) << 12))) | ((((pattern[3] & 63)) << 6))) | ((pattern[4] & 63))))
                                        
                                        pattern = pattern + 5
                                        
                        
                    
                    if (pattern >= pattern_end):
                        break
                    
                
                (has_prev_c = 1)
                
                (prev_c = c)
                
        
        if ((((c == 91) or (c == 93)) or (c == 92)) or (c == 45)):
            convert_glob_write(out, 92)
        
        if (c == separator):
            (separator_seen = 1)
        
        while true:
            var __ci_expr_old_8: *const u8 = char_start
            (char_start = char_start + 1)
            
            if not ((char_start < pattern)):
                break
            
        

    ((unsafe: *from) = pattern)

    return 106


fn convert_glob_print_commit(out: *mut pcre2_output_context):
    (out.out_str[0] = 40)

    (out.out_str[1] = 42)

    (out.out_str[2] = 67)

    (out.out_str[3] = 79)

    (out.out_str[4] = 77)

    (out.out_str[5] = 77)

    (out.out_str[6] = 73)

    (out.out_str[7] = 84)

    convert_glob_write_str(out, 8)

    convert_glob_write(out, 41)


fn convert_glob(options: c_uint, __param_pattern: *const u8, plength: c_ulong, utf: c_int, use_buffer: *mut u8, use_length: c_ulong, bufflenptr: *mut c_ulong, dummyrun: c_int, ccontext: *mut pcre2_real_convert_context_8) -> c_int:
    var pattern = __param_pattern
    var out: pcre2_output_context

    var pattern_start: *const u8 = pattern

    var pattern_end: *const u8 = (pattern + plength)

    var separator: u8 = ccontext.glob_separator

    var escape: u8 = ccontext.glob_escape

    var c: u8

    var no_wildsep: c_int = (if ((options & 48)) != 0: 1 else: 0)

    var no_starstar: c_int = (if ((options & 80)) != 0: 1 else: 0)

    var in_atomic: c_int = 0

    var after_starstar: c_int = 0

    var no_slash_z: c_int = 0

    var with_escape: c_int
    var is_start: c_int
    var after_separator: c_int

    var result: c_int = 0

    utf

    if ((utf != 0) and ((separator >= 128) or (escape >= 128))):
        ((unsafe: *bufflenptr) = 0)
        
        return (-64)
        

    (with_escape = (if string_find_char(pcre2_escaped_literals, separator) != null: 1 else: 0))

    (out.output = use_buffer)

    (out.output_end = ((use_buffer + use_length) as *const u8))

    (out.output_size = 0)

    (out.out_str[0] = 40)

    (out.out_str[1] = 63)

    (out.out_str[2] = 115)

    (out.out_str[3] = 41)

    convert_glob_write_str((&mut out as *mut pcre2_output_context), 4)

    (is_start = 1)

    if ((pattern < pattern_end) and (pattern[0] == 42)):
        if (no_wildsep != 0):
            (is_start = 0)
        else:
            if (((not ((no_starstar != 0))) and ((pattern + (1 as isize as usize)) < pattern_end)) and (pattern[1] == 42)):
                (is_start = 0)
        

    if (is_start != 0):
        (out.out_str[0] = 92)
        
        (out.out_str[1] = 65)
        
        convert_glob_write_str((&mut out as *mut pcre2_output_context), 2)
        

    while (pattern < pattern_end):
        var __ci_expr_old_0: *const u8 = pattern
        (pattern = pattern + 1)
        (c = (unsafe: *__ci_expr_old_0))
        
        if (c == 42):
            (is_start = (if pattern == (pattern_start + (1 as isize as usize)): 1 else: 0))
            
            if (in_atomic != 0):
                convert_glob_write((&mut out as *mut pcre2_output_context), 41)
                
                (in_atomic = 0)
                
            
            if (((not ((no_starstar != 0))) and (pattern < pattern_end)) and ((unsafe: *pattern) == 42)):
                (after_separator = (if (is_start != 0) or (pattern[-2] == separator): 1 else: 0))
                
                while true:
                    (pattern = pattern + 1)
                    
                    if not (((pattern < pattern_end) and ((unsafe: *pattern) == 42))):
                        break
                    
                
                if (pattern >= pattern_end):
                    (no_slash_z = 1)
                    
                    break
                    
                
                (after_starstar = 1)
                
                if (((((after_separator != 0) and (escape != 0)) and ((unsafe: *pattern) == escape)) and ((pattern + (1 as isize as usize)) < pattern_end)) and (pattern[1] == separator)):
                    (pattern = pattern + 1)
                
                if (is_start != 0):
                    if ((unsafe: *pattern) != separator):
                        continue
                    
                    (out.out_str[0] = 40)
                    
                    (out.out_str[1] = 63)
                    
                    (out.out_str[2] = 58)
                    
                    (out.out_str[3] = 92)
                    
                    (out.out_str[4] = 65)
                    
                    (out.out_str[5] = 124)
                    
                    convert_glob_write_str((&mut out as *mut pcre2_output_context), 6)
                    
                    convert_glob_print_separator((&mut out as *mut pcre2_output_context), separator, with_escape)
                    
                    convert_glob_write((&mut out as *mut pcre2_output_context), 41)
                    
                    (pattern = pattern + 1)
                    
                    continue
                    
                
                convert_glob_print_commit((&mut out as *mut pcre2_output_context))
                
                if ((not ((after_separator != 0))) or ((unsafe: *pattern) != separator)):
                    (out.out_str[0] = 46)
                    
                    (out.out_str[1] = 42)
                    
                    (out.out_str[2] = 63)
                    
                    convert_glob_write_str((&mut out as *mut pcre2_output_context), 3)
                    
                    continue
                    
                
                (out.out_str[0] = 40)
                
                (out.out_str[1] = 63)
                
                (out.out_str[2] = 58)
                
                (out.out_str[3] = 46)
                
                (out.out_str[4] = 42)
                
                (out.out_str[5] = 63)
                
                convert_glob_write_str((&mut out as *mut pcre2_output_context), 6)
                
                convert_glob_print_separator((&mut out as *mut pcre2_output_context), separator, with_escape)
                
                (out.out_str[0] = 41)
                
                (out.out_str[1] = 63)
                
                (out.out_str[2] = 63)
                
                convert_glob_write_str((&mut out as *mut pcre2_output_context), 3)
                
                (pattern = pattern + 1)
                
                continue
                
            
            if ((pattern < pattern_end) and ((unsafe: *pattern) == 42)):
                while true:
                    (pattern = pattern + 1)
                    
                    if not (((pattern < pattern_end) and ((unsafe: *pattern) == 42))):
                        break
                    
                
            
            if (no_wildsep != 0):
                if (pattern >= pattern_end):
                    (no_slash_z = 1)
                    
                    break
                    
                
                if (is_start != 0):
                    continue
                
            
            if (not ((is_start != 0))):
                if (after_starstar != 0):
                    (out.out_str[0] = 40)
                    
                    (out.out_str[1] = 63)
                    
                    (out.out_str[2] = 62)
                    
                    convert_glob_write_str((&mut out as *mut pcre2_output_context), 3)
                    
                    (in_atomic = 1)
                    
                else:
                    convert_glob_print_commit((&mut out as *mut pcre2_output_context))
                
            
            if (no_wildsep != 0):
                convert_glob_write((&mut out as *mut pcre2_output_context), 46)
            else:
                convert_glob_print_wildcard((&mut out as *mut pcre2_output_context), separator, with_escape)
            
            (out.out_str[0] = 42)
            
            (out.out_str[1] = 63)
            
            if (pattern >= pattern_end):
                (out.out_str[1] = 43)
            
            convert_glob_write_str((&mut out as *mut pcre2_output_context), 2)
            
            continue
            
        
        if (c == 63):
            if (no_wildsep != 0):
                convert_glob_write((&mut out as *mut pcre2_output_context), 46)
            else:
                convert_glob_print_wildcard((&mut out as *mut pcre2_output_context), separator, with_escape)
            
            continue
            
        
        if (c == 91):
            (result = convert_glob_parse_range((&mut pattern as *mut *const u8), pattern_end, (&mut out as *mut pcre2_output_context), utf, separator, with_escape, escape, no_wildsep))
            
            if (result != 0):
                break
            
            continue
            
        
        if ((escape != 0) and (c == escape)):
            if (pattern >= pattern_end):
                (result = (-64))
                
                break
                
            
            var __ci_expr_old_1: *const u8 = pattern
            (pattern = pattern + 1)
            (c = (unsafe: *__ci_expr_old_1))
            
        
        if ((c < 255) and (string_find_char(pcre2_escaped_literals, c) != null)):
            convert_glob_write((&mut out as *mut pcre2_output_context), 92)
        
        convert_glob_write((&mut out as *mut pcre2_output_context), c)
        

    if (result == 0):
        if (not ((no_slash_z != 0))):
            (out.out_str[0] = 92)
            
            (out.out_str[1] = 122)
            
            convert_glob_write_str((&mut out as *mut pcre2_output_context), 2)
            
        
        if (in_atomic != 0):
            convert_glob_write((&mut out as *mut pcre2_output_context), 41)
        
        convert_glob_write((&mut out as *mut pcre2_output_context), 0)
        
        if ((not ((dummyrun != 0))) and (out.output_size != ((((out.output as usize -% use_buffer as usize) / sizeof[u8]())) as c_ulong))):
            (result = (-48))
        

    if (result != 0):
        ((unsafe: *bufflenptr) = ((pattern as usize -% pattern_start as usize) / sizeof[u8]()))
        
        return result
        

    ((unsafe: *bufflenptr) = (out.output_size -% 1))

    return 0


var pcre2_escaped_literals: *const i8 = "\134\077\052\053\174\056\136\044\173\175\133\135\050\051"
var posix_meta_escapes: *const i8 = "\050\051\173\175\061\062\063\064\065\066\067\070\071"
var posix_classes: *const i8 = "\141\154\160\150\141\072\154\157\167\145\162\072\165\160\160\145\162\072\141\154\156\165\155\072\141\163\143\151\151\072\142\154\141\156\153\072\143\156\164\162\154\072\144\151\147\151\164\072\147\162\141\160\150\072\160\162\151\156\164\072\160\165\156\143\164\072\163\160\141\143\145\072\167\157\162\144\072\170\144\151\147\151\164\072"
extern let _pcre2_utf8_table1: [6]c_int
extern let _pcre2_utf8_table1_size: c_uint
extern let _pcre2_utf8_table2: [6]c_int
extern let _pcre2_utf8_table3: [6]c_int
extern let _pcre2_utf8_table4: [64]u8
extern let _pcre2_OP_lengths_8: [173]u8
extern let _pcre2_callout_end_delims_8: [9]c_uint
extern let _pcre2_callout_start_delims_8: [9]c_uint
extern var _pcre2_default_compile_context_8: pcre2_real_compile_context_8
extern var _pcre2_default_convert_context_8: pcre2_real_convert_context_8
extern var _pcre2_default_match_context_8: pcre2_real_match_context_8
extern let _pcre2_default_tables_8: [1088]u8
extern let _pcre2_hspace_list_8: [20]c_uint
extern let _pcre2_vspace_list_8: [8]c_uint
extern let _pcre2_ucd_boolprop_sets_8: [382]c_uint
extern let _pcre2_ucd_caseless_sets_8: [118]c_uint
extern let _pcre2_ucd_turkish_dotted_i_caseset_8: c_uint
extern let _pcre2_ucd_nocase_ranges_8: [84]c_uint
extern let _pcre2_ucd_nocase_ranges_size_8: c_uint
extern let _pcre2_ucd_digit_sets_8: [78]c_uint
extern let _pcre2_ucd_script_sets_8: [476]c_uint
extern let _pcre2_ucd_records_8: [1563]ucd_record
extern let _pcre2_ucd_stage1_8: [8704]c_ushort
extern let _pcre2_ucd_stage2_8: [40192]c_ushort
extern let _pcre2_ucp_gbtable_8: [15]c_uint
extern let _pcre2_ucp_gentype_8: [30]c_uint
extern var _pcre2_unicode_version_8: *const i8
extern let _pcre2_utt_8: *ucp_type_table
extern let _pcre2_utt_names_8: *c_char
extern let _pcre2_utt_size_8: c_ulong
extern let _pcre2_ebcdic_1047_to_ascii_8: *u8
extern let _pcre2_ascii_to_ebcdic_1047_8: *u8
// untranslatable fn-like macro
fn ACROSSCHAR() -> Never:
    comptime_error("untranslatable C macro: ACROSSCHAR")
// untranslatable fn-like macro
fn BACKCHAR() -> Never:
    comptime_error("untranslatable C macro: BACKCHAR")
// untranslatable fn-like macro
fn BYTES2CU() -> Never:
    comptime_error("untranslatable C macro: BYTES2CU")
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
fn CHMAX_255[T](c: T) -> T:
    (c <= 255)
// untranslatable fn-like macro
fn CU2BYTES() -> Never:
    comptime_error("untranslatable C macro: CU2BYTES")
let DUMMY_BUFFER_SIZE: c_int = 100
// untranslatable fn-like macro
fn FORWARDCHAR() -> Never:
    comptime_error("untranslatable C macro: FORWARDCHAR")
// untranslatable fn-like macro
fn FORWARDCHARTEST() -> Never:
    comptime_error("untranslatable C macro: FORWARDCHARTEST")
// untranslatable fn-like macro
fn GET() -> Never:
    comptime_error("untranslatable C macro: GET")
// untranslatable fn-like macro
fn GET2() -> Never:
    comptime_error("untranslatable C macro: GET2")
// untranslatable fn-like macro
fn GETCHAR() -> Never:
    comptime_error("untranslatable C macro: GETCHAR")
// untranslatable fn-like macro
fn GETCHARINC() -> Never:
    comptime_error("untranslatable C macro: GETCHARINC")
// untranslatable fn-like macro
fn GETCHARINCTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARINCTEST")
// untranslatable fn-like macro
fn GETCHARLEN() -> Never:
    comptime_error("untranslatable C macro: GETCHARLEN")
// untranslatable fn-like macro
fn GETCHARLENTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARLENTEST")
// untranslatable fn-like macro
fn GETCHARTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARTEST")
// untranslatable fn-like macro
fn GETUTF8() -> Never:
    comptime_error("untranslatable C macro: GETUTF8")
// untranslatable fn-like macro
fn GETUTF8INC() -> Never:
    comptime_error("untranslatable C macro: GETUTF8INC")
// untranslatable fn-like macro
fn GETUTF8LEN() -> Never:
    comptime_error("untranslatable C macro: GETUTF8LEN")
// untranslatable fn-like macro
fn GET_EXTRALEN() -> Never:
    comptime_error("untranslatable C macro: GET_EXTRALEN")
// untranslatable fn-like macro
fn GET_UCD() -> Never:
    comptime_error("untranslatable C macro: GET_UCD")
fn HASUTF8EXTRALEN[T](c: T) -> T:
    (c >= 0xc0)
fn HAS_EXTRALEN[T](c: T) -> T:
    HASUTF8EXTRALEN(c)
// untranslatable fn-like macro
fn HTONL() -> Never:
    comptime_error("untranslatable C macro: HTONL")
// untranslatable fn-like macro
fn HTONLL() -> Never:
    comptime_error("untranslatable C macro: HTONLL")
// untranslatable fn-like macro
fn HTONS() -> Never:
    comptime_error("untranslatable C macro: HTONS")
fn INT16_C[T](v: T) -> T:
    v
fn INT32_C[T](v: T) -> T:
    v
fn INT64_C[T](v: T) -> i64:
    (v as i64)
fn INT8_C[T](v: T) -> T:
    v
fn INTMAX_C[T](v: T) -> i64:
    (v as i64)
// untranslatable fn-like macro
fn ISLOWER() -> Never:
    comptime_error("untranslatable C macro: ISLOWER")
// untranslatable fn-like macro
fn IS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: IS_NEWLINE")
// untranslatable fn-like macro
fn MAPBIT() -> Never:
    comptime_error("untranslatable C macro: MAPBIT")
// untranslatable fn-like macro
fn MAPSET() -> Never:
    comptime_error("untranslatable C macro: MAPSET")
// untranslatable fn-like macro
fn MAX_255() -> Never:
    comptime_error("untranslatable C macro: MAX_255")
// untranslatable fn-like macro
fn NOT_FIRSTCU() -> Never:
    comptime_error("untranslatable C macro: NOT_FIRSTCU")
// untranslatable fn-like macro
fn NTOHL() -> Never:
    comptime_error("untranslatable C macro: NTOHL")
// untranslatable fn-like macro
fn NTOHLL() -> Never:
    comptime_error("untranslatable C macro: NTOHLL")
// untranslatable fn-like macro
fn NTOHS() -> Never:
    comptime_error("untranslatable C macro: NTOHS")
// untranslatable fn-like macro
fn PCRE2_ASSERT() -> Never:
    comptime_error("untranslatable C macro: PCRE2_ASSERT")
// untranslatable fn-like macro
fn PCRE2_DEBUG_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_DEBUG_UNREACHABLE")
// untranslatable fn-like macro
fn PCRE2_GLUE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_GLUE")
// untranslatable fn-like macro
fn PCRE2_JOIN() -> Never:
    comptime_error("untranslatable C macro: PCRE2_JOIN")
fn PCRE2_SUFFIX[T](a: T) -> T:
    PCRE2_GLUE(a, PCRE2_CODE_UNIT_WIDTH)
// untranslatable fn-like macro
fn PCRE2_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_UNREACHABLE")
// untranslatable fn-like macro
fn PRIV() -> Never:
    comptime_error("untranslatable C macro: PRIV")
// untranslatable fn-like macro
fn PUT() -> Never:
    comptime_error("untranslatable C macro: PUT")
// untranslatable fn-like macro
fn PUT2() -> Never:
    comptime_error("untranslatable C macro: PUT2")
// untranslatable fn-like macro
fn PUT2INC() -> Never:
    comptime_error("untranslatable C macro: PUT2INC")
// untranslatable fn-like macro
fn PUTCHAR() -> Never:
    comptime_error("untranslatable C macro: PUTCHAR")
// untranslatable fn-like macro
fn PUTCHARS() -> Never:
    comptime_error("untranslatable C macro: PUTCHARS")
// untranslatable fn-like macro
fn PUTINC() -> Never:
    comptime_error("untranslatable C macro: PUTINC")
// untranslatable fn-like macro
fn REAL_GET_UCD() -> Never:
    comptime_error("untranslatable C macro: REAL_GET_UCD")
// untranslatable fn-like macro
fn STATIC_ASSERT() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT")
// untranslatable fn-like macro
fn STATIC_ASSERT_JOIN() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT_JOIN")
// untranslatable fn-like macro
fn TABLE_GET() -> Never:
    comptime_error("untranslatable C macro: TABLE_GET")
let TYPE_OPTIONS: c_int = 28
// untranslatable fn-like macro
fn UCD_ANY_I() -> Never:
    comptime_error("untranslatable C macro: UCD_ANY_I")
// untranslatable fn-like macro
fn UCD_BIDICLASS() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS")
// untranslatable fn-like macro
fn UCD_BIDICLASS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS_PROP")
// untranslatable fn-like macro
fn UCD_BPROPS() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS")
// untranslatable fn-like macro
fn UCD_BPROPS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS_PROP")
// untranslatable fn-like macro
fn UCD_CASESET() -> Never:
    comptime_error("untranslatable C macro: UCD_CASESET")
// untranslatable fn-like macro
fn UCD_CATEGORY() -> Never:
    comptime_error("untranslatable C macro: UCD_CATEGORY")
// untranslatable fn-like macro
fn UCD_CHARTYPE() -> Never:
    comptime_error("untranslatable C macro: UCD_CHARTYPE")
fn UCD_DOTTED_I[T](ch: T) -> T:
    (((ch as u32) == 0x69) or ((ch as u32) == 0x0130))
fn UCD_FOLD_I_TURKISH[T](ch: T) -> T:
    (if ((ch as u32) == 0x0130): 0x69 else: (if ((ch as u32) == 0x49): 0x0131 else: (ch as u32)))
// untranslatable fn-like macro
fn UCD_GRAPHBREAK() -> Never:
    comptime_error("untranslatable C macro: UCD_GRAPHBREAK")
// untranslatable fn-like macro
fn UCD_OTHERCASE() -> Never:
    comptime_error("untranslatable C macro: UCD_OTHERCASE")
// untranslatable fn-like macro
fn UCD_SCRIPT() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPT")
// untranslatable fn-like macro
fn UCD_SCRIPTX() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX")
// untranslatable fn-like macro
fn UCD_SCRIPTX_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX_PROP")
fn UINT16_C[T](v: T) -> T:
    v
fn UINT32_C[T](v: T) -> u32:
    (v as u32)
fn UINT64_C[T](v: T) -> u64:
    (v as u64)
fn UINT8_C[T](v: T) -> T:
    v
fn UINTMAX_C[T](v: T) -> u64:
    (v as u64)
// untranslatable fn-like macro
fn WAS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: WAS_NEWLINE")
// untranslatable fn-like macro
fn WCOREDUMP() -> Never:
    comptime_error("untranslatable C macro: WCOREDUMP")
// untranslatable fn-like macro
fn WEXITSTATUS() -> Never:
    comptime_error("untranslatable C macro: WEXITSTATUS")
// untranslatable fn-like macro
fn WIFCONTINUED() -> Never:
    comptime_error("untranslatable C macro: WIFCONTINUED")
// untranslatable fn-like macro
fn WIFEXITED() -> Never:
    comptime_error("untranslatable C macro: WIFEXITED")
// untranslatable fn-like macro
fn WIFSIGNALED() -> Never:
    comptime_error("untranslatable C macro: WIFSIGNALED")
// untranslatable fn-like macro
fn WIFSTOPPED() -> Never:
    comptime_error("untranslatable C macro: WIFSTOPPED")
// untranslatable fn-like macro
fn WSTOPSIG() -> Never:
    comptime_error("untranslatable C macro: WSTOPSIG")
// untranslatable fn-like macro
fn WTERMSIG() -> Never:
    comptime_error("untranslatable C macro: WTERMSIG")
fn W_EXITCODE[T](ret: T, sig: T) -> T:
    ((ret << 8) | sig)
// untranslatable fn-like macro
fn W_STOPCODE() -> Never:
    comptime_error("untranslatable C macro: W_STOPCODE")
// untranslatable fn-like macro
fn alloca() -> Never:
    comptime_error("untranslatable C macro: alloca")
// untranslatable fn-like macro
fn clearerr_unlocked() -> Never:
    comptime_error("untranslatable C macro: clearerr_unlocked")
// untranslatable fn-like macro
fn feof_unlocked() -> Never:
    comptime_error("untranslatable C macro: feof_unlocked")
// untranslatable fn-like macro
fn ferror_unlocked() -> Never:
    comptime_error("untranslatable C macro: ferror_unlocked")
// untranslatable fn-like macro
fn fileno_unlocked() -> Never:
    comptime_error("untranslatable C macro: fileno_unlocked")
// untranslatable fn-like macro
fn fropen() -> Never:
    comptime_error("untranslatable C macro: fropen")
// untranslatable fn-like macro
fn fwopen() -> Never:
    comptime_error("untranslatable C macro: fwopen")
// untranslatable fn-like macro
fn getc_unlocked() -> Never:
    comptime_error("untranslatable C macro: getc_unlocked")
// untranslatable fn-like macro
fn getchar_unlocked() -> Never:
    comptime_error("untranslatable C macro: getchar_unlocked")
// untranslatable fn-like macro
fn htonl() -> Never:
    comptime_error("untranslatable C macro: htonl")
// untranslatable fn-like macro
fn htonll() -> Never:
    comptime_error("untranslatable C macro: htonll")
// untranslatable fn-like macro
fn htons() -> Never:
    comptime_error("untranslatable C macro: htons")
fn memccpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn memcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn memmove() -> Never:
    comptime_error("variadic macro — use direct call")
fn memset() -> Never:
    comptime_error("variadic macro — use direct call")
// untranslatable fn-like macro
fn ntohl() -> Never:
    comptime_error("untranslatable C macro: ntohl")
// untranslatable fn-like macro
fn ntohll() -> Never:
    comptime_error("untranslatable C macro: ntohll")
// untranslatable fn-like macro
fn ntohs() -> Never:
    comptime_error("untranslatable C macro: ntohs")
// untranslatable fn-like macro
fn offsetof() -> Never:
    comptime_error("untranslatable C macro: offsetof")
// untranslatable fn-like macro
fn putc_unlocked() -> Never:
    comptime_error("untranslatable C macro: putc_unlocked")
// untranslatable fn-like macro
fn putchar_unlocked() -> Never:
    comptime_error("untranslatable C macro: putchar_unlocked")
// untranslatable fn-like macro
fn sigmask() -> Never:
    comptime_error("untranslatable C macro: sigmask")
fn snprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn sprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn stpcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn stpncpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strcat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strlcat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strlcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strncat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strncpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn vsnprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn vsprintf() -> Never:
    comptime_error("variadic macro — use direct call")
