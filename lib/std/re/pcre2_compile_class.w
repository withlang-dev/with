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
extern fn pcre2_pattern_convert_8(p0: *const u8, p1: c_ulong, p2: c_uint, p3: *mut *mut u8, p4: *mut c_ulong, p5: *mut pcre2_real_convert_context_8) -> c_int
extern fn pcre2_converted_pattern_free_8(p0: *mut u8) -> void
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
type eclass_op_info { code_start: *mut u8 = null, length: c_ulong = 0, op_single_type: u8 = 0, bits: class_bits_storage }
type struct_eclass_op_info = eclass_op_info
fn _pcre2_update_classbits_8(ptype: c_uint, pdata: c_uint, negated: c_int, __param_classbits: *mut u8):
    var classbits = __param_classbits
    var c: c_int
    var chartype: c_int

    var prop: *const ucd_record

    var gentype: c_uint

    var set_bit: c_int

    if (ptype == 13):
        if (not ((negated != 0))):
            with_memset(classbits as *i8, 255, 32 as i64)
        
        return
        

    (c = 0)
    
    while (c < 256):
        (prop = (((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c) / 128)] * 128) + ((c) % 128))] as isize as usize))))
        
        (set_bit = 0)
        
        set_bit
        
        match ptype
            0 =>
                (chartype = prop.chartype)
                (set_bit = ((if ((chartype == ucp_Lu) or (chartype == ucp_Ll)) or (chartype == ucp_Lt): 1 else: 0)))
            1 =>
                (set_bit = ((if _pcre2_ucp_gentype_8[prop.chartype] == pdata: 1 else: 0)))
            2 =>
                (set_bit = ((if prop.chartype == pdata: 1 else: 0)))
            3 =>
                (set_bit = ((if prop.script == pdata: 1 else: 0)))
            4 =>
                (set_bit = ((if (prop.script == pdata) or ((((((&_pcre2_ucd_script_sets_8[0] as *mut c_uint) + ((((prop).scriptx_bidiclass & 1023)) as isize as usize)))[((pdata) / 32)] & ((1 << (((pdata) % 32)))))) != 0): 1 else: 0)))
            5 =>
                (gentype = _pcre2_ucp_gentype_8[prop.chartype])
                (set_bit = ((if (gentype == 1) or (gentype == 3): 1 else: 0)))
            6 =>
                match c
                    9 =>
                        (set_bit = 1)
                    32 =>
                        (set_bit = 1)
                    160 =>
                        (set_bit = 1)
                    10 =>
                        (set_bit = 1)
                    11 =>
                        (set_bit = 1)
                    12 =>
                        (set_bit = 1)
                    13 =>
                        (set_bit = 1)
                    133 =>
                        (set_bit = 1)
                    _ =>
                        (set_bit = ((if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0)))
            7 =>
                match c
                    9 =>
                        (set_bit = 1)
                    32 =>
                        (set_bit = 1)
                    160 =>
                        (set_bit = 1)
                    10 =>
                        (set_bit = 1)
                    11 =>
                        (set_bit = 1)
                    12 =>
                        (set_bit = 1)
                    13 =>
                        (set_bit = 1)
                    133 =>
                        (set_bit = 1)
                    _ =>
                        (set_bit = ((if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0)))
            8 =>
                (chartype = prop.chartype)
                (gentype = _pcre2_ucp_gentype_8[chartype])
                (set_bit = ((if (((gentype == 1) or (gentype == 3)) or (chartype == ucp_Mn)) or (chartype == ucp_Pc): 1 else: 0)))
            10 =>
                (set_bit = ((if (((c == 36) or (c == 64)) or (c == 96)) or (c >= 160): 1 else: 0)))
            11 =>
                (set_bit = ((if (((prop).scriptx_bidiclass >> 11)) == pdata: 1 else: 0)))
            12 =>
                (set_bit = (if (((((&_pcre2_ucd_boolprop_sets_8[0] as *mut c_uint) + ((((prop).bprops & 4095)) as isize as usize)))[((pdata) / 32)] & ((1 << (((pdata) % 32)))))) != 0: 1 else: 0))
            14 =>
                (chartype = prop.chartype)
                (gentype = _pcre2_ucp_gentype_8[chartype])
                (set_bit = ((if (gentype != 6) and ((gentype != 0) or (chartype == ucp_Cf)): 1 else: 0)))
            15 =>
                (chartype = prop.chartype)
                (set_bit = ((if ((chartype != ucp_Zl) and (chartype != ucp_Zp)) and ((_pcre2_ucp_gentype_8[chartype] != 0) or (chartype == ucp_Cf)): 1 else: 0)))
            16 =>
                (gentype = _pcre2_ucp_gentype_8[prop.chartype])
                (set_bit = ((if (gentype == 4) or ((c < 128) and (gentype == 5)): 1 else: 0)))
            _ =>
                (set_bit = (if (((c >= 48) and (c <= 57)) or ((c >= 65) and (c <= 70))) or ((c >= 97) and (c <= 102)): 1 else: 0))
        
        if (negated != 0):
            (set_bit = (if set_bit != 0: 0 else: 1))
        
        if (set_bit != 0):
            (unsafe: *classbits) = (unsafe: *classbits) | (((1 << ((c & 7)))) as u8)
        
        if (((c & 7)) == 7):
            (classbits = classbits + 1)
        
        
        var __ci_expr_old_0: c_int = c
        (c = c + 1)
        
    


fn _pcre2_compile_class_not_nested_8(options: c_uint, xoptions: c_uint, start_ptr: *mut c_uint, pcode: *mut *mut u8, negate_class: c_int, has_bitmap: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint:
    var pptr__goto_1076_11: *mut c_uint = null
    var code__goto_1077_14: *mut u8 = null
    var should_flip_negation__goto_1078_6: c_int = 0
    var cbits__goto_1079_16: *const u8 = null
    var classbits__goto_1082_16: *mut u8 = null
    var utf__goto_1085_6: c_int = 0
    var xclass_props__goto_1093_10: c_uint = 0
    var class_uchardata__goto_1094_14: *mut u8 = null
    var cranges__goto_1095_15: *mut class_ranges = null
    var ranges__goto_1149_21: *const c_uint = null
    var meta__goto_1174_12: c_uint = 0
    var local_negate__goto_1175_8: c_int = 0
    var posix_class__goto_1176_7: c_int = 0
    var taboffset__goto_1177_7: c_int = 0
    var tabopt__goto_1177_18: c_int = 0
    var pbits__goto_1178_22: class_bits_storage
    var escape__goto_1179_12: c_uint = 0
    var c__goto_1179_20: c_uint = 0
    var ptype__goto_1211_16: c_uint = 0
    var i__goto_1279_18: c_int = 0
    var i__goto_1282_18: c_int = 0
    var classwords__goto_1312_17: *mut c_uint = null
    var i__goto_1315_18: c_int = 0
    var i__goto_1318_18: c_int = 0
    var i__goto_1340_16: c_int = 0
    var i__goto_1345_16: c_int = 0
    var i__goto_1350_16: c_int = 0
    var i__goto_1355_16: c_int = 0
    var i__goto_1367_16: c_int = 0
    var i__goto_1372_16: c_int = 0
    var ptype__goto_1437_18: c_uint = 0
    var pdata__goto_1438_18: c_uint = 0
    var d__goto_1497_14: c_uint = 0
    var range__goto_1581_13: *mut c_uint = null
    var end__goto_1582_13: *mut c_uint = null
    var range_start__goto_1616_16: c_uint = 0
    var range_end__goto_1617_16: c_uint = 0
    var previous__goto_1707_16: *mut u8 = null
    var classwords__goto_1723_17: *mut c_uint = null
    var i__goto_1724_16: c_int = 0
    var char_lists_size__goto_1748_12: c_ulong = 0
    var data__goto_1777_16: *mut u8 = null
    var classwords__goto_1840_13: *mut c_uint = null
    var i__goto_1842_12: c_int = 0
    var classwords__goto_1848_19: *const c_uint = null
    var i__goto_1849_7: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                pptr__goto_1076_11 = start_ptr
                code__goto_1077_14 = (unsafe: *pcode)
                cbits__goto_1079_16 = cb.cbits
                classbits__goto_1082_16 = (&(&cb.classbits.classbits[0] as *mut u8)[0] as *mut u8)
                utf__goto_1085_6 = (if ((options & 524288)) != 0: 1 else: 0)
                (should_flip_negation__goto_1078_6 = 0)
                if __goto_pending != 0:
                    continue
                (xclass_props__goto_1093_10 = 0)
                if __goto_pending != 0:
                    continue
                (cranges__goto_1095_15 = (null as *mut class_ranges))
                if __goto_pending != 0:
                    continue
                if (utf__goto_1085_6 != 0):
                    if (lengthptr != (null as *mut c_ulong)):
                        (cranges__goto_1095_15 = compile_optimize_class(pptr__goto_1076_11, options, xoptions, cb))
                        if __goto_pending != 0:
                            continue
                        if (cranges__goto_1095_15 == (null as *mut class_ranges)):
                            ((unsafe: *errorcodeptr) = ERR21)
                            if __goto_pending != 0:
                                continue
                            return (null as *mut c_uint)
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                        if (cb.last_data != (null as *mut compile_data)):
                            (cb.last_data.next = ((&cranges__goto_1095_15.header as *const compile_data) as *mut compile_data))
                        else:
                            (cb.first_data = ((&cranges__goto_1095_15.header as *const compile_data) as *mut compile_data))
                        if __goto_pending != 0:
                            continue
                        (cb.last_data = ((&cranges__goto_1095_15.header as *const compile_data) as *mut compile_data))
                        if __goto_pending != 0:
                            continue
                    else:
                        (cranges__goto_1095_15 = (cb.first_data as *mut class_ranges))
                        if __goto_pending != 0:
                            continue
                        (cb.first_data = cranges__goto_1095_15.header.next)
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                    if (cranges__goto_1095_15.range_list_size > 0):
                        ranges__goto_1149_21 = (((cranges__goto_1095_15 + (1 as isize as usize))) as *const c_uint)
                        if __goto_pending != 0:
                            continue
                        if (ranges__goto_1149_21[0] <= 255):
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                        if __goto_pending != 0:
                            continue
                        if ((ranges__goto_1149_21[(cranges__goto_1095_15.range_list_size - 1)] == ((if (utf__goto_1085_6 != 0): 1114111 else: 255))) and (ranges__goto_1149_21[(cranges__goto_1095_15.range_list_size - 2)] <= 256)):
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 16)
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                (class_uchardata__goto_1094_14 = ((code__goto_1077_14 + (2 as isize as usize)) + (2 as isize as usize)))
                if __goto_pending != 0:
                    continue
                with_memset((classbits__goto_1082_16 as *mut c_void) as *i8, 0, 32 as i64)
                if __goto_pending != 0:
                    continue
                while (1 != 0):
                    meta__goto_1174_12 = with 0 as __ci_expr_seq_1:
                        var __ci_expr_old_0: *mut c_uint = pptr__goto_1076_11
                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                        (unsafe: *(__ci_expr_old_0))
                    if __goto_pending != 0:
                        break
                    match ((meta__goto_1174_12 & (4294901760 as c_uint)))
                        2149580800 =>
                            (local_negate__goto_1175_8 = ((if meta__goto_1174_12 == 2149646336: 1 else: 0)))
                            var __ci_expr_old_2: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (posix_class__goto_1176_7 = (unsafe: *(__ci_expr_old_2)))
                            if (local_negate__goto_1175_8 != 0):
                                (should_flip_negation__goto_1078_6 = 1)
                            if ((((options & 8)) != 0) and (posix_class__goto_1176_7 <= 2)):
                                (posix_class__goto_1176_7 = 0)
                            if ((((options & 131072)) != 0) and (((xoptions & 2048)) == 0)):
                                match posix_class__goto_1176_7
                                    8 =>
                                        (ptype__goto_1211_16 = (if (posix_class__goto_1176_7 == 8): 14 else: (if (posix_class__goto_1176_7 == 9): 15 else: 16)))
                                        _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)
                                        if (((xclass_props__goto_1093_10 & 16)) == 0):
                                            if (lengthptr != (null as *mut c_ulong)):
                                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                            else:
                                                var __ci_expr_old_3: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_3) = (if (local_negate__goto_1175_8 != 0): 4 else: 3))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_4: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_4) = (ptype__goto_1211_16 as u8))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_5: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_5) = 0)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                            if __goto_pending != 0:
                                                break
                                        continue
                                    9 =>
                                        (ptype__goto_1211_16 = (if (posix_class__goto_1176_7 == 8): 14 else: (if (posix_class__goto_1176_7 == 9): 15 else: 16)))
                                        _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)
                                        if (((xclass_props__goto_1093_10 & 16)) == 0):
                                            if (lengthptr != (null as *mut c_ulong)):
                                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                            else:
                                                var __ci_expr_old_3: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_3) = (if (local_negate__goto_1175_8 != 0): 4 else: 3))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_4: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_4) = (ptype__goto_1211_16 as u8))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_5: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_5) = 0)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                            if __goto_pending != 0:
                                                break
                                        continue
                                    10 =>
                                        (ptype__goto_1211_16 = (if (posix_class__goto_1176_7 == 8): 14 else: (if (posix_class__goto_1176_7 == 9): 15 else: 16)))
                                        _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)
                                        if (((xclass_props__goto_1093_10 & 16)) == 0):
                                            if (lengthptr != (null as *mut c_ulong)):
                                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                            else:
                                                var __ci_expr_old_3: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_3) = (if (local_negate__goto_1175_8 != 0): 4 else: 3))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_4: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_4) = (ptype__goto_1211_16 as u8))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_5: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_5) = 0)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                            if __goto_pending != 0:
                                                break
                                        continue
                                    _ => 0
                                if __goto_pending != 0:
                                    break
                            (posix_class__goto_1176_7 = posix_class__goto_1176_7 * 3)
                            with_memcpy(((&pbits__goto_1178_22.classbits[0] as *mut u8) as *mut c_void) as *i8, ((cbits__goto_1079_16 + (_pcre2_posix_class_maps8[posix_class__goto_1176_7] as isize as usize)) as *const c_void) as *i8, 32 as i64)
                            (taboffset__goto_1177_7 = _pcre2_posix_class_maps8[(posix_class__goto_1176_7 + 1)])
                            (tabopt__goto_1177_18 = _pcre2_posix_class_maps8[(posix_class__goto_1176_7 + 2)])
                            if (taboffset__goto_1177_7 >= 0):
                                if (tabopt__goto_1177_18 >= 0):
                                    i__goto_1279_18 = 0
                                    while (i__goto_1279_18 < 32):
                                        ((&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1279_18] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1279_18] | cbits__goto_1079_16[(i__goto_1279_18 + taboffset__goto_1177_7)])
                                        var __ci_expr_old_6: c_int = i__goto_1279_18
                                    (i__goto_1279_18 = i__goto_1279_18 + 1)
                                        if __goto_pending != 0:
                                            break
                                else:
                                    i__goto_1282_18 = 0
                                    while (i__goto_1282_18 < 32):
                                        ((&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1282_18] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1282_18] & (((0 - cbits__goto_1079_16[(i__goto_1282_18 + taboffset__goto_1177_7)] - 1)) as u8))
                                        var __ci_expr_old_7: c_int = i__goto_1282_18
                                    (i__goto_1282_18 = i__goto_1282_18 + 1)
                                        if __goto_pending != 0:
                                            break
                                if __goto_pending != 0:
                                    break
                            if (tabopt__goto_1177_18 < 0):
                                (tabopt__goto_1177_18 = (0 - tabopt__goto_1177_18))
                            if (tabopt__goto_1177_18 == 1):
                                ((&pbits__goto_1178_22.classbits[0] as *mut u8)[1] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[1] & (0 - 60 - 1))
                            else:
                                if (tabopt__goto_1177_18 == 2):
                                    ((&pbits__goto_1178_22.classbits[0] as *mut u8)[11] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[11] & 127)
                            classwords__goto_1312_17 = (&(&cb.classbits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                            if __goto_pending != 0:
                                break
                            if (local_negate__goto_1175_8 != 0):
                                i__goto_1315_18 = 0
                                while (i__goto_1315_18 < 8):
                                    (classwords__goto_1312_17[i__goto_1315_18] = classwords__goto_1312_17[i__goto_1315_18] | ((0 - (&pbits__goto_1178_22.classwords[0] as *mut c_uint)[i__goto_1315_18] - 1)))
                                    var __ci_expr_old_8: c_int = i__goto_1315_18
                                (i__goto_1315_18 = i__goto_1315_18 + 1)
                                    if __goto_pending != 0:
                                        break
                            else:
                                i__goto_1318_18 = 0
                                while (i__goto_1318_18 < 8):
                                    (classwords__goto_1312_17[i__goto_1318_18] = classwords__goto_1312_17[i__goto_1318_18] | (&pbits__goto_1178_22.classwords[0] as *mut c_uint)[i__goto_1318_18])
                                    var __ci_expr_old_9: c_int = i__goto_1318_18
                                (i__goto_1318_18 = i__goto_1318_18 + 1)
                                    if __goto_pending != 0:
                                        break
                            if __goto_pending != 0:
                                break
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                            continue
                            var __ci_expr_old_10: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (meta__goto_1174_12 = (unsafe: *(__ci_expr_old_10)))
                        2149646336 =>
                            (local_negate__goto_1175_8 = ((if meta__goto_1174_12 == 2149646336: 1 else: 0)))
                            var __ci_expr_old_2: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (posix_class__goto_1176_7 = (unsafe: *(__ci_expr_old_2)))
                            if (local_negate__goto_1175_8 != 0):
                                (should_flip_negation__goto_1078_6 = 1)
                            if ((((options & 8)) != 0) and (posix_class__goto_1176_7 <= 2)):
                                (posix_class__goto_1176_7 = 0)
                            if ((((options & 131072)) != 0) and (((xoptions & 2048)) == 0)):
                                match posix_class__goto_1176_7
                                    8 =>
                                        (ptype__goto_1211_16 = (if (posix_class__goto_1176_7 == 8): 14 else: (if (posix_class__goto_1176_7 == 9): 15 else: 16)))
                                        _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)
                                        if (((xclass_props__goto_1093_10 & 16)) == 0):
                                            if (lengthptr != (null as *mut c_ulong)):
                                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                            else:
                                                var __ci_expr_old_3: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_3) = (if (local_negate__goto_1175_8 != 0): 4 else: 3))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_4: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_4) = (ptype__goto_1211_16 as u8))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_5: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_5) = 0)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                            if __goto_pending != 0:
                                                break
                                        continue
                                    9 =>
                                        (ptype__goto_1211_16 = (if (posix_class__goto_1176_7 == 8): 14 else: (if (posix_class__goto_1176_7 == 9): 15 else: 16)))
                                        _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)
                                        if (((xclass_props__goto_1093_10 & 16)) == 0):
                                            if (lengthptr != (null as *mut c_ulong)):
                                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                            else:
                                                var __ci_expr_old_3: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_3) = (if (local_negate__goto_1175_8 != 0): 4 else: 3))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_4: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_4) = (ptype__goto_1211_16 as u8))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_5: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_5) = 0)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                            if __goto_pending != 0:
                                                break
                                        continue
                                    10 =>
                                        (ptype__goto_1211_16 = (if (posix_class__goto_1176_7 == 8): 14 else: (if (posix_class__goto_1176_7 == 9): 15 else: 16)))
                                        _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)
                                        if (((xclass_props__goto_1093_10 & 16)) == 0):
                                            if (lengthptr != (null as *mut c_ulong)):
                                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                            else:
                                                var __ci_expr_old_3: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_3) = (if (local_negate__goto_1175_8 != 0): 4 else: 3))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_4: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_4) = (ptype__goto_1211_16 as u8))
                                                if __goto_pending != 0:
                                                    break
                                                var __ci_expr_old_5: *mut u8 = class_uchardata__goto_1094_14
                                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                                ((unsafe: *__ci_expr_old_5) = 0)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                            if __goto_pending != 0:
                                                break
                                        continue
                                    _ => 0
                                if __goto_pending != 0:
                                    break
                            (posix_class__goto_1176_7 = posix_class__goto_1176_7 * 3)
                            with_memcpy(((&pbits__goto_1178_22.classbits[0] as *mut u8) as *mut c_void) as *i8, ((cbits__goto_1079_16 + (_pcre2_posix_class_maps8[posix_class__goto_1176_7] as isize as usize)) as *const c_void) as *i8, 32 as i64)
                            (taboffset__goto_1177_7 = _pcre2_posix_class_maps8[(posix_class__goto_1176_7 + 1)])
                            (tabopt__goto_1177_18 = _pcre2_posix_class_maps8[(posix_class__goto_1176_7 + 2)])
                            if (taboffset__goto_1177_7 >= 0):
                                if (tabopt__goto_1177_18 >= 0):
                                    i__goto_1279_18 = 0
                                    while (i__goto_1279_18 < 32):
                                        ((&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1279_18] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1279_18] | cbits__goto_1079_16[(i__goto_1279_18 + taboffset__goto_1177_7)])
                                        var __ci_expr_old_6: c_int = i__goto_1279_18
                                    (i__goto_1279_18 = i__goto_1279_18 + 1)
                                        if __goto_pending != 0:
                                            break
                                else:
                                    i__goto_1282_18 = 0
                                    while (i__goto_1282_18 < 32):
                                        ((&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1282_18] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[i__goto_1282_18] & (((0 - cbits__goto_1079_16[(i__goto_1282_18 + taboffset__goto_1177_7)] - 1)) as u8))
                                        var __ci_expr_old_7: c_int = i__goto_1282_18
                                    (i__goto_1282_18 = i__goto_1282_18 + 1)
                                        if __goto_pending != 0:
                                            break
                                if __goto_pending != 0:
                                    break
                            if (tabopt__goto_1177_18 < 0):
                                (tabopt__goto_1177_18 = (0 - tabopt__goto_1177_18))
                            if (tabopt__goto_1177_18 == 1):
                                ((&pbits__goto_1178_22.classbits[0] as *mut u8)[1] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[1] & (0 - 60 - 1))
                            else:
                                if (tabopt__goto_1177_18 == 2):
                                    ((&pbits__goto_1178_22.classbits[0] as *mut u8)[11] = (&pbits__goto_1178_22.classbits[0] as *mut u8)[11] & 127)
                            classwords__goto_1312_17 = (&(&cb.classbits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                            if __goto_pending != 0:
                                break
                            if (local_negate__goto_1175_8 != 0):
                                i__goto_1315_18 = 0
                                while (i__goto_1315_18 < 8):
                                    (classwords__goto_1312_17[i__goto_1315_18] = classwords__goto_1312_17[i__goto_1315_18] | ((0 - (&pbits__goto_1178_22.classwords[0] as *mut c_uint)[i__goto_1315_18] - 1)))
                                    var __ci_expr_old_8: c_int = i__goto_1315_18
                                (i__goto_1315_18 = i__goto_1315_18 + 1)
                                    if __goto_pending != 0:
                                        break
                            else:
                                i__goto_1318_18 = 0
                                while (i__goto_1318_18 < 8):
                                    (classwords__goto_1312_17[i__goto_1318_18] = classwords__goto_1312_17[i__goto_1318_18] | (&pbits__goto_1178_22.classwords[0] as *mut c_uint)[i__goto_1318_18])
                                    var __ci_expr_old_9: c_int = i__goto_1318_18
                                (i__goto_1318_18 = i__goto_1318_18 + 1)
                                    if __goto_pending != 0:
                                        break
                            if __goto_pending != 0:
                                break
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                            continue
                            var __ci_expr_old_10: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (meta__goto_1174_12 = (unsafe: *(__ci_expr_old_10)))
                        2147811328 =>
                            var __ci_expr_old_10: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (meta__goto_1174_12 = (unsafe: *(__ci_expr_old_10)))
                        2149318656 =>
                            (escape__goto_1179_12 = ((meta__goto_1174_12 & 65535)))
                            match escape__goto_1179_12
                                7 =>
                                    i__goto_1340_16 = 0
                                    while (i__goto_1340_16 < 32):
                                        (classbits__goto_1082_16[i__goto_1340_16] = classbits__goto_1082_16[i__goto_1340_16] | cbits__goto_1079_16[(i__goto_1340_16 + 64)])
                                        var __ci_expr_old_11: c_int = i__goto_1340_16
                                    (i__goto_1340_16 = i__goto_1340_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                6 =>
                                    (should_flip_negation__goto_1078_6 = 1)
                                    i__goto_1345_16 = 0
                                    while (i__goto_1345_16 < 32):
                                        (classbits__goto_1082_16[i__goto_1345_16] = classbits__goto_1082_16[i__goto_1345_16] | (((0 - cbits__goto_1079_16[(i__goto_1345_16 + 64)] - 1)) as u8))
                                        var __ci_expr_old_12: c_int = i__goto_1345_16
                                    (i__goto_1345_16 = i__goto_1345_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                11 =>
                                    i__goto_1350_16 = 0
                                    while (i__goto_1350_16 < 32):
                                        (classbits__goto_1082_16[i__goto_1350_16] = classbits__goto_1082_16[i__goto_1350_16] | cbits__goto_1079_16[(i__goto_1350_16 + 160)])
                                        var __ci_expr_old_13: c_int = i__goto_1350_16
                                    (i__goto_1350_16 = i__goto_1350_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                10 =>
                                    (should_flip_negation__goto_1078_6 = 1)
                                    i__goto_1355_16 = 0
                                    while (i__goto_1355_16 < 32):
                                        (classbits__goto_1082_16[i__goto_1355_16] = classbits__goto_1082_16[i__goto_1355_16] | (((0 - cbits__goto_1079_16[(i__goto_1355_16 + 160)] - 1)) as u8))
                                        var __ci_expr_old_14: c_int = i__goto_1355_16
                                    (i__goto_1355_16 = i__goto_1355_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                9 =>
                                    i__goto_1367_16 = 0
                                    while (i__goto_1367_16 < 32):
                                        (classbits__goto_1082_16[i__goto_1367_16] = classbits__goto_1082_16[i__goto_1367_16] | cbits__goto_1079_16[(i__goto_1367_16 + 0)])
                                        var __ci_expr_old_15: c_int = i__goto_1367_16
                                    (i__goto_1367_16 = i__goto_1367_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                8 =>
                                    (should_flip_negation__goto_1078_6 = 1)
                                    i__goto_1372_16 = 0
                                    while (i__goto_1372_16 < 32):
                                        (classbits__goto_1082_16[i__goto_1372_16] = classbits__goto_1082_16[i__goto_1372_16] | (((0 - cbits__goto_1079_16[(i__goto_1372_16 + 0)] - 1)) as u8))
                                        var __ci_expr_old_16: c_int = i__goto_1372_16
                                    (i__goto_1372_16 = i__goto_1372_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                19 =>
                                    if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                                        break
                                    add_list_to_class((options & (0 - 8 - 1)), xoptions, cb, (&_pcre2_hspace_list_8[0] as *mut c_uint))
                                18 =>
                                    if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                                        break
                                    add_not_list_to_class((options & (0 - 8 - 1)), xoptions, cb, (&_pcre2_hspace_list_8[0] as *mut c_uint))
                                21 =>
                                    if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                                        break
                                    add_list_to_class((options & (0 - 8 - 1)), xoptions, cb, (&_pcre2_vspace_list_8[0] as *mut c_uint))
                                20 =>
                                    if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                                        break
                                    add_not_list_to_class((options & (0 - 8 - 1)), xoptions, cb, (&_pcre2_vspace_list_8[0] as *mut c_uint))
                                16 =>
                                    ptype__goto_1437_18 = ((unsafe: *pptr__goto_1076_11) >> 16)
                                    if __goto_pending != 0:
                                        break
                                    pdata__goto_1438_18 = with 0 as __ci_expr_seq_18:
                                        var __ci_expr_old_17: *mut c_uint = pptr__goto_1076_11
                                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                                        ((unsafe: *(__ci_expr_old_17)) & 65535)
                                    if __goto_pending != 0:
                                        break
                                    if (ptype__goto_1437_18 == 13):
                                        if ((not ((utf__goto_1085_6 != 0))) and (escape__goto_1179_12 == 16)):
                                            with_memset((classbits__goto_1082_16 as *mut c_void) as *i8, 255, 32 as i64)
                                        if __goto_pending != 0:
                                            break
                                        continue
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    _pcre2_update_classbits_8(ptype__goto_1437_18, pdata__goto_1438_18, ((if escape__goto_1179_12 == 15: 1 else: 0)), classbits__goto_1082_16)
                                    if __goto_pending != 0:
                                        break
                                    if (((xclass_props__goto_1093_10 & 16)) == 0):
                                        if (lengthptr != (null as *mut c_ulong)):
                                            ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                        else:
                                            var __ci_expr_old_19: *mut u8 = class_uchardata__goto_1094_14
                                            (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                            ((unsafe: *__ci_expr_old_19) = (if (escape__goto_1179_12 == 16): 3 else: 4))
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_20: *mut u8 = class_uchardata__goto_1094_14
                                            (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                            ((unsafe: *__ci_expr_old_20) = ptype__goto_1437_18)
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_21: *mut u8 = class_uchardata__goto_1094_14
                                            (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                            ((unsafe: *__ci_expr_old_21) = pdata__goto_1438_18)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    continue
                                15 =>
                                    ptype__goto_1437_18 = ((unsafe: *pptr__goto_1076_11) >> 16)
                                    if __goto_pending != 0:
                                        break
                                    pdata__goto_1438_18 = with 0 as __ci_expr_seq_18:
                                        var __ci_expr_old_17: *mut c_uint = pptr__goto_1076_11
                                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                                        ((unsafe: *(__ci_expr_old_17)) & 65535)
                                    if __goto_pending != 0:
                                        break
                                    if (ptype__goto_1437_18 == 13):
                                        if ((not ((utf__goto_1085_6 != 0))) and (escape__goto_1179_12 == 16)):
                                            with_memset((classbits__goto_1082_16 as *mut c_void) as *i8, 255, 32 as i64)
                                        if __goto_pending != 0:
                                            break
                                        continue
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    _pcre2_update_classbits_8(ptype__goto_1437_18, pdata__goto_1438_18, ((if escape__goto_1179_12 == 15: 1 else: 0)), classbits__goto_1082_16)
                                    if __goto_pending != 0:
                                        break
                                    if (((xclass_props__goto_1093_10 & 16)) == 0):
                                        if (lengthptr != (null as *mut c_ulong)):
                                            ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                        else:
                                            var __ci_expr_old_19: *mut u8 = class_uchardata__goto_1094_14
                                            (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                            ((unsafe: *__ci_expr_old_19) = (if (escape__goto_1179_12 == 16): 3 else: 4))
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_20: *mut u8 = class_uchardata__goto_1094_14
                                            (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                            ((unsafe: *__ci_expr_old_20) = ptype__goto_1437_18)
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_21: *mut u8 = class_uchardata__goto_1094_14
                                            (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                            ((unsafe: *__ci_expr_old_21) = pdata__goto_1438_18)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    continue
                                _ => 0
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                            continue
                            if (meta__goto_1174_12 < 2147483648):
                                break
                            __pc = 1
                            __goto_pending = 1
                        _ =>
                            if (meta__goto_1174_12 < 2147483648):
                                break
                            __pc = 1
                            __goto_pending = 1
                    if __goto_pending != 0:
                        break
                    (c__goto_1179_20 = meta__goto_1174_12)
                    if __goto_pending != 0:
                        break
                    if ((c__goto_1179_20 == 13) or (c__goto_1179_20 == 10)):
                        (cb.external_flags = cb.external_flags | 2048)
                    if __goto_pending != 0:
                        break
                    if (((unsafe: *pptr__goto_1076_11) == 2149777408) or ((unsafe: *pptr__goto_1076_11) == 2149711872)):
                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                        if __goto_pending != 0:
                            break
                        var __ci_expr_old_22: *mut c_uint = pptr__goto_1076_11
                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                        (d__goto_1497_14 = (unsafe: *(__ci_expr_old_22)))
                        if __goto_pending != 0:
                            break
                        if (d__goto_1497_14 == 2147811328):
                            var __ci_expr_old_23: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (d__goto_1497_14 = (unsafe: *(__ci_expr_old_23)))
                        if __goto_pending != 0:
                            break
                        if ((d__goto_1497_14 == 13) or (d__goto_1497_14 == 10)):
                            (cb.external_flags = cb.external_flags | 2048)
                        if __goto_pending != 0:
                            break
                        if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                            continue
                        if __goto_pending != 0:
                            break
                        (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                        if __goto_pending != 0:
                            break
                        add_to_class(options, xoptions, cb, c__goto_1179_20, d__goto_1497_14)
                        if __goto_pending != 0:
                            break
                        continue
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                        continue
                    if __goto_pending != 0:
                        break
                    (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                    if __goto_pending != 0:
                        break
                    add_to_class(options, xoptions, cb, meta__goto_1174_12, meta__goto_1174_12)
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // END_PROCESSING
                (__goto_pending = 0)
                if (cranges__goto_1095_15 != (null as *mut class_ranges)):
                    range__goto_1581_13 = (((cranges__goto_1095_15 + (1 as isize as usize))) as *mut c_uint)
                    if __goto_pending != 0:
                        continue
                    end__goto_1582_13 = (range__goto_1581_13 + (cranges__goto_1095_15.range_list_size as isize as usize))
                    if __goto_pending != 0:
                        continue
                    while ((range__goto_1581_13 < end__goto_1582_13) and (range__goto_1581_13[0] < 256)):
                        add_to_class((if (((options & ((524288 | 131072)))) != 0): ((options & (0 - 8 - 1))) else: options), xoptions, cb, range__goto_1581_13[0], range__goto_1581_13[1])
                        if __goto_pending != 0:
                            break
                        if (range__goto_1581_13[1] > 255):
                            break
                        if __goto_pending != 0:
                            break
                        (range__goto_1581_13 = range__goto_1581_13 + 2)
                        if __goto_pending != 0:
                            break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        continue
                    if (cranges__goto_1095_15.char_lists_size > 0):
                        (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 9)
                        if __goto_pending != 0:
                            continue
                    else:
                        if (((xclass_props__goto_1093_10 & 16)) != 0):
                            (should_flip_negation__goto_1078_6 = 1)
                            if __goto_pending != 0:
                                continue
                            (range__goto_1581_13 = end__goto_1582_13)
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                        while (range__goto_1581_13 < end__goto_1582_13):
                            range_start__goto_1616_16 = range__goto_1581_13[0]
                            if __goto_pending != 0:
                                break
                            range_end__goto_1617_16 = range__goto_1581_13[1]
                            if __goto_pending != 0:
                                break
                            (range__goto_1581_13 = range__goto_1581_13 + 2)
                            if __goto_pending != 0:
                                break
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 1)
                            if __goto_pending != 0:
                                break
                            if (range_start__goto_1616_16 < 256):
                                (range_start__goto_1616_16 = 256)
                            if __goto_pending != 0:
                                break
                            if (lengthptr != (null as *mut c_ulong)):
                                if (utf__goto_1085_6 != 0):
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 1)
                                    if __goto_pending != 0:
                                        break
                                    if (range_start__goto_1616_16 < range_end__goto_1617_16):
                                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + _pcre2_ord2utf_8(range_start__goto_1616_16, class_uchardata__goto_1094_14))
                                    if __goto_pending != 0:
                                        break
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + _pcre2_ord2utf_8(range_end__goto_1617_16, class_uchardata__goto_1094_14))
                                    if __goto_pending != 0:
                                        break
                                    continue
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + (if (range_start__goto_1616_16 < range_end__goto_1617_16): 3 else: 2))
                                if __goto_pending != 0:
                                    break
                                continue
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if (utf__goto_1085_6 != 0):
                                if (range_start__goto_1616_16 < range_end__goto_1617_16):
                                    var __ci_expr_old_24: *mut u8 = class_uchardata__goto_1094_14
                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                    ((unsafe: *__ci_expr_old_24) = 2)
                                    if __goto_pending != 0:
                                        break
                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + _pcre2_ord2utf_8(range_start__goto_1616_16, class_uchardata__goto_1094_14))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    var __ci_expr_old_25: *mut u8 = class_uchardata__goto_1094_14
                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                    ((unsafe: *__ci_expr_old_25) = 1)
                                if __goto_pending != 0:
                                    break
                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + _pcre2_ord2utf_8(range_end__goto_1617_16, class_uchardata__goto_1094_14))
                                if __goto_pending != 0:
                                    break
                                continue
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            continue
                        if (lengthptr == (null as *mut c_ulong)):
                            cb.cx.memctl.free((cranges__goto_1095_15 as *mut c_void), cb.cx.memctl.memory_data)
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (((xclass_props__goto_1093_10 & 1)) != 0):
                    previous__goto_1707_16 = code__goto_1077_14
                    if __goto_pending != 0:
                        continue
                    if (((xclass_props__goto_1093_10 & 8)) == 0):
                        var __ci_expr_old_26: *mut u8 = class_uchardata__goto_1094_14
                        (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                        ((unsafe: *__ci_expr_old_26) = 0)
                    if __goto_pending != 0:
                        continue
                    var __ci_expr_old_27: *mut u8 = code__goto_1077_14
                    (code__goto_1077_14 = code__goto_1077_14 + 1)
                    ((unsafe: *__ci_expr_old_27) = 112)
                    if __goto_pending != 0:
                        continue
                    (code__goto_1077_14 = code__goto_1077_14 + 2)
                    if __goto_pending != 0:
                        continue
                    ((unsafe: *code__goto_1077_14) = (if (negate_class != 0): 1 else: 0))
                    if __goto_pending != 0:
                        continue
                    if (((xclass_props__goto_1093_10 & 4)) != 0):
                        ((unsafe: *code__goto_1077_14) = (unsafe: *code__goto_1077_14) | 4)
                    if __goto_pending != 0:
                        continue
                    if ((((xclass_props__goto_1093_10 & 2)) != 0) or (has_bitmap != (null as *mut c_int))):
                        if (negate_class != 0):
                            classwords__goto_1723_17 = (&(&cb.classbits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                            if __goto_pending != 0:
                                continue
                            i__goto_1724_16 = 0
                            while (i__goto_1724_16 < 8):
                                (classwords__goto_1723_17[i__goto_1724_16] = (0 - classwords__goto_1723_17[i__goto_1724_16] - 1))
                                var __ci_expr_old_28: c_int = i__goto_1724_16
                            (i__goto_1724_16 = i__goto_1724_16 + 1)
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                        if (has_bitmap == (null as *mut c_int)):
                            var __ci_expr_old_29: *mut u8 = code__goto_1077_14
                            (code__goto_1077_14 = code__goto_1077_14 + 1)
                            ((unsafe: *__ci_expr_old_29) = (unsafe: *__ci_expr_old_29) | 2)
                            if __goto_pending != 0:
                                continue
                            with_memcpy((code__goto_1077_14 as *mut c_void) as *i8, (classbits__goto_1082_16 as *const c_void) as *i8, 32 as i64)
                            if __goto_pending != 0:
                                continue
                            (code__goto_1077_14 = (class_uchardata__goto_1094_14 + ((32 / sizeof[u8]()))))
                            if __goto_pending != 0:
                                continue
                        else:
                            (code__goto_1077_14 = class_uchardata__goto_1094_14)
                            if __goto_pending != 0:
                                continue
                            if (((xclass_props__goto_1093_10 & 2)) != 0):
                                ((unsafe: *has_bitmap) = 1)
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                    else:
                        (code__goto_1077_14 = class_uchardata__goto_1094_14)
                    if __goto_pending != 0:
                        continue
                    if (((xclass_props__goto_1093_10 & 8)) != 0):
                        char_lists_size__goto_1748_12 = cranges__goto_1095_15.char_lists_size
                        if __goto_pending != 0:
                            continue
                        if (lengthptr != (null as *mut c_ulong)):
                            ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 4)
                            if __goto_pending != 0:
                                continue
                            (cb.char_lists_size = cb.char_lists_size + char_lists_size__goto_1748_12)
                            if __goto_pending != 0:
                                continue
                            (char_lists_size__goto_1748_12 = char_lists_size__goto_1748_12 / sizeof[u8]())
                            if __goto_pending != 0:
                                continue
                            if (((unsafe: *lengthptr) > 65536) or ((65536 -% (unsafe: *lengthptr)) < char_lists_size__goto_1748_12)):
                                ((unsafe: *errorcodeptr) = ERR20)
                                if __goto_pending != 0:
                                    continue
                                return (null as *mut c_uint)
                                if __goto_pending != 0:
                                    continue
                            if __goto_pending != 0:
                                continue
                        else:
                            (code__goto_1077_14[1] = (cranges__goto_1095_15.char_lists_types as u8))
                            if __goto_pending != 0:
                                continue
                            (code__goto_1077_14 = code__goto_1077_14 + 2)
                            if __goto_pending != 0:
                                continue
                            (cb.char_lists_size = cb.char_lists_size + char_lists_size__goto_1748_12)
                            if __goto_pending != 0:
                                continue
                            (data__goto_1777_16 = (cb.start_code - cb.char_lists_size))
                            if __goto_pending != 0:
                                continue
                            with_memcpy((data__goto_1777_16 as *mut c_void) as *i8, (((((cranges__goto_1095_15 + (1 as isize as usize))) as *mut u8) + cranges__goto_1095_15.char_lists_start) as *const c_void) as *i8, char_lists_size__goto_1748_12 as i64)
                            if __goto_pending != 0:
                                continue
                            (char_lists_size__goto_1748_12 = cb.char_lists_size)
                            if __goto_pending != 0:
                                continue
                            (code__goto_1077_14[0] = (((((((char_lists_size__goto_1748_12 >> 1)) as c_uint)) >> 8)) as u8))
                            (code__goto_1077_14[((0) + 1)] = (((((((char_lists_size__goto_1748_12 >> 1)) as c_uint)) & 255)) as u8))
                            if __goto_pending != 0:
                                continue
                            (code__goto_1077_14 = code__goto_1077_14 + 2)
                            if __goto_pending != 0:
                                continue
                            if (((char_lists_size__goto_1748_12 & 2)) != 0):
                                (((data__goto_1777_16 as *mut c_ushort))[-1] = 57005)
                            if __goto_pending != 0:
                                continue
                            cb.cx.memctl.free((cranges__goto_1095_15 as *mut c_void), cb.cx.memctl.memory_data)
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                    (previous__goto_1707_16[1] = ((((((((code__goto_1077_14 as usize -% previous__goto_1707_16 as usize) / sizeof[u8]())) as c_int)) >> 8)) as u8))
                    (previous__goto_1707_16[((1) + 1)] = ((((((((code__goto_1077_14 as usize -% previous__goto_1707_16 as usize) / sizeof[u8]())) as c_int)) & 255)) as u8))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (negate_class != 0):
                    classwords__goto_1840_13 = (&(&cb.classbits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                    if __goto_pending != 0:
                        continue
                    i__goto_1842_12 = 0
                    while (i__goto_1842_12 < 8):
                        (classwords__goto_1840_13[i__goto_1842_12] = (0 - classwords__goto_1840_13[i__goto_1842_12] - 1))
                        var __ci_expr_old_30: c_int = i__goto_1842_12
                    (i__goto_1842_12 = i__goto_1842_12 + 1)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (((not ((utf__goto_1085_6 != 0))) or (negate_class != should_flip_negation__goto_1078_6)) and ((&cb.classbits.classwords[0] as *mut c_uint)[0] == (0 - (0 as c_uint) - 1))):
                    classwords__goto_1848_19 = (&((&cb.classbits.classwords[0] as *mut c_uint) as *const c_uint)[0] as *const c_uint)
                    if __goto_pending != 0:
                        continue
                    (i__goto_1849_7 = 0)
                    while (i__goto_1849_7 < 8):
                        if (classwords__goto_1848_19[i__goto_1849_7] != (0 - (0 as c_uint) - 1)):
                            break
                        var __ci_expr_old_31: c_int = i__goto_1849_7
                    (i__goto_1849_7 = i__goto_1849_7 + 1)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        continue
                    if (i__goto_1849_7 == 8):
                        var __ci_expr_old_32: *mut u8 = code__goto_1077_14
                        (code__goto_1077_14 = code__goto_1077_14 + 1)
                        ((unsafe: *__ci_expr_old_32) = 13)
                        if __goto_pending != 0:
                            continue
                        __pc = 2
                        __goto_pending = 1
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                var __ci_expr_old_33: *mut u8 = code__goto_1077_14
                (code__goto_1077_14 = code__goto_1077_14 + 1)
                ((unsafe: *__ci_expr_old_33) = (if (negate_class == should_flip_negation__goto_1078_6): OP_CLASS else: OP_NCLASS))
                if __goto_pending != 0:
                    continue
                with_memcpy((code__goto_1077_14 as *mut c_void) as *i8, (classbits__goto_1082_16 as *const c_void) as *i8, 32 as i64)
                if __goto_pending != 0:
                    continue
                (code__goto_1077_14 = code__goto_1077_14 + (32 / sizeof[u8]()))
                if __goto_pending != 0:
                    continue
                __pc = 2
                continue
            2 =>  // DONE
                (__goto_pending = 0)
                ((unsafe: *pcode) = code__goto_1077_14)
                if __goto_pending != 0:
                    continue
                return (pptr__goto_1076_11 - (1 as isize as usize))
                if __goto_pending != 0:
                    continue
            _ => break

fn _pcre2_compile_class_nested_8(options: c_uint, xoptions: c_uint, pptr: *mut *mut c_uint, pcode: *mut *mut u8, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int:
    var context: eclass_context

    var op_info: eclass_op_info

    var previous_length: c_ulong = (if (lengthptr != null): (unsafe: *lengthptr) else: 0)

    var code: *mut u8 = (unsafe: *pcode)

    var previous: *mut u8

    var allbitsone: c_int = 1

    (context.needs_bitmap = 0)

    (context.options = options)

    (context.xoptions = xoptions)

    (context.errorcodeptr = errorcodeptr)

    (context.cb = cb)

    (previous = code)

    var __ci_expr_old_0: *mut u8 = code
    (code = code + 1)
    ((unsafe: *__ci_expr_old_0) = 113)

    code = code + 2

    var __ci_expr_old_1: *mut u8 = code
    (code = code + 1)
    ((unsafe: *__ci_expr_old_1) = 0)

    if (not ((compile_eclass_nested((&mut context as *mut eclass_context), 0, pptr, (&mut code as *mut *mut u8), (&mut op_info as *mut eclass_op_info), lengthptr) != 0))):
        return 0

    if (lengthptr != null):
        (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code as usize -% previous as usize) / sizeof[u8]())
        
        (code = previous)
        

    var i: c_int = 0
    
    while (i < 8):
        if (op_info.bits.classwords[i] != 4294967295):
            (allbitsone = 0)
            
            break
            
        
        var __ci_expr_old_2: c_int = i
        (i = i + 1)
        
    

    if (op_info.op_single_type != 0):
        (code = previous)
        
        if ((op_info.op_single_type == 6) and (allbitsone != 0)):
            if (lengthptr != null):
                (unsafe: *lengthptr) = (unsafe: *lengthptr) - 1
            
            var __ci_expr_old_3: *mut u8 = code
            (code = code + 1)
            ((unsafe: *__ci_expr_old_3) = 13)
            
        else:
            if ((op_info.op_single_type == 6) or (op_info.op_single_type == 7)):
                var required_len: c_ulong = (1 +% ((32 / sizeof[u8]())))
                
                if (lengthptr != null):
                    if (required_len > (((unsafe: *lengthptr) -% previous_length))):
                        ((unsafe: *lengthptr) = (previous_length +% required_len))
                    
                
                if (lengthptr != null):
                    (unsafe: *lengthptr) = (unsafe: *lengthptr) - required_len
                
                var __ci_expr_old_4: *mut u8 = code
                (code = code + 1)
                ((unsafe: *__ci_expr_old_4) = (if (op_info.op_single_type == 6): OP_NCLASS else: OP_CLASS))
                
                with_memcpy(code as *i8, op_info.bits.classbits as *i8, 32 as i64)
                
                code = code + (32 / sizeof[u8]())
                
            else:
                var need_map: c_int = context.needs_bitmap
                
                var required_len_1: c_ulong
                
                while true:
                    
                    if not ((0 != 0)):
                        break
                    
                
                (required_len_1 = (op_info.length +% ((if (need_map != 0): (32 / sizeof[u8]()) else: 0))))
                
                if (lengthptr != null):
                    if (required_len_1 > (((unsafe: *lengthptr) -% previous_length))):
                        ((unsafe: *lengthptr) = (previous_length +% required_len_1))
                    
                    (unsafe: *lengthptr) = (unsafe: *lengthptr) - ((1 + 2) + 1)
                    
                    var __ci_expr_old_5: *mut u8 = code
                    (code = code + 1)
                    ((unsafe: *__ci_expr_old_5) = 112)
                    
                    (code[0] = ((((((1 + 2) + 1)) >> 8)) as u8))
                    (code[((0) + 1)] = ((((((1 + 2) + 1)) & 255)) as u8))
                    
                    code = code + 2
                    
                    var __ci_expr_old_6: *mut u8 = code
                    (code = code + 1)
                    ((unsafe: *__ci_expr_old_6) = 0)
                    
                else:
                    var rest: *mut u8
                    
                    var rest_len: c_ulong
                    
                    var flags: u8
                    
                    while true:
                        
                        if not ((0 != 0)):
                            break
                        
                    
                    (rest = (((op_info.code_start + (1 as isize as usize)) + (2 as isize as usize)) + (1 as isize as usize)))
                    
                    (rest_len = ((((op_info.code_start + op_info.length)) as usize -% rest as usize) / sizeof[u8]()))
                    
                    (flags = op_info.code_start[(1 + 2)])
                    
                    while true:
                        
                        if not ((0 != 0)):
                            break
                        
                    
                    var __ci_expr_old_7: *mut u8 = code
                    (code = code + 1)
                    ((unsafe: *__ci_expr_old_7) = 112)
                    
                    (code[0] = (((((required_len_1 as c_int)) >> 8)) as u8))
                    (code[((0) + 1)] = (((((required_len_1 as c_int)) & 255)) as u8))
                    
                    code = code + 2
                    
                    var __ci_expr_old_8: *mut u8 = code
                    (code = code + 1)
                    ((unsafe: *__ci_expr_old_8) = (flags | ((if (need_map != 0): 2 else: 0))))
                    
                    if (need_map != 0):
                        with_memcpy(code as *i8, op_info.bits.classbits as *i8, 32 as i64)
                        
                        code = code + (32 / sizeof[u8]())
                        
                    
                    code = code + rest_len
                    
                
        
    else:
        var need_map_1: c_int = context.needs_bitmap
        
        var required_len_2: c_ulong = ((((1 + 2) + 1) +% ((if (need_map_1 != 0): (32 / sizeof[u8]()) else: 0))) +% op_info.length)
        
        if (lengthptr != null):
            if (required_len_2 > (((unsafe: *lengthptr) -% previous_length))):
                ((unsafe: *lengthptr) = (previous_length +% required_len_2))
            
            (unsafe: *lengthptr) = (unsafe: *lengthptr) - ((1 + 2) + 1)
            
            var __ci_expr_old_9: *mut u8 = code
            (code = code + 1)
            ((unsafe: *__ci_expr_old_9) = 113)
            
            (code[0] = ((((((1 + 2) + 1)) >> 8)) as u8))
            (code[((0) + 1)] = ((((((1 + 2) + 1)) & 255)) as u8))
            
            code = code + 2
            
            var __ci_expr_old_10: *mut u8 = code
            (code = code + 1)
            ((unsafe: *__ci_expr_old_10) = 0)
            
        else:
            if (need_map_1 != 0):
                var map_start: *mut u8 = (((previous + (1 as isize as usize)) + (2 as isize as usize)) + (1 as isize as usize))
                
                previous[(1 + 2)] = previous[(1 + 2)] | 1
                
                with_memcpy(map_start as *i8, op_info.bits.classbits as *i8, 32 as i64)
                
                code = code + (32 / sizeof[u8]())
                
            
            (previous[1] = ((((((((code as usize -% previous as usize) / sizeof[u8]())) as c_int)) >> 8)) as u8))
            (previous[((1) + 1)] = ((((((((code as usize -% previous as usize) / sizeof[u8]())) as c_int)) & 255)) as u8))
            
        

    ((unsafe: *pcode) = code)

    return 1


extern fn _pcre2_compile_get_hash_from_name8(name: *const u8, length: c_uint) -> c_ushort
extern fn _pcre2_compile_find_named_group8(name: *const u8, length: c_uint, cb: *mut compile_block_8) -> *mut named_group_8
extern fn _pcre2_compile_add_name_to_table8(cb: *mut compile_block_8, ng: *mut named_group_8, tablecount: c_uint) -> c_uint
extern fn _pcre2_compile_find_dupname_details8(name: *const u8, length: c_uint, indexptr: *mut c_int, countptr: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int
extern fn _pcre2_compile_parse_scan_substr_args8(pptr: *mut c_uint, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint
extern fn _pcre2_compile_parse_recurse_args8(pptr_start: *mut c_uint, offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int
type eclass_context { options: c_uint = 0, xoptions: c_uint = 0, errorcodeptr: *mut c_int = null, cb: *mut compile_block_8 = null, needs_bitmap: c_int = 0 }
type struct_eclass_context = eclass_context
fn do_heapify(buffer: *mut c_uint, size: c_ulong, __param_i: c_ulong):
    var i = __param_i
    var max: c_ulong

    var left: c_ulong

    var right: c_ulong

    var tmp1: c_uint
    var tmp2: c_uint

    while (1 != 0):
        (max = i)
        
        (left = (((i << 1)) +% 2))
        
        (right = (left +% 2))
        
        if ((left < size) and (buffer[left] > buffer[max])):
            (max = left)
        
        if ((right < size) and (buffer[right] > buffer[max])):
            (max = right)
        
        if (i == max):
            return
        
        (tmp1 = buffer[i])
        
        (tmp2 = buffer[(i +% 1)])
        
        (buffer[i] = buffer[max])
        
        (buffer[(i +% 1)] = buffer[(max +% 1)])
        
        (buffer[max] = tmp1)
        
        (buffer[(max +% 1)] = tmp2)
        
        (i = max)
        


fn get_nocase_range(c: c_uint) -> *const c_uint:
    var left: c_uint = 0

    var right: c_uint = _pcre2_ucd_nocase_ranges_size_8

    var middle: c_uint

    if (c > 1114111):
        return ((&_pcre2_ucd_nocase_ranges_8[0] as *mut c_uint) + right)

    while (1 != 0):
        (middle = (((((left +% right)) >> 1)) | 1))
        
        if (_pcre2_ucd_nocase_ranges_8[middle] <= c):
            (left = (middle +% 1))
        else:
            if ((middle > 1) and (_pcre2_ucd_nocase_ranges_8[(middle -% 2)] > c)):
                (right = (middle -% 1))
            else:
                return ((&_pcre2_ucd_nocase_ranges_8[0] as *mut c_uint) + ((middle -% 1)))
        


fn utf_caseless_extend(start: c_uint, end: c_uint, options: c_uint, __param_buffer: *mut c_uint) -> c_ulong:
    var buffer = __param_buffer
    var new_start: c_uint = start

    var new_end: c_uint = end

    var c: c_uint = start

    var list: *const c_uint

    var tmp: [3]c_uint

    var result: c_ulong = 2

    var skip_range: *const c_uint = get_nocase_range(c)

    var skip_start: c_uint = skip_range[0]

    while true:
        
        if not ((0 != 0)):
            break
        

    while (c <= end):
        var co: c_uint
        
        if (c > skip_start):
            (c = skip_range[1])
            
            skip_range = skip_range + 2
            
            (skip_start = skip_range[0])
            
            continue
            
        
        if ((((options & ((8 | 4)))) == 8) and (((((c) | 32)) == 105) or ((((c) | 1)) == 305))):
            (co = (_pcre2_ucd_turkish_dotted_i_caseset_8 +% ((if (((c) == 105) or ((c) == 304)): 0 else: 3))))
            
        else:
            var __ci_cond_if_0: bool = false
            var __ci_expr_logic_0: c_int = (if false: 1 else: 0)
            var __ci_expr_logic_1: c_int = (if false: 1 else: 0)
            (co = (((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(((c) as c_int) / 128)] * 128) + (((c) as c_int) % 128))] as isize as usize))).caseset)
            if ((if (co) != 0: 1 else: 0) != 0):
                (__ci_expr_logic_1 = (if ((if ((options & 4)) != 0: 1 else: 0) != 0): 1 else: 0))
            
            if (__ci_expr_logic_1 != 0):
                (__ci_expr_logic_0 = (if ((if _pcre2_ucd_caseless_sets_8[co] < 128: 1 else: 0) != 0): 1 else: 0))
            
            (__ci_cond_if_0 = (__ci_expr_logic_0 != 0))
            
            if __ci_cond_if_0:
                (co = 0)
                
            
        
        if (co != 0):
            (list = ((&_pcre2_ucd_caseless_sets_8[0] as *mut c_uint) + co))
        else:
            (co = (((((c as c_int) + ((((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(((c) as c_int) / 128)] * 128) + (((c) as c_int) % 128))] as isize as usize))).other_case))) as c_uint)))
            
            (list = ((&tmp[0] as *mut c_uint) as *const c_uint))
            
            (tmp[0] = c)
            
            (tmp[1] = 4294967295)
            
            if (co != c):
                (tmp[1] = co)
                
                (tmp[2] = 4294967295)
                
            
        
        (c = c + 1)
        
        while true:
            if ((unsafe: *list) < new_start):
                if (((unsafe: *list) +% 1) == new_start):
                    var __ci_expr_old_2: c_uint = new_start
                    (new_start = new_start - 1)
                    
                    continue
                    
                
            else:
                if ((unsafe: *list) > new_end):
                    if (((unsafe: *list) -% 1) == new_end):
                        var __ci_expr_old_3: c_uint = new_end
                        (new_end = new_end + 1)
                        
                        continue
                        
                    
                else:
                    continue
            
            (result = result + 2)
            
            if (buffer != (null as *mut c_uint)):
                (buffer[0] = (unsafe: *list))
                
                (buffer[1] = (unsafe: *list))
                
                (buffer = buffer + 2)
                
            
            var __ci_cond_do_4: bool = false
            (list = list + 1)
            (__ci_cond_do_4 = ((if (unsafe: *(list)) != 4294967295: 1 else: 0) != 0))
            if not (__ci_cond_do_4):
                break
        

    if (buffer != null):
        (buffer[0] = new_start)
        
        (buffer[1] = new_end)
        
        buffer = buffer + 2
        
        buffer
        

    return result


fn append_char_list(__param_p: *const c_uint, __param_buffer: *mut c_uint) -> c_ulong:
    var p = __param_p
    var buffer = __param_buffer
    var n: *const c_uint

    var result: c_ulong = 0

    while ((unsafe: *p) != 4294967295):
        (n = p)
        
        while (n[0] == (n[1] -% 1)):
            (n = n + 1)
        
        while true:
            
            if not ((0 != 0)):
                break
            
        
        if (buffer != null):
            (buffer[0] = (unsafe: *p))
            
            (buffer[1] = (unsafe: *n))
            
            buffer = buffer + 2
            
        
        result = result + 2
        
        (p = (n + (1 as isize as usize)))
        

    return result


fn get_highest_char(options: c_uint) -> c_uint:
    options

    return 1114111


fn append_negated_char_list(__param_p: *const c_uint, options: c_uint, __param_buffer: *mut c_uint) -> c_ulong:
    var p = __param_p
    var buffer = __param_buffer
    var n: *const c_uint

    var start: c_uint = 0

    var result: c_ulong = 2

    while true:
        
        if not ((0 != 0)):
            break
        

    while ((unsafe: *p) != 4294967295):
        (n = p)
        
        while (n[0] == (n[1] -% 1)):
            (n = n + 1)
        
        while true:
            
            if not ((0 != 0)):
                break
            
        
        if (buffer != null):
            (buffer[0] = start)
            
            (buffer[1] = ((unsafe: *p) -% 1))
            
            buffer = buffer + 2
            
        
        result = result + 2
        
        (start = ((unsafe: *n) +% 1))
        
        (p = (n + (1 as isize as usize)))
        

    if (buffer != null):
        (buffer[0] = start)
        
        (buffer[1] = get_highest_char(options))
        
        buffer = buffer + 2
        
        buffer
        

    return result


fn append_non_ascii_range(options: c_uint, buffer: *mut c_uint) -> *mut c_uint:
    if (buffer == null):
        return null

    (buffer[0] = 256)

    (buffer[1] = get_highest_char(options))

    return (buffer + (2 as isize as usize))


fn parse_class(__param_ptr: *mut c_uint, options: c_uint, __param_buffer: *mut c_uint) -> c_ulong:
    var ptr = __param_ptr
    var buffer = __param_buffer
    var total_size: c_ulong = 0

    var size: c_ulong

    var meta_arg: c_uint

    var start_char: c_uint

    while (1 != 0):
        match (((unsafe: *ptr) & (4294901760 as c_uint)))
            2149318656 =>
                (meta_arg = (((unsafe: *ptr) & 65535)))
                match meta_arg
                    6 =>
                        (buffer = append_non_ascii_range(options, buffer))
                        (total_size = total_size + 2)
                    10 =>
                        (buffer = append_non_ascii_range(options, buffer))
                        (total_size = total_size + 2)
                    8 =>
                        (buffer = append_non_ascii_range(options, buffer))
                        (total_size = total_size + 2)
                    19 =>
                        (size = append_char_list((&_pcre2_hspace_list_8[0] as *mut c_uint), buffer))
                        (total_size = total_size + size)
                        if (buffer != (null as *mut c_uint)):
                            (buffer = buffer + size)
                    18 =>
                        (size = append_negated_char_list((&_pcre2_hspace_list_8[0] as *mut c_uint), options, buffer))
                        (total_size = total_size + size)
                        if (buffer != (null as *mut c_uint)):
                            (buffer = buffer + size)
                    21 =>
                        (size = append_char_list((&_pcre2_vspace_list_8[0] as *mut c_uint), buffer))
                        (total_size = total_size + size)
                        if (buffer != (null as *mut c_uint)):
                            (buffer = buffer + size)
                    20 =>
                        (size = append_negated_char_list((&_pcre2_vspace_list_8[0] as *mut c_uint), options, buffer))
                        (total_size = total_size + size)
                        if (buffer != (null as *mut c_uint)):
                            (buffer = buffer + size)
                    16 =>
                        var __ci_expr_old_0: *mut c_uint = ptr
                        (ptr = ptr + 1)
                        if ((meta_arg == 16) and ((((unsafe: *ptr) >> 16)) == 13)):
                            if (buffer != (null as *mut c_uint)):
                                (buffer[0] = 0)
                                
                                (buffer[1] = get_highest_char(options))
                                
                                (buffer = buffer + 2)
                                
                            
                            (total_size = total_size + 2)
                            
                    15 =>
                        var __ci_expr_old_0: *mut c_uint = ptr
                        (ptr = ptr + 1)
                        if ((meta_arg == 16) and ((((unsafe: *ptr) >> 16)) == 13)):
                            if (buffer != (null as *mut c_uint)):
                                (buffer[0] = 0)
                                
                                (buffer[1] = get_highest_char(options))
                                
                                (buffer = buffer + 2)
                                
                            
                            (total_size = total_size + 2)
                            
                    _ => 0
                var __ci_expr_old_1: *mut c_uint = ptr
                (ptr = ptr + 1)
                continue
                (buffer = append_non_ascii_range(options, buffer))
                (total_size = total_size + 2)
                (ptr = ptr + 2)
                continue
                (ptr = ptr + 2)
                continue
                var __ci_expr_old_2: *mut c_uint = ptr
                (ptr = ptr + 1)
            2149646336 =>
                (buffer = append_non_ascii_range(options, buffer))
                (total_size = total_size + 2)
                (ptr = ptr + 2)
                continue
                (ptr = ptr + 2)
                continue
                var __ci_expr_old_2: *mut c_uint = ptr
                (ptr = ptr + 1)
            2149580800 =>
                (ptr = ptr + 2)
                continue
                var __ci_expr_old_2: *mut c_uint = ptr
                (ptr = ptr + 1)
            2147811328 =>
                var __ci_expr_old_2: *mut c_uint = ptr
                (ptr = ptr + 1)
            _ =>
                if ((unsafe: *ptr) >= 2147483648):
                    return total_size
        
        (start_char = (unsafe: *ptr))
        
        if ((ptr[1] == 2149777408) or (ptr[1] == 2149711872)):
            ptr = ptr + 2
            
            while true:
                
                if not ((0 != 0)):
                    break
                
            
            if ((unsafe: *ptr) == 2147811328):
                (ptr = ptr + 1)
            
        
        if ((options & 2) != 0):
            var __ci_expr_old_3: *mut c_uint = ptr
            (ptr = ptr + 1)
            (size = utf_caseless_extend(start_char, (unsafe: *__ci_expr_old_3), options, buffer))
            
            if (buffer != null):
                buffer = buffer + size
            
            total_size = total_size + size
            
            continue
            
        
        if (buffer != null):
            (buffer[0] = start_char)
            
            (buffer[1] = (unsafe: *ptr))
            
            buffer = buffer + 2
            
        
        (ptr = ptr + 1)
        
        total_size = total_size + 2
        

    return total_size


fn compile_optimize_class(start_ptr: *mut c_uint, options: c_uint, xoptions: c_uint, cb: *mut compile_block_8) -> *mut class_ranges:
    var cranges: *mut class_ranges

    var ptr: *mut c_uint

    var buffer: *mut c_uint

    var dst: *mut c_uint

    var class_options: c_uint = 0

    var range_list_size: c_ulong = 0
    var total_size: c_ulong
    var i: c_ulong

    var tmp1: c_uint
    var tmp2: c_uint

    var char_list_next: *const c_uint

    var next_char: *mut c_ushort

    var char_list_start: c_uint
    var char_list_end: c_uint

    var range_start: c_uint
    var range_end: c_uint

    if ((options & 524288) != 0):
        class_options = class_options | 1

    if (((options & 8) != 0) and ((options & ((524288 | 131072))) != 0)):
        class_options = class_options | 2

    if ((xoptions & 128) != 0):
        class_options = class_options | 4

    if ((xoptions & 65536) != 0):
        class_options = class_options | 8

    (range_list_size = parse_class(start_ptr, class_options, null))

    while true:
        
        if not ((0 != 0)):
            break
        

    (total_size = (range_list_size +% ((if (range_list_size >= 2): 3 else: 0))))

    (cranges = (cb.cx.memctl.malloc((sizeof[class_ranges]() +% (total_size *% sizeof[c_uint]())), cb.cx.memctl.memory_data) as *mut class_ranges))

    if (cranges == null):
        return null

    (cranges.header.next = (null as *mut compile_data))

    (cranges.range_list_size = (range_list_size as c_ushort))

    (cranges.char_lists_types = 0)

    (cranges.char_lists_size = 0)

    (cranges.char_lists_start = 0)

    if (range_list_size == 0):
        return cranges

    (buffer = (((cranges + (1 as isize as usize))) as *mut c_uint))

    parse_class(start_ptr, class_options, buffer)

    if (range_list_size <= 2):
        return cranges

    (i = ((((((range_list_size >> 2)) -% 1)) << 1)))

    while (1 != 0):
        do_heapify(buffer, range_list_size, i)
        
        if (i == 0):
            break
        
        i = i - 2
        

    (i = (range_list_size -% 2))

    while (1 != 0):
        (tmp1 = buffer[i])
        
        (tmp2 = buffer[(i +% 1)])
        
        (buffer[i] = buffer[0])
        
        (buffer[(i +% 1)] = buffer[1])
        
        (buffer[0] = tmp1)
        
        (buffer[1] = tmp2)
        
        do_heapify(buffer, i, 0)
        
        if (i == 0):
            break
        
        i = i - 2
        

    (dst = buffer)

    (ptr = (buffer + (2 as isize as usize)))

    range_list_size = range_list_size - 2

    while ((range_list_size > 0) and (dst[1] != (0 - (0 as c_uint) - 1))):
        if ((dst[1] +% 1) < ptr[0]):
            dst = dst + 2
            
            (dst[0] = ptr[0])
            
            (dst[1] = ptr[1])
            
        else:
            if (dst[1] < ptr[1]):
                (dst[1] = ptr[1])
        
        ptr = ptr + 2
        
        range_list_size = range_list_size - 2
        

    while true:
        
        if not ((0 != 0)):
            break
        

    (ptr = buffer)

    while ((ptr < dst) and (ptr[1] < 256)):
        ptr = ptr + 2

    if (((dst as usize -% ptr as usize) / sizeof[c_uint]()) < ((2 * ((6 - 1))))):
        (cranges.range_list_size = (((((dst + (2 as isize as usize)) as usize -% buffer as usize) / sizeof[c_uint]())) as c_ushort))
        
        return cranges
        

    (char_list_next = (&char_list_starts[0] as *mut c_uint))

    var __ci_expr_old_0: *const c_uint = char_list_next
    (char_list_next = char_list_next + 1)
    (char_list_start = (unsafe: *__ci_expr_old_0))

    (char_list_end = 2147483647)

    (next_char = (((buffer + total_size)) as *mut c_ushort))

    (tmp1 = 0)

    (tmp2 = ((((((3 * sizeof[c_uint]()) / sizeof[c_uint]())) -% 1)) *% 3))

    while true:
        
        if not ((0 != 0)):
            break
        

    (range_start = dst[0])

    (range_end = dst[1])

    while (1 != 0):
        if (range_start >= char_list_start):
            if ((range_start == range_end) or (range_end < char_list_end)):
                (tmp1 = tmp1 + 1)
                
                (next_char = next_char - 1)
                
                if (char_list_start < 65536):
                    ((unsafe: *next_char) = (((((range_end << 1)) | 1)) as c_ushort))
                else:
                    (next_char = next_char - 1)
                    ((unsafe: *((next_char) as *mut c_uint)) = (((range_end << 1)) | 1))
                
            
            if (range_start < range_end):
                if (range_start > char_list_start):
                    (tmp1 = tmp1 + 1)
                    
                    (next_char = next_char - 1)
                    
                    if (char_list_start < 65536):
                        ((unsafe: *next_char) = (((range_start << 1)) as c_ushort))
                    else:
                        (next_char = next_char - 1)
                        ((unsafe: *((next_char) as *mut c_uint)) = ((range_start << 1)))
                    
                else:
                    cranges.char_lists_types = cranges.char_lists_types | (4 << tmp2)
                
            
            while true:
                
                if not ((0 != 0)):
                    break
                
            
            if (dst > buffer):
                dst = dst - 2
                
                (range_start = dst[0])
                
                (range_end = dst[1])
                
                continue
                
            
            (range_start = 0)
            
            (range_end = 0)
            
        
        if (range_end >= char_list_start):
            while true:
                
                if not ((0 != 0)):
                    break
                
            
            if (range_end < char_list_end):
                (tmp1 = tmp1 + 1)
                
                (next_char = next_char - 1)
                
                if (char_list_start < 65536):
                    ((unsafe: *next_char) = (((((range_end << 1)) | 1)) as c_ushort))
                else:
                    (next_char = next_char - 1)
                    ((unsafe: *((next_char) as *mut c_uint)) = (((range_end << 1)) | 1))
                
                while true:
                    
                    if not ((0 != 0)):
                        break
                    
                
            
            cranges.char_lists_types = cranges.char_lists_types | (4 << tmp2)
            
        
        if (tmp1 >= 3):
            cranges.char_lists_types = cranges.char_lists_types | (3 << tmp2)
            
            (next_char = next_char - 1)
            
            if (char_list_start < 65536):
                ((unsafe: *next_char) = (tmp1 as c_ushort))
            else:
                (next_char = next_char - 1)
                ((unsafe: *((next_char) as *mut c_uint)) = tmp1)
            
        else:
            cranges.char_lists_types = cranges.char_lists_types | (tmp1 << tmp2)
        
        if ((range_end < 256) or (tmp2 == 0)):
            while true:
                
                if not ((0 != 0)):
                    break
                
            
            break
            
        
        while true:
            
            if not ((0 != 0)):
                break
            
        
        (char_list_end = (char_list_start -% 1))
        
        var __ci_expr_old_1: *const c_uint = char_list_next
        (char_list_next = char_list_next + 1)
        (char_list_start = (unsafe: *__ci_expr_old_1))
        
        (tmp1 = 0)
        
        tmp2 = tmp2 - 3
        

    if (dst[0] < 256):
        dst = dst + 2

    while true:
        
        if not ((0 != 0)):
            break
        

    (cranges.char_lists_size = (((((((buffer + total_size)) as *mut u8) as usize -% (next_char as *mut u8) as usize) / sizeof[u8]())) as c_ulong))

    (cranges.char_lists_start = (((((next_char as *mut u8) as usize -% (buffer as *mut u8) as usize) / sizeof[u8]())) as c_ulong))

    (cranges.range_list_size = ((((dst as usize -% buffer as usize) / sizeof[c_uint]())) as c_ushort))

    return cranges


fn add_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, start: c_uint, end: c_uint):
    var classbits: *mut u8 = (&cb.classbits.classbits[0] as *mut u8)

    var c: c_uint
    var byte_start: c_uint
    var byte_end: c_uint

    var classbits_end: c_uint = ((if (end <= 255): end else: 255))

    if (((options & 8)) != 0):
        if (((options & ((524288 | 131072)))) != 0):
            var turkish_i: c_int = (if ((xoptions & ((65536 | 128)))) == 65536: 1 else: 0)
            
            if (start < 128):
                var lo_end: c_uint = ((if (classbits_end < 127): classbits_end else: 127))
                
                (c = start)
                
                while (c <= lo_end):
                    if ((turkish_i != 0) and (((((c) | 32)) == 105) or ((((c) | 1)) == 305))):
                        continue
                    
                    classbits[((cb.fcc[c]) >> 3)] = classbits[((cb.fcc[c]) >> 3)] | (((1 << (((cb.fcc[c]) & 7)))) as u8)
                    
                    
                    var __ci_expr_old_0: c_uint = c
                    (c = c + 1)
                    
                
                
            
            if (classbits_end >= 128):
                var hi_start: c_uint = ((if (start > 128): start else: 128))
                
                (c = hi_start)
                
                while (c <= classbits_end):
                    var co: c_uint = (((((c as c_int) + ((((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(((c) as c_int) / 128)] * 128) + (((c) as c_int) % 128))] as isize as usize))).other_case))) as c_uint))
                    
                    if (co <= 255):
                        classbits[((co) >> 3)] = classbits[((co) >> 3)] | (((1 << (((co) & 7)))) as u8)
                    
                    
                    var __ci_expr_old_1: c_uint = c
                    (c = c + 1)
                    
                
                
            
        else:
            (c = start)
            
            while (c <= classbits_end):
                classbits[((cb.fcc[c]) >> 3)] = classbits[((cb.fcc[c]) >> 3)] | (((1 << (((cb.fcc[c]) & 7)))) as u8)
                
                var __ci_expr_old_2: c_uint = c
                (c = c + 1)
                
            
            
        

    (byte_start = (((start +% 7)) >> 3))

    (byte_end = (((classbits_end +% 1)) >> 3))

    if (byte_start >= byte_end):
        (c = start)
        
        while (c <= classbits_end):
            classbits[((c) >> 3)] = classbits[((c) >> 3)] | (((1 << (((c) & 7)))) as u8)
            
            var __ci_expr_old_3: c_uint = c
            (c = c + 1)
            
        
        
        return
        

    (c = byte_start)
    
    while (c < byte_end):
        (classbits[c] = 255)
        
        var __ci_expr_old_4: c_uint = c
        (c = c + 1)
        
    

    byte_start = byte_start << 3

    byte_end = byte_end << 3

    (c = start)
    
    while (c < byte_start):
        classbits[((c) >> 3)] = classbits[((c) >> 3)] | (((1 << (((c) & 7)))) as u8)
        
        var __ci_expr_old_5: c_uint = c
        (c = c + 1)
        
    

    (c = byte_end)
    
    while (c <= classbits_end):
        classbits[((c) >> 3)] = classbits[((c) >> 3)] | (((1 << (((c) & 7)))) as u8)
        
        var __ci_expr_old_6: c_uint = c
        (c = c + 1)
        
    


fn add_list_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, __param_p: *const c_uint):
    var p = __param_p
    while (p[0] < 256):
        var n: c_uint = 0
        
        while (p[(n +% 1)] == ((p[0] +% n) +% 1)):
            (n = n + 1)
        
        add_to_class(options, xoptions, cb, p[0], p[n])
        
        p = p + (n +% 1)
        


fn add_not_list_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, __param_p: *const c_uint):
    var p = __param_p
    if (p[0] > 0):
        add_to_class(options, xoptions, cb, 0, (p[0] -% 1))

    while (p[0] < 256):
        while (p[1] == (p[0] +% 1)):
            (p = p + 1)
        
        add_to_class(options, xoptions, cb, (p[0] +% 1), (if (p[1] > 255): 255 else: (p[1] -% 1)))
        
        (p = p + 1)
        


fn fold_negation(pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong, preserve_classbits: c_int):
    if (pop_info.op_single_type == 0):
        if (lengthptr != null):
            (unsafe: *lengthptr) = (unsafe: *lengthptr) + 1
        else:
            (pop_info.code_start[pop_info.length] = 4)
        
        pop_info.length = pop_info.length + 1
        
    else:
        if ((pop_info.op_single_type == 6) or (pop_info.op_single_type == 7)):
            (pop_info.op_single_type = (if (pop_info.op_single_type == 7): 6 else: 7))
            
            if (lengthptr == null):
                ((unsafe: *(pop_info.code_start)) = pop_info.op_single_type)
            
        else:
            while true:
                
                if not ((0 != 0)):
                    break
                
            
            if (lengthptr == null):
                pop_info.code_start[(1 + 2)] = pop_info.code_start[(1 + 2)] ^ 1
            

    if (not ((preserve_classbits != 0))):
        var i: c_int = 0
        
        while (i < 8):
            (pop_info.bits.classwords[i] = (0 - pop_info.bits.classwords[i] - 1))
            
            var __ci_expr_old_0: c_int = i
            (i = i + 1)
            
        
        


fn fold_binary(op: c_int, lhs_op_info: *mut eclass_op_info, rhs_op_info: *mut eclass_op_info, lengthptr: *mut c_ulong):
    match op
        1 =>
            var i: c_int = 0
            while (i < 8):
                ((&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] = (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] & (&rhs_op_info.bits.classwords[0] as *mut c_uint)[i])
                var __ci_expr_old_0: c_int = i
            (i = i + 1)
        2 =>
            var i_1: c_int = 0
            while (i_1 < 8):
                ((&lhs_op_info.bits.classwords[0] as *mut c_uint)[i_1] = (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i_1] | (&rhs_op_info.bits.classwords[0] as *mut c_uint)[i_1])
                var __ci_expr_old_1: c_int = i_1
            (i_1 = i_1 + 1)
        3 =>
            var i_2: c_int = 0
            while (i_2 < 8):
                ((&lhs_op_info.bits.classwords[0] as *mut c_uint)[i_2] = (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i_2] ^ (&rhs_op_info.bits.classwords[0] as *mut c_uint)[i_2])
                var __ci_expr_old_2: c_int = i_2
            (i_2 = i_2 + 1)


fn compile_eclass_nested(context: *mut eclass_context, __param_negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var negated = __param_negated
    var ptr: *mut c_uint = (unsafe: *pptr)

    while true:
        
        if not ((0 != 0)):
            break
        

    var __ci_cond_if_0: bool = false
    var __ci_expr_old_1: *mut c_uint = ptr
    (ptr = ptr + 1)
    (__ci_cond_if_0 = ((if (unsafe: *__ci_expr_old_1) == (((2148401152 as c_uint) | 1)): 1 else: 0) != 0))
    
    if __ci_cond_if_0:
        (negated = (if negated != 0: 0 else: 1))
    

    (((unsafe: *pptr)) = ((unsafe: *pptr)) + 1)

    if (not ((compile_class_binary_loose(context, negated, pptr, pcode, pop_info, lengthptr) != 0))):
        return 0

    while true:
        
        if not ((0 != 0)):
            break
        

    while true:
        
        if not ((0 != 0)):
            break
        

    return 1


fn compile_class_operand(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr__goto_2135_11: *mut c_uint = null
    var prev_ptr__goto_2136_11: *mut c_uint = null
    var code__goto_2137_14: *mut u8 = null
    var code_start__goto_2138_14: *mut u8 = null
    var prev_length__goto_2139_12: c_ulong = 0
    var extra_length__goto_2140_12: c_ulong = 0
    var meta__goto_2141_10: c_uint = 0
    var classwords__goto_2242_17: *mut c_uint = null
    var i__goto_2244_16: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr__goto_2135_11 = (unsafe: *pptr)
                code__goto_2137_14 = (unsafe: *pcode)
                code_start__goto_2138_14 = code__goto_2137_14
                prev_length__goto_2139_12 = (if (lengthptr != (null as *mut c_ulong)): (unsafe: *lengthptr) else: 0)
                meta__goto_2141_10 = (((unsafe: *ptr__goto_2135_11) & (4294901760 as c_uint)))
                match meta__goto_2141_10
                    2148270080 =>
                        (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                        (pop_info.length = 1)
                        if (((if meta__goto_2141_10 == 2148204544: 1 else: 0)) == negated):
                            var __ci_expr_old_0: *mut u8 = code__goto_2137_14
                            (code__goto_2137_14 = code__goto_2137_14 + 1)
                            (pop_info.op_single_type = 6)
                            ((unsafe: *__ci_expr_old_0) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            var __ci_expr_old_1: *mut u8 = code__goto_2137_14
                            (code__goto_2137_14 = code__goto_2137_14 + 1)
                            (pop_info.op_single_type = 7)
                            ((unsafe: *__ci_expr_old_1) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 0, 32 as i64)
                            if __goto_pending != 0:
                                continue
                    2148204544 =>
                        (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                        (pop_info.length = 1)
                        if (((if meta__goto_2141_10 == 2148204544: 1 else: 0)) == negated):
                            var __ci_expr_old_0: *mut u8 = code__goto_2137_14
                            (code__goto_2137_14 = code__goto_2137_14 + 1)
                            (pop_info.op_single_type = 6)
                            ((unsafe: *__ci_expr_old_0) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            var __ci_expr_old_1: *mut u8 = code__goto_2137_14
                            (code__goto_2137_14 = code__goto_2137_14 + 1)
                            (pop_info.op_single_type = 7)
                            ((unsafe: *__ci_expr_old_1) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 0, 32 as i64)
                            if __goto_pending != 0:
                                continue
                    2148139008 =>
                        if ((((unsafe: *ptr__goto_2135_11) & 1)) != 0):
                            if (not ((compile_eclass_nested(context, negated, (&mut ptr__goto_2135_11 as *mut *mut c_uint), (&mut code__goto_2137_14 as *mut *mut u8), pop_info, lengthptr) != 0))):
                                return 0
                            if __goto_pending != 0:
                                continue
                            var __ci_expr_old_2: *mut c_uint = ptr__goto_2135_11
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                            if __goto_pending != 0:
                                continue
                            __pc = 1
                            __goto_pending = 1
                            if __goto_pending != 0:
                                continue
                        var __ci_expr_old_3: *mut c_uint = ptr__goto_2135_11
                        (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                        (prev_ptr__goto_2136_11 = ptr__goto_2135_11)
                        (ptr__goto_2135_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2135_11, (&mut code__goto_2137_14 as *mut *mut u8), (if ((if meta__goto_2141_10 != 2148401152: 1 else: 0)) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))
                        if (ptr__goto_2135_11 == (null as *mut c_uint)):
                            return 0
                        if (ptr__goto_2135_11 <= prev_ptr__goto_2136_11):
                            return 0
                            if __goto_pending != 0:
                                continue
                        if ((meta__goto_2141_10 == 2148139008) or (meta__goto_2141_10 == 2148401152)):
                            var __ci_expr_old_4: *mut c_uint = ptr__goto_2135_11
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                            if __goto_pending != 0:
                                continue
                        (extra_length__goto_2140_12 = (if (lengthptr != (null as *mut c_ulong)): ((unsafe: *lengthptr) -% prev_length__goto_2139_12) else: 0))
                        if ((unsafe: *code_start__goto_2138_14) == OP_ALLANY):
                            (pop_info.length = 1)
                            if __goto_pending != 0:
                                continue
                            (pop_info.op_single_type = 6)
                            ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            if (((unsafe: *code_start__goto_2138_14) == OP_CLASS) or ((unsafe: *code_start__goto_2138_14) == OP_NCLASS)):
                                (pop_info.length = 1)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.op_single_type = (if ((unsafe: *code_start__goto_2138_14) == OP_CLASS): 7 else: 6))
                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((code_start__goto_2138_14 + (1 as isize as usize)) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                if (lengthptr != (null as *mut c_ulong)):
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2137_14 as usize -% ((code_start__goto_2138_14 + (1 as isize as usize))) as usize) / sizeof[u8]()))
                                if __goto_pending != 0:
                                    continue
                                (code__goto_2137_14 = (code_start__goto_2138_14 + (1 as isize as usize)))
                                if __goto_pending != 0:
                                    continue
                                if ((not ((context.needs_bitmap != 0))) and ((unsafe: *code_start__goto_2138_14) == 7)):
                                    classwords__goto_2242_17 = (&(&pop_info.bits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                                    if __goto_pending != 0:
                                        continue
                                    i__goto_2244_16 = 0
                                    while (i__goto_2244_16 < 8):
                                        if (classwords__goto_2242_17[i__goto_2244_16] != 0):
                                            (context.needs_bitmap = 1)
                                            if __goto_pending != 0:
                                                break
                                            break
                                            if __goto_pending != 0:
                                                break
                                        var __ci_expr_old_5: c_int = i__goto_2244_16
                                    (i__goto_2244_16 = i__goto_2244_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        continue
                                else:
                                    (context.needs_bitmap = 1)
                                if __goto_pending != 0:
                                    continue
                            else:
                                (pop_info.op_single_type = 5)
                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((&context.cb.classbits.classbits[0] as *mut u8) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.length = ((((code__goto_2137_14 as usize -% code_start__goto_2138_14 as usize) / sizeof[u8]())) +% extra_length__goto_2140_12))
                                if __goto_pending != 0:
                                    continue
                    2148401152 =>
                        if ((((unsafe: *ptr__goto_2135_11) & 1)) != 0):
                            if (not ((compile_eclass_nested(context, negated, (&mut ptr__goto_2135_11 as *mut *mut c_uint), (&mut code__goto_2137_14 as *mut *mut u8), pop_info, lengthptr) != 0))):
                                return 0
                            if __goto_pending != 0:
                                continue
                            var __ci_expr_old_2: *mut c_uint = ptr__goto_2135_11
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                            if __goto_pending != 0:
                                continue
                            __pc = 1
                            __goto_pending = 1
                            if __goto_pending != 0:
                                continue
                        var __ci_expr_old_3: *mut c_uint = ptr__goto_2135_11
                        (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                        (prev_ptr__goto_2136_11 = ptr__goto_2135_11)
                        (ptr__goto_2135_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2135_11, (&mut code__goto_2137_14 as *mut *mut u8), (if ((if meta__goto_2141_10 != 2148401152: 1 else: 0)) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))
                        if (ptr__goto_2135_11 == (null as *mut c_uint)):
                            return 0
                        if (ptr__goto_2135_11 <= prev_ptr__goto_2136_11):
                            return 0
                            if __goto_pending != 0:
                                continue
                        if ((meta__goto_2141_10 == 2148139008) or (meta__goto_2141_10 == 2148401152)):
                            var __ci_expr_old_4: *mut c_uint = ptr__goto_2135_11
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                            if __goto_pending != 0:
                                continue
                        (extra_length__goto_2140_12 = (if (lengthptr != (null as *mut c_ulong)): ((unsafe: *lengthptr) -% prev_length__goto_2139_12) else: 0))
                        if ((unsafe: *code_start__goto_2138_14) == OP_ALLANY):
                            (pop_info.length = 1)
                            if __goto_pending != 0:
                                continue
                            (pop_info.op_single_type = 6)
                            ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            if (((unsafe: *code_start__goto_2138_14) == OP_CLASS) or ((unsafe: *code_start__goto_2138_14) == OP_NCLASS)):
                                (pop_info.length = 1)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.op_single_type = (if ((unsafe: *code_start__goto_2138_14) == OP_CLASS): 7 else: 6))
                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((code_start__goto_2138_14 + (1 as isize as usize)) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                if (lengthptr != (null as *mut c_ulong)):
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2137_14 as usize -% ((code_start__goto_2138_14 + (1 as isize as usize))) as usize) / sizeof[u8]()))
                                if __goto_pending != 0:
                                    continue
                                (code__goto_2137_14 = (code_start__goto_2138_14 + (1 as isize as usize)))
                                if __goto_pending != 0:
                                    continue
                                if ((not ((context.needs_bitmap != 0))) and ((unsafe: *code_start__goto_2138_14) == 7)):
                                    classwords__goto_2242_17 = (&(&pop_info.bits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                                    if __goto_pending != 0:
                                        continue
                                    i__goto_2244_16 = 0
                                    while (i__goto_2244_16 < 8):
                                        if (classwords__goto_2242_17[i__goto_2244_16] != 0):
                                            (context.needs_bitmap = 1)
                                            if __goto_pending != 0:
                                                break
                                            break
                                            if __goto_pending != 0:
                                                break
                                        var __ci_expr_old_5: c_int = i__goto_2244_16
                                    (i__goto_2244_16 = i__goto_2244_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        continue
                                else:
                                    (context.needs_bitmap = 1)
                                if __goto_pending != 0:
                                    continue
                            else:
                                (pop_info.op_single_type = 5)
                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((&context.cb.classbits.classbits[0] as *mut u8) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.length = ((((code__goto_2137_14 as usize -% code_start__goto_2138_14 as usize) / sizeof[u8]())) +% extra_length__goto_2140_12))
                                if __goto_pending != 0:
                                    continue
                    _ =>
                        (prev_ptr__goto_2136_11 = ptr__goto_2135_11)
                        (ptr__goto_2135_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2135_11, (&mut code__goto_2137_14 as *mut *mut u8), (if ((if meta__goto_2141_10 != 2148401152: 1 else: 0)) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))
                        if (ptr__goto_2135_11 == (null as *mut c_uint)):
                            return 0
                        if (ptr__goto_2135_11 <= prev_ptr__goto_2136_11):
                            return 0
                            if __goto_pending != 0:
                                continue
                        if ((meta__goto_2141_10 == 2148139008) or (meta__goto_2141_10 == 2148401152)):
                            var __ci_expr_old_4: *mut c_uint = ptr__goto_2135_11
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)
                            if __goto_pending != 0:
                                continue
                        (extra_length__goto_2140_12 = (if (lengthptr != (null as *mut c_ulong)): ((unsafe: *lengthptr) -% prev_length__goto_2139_12) else: 0))
                        if ((unsafe: *code_start__goto_2138_14) == OP_ALLANY):
                            (pop_info.length = 1)
                            if __goto_pending != 0:
                                continue
                            (pop_info.op_single_type = 6)
                            ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            if (((unsafe: *code_start__goto_2138_14) == OP_CLASS) or ((unsafe: *code_start__goto_2138_14) == OP_NCLASS)):
                                (pop_info.length = 1)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.op_single_type = (if ((unsafe: *code_start__goto_2138_14) == OP_CLASS): 7 else: 6))
                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((code_start__goto_2138_14 + (1 as isize as usize)) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                if (lengthptr != (null as *mut c_ulong)):
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2137_14 as usize -% ((code_start__goto_2138_14 + (1 as isize as usize))) as usize) / sizeof[u8]()))
                                if __goto_pending != 0:
                                    continue
                                (code__goto_2137_14 = (code_start__goto_2138_14 + (1 as isize as usize)))
                                if __goto_pending != 0:
                                    continue
                                if ((not ((context.needs_bitmap != 0))) and ((unsafe: *code_start__goto_2138_14) == 7)):
                                    classwords__goto_2242_17 = (&(&pop_info.bits.classwords[0] as *mut c_uint)[0] as *mut c_uint)
                                    if __goto_pending != 0:
                                        continue
                                    i__goto_2244_16 = 0
                                    while (i__goto_2244_16 < 8):
                                        if (classwords__goto_2242_17[i__goto_2244_16] != 0):
                                            (context.needs_bitmap = 1)
                                            if __goto_pending != 0:
                                                break
                                            break
                                            if __goto_pending != 0:
                                                break
                                        var __ci_expr_old_5: c_int = i__goto_2244_16
                                    (i__goto_2244_16 = i__goto_2244_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        continue
                                else:
                                    (context.needs_bitmap = 1)
                                if __goto_pending != 0:
                                    continue
                            else:
                                (pop_info.op_single_type = 5)
                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((&context.cb.classbits.classbits[0] as *mut u8) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.length = ((((code__goto_2137_14 as usize -% code_start__goto_2138_14 as usize) / sizeof[u8]())) +% extra_length__goto_2140_12))
                                if __goto_pending != 0:
                                    continue
                if __goto_pending != 0:
                    continue
                (pop_info.code_start = (if (lengthptr == (null as *mut c_ulong)): code_start__goto_2138_14 else: (null as *mut u8)))
                if __goto_pending != 0:
                    continue
                if (lengthptr != (null as *mut c_ulong)):
                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2137_14 as usize -% code_start__goto_2138_14 as usize) / sizeof[u8]()))
                    if __goto_pending != 0:
                        continue
                    (code__goto_2137_14 = code_start__goto_2138_14)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // DONE
                (__goto_pending = 0)
                ((unsafe: *pptr) = ptr__goto_2135_11)
                if __goto_pending != 0:
                    continue
                ((unsafe: *pcode) = code__goto_2137_14)
                if __goto_pending != 0:
                    continue
                return 1
                if __goto_pending != 0:
                    continue
            _ => break

fn compile_class_juxtaposition(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr: *mut c_uint = (unsafe: *pptr)

    var code: *mut u8 = (unsafe: *pcode)

    if (not ((compile_class_operand(context, negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), pop_info, lengthptr) != 0))):
        return 0

    while (((unsafe: *ptr) != 2148335616) and (not ((((unsafe: *ptr) >= 2151940096) and ((unsafe: *ptr) <= 2152202240))))):
        var op: c_uint
        
        var rhs_negated: c_int
        
        var rhs_op_info: eclass_op_info
        
        if (negated != 0):
            (op = 1)
            
            (rhs_negated = 1)
            
        else:
            (op = 2)
            
            (rhs_negated = 0)
            
        
        if (not ((compile_class_operand(context, rhs_negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), (&mut rhs_op_info as *mut eclass_op_info), lengthptr) != 0))):
            return 0
        
        fold_binary(op, pop_info, (&mut rhs_op_info as *mut eclass_op_info), lengthptr)
        
        if (lengthptr == null):
            (code = (pop_info.code_start + pop_info.length))
        

    while true:
        
        if not ((0 != 0)):
            break
        

    ((unsafe: *pptr) = ptr)

    ((unsafe: *pcode) = code)

    return 1


fn compile_class_unary(context: *mut eclass_context, __param_negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var negated = __param_negated
    var ptr: *mut c_uint = (unsafe: *pptr)

    while ((unsafe: *ptr) == 2152202240):
        (ptr = ptr + 1)
        
        (negated = (if negated != 0: 0 else: 1))
        

    ((unsafe: *pptr) = ptr)

    if (not ((compile_class_juxtaposition(context, negated, pptr, pcode, pop_info, lengthptr) != 0))):
        return 0

    while true:
        
        if not ((0 != 0)):
            break
        

    return 1


fn compile_class_binary_tight(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr: *mut c_uint = (unsafe: *pptr)

    var code: *mut u8 = (unsafe: *pcode)

    if (not ((compile_class_unary(context, negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), pop_info, lengthptr) != 0))):
        return 0

    while ((unsafe: *ptr) == 2151940096):
        var op: c_uint
        
        var rhs_negated: c_int
        
        var rhs_op_info: eclass_op_info
        
        if (negated != 0):
            (op = 2)
            
            (rhs_negated = 1)
            
        else:
            (op = 1)
            
            (rhs_negated = 0)
            
        
        (ptr = ptr + 1)
        
        if (not ((compile_class_unary(context, rhs_negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), (&mut rhs_op_info as *mut eclass_op_info), lengthptr) != 0))):
            return 0
        
        fold_binary(op, pop_info, (&mut rhs_op_info as *mut eclass_op_info), lengthptr)
        
        if (lengthptr == null):
            (code = (pop_info.code_start + pop_info.length))
        

    while true:
        
        if not ((0 != 0)):
            break
        

    ((unsafe: *pptr) = ptr)

    ((unsafe: *pcode) = code)

    return 1


fn compile_class_binary_loose(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr: *mut c_uint = (unsafe: *pptr)

    var code: *mut u8 = (unsafe: *pcode)

    if (not ((compile_class_binary_tight(context, negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), pop_info, lengthptr) != 0))):
        return 0

    while (((unsafe: *ptr) >= 2152005632) and ((unsafe: *ptr) <= 2152136704)):
        var op: c_uint
        
        var op_neg: c_int
        
        var rhs_negated: c_int
        
        var rhs_op_info: eclass_op_info
        
        if (negated != 0):
            (op = (if ((unsafe: *ptr) == 2152005632): 1 else: (if ((unsafe: *ptr) == 2152071168): 2 else: 3)))
            
            (op_neg = ((if (unsafe: *ptr) == 2152136704: 1 else: 0)))
            
            (rhs_negated = (if (unsafe: *ptr) != 2152071168: 1 else: 0))
            
        else:
            (op = (if ((unsafe: *ptr) == 2152005632): 2 else: (if ((unsafe: *ptr) == 2152071168): 1 else: 3)))
            
            (op_neg = 0)
            
            (rhs_negated = (if (unsafe: *ptr) == 2152071168: 1 else: 0))
            
        
        (ptr = ptr + 1)
        
        if (not ((compile_class_binary_tight(context, rhs_negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), (&mut rhs_op_info as *mut eclass_op_info), lengthptr) != 0))):
            return 0
        
        fold_binary(op, pop_info, (&mut rhs_op_info as *mut eclass_op_info), lengthptr)
        
        if (op_neg != 0):
            fold_negation(pop_info, lengthptr, 0)
        
        if (lengthptr == null):
            (code = (pop_info.code_start + pop_info.length))
        

    while true:
        
        if not ((0 != 0)):
            break
        

    ((unsafe: *pptr) = ptr)

    ((unsafe: *pcode) = code)

    return 1


let char_list_starts: [3]c_uint = [65536, 32768, 256]
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
extern let _pcre2_posix_class_maps8: [42]c_int
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
let CHAR_LIST_EXTRA_SIZE: c_int = 3
fn CHMAX_255[T](c: T) -> T:
    (c <= 255)
// untranslatable fn-like macro
fn CLASS_END_CASES() -> Never:
    comptime_error("untranslatable C macro: CLASS_END_CASES")
// untranslatable fn-like macro
fn CLIST_ALIGN_TO() -> Never:
    comptime_error("untranslatable C macro: CLIST_ALIGN_TO")
// untranslatable fn-like macro
fn CU2BYTES() -> Never:
    comptime_error("untranslatable C macro: CU2BYTES")
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
fn GETOFFSET() -> Never:
    comptime_error("untranslatable C macro: GETOFFSET")
// untranslatable fn-like macro
fn GETPLUSOFFSET() -> Never:
    comptime_error("untranslatable C macro: GETPLUSOFFSET")
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
fn GET_MAX_CHAR_VALUE() -> Never:
    comptime_error("untranslatable C macro: GET_MAX_CHAR_VALUE")
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
fn META_CODE[T](x: T) -> T:
    (x & 0xffff0000)
fn META_DATA[T](x: T) -> T:
    (x & 0x0000ffff)
// untranslatable fn-like macro
fn META_DIFF() -> Never:
    comptime_error("untranslatable C macro: META_DIFF")
// untranslatable fn-like macro
fn NAMED_GROUP_GET_HASH() -> Never:
    comptime_error("untranslatable C macro: NAMED_GROUP_GET_HASH")
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
let PARSE_CLASS_CASELESS_UTF: c_int = 0x2
let PARSE_CLASS_RESTRICTED_UTF: c_int = 0x4
let PARSE_CLASS_TURKISH_UTF: c_int = 0x8
let PARSE_CLASS_UTF: c_int = 0x1
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
fn PUTINC() -> Never:
    comptime_error("untranslatable C macro: PUTINC")
// untranslatable fn-like macro
fn PUTOFFSET() -> Never:
    comptime_error("untranslatable C macro: PUTOFFSET")
// untranslatable fn-like macro
fn READPLUSOFFSET() -> Never:
    comptime_error("untranslatable C macro: READPLUSOFFSET")
// untranslatable fn-like macro
fn REAL_GET_UCD() -> Never:
    comptime_error("untranslatable C macro: REAL_GET_UCD")
fn SELECT_VALUE8[T](value8: T, value: T) -> T:
    value8
// untranslatable fn-like macro
fn SETBIT() -> Never:
    comptime_error("untranslatable C macro: SETBIT")
// untranslatable fn-like macro
fn SKIPOFFSET() -> Never:
    comptime_error("untranslatable C macro: SKIPOFFSET")
// untranslatable fn-like macro
fn STATIC_ASSERT() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT")
// untranslatable fn-like macro
fn STATIC_ASSERT_JOIN() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT_JOIN")
// untranslatable fn-like macro
fn TABLE_GET() -> Never:
    comptime_error("untranslatable C macro: TABLE_GET")
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
let XCLASS_HAS_8BIT_CHARS: c_int = 0x2
let XCLASS_HAS_CHAR_LISTS: c_int = 0x8
let XCLASS_HAS_PROPS: c_int = 0x4
let XCLASS_HIGH_ANY: c_int = 0x10
let XCLASS_REQUIRED: c_int = 0x1
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
