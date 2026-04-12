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
extern var _pcre2_posix_class_maps8: *c_int
extern fn _pcre2_update_classbits_8(ptype: c_uint, pdata: c_uint, negated: c_int, classbits: *mut u8) -> void
fn _pcre2_compile_class_not_nested_8(options: c_uint, xoptions: c_uint, start_ptr: *mut c_uint, pcode: *mut *mut u8, negate_class: c_int, has_bitmap: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint:
    var pptr__goto_1092_11: *mut c_uint = null
    var code__goto_1093_14: *mut u8 = null
    var should_flip_negation__goto_1094_6: c_int = 0
    var cbits__goto_1095_16: *const u8 = null
    var classbits__goto_1098_16: *mut u8 = null
    var utf__goto_1103_6: c_int = 0
    var meta__goto_1190_12: c_uint = 0
    var local_negate__goto_1191_8: c_int = 0
    var posix_class__goto_1192_7: c_int = 0
    var taboffset__goto_1193_7: c_int = 0
    var tabopt__goto_1193_18: c_int = 0
    var pbits__goto_1194_22: class_bits_storage
    var escape__goto_1195_12: c_uint = 0
    var c__goto_1195_20: c_uint = 0
    var i__goto_1295_18: c_int = 0
    var i__goto_1298_18: c_int = 0
    var classwords__goto_1328_17: *mut c_uint = null
    var i__goto_1331_18: c_int = 0
    var i__goto_1334_18: c_int = 0
    var i__goto_1356_16: c_int = 0
    var i__goto_1361_16: c_int = 0
    var i__goto_1366_16: c_int = 0
    var i__goto_1371_16: c_int = 0
    var i__goto_1383_16: c_int = 0
    var i__goto_1388_16: c_int = 0
    var d__goto_1513_14: c_uint = 0
    var classwords__goto_1856_13: *mut c_uint = null
    var i__goto_1858_12: c_int = 0
    var classwords__goto_1864_19: *const c_uint = null
    var i__goto_1865_7: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                pptr__goto_1092_11 = start_ptr
                code__goto_1093_14 = (unsafe: *pcode)
                cbits__goto_1095_16 = cb.cbits
                classbits__goto_1098_16 = (&cb.classbits.classbits[0] as *mut u8)
                utf__goto_1103_6 = 0
                has_bitmap
                if __goto_pending != 0:
                    continue
                errorcodeptr
                if __goto_pending != 0:
                    continue
                lengthptr
                if __goto_pending != 0:
                    continue
                (should_flip_negation__goto_1094_6 = 0)
                if __goto_pending != 0:
                    continue
                with_memset((classbits__goto_1098_16 as *mut c_void) as *i8, 0, 32 as i64)
                if __goto_pending != 0:
                    continue
                while (1 != 0):
                    meta__goto_1190_12 = (unsafe: *((pptr__goto_1092_11 = pptr__goto_1092_11 + 1)))
                    if __goto_pending != 0:
                        break
                    match ((meta__goto_1190_12 & (4294901760 as c_uint)))
                        2149580800 =>
                            (posix_class__goto_1192_7 = (unsafe: *pptr__goto_1092_11))
                            (pptr__goto_1092_11 = pptr__goto_1092_11 + 1)
                            if (local_negate__goto_1191_8 != 0):
                                (should_flip_negation__goto_1094_6 = 1)
                            if ((((options & 8)) != 0) and (posix_class__goto_1192_7 <= 2)):
                                (posix_class__goto_1192_7 = 0)
                            posix_class__goto_1192_7 = posix_class__goto_1192_7 * 3
                            with_memcpy(((&pbits__goto_1194_22.classbits[0] as *mut u8) as *mut c_void) as *i8, ((cbits__goto_1095_16 + (_pcre2_posix_class_maps8[posix_class__goto_1192_7] as isize as usize)) as *const c_void) as *i8, 32 as i64)
                            (taboffset__goto_1193_7 = _pcre2_posix_class_maps8[(posix_class__goto_1192_7 + 1)])
                            (tabopt__goto_1193_18 = _pcre2_posix_class_maps8[(posix_class__goto_1192_7 + 2)])
                            if (taboffset__goto_1193_7 >= 0):
                                if (tabopt__goto_1193_18 >= 0):
                                    i__goto_1295_18 = 0
                                    while (i__goto_1295_18 < 32):
                                        (&pbits__goto_1194_22.classbits[0] as *mut u8)[i__goto_1295_18] = (&pbits__goto_1194_22.classbits[0] as *mut u8)[i__goto_1295_18] | cbits__goto_1095_16[(i__goto_1295_18 + taboffset__goto_1193_7)]
                                        (i__goto_1295_18 = i__goto_1295_18 + 1)
                                        if __goto_pending != 0:
                                            break
                                else:
                                    i__goto_1298_18 = 0
                                    while (i__goto_1298_18 < 32):
                                        (&pbits__goto_1194_22.classbits[0] as *mut u8)[i__goto_1298_18] = (&pbits__goto_1194_22.classbits[0] as *mut u8)[i__goto_1298_18] & (((0 - cbits__goto_1095_16[(i__goto_1298_18 + taboffset__goto_1193_7)] - 1)) as u8)
                                        (i__goto_1298_18 = i__goto_1298_18 + 1)
                                        if __goto_pending != 0:
                                            break
                                if __goto_pending != 0:
                                    break
                            if (tabopt__goto_1193_18 < 0):
                                (tabopt__goto_1193_18 = (0 - tabopt__goto_1193_18))
                            if (tabopt__goto_1193_18 == 1):
                                (&pbits__goto_1194_22.classbits[0] as *mut u8)[1] = (&pbits__goto_1194_22.classbits[0] as *mut u8)[1] & (0 - 60 - 1)
                            else:
                                if (tabopt__goto_1193_18 == 2):
                                    (&pbits__goto_1194_22.classbits[0] as *mut u8)[11] = (&pbits__goto_1194_22.classbits[0] as *mut u8)[11] & 127
                            classwords__goto_1328_17 = (&cb.classbits.classwords[0] as *mut c_uint)
                            if __goto_pending != 0:
                                break
                            if (local_negate__goto_1191_8 != 0):
                                i__goto_1331_18 = 0
                                while (i__goto_1331_18 < 8):
                                    classwords__goto_1328_17[i__goto_1331_18] = classwords__goto_1328_17[i__goto_1331_18] | (((0 - (&pbits__goto_1194_22.classwords[0] as *mut c_uint)[i__goto_1331_18] - 1)) as c_uint)
                                    (i__goto_1331_18 = i__goto_1331_18 + 1)
                                    if __goto_pending != 0:
                                        break
                            else:
                                i__goto_1334_18 = 0
                                while (i__goto_1334_18 < 8):
                                    classwords__goto_1328_17[i__goto_1334_18] = classwords__goto_1328_17[i__goto_1334_18] | (&pbits__goto_1194_22.classwords[0] as *mut c_uint)[i__goto_1334_18]
                                    (i__goto_1334_18 = i__goto_1334_18 + 1)
                                    if __goto_pending != 0:
                                        break
                            if __goto_pending != 0:
                                break
                            continue
                            (meta__goto_1190_12 = (unsafe: *pptr__goto_1092_11))
                            (pptr__goto_1092_11 = pptr__goto_1092_11 + 1)
                        2147811328 =>
                            (meta__goto_1190_12 = (unsafe: *pptr__goto_1092_11))
                            (pptr__goto_1092_11 = pptr__goto_1092_11 + 1)
                        2149318656 =>
                            (escape__goto_1195_12 = ((meta__goto_1190_12 & 65535)))
                            match escape__goto_1195_12
                                7 =>
                                    i__goto_1356_16 = 0
                                    while (i__goto_1356_16 < 32):
                                        classbits__goto_1098_16[i__goto_1356_16] = classbits__goto_1098_16[i__goto_1356_16] | cbits__goto_1095_16[(i__goto_1356_16 + 64)]
                                        (i__goto_1356_16 = i__goto_1356_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                6 =>
                                    (should_flip_negation__goto_1094_6 = 1)
                                    i__goto_1361_16 = 0
                                    while (i__goto_1361_16 < 32):
                                        classbits__goto_1098_16[i__goto_1361_16] = classbits__goto_1098_16[i__goto_1361_16] | (((0 - cbits__goto_1095_16[(i__goto_1361_16 + 64)] - 1)) as u8)
                                        (i__goto_1361_16 = i__goto_1361_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                11 =>
                                    i__goto_1366_16 = 0
                                    while (i__goto_1366_16 < 32):
                                        classbits__goto_1098_16[i__goto_1366_16] = classbits__goto_1098_16[i__goto_1366_16] | cbits__goto_1095_16[(i__goto_1366_16 + 160)]
                                        (i__goto_1366_16 = i__goto_1366_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                10 =>
                                    (should_flip_negation__goto_1094_6 = 1)
                                    i__goto_1371_16 = 0
                                    while (i__goto_1371_16 < 32):
                                        classbits__goto_1098_16[i__goto_1371_16] = classbits__goto_1098_16[i__goto_1371_16] | (((0 - cbits__goto_1095_16[(i__goto_1371_16 + 160)] - 1)) as u8)
                                        (i__goto_1371_16 = i__goto_1371_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                9 =>
                                    i__goto_1383_16 = 0
                                    while (i__goto_1383_16 < 32):
                                        classbits__goto_1098_16[i__goto_1383_16] = classbits__goto_1098_16[i__goto_1383_16] | cbits__goto_1095_16[(i__goto_1383_16 + 0)]
                                        (i__goto_1383_16 = i__goto_1383_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                8 =>
                                    (should_flip_negation__goto_1094_6 = 1)
                                    i__goto_1388_16 = 0
                                    while (i__goto_1388_16 < 32):
                                        classbits__goto_1098_16[i__goto_1388_16] = classbits__goto_1098_16[i__goto_1388_16] | (((0 - cbits__goto_1095_16[(i__goto_1388_16 + 0)] - 1)) as u8)
                                        (i__goto_1388_16 = i__goto_1388_16 + 1)
                                        if __goto_pending != 0:
                                            break
                                19 =>
                                    add_list_to_class((options & (0 - 8 - 1)), xoptions, cb, _pcre2_hspace_list_8)
                                18 =>
                                    add_not_list_to_class((options & (0 - 8 - 1)), xoptions, cb, _pcre2_hspace_list_8)
                                21 =>
                                    add_list_to_class((options & (0 - 8 - 1)), xoptions, cb, _pcre2_vspace_list_8)
                                20 =>
                                    add_not_list_to_class((options & (0 - 8 - 1)), xoptions, cb, _pcre2_vspace_list_8)
                                _ => 0
                            continue
                            if (meta__goto_1190_12 < 2147483648):
                                break
                            __pc = 1
                            __goto_pending = 1
                        _ =>
                            if (meta__goto_1190_12 < 2147483648):
                                break
                            __pc = 1
                            __goto_pending = 1
                    if __goto_pending != 0:
                        break
                    (c__goto_1195_20 = meta__goto_1190_12)
                    if __goto_pending != 0:
                        break
                    if ((c__goto_1195_20 == 13) or (c__goto_1195_20 == 10)):
                        cb.external_flags = cb.external_flags | 2048
                    if __goto_pending != 0:
                        break
                    if (((unsafe: *pptr__goto_1092_11) == 2149777408) or ((unsafe: *pptr__goto_1092_11) == 2149711872)):
                        (pptr__goto_1092_11 = pptr__goto_1092_11 + 1)
                        if __goto_pending != 0:
                            break
                        (d__goto_1513_14 = (unsafe: *pptr__goto_1092_11))
                        (pptr__goto_1092_11 = pptr__goto_1092_11 + 1)
                        if __goto_pending != 0:
                            break
                        if (d__goto_1513_14 == 2147811328):
                            (d__goto_1513_14 = (unsafe: *pptr__goto_1092_11))
                            (pptr__goto_1092_11 = pptr__goto_1092_11 + 1)
                        if __goto_pending != 0:
                            break
                        if ((d__goto_1513_14 == 13) or (d__goto_1513_14 == 10)):
                            cb.external_flags = cb.external_flags | 2048
                        if __goto_pending != 0:
                            break
                        add_to_class(options, xoptions, cb, c__goto_1195_20, d__goto_1513_14)
                        if __goto_pending != 0:
                            break
                        continue
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    add_to_class(options, xoptions, cb, meta__goto_1190_12, meta__goto_1190_12)
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
                if (negate_class != 0):
                    classwords__goto_1856_13 = (&cb.classbits.classwords[0] as *mut c_uint)
                    if __goto_pending != 0:
                        continue
                    i__goto_1858_12 = 0
                    while (i__goto_1858_12 < 8):
                        (classwords__goto_1856_13[i__goto_1858_12] = (0 - classwords__goto_1856_13[i__goto_1858_12] - 1))
                        (i__goto_1858_12 = i__goto_1858_12 + 1)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (((not ((utf__goto_1103_6 != 0))) or (negate_class != should_flip_negation__goto_1094_6)) and ((&cb.classbits.classwords[0] as *mut c_uint)[0] == (0 - (0 as c_uint) - 1))):
                    classwords__goto_1864_19 = ((&cb.classbits.classwords[0] as *mut c_uint) as *const c_uint)
                    if __goto_pending != 0:
                        continue
                    (i__goto_1865_7 = 0)
                    while (i__goto_1865_7 < 8):
                        if (classwords__goto_1864_19[i__goto_1865_7] != (0 - (0 as c_uint) - 1)):
                            break
                        (i__goto_1865_7 = i__goto_1865_7 + 1)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        continue
                    if (i__goto_1865_7 == 8):
                        (unsafe: *code__goto_1093_14 = 13)
                        (code__goto_1093_14 = code__goto_1093_14 + 1)
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
                (unsafe: *code__goto_1093_14 = (if (negate_class == should_flip_negation__goto_1094_6): OP_CLASS else: OP_NCLASS))
                (code__goto_1093_14 = code__goto_1093_14 + 1)
                if __goto_pending != 0:
                    continue
                with_memcpy((code__goto_1093_14 as *mut c_void) as *i8, (classbits__goto_1098_16 as *const c_void) as *i8, 32 as i64)
                if __goto_pending != 0:
                    continue
                code__goto_1093_14 = code__goto_1093_14 + (32 / sizeof[u8]())
                if __goto_pending != 0:
                    continue
                __pc = 2
                continue
            2 =>  // DONE
                (__goto_pending = 0)
                ((unsafe: *pcode) = code__goto_1093_14)
                if __goto_pending != 0:
                    continue
                return (pptr__goto_1092_11 - (1 as isize as usize))
                if __goto_pending != 0:
                    continue
            _ => break

fn _pcre2_compile_class_nested_8(options: c_uint, xoptions: c_uint, pptr: *mut *mut c_uint, pcode: *mut *mut u8, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int:
    var context: eclass_context
    var op_info: eclass_op_info
    var previous_length: c_ulong = (if (lengthptr != (null as *mut c_ulong)): (unsafe: *lengthptr) else: 0)
    var code: *mut u8 = (unsafe: *pcode)
    var previous: *mut u8
    var allbitsone: c_int = 1
    (context.needs_bitmap = 0)
    (context.options = options)
    (context.xoptions = xoptions)
    (context.errorcodeptr = errorcodeptr)
    (context.cb = cb)
    (previous = code)
    (unsafe: *code = 113)
    (code = code + 1)
    code = code + 2
    (unsafe: *code = 0)
    (code = code + 1)
    if (not ((compile_eclass_nested(((&context as *const eclass_context) as *mut eclass_context), 0, pptr, ((&code as *const *mut u8) as *mut *mut u8), ((&op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr) != 0))):
        return 0

    if (lengthptr != (null as *mut c_ulong)):
        (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code as usize -% previous as usize) / sizeof[u8]())
        (code = previous)

    var i: c_int = 0
    while (i < 8):
        if ((&op_info.bits.classwords[0] as *mut c_uint)[i] != 4294967295):
            (allbitsone = 0)
            break
        (i = i + 1)

        (code = previous)
    if ((op_info.op_single_type == 6) and (allbitsone != 0)):
        if (lengthptr != (null as *mut c_ulong)):
            (unsafe: *lengthptr) = (unsafe: *lengthptr) - 1
        
        (unsafe: *code = 13)
        (code = code + 1)
    else:
        if ((op_info.op_single_type == 6) or (op_info.op_single_type == 7)):
            var required_len: c_ulong = (1 +% ((32 / sizeof[u8]())))
            if (lengthptr != (null as *mut c_ulong)):
                if (required_len > (((unsafe: *lengthptr) -% previous_length))):
                    ((unsafe: *lengthptr) = (previous_length +% required_len))
                
            
            if (lengthptr != (null as *mut c_ulong)):
                (unsafe: *lengthptr) = (unsafe: *lengthptr) - required_len
            
            (unsafe: *code = (if (op_info.op_single_type == 6): OP_NCLASS else: OP_CLASS))
            (code = code + 1)
            with_memcpy((code as *mut c_void) as *i8, ((&op_info.bits.classbits[0] as *mut u8) as *const c_void) as *i8, 32 as i64)
            code = code + (32 / sizeof[u8]())


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
fn add_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, start: c_uint, end: c_uint):
    var classbits: *mut u8 = (&cb.classbits.classbits[0] as *mut u8)
    var c: c_uint
    var byte_start: c_uint
    var byte_end: c_uint
    var classbits_end: c_uint = ((if (end <= 255): end else: 255))
    xoptions
    if (((options & 8)) != 0):
        (c = start)
        while (c <= classbits_end):
            classbits[((cb.fcc[c]) >> 3)] = classbits[((cb.fcc[c]) >> 3)] | (((1 << (((cb.fcc[c]) & 7)))) as u8)
            (c = c + 1)
        
        

    (byte_start = (((start +% 7)) >> 3))
    (byte_end = (((classbits_end +% 1)) >> 3))
    if (byte_start >= byte_end):
        (c = start)
        while (c <= classbits_end):
            classbits[((c) >> 3)] = classbits[((c) >> 3)] | (((1 << (((c) & 7)))) as u8)
            (c = c + 1)
        
        return

    (c = byte_start)
    while (c < byte_end):
        (classbits[c] = 255)
        (c = c + 1)

    byte_start = byte_start << 3
    byte_end = byte_end << 3
    (c = start)
    while (c < byte_start):
        classbits[((c) >> 3)] = classbits[((c) >> 3)] | (((1 << (((c) & 7)))) as u8)
        (c = c + 1)

    (c = byte_end)
    while (c <= classbits_end):
        classbits[((c) >> 3)] = classbits[((c) >> 3)] | (((1 << (((c) & 7)))) as u8)
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
        if (lengthptr != (null as *mut c_ulong)):
            (unsafe: *lengthptr) = (unsafe: *lengthptr) + 1
        else:
            (pop_info.code_start[pop_info.length] = 4)
        
        pop_info.length = pop_info.length + 1
    else:
        if ((pop_info.op_single_type == 6) or (pop_info.op_single_type == 7)):
            (pop_info.op_single_type = (if (pop_info.op_single_type == 7): 6 else: 7))
            if (lengthptr == (null as *mut c_ulong)):
                ((unsafe: *(pop_info.code_start)) = pop_info.op_single_type)
            
        else:
            if (lengthptr == (null as *mut c_ulong)):
                pop_info.code_start[(1 + 2)] = pop_info.code_start[(1 + 2)] ^ 1
            

    if (not ((preserve_classbits != 0))):
        var i: c_int = 0
        while (i < 8):
            ((&pop_info.bits.classwords[0] as *mut c_uint)[i] = (0 - (&pop_info.bits.classwords[0] as *mut c_uint)[i] - 1))
            (i = i + 1)
        


fn fold_binary(op: c_int, lhs_op_info: *mut eclass_op_info, rhs_op_info: *mut eclass_op_info, lengthptr: *mut c_ulong):
    match op
        1 =>
            var i: c_int = 0
            while (i < 8):
                (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] = (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] & (&rhs_op_info.bits.classwords[0] as *mut c_uint)[i]
                (i = i + 1)
        2 =>
            var i: c_int = 0
            while (i < 8):
                (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] = (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] | (&rhs_op_info.bits.classwords[0] as *mut c_uint)[i]
                (i = i + 1)
        3 =>
            var i: c_int = 0
            while (i < 8):
                (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] = (&lhs_op_info.bits.classwords[0] as *mut c_uint)[i] ^ (&rhs_op_info.bits.classwords[0] as *mut c_uint)[i]
                (i = i + 1)
        _ => 0


fn compile_eclass_nested(context: *mut eclass_context, __param_negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var negated = __param_negated
    var ptr: *mut c_uint = (unsafe: *pptr)
    if ((unsafe: *(ptr = ptr + 1)) == (((2148401152 as c_uint) | 1))):
        (negated = (if negated != 0: 0 else: 1))

    (((unsafe: *pptr)) = ((unsafe: *pptr)) + 1)
    if (not ((compile_class_binary_loose(context, negated, pptr, pcode, pop_info, lengthptr) != 0))):
        return 0

    return 1

fn compile_class_operand(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr__goto_2151_11: *mut c_uint = null
    var prev_ptr__goto_2152_11: *mut c_uint = null
    var code__goto_2153_14: *mut u8 = null
    var code_start__goto_2154_14: *mut u8 = null
    var prev_length__goto_2155_12: c_ulong = 0
    var extra_length__goto_2156_12: c_ulong = 0
    var meta__goto_2157_10: c_uint = 0
    var classwords__goto_2258_17: *mut c_uint = null
    var i__goto_2260_16: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr__goto_2151_11 = (unsafe: *pptr)
                code__goto_2153_14 = (unsafe: *pcode)
                code_start__goto_2154_14 = code__goto_2153_14
                prev_length__goto_2155_12 = (if (lengthptr != (null as *mut c_ulong)): (unsafe: *lengthptr) else: 0)
                meta__goto_2157_10 = (((unsafe: *ptr__goto_2151_11) & (4294901760 as c_uint)))
                match meta__goto_2157_10
                    2148270080 =>
                        (pop_info.length = 1)
                        if (((if meta__goto_2157_10 == 2148204544: 1 else: 0)) == negated):
                            (pop_info.op_single_type = 6)
                            ((unsafe: *(code__goto_2153_14 = code__goto_2153_14 + 1)) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            (pop_info.op_single_type = 7)
                            ((unsafe: *(code__goto_2153_14 = code__goto_2153_14 + 1)) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 0, 32 as i64)
                            if __goto_pending != 0:
                                continue
                    2148139008 =>
                        (ptr__goto_2151_11 = ptr__goto_2151_11 + 1)
                        (prev_ptr__goto_2152_11 = ptr__goto_2151_11)
                        (ptr__goto_2151_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2151_11, ((&code__goto_2153_14 as *const *mut u8) as *mut *mut u8), (if ((if meta__goto_2157_10 != 2148401152: 1 else: 0)) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))
                        if (ptr__goto_2151_11 == (null as *mut c_uint)):
                            return 0
                        if (ptr__goto_2151_11 <= prev_ptr__goto_2152_11):
                            return 0
                            if __goto_pending != 0:
                                continue
                        if ((meta__goto_2157_10 == 2148139008) or (meta__goto_2157_10 == 2148401152)):
                            (ptr__goto_2151_11 = ptr__goto_2151_11 + 1)
                            if __goto_pending != 0:
                                continue
                        (extra_length__goto_2156_12 = (if (lengthptr != (null as *mut c_ulong)): ((unsafe: *lengthptr) -% prev_length__goto_2155_12) else: 0))
                        if ((unsafe: *code_start__goto_2154_14) == OP_ALLANY):
                            (pop_info.length = 1)
                            if __goto_pending != 0:
                                continue
                            (pop_info.op_single_type = 6)
                            ((unsafe: *code_start__goto_2154_14) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            if (((unsafe: *code_start__goto_2154_14) == OP_CLASS) or ((unsafe: *code_start__goto_2154_14) == OP_NCLASS)):
                                (pop_info.length = 1)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.op_single_type = (if ((unsafe: *code_start__goto_2154_14) == OP_CLASS): 7 else: 6))
                                ((unsafe: *code_start__goto_2154_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((code_start__goto_2154_14 + (1 as isize as usize)) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                if (lengthptr != (null as *mut c_ulong)):
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2153_14 as usize -% ((code_start__goto_2154_14 + (1 as isize as usize))) as usize) / sizeof[u8]())
                                if __goto_pending != 0:
                                    continue
                                (code__goto_2153_14 = (code_start__goto_2154_14 + (1 as isize as usize)))
                                if __goto_pending != 0:
                                    continue
                                if ((not ((context.needs_bitmap != 0))) and ((unsafe: *code_start__goto_2154_14) == 7)):
                                    classwords__goto_2258_17 = (&pop_info.bits.classwords[0] as *mut c_uint)
                                    if __goto_pending != 0:
                                        continue
                                    i__goto_2260_16 = 0
                                    while (i__goto_2260_16 < 8):
                                        if (classwords__goto_2258_17[i__goto_2260_16] != 0):
                                            (context.needs_bitmap = 1)
                                            if __goto_pending != 0:
                                                break
                                            break
                                            if __goto_pending != 0:
                                                break
                                        (i__goto_2260_16 = i__goto_2260_16 + 1)
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
                                ((unsafe: *code_start__goto_2154_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((&context.cb.classbits.classbits[0] as *mut u8) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.length = ((((code__goto_2153_14 as usize -% code_start__goto_2154_14 as usize) / sizeof[u8]())) +% extra_length__goto_2156_12))
                                if __goto_pending != 0:
                                    continue
                    _ =>
                        (prev_ptr__goto_2152_11 = ptr__goto_2151_11)
                        (ptr__goto_2151_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2151_11, ((&code__goto_2153_14 as *const *mut u8) as *mut *mut u8), (if ((if meta__goto_2157_10 != 2148401152: 1 else: 0)) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))
                        if (ptr__goto_2151_11 == (null as *mut c_uint)):
                            return 0
                        if (ptr__goto_2151_11 <= prev_ptr__goto_2152_11):
                            return 0
                            if __goto_pending != 0:
                                continue
                        if ((meta__goto_2157_10 == 2148139008) or (meta__goto_2157_10 == 2148401152)):
                            (ptr__goto_2151_11 = ptr__goto_2151_11 + 1)
                            if __goto_pending != 0:
                                continue
                        (extra_length__goto_2156_12 = (if (lengthptr != (null as *mut c_ulong)): ((unsafe: *lengthptr) -% prev_length__goto_2155_12) else: 0))
                        if ((unsafe: *code_start__goto_2154_14) == OP_ALLANY):
                            (pop_info.length = 1)
                            if __goto_pending != 0:
                                continue
                            (pop_info.op_single_type = 6)
                            ((unsafe: *code_start__goto_2154_14) = pop_info.op_single_type)
                            if __goto_pending != 0:
                                continue
                            with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, 255, 32 as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            if (((unsafe: *code_start__goto_2154_14) == OP_CLASS) or ((unsafe: *code_start__goto_2154_14) == OP_NCLASS)):
                                (pop_info.length = 1)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.op_single_type = (if ((unsafe: *code_start__goto_2154_14) == OP_CLASS): 7 else: 6))
                                ((unsafe: *code_start__goto_2154_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((code_start__goto_2154_14 + (1 as isize as usize)) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                if (lengthptr != (null as *mut c_ulong)):
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2153_14 as usize -% ((code_start__goto_2154_14 + (1 as isize as usize))) as usize) / sizeof[u8]())
                                if __goto_pending != 0:
                                    continue
                                (code__goto_2153_14 = (code_start__goto_2154_14 + (1 as isize as usize)))
                                if __goto_pending != 0:
                                    continue
                                if ((not ((context.needs_bitmap != 0))) and ((unsafe: *code_start__goto_2154_14) == 7)):
                                    classwords__goto_2258_17 = (&pop_info.bits.classwords[0] as *mut c_uint)
                                    if __goto_pending != 0:
                                        continue
                                    i__goto_2260_16 = 0
                                    while (i__goto_2260_16 < 8):
                                        if (classwords__goto_2258_17[i__goto_2260_16] != 0):
                                            (context.needs_bitmap = 1)
                                            if __goto_pending != 0:
                                                break
                                            break
                                            if __goto_pending != 0:
                                                break
                                        (i__goto_2260_16 = i__goto_2260_16 + 1)
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
                                ((unsafe: *code_start__goto_2154_14) = pop_info.op_single_type)
                                if __goto_pending != 0:
                                    continue
                                with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *mut c_void) as *i8, ((&context.cb.classbits.classbits[0] as *mut u8) as *const c_void) as *i8, 32 as i64)
                                if __goto_pending != 0:
                                    continue
                                (pop_info.length = ((((code__goto_2153_14 as usize -% code_start__goto_2154_14 as usize) / sizeof[u8]())) +% extra_length__goto_2156_12))
                                if __goto_pending != 0:
                                    continue
                if __goto_pending != 0:
                    continue
                (pop_info.code_start = (if (lengthptr == (null as *mut c_ulong)): code_start__goto_2154_14 else: (null as *mut u8)))
                if __goto_pending != 0:
                    continue
                if (lengthptr != (null as *mut c_ulong)):
                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((code__goto_2153_14 as usize -% code_start__goto_2154_14 as usize) / sizeof[u8]())
                    if __goto_pending != 0:
                        continue
                    (code__goto_2153_14 = code_start__goto_2154_14)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // DONE
                (__goto_pending = 0)
                ((unsafe: *pptr) = ptr__goto_2151_11)
                if __goto_pending != 0:
                    continue
                ((unsafe: *pcode) = code__goto_2153_14)
                if __goto_pending != 0:
                    continue
                return 1
                if __goto_pending != 0:
                    continue
            _ => break

fn compile_class_juxtaposition(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr: *mut c_uint = (unsafe: *pptr)
    var code: *mut u8 = (unsafe: *pcode)
    if (not ((compile_class_operand(context, negated, ((&ptr as *const *mut c_uint) as *mut *mut c_uint), ((&code as *const *mut u8) as *mut *mut u8), pop_info, lengthptr) != 0))):
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
        
        if (not ((compile_class_operand(context, rhs_negated, ((&ptr as *const *mut c_uint) as *mut *mut c_uint), ((&code as *const *mut u8) as *mut *mut u8), ((&rhs_op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr) != 0))):
            return 0
        
        fold_binary(op, pop_info, ((&rhs_op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr)
        if (lengthptr == (null as *mut c_ulong)):
            (code = (pop_info.code_start + pop_info.length))
        

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

    return 1

fn compile_class_binary_tight(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr: *mut c_uint = (unsafe: *pptr)
    var code: *mut u8 = (unsafe: *pcode)
    if (not ((compile_class_unary(context, negated, ((&ptr as *const *mut c_uint) as *mut *mut c_uint), ((&code as *const *mut u8) as *mut *mut u8), pop_info, lengthptr) != 0))):
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
        if (not ((compile_class_unary(context, rhs_negated, ((&ptr as *const *mut c_uint) as *mut *mut c_uint), ((&code as *const *mut u8) as *mut *mut u8), ((&rhs_op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr) != 0))):
            return 0
        
        fold_binary(op, pop_info, ((&rhs_op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr)
        if (lengthptr == (null as *mut c_ulong)):
            (code = (pop_info.code_start + pop_info.length))
        

    ((unsafe: *pptr) = ptr)
    ((unsafe: *pcode) = code)
    return 1

fn compile_class_binary_loose(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int:
    var ptr: *mut c_uint = (unsafe: *pptr)
    var code: *mut u8 = (unsafe: *pcode)
    if (not ((compile_class_binary_tight(context, negated, ((&ptr as *const *mut c_uint) as *mut *mut c_uint), ((&code as *const *mut u8) as *mut *mut u8), pop_info, lengthptr) != 0))):
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
        if (not ((compile_class_binary_tight(context, rhs_negated, ((&ptr as *const *mut c_uint) as *mut *mut c_uint), ((&code as *const *mut u8) as *mut *mut u8), ((&rhs_op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr) != 0))):
            return 0
        
        fold_binary(op, pop_info, ((&rhs_op_info as *const eclass_op_info) as *mut eclass_op_info), lengthptr)
        if (op_neg != 0):
            fold_negation(pop_info, lengthptr, 0)
        
        if (lengthptr == (null as *mut c_ulong)):
            (code = (pop_info.code_start + pop_info.length))
        

    ((unsafe: *pptr) = ptr)
    ((unsafe: *pcode) = code)
    return 1

