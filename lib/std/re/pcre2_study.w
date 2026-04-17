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
fn _pcre2_study_8(re: *mut pcre2_real_code_8) -> c_int:
    var count__goto_1917_5: c_int = 0
    var code__goto_1918_14: *mut u8 = null
    var utf__goto_1919_6: c_int = 0
    var ucp__goto_1920_6: c_int = 0
    var depth__goto_1932_7: c_int = 0
    var rc__goto_1933_7: c_int = 0
    var i__goto_1952_9: c_int = 0
    var a__goto_1953_9: c_int = 0
    var b__goto_1954_9: c_int = 0
    var p__goto_1955_14: *mut u8 = null
    var flags__goto_1956_14: c_uint = 0
    var x__goto_1960_15: u8 = 0
    var c__goto_1963_13: c_int = 0
    var y__goto_1964_17: u8 = 0
    var d__goto_1996_15: c_int = 0
    var min__goto_2056_7: c_int = 0
    var backref_cache__goto_2057_7: [129]c_int = [0 as c_int; 129]
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc:
            0 =>
                (__goto_pending = 0)
                count__goto_1917_5 = 0
                utf__goto_1919_6 = (if ((re.overall_options & 524288)) != 0: 1 else: 0)
                ucp__goto_1920_6 = (if ((re.overall_options & 131072)) != 0: 1 else: 0)
                (code__goto_1918_14 = (((re as *mut u8) + re.code_start)))
                if __goto_pending != 0:
                    continue
                if (((re.flags & ((16 | 512)))) == 0):
                    depth__goto_1932_7 = 0
                    if __goto_pending != 0:
                        continue
                    rc__goto_1933_7 = set_start_bits(re, (code__goto_1918_14 as *const u8), utf__goto_1919_6, ucp__goto_1920_6, (&mut depth__goto_1932_7 as *mut c_int))
                    if __goto_pending != 0:
                        continue
                    if (rc__goto_1933_7 == SSB_UNKNOWN):
                        return 1
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                    if (rc__goto_1933_7 == SSB_DONE):
                        a__goto_1953_9 = -1
                        if __goto_pending != 0:
                            continue
                        b__goto_1954_9 = -1
                        if __goto_pending != 0:
                            continue
                        p__goto_1955_14 = (&(&re.start_bitmap[0] as *mut u8)[0] as *mut u8)
                        if __goto_pending != 0:
                            continue
                        flags__goto_1956_14 = 64
                        if __goto_pending != 0:
                            continue
                        (i__goto_1952_9 = 0)
                        while (i__goto_1952_9 < 256):
                            x__goto_1960_15 = (unsafe: *p__goto_1955_14)
                            if __goto_pending != 0:
                                break
                            if (x__goto_1960_15 != 0):
                                y__goto_1964_17 = (x__goto_1960_15 & (((0 - x__goto_1960_15 - 1) + 1)))
                                if __goto_pending != 0:
                                    break
                                if (y__goto_1964_17 != x__goto_1960_15):
                                    __pc = 1
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                (c__goto_1963_13 = i__goto_1952_9)
                                if __goto_pending != 0:
                                    break
                                match x__goto_1960_15:
                                    1 => 0
                                    2 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 1)
                                    4 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 2)
                                    8 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 3)
                                    16 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 4)
                                    32 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 5)
                                    64 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 6)
                                    128 =>
                                        (c__goto_1963_13 = c__goto_1963_13 + 7)
                                    _ => 0
                                if __goto_pending != 0:
                                    break
                                if ((utf__goto_1919_6 != 0) and (c__goto_1963_13 > 127)):
                                    __pc = 1
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if (a__goto_1953_9 < 0):
                                    (a__goto_1953_9 = c__goto_1963_13)
                                else:
                                    if (b__goto_1954_9 < 0):
                                        d__goto_1996_15 = (((re.tables + (256 as isize as usize)))[(c__goto_1963_13 as c_uint)])
                                        if __goto_pending != 0:
                                            break
                                        if ((utf__goto_1919_6 != 0) or (ucp__goto_1920_6 != 0)):
                                            if ((((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c__goto_1963_13) / 128)] * 128) + ((c__goto_1963_13) % 128))] as isize as usize))).caseset != 0):
                                                __pc = 1
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if (c__goto_1963_13 > 127):
                                                (d__goto_1996_15 = ((((c__goto_1963_13 + ((((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c__goto_1963_13) / 128)] * 128) + ((c__goto_1963_13) % 128))] as isize as usize))).other_case))) as c_uint)))
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (d__goto_1996_15 != a__goto_1953_9):
                                            __pc = 1
                                            __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        (b__goto_1954_9 = c__goto_1963_13)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        __pc = 1
                                        __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            var __ci_expr_old_0: *mut u8 = p__goto_1955_14
                        (p__goto_1955_14 = p__goto_1955_14 + 1)
                        (i__goto_1952_9 = i__goto_1952_9 + 8)
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            continue
                        if (a__goto_1953_9 >= 0):
                            if (((re.flags & 128) != 0) and ((re.last_codeunit == (a__goto_1953_9 as c_uint)) or ((b__goto_1954_9 >= 0) and (re.last_codeunit == (b__goto_1954_9 as c_uint))))):
                                (re.flags = re.flags & (0 - ((128 | 256)) - 1))
                                if __goto_pending != 0:
                                    continue
                                (re.last_codeunit = 0)
                                if __goto_pending != 0:
                                    continue
                            if __goto_pending != 0:
                                continue
                            (re.first_codeunit = a__goto_1953_9)
                            if __goto_pending != 0:
                                continue
                            (flags__goto_1956_14 = 16)
                            if __goto_pending != 0:
                                continue
                            if (b__goto_1954_9 >= 0):
                                (flags__goto_1956_14 = flags__goto_1956_14 | 32)
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                        (re.flags = re.flags | flags__goto_1956_14)
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if ((((re.flags & ((8192 | 8388608)))) == 0) and (re.top_backref <= 128)):
                    ((&backref_cache__goto_2057_7[0] as *mut c_int)[0] = 0)
                    if __goto_pending != 0:
                        continue
                    (min__goto_2056_7 = find_minlength((re as *const pcre2_real_code_8), (code__goto_1918_14 as *const u8), (code__goto_1918_14 as *const u8), utf__goto_1919_6, (null as *mut recurse_check), (&mut count__goto_1917_5 as *mut c_int), (&backref_cache__goto_2057_7[0] as *mut c_int)))
                    if __goto_pending != 0:
                        continue
                    match min__goto_2056_7:
                        -1 => 0
                        -2 =>
                            return 2
                        -3 =>
                            return 3
                        _ =>
                            (re.minlength = (if (min__goto_2056_7 > 65535): 65535 else: min__goto_2056_7))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                return 0
                if __goto_pending != 0:
                    continue
            _ => break

extern fn _pcre2_valid_utf_8(p0: *const u8, p1: c_ulong, p2: *mut c_ulong) -> c_int
extern fn _pcre2_was_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_xclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: c_int) -> c_int
extern fn _pcre2_eclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int) -> c_int
let SSB_FAIL: c_uint = 0
let SSB_DONE: c_uint = 1
let SSB_CONTINUE: c_uint = 2
let SSB_UNKNOWN: c_uint = 3
let SSB_TOODEEP: c_uint = 4
fn find_minlength(re: *const pcre2_real_code_8, code: *const u8, startcode: *const u8, utf: c_int, recurses: *mut recurse_check, countptr: *mut c_int, backref_cache: *mut c_int) -> c_int:
    var length__goto_106_5: c_int = 0
    var branchlength__goto_107_5: c_int = 0
    var prev_cap_recno__goto_108_5: c_int = 0
    var prev_cap_d__goto_109_5: c_int = 0
    var prev_recurse_recno__goto_110_5: c_int = 0
    var prev_recurse_d__goto_111_5: c_int = 0
    var once_fudge__goto_112_10: c_uint = 0
    var had_recurse__goto_113_6: c_int = 0
    var dupcapused__goto_114_6: c_int = 0
    var nextbranch__goto_115_12: *const u8 = null
    var cc__goto_116_12: *const u8 = null
    var this_recurse__goto_117_15: recurse_check
    var d__goto_137_7: c_int = 0
    var min__goto_137_10: c_int = 0
    var recno__goto_137_15: c_int = 0
    var op__goto_138_15: u8 = 0
    var cs__goto_139_14: *const u8 = null
    var ce__goto_139_18: *const u8 = null
    var count__goto_481_11: c_int = 0
    var slot__goto_482_18: *const u8 = null
    var dd__goto_492_13: c_int = 0
    var i__goto_492_17: c_int = 0
    var r__goto_512_30: *mut recurse_check = null
    var i__goto_554_11: c_int = 0
    var r__goto_571_28: *mut recurse_check = null
    var r__goto_657_24: *mut recurse_check = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc:
            0 =>
                (__goto_pending = 0)
                length__goto_106_5 = -1
                branchlength__goto_107_5 = 0
                prev_cap_recno__goto_108_5 = -1
                prev_cap_d__goto_109_5 = 0
                prev_recurse_recno__goto_110_5 = -1
                prev_recurse_d__goto_111_5 = 0
                once_fudge__goto_112_10 = 0
                had_recurse__goto_113_6 = 0
                dupcapused__goto_114_6 = (if ((re.flags & 2097152)) != 0: 1 else: 0)
                nextbranch__goto_115_12 = (code + ((((((code)[1] << 8)) | (code)[((1) + 1)])) as c_uint))
                cc__goto_116_12 = ((code + (1 as isize as usize)) + (2 as isize as usize))
                if (((unsafe: *code) >= OP_SBRA) and ((unsafe: *code) <= OP_SCOND)):
                    return 0
                if __goto_pending != 0:
                    continue
                if (((unsafe: *code) == OP_CBRA) or ((unsafe: *code) == OP_CBRAPOS)):
                    (cc__goto_116_12 = cc__goto_116_12 + 2)
                if __goto_pending != 0:
                    continue
                var __ci_cond_if_0: bool = false
                var __ci_expr_old_1: c_int = (unsafe: *countptr)
                ((unsafe: *countptr) = (unsafe: *countptr) + 1)
                (__ci_cond_if_0 = ((if __ci_expr_old_1 > 1000: 1 else: 0) != 0))
                if __ci_cond_if_0:
                    return -1
                if __goto_pending != 0:
                    continue
                while true:
                    if (branchlength__goto_107_5 >= 65535):
                        (branchlength__goto_107_5 = 65535)
                        if __goto_pending != 0:
                            break
                        (cc__goto_116_12 = nextbranch__goto_115_12)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    (op__goto_138_15 = (unsafe: *cc__goto_116_12))
                    if __goto_pending != 0:
                        break
                    match op__goto_138_15:
                        OP_COND =>
                            (cs__goto_139_14 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            if ((unsafe: *cs__goto_139_14) != OP_ALT):
                                (cc__goto_116_12 = ((cs__goto_139_14 + (1 as isize as usize)) + (2 as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            __pc = 1
                            __goto_pending = 1
                        OP_SCOND =>
                            (cs__goto_139_14 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            if ((unsafe: *cs__goto_139_14) != OP_ALT):
                                (cc__goto_116_12 = ((cs__goto_139_14 + (1 as isize as usize)) + (2 as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            __pc = 1
                            __goto_pending = 1
                        OP_BRA =>
                            if ((cc__goto_116_12[(1 + 2)] == OP_RECURSE) and (cc__goto_116_12[(2 * ((1 + 2)))] == OP_KET)):
                                (once_fudge__goto_112_10 = 3)
                                if __goto_pending != 0:
                                    break
                                (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                            if (d__goto_137_7 < 0):
                                return d__goto_137_7
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_ONCE =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                            if (d__goto_137_7 < 0):
                                return d__goto_137_7
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_SCRIPT_RUN =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                            if (d__goto_137_7 < 0):
                                return d__goto_137_7
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_SBRA =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                            if (d__goto_137_7 < 0):
                                return d__goto_137_7
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_BRAPOS =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                            if (d__goto_137_7 < 0):
                                return d__goto_137_7
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_SBRAPOS =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                            if (d__goto_137_7 < 0):
                                return d__goto_137_7
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_CBRA =>
                            (recno__goto_137_15 = (((((((cc__goto_116_12)[(1 + 2)] << 8)) | (cc__goto_116_12)[(((1 + 2)) + 1)])) as c_uint) as c_int))
                            if ((dupcapused__goto_114_6 != 0) or (recno__goto_137_15 != prev_cap_recno__goto_108_5)):
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)
                                if __goto_pending != 0:
                                    break
                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                                if __goto_pending != 0:
                                    break
                                if (prev_cap_d__goto_109_5 < 0):
                                    return prev_cap_d__goto_109_5
                                if __goto_pending != 0:
                                    break
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_SCBRA =>
                            (recno__goto_137_15 = (((((((cc__goto_116_12)[(1 + 2)] << 8)) | (cc__goto_116_12)[(((1 + 2)) + 1)])) as c_uint) as c_int))
                            if ((dupcapused__goto_114_6 != 0) or (recno__goto_137_15 != prev_cap_recno__goto_108_5)):
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)
                                if __goto_pending != 0:
                                    break
                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                                if __goto_pending != 0:
                                    break
                                if (prev_cap_d__goto_109_5 < 0):
                                    return prev_cap_d__goto_109_5
                                if __goto_pending != 0:
                                    break
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_CBRAPOS =>
                            (recno__goto_137_15 = (((((((cc__goto_116_12)[(1 + 2)] << 8)) | (cc__goto_116_12)[(((1 + 2)) + 1)])) as c_uint) as c_int))
                            if ((dupcapused__goto_114_6 != 0) or (recno__goto_137_15 != prev_cap_recno__goto_108_5)):
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)
                                if __goto_pending != 0:
                                    break
                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                                if __goto_pending != 0:
                                    break
                                if (prev_cap_d__goto_109_5 < 0):
                                    return prev_cap_d__goto_109_5
                                if __goto_pending != 0:
                                    break
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_SCBRAPOS =>
                            (recno__goto_137_15 = (((((((cc__goto_116_12)[(1 + 2)] << 8)) | (cc__goto_116_12)[(((1 + 2)) + 1)])) as c_uint) as c_int))
                            if ((dupcapused__goto_114_6 != 0) or (recno__goto_137_15 != prev_cap_recno__goto_108_5)):
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)
                                if __goto_pending != 0:
                                    break
                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                                if __goto_pending != 0:
                                    break
                                if (prev_cap_d__goto_109_5 < 0):
                                    return prev_cap_d__goto_109_5
                                if __goto_pending != 0:
                                    break
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_ACCEPT =>
                            return -1
                        OP_ASSERT_ACCEPT =>
                            return -1
                        OP_ALT =>
                            if ((length__goto_106_5 < 0) or ((not ((had_recurse__goto_113_6 != 0))) and (branchlength__goto_107_5 < length__goto_106_5))):
                                (length__goto_106_5 = branchlength__goto_107_5)
                            if ((op__goto_138_15 != OP_ALT) or (length__goto_106_5 == 0)):
                                return length__goto_106_5
                            (nextbranch__goto_115_12 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                            (branchlength__goto_107_5 = 0)
                            (had_recurse__goto_113_6 = 0)
                        OP_KET =>
                            if ((length__goto_106_5 < 0) or ((not ((had_recurse__goto_113_6 != 0))) and (branchlength__goto_107_5 < length__goto_106_5))):
                                (length__goto_106_5 = branchlength__goto_107_5)
                            if ((op__goto_138_15 != OP_ALT) or (length__goto_106_5 == 0)):
                                return length__goto_106_5
                            (nextbranch__goto_115_12 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                            (branchlength__goto_107_5 = 0)
                            (had_recurse__goto_113_6 = 0)
                        OP_KETRMAX =>
                            if ((length__goto_106_5 < 0) or ((not ((had_recurse__goto_113_6 != 0))) and (branchlength__goto_107_5 < length__goto_106_5))):
                                (length__goto_106_5 = branchlength__goto_107_5)
                            if ((op__goto_138_15 != OP_ALT) or (length__goto_106_5 == 0)):
                                return length__goto_106_5
                            (nextbranch__goto_115_12 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                            (branchlength__goto_107_5 = 0)
                            (had_recurse__goto_113_6 = 0)
                        OP_KETRMIN =>
                            if ((length__goto_106_5 < 0) or ((not ((had_recurse__goto_113_6 != 0))) and (branchlength__goto_107_5 < length__goto_106_5))):
                                (length__goto_106_5 = branchlength__goto_107_5)
                            if ((op__goto_138_15 != OP_ALT) or (length__goto_106_5 == 0)):
                                return length__goto_106_5
                            (nextbranch__goto_115_12 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                            (branchlength__goto_107_5 = 0)
                            (had_recurse__goto_113_6 = 0)
                        OP_KETRPOS =>
                            if ((length__goto_106_5 < 0) or ((not ((had_recurse__goto_113_6 != 0))) and (branchlength__goto_107_5 < length__goto_106_5))):
                                (length__goto_106_5 = branchlength__goto_107_5)
                            if ((op__goto_138_15 != OP_ALT) or (length__goto_106_5 == 0)):
                                return length__goto_106_5
                            (nextbranch__goto_115_12 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                            (branchlength__goto_107_5 = 0)
                            (had_recurse__goto_113_6 = 0)
                        OP_END =>
                            if ((length__goto_106_5 < 0) or ((not ((had_recurse__goto_113_6 != 0))) and (branchlength__goto_107_5 < length__goto_106_5))):
                                (length__goto_106_5 = branchlength__goto_107_5)
                            if ((op__goto_138_15 != OP_ALT) or (length__goto_106_5 == 0)):
                                return length__goto_106_5
                            (nextbranch__goto_115_12 = (cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                            (branchlength__goto_107_5 = 0)
                            (had_recurse__goto_113_6 = 0)
                        OP_ASSERT =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_ASSERT_NOT =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_ASSERTBACK =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_ASSERTBACK_NOT =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_ASSERT_NA =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_ASSERT_SCS =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_ASSERTBACK_NA =>
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_REVERSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_VREVERSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DNCREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_RREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DNRREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_FALSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_TRUE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CALLOUT =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_SOD =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_SOM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_EOD =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_EODN =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CIRC =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CIRCM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DOLL =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DOLLM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_NOT_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_NOT_UCP_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_UCP_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CALLOUT_STR =>
                            (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[(1 + (2 * 2))] << 8)) | (cc__goto_116_12)[(((1 + (2 * 2))) + 1)])) as c_uint))
                        OP_BRAZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_BRAMINZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_BRAPOSZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_SKIPZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            while true:
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *cc__goto_116_12) == OP_ALT)):
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))
                        OP_CHAR =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_CHARI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOT =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_PLUS =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_PLUSI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINPLUS =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINPLUSI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSPLUS =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSPLUSI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPLUS =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPLUSI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINPLUS =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINPLUSI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSPLUS =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSPLUSI =>
                            var __ci_expr_old_2: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_TYPEPLUS =>
                            var __ci_expr_old_3: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + (if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)): 4 else: 2))
                        OP_TYPEMINPLUS =>
                            var __ci_expr_old_3: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + (if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)): 4 else: 2))
                        OP_TYPEPOSPLUS =>
                            var __ci_expr_old_3: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            (cc__goto_116_12 = cc__goto_116_12 + (if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)): 4 else: 2))
                        OP_EXACT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_EXACTI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTEXACT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTEXACTI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_TYPEEXACT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            (cc__goto_116_12 = cc__goto_116_12 + ((2 + 2) + ((if ((cc__goto_116_12[(1 + 2)] == OP_PROP) or (cc__goto_116_12[(1 + 2)] == OP_NOTPROP)): 2 else: 0))))
                        OP_PROP =>
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_NOTPROP =>
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_NOT_DIGIT =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_DIGIT =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_NOT_WHITESPACE =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_WHITESPACE =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_NOT_WORDCHAR =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_WORDCHAR =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_ANY =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_ALLANY =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_EXTUNI =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_HSPACE =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_NOT_HSPACE =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_VSPACE =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_NOT_VSPACE =>
                            var __ci_expr_old_4: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_5: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_ANYNL =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_6: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_ANYBYTE =>
                            if (utf != 0):
                                return -1
                            var __ci_expr_old_7: c_int = branchlength__goto_107_5
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            var __ci_expr_old_8: *const u8 = cc__goto_116_12
                            (cc__goto_116_12 = cc__goto_116_12 + 1)
                        OP_TYPESTAR =>
                            if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEMINSTAR =>
                            if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEQUERY =>
                            if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEMINQUERY =>
                            if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEPOSSTAR =>
                            if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEPOSQUERY =>
                            if ((cc__goto_116_12[1] == OP_PROP) or (cc__goto_116_12[1] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEUPTO =>
                            if ((cc__goto_116_12[(1 + 2)] == OP_PROP) or (cc__goto_116_12[(1 + 2)] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEMINUPTO =>
                            if ((cc__goto_116_12[(1 + 2)] == OP_PROP) or (cc__goto_116_12[(1 + 2)] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_TYPEPOSUPTO =>
                            if ((cc__goto_116_12[(1 + 2)] == OP_PROP) or (cc__goto_116_12[(1 + 2)] == OP_NOTPROP)):
                                (cc__goto_116_12 = cc__goto_116_12 + 2)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_CLASS =>
                            if ((op__goto_138_15 == OP_XCLASS) or (op__goto_138_15 == OP_ECLASS)):
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            else:
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                _ =>
                                    var __ci_expr_old_11: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                        OP_NCLASS =>
                            if ((op__goto_138_15 == OP_XCLASS) or (op__goto_138_15 == OP_ECLASS)):
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            else:
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                _ =>
                                    var __ci_expr_old_11: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                        OP_XCLASS =>
                            if ((op__goto_138_15 == OP_XCLASS) or (op__goto_138_15 == OP_ECLASS)):
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            else:
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                _ =>
                                    var __ci_expr_old_11: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                        OP_ECLASS =>
                            if ((op__goto_138_15 == OP_XCLASS) or (op__goto_138_15 == OP_ECLASS)):
                                (cc__goto_116_12 = cc__goto_116_12 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            else:
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSPLUS =>
                                    var __ci_expr_old_9: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    var __ci_expr_old_10: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                _ =>
                                    var __ci_expr_old_11: c_int = branchlength__goto_107_5
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                        OP_DNREF =>
                            if ((not ((dupcapused__goto_114_6 != 0))) and (((re.overall_options & 512)) == 0)):
                                count__goto_481_11 = ((((((cc__goto_116_12)[(1 + 2)] << 8)) | (cc__goto_116_12)[(((1 + 2)) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                slot__goto_482_18 = ((((re as *const u8) + sizeof[pcre2_real_code_8]())) + (((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint) *% re.name_entry_size))
                                if __goto_pending != 0:
                                    break
                                (d__goto_137_7 = 2147483647)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    var __ci_cond_while_13: bool = false
                                    var __ci_expr_old_14: c_int = count__goto_481_11
                                    (count__goto_481_11 = count__goto_481_11 - 1)
                                    (__ci_cond_while_13 = ((if __ci_expr_old_14 > 0: 1 else: 0) != 0))
                                    if not (__ci_cond_while_13):
                                        break
                                    (recno__goto_137_15 = ((((((slot__goto_482_18)[0] << 8)) | (slot__goto_482_18)[((0) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if ((recno__goto_137_15 <= backref_cache[0]) and (backref_cache[recno__goto_137_15] >= 0)):
                                        (dd__goto_492_13 = backref_cache[recno__goto_137_15])
                                    else:
                                        (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))
                                        (ce__goto_139_18 = cs__goto_139_14)
                                        if __goto_pending != 0:
                                            break
                                        if (cs__goto_139_14 == (null as *const u8)):
                                            return -2
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            (ce__goto_139_18 = ce__goto_139_18 + ((((((ce__goto_139_18)[1] << 8)) | (ce__goto_139_18)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *ce__goto_139_18) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (dd__goto_492_13 = 0)
                                        if __goto_pending != 0:
                                            break
                                        if ((not ((dupcapused__goto_114_6 != 0))) or (_pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == (null as *const u8))):
                                            if ((cc__goto_116_12 > cs__goto_139_14) and (cc__goto_116_12 < ce__goto_139_18)):
                                                (had_recurse__goto_113_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                r__goto_512_30 = recurses
                                                if __goto_pending != 0:
                                                    break
                                                (r__goto_512_30 = recurses)
                                                while (r__goto_512_30 != (null as *mut recurse_check)):
                                                    if (r__goto_512_30.group == cs__goto_139_14):
                                                        break
                                                    (r__goto_512_30 = r__goto_512_30.prev)
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                                if (r__goto_512_30 != (null as *mut recurse_check)):
                                                    (had_recurse__goto_113_6 = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    (this_recurse__goto_117_15.prev = recurses)
                                                    if __goto_pending != 0:
                                                        break
                                                    (this_recurse__goto_117_15.group = cs__goto_139_14)
                                                    if __goto_pending != 0:
                                                        break
                                                    (dd__goto_492_13 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))
                                                    if __goto_pending != 0:
                                                        break
                                                    if (dd__goto_492_13 < 0):
                                                        return dd__goto_492_13
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (backref_cache[recno__goto_137_15] = dd__goto_492_13)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_492_17 = (backref_cache[0] + 1))
                                        while (i__goto_492_17 < recno__goto_137_15):
                                            (backref_cache[i__goto_492_17] = -1)
                                            var __ci_expr_old_12: c_int = i__goto_492_17
                                        (i__goto_492_17 = i__goto_492_17 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (backref_cache[0] = recno__goto_137_15)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (dd__goto_492_13 < d__goto_137_7):
                                        (d__goto_137_7 = dd__goto_492_13)
                                    if __goto_pending != 0:
                                        break
                                    if (d__goto_137_7 <= 0):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    (slot__goto_482_18 = slot__goto_482_18 + re.name_entry_size)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            else:
                                (d__goto_137_7 = 0)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            __pc = 2
                            __goto_pending = 1
                        OP_DNREFI =>
                            if ((not ((dupcapused__goto_114_6 != 0))) and (((re.overall_options & 512)) == 0)):
                                count__goto_481_11 = ((((((cc__goto_116_12)[(1 + 2)] << 8)) | (cc__goto_116_12)[(((1 + 2)) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                slot__goto_482_18 = ((((re as *const u8) + sizeof[pcre2_real_code_8]())) + (((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint) *% re.name_entry_size))
                                if __goto_pending != 0:
                                    break
                                (d__goto_137_7 = 2147483647)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    var __ci_cond_while_13: bool = false
                                    var __ci_expr_old_14: c_int = count__goto_481_11
                                    (count__goto_481_11 = count__goto_481_11 - 1)
                                    (__ci_cond_while_13 = ((if __ci_expr_old_14 > 0: 1 else: 0) != 0))
                                    if not (__ci_cond_while_13):
                                        break
                                    (recno__goto_137_15 = ((((((slot__goto_482_18)[0] << 8)) | (slot__goto_482_18)[((0) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if ((recno__goto_137_15 <= backref_cache[0]) and (backref_cache[recno__goto_137_15] >= 0)):
                                        (dd__goto_492_13 = backref_cache[recno__goto_137_15])
                                    else:
                                        (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))
                                        (ce__goto_139_18 = cs__goto_139_14)
                                        if __goto_pending != 0:
                                            break
                                        if (cs__goto_139_14 == (null as *const u8)):
                                            return -2
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            (ce__goto_139_18 = ce__goto_139_18 + ((((((ce__goto_139_18)[1] << 8)) | (ce__goto_139_18)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *ce__goto_139_18) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (dd__goto_492_13 = 0)
                                        if __goto_pending != 0:
                                            break
                                        if ((not ((dupcapused__goto_114_6 != 0))) or (_pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == (null as *const u8))):
                                            if ((cc__goto_116_12 > cs__goto_139_14) and (cc__goto_116_12 < ce__goto_139_18)):
                                                (had_recurse__goto_113_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                r__goto_512_30 = recurses
                                                if __goto_pending != 0:
                                                    break
                                                (r__goto_512_30 = recurses)
                                                while (r__goto_512_30 != (null as *mut recurse_check)):
                                                    if (r__goto_512_30.group == cs__goto_139_14):
                                                        break
                                                    (r__goto_512_30 = r__goto_512_30.prev)
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                                if (r__goto_512_30 != (null as *mut recurse_check)):
                                                    (had_recurse__goto_113_6 = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    (this_recurse__goto_117_15.prev = recurses)
                                                    if __goto_pending != 0:
                                                        break
                                                    (this_recurse__goto_117_15.group = cs__goto_139_14)
                                                    if __goto_pending != 0:
                                                        break
                                                    (dd__goto_492_13 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))
                                                    if __goto_pending != 0:
                                                        break
                                                    if (dd__goto_492_13 < 0):
                                                        return dd__goto_492_13
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (backref_cache[recno__goto_137_15] = dd__goto_492_13)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_492_17 = (backref_cache[0] + 1))
                                        while (i__goto_492_17 < recno__goto_137_15):
                                            (backref_cache[i__goto_492_17] = -1)
                                            var __ci_expr_old_12: c_int = i__goto_492_17
                                        (i__goto_492_17 = i__goto_492_17 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (backref_cache[0] = recno__goto_137_15)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (dd__goto_492_13 < d__goto_137_7):
                                        (d__goto_137_7 = dd__goto_492_13)
                                    if __goto_pending != 0:
                                        break
                                    if (d__goto_137_7 <= 0):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    (slot__goto_482_18 = slot__goto_482_18 + re.name_entry_size)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            else:
                                (d__goto_137_7 = 0)
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            __pc = 2
                            __goto_pending = 1
                        OP_REF =>
                            (recno__goto_137_15 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            if ((recno__goto_137_15 <= backref_cache[0]) and (backref_cache[recno__goto_137_15] >= 0)):
                                (d__goto_137_7 = backref_cache[recno__goto_137_15])
                            else:
                                (d__goto_137_7 = 0)
                                if __goto_pending != 0:
                                    break
                                if (((re.overall_options & 512)) == 0):
                                    (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))
                                    (ce__goto_139_18 = cs__goto_139_14)
                                    if __goto_pending != 0:
                                        break
                                    if (cs__goto_139_14 == (null as *const u8)):
                                        return -2
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (ce__goto_139_18 = ce__goto_139_18 + ((((((ce__goto_139_18)[1] << 8)) | (ce__goto_139_18)[((1) + 1)])) as c_uint))
                                        if __goto_pending != 0:
                                            break
                                        if not (((unsafe: *ce__goto_139_18) == OP_ALT)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if ((not ((dupcapused__goto_114_6 != 0))) or (_pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == (null as *const u8))):
                                        if ((cc__goto_116_12 > cs__goto_139_14) and (cc__goto_116_12 < ce__goto_139_18)):
                                            (had_recurse__goto_113_6 = 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            r__goto_571_28 = recurses
                                            if __goto_pending != 0:
                                                break
                                            (r__goto_571_28 = recurses)
                                            while (r__goto_571_28 != (null as *mut recurse_check)):
                                                if (r__goto_571_28.group == cs__goto_139_14):
                                                    break
                                                (r__goto_571_28 = r__goto_571_28.prev)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if (r__goto_571_28 != (null as *mut recurse_check)):
                                                (had_recurse__goto_113_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                (this_recurse__goto_117_15.prev = recurses)
                                                if __goto_pending != 0:
                                                    break
                                                (this_recurse__goto_117_15.group = cs__goto_139_14)
                                                if __goto_pending != 0:
                                                    break
                                                (d__goto_137_7 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))
                                                if __goto_pending != 0:
                                                    break
                                                if (d__goto_137_7 < 0):
                                                    return d__goto_137_7
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (backref_cache[recno__goto_137_15] = d__goto_137_7)
                                if __goto_pending != 0:
                                    break
                                (i__goto_554_11 = (backref_cache[0] + 1))
                                while (i__goto_554_11 < recno__goto_137_15):
                                    (backref_cache[i__goto_554_11] = -1)
                                    var __ci_expr_old_15: c_int = i__goto_554_11
                                (i__goto_554_11 = i__goto_554_11 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (backref_cache[0] = recno__goto_137_15)
                                if __goto_pending != 0:
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            match (unsafe: *cc__goto_116_12):
                                OP_CRSTAR =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPLUS =>
                                    (min__goto_137_10 = 1)
                                    var __ci_expr_old_17: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINPLUS =>
                                    (min__goto_137_10 = 1)
                                    var __ci_expr_old_17: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSPLUS =>
                                    (min__goto_137_10 = 1)
                                    var __ci_expr_old_17: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (min__goto_137_10 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRMINRANGE =>
                                    (min__goto_137_10 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRPOSRANGE =>
                                    (min__goto_137_10 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                _ =>
                                    (min__goto_137_10 = 1)
                            if (((d__goto_137_7 > 0) and (((2147483647 / d__goto_137_7)) < min__goto_137_10)) or ((65535 - branchlength__goto_107_5) < (min__goto_137_10 * d__goto_137_7))):
                                (branchlength__goto_107_5 = 65535)
                            else:
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (min__goto_137_10 * d__goto_137_7))
                        OP_REFI =>
                            (recno__goto_137_15 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                            if ((recno__goto_137_15 <= backref_cache[0]) and (backref_cache[recno__goto_137_15] >= 0)):
                                (d__goto_137_7 = backref_cache[recno__goto_137_15])
                            else:
                                (d__goto_137_7 = 0)
                                if __goto_pending != 0:
                                    break
                                if (((re.overall_options & 512)) == 0):
                                    (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))
                                    (ce__goto_139_18 = cs__goto_139_14)
                                    if __goto_pending != 0:
                                        break
                                    if (cs__goto_139_14 == (null as *const u8)):
                                        return -2
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (ce__goto_139_18 = ce__goto_139_18 + ((((((ce__goto_139_18)[1] << 8)) | (ce__goto_139_18)[((1) + 1)])) as c_uint))
                                        if __goto_pending != 0:
                                            break
                                        if not (((unsafe: *ce__goto_139_18) == OP_ALT)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if ((not ((dupcapused__goto_114_6 != 0))) or (_pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == (null as *const u8))):
                                        if ((cc__goto_116_12 > cs__goto_139_14) and (cc__goto_116_12 < ce__goto_139_18)):
                                            (had_recurse__goto_113_6 = 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            r__goto_571_28 = recurses
                                            if __goto_pending != 0:
                                                break
                                            (r__goto_571_28 = recurses)
                                            while (r__goto_571_28 != (null as *mut recurse_check)):
                                                if (r__goto_571_28.group == cs__goto_139_14):
                                                    break
                                                (r__goto_571_28 = r__goto_571_28.prev)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if (r__goto_571_28 != (null as *mut recurse_check)):
                                                (had_recurse__goto_113_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                (this_recurse__goto_117_15.prev = recurses)
                                                if __goto_pending != 0:
                                                    break
                                                (this_recurse__goto_117_15.group = cs__goto_139_14)
                                                if __goto_pending != 0:
                                                    break
                                                (d__goto_137_7 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))
                                                if __goto_pending != 0:
                                                    break
                                                if (d__goto_137_7 < 0):
                                                    return d__goto_137_7
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (backref_cache[recno__goto_137_15] = d__goto_137_7)
                                if __goto_pending != 0:
                                    break
                                (i__goto_554_11 = (backref_cache[0] + 1))
                                while (i__goto_554_11 < recno__goto_137_15):
                                    (backref_cache[i__goto_554_11] = -1)
                                    var __ci_expr_old_15: c_int = i__goto_554_11
                                (i__goto_554_11 = i__goto_554_11 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (backref_cache[0] = recno__goto_137_15)
                                if __goto_pending != 0:
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                            match (unsafe: *cc__goto_116_12):
                                OP_CRSTAR =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    (min__goto_137_10 = 0)
                                    var __ci_expr_old_16: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPLUS =>
                                    (min__goto_137_10 = 1)
                                    var __ci_expr_old_17: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINPLUS =>
                                    (min__goto_137_10 = 1)
                                    var __ci_expr_old_17: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSPLUS =>
                                    (min__goto_137_10 = 1)
                                    var __ci_expr_old_17: *const u8 = cc__goto_116_12
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (min__goto_137_10 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRMINRANGE =>
                                    (min__goto_137_10 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                OP_CRPOSRANGE =>
                                    (min__goto_137_10 = ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint))
                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))
                                _ =>
                                    (min__goto_137_10 = 1)
                            if (((d__goto_137_7 > 0) and (((2147483647 / d__goto_137_7)) < min__goto_137_10)) or ((65535 - branchlength__goto_107_5) < (min__goto_137_10 * d__goto_137_7))):
                                (branchlength__goto_107_5 = 65535)
                            else:
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (min__goto_137_10 * d__goto_137_7))
                        OP_RECURSE =>
                            (ce__goto_139_18 = (startcode + ((((((cc__goto_116_12)[1] << 8)) | (cc__goto_116_12)[((1) + 1)])) as c_uint)))
                            (cs__goto_139_14 = ce__goto_139_18)
                            (recno__goto_137_15 = ((((((cs__goto_139_14)[(1 + 2)] << 8)) | (cs__goto_139_14)[(((1 + 2)) + 1)])) as c_uint))
                            if (recno__goto_137_15 == prev_recurse_recno__goto_110_5):
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_recurse_d__goto_111_5)
                                if __goto_pending != 0:
                                    break
                            else:
                                while true:
                                    (ce__goto_139_18 = ce__goto_139_18 + ((((((ce__goto_139_18)[1] << 8)) | (ce__goto_139_18)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *ce__goto_139_18) == OP_ALT)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((cc__goto_116_12 > cs__goto_139_14) and (cc__goto_116_12 < ce__goto_139_18)):
                                    (had_recurse__goto_113_6 = 1)
                                else:
                                    r__goto_657_24 = recurses
                                    if __goto_pending != 0:
                                        break
                                    (r__goto_657_24 = recurses)
                                    while (r__goto_657_24 != (null as *mut recurse_check)):
                                        if (r__goto_657_24.group == cs__goto_139_14):
                                            break
                                        (r__goto_657_24 = r__goto_657_24.prev)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (r__goto_657_24 != (null as *mut recurse_check)):
                                        (had_recurse__goto_113_6 = 1)
                                    else:
                                        (this_recurse__goto_117_15.prev = recurses)
                                        if __goto_pending != 0:
                                            break
                                        (this_recurse__goto_117_15.group = cs__goto_139_14)
                                        if __goto_pending != 0:
                                            break
                                        (prev_recurse_d__goto_111_5 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))
                                        if __goto_pending != 0:
                                            break
                                        if (prev_recurse_d__goto_111_5 < 0):
                                            return prev_recurse_d__goto_111_5
                                        if __goto_pending != 0:
                                            break
                                        (prev_recurse_recno__goto_110_5 = recno__goto_137_15)
                                        if __goto_pending != 0:
                                            break
                                        (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_recurse_d__goto_111_5)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            (cc__goto_116_12 = cc__goto_116_12 + (3 +% once_fudge__goto_112_10))
                            (once_fudge__goto_112_10 = 0)
                        OP_UPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_UPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_STAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_STARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_QUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_QUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MINQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTMINQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_POSQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_NOTPOSQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                            if ((utf != 0) and ((cc__goto_116_12[-1]) >= 192)):
                                (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_utf8_table4[((cc__goto_116_12[-1]) & 63)]))
                        OP_MARK =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + cc__goto_116_12[1]))
                        OP_COMMIT_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + cc__goto_116_12[1]))
                        OP_PRUNE_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + cc__goto_116_12[1]))
                        OP_SKIP_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + cc__goto_116_12[1]))
                        OP_THEN_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + cc__goto_116_12[1]))
                        OP_CLOSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_COMMIT =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_FAIL =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_PRUNE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_SET_SOM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_SKIP =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_THEN =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        _ =>
                            return -3
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                return -3
                if __goto_pending != 0:
                    continue
            _ => break

fn set_table_bit(re: *mut pcre2_real_code_8, __param_p: *const u8, caseless: c_int, utf: c_int, ucp: c_int) -> *const u8:
    var p = __param_p
    var c: c_uint = with 0 as __ci_expr_seq_1:
        var __ci_expr_old_0: *const u8 = p
        (p = p + 1)
        (unsafe: *__ci_expr_old_0)

    utf

    ucp

    re.start_bitmap[((c) / 8)] = re.start_bitmap[((c) / 8)] | ((1 << (((c) & 7))))

    if (utf != 0):
        if (c >= 192):
            if (((c & 32)) == 0):
                var __ci_expr_old_2: *const u8 = p
                (p = p + 1)
                (c = (((((c & 31)) << 6)) | (((unsafe: *__ci_expr_old_2) & 63))))
            else:
                if (((c & 16)) == 0):
                    (c = ((((((c & 15)) << 12)) | (((((unsafe: *p) & 63)) << 6))) | ((p[1] & 63))))
                    
                    p = p + 2
                    
                else:
                    if (((c & 8)) == 0):
                        (c = (((((((c & 7)) << 18)) | (((((unsafe: *p) & 63)) << 12))) | ((((p[1] & 63)) << 6))) | ((p[2] & 63))))
                        
                        p = p + 3
                        
                    else:
                        if (((c & 4)) == 0):
                            (c = ((((((((c & 3)) << 24)) | (((((unsafe: *p) & 63)) << 18))) | ((((p[1] & 63)) << 12))) | ((((p[2] & 63)) << 6))) | ((p[3] & 63))))
                            
                            p = p + 4
                            
                        else:
                            (c = (((((((((c & 1)) << 30)) | (((((unsafe: *p) & 63)) << 24))) | ((((p[1] & 63)) << 18))) | ((((p[2] & 63)) << 12))) | ((((p[3] & 63)) << 6))) | ((p[4] & 63))))
                            
                            p = p + 5
                            
            
        

    if (caseless != 0):
        if ((utf != 0) or (ucp != 0)):
            (c = (((((c as c_int) + ((((&_pcre2_ucd_records_8[0] as *mut ucd_record) + (_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(((c) as c_int) / 128)] * 128) + (((c) as c_int) % 128))] as isize as usize))).other_case))) as c_uint)))
            
            if (utf != 0):
                var buff: [6]u8
                
                _pcre2_ord2utf_8(c, (&buff[0] as *mut u8))
                
                re.start_bitmap[((buff[0]) / 8)] = re.start_bitmap[((buff[0]) / 8)] | ((1 << (((buff[0]) & 7))))
                
            else:
                if (c < 256):
                    re.start_bitmap[((c) / 8)] = re.start_bitmap[((c) / 8)] | ((1 << (((c) & 7))))
            
        else:
            if (1 != 0):
                re.start_bitmap[((re.tables[(256 +% c)]) / 8)] = re.start_bitmap[((re.tables[(256 +% c)]) / 8)] | ((1 << (((re.tables[(256 +% c)]) & 7))))
        

    return p


fn set_type_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint):
    var c: c_uint

    (c = 0)
    
    while (c < table_limit):
        re.start_bitmap[c] = re.start_bitmap[c] | re.tables[((c +% 512) +% cbit_type)]
        
        var __ci_expr_old_0: c_uint = c
        (c = c + 1)
        
    

    if (table_limit == 32):
        return

    (c = 128)
    
    while (c < 256):
        if (((re.tables[(512 +% (c / 8))] & ((1 << ((c & 7)))))) != 0):
            var buff: [6]u8
            
            _pcre2_ord2utf_8(c, (&buff[0] as *mut u8))
            
            re.start_bitmap[((buff[0]) / 8)] = re.start_bitmap[((buff[0]) / 8)] | ((1 << (((buff[0]) & 7))))
            
        
        
        var __ci_expr_old_1: c_uint = c
        (c = c + 1)
        
    


fn set_nottype_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint):
    var c: c_uint

    (c = 0)
    
    while (c < table_limit):
        re.start_bitmap[c] = re.start_bitmap[c] | (((0 - (re.tables[((c +% 512) +% cbit_type)]) - 1)) as u8)
        
        var __ci_expr_old_0: c_uint = c
        (c = c + 1)
        
    

    if (table_limit != 32):
        (c = 24)
        
        while (c < 32):
            (re.start_bitmap[c] = 255)
            
            var __ci_expr_old_1: c_uint = c
            (c = c + 1)
            
        


fn study_char_list(__param_code: *const u8, start_bitmap: *mut u8, char_lists_end: *const u8):
    var code = __param_code
    var type_: c_uint
    var list_ind: c_uint

    var char_list_add: c_uint = 0

    var range_start: c_uint = (0 - (0 as c_uint) - 1)
    var range_end: c_uint = 0

    var next_char: *const u8

    var start_buffer: [6]u8
    var end_buffer: [6]u8

    var start: u8
    var end: u8

    (type_ = ((((code[0] << 8)) as c_uint) | code[1]))

    code = code + 2

    (next_char = (char_lists_end - ((((((((code)[0] << 8)) | (code)[((0) + 1)])) as c_uint) << 1))))

    type_ = type_ & 4095

    (list_ind = 0)

    if (((type_ & 4)) != 0):
        (range_start = 256)

    while (type_ > 0):
        var item_count: c_uint = (type_ & 3)
        
        if (item_count == 3):
            if (list_ind <= 1):
                (item_count = (unsafe: *(next_char as *const c_ushort)))
                
                next_char = next_char + 2
                
            else:
                (item_count = (unsafe: *(next_char as *const c_uint)))
                
                next_char = next_char + 4
                
            
        
        while (item_count > 0):
            if (list_ind <= 1):
                (range_end = (unsafe: *(next_char as *const c_ushort)))
                
                next_char = next_char + 2
                
            else:
                (range_end = (unsafe: *(next_char as *const c_uint)))
                
                next_char = next_char + 4
                
            
            if (((range_end & 1)) != 0):
                (range_end = (char_list_add +% ((range_end >> 1))))
                
                _pcre2_ord2utf_8(range_end, (&end_buffer[0] as *mut u8))
                
                (end = end_buffer[0])
                
                if (range_start < range_end):
                    _pcre2_ord2utf_8(range_start, (&start_buffer[0] as *mut u8))
                    
                    (start = start_buffer[0])
                    
                    while (start <= end):
                        start_bitmap[(start / 8)] = start_bitmap[(start / 8)] | ((1 << ((start & 7))))
                        
                        var __ci_expr_old_0: u8 = start
                        (start = start + 1)
                        
                    
                    
                else:
                    start_bitmap[(end / 8)] = start_bitmap[(end / 8)] | ((1 << ((end & 7))))
                
                (range_start = (0 - (0 as c_uint) - 1))
                
            else:
                (range_start = (char_list_add +% ((range_end >> 1))))
            
            (item_count = item_count - 1)
            
        
        (list_ind = list_ind + 1)
        
        type_ = type_ >> 3
        
        if (range_start == (0 - (0 as c_uint) - 1)):
            if (((type_ & 4)) != 0):
                if (list_ind == 1):
                    (range_start = 32768)
                else:
                    (range_start = 65536)
                
            
        else:
            if (((type_ & 4)) == 0):
                _pcre2_ord2utf_8(range_start, (&start_buffer[0] as *mut u8))
                
                if (list_ind == 1):
                    (range_end = 32767)
                else:
                    (range_end = 65535)
                
                _pcre2_ord2utf_8(range_end, (&end_buffer[0] as *mut u8))
                
                (end = end_buffer[0])
                
                (start = start_buffer[0])
                
                while (start <= end):
                    start_bitmap[(start / 8)] = start_bitmap[(start / 8)] | ((1 << ((start & 7))))
                    
                    var __ci_expr_old_1: u8 = start
                    (start = start + 1)
                    
                
                
                (range_start = (0 - (0 as c_uint) - 1))
                
        
        if (list_ind == 1):
            (char_list_add = 32768)
        else:
            (char_list_add = 0)
        


fn set_start_bits(re: *mut pcre2_real_code_8, __param_code: *const u8, utf: c_int, ucp: c_int, depthptr: *mut c_int) -> c_int:
    var code = __param_code
    var c__goto_1096_10: c_uint = 0
    var yield___goto_1097_5: c_int = 0
    var table_limit__goto_1100_5: c_int = 0
    var try_next__goto_1110_8: c_int = 0
    var tcode__goto_1111_14: *const u8 = null
    var rc__goto_1118_9: c_int = 0
    var ncode__goto_1119_16: *const u8 = null
    var classmap__goto_1120_20: *const u8 = null
    var xclassflags__goto_1122_17: u8 = 0
    var p__goto_1225_25: *const c_uint = null
    var buff__goto_1231_25: [6]u8 = [0 as u8; 6]
    var done__goto_1264_17: c_int = 0
    var b__goto_1749_21: u8 = 0
    var e__goto_1749_24: u8 = 0
    var p__goto_1750_20: *const u8 = null
    var d__goto_1845_19: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc:
            0 =>
                (__goto_pending = 0)
                yield___goto_1097_5 = SSB_DONE
                table_limit__goto_1100_5 = (if (utf != 0): 16 else: 32)
                ((unsafe: *depthptr) = (unsafe: *depthptr) + 1)
                if __goto_pending != 0:
                    continue
                if ((unsafe: *depthptr) > 1000):
                    return SSB_TOODEEP
                if __goto_pending != 0:
                    continue
                while true:
                    try_next__goto_1110_8 = 1
                    if __goto_pending != 0:
                        break
                    tcode__goto_1111_14 = ((code + (1 as isize as usize)) + (2 as isize as usize))
                    if __goto_pending != 0:
                        break
                    if (((((unsafe: *code) == OP_CBRA) or ((unsafe: *code) == OP_SCBRA)) or ((unsafe: *code) == OP_CBRAPOS)) or ((unsafe: *code) == OP_SCBRAPOS)):
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                    if __goto_pending != 0:
                        break
                    while (try_next__goto_1110_8 != 0):
                        classmap__goto_1120_20 = ((null as *const u8) as *const u8)
                        if __goto_pending != 0:
                            break
                        match (unsafe: *tcode__goto_1111_14):
                            OP_ACCEPT =>
                                return SSB_FAIL
                            OP_ASSERT_ACCEPT =>
                                return SSB_FAIL
                            OP_ALLANY =>
                                return SSB_FAIL
                            OP_ANY =>
                                return SSB_FAIL
                            OP_ANYBYTE =>
                                return SSB_FAIL
                            OP_CIRCM =>
                                return SSB_FAIL
                            OP_CLOSE =>
                                return SSB_FAIL
                            OP_COMMIT =>
                                return SSB_FAIL
                            OP_COMMIT_ARG =>
                                return SSB_FAIL
                            OP_COND =>
                                return SSB_FAIL
                            OP_CREF =>
                                return SSB_FAIL
                            OP_FALSE =>
                                return SSB_FAIL
                            OP_TRUE =>
                                return SSB_FAIL
                            OP_DNCREF =>
                                return SSB_FAIL
                            OP_DNREF =>
                                return SSB_FAIL
                            OP_DNREFI =>
                                return SSB_FAIL
                            OP_DNRREF =>
                                return SSB_FAIL
                            OP_DOLL =>
                                return SSB_FAIL
                            OP_DOLLM =>
                                return SSB_FAIL
                            OP_END =>
                                return SSB_FAIL
                            OP_EOD =>
                                return SSB_FAIL
                            OP_EODN =>
                                return SSB_FAIL
                            OP_EXTUNI =>
                                return SSB_FAIL
                            OP_FAIL =>
                                return SSB_FAIL
                            OP_MARK =>
                                return SSB_FAIL
                            OP_NOT =>
                                return SSB_FAIL
                            OP_NOTEXACT =>
                                return SSB_FAIL
                            OP_NOTEXACTI =>
                                return SSB_FAIL
                            OP_NOTI =>
                                return SSB_FAIL
                            OP_NOTMINPLUS =>
                                return SSB_FAIL
                            OP_NOTMINPLUSI =>
                                return SSB_FAIL
                            OP_NOTMINQUERY =>
                                return SSB_FAIL
                            OP_NOTMINQUERYI =>
                                return SSB_FAIL
                            OP_NOTMINSTAR =>
                                return SSB_FAIL
                            OP_NOTMINSTARI =>
                                return SSB_FAIL
                            OP_NOTMINUPTO =>
                                return SSB_FAIL
                            OP_NOTMINUPTOI =>
                                return SSB_FAIL
                            OP_NOTPLUS =>
                                return SSB_FAIL
                            OP_NOTPLUSI =>
                                return SSB_FAIL
                            OP_NOTPOSPLUS =>
                                return SSB_FAIL
                            OP_NOTPOSPLUSI =>
                                return SSB_FAIL
                            OP_NOTPOSQUERY =>
                                return SSB_FAIL
                            OP_NOTPOSQUERYI =>
                                return SSB_FAIL
                            OP_NOTPOSSTAR =>
                                return SSB_FAIL
                            OP_NOTPOSSTARI =>
                                return SSB_FAIL
                            OP_NOTPOSUPTO =>
                                return SSB_FAIL
                            OP_NOTPOSUPTOI =>
                                return SSB_FAIL
                            OP_NOTPROP =>
                                return SSB_FAIL
                            OP_NOTQUERY =>
                                return SSB_FAIL
                            OP_NOTQUERYI =>
                                return SSB_FAIL
                            OP_NOTSTAR =>
                                return SSB_FAIL
                            OP_NOTSTARI =>
                                return SSB_FAIL
                            OP_NOTUPTO =>
                                return SSB_FAIL
                            OP_NOTUPTOI =>
                                return SSB_FAIL
                            OP_NOT_HSPACE =>
                                return SSB_FAIL
                            OP_NOT_VSPACE =>
                                return SSB_FAIL
                            OP_PRUNE =>
                                return SSB_FAIL
                            OP_PRUNE_ARG =>
                                return SSB_FAIL
                            OP_RECURSE =>
                                return SSB_FAIL
                            OP_REF =>
                                return SSB_FAIL
                            OP_REFI =>
                                return SSB_FAIL
                            OP_REVERSE =>
                                return SSB_FAIL
                            OP_VREVERSE =>
                                return SSB_FAIL
                            OP_RREF =>
                                return SSB_FAIL
                            OP_SCOND =>
                                return SSB_FAIL
                            OP_SET_SOM =>
                                return SSB_FAIL
                            OP_SKIP =>
                                return SSB_FAIL
                            OP_SKIP_ARG =>
                                return SSB_FAIL
                            OP_SOD =>
                                return SSB_FAIL
                            OP_SOM =>
                                return SSB_FAIL
                            OP_THEN =>
                                return SSB_FAIL
                            OP_THEN_ARG =>
                                return SSB_FAIL
                            OP_CIRC =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + _pcre2_OP_lengths_8[OP_CIRC])
                            OP_PROP =>
                                if (tcode__goto_1111_14[1] != 9):
                                    return SSB_FAIL
                                p__goto_1225_25 = ((&_pcre2_ucd_caseless_sets_8[0] as *mut c_uint) + (tcode__goto_1111_14[2] as isize as usize))
                                if __goto_pending != 0:
                                    break
                                while true:
                                    var __ci_cond_while_0: bool = false
                                    var __ci_expr_old_1: *const c_uint = p__goto_1225_25
                                    (p__goto_1225_25 = p__goto_1225_25 + 1)
                                    (c__goto_1096_10 = (unsafe: *__ci_expr_old_1))
                                    (__ci_cond_while_0 = ((if (c__goto_1096_10) < 4294967295: 1 else: 0) != 0))
                                    if not (__ci_cond_while_0):
                                        break
                                    if (utf != 0):
                                        _pcre2_ord2utf_8(c__goto_1096_10, (&buff__goto_1231_25[0] as *mut u8))
                                        if __goto_pending != 0:
                                            break
                                        (c__goto_1096_10 = (&buff__goto_1231_25[0] as *mut u8)[0])
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (c__goto_1096_10 > 255):
                                        ((&re.start_bitmap[0] as *mut u8)[((255) / 8)] = (&re.start_bitmap[0] as *mut u8)[((255) / 8)] | ((1 << (((255) & 7)))))
                                    else:
                                        ((&re.start_bitmap[0] as *mut u8)[((c__goto_1096_10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((c__goto_1096_10) / 8)] | ((1 << (((c__goto_1096_10) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (try_next__goto_1110_8 = 0)
                            OP_WORD_BOUNDARY =>
                                var __ci_expr_old_2: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_NOT_WORD_BOUNDARY =>
                                var __ci_expr_old_2: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_UCP_WORD_BOUNDARY =>
                                var __ci_expr_old_2: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_NOT_UCP_WORD_BOUNDARY =>
                                var __ci_expr_old_2: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_ASSERT =>
                                (ncode__goto_1119_16 = (tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint)))
                                while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                done__goto_1264_17 = 0
                                while (not ((done__goto_1264_17 != 0))):
                                    match (unsafe: *ncode__goto_1119_16):
                                        OP_ASSERT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERT_NOT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERTBACK =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERTBACK_NOT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERT_NA =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERTBACK_NA =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERT_SCS =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_NOT_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_UCP_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_NOT_UCP_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_CALLOUT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + _pcre2_OP_lengths_8[OP_CALLOUT])
                                        OP_CALLOUT_STR =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[(1 + (2 * 2))] << 8)) | (ncode__goto_1119_16)[(((1 + (2 * 2))) + 1)])) as c_uint))
                                        _ =>
                                            (done__goto_1264_17 = 1)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                match (unsafe: *ncode__goto_1119_16):
                                    OP_PROP =>
                                        if (ncode__goto_1119_16[1] != 9):
                                            break
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_ANYNL =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_CHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_CHARI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_EXACT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_EXACTI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_HSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_MINPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_MINPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_PLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_PLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_POSPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_POSPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_VSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_NOT_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_NOT_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_NOT_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    _ => 0
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_ASSERT_NA =>
                                (ncode__goto_1119_16 = (tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint)))
                                while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                done__goto_1264_17 = 0
                                while (not ((done__goto_1264_17 != 0))):
                                    match (unsafe: *ncode__goto_1119_16):
                                        OP_ASSERT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERT_NOT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERTBACK =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERTBACK_NOT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERT_NA =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERTBACK_NA =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_ASSERT_SCS =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                            while ((unsafe: *ncode__goto_1119_16) == OP_ALT):
                                                (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[1] << 8)) | (ncode__goto_1119_16)[((1) + 1)])) as c_uint))
                                                if __goto_pending != 0:
                                                    break
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))
                                        OP_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_NOT_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_UCP_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_NOT_UCP_WORD_BOUNDARY =>
                                            var __ci_expr_old_3: *const u8 = ncode__goto_1119_16
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                        OP_CALLOUT =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + _pcre2_OP_lengths_8[OP_CALLOUT])
                                        OP_CALLOUT_STR =>
                                            (ncode__goto_1119_16 = ncode__goto_1119_16 + ((((((ncode__goto_1119_16)[(1 + (2 * 2))] << 8)) | (ncode__goto_1119_16)[(((1 + (2 * 2))) + 1)])) as c_uint))
                                        _ =>
                                            (done__goto_1264_17 = 1)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                match (unsafe: *ncode__goto_1119_16):
                                    OP_PROP =>
                                        if (ncode__goto_1119_16[1] != 9):
                                            break
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_ANYNL =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_CHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_CHARI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_EXACT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_EXACTI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_HSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_MINPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_MINPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_PLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_PLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_POSPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_POSPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_VSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_NOT_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_NOT_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    OP_NOT_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)
                                        continue
                                    _ => 0
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_BRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_SBRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_CBRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_SCBRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_BRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_SBRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_CBRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_SCBRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_ONCE =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_SCRIPT_RUN =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (rc__goto_1118_9 == SSB_DONE):
                                    (try_next__goto_1110_8 = 0)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_1118_9 == SSB_CONTINUE):
                                        while true:
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return rc__goto_1118_9
                            OP_ALT =>
                                (yield___goto_1097_5 = SSB_CONTINUE)
                                (try_next__goto_1110_8 = 0)
                            OP_KET =>
                                return SSB_CONTINUE
                            OP_KETRMAX =>
                                return SSB_CONTINUE
                            OP_KETRMIN =>
                                return SSB_CONTINUE
                            OP_KETRPOS =>
                                return SSB_CONTINUE
                            OP_CALLOUT =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + _pcre2_OP_lengths_8[OP_CALLOUT])
                            OP_CALLOUT_STR =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[(1 + (2 * 2))] << 8)) | (tcode__goto_1111_14)[(((1 + (2 * 2))) + 1)])) as c_uint))
                            OP_ASSERT_NOT =>
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_ASSERTBACK =>
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_ASSERTBACK_NOT =>
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_ASSERTBACK_NA =>
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_ASSERT_SCS =>
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_BRAZERO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (((rc__goto_1118_9 == SSB_FAIL) or (rc__goto_1118_9 == SSB_UNKNOWN)) or (rc__goto_1118_9 == SSB_TOODEEP)):
                                    return rc__goto_1118_9
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_BRAMINZERO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (((rc__goto_1118_9 == SSB_FAIL) or (rc__goto_1118_9 == SSB_UNKNOWN)) or (rc__goto_1118_9 == SSB_TOODEEP)):
                                    return rc__goto_1118_9
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_BRAPOSZERO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))
                                if (((rc__goto_1118_9 == SSB_FAIL) or (rc__goto_1118_9 == SSB_UNKNOWN)) or (rc__goto_1118_9 == SSB_TOODEEP)):
                                    return rc__goto_1118_9
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_SKIPZERO =>
                                var __ci_expr_old_4: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                while true:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *tcode__goto_1111_14) == OP_ALT)):
                                        break
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_STAR =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp))
                            OP_MINSTAR =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp))
                            OP_POSSTAR =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp))
                            OP_QUERY =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp))
                            OP_MINQUERY =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp))
                            OP_POSQUERY =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp))
                            OP_STARI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp))
                            OP_MINSTARI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp))
                            OP_POSSTARI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp))
                            OP_QUERYI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp))
                            OP_MINQUERYI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp))
                            OP_POSQUERYI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp))
                            OP_UPTO =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)), 0, utf, ucp))
                            OP_MINUPTO =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)), 0, utf, ucp))
                            OP_POSUPTO =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)), 0, utf, ucp))
                            OP_UPTOI =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)), 1, utf, ucp))
                            OP_MINUPTOI =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)), 1, utf, ucp))
                            OP_POSUPTOI =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)), 1, utf, ucp))
                            OP_EXACT =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_CHAR =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_PLUS =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_MINPLUS =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_POSPLUS =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 0, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_EXACTI =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_CHARI =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_PLUSI =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_MINPLUSI =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_POSPLUSI =>
                                set_table_bit(re, (tcode__goto_1111_14 + (1 as isize as usize)), 1, utf, ucp)
                                (try_next__goto_1110_8 = 0)
                            OP_HSPACE =>
                                ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                if (utf != 0):
                                    ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                    ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                    ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                    ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                    if __goto_pending != 0:
                                        break
                                (try_next__goto_1110_8 = 0)
                            OP_ANYNL =>
                                ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                if (utf != 0):
                                    ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                    ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                    if __goto_pending != 0:
                                        break
                                (try_next__goto_1110_8 = 0)
                            OP_VSPACE =>
                                ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                if (utf != 0):
                                    ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                    ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                    if __goto_pending != 0:
                                        break
                                (try_next__goto_1110_8 = 0)
                            OP_NOT_DIGIT =>
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                (try_next__goto_1110_8 = 0)
                            OP_DIGIT =>
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                                (try_next__goto_1110_8 = 0)
                            OP_NOT_WHITESPACE =>
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                (try_next__goto_1110_8 = 0)
                            OP_WHITESPACE =>
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                                (try_next__goto_1110_8 = 0)
                            OP_NOT_WORDCHAR =>
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                (try_next__goto_1110_8 = 0)
                            OP_WORDCHAR =>
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                                (try_next__goto_1110_8 = 0)
                            OP_TYPEPLUS =>
                                var __ci_expr_old_5: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_TYPEMINPLUS =>
                                var __ci_expr_old_5: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_TYPEPOSPLUS =>
                                var __ci_expr_old_5: *const u8 = tcode__goto_1111_14
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_TYPEEXACT =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_TYPEUPTO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEMINUPTO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEPOSUPTO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPESTAR =>
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEMINSTAR =>
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEPOSSTAR =>
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEQUERY =>
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEMINQUERY =>
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEPOSQUERY =>
                                match tcode__goto_1111_14[1]:
                                    OP_ANY =>
                                        return SSB_FAIL
                                    OP_ALLANY =>
                                        return SSB_FAIL
                                    OP_HSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((9) / 8)] = (&re.start_bitmap[0] as *mut u8)[((9) / 8)] | ((1 << (((9) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((32) / 8)] = (&re.start_bitmap[0] as *mut u8)[((32) / 8)] | ((1 << (((32) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((225) / 8)] = (&re.start_bitmap[0] as *mut u8)[((225) / 8)] | ((1 << (((225) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((227) / 8)] = (&re.start_bitmap[0] as *mut u8)[((227) / 8)] | ((1 << (((227) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(160 / 8)] = (&re.start_bitmap[0] as *mut u8)[(160 / 8)] | ((1 << ((160 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_ANYNL =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_VSPACE =>
                                        ((&re.start_bitmap[0] as *mut u8)[((10) / 8)] = (&re.start_bitmap[0] as *mut u8)[((10) / 8)] | ((1 << (((10) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((11) / 8)] = (&re.start_bitmap[0] as *mut u8)[((11) / 8)] | ((1 << (((11) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((12) / 8)] = (&re.start_bitmap[0] as *mut u8)[((12) / 8)] | ((1 << (((12) & 7)))))
                                        ((&re.start_bitmap[0] as *mut u8)[((13) / 8)] = (&re.start_bitmap[0] as *mut u8)[((13) / 8)] | ((1 << (((13) & 7)))))
                                        if (utf != 0):
                                            ((&re.start_bitmap[0] as *mut u8)[((194) / 8)] = (&re.start_bitmap[0] as *mut u8)[((194) / 8)] | ((1 << (((194) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                            ((&re.start_bitmap[0] as *mut u8)[((226) / 8)] = (&re.start_bitmap[0] as *mut u8)[((226) / 8)] | ((1 << (((226) & 7)))))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            ((&re.start_bitmap[0] as *mut u8)[(133 / 8)] = (&re.start_bitmap[0] as *mut u8)[(133 / 8)] | ((1 << ((133 & 7)))))
                                            if __goto_pending != 0:
                                                break
                                    OP_NOT_DIGIT =>
                                        set_nottype_bits(re, 64, table_limit__goto_1100_5)
                                    OP_DIGIT =>
                                        set_type_bits(re, 64, table_limit__goto_1100_5)
                                    OP_NOT_WHITESPACE =>
                                        set_nottype_bits(re, 0, table_limit__goto_1100_5)
                                    OP_WHITESPACE =>
                                        set_type_bits(re, 0, table_limit__goto_1100_5)
                                    OP_NOT_WORDCHAR =>
                                        set_nottype_bits(re, 160, table_limit__goto_1100_5)
                                    OP_WORDCHAR =>
                                        set_type_bits(re, 160, table_limit__goto_1100_5)
                                    _ =>
                                        return SSB_FAIL
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_ECLASS =>
                                return SSB_FAIL
                            OP_XCLASS =>
                                (xclassflags__goto_1122_17 = tcode__goto_1111_14[(1 + 2)])
                                if ((((xclassflags__goto_1122_17 & 4)) != 0) or (((xclassflags__goto_1122_17 & ((2 | 1)))) == 1)):
                                    return SSB_FAIL
                                (classmap__goto_1120_20 = (if (((xclassflags__goto_1122_17 & 2)) == 0): (null as *const u8) else: ((((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)) + (1 as isize as usize)))))
                                if ((utf != 0) and (((xclassflags__goto_1122_17 & 1)) == 0)):
                                    p__goto_1750_20 = ((((tcode__goto_1111_14 + (1 as isize as usize)) + (2 as isize as usize)) + (1 as isize as usize)) + (((if (classmap__goto_1120_20 == (null as *const u8)): 0 else: 32)) as isize as usize))
                                    if __goto_pending != 0:
                                        break
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        var __ci_expr_old_6: *const u8 = p__goto_1750_20
                                        (p__goto_1750_20 = p__goto_1750_20 + 1)
                                        var __ci_expr_switch_7: c_int = (unsafe: *__ci_expr_old_6)
                                        match __ci_expr_switch_7:
                                            1 =>
                                                var __ci_expr_old_8: *const u8 = p__goto_1750_20
                                                (p__goto_1750_20 = p__goto_1750_20 + 1)
                                                (b__goto_1749_21 = (unsafe: *__ci_expr_old_8))
                                                while ((((unsafe: *p__goto_1750_20) & 192)) == 128):
                                                    var __ci_expr_old_9: *const u8 = p__goto_1750_20
                                                    (p__goto_1750_20 = p__goto_1750_20 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                ((&re.start_bitmap[0] as *mut u8)[(b__goto_1749_21 / 8)] = (&re.start_bitmap[0] as *mut u8)[(b__goto_1749_21 / 8)] | ((1 << ((b__goto_1749_21 & 7)))))
                                            2 =>
                                                var __ci_expr_old_10: *const u8 = p__goto_1750_20
                                                (p__goto_1750_20 = p__goto_1750_20 + 1)
                                                (b__goto_1749_21 = (unsafe: *__ci_expr_old_10))
                                                while ((((unsafe: *p__goto_1750_20) & 192)) == 128):
                                                    var __ci_expr_old_11: *const u8 = p__goto_1750_20
                                                    (p__goto_1750_20 = p__goto_1750_20 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                var __ci_expr_old_12: *const u8 = p__goto_1750_20
                                                (p__goto_1750_20 = p__goto_1750_20 + 1)
                                                (e__goto_1749_24 = (unsafe: *__ci_expr_old_12))
                                                while ((((unsafe: *p__goto_1750_20) & 192)) == 128):
                                                    var __ci_expr_old_13: *const u8 = p__goto_1750_20
                                                    (p__goto_1750_20 = p__goto_1750_20 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                while (b__goto_1749_21 <= e__goto_1749_24):
                                                    ((&re.start_bitmap[0] as *mut u8)[(b__goto_1749_21 / 8)] = (&re.start_bitmap[0] as *mut u8)[(b__goto_1749_21 / 8)] | ((1 << ((b__goto_1749_21 & 7)))))
                                                    var __ci_expr_old_14: u8 = b__goto_1749_21
                                                (b__goto_1749_21 = b__goto_1749_21 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                            0 =>
                                                __pc = 1
                                                __goto_pending = 1
                                            _ =>
                                                return SSB_UNKNOWN
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                if (utf != 0):
                                    ((&re.start_bitmap[0] as *mut u8)[24] = (&re.start_bitmap[0] as *mut u8)[24] | 240)
                                    if __goto_pending != 0:
                                        break
                                    with_memset((((&(&re.start_bitmap[0] as *mut u8)[0] as *mut u8) + (25 as isize as usize)) as *mut c_void) as *i8, 255, 7 as i64)
                                    if __goto_pending != 0:
                                        break
                                if ((unsafe: *tcode__goto_1111_14) == OP_XCLASS):
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                else:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    (classmap__goto_1120_20 = (tcode__goto_1111_14))
                                    if __goto_pending != 0:
                                        break
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))
                                    if __goto_pending != 0:
                                        break
                                if (classmap__goto_1120_20 != (null as *const u8)):
                                    if (utf != 0):
                                        (c__goto_1096_10 = 0)
                                        while (c__goto_1096_10 < 16):
                                            ((&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] = (&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] | classmap__goto_1120_20[c__goto_1096_10])
                                            var __ci_expr_old_15: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (c__goto_1096_10 = 128)
                                        while (c__goto_1096_10 < 256):
                                            if (((classmap__goto_1120_20[(c__goto_1096_10 / 8)] & ((1 << ((c__goto_1096_10 & 7)))))) != 0):
                                                d__goto_1845_19 = (((c__goto_1096_10 >> 6)) | 192)
                                                if __goto_pending != 0:
                                                    break
                                                ((&re.start_bitmap[0] as *mut u8)[(d__goto_1845_19 / 8)] = (&re.start_bitmap[0] as *mut u8)[(d__goto_1845_19 / 8)] | ((1 << ((d__goto_1845_19 & 7)))))
                                                if __goto_pending != 0:
                                                    break
                                                (c__goto_1096_10 = ((((c__goto_1096_10 & 192)) +% 64) -% 1))
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_16: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (c__goto_1096_10 = 0)
                                        while (c__goto_1096_10 < 32):
                                            ((&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] = (&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] | classmap__goto_1120_20[c__goto_1096_10])
                                            var __ci_expr_old_17: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                match (unsafe: *tcode__goto_1111_14):
                                    OP_CRSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRMINSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRMINQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRPOSSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRPOSQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    OP_CRMINRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    OP_CRPOSRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    _ =>
                                        (try_next__goto_1110_8 = 0)
                            OP_NCLASS =>
                                if (utf != 0):
                                    ((&re.start_bitmap[0] as *mut u8)[24] = (&re.start_bitmap[0] as *mut u8)[24] | 240)
                                    if __goto_pending != 0:
                                        break
                                    with_memset((((&(&re.start_bitmap[0] as *mut u8)[0] as *mut u8) + (25 as isize as usize)) as *mut c_void) as *i8, 255, 7 as i64)
                                    if __goto_pending != 0:
                                        break
                                if ((unsafe: *tcode__goto_1111_14) == OP_XCLASS):
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                else:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    (classmap__goto_1120_20 = (tcode__goto_1111_14))
                                    if __goto_pending != 0:
                                        break
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))
                                    if __goto_pending != 0:
                                        break
                                if (classmap__goto_1120_20 != (null as *const u8)):
                                    if (utf != 0):
                                        (c__goto_1096_10 = 0)
                                        while (c__goto_1096_10 < 16):
                                            ((&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] = (&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] | classmap__goto_1120_20[c__goto_1096_10])
                                            var __ci_expr_old_15: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (c__goto_1096_10 = 128)
                                        while (c__goto_1096_10 < 256):
                                            if (((classmap__goto_1120_20[(c__goto_1096_10 / 8)] & ((1 << ((c__goto_1096_10 & 7)))))) != 0):
                                                d__goto_1845_19 = (((c__goto_1096_10 >> 6)) | 192)
                                                if __goto_pending != 0:
                                                    break
                                                ((&re.start_bitmap[0] as *mut u8)[(d__goto_1845_19 / 8)] = (&re.start_bitmap[0] as *mut u8)[(d__goto_1845_19 / 8)] | ((1 << ((d__goto_1845_19 & 7)))))
                                                if __goto_pending != 0:
                                                    break
                                                (c__goto_1096_10 = ((((c__goto_1096_10 & 192)) +% 64) -% 1))
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_16: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (c__goto_1096_10 = 0)
                                        while (c__goto_1096_10 < 32):
                                            ((&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] = (&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] | classmap__goto_1120_20[c__goto_1096_10])
                                            var __ci_expr_old_17: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                match (unsafe: *tcode__goto_1111_14):
                                    OP_CRSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRMINSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRMINQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRPOSSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRPOSQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    OP_CRMINRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    OP_CRPOSRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    _ =>
                                        (try_next__goto_1110_8 = 0)
                            OP_CLASS =>
                                if ((unsafe: *tcode__goto_1111_14) == OP_XCLASS):
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + ((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint))
                                else:
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    (classmap__goto_1120_20 = (tcode__goto_1111_14))
                                    if __goto_pending != 0:
                                        break
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))
                                    if __goto_pending != 0:
                                        break
                                if (classmap__goto_1120_20 != (null as *const u8)):
                                    if (utf != 0):
                                        (c__goto_1096_10 = 0)
                                        while (c__goto_1096_10 < 16):
                                            ((&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] = (&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] | classmap__goto_1120_20[c__goto_1096_10])
                                            var __ci_expr_old_15: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (c__goto_1096_10 = 128)
                                        while (c__goto_1096_10 < 256):
                                            if (((classmap__goto_1120_20[(c__goto_1096_10 / 8)] & ((1 << ((c__goto_1096_10 & 7)))))) != 0):
                                                d__goto_1845_19 = (((c__goto_1096_10 >> 6)) | 192)
                                                if __goto_pending != 0:
                                                    break
                                                ((&re.start_bitmap[0] as *mut u8)[(d__goto_1845_19 / 8)] = (&re.start_bitmap[0] as *mut u8)[(d__goto_1845_19 / 8)] | ((1 << ((d__goto_1845_19 & 7)))))
                                                if __goto_pending != 0:
                                                    break
                                                (c__goto_1096_10 = ((((c__goto_1096_10 & 192)) +% 64) -% 1))
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            var __ci_expr_old_16: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (c__goto_1096_10 = 0)
                                        while (c__goto_1096_10 < 32):
                                            ((&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] = (&re.start_bitmap[0] as *mut u8)[c__goto_1096_10] | classmap__goto_1120_20[c__goto_1096_10])
                                            var __ci_expr_old_17: c_uint = c__goto_1096_10
                                        (c__goto_1096_10 = c__goto_1096_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                match (unsafe: *tcode__goto_1111_14):
                                    OP_CRSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRMINSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRMINQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRPOSSTAR =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRPOSQUERY =>
                                        var __ci_expr_old_18: *const u8 = tcode__goto_1111_14
                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                                    OP_CRRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    OP_CRMINRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    OP_CRPOSRANGE =>
                                        if (((((((tcode__goto_1111_14)[1] << 8)) | (tcode__goto_1111_14)[((1) + 1)])) as c_uint) == 0):
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + (2 * 2)))
                                        else:
                                            (try_next__goto_1110_8 = 0)
                                    _ =>
                                        (try_next__goto_1110_8 = 0)
                            _ =>
                                return SSB_UNKNOWN
                        if __goto_pending != 0:
                            break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    (code = code + ((((((code)[1] << 8)) | (code)[((1) + 1)])) as c_uint))
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                    if not (((unsafe: *code) == OP_ALT)):
                        break
                if __goto_pending != 0:
                    continue
                return yield___goto_1097_5
                if __goto_pending != 0:
                    continue
            _ => break

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
let MAX_CACHE_BACKREF: c_int = 128
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
fn PUTINC() -> Never:
    comptime_error("untranslatable C macro: PUTINC")
// untranslatable fn-like macro
fn REAL_GET_UCD() -> Never:
    comptime_error("untranslatable C macro: REAL_GET_UCD")
// untranslatable fn-like macro
fn SET_BIT() -> Never:
    comptime_error("untranslatable C macro: SET_BIT")
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
