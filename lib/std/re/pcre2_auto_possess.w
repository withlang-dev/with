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
fn _pcre2_auto_possessify_8(__param_code: *mut u8, cb: *const compile_block_8) -> c_int:
    var code = __param_code
    var c: u8
    var end: *const u8
    var repeat_opcode: *mut u8
    var list: [8]c_uint
    var rec_limit: c_int = 1000
    var utf: c_int = (if ((cb.external_options & 524288)) != 0: 1 else: 0)
    var ucp: c_int = (if ((cb.external_options & 131072)) != 0: 1 else: 0)
    while true:
        (c = (unsafe: *code))
        if (c >= OP_TABLE_LENGTH):
            return -1
        
        if ((c >= OP_STAR) and (c <= OP_TYPEPOSUPTO)):
            c = c - (get_repeat_base(c) - OP_STAR)
            (end = (if (c <= OP_MINUPTO): get_chr_property_list((code as *const u8), utf, ucp, cb.fcc, (&list[0] as *mut c_uint)) else: (null as *const u8)))
            ((&list[0] as *mut c_uint)[1] = (if (((c == OP_STAR) or (c == OP_PLUS)) or (c == OP_QUERY)) or (c == OP_UPTO): 1 else: 0))
            if ((end != (null as *const u8)) and (compare_opcodes(end, utf, ucp, cb, ((&list[0] as *mut c_uint) as *const c_uint), end, ((&rec_limit as *const c_int) as *mut c_int)) != 0)):
                match c
                    OP_STAR =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSSTAR - OP_STAR)
                    OP_MINSTAR =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSSTAR - OP_MINSTAR)
                    OP_PLUS =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSPLUS - OP_PLUS)
                    OP_MINPLUS =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSPLUS - OP_MINPLUS)
                    OP_QUERY =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSQUERY - OP_QUERY)
                    OP_MINQUERY =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSQUERY - OP_MINQUERY)
                    OP_UPTO =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSUPTO - OP_UPTO)
                    OP_MINUPTO =>
                        (unsafe: *code) = (unsafe: *code) + (OP_POSUPTO - OP_MINUPTO)
                    _ => 0
                
            
            (c = (unsafe: *code))
        else:
            if ((c == OP_CLASS) or (c == OP_NCLASS)):
                (repeat_opcode = ((code + (1 as isize as usize)) + ((32 / sizeof[u8]()))))
                (c = (unsafe: *repeat_opcode))
                if ((c >= OP_CRSTAR) and (c <= OP_CRMINRANGE)):
                    (end = get_chr_property_list((code as *const u8), utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))
                    ((&list[0] as *mut c_uint)[1] = (if ((c & 1)) == 0: 1 else: 0))
                    if ((end != (null as *const u8)) and (compare_opcodes(end, utf, ucp, cb, ((&list[0] as *mut c_uint) as *const c_uint), end, ((&rec_limit as *const c_int) as *mut c_int)) != 0)):
                        match c
                            OP_CRSTAR => 0
                            OP_CRPLUS => 0
                            OP_CRQUERY => 0
                            OP_CRRANGE => 0
                            _ => 0
                        
                    
                
                (c = (unsafe: *code))
        
        match c
            OP_END =>
                return 0
            OP_TYPESTAR => 0
            OP_TYPEUPTO => 0
            OP_CALLOUT_STR =>
                code = code + ((((((((code)[(1 + (2 * 2))] as c_uint) << 8))) | (code)[(((1 + (2 * 2))) + 1)])) as c_uint)
            OP_MARK => 0
            _ => 0
        
        code = code + _pcre2_OP_lengths_8[c]
        (utf)


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
var autoposstab: [17][21]u8 = [[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]]
fn get_repeat_base(c: u8) -> u8:
    return (if (c > OP_TYPEPOSUPTO): c else: (if (c >= OP_TYPESTAR): OP_TYPESTAR else: (if (c >= OP_NOTSTARI): OP_NOTSTARI else: (if (c >= OP_NOTSTAR): OP_NOTSTAR else: (if (c >= OP_STARI): OP_STARI else: OP_STAR)))))

fn get_chr_property_list(__param_code: *const u8, utf: c_int, ucp: c_int, fcc: *const u8, list: *mut c_uint) -> *const u8:
    var code = __param_code
    var c: u8 = (unsafe: *code)
    var base: u8
    var end: *const u8
    var class_end: *const u8
    var chr: c_uint
    utf
    ucp
    (list[0] = c)
    (list[1] = 0)
    (code = code + 1)
    if ((c >= OP_STAR) and (c <= OP_TYPEPOSUPTO)):
        (base = get_repeat_base(c))
        c = c - ((base - OP_STAR))
        if ((((c == OP_UPTO) or (c == OP_MINUPTO)) or (c == OP_EXACT)) or (c == OP_POSUPTO)):
            code = code + 2
        
        (list[1] = ((if (((c != OP_PLUS) and (c != OP_MINPLUS)) and (c != OP_EXACT)) and (c != OP_POSPLUS): 1 else: 0)))
        match base
            OP_STAR =>
                (list[0] = 29)
            OP_STARI =>
                (list[0] = 30)
            OP_NOTSTAR =>
                (list[0] = 31)
            OP_NOTSTARI =>
                (list[0] = 32)
            OP_TYPESTAR =>
                (list[0] = (unsafe: *code))
                (code = code + 1)
            _ => 0
        
        (c = list[0])

    match c
        OP_NOT_DIGIT =>
            0
            (list[2] = chr)
            (list[3] = (4294967295 as c_uint))
            return code
        OP_CHAR =>
            0
            (list[2] = chr)
            (list[3] = (4294967295 as c_uint))
            return code
        OP_CHARI =>
            (chr = (unsafe: *code))
            (code = code + 1)
            0
            (list[2] = chr)
            (list[3] = fcc[chr])
            if (chr == list[3]):
                (list[3] = (4294967295 as c_uint))
            else:
                (list[4] = (4294967295 as c_uint))
            return code
        OP_NCLASS =>
            (class_end = end)
            match (unsafe: *end)
                OP_CRSTAR =>
                    (end = end + 1)
                OP_CRPLUS => 0
                OP_CRRANGE =>
                    end = end + (1 + (2 * 2))
                _ => 0
            (list[2] = ((((end as usize -% code as usize) / sizeof[u8]())) as c_uint))
            (list[3] = ((((end as usize -% class_end as usize) / sizeof[u8]())) as c_uint))
            return end
        _ => 0

    return (null as *const u8)

fn compare_opcodes(__param_code: *const u8, utf: c_int, ucp: c_int, cb: *const compile_block_8, base_list: *const c_uint, base_end: *const u8, rec_limit: *mut c_int) -> c_int:
    var code = __param_code
    var c: u8
    var list: [8]c_uint
    var chr_ptr: *const c_uint
    var ochr_ptr: *const c_uint
    var list_ptr: *const c_uint
    var next_code: *const u8
    var class_bitset: *const u8
    var set1: *const u8
    var set2: *const u8
    var set_end: *const u8
    var chr: c_uint
    var accepted: c_int
    var invert_bits: c_int
    var entered_a_group: c_int = 0
    if ((((unsafe: *rec_limit)) = ((unsafe: *rec_limit)) - 1) <= 0):
        return 0

    while true:
        var bracode: *const u8
        (c = (unsafe: *code))
        if (c == OP_CALLOUT):
            code = code + _pcre2_OP_lengths_8[c]
            continue
        
        if (c == OP_CALLOUT_STR):
            code = code + ((((((((code)[(1 + (2 * 2))] as c_uint) << 8))) | (code)[(((1 + (2 * 2))) + 1)])) as c_uint)
            continue
        
        if (c == OP_ALT):
            while true:
                code = code + ((((((((code)[1] as c_uint) << 8))) | (code)[((1) + 1)])) as c_uint)
                if not (((unsafe: *code) == OP_ALT)):
                    break
            
            (c = (unsafe: *code))
        
        match c
            OP_END =>
                return (if base_list[1] != 0: 1 else: 0)
            OP_KET =>
                (bracode = (code - ((((((((code)[1] as c_uint) << 8))) | (code)[((1) + 1)])) as c_uint)))
                match (unsafe: *bracode)
                    OP_CBRA => 0
                    OP_SCRIPT_RUN =>
                        if ((base_list[0] != 29) and (base_list[0] != 30)):
                            return 0
                    OP_ASSERT =>
                        return (if entered_a_group != 0: 0 else: 1)
                    OP_ASSERTBACK =>
                        return (if entered_a_group != 0: 0 else: 1)
                    OP_ASSERT_NA => 0
                    _ => 0
                code = code + _pcre2_OP_lengths_8[c]
                continue
                code = code + _pcre2_OP_lengths_8[c]
                while ((unsafe: *next_code) == OP_ALT):
                    if (not ((compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0))):
                        return 0
                    
                    (code = ((next_code + (1 as isize as usize)) + (2 as isize as usize)))
                    next_code = next_code + ((((((((next_code)[1] as c_uint) << 8))) | (next_code)[((1) + 1)])) as c_uint)
                (entered_a_group = 1)
                continue
                if ((((unsafe: *next_code) != OP_BRA) and ((unsafe: *next_code) != OP_CBRA)) and ((unsafe: *next_code) != OP_ONCE)):
                    return 0
                while true:
                    next_code = next_code + ((((((((next_code)[1] as c_uint) << 8))) | (next_code)[((1) + 1)])) as c_uint)
                    if not (((unsafe: *next_code) == OP_ALT)):
                        break
                next_code = next_code + (1 + 2)
                if (not ((compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0))):
                    return 0
                code = code + _pcre2_OP_lengths_8[c]
                continue
            OP_ONCE =>
                code = code + _pcre2_OP_lengths_8[c]
                while ((unsafe: *next_code) == OP_ALT):
                    if (not ((compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0))):
                        return 0
                    
                    (code = ((next_code + (1 as isize as usize)) + (2 as isize as usize)))
                    next_code = next_code + ((((((((next_code)[1] as c_uint) << 8))) | (next_code)[((1) + 1)])) as c_uint)
                (entered_a_group = 1)
                continue
                if ((((unsafe: *next_code) != OP_BRA) and ((unsafe: *next_code) != OP_CBRA)) and ((unsafe: *next_code) != OP_ONCE)):
                    return 0
                while true:
                    next_code = next_code + ((((((((next_code)[1] as c_uint) << 8))) | (next_code)[((1) + 1)])) as c_uint)
                    if not (((unsafe: *next_code) == OP_ALT)):
                        break
                next_code = next_code + (1 + 2)
                if (not ((compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0))):
                    return 0
                code = code + _pcre2_OP_lengths_8[c]
                continue
            OP_BRAZERO =>
                if ((((unsafe: *next_code) != OP_BRA) and ((unsafe: *next_code) != OP_CBRA)) and ((unsafe: *next_code) != OP_ONCE)):
                    return 0
                while true:
                    next_code = next_code + ((((((((next_code)[1] as c_uint) << 8))) | (next_code)[((1) + 1)])) as c_uint)
                    if not (((unsafe: *next_code) == OP_ALT)):
                        break
                next_code = next_code + (1 + 2)
                if (not ((compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0))):
                    return 0
                code = code + _pcre2_OP_lengths_8[c]
                continue
            _ => 0
        
        (code = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))
        if (code == (null as *const u8)):
            return 0
        
        if (base_list[0] == 29):
            (chr_ptr = (base_list + (2 as isize as usize)))
            (list_ptr = ((&list[0] as *mut c_uint) as *const c_uint))
        else:
            if ((&list[0] as *mut c_uint)[0] == 29):
                (chr_ptr = (((&list[0] as *mut c_uint) + (2 as isize as usize)) as *const c_uint))
                (list_ptr = base_list)
            else:
                if (((base_list[0] == 110) or ((&list[0] as *mut c_uint)[0] == 110)) or ((not ((utf != 0))) and ((base_list[0] == 111) or ((&list[0] as *mut c_uint)[0] == 111)))):
                    if ((base_list[0] == 110) or ((not ((utf != 0))) and (base_list[0] == 111))):
                        (set1 = (((base_end - base_list[2])) as *const u8))
                        (list_ptr = ((&list[0] as *mut c_uint) as *const c_uint))
                    else:
                        (set1 = (((code - (&list[0] as *mut c_uint)[2])) as *const u8))
                        (list_ptr = base_list)
                    
                    (invert_bits = 0)
                    match list_ptr[0]
                        110 => 0
                        6 =>
                            (invert_bits = 1)
                            (set2 = (((cb.cbits + (64 as isize as usize))) as *const u8))
                        7 =>
                            (set2 = (((cb.cbits + (64 as isize as usize))) as *const u8))
                        8 =>
                            (invert_bits = 1)
                            (set2 = (((cb.cbits + (0 as isize as usize))) as *const u8))
                        9 =>
                            (set2 = (((cb.cbits + (0 as isize as usize))) as *const u8))
                        10 =>
                            (invert_bits = 1)
                            (set2 = (((cb.cbits + (160 as isize as usize))) as *const u8))
                        11 =>
                            (set2 = (((cb.cbits + (160 as isize as usize))) as *const u8))
                        _ =>
                            return 0
                    
                    (set_end = (set1 + (32 as isize as usize)))
                    if (invert_bits != 0):
                        while true:
                            if ((((unsafe: *(set1 = set1 + 1)) & (0 - ((unsafe: *(set2 = set2 + 1))) - 1))) != 0):
                                return 0
                            
                            if not ((set1 < set_end)):
                                break
                        
                    else:
                        while true:
                            if ((((unsafe: *(set1 = set1 + 1)) & (unsafe: *(set2 = set2 + 1)))) != 0):
                                return 0
                            
                            if not ((set1 < set_end)):
                                break
                        
                    
                    if ((&list[0] as *mut c_uint)[1] == 0):
                        return 1
                    
                    continue
                else:
                    var leftop: c_uint
                    var rightop: c_uint
                    (leftop = base_list[0])
                    (rightop = (&list[0] as *mut c_uint)[0])
                    (accepted = (if ((((leftop >= 6) and (leftop <= 22)) and (rightop >= 6)) and (rightop <= 26)) and ((&(&autoposstab[0] as *mut [21]u8)[(leftop -% 6)][0] as *mut u8)[(rightop -% 6)] != 0): 1 else: 0))
                    if (not ((accepted != 0))):
                        return 0
                    
                    if ((&list[0] as *mut c_uint)[1] == 0):
                        return 1
                    
                    continue
        
        while true:
            (chr = (unsafe: *chr_ptr))
            match list_ptr[0]
                29 =>
                    (ochr_ptr = (list_ptr + (2 as isize as usize)))
                    while true:
                        if (chr == (unsafe: *ochr_ptr)):
                            return 0
                        
                        (ochr_ptr = ochr_ptr + 1)
                        if not (((unsafe: *ochr_ptr) != 4294967295)):
                            break
                31 =>
                    (ochr_ptr = (list_ptr + (2 as isize as usize)))
                    while true:
                        if (chr == (unsafe: *ochr_ptr)):
                            break
                        
                        (ochr_ptr = ochr_ptr + 1)
                        if not (((unsafe: *ochr_ptr) != 4294967295)):
                            break
                    if ((unsafe: *ochr_ptr) == 4294967295):
                        return 0
                7 =>
                    if ((chr < 256) and (((cb.ctypes[chr] & 8)) != 0)):
                        return 0
                6 =>
                    if ((chr > 255) or (((cb.ctypes[chr] & 8)) == 0)):
                        return 0
                9 =>
                    if ((chr < 256) and (((cb.ctypes[chr] & 1)) != 0)):
                        return 0
                8 =>
                    if ((chr > 255) or (((cb.ctypes[chr] & 1)) == 0)):
                        return 0
                11 =>
                    if ((chr < 255) and (((cb.ctypes[chr] & 16)) != 0)):
                        return 0
                10 =>
                    if ((chr > 255) or (((cb.ctypes[chr] & 16)) == 0)):
                        return 0
                19 =>
                    match chr
                        9 => 0
                        _ => 0
                18 =>
                    match chr
                        9 =>
                            return 0
                        _ =>
                            return 0
                17 => 0
                20 =>
                    match chr
                        10 =>
                            return 0
                        _ =>
                            return 0
                25 => 0
                24 => 0
                111 =>
                    if (chr > 255):
                        return 0
                    if (chr > 255):
                        break
                    (class_bitset = (((((if (list_ptr == ((&list[0] as *mut c_uint) as *const c_uint)): code else: base_end)) - list_ptr[2])) as *const u8))
                    if (((class_bitset[(chr >> 3)] & ((1 << ((chr & 7)))))) != 0):
                        return 0
                110 =>
                    if (chr > 255):
                        break
                    (class_bitset = (((((if (list_ptr == ((&list[0] as *mut c_uint) as *const c_uint)): code else: base_end)) - list_ptr[2])) as *const u8))
                    if (((class_bitset[(chr >> 3)] & ((1 << ((chr & 7)))))) != 0):
                        return 0
                _ =>
                    return 0
            
            (chr_ptr = chr_ptr + 1)
            if not (((unsafe: *chr_ptr) != 4294967295)):
                break
        
        if ((&list[0] as *mut c_uint)[1] == 0):
            return 1
        

    return 0

