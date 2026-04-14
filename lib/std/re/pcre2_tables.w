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
let _pcre2_OP_lengths_8: [173]u8 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 1, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1, 5, 33, 33, 0, 0, 3, 4, 5, 6, 3, 6, 0, 3, 3, 3, 3, 3, 3, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5, 3, 3, 3, 5, 5, 3, 3, 5, 3, 5, 1, 1, 1, 1, 1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1, 1, 1, 3, 1, 1, 1, 1]
let _pcre2_hspace_list_8: [20]c_uint = [9, 32, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288, 4294967295]
let _pcre2_vspace_list_8: [8]c_uint = [10, 11, 12, 13, 133, 8232, 8233, 4294967295]
let _pcre2_callout_start_delims_8: [9]c_uint = [96, 39, 34, 94, 37, 35, 36, 123, 0]
let _pcre2_callout_end_delims_8: [9]c_uint = [96, 39, 34, 94, 37, 35, 36, 125, 0]
let _pcre2_utf8_table1: [6]c_int = [127, 2047, 65535, 2097151, 67108863, 2147483647]
let _pcre2_utf8_table1_size: c_uint = 6
let _pcre2_utf8_table2: [6]c_int = [0, 192, 224, 240, 248, 252]
let _pcre2_utf8_table3: [6]c_int = [255, 31, 15, 7, 3, 1]
let _pcre2_utf8_table4: [64]u8 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5]
let _pcre2_ucp_gentype_8: [30]c_uint = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6]
let _pcre2_ucp_gbtable_8: [15]c_uint = [((1 << ucp_gbLF)), 0, 0, 8232, ((((((((8232 | ((1 << ucp_gbPrepend))) | ((1 << ucp_gbL))) | ((1 << ucp_gbV))) | ((1 << ucp_gbT))) | ((1 << ucp_gbLV))) | ((1 << ucp_gbLVT))) | ((1 << ucp_gbOther))) | ((1 << ucp_gbRegional_Indicator))), 8232, ((((8232 | ((1 << ucp_gbL))) | ((1 << ucp_gbV))) | ((1 << ucp_gbLV))) | ((1 << ucp_gbLVT))), ((8232 | ((1 << ucp_gbV))) | ((1 << ucp_gbT))), (8232 | ((1 << ucp_gbT))), ((8232 | ((1 << ucp_gbV))) | ((1 << ucp_gbT))), (8232 | ((1 << ucp_gbT))), ((1 << ucp_gbRegional_Indicator)), 8232, (8232 | ((1 << ucp_gbExtended_Pictographic))), 8232]
let _pcre2_utt_names_8: [3834]c_char = "\141\144\154\141\155\0\141\144\154\155\0\141\147\150\142\0\141\150\145\170\0\141\150\157\155\0\141\154\160\150\141\0\141\154\160\150\141\142\145\164\151\143\0\141\156\141\164\157\154\151\141\156\150\151\145\162\157\147\154\171\160\150\163\0\141\156\171\0\141\162\141\142\0\141\162\141\142\151\143\0\141\162\155\145\156\151\141\156\0\141\162\155\151\0\141\162\155\156\0\141\163\143\151\151\0\141\163\143\151\151\150\145\170\144\151\147\151\164\0\141\166\145\163\164\141\156\0\141\166\163\164\0\142\141\154\151\0\142\141\154\151\156\145\163\145\0\142\141\155\165\0\142\141\155\165\155\0\142\141\163\163\0\142\141\163\163\141\166\141\150\0\142\141\164\141\153\0\142\141\164\153\0\142\145\156\147\0\142\145\156\147\141\154\151\0\142\145\162\146\0\142\145\162\151\141\145\162\146\145\0\142\150\141\151\153\163\165\153\151\0\142\150\153\163\0\142\151\144\151\141\154\0\142\151\144\151\141\156\0\142\151\144\151\142\0\142\151\144\151\142\156\0\142\151\144\151\143\0\142\151\144\151\143\157\156\164\162\157\154\0\142\151\144\151\143\163\0\142\151\144\151\145\156\0\142\151\144\151\145\163\0\142\151\144\151\145\164\0\142\151\144\151\146\163\151\0\142\151\144\151\154\0\142\151\144\151\154\162\145\0\142\151\144\151\154\162\151\0\142\151\144\151\154\162\157\0\142\151\144\151\155\0\142\151\144\151\155\151\162\162\157\162\145\144\0\142\151\144\151\156\163\155\0\142\151\144\151\157\156\0\142\151\144\151\160\144\146\0\142\151\144\151\160\144\151\0\142\151\144\151\162\0\142\151\144\151\162\154\145\0\142\151\144\151\162\154\151\0\142\151\144\151\162\154\157\0\142\151\144\151\163\0\142\151\144\151\167\163\0\142\157\160\157\0\142\157\160\157\155\157\146\157\0\142\162\141\150\0\142\162\141\150\155\151\0\142\162\141\151\0\142\162\141\151\154\154\145\0\142\165\147\151\0\142\165\147\151\156\145\163\145\0\142\165\150\144\0\142\165\150\151\144\0\143\0\143\141\153\155\0\143\141\156\141\144\151\141\156\141\142\157\162\151\147\151\156\141\154\0\143\141\156\163\0\143\141\162\151\0\143\141\162\151\141\156\0\143\141\163\145\144\0\143\141\163\145\151\147\156\157\162\141\142\154\145\0\143\141\165\143\141\163\151\141\156\141\154\142\141\156\151\141\156\0\143\143\0\143\146\0\143\150\141\153\155\141\0\143\150\141\155\0\143\150\141\156\147\145\163\167\150\145\156\143\141\163\145\146\157\154\144\145\144\0\143\150\141\156\147\145\163\167\150\145\156\143\141\163\145\155\141\160\160\145\144\0\143\150\141\156\147\145\163\167\150\145\156\154\157\167\145\162\143\141\163\145\144\0\143\150\141\156\147\145\163\167\150\145\156\164\151\164\154\145\143\141\163\145\144\0\143\150\141\156\147\145\163\167\150\145\156\165\160\160\145\162\143\141\163\145\144\0\143\150\145\162\0\143\150\145\162\157\153\145\145\0\143\150\157\162\141\163\155\151\141\156\0\143\150\162\163\0\143\151\0\143\156\0\143\157\0\143\157\155\155\157\156\0\143\157\160\164\0\143\157\160\164\151\143\0\143\160\155\156\0\143\160\162\164\0\143\163\0\143\165\156\145\151\146\157\162\155\0\143\167\143\146\0\143\167\143\155\0\143\167\154\0\143\167\164\0\143\167\165\0\143\171\160\162\151\157\164\0\143\171\160\162\157\155\151\156\157\141\156\0\143\171\162\151\154\154\151\143\0\143\171\162\154\0\144\141\163\150\0\144\145\146\141\165\154\164\151\147\156\157\162\141\142\154\145\143\157\144\145\160\157\151\156\164\0\144\145\160\0\144\145\160\162\145\143\141\164\145\144\0\144\145\163\145\162\145\164\0\144\145\166\141\0\144\145\166\141\156\141\147\141\162\151\0\144\151\0\144\151\141\0\144\151\141\143\162\151\164\151\143\0\144\151\141\153\0\144\151\166\145\163\141\153\165\162\165\0\144\157\147\162\0\144\157\147\162\141\0\144\163\162\164\0\144\165\160\154\0\144\165\160\154\157\171\141\156\0\145\142\141\163\145\0\145\143\157\155\160\0\145\147\171\160\0\145\147\171\160\164\151\141\156\150\151\145\162\157\147\154\171\160\150\163\0\145\154\142\141\0\145\154\142\141\163\141\156\0\145\154\171\155\0\145\154\171\155\141\151\143\0\145\155\157\144\0\145\155\157\152\151\0\145\155\157\152\151\143\157\155\160\157\156\145\156\164\0\145\155\157\152\151\155\157\144\151\146\151\145\162\0\145\155\157\152\151\155\157\144\151\146\151\145\162\142\141\163\145\0\145\155\157\152\151\160\162\145\163\145\156\164\141\164\151\157\156\0\145\160\162\145\163\0\145\164\150\151\0\145\164\150\151\157\160\151\143\0\145\170\164\0\145\170\164\145\156\144\145\144\160\151\143\164\157\147\162\141\160\150\151\143\0\145\170\164\145\156\144\145\162\0\145\170\164\160\151\143\164\0\147\141\162\141\0\147\141\162\141\171\0\147\145\157\162\0\147\145\157\162\147\151\141\156\0\147\154\141\147\0\147\154\141\147\157\154\151\164\151\143\0\147\157\156\147\0\147\157\156\155\0\147\157\164\150\0\147\157\164\150\151\143\0\147\162\141\156\0\147\162\141\156\164\150\141\0\147\162\141\160\150\145\155\145\142\141\163\145\0\147\162\141\160\150\145\155\145\145\170\164\145\156\144\0\147\162\141\160\150\145\155\145\154\151\156\153\0\147\162\142\141\163\145\0\147\162\145\145\153\0\147\162\145\153\0\147\162\145\170\164\0\147\162\154\151\156\153\0\147\165\152\141\162\141\164\151\0\147\165\152\162\0\147\165\153\150\0\147\165\156\152\141\154\141\147\157\156\144\151\0\147\165\162\155\165\153\150\151\0\147\165\162\165\0\147\165\162\165\156\147\153\150\145\155\141\0\150\141\156\0\150\141\156\147\0\150\141\156\147\165\154\0\150\141\156\151\0\150\141\156\151\146\151\162\157\150\151\156\147\171\141\0\150\141\156\157\0\150\141\156\165\156\157\157\0\150\141\164\162\0\150\141\164\162\141\156\0\150\145\142\162\0\150\145\142\162\145\167\0\150\145\170\0\150\145\170\144\151\147\151\164\0\150\151\162\141\0\150\151\162\141\147\141\156\141\0\150\154\165\167\0\150\155\156\147\0\150\155\156\160\0\150\165\156\147\0\151\144\143\0\151\144\143\157\155\160\141\164\155\141\164\150\143\157\156\164\151\156\165\145\0\151\144\143\157\155\160\141\164\155\141\164\150\163\164\141\162\164\0\151\144\143\157\156\164\151\156\165\145\0\151\144\145\157\0\151\144\145\157\147\162\141\160\150\151\143\0\151\144\163\0\151\144\163\142\0\151\144\163\142\151\156\141\162\171\157\160\145\162\141\164\157\162\0\151\144\163\164\0\151\144\163\164\141\162\164\0\151\144\163\164\162\151\156\141\162\171\157\160\145\162\141\164\157\162\0\151\144\163\165\0\151\144\163\165\156\141\162\171\157\160\145\162\141\164\157\162\0\151\155\160\145\162\151\141\154\141\162\141\155\141\151\143\0\151\156\143\142\0\151\156\150\145\162\151\164\145\144\0\151\156\163\143\162\151\160\164\151\157\156\141\154\160\141\150\154\141\166\151\0\151\156\163\143\162\151\160\164\151\157\156\141\154\160\141\162\164\150\151\141\156\0\151\164\141\154\0\152\141\166\141\0\152\141\166\141\156\145\163\145\0\152\157\151\156\143\0\152\157\151\156\143\157\156\164\162\157\154\0\153\141\151\164\150\151\0\153\141\154\151\0\153\141\156\141\0\153\141\156\156\141\144\141\0\153\141\164\141\153\141\156\141\0\153\141\167\151\0\153\141\171\141\150\154\151\0\153\150\141\162\0\153\150\141\162\157\163\150\164\150\151\0\153\150\151\164\141\156\163\155\141\154\154\163\143\162\151\160\164\0\153\150\155\145\162\0\153\150\155\162\0\153\150\157\152\0\153\150\157\152\153\151\0\153\150\165\144\141\167\141\144\151\0\153\151\162\141\164\162\141\151\0\153\151\164\163\0\153\156\144\141\0\153\162\141\151\0\153\164\150\151\0\154\0\154\046\0\154\141\156\141\0\154\141\157\0\154\141\157\157\0\154\141\164\151\156\0\154\141\164\156\0\154\143\0\154\145\160\143\0\154\145\160\143\150\141\0\154\151\155\142\0\154\151\155\142\165\0\154\151\156\141\0\154\151\156\142\0\154\151\156\145\141\162\141\0\154\151\156\145\141\162\142\0\154\151\163\165\0\154\154\0\154\155\0\154\157\0\154\157\145\0\154\157\147\151\143\141\154\157\162\144\145\162\145\170\143\145\160\164\151\157\156\0\154\157\167\145\162\0\154\157\167\145\162\143\141\163\145\0\154\164\0\154\165\0\154\171\143\151\0\154\171\143\151\141\156\0\154\171\144\151\0\154\171\144\151\141\156\0\155\0\155\141\150\141\152\141\156\151\0\155\141\150\152\0\155\141\153\141\0\155\141\153\141\163\141\162\0\155\141\154\141\171\141\154\141\155\0\155\141\156\144\0\155\141\156\144\141\151\143\0\155\141\156\151\0\155\141\156\151\143\150\141\145\141\156\0\155\141\162\143\0\155\141\162\143\150\145\156\0\155\141\163\141\162\141\155\147\157\156\144\151\0\155\141\164\150\0\155\143\0\155\143\155\0\155\145\0\155\145\144\145\146\141\151\144\162\151\156\0\155\145\144\146\0\155\145\145\164\145\151\155\141\171\145\153\0\155\145\156\144\0\155\145\156\144\145\153\151\153\141\153\165\151\0\155\145\162\143\0\155\145\162\157\0\155\145\162\157\151\164\151\143\143\165\162\163\151\166\145\0\155\145\162\157\151\164\151\143\150\151\145\162\157\147\154\171\160\150\163\0\155\151\141\157\0\155\154\171\155\0\155\156\0\155\157\144\151\0\155\157\144\151\146\151\145\162\143\157\155\142\151\156\151\156\147\155\141\162\153\0\155\157\156\147\0\155\157\156\147\157\154\151\141\156\0\155\162\157\0\155\162\157\157\0\155\164\145\151\0\155\165\154\164\0\155\165\154\164\141\156\151\0\155\171\141\156\155\141\162\0\155\171\155\162\0\156\0\156\141\142\141\164\141\145\141\156\0\156\141\147\155\0\156\141\147\155\165\156\144\141\162\151\0\156\141\156\144\0\156\141\156\144\151\156\141\147\141\162\151\0\156\141\162\142\0\156\142\141\164\0\156\143\150\141\162\0\156\144\0\156\145\167\141\0\156\145\167\164\141\151\154\165\145\0\156\153\157\0\156\153\157\157\0\156\154\0\156\157\0\156\157\156\143\150\141\162\141\143\164\145\162\143\157\144\145\160\157\151\156\164\0\156\163\150\165\0\156\165\163\150\165\0\156\171\151\141\153\145\156\147\160\165\141\143\150\165\145\150\155\157\156\147\0\157\147\141\155\0\157\147\150\141\155\0\157\154\143\150\151\153\151\0\157\154\143\153\0\157\154\144\150\165\156\147\141\162\151\141\156\0\157\154\144\151\164\141\154\151\143\0\157\154\144\156\157\162\164\150\141\162\141\142\151\141\156\0\157\154\144\160\145\162\155\151\143\0\157\154\144\160\145\162\163\151\141\156\0\157\154\144\163\157\147\144\151\141\156\0\157\154\144\163\157\165\164\150\141\162\141\142\151\141\156\0\157\154\144\164\165\162\153\151\143\0\157\154\144\165\171\147\150\165\162\0\157\154\157\156\141\154\0\157\156\141\157\0\157\162\151\171\141\0\157\162\153\150\0\157\162\171\141\0\157\163\141\147\145\0\157\163\147\145\0\157\163\155\141\0\157\163\155\141\156\171\141\0\157\165\147\162\0\160\0\160\141\150\141\167\150\150\155\157\156\147\0\160\141\154\155\0\160\141\154\155\171\162\145\156\145\0\160\141\164\163\171\156\0\160\141\164\164\145\162\156\163\171\156\164\141\170\0\160\141\164\164\145\162\156\167\150\151\164\145\163\160\141\143\145\0\160\141\164\167\163\0\160\141\165\143\0\160\141\165\143\151\156\150\141\165\0\160\143\0\160\143\155\0\160\144\0\160\145\0\160\145\162\155\0\160\146\0\160\150\141\147\0\160\150\141\147\163\160\141\0\160\150\154\151\0\160\150\154\160\0\160\150\156\170\0\160\150\157\145\156\151\143\151\141\156\0\160\151\0\160\154\162\144\0\160\157\0\160\162\145\160\145\156\144\145\144\143\157\156\143\141\164\145\156\141\164\151\157\156\155\141\162\153\0\160\162\164\151\0\160\163\0\160\163\141\154\164\145\162\160\141\150\154\141\166\151\0\161\141\141\143\0\161\141\141\151\0\161\155\141\162\153\0\161\165\157\164\141\164\151\157\156\155\141\162\153\0\162\141\144\151\143\141\154\0\162\145\147\151\157\156\141\154\151\156\144\151\143\141\164\157\162\0\162\145\152\141\156\147\0\162\151\0\162\152\156\147\0\162\157\150\147\0\162\165\156\151\143\0\162\165\156\162\0\163\0\163\141\155\141\162\151\164\141\156\0\163\141\155\162\0\163\141\162\142\0\163\141\165\162\0\163\141\165\162\141\163\150\164\162\141\0\163\143\0\163\144\0\163\145\156\164\145\156\143\145\164\145\162\155\151\156\141\154\0\163\147\156\167\0\163\150\141\162\141\144\141\0\163\150\141\166\151\141\156\0\163\150\141\167\0\163\150\162\144\0\163\151\144\144\0\163\151\144\144\150\141\155\0\163\151\144\145\164\151\143\0\163\151\144\164\0\163\151\147\156\167\162\151\164\151\156\147\0\163\151\156\144\0\163\151\156\150\0\163\151\156\150\141\154\141\0\163\153\0\163\155\0\163\157\0\163\157\146\164\144\157\164\164\145\144\0\163\157\147\144\0\163\157\147\144\151\141\156\0\163\157\147\157\0\163\157\162\141\0\163\157\162\141\163\157\155\160\145\156\147\0\163\157\171\157\0\163\157\171\157\155\142\157\0\163\160\141\143\145\0\163\164\145\162\155\0\163\165\156\144\0\163\165\156\144\141\156\145\163\145\0\163\165\156\165\0\163\165\156\165\167\141\162\0\163\171\154\157\0\163\171\154\157\164\151\156\141\147\162\151\0\163\171\162\143\0\163\171\162\151\141\143\0\164\141\147\141\154\157\147\0\164\141\147\142\0\164\141\147\142\141\156\167\141\0\164\141\151\154\145\0\164\141\151\164\150\141\155\0\164\141\151\166\151\145\164\0\164\141\151\171\157\0\164\141\153\162\0\164\141\153\162\151\0\164\141\154\145\0\164\141\154\165\0\164\141\155\151\154\0\164\141\155\154\0\164\141\156\147\0\164\141\156\147\163\141\0\164\141\156\147\165\164\0\164\141\166\164\0\164\141\171\157\0\164\145\154\165\0\164\145\154\165\147\165\0\164\145\162\155\0\164\145\162\155\151\156\141\154\160\165\156\143\164\165\141\164\151\157\156\0\164\146\156\147\0\164\147\154\147\0\164\150\141\141\0\164\150\141\141\156\141\0\164\150\141\151\0\164\151\142\145\164\141\156\0\164\151\142\164\0\164\151\146\151\156\141\147\150\0\164\151\162\150\0\164\151\162\150\165\164\141\0\164\156\163\141\0\164\157\144\150\162\151\0\164\157\144\162\0\164\157\154\157\156\147\163\151\153\151\0\164\157\154\163\0\164\157\164\157\0\164\165\154\165\164\151\147\141\154\141\162\151\0\164\165\164\147\0\165\147\141\162\0\165\147\141\162\151\164\151\143\0\165\151\144\145\157\0\165\156\151\146\151\145\144\151\144\145\157\147\162\141\160\150\0\165\156\153\156\157\167\156\0\165\160\160\145\162\0\165\160\160\145\162\143\141\163\145\0\166\141\151\0\166\141\151\151\0\166\141\162\151\141\164\151\157\156\163\145\154\145\143\164\157\162\0\166\151\164\150\0\166\151\164\150\153\165\161\151\0\166\163\0\167\141\156\143\150\157\0\167\141\162\141\0\167\141\162\141\156\147\143\151\164\151\0\167\143\150\157\0\167\150\151\164\145\163\160\141\143\145\0\167\163\160\141\143\145\0\170\141\156\0\170\151\144\143\0\170\151\144\143\157\156\164\151\156\165\145\0\170\151\144\163\0\170\151\144\163\164\141\162\164\0\170\160\145\157\0\170\160\163\0\170\163\160\0\170\163\165\170\0\170\165\143\0\170\167\144\0\171\145\172\151\0\171\145\172\151\144\151\0\171\151\0\171\151\151\151\0\172\0\172\141\156\141\142\141\172\141\162\163\161\165\141\162\145\0\172\141\156\142\0\172\151\156\150\0\172\154\0\172\160\0\172\163\0\172\171\171\171\0\172\172\172\172\0"
let _pcre2_utt_8: [518]ucp_type_table = [ucp_type_table { name_offset: 0, type_: 4, value: 79 }, ucp_type_table { name_offset: 6, type_: 4, value: 79 }, ucp_type_table { name_offset: 11, type_: 4, value: 64 }, ucp_type_table { name_offset: 16, type_: 12, value: 1 }, ucp_type_table { name_offset: 21, type_: 3, value: 148 }, ucp_type_table { name_offset: 26, type_: 12, value: 2 }, ucp_type_table { name_offset: 32, type_: 12, value: 2 }, ucp_type_table { name_offset: 43, type_: 3, value: 149 }, ucp_type_table { name_offset: 64, type_: 13, value: 0 }, ucp_type_table { name_offset: 68, type_: 4, value: 5 }, ucp_type_table { name_offset: 73, type_: 4, value: 5 }, ucp_type_table { name_offset: 80, type_: 4, value: 3 }, ucp_type_table { name_offset: 89, type_: 3, value: 129 }, ucp_type_table { name_offset: 94, type_: 4, value: 3 }, ucp_type_table { name_offset: 99, type_: 12, value: 0 }, ucp_type_table { name_offset: 105, type_: 12, value: 1 }, ucp_type_table { name_offset: 119, type_: 4, value: 53 }, ucp_type_table { name_offset: 127, type_: 4, value: 53 }, ucp_type_table { name_offset: 132, type_: 3, value: 114 }, ucp_type_table { name_offset: 137, type_: 3, value: 114 }, ucp_type_table { name_offset: 146, type_: 3, value: 127 }, ucp_type_table { name_offset: 151, type_: 3, value: 127 }, ucp_type_table { name_offset: 157, type_: 3, value: 138 }, ucp_type_table { name_offset: 162, type_: 3, value: 138 }, ucp_type_table { name_offset: 171, type_: 3, value: 133 }, ucp_type_table { name_offset: 177, type_: 3, value: 133 }, ucp_type_table { name_offset: 182, type_: 4, value: 9 }, ucp_type_table { name_offset: 187, type_: 4, value: 9 }, ucp_type_table { name_offset: 195, type_: 3, value: 174 }, ucp_type_table { name_offset: 200, type_: 3, value: 174 }, ucp_type_table { name_offset: 210, type_: 3, value: 152 }, ucp_type_table { name_offset: 220, type_: 3, value: 152 }, ucp_type_table { name_offset: 225, type_: 11, value: 0 }, ucp_type_table { name_offset: 232, type_: 11, value: 1 }, ucp_type_table { name_offset: 239, type_: 11, value: 2 }, ucp_type_table { name_offset: 245, type_: 11, value: 3 }, ucp_type_table { name_offset: 252, type_: 12, value: 3 }, ucp_type_table { name_offset: 258, type_: 12, value: 3 }, ucp_type_table { name_offset: 270, type_: 11, value: 4 }, ucp_type_table { name_offset: 277, type_: 11, value: 5 }, ucp_type_table { name_offset: 284, type_: 11, value: 6 }, ucp_type_table { name_offset: 291, type_: 11, value: 7 }, ucp_type_table { name_offset: 298, type_: 11, value: 8 }, ucp_type_table { name_offset: 306, type_: 11, value: 9 }, ucp_type_table { name_offset: 312, type_: 11, value: 10 }, ucp_type_table { name_offset: 320, type_: 11, value: 11 }, ucp_type_table { name_offset: 328, type_: 11, value: 12 }, ucp_type_table { name_offset: 336, type_: 12, value: 4 }, ucp_type_table { name_offset: 342, type_: 12, value: 4 }, ucp_type_table { name_offset: 355, type_: 11, value: 13 }, ucp_type_table { name_offset: 363, type_: 11, value: 14 }, ucp_type_table { name_offset: 370, type_: 11, value: 15 }, ucp_type_table { name_offset: 378, type_: 11, value: 16 }, ucp_type_table { name_offset: 386, type_: 11, value: 17 }, ucp_type_table { name_offset: 392, type_: 11, value: 18 }, ucp_type_table { name_offset: 400, type_: 11, value: 19 }, ucp_type_table { name_offset: 408, type_: 11, value: 20 }, ucp_type_table { name_offset: 416, type_: 11, value: 21 }, ucp_type_table { name_offset: 422, type_: 11, value: 22 }, ucp_type_table { name_offset: 429, type_: 4, value: 29 }, ucp_type_table { name_offset: 434, type_: 4, value: 29 }, ucp_type_table { name_offset: 443, type_: 3, value: 134 }, ucp_type_table { name_offset: 448, type_: 3, value: 134 }, ucp_type_table { name_offset: 455, type_: 3, value: 110 }, ucp_type_table { name_offset: 460, type_: 3, value: 110 }, ucp_type_table { name_offset: 468, type_: 4, value: 42 }, ucp_type_table { name_offset: 473, type_: 4, value: 42 }, ucp_type_table { name_offset: 482, type_: 4, value: 35 }, ucp_type_table { name_offset: 487, type_: 4, value: 35 }, ucp_type_table { name_offset: 493, type_: 1, value: 0 }, ucp_type_table { name_offset: 495, type_: 4, value: 60 }, ucp_type_table { name_offset: 500, type_: 3, value: 102 }, ucp_type_table { name_offset: 519, type_: 3, value: 102 }, ucp_type_table { name_offset: 524, type_: 4, value: 51 }, ucp_type_table { name_offset: 529, type_: 4, value: 51 }, ucp_type_table { name_offset: 536, type_: 12, value: 6 }, ucp_type_table { name_offset: 542, type_: 12, value: 5 }, ucp_type_table { name_offset: 556, type_: 4, value: 64 }, ucp_type_table { name_offset: 574, type_: 2, value: 0 }, ucp_type_table { name_offset: 577, type_: 2, value: 1 }, ucp_type_table { name_offset: 580, type_: 4, value: 60 }, ucp_type_table { name_offset: 587, type_: 3, value: 123 }, ucp_type_table { name_offset: 592, type_: 12, value: 7 }, ucp_type_table { name_offset: 614, type_: 12, value: 8 }, ucp_type_table { name_offset: 636, type_: 12, value: 9 }, ucp_type_table { name_offset: 658, type_: 12, value: 10 }, ucp_type_table { name_offset: 680, type_: 12, value: 11 }, ucp_type_table { name_offset: 702, type_: 4, value: 24 }, ucp_type_table { name_offset: 707, type_: 4, value: 24 }, ucp_type_table { name_offset: 716, type_: 3, value: 163 }, ucp_type_table { name_offset: 727, type_: 3, value: 163 }, ucp_type_table { name_offset: 732, type_: 12, value: 5 }, ucp_type_table { name_offset: 735, type_: 2, value: 2 }, ucp_type_table { name_offset: 738, type_: 2, value: 3 }, ucp_type_table { name_offset: 741, type_: 3, value: 100 }, ucp_type_table { name_offset: 748, type_: 4, value: 43 }, ucp_type_table { name_offset: 753, type_: 4, value: 43 }, ucp_type_table { name_offset: 760, type_: 4, value: 90 }, ucp_type_table { name_offset: 765, type_: 4, value: 41 }, ucp_type_table { name_offset: 770, type_: 2, value: 4 }, ucp_type_table { name_offset: 773, type_: 3, value: 115 }, ucp_type_table { name_offset: 783, type_: 12, value: 7 }, ucp_type_table { name_offset: 788, type_: 12, value: 8 }, ucp_type_table { name_offset: 793, type_: 12, value: 9 }, ucp_type_table { name_offset: 797, type_: 12, value: 10 }, ucp_type_table { name_offset: 801, type_: 12, value: 11 }, ucp_type_table { name_offset: 805, type_: 4, value: 41 }, ucp_type_table { name_offset: 813, type_: 4, value: 90 }, ucp_type_table { name_offset: 825, type_: 4, value: 2 }, ucp_type_table { name_offset: 834, type_: 4, value: 2 }, ucp_type_table { name_offset: 839, type_: 12, value: 12 }, ucp_type_table { name_offset: 844, type_: 12, value: 13 }, ucp_type_table { name_offset: 870, type_: 12, value: 14 }, ucp_type_table { name_offset: 874, type_: 12, value: 14 }, ucp_type_table { name_offset: 885, type_: 3, value: 106 }, ucp_type_table { name_offset: 893, type_: 4, value: 8 }, ucp_type_table { name_offset: 898, type_: 4, value: 8 }, ucp_type_table { name_offset: 909, type_: 12, value: 13 }, ucp_type_table { name_offset: 912, type_: 12, value: 15 }, ucp_type_table { name_offset: 916, type_: 12, value: 15 }, ucp_type_table { name_offset: 926, type_: 3, value: 164 }, ucp_type_table { name_offset: 931, type_: 3, value: 164 }, ucp_type_table { name_offset: 942, type_: 4, value: 84 }, ucp_type_table { name_offset: 947, type_: 4, value: 84 }, ucp_type_table { name_offset: 953, type_: 3, value: 106 }, ucp_type_table { name_offset: 958, type_: 4, value: 65 }, ucp_type_table { name_offset: 963, type_: 4, value: 65 }, ucp_type_table { name_offset: 972, type_: 12, value: 19 }, ucp_type_table { name_offset: 978, type_: 12, value: 17 }, ucp_type_table { name_offset: 984, type_: 3, value: 126 }, ucp_type_table { name_offset: 989, type_: 3, value: 126 }, ucp_type_table { name_offset: 1009, type_: 4, value: 66 }, ucp_type_table { name_offset: 1014, type_: 4, value: 66 }, ucp_type_table { name_offset: 1022, type_: 3, value: 160 }, ucp_type_table { name_offset: 1027, type_: 3, value: 160 }, ucp_type_table { name_offset: 1035, type_: 12, value: 18 }, ucp_type_table { name_offset: 1040, type_: 12, value: 16 }, ucp_type_table { name_offset: 1046, type_: 12, value: 17 }, ucp_type_table { name_offset: 1061, type_: 12, value: 18 }, ucp_type_table { name_offset: 1075, type_: 12, value: 19 }, ucp_type_table { name_offset: 1093, type_: 12, value: 20 }, ucp_type_table { name_offset: 1111, type_: 12, value: 20 }, ucp_type_table { name_offset: 1117, type_: 4, value: 23 }, ucp_type_table { name_offset: 1122, type_: 4, value: 23 }, ucp_type_table { name_offset: 1131, type_: 12, value: 22 }, ucp_type_table { name_offset: 1135, type_: 12, value: 21 }, ucp_type_table { name_offset: 1156, type_: 12, value: 22 }, ucp_type_table { name_offset: 1165, type_: 12, value: 21 }, ucp_type_table { name_offset: 1173, type_: 4, value: 93 }, ucp_type_table { name_offset: 1178, type_: 4, value: 93 }, ucp_type_table { name_offset: 1184, type_: 4, value: 21 }, ucp_type_table { name_offset: 1189, type_: 4, value: 21 }, ucp_type_table { name_offset: 1198, type_: 4, value: 44 }, ucp_type_table { name_offset: 1203, type_: 4, value: 44 }, ucp_type_table { name_offset: 1214, type_: 4, value: 85 }, ucp_type_table { name_offset: 1219, type_: 4, value: 83 }, ucp_type_table { name_offset: 1224, type_: 4, value: 32 }, ucp_type_table { name_offset: 1229, type_: 4, value: 32 }, ucp_type_table { name_offset: 1236, type_: 4, value: 67 }, ucp_type_table { name_offset: 1241, type_: 4, value: 67 }, ucp_type_table { name_offset: 1249, type_: 12, value: 23 }, ucp_type_table { name_offset: 1262, type_: 12, value: 24 }, ucp_type_table { name_offset: 1277, type_: 12, value: 25 }, ucp_type_table { name_offset: 1290, type_: 12, value: 23 }, ucp_type_table { name_offset: 1297, type_: 4, value: 1 }, ucp_type_table { name_offset: 1303, type_: 4, value: 1 }, ucp_type_table { name_offset: 1308, type_: 12, value: 24 }, ucp_type_table { name_offset: 1314, type_: 12, value: 25 }, ucp_type_table { name_offset: 1321, type_: 4, value: 11 }, ucp_type_table { name_offset: 1330, type_: 4, value: 11 }, ucp_type_table { name_offset: 1335, type_: 4, value: 94 }, ucp_type_table { name_offset: 1340, type_: 4, value: 85 }, ucp_type_table { name_offset: 1353, type_: 4, value: 10 }, ucp_type_table { name_offset: 1362, type_: 4, value: 10 }, ucp_type_table { name_offset: 1367, type_: 4, value: 94 }, ucp_type_table { name_offset: 1379, type_: 4, value: 30 }, ucp_type_table { name_offset: 1383, type_: 4, value: 22 }, ucp_type_table { name_offset: 1388, type_: 4, value: 22 }, ucp_type_table { name_offset: 1395, type_: 4, value: 30 }, ucp_type_table { name_offset: 1400, type_: 4, value: 86 }, ucp_type_table { name_offset: 1415, type_: 4, value: 34 }, ucp_type_table { name_offset: 1420, type_: 4, value: 34 }, ucp_type_table { name_offset: 1428, type_: 3, value: 150 }, ucp_type_table { name_offset: 1433, type_: 3, value: 150 }, ucp_type_table { name_offset: 1440, type_: 4, value: 4 }, ucp_type_table { name_offset: 1445, type_: 4, value: 4 }, ucp_type_table { name_offset: 1452, type_: 12, value: 26 }, ucp_type_table { name_offset: 1456, type_: 12, value: 26 }, ucp_type_table { name_offset: 1465, type_: 4, value: 27 }, ucp_type_table { name_offset: 1470, type_: 4, value: 27 }, ucp_type_table { name_offset: 1479, type_: 3, value: 149 }, ucp_type_table { name_offset: 1484, type_: 3, value: 139 }, ucp_type_table { name_offset: 1489, type_: 3, value: 161 }, ucp_type_table { name_offset: 1494, type_: 4, value: 78 }, ucp_type_table { name_offset: 1499, type_: 12, value: 32 }, ucp_type_table { name_offset: 1503, type_: 12, value: 30 }, ucp_type_table { name_offset: 1524, type_: 12, value: 31 }, ucp_type_table { name_offset: 1542, type_: 12, value: 32 }, ucp_type_table { name_offset: 1553, type_: 12, value: 34 }, ucp_type_table { name_offset: 1558, type_: 12, value: 34 }, ucp_type_table { name_offset: 1570, type_: 12, value: 33 }, ucp_type_table { name_offset: 1574, type_: 12, value: 27 }, ucp_type_table { name_offset: 1579, type_: 12, value: 27 }, ucp_type_table { name_offset: 1597, type_: 12, value: 28 }, ucp_type_table { name_offset: 1602, type_: 12, value: 33 }, ucp_type_table { name_offset: 1610, type_: 12, value: 28 }, ucp_type_table { name_offset: 1629, type_: 12, value: 29 }, ucp_type_table { name_offset: 1634, type_: 12, value: 29 }, ucp_type_table { name_offset: 1651, type_: 3, value: 129 }, ucp_type_table { name_offset: 1667, type_: 12, value: 35 }, ucp_type_table { name_offset: 1672, type_: 3, value: 107 }, ucp_type_table { name_offset: 1682, type_: 3, value: 132 }, ucp_type_table { name_offset: 1703, type_: 3, value: 131 }, ucp_type_table { name_offset: 1725, type_: 3, value: 105 }, ucp_type_table { name_offset: 1730, type_: 4, value: 56 }, ucp_type_table { name_offset: 1735, type_: 4, value: 56 }, ucp_type_table { name_offset: 1744, type_: 12, value: 36 }, ucp_type_table { name_offset: 1750, type_: 12, value: 36 }, ucp_type_table { name_offset: 1762, type_: 4, value: 58 }, ucp_type_table { name_offset: 1769, type_: 4, value: 49 }, ucp_type_table { name_offset: 1774, type_: 4, value: 28 }, ucp_type_table { name_offset: 1779, type_: 4, value: 15 }, ucp_type_table { name_offset: 1787, type_: 4, value: 28 }, ucp_type_table { name_offset: 1796, type_: 3, value: 168 }, ucp_type_table { name_offset: 1801, type_: 4, value: 49 }, ucp_type_table { name_offset: 1809, type_: 3, value: 113 }, ucp_type_table { name_offset: 1814, type_: 3, value: 113 }, ucp_type_table { name_offset: 1825, type_: 3, value: 165 }, ucp_type_table { name_offset: 1843, type_: 3, value: 104 }, ucp_type_table { name_offset: 1849, type_: 3, value: 104 }, ucp_type_table { name_offset: 1854, type_: 4, value: 68 }, ucp_type_table { name_offset: 1859, type_: 4, value: 68 }, ucp_type_table { name_offset: 1866, type_: 4, value: 75 }, ucp_type_table { name_offset: 1876, type_: 3, value: 170 }, ucp_type_table { name_offset: 1885, type_: 3, value: 165 }, ucp_type_table { name_offset: 1890, type_: 4, value: 15 }, ucp_type_table { name_offset: 1895, type_: 3, value: 170 }, ucp_type_table { name_offset: 1900, type_: 4, value: 58 }, ucp_type_table { name_offset: 1905, type_: 1, value: 1 }, ucp_type_table { name_offset: 1907, type_: 0, value: 0 }, ucp_type_table { name_offset: 1910, type_: 3, value: 124 }, ucp_type_table { name_offset: 1915, type_: 3, value: 101 }, ucp_type_table { name_offset: 1919, type_: 3, value: 101 }, ucp_type_table { name_offset: 1924, type_: 4, value: 0 }, ucp_type_table { name_offset: 1930, type_: 4, value: 0 }, ucp_type_table { name_offset: 1935, type_: 0, value: 0 }, ucp_type_table { name_offset: 1938, type_: 3, value: 118 }, ucp_type_table { name_offset: 1943, type_: 3, value: 118 }, ucp_type_table { name_offset: 1950, type_: 4, value: 37 }, ucp_type_table { name_offset: 1955, type_: 4, value: 37 }, ucp_type_table { name_offset: 1961, type_: 4, value: 69 }, ucp_type_table { name_offset: 1966, type_: 4, value: 39 }, ucp_type_table { name_offset: 1971, type_: 4, value: 69 }, ucp_type_table { name_offset: 1979, type_: 4, value: 39 }, ucp_type_table { name_offset: 1987, type_: 4, value: 55 }, ucp_type_table { name_offset: 1992, type_: 2, value: 5 }, ucp_type_table { name_offset: 1995, type_: 2, value: 6 }, ucp_type_table { name_offset: 1998, type_: 2, value: 7 }, ucp_type_table { name_offset: 2001, type_: 12, value: 37 }, ucp_type_table { name_offset: 2005, type_: 12, value: 37 }, ucp_type_table { name_offset: 2027, type_: 12, value: 38 }, ucp_type_table { name_offset: 2033, type_: 12, value: 38 }, ucp_type_table { name_offset: 2043, type_: 2, value: 8 }, ucp_type_table { name_offset: 2046, type_: 2, value: 9 }, ucp_type_table { name_offset: 2049, type_: 4, value: 50 }, ucp_type_table { name_offset: 2054, type_: 4, value: 50 }, ucp_type_table { name_offset: 2061, type_: 4, value: 52 }, ucp_type_table { name_offset: 2066, type_: 4, value: 52 }, ucp_type_table { name_offset: 2073, type_: 1, value: 2 }, ucp_type_table { name_offset: 2075, type_: 4, value: 70 }, ucp_type_table { name_offset: 2084, type_: 4, value: 70 }, ucp_type_table { name_offset: 2089, type_: 3, value: 157 }, ucp_type_table { name_offset: 2094, type_: 3, value: 157 }, ucp_type_table { name_offset: 2102, type_: 4, value: 16 }, ucp_type_table { name_offset: 2112, type_: 4, value: 59 }, ucp_type_table { name_offset: 2117, type_: 4, value: 59 }, ucp_type_table { name_offset: 2125, type_: 4, value: 71 }, ucp_type_table { name_offset: 2130, type_: 4, value: 71 }, ucp_type_table { name_offset: 2141, type_: 3, value: 153 }, ucp_type_table { name_offset: 2146, type_: 3, value: 153 }, ucp_type_table { name_offset: 2154, type_: 4, value: 83 }, ucp_type_table { name_offset: 2167, type_: 12, value: 39 }, ucp_type_table { name_offset: 2172, type_: 2, value: 10 }, ucp_type_table { name_offset: 2175, type_: 12, value: 40 }, ucp_type_table { name_offset: 2179, type_: 2, value: 11 }, ucp_type_table { name_offset: 2182, type_: 3, value: 158 }, ucp_type_table { name_offset: 2194, type_: 3, value: 158 }, ucp_type_table { name_offset: 2199, type_: 3, value: 128 }, ucp_type_table { name_offset: 2211, type_: 3, value: 140 }, ucp_type_table { name_offset: 2216, type_: 3, value: 140 }, ucp_type_table { name_offset: 2229, type_: 3, value: 135 }, ucp_type_table { name_offset: 2234, type_: 4, value: 61 }, ucp_type_table { name_offset: 2239, type_: 3, value: 135 }, ucp_type_table { name_offset: 2255, type_: 4, value: 61 }, ucp_type_table { name_offset: 2275, type_: 3, value: 136 }, ucp_type_table { name_offset: 2280, type_: 4, value: 16 }, ucp_type_table { name_offset: 2285, type_: 2, value: 12 }, ucp_type_table { name_offset: 2288, type_: 4, value: 72 }, ucp_type_table { name_offset: 2293, type_: 12, value: 40 }, ucp_type_table { name_offset: 2315, type_: 4, value: 26 }, ucp_type_table { name_offset: 2320, type_: 4, value: 26 }, ucp_type_table { name_offset: 2330, type_: 3, value: 141 }, ucp_type_table { name_offset: 2334, type_: 3, value: 141 }, ucp_type_table { name_offset: 2339, type_: 3, value: 128 }, ucp_type_table { name_offset: 2344, type_: 4, value: 77 }, ucp_type_table { name_offset: 2349, type_: 4, value: 77 }, ucp_type_table { name_offset: 2357, type_: 4, value: 20 }, ucp_type_table { name_offset: 2365, type_: 4, value: 20 }, ucp_type_table { name_offset: 2370, type_: 1, value: 3 }, ucp_type_table { name_offset: 2372, type_: 3, value: 143 }, ucp_type_table { name_offset: 2382, type_: 3, value: 169 }, ucp_type_table { name_offset: 2387, type_: 3, value: 169 }, ucp_type_table { name_offset: 2398, type_: 4, value: 88 }, ucp_type_table { name_offset: 2403, type_: 4, value: 88 }, ucp_type_table { name_offset: 2415, type_: 3, value: 142 }, ucp_type_table { name_offset: 2420, type_: 3, value: 143 }, ucp_type_table { name_offset: 2425, type_: 12, value: 41 }, ucp_type_table { name_offset: 2431, type_: 2, value: 13 }, ucp_type_table { name_offset: 2434, type_: 4, value: 80 }, ucp_type_table { name_offset: 2439, type_: 3, value: 111 }, ucp_type_table { name_offset: 2449, type_: 4, value: 48 }, ucp_type_table { name_offset: 2453, type_: 4, value: 48 }, ucp_type_table { name_offset: 2458, type_: 2, value: 14 }, ucp_type_table { name_offset: 2461, type_: 2, value: 15 }, ucp_type_table { name_offset: 2464, type_: 12, value: 41 }, ucp_type_table { name_offset: 2486, type_: 3, value: 154 }, ucp_type_table { name_offset: 2491, type_: 3, value: 154 }, ucp_type_table { name_offset: 2497, type_: 3, value: 161 }, ucp_type_table { name_offset: 2518, type_: 3, value: 103 }, ucp_type_table { name_offset: 2523, type_: 3, value: 103 }, ucp_type_table { name_offset: 2529, type_: 3, value: 119 }, ucp_type_table { name_offset: 2537, type_: 3, value: 119 }, ucp_type_table { name_offset: 2542, type_: 4, value: 78 }, ucp_type_table { name_offset: 2555, type_: 3, value: 105 }, ucp_type_table { name_offset: 2565, type_: 3, value: 142 }, ucp_type_table { name_offset: 2581, type_: 4, value: 73 }, ucp_type_table { name_offset: 2591, type_: 3, value: 112 }, ucp_type_table { name_offset: 2602, type_: 3, value: 159 }, ucp_type_table { name_offset: 2613, type_: 3, value: 130 }, ucp_type_table { name_offset: 2629, type_: 4, value: 57 }, ucp_type_table { name_offset: 2639, type_: 4, value: 91 }, ucp_type_table { name_offset: 2649, type_: 4, value: 95 }, ucp_type_table { name_offset: 2656, type_: 4, value: 95 }, ucp_type_table { name_offset: 2661, type_: 4, value: 12 }, ucp_type_table { name_offset: 2667, type_: 4, value: 57 }, ucp_type_table { name_offset: 2672, type_: 4, value: 12 }, ucp_type_table { name_offset: 2677, type_: 4, value: 81 }, ucp_type_table { name_offset: 2683, type_: 4, value: 81 }, ucp_type_table { name_offset: 2688, type_: 3, value: 109 }, ucp_type_table { name_offset: 2693, type_: 3, value: 109 }, ucp_type_table { name_offset: 2701, type_: 4, value: 91 }, ucp_type_table { name_offset: 2706, type_: 1, value: 4 }, ucp_type_table { name_offset: 2708, type_: 3, value: 139 }, ucp_type_table { name_offset: 2720, type_: 3, value: 144 }, ucp_type_table { name_offset: 2725, type_: 3, value: 144 }, ucp_type_table { name_offset: 2735, type_: 12, value: 42 }, ucp_type_table { name_offset: 2742, type_: 12, value: 42 }, ucp_type_table { name_offset: 2756, type_: 12, value: 43 }, ucp_type_table { name_offset: 2774, type_: 12, value: 43 }, ucp_type_table { name_offset: 2780, type_: 3, value: 145 }, ucp_type_table { name_offset: 2785, type_: 3, value: 145 }, ucp_type_table { name_offset: 2795, type_: 2, value: 16 }, ucp_type_table { name_offset: 2798, type_: 12, value: 44 }, ucp_type_table { name_offset: 2802, type_: 2, value: 17 }, ucp_type_table { name_offset: 2805, type_: 2, value: 18 }, ucp_type_table { name_offset: 2808, type_: 4, value: 73 }, ucp_type_table { name_offset: 2813, type_: 2, value: 19 }, ucp_type_table { name_offset: 2816, type_: 4, value: 47 }, ucp_type_table { name_offset: 2821, type_: 4, value: 47 }, ucp_type_table { name_offset: 2829, type_: 3, value: 132 }, ucp_type_table { name_offset: 2834, type_: 4, value: 74 }, ucp_type_table { name_offset: 2839, type_: 3, value: 116 }, ucp_type_table { name_offset: 2844, type_: 3, value: 116 }, ucp_type_table { name_offset: 2855, type_: 2, value: 20 }, ucp_type_table { name_offset: 2858, type_: 3, value: 136 }, ucp_type_table { name_offset: 2863, type_: 2, value: 21 }, ucp_type_table { name_offset: 2866, type_: 12, value: 44 }, ucp_type_table { name_offset: 2893, type_: 3, value: 131 }, ucp_type_table { name_offset: 2898, type_: 2, value: 22 }, ucp_type_table { name_offset: 2901, type_: 4, value: 74 }, ucp_type_table { name_offset: 2916, type_: 4, value: 43 }, ucp_type_table { name_offset: 2921, type_: 3, value: 107 }, ucp_type_table { name_offset: 2926, type_: 12, value: 45 }, ucp_type_table { name_offset: 2932, type_: 12, value: 45 }, ucp_type_table { name_offset: 2946, type_: 12, value: 46 }, ucp_type_table { name_offset: 2954, type_: 12, value: 47 }, ucp_type_table { name_offset: 2972, type_: 3, value: 122 }, ucp_type_table { name_offset: 2979, type_: 12, value: 47 }, ucp_type_table { name_offset: 2982, type_: 3, value: 122 }, ucp_type_table { name_offset: 2987, type_: 4, value: 86 }, ucp_type_table { name_offset: 2992, type_: 4, value: 25 }, ucp_type_table { name_offset: 2998, type_: 4, value: 25 }, ucp_type_table { name_offset: 3003, type_: 1, value: 5 }, ucp_type_table { name_offset: 3005, type_: 4, value: 54 }, ucp_type_table { name_offset: 3015, type_: 4, value: 54 }, ucp_type_table { name_offset: 3020, type_: 3, value: 130 }, ucp_type_table { name_offset: 3025, type_: 3, value: 121 }, ucp_type_table { name_offset: 3030, type_: 3, value: 121 }, ucp_type_table { name_offset: 3041, type_: 2, value: 23 }, ucp_type_table { name_offset: 3044, type_: 12, value: 49 }, ucp_type_table { name_offset: 3047, type_: 12, value: 48 }, ucp_type_table { name_offset: 3064, type_: 3, value: 151 }, ucp_type_table { name_offset: 3069, type_: 4, value: 62 }, ucp_type_table { name_offset: 3077, type_: 4, value: 40 }, ucp_type_table { name_offset: 3085, type_: 4, value: 40 }, ucp_type_table { name_offset: 3090, type_: 4, value: 62 }, ucp_type_table { name_offset: 3095, type_: 3, value: 146 }, ucp_type_table { name_offset: 3100, type_: 3, value: 146 }, ucp_type_table { name_offset: 3108, type_: 3, value: 171 }, ucp_type_table { name_offset: 3116, type_: 3, value: 171 }, ucp_type_table { name_offset: 3121, type_: 3, value: 151 }, ucp_type_table { name_offset: 3133, type_: 4, value: 75 }, ucp_type_table { name_offset: 3138, type_: 4, value: 17 }, ucp_type_table { name_offset: 3143, type_: 4, value: 17 }, ucp_type_table { name_offset: 3151, type_: 2, value: 24 }, ucp_type_table { name_offset: 3154, type_: 2, value: 25 }, ucp_type_table { name_offset: 3157, type_: 2, value: 26 }, ucp_type_table { name_offset: 3160, type_: 12, value: 49 }, ucp_type_table { name_offset: 3171, type_: 4, value: 87 }, ucp_type_table { name_offset: 3176, type_: 4, value: 87 }, ucp_type_table { name_offset: 3184, type_: 3, value: 159 }, ucp_type_table { name_offset: 3189, type_: 3, value: 137 }, ucp_type_table { name_offset: 3194, type_: 3, value: 137 }, ucp_type_table { name_offset: 3206, type_: 3, value: 155 }, ucp_type_table { name_offset: 3211, type_: 3, value: 155 }, ucp_type_table { name_offset: 3219, type_: 12, value: 54 }, ucp_type_table { name_offset: 3225, type_: 12, value: 48 }, ucp_type_table { name_offset: 3231, type_: 3, value: 117 }, ucp_type_table { name_offset: 3236, type_: 3, value: 117 }, ucp_type_table { name_offset: 3246, type_: 4, value: 96 }, ucp_type_table { name_offset: 3251, type_: 4, value: 96 }, ucp_type_table { name_offset: 3259, type_: 4, value: 46 }, ucp_type_table { name_offset: 3264, type_: 4, value: 46 }, ucp_type_table { name_offset: 3276, type_: 4, value: 6 }, ucp_type_table { name_offset: 3281, type_: 4, value: 6 }, ucp_type_table { name_offset: 3288, type_: 4, value: 33 }, ucp_type_table { name_offset: 3296, type_: 4, value: 36 }, ucp_type_table { name_offset: 3301, type_: 4, value: 36 }, ucp_type_table { name_offset: 3310, type_: 4, value: 38 }, ucp_type_table { name_offset: 3316, type_: 3, value: 124 }, ucp_type_table { name_offset: 3324, type_: 3, value: 125 }, ucp_type_table { name_offset: 3332, type_: 3, value: 172 }, ucp_type_table { name_offset: 3338, type_: 4, value: 63 }, ucp_type_table { name_offset: 3343, type_: 4, value: 63 }, ucp_type_table { name_offset: 3349, type_: 4, value: 38 }, ucp_type_table { name_offset: 3354, type_: 3, value: 111 }, ucp_type_table { name_offset: 3359, type_: 4, value: 13 }, ucp_type_table { name_offset: 3365, type_: 4, value: 13 }, ucp_type_table { name_offset: 3370, type_: 4, value: 82 }, ucp_type_table { name_offset: 3375, type_: 3, value: 166 }, ucp_type_table { name_offset: 3382, type_: 4, value: 82 }, ucp_type_table { name_offset: 3389, type_: 3, value: 125 }, ucp_type_table { name_offset: 3394, type_: 3, value: 172 }, ucp_type_table { name_offset: 3399, type_: 4, value: 14 }, ucp_type_table { name_offset: 3404, type_: 4, value: 14 }, ucp_type_table { name_offset: 3411, type_: 12, value: 50 }, ucp_type_table { name_offset: 3416, type_: 12, value: 50 }, ucp_type_table { name_offset: 3436, type_: 4, value: 45 }, ucp_type_table { name_offset: 3441, type_: 4, value: 33 }, ucp_type_table { name_offset: 3446, type_: 4, value: 7 }, ucp_type_table { name_offset: 3451, type_: 4, value: 7 }, ucp_type_table { name_offset: 3458, type_: 4, value: 18 }, ucp_type_table { name_offset: 3463, type_: 4, value: 19 }, ucp_type_table { name_offset: 3471, type_: 4, value: 19 }, ucp_type_table { name_offset: 3476, type_: 4, value: 45 }, ucp_type_table { name_offset: 3485, type_: 4, value: 76 }, ucp_type_table { name_offset: 3490, type_: 4, value: 76 }, ucp_type_table { name_offset: 3498, type_: 3, value: 166 }, ucp_type_table { name_offset: 3503, type_: 4, value: 97 }, ucp_type_table { name_offset: 3510, type_: 4, value: 97 }, ucp_type_table { name_offset: 3515, type_: 3, value: 173 }, ucp_type_table { name_offset: 3526, type_: 3, value: 173 }, ucp_type_table { name_offset: 3531, type_: 4, value: 92 }, ucp_type_table { name_offset: 3536, type_: 4, value: 98 }, ucp_type_table { name_offset: 3549, type_: 4, value: 98 }, ucp_type_table { name_offset: 3554, type_: 3, value: 108 }, ucp_type_table { name_offset: 3559, type_: 3, value: 108 }, ucp_type_table { name_offset: 3568, type_: 12, value: 51 }, ucp_type_table { name_offset: 3574, type_: 12, value: 51 }, ucp_type_table { name_offset: 3591, type_: 3, value: 99 }, ucp_type_table { name_offset: 3599, type_: 12, value: 52 }, ucp_type_table { name_offset: 3605, type_: 12, value: 52 }, ucp_type_table { name_offset: 3615, type_: 3, value: 120 }, ucp_type_table { name_offset: 3619, type_: 3, value: 120 }, ucp_type_table { name_offset: 3624, type_: 12, value: 53 }, ucp_type_table { name_offset: 3642, type_: 3, value: 167 }, ucp_type_table { name_offset: 3647, type_: 3, value: 167 }, ucp_type_table { name_offset: 3656, type_: 12, value: 53 }, ucp_type_table { name_offset: 3659, type_: 3, value: 162 }, ucp_type_table { name_offset: 3666, type_: 3, value: 147 }, ucp_type_table { name_offset: 3671, type_: 3, value: 147 }, ucp_type_table { name_offset: 3682, type_: 3, value: 162 }, ucp_type_table { name_offset: 3687, type_: 12, value: 54 }, ucp_type_table { name_offset: 3698, type_: 12, value: 54 }, ucp_type_table { name_offset: 3705, type_: 5, value: 0 }, ucp_type_table { name_offset: 3709, type_: 12, value: 55 }, ucp_type_table { name_offset: 3714, type_: 12, value: 55 }, ucp_type_table { name_offset: 3726, type_: 12, value: 56 }, ucp_type_table { name_offset: 3731, type_: 12, value: 56 }, ucp_type_table { name_offset: 3740, type_: 3, value: 112 }, ucp_type_table { name_offset: 3745, type_: 7, value: 0 }, ucp_type_table { name_offset: 3749, type_: 6, value: 0 }, ucp_type_table { name_offset: 3753, type_: 3, value: 115 }, ucp_type_table { name_offset: 3758, type_: 10, value: 0 }, ucp_type_table { name_offset: 3762, type_: 8, value: 0 }, ucp_type_table { name_offset: 3766, type_: 4, value: 89 }, ucp_type_table { name_offset: 3771, type_: 4, value: 89 }, ucp_type_table { name_offset: 3778, type_: 4, value: 31 }, ucp_type_table { name_offset: 3781, type_: 4, value: 31 }, ucp_type_table { name_offset: 3786, type_: 1, value: 6 }, ucp_type_table { name_offset: 3788, type_: 3, value: 156 }, ucp_type_table { name_offset: 3804, type_: 3, value: 156 }, ucp_type_table { name_offset: 3809, type_: 3, value: 107 }, ucp_type_table { name_offset: 3814, type_: 2, value: 27 }, ucp_type_table { name_offset: 3817, type_: 2, value: 28 }, ucp_type_table { name_offset: 3820, type_: 2, value: 29 }, ucp_type_table { name_offset: 3823, type_: 3, value: 100 }, ucp_type_table { name_offset: 3828, type_: 3, value: 99 }]
let _pcre2_utt_size_8: c_ulong = 518
extern var _pcre2_default_compile_context_8: pcre2_real_compile_context_8
extern var _pcre2_default_convert_context_8: pcre2_real_convert_context_8
extern var _pcre2_default_match_context_8: pcre2_real_match_context_8
extern let _pcre2_default_tables_8: [1088]u8
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
extern var _pcre2_unicode_version_8: *const i8
extern let _pcre2_ebcdic_1047_to_ascii_8: *u8
extern let _pcre2_ascii_to_ebcdic_1047_8: *u8
// untranslatable fn-like macro
fn ACROSSCHAR() -> Never:
    comptime_error("untranslatable C macro: ACROSSCHAR")
fn ARR_SIZE[T](x: T) -> T:
    sizeof[T]()
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
