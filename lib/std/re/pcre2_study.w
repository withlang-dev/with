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
// /Users/eric/with/.reference/pcre2/src/pcre2_intmodedep.h:696:8: demoted to opaque
type heapframe = opaque
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
// /Users/eric/with/.reference/pcre2/src/pcre2_intmodedep.h:1024:16: demoted to opaque
type heapframe_align = opaque
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
    var count: c_int = 0
    var code: *mut u8 = null
    var utf: c_int = 0
    var ucp: c_int = 0
    var depth: c_int = 0
    var rc: c_int = 0
    var i: c_int = 0
    var a: c_int = 0
    var b: c_int = 0
    var p: *mut u8 = null
    var flags: c_uint = 0
    var x: u8 = 0
    var c: c_int = 0
    var y: u8 = 0
    var d: c_int = 0
    var min: c_int = 0
    var backref_cache: [129]c_int = [0 as c_int; 129]
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                count = 0
                utf = (if ((re.overall_options & 524288)) != 0: 1 else: 0)
                ucp = (if ((re.overall_options & 131072)) != 0: 1 else: 0)
                if (if ((re.flags & ((16 | 512)))) == 0: 1 else: 0) != 0:
                    depth = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    rc = set_start_bits(re, (code as *const u8), utf, ucp, (&mut depth as *mut c_int))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if rc == SSB_UNKNOWN: 1 else: 0) != 0:
                        return 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if rc == SSB_DONE: 1 else: 0) != 0:
                        a = -1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        b = -1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        p = (&re.start_bitmap[0] as *mut u8)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        flags = 64
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (i = 0)
                        while (if i < 256: 1 else: 0) != 0:
                            x = (unsafe: *p)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if x != 0: 1 else: 0) != 0:
                                y = (x & (((0 - x - 1) + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if y != x: 1 else: 0) != 0:
                                    __pc = 1
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (c = i)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                match x
                                    1 => 0
                                    2 =>
                                        c = c + 1
                                    4 =>
                                        c = c + 2
                                    8 =>
                                        c = c + 3
                                    16 =>
                                        c = c + 4
                                    32 =>
                                        c = c + 5
                                    64 =>
                                        c = c + 6
                                    128 =>
                                        c = c + 7
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if utf != 0 and (if c > 127: 1 else: 0) != 0: 1 else: 0) != 0:
                                    __pc = 1
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if a < 0: 1 else: 0) != 0:
                                    (a = c)
                                else:
                                    if (if b < 0: 1 else: 0) != 0:
                                        d = (((re.tables + (256 as isize as usize)))[(c as c_uint)])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if d != a: 1 else: 0) != 0:
                                            __pc = 1
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (b = c)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        __pc = 1
                                        __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if a >= 0: 1 else: 0) != 0:
                            (re.first_codeunit = a)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (flags = 16)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            if (if b >= 0: 1 else: 0) != 0:
                                flags = flags | 32
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        re.flags = re.flags | flags
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if ((re.flags & ((8192 | 8388608)))) == 0: 1 else: 0) != 0 and (if re.top_backref <= 128: 1 else: 0) != 0: 1 else: 0) != 0:
                    ((&backref_cache[0] as *mut c_int)[0] = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (min = find_minlength((re as *const pcre2_real_code_8), (code as *const u8), (code as *const u8), utf, (null as *mut recurse_check), (&mut count as *mut c_int), (&backref_cache[0] as *mut c_int)))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    match min
                        -1 => 0
                        -2 =>
                            return 2
                        -3 =>
                            return 3
                        _ =>
                            (re.minlength = (if ((if min > (65535 as c_int): 1 else: 0)) != 0: (65535 as c_int) else: min))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
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
    var length: c_int = 0
    var branchlength: c_int = 0
    var prev_cap_recno: c_int = 0
    var prev_cap_d: c_int = 0
    var prev_recurse_recno: c_int = 0
    var prev_recurse_d: c_int = 0
    var once_fudge: c_uint = 0
    var had_recurse: c_int = 0
    var dupcapused: c_int = 0
    var nextbranch: *const u8 = null
    var cc: *const u8 = null
    var this_recurse: recurse_check
    var d: c_int = 0
    var min: c_int = 0
    var recno: c_int = 0
    var op: u8 = 0
    var cs: *const u8 = null
    var ce: *const u8 = null
    var count: c_int = 0
    var slot: *const u8 = null
    var dd: c_int = 0
    var i: c_int = 0
    var r: *mut recurse_check = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                length = -1
                branchlength = 0
                prev_cap_recno = -1
                prev_cap_d = 0
                prev_recurse_recno = -1
                prev_recurse_d = 0
                once_fudge = 0
                had_recurse = 0
                dupcapused = (if ((re.flags & 2097152)) != 0: 1 else: 0)
                cc = ((code + (1 as isize as usize)) + (2 as isize as usize))
                if (if (if (unsafe: *code) >= OP_SBRA: 1 else: 0) != 0 and (if (unsafe: *code) <= OP_SCOND: 1 else: 0) != 0: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if (unsafe: *code) == OP_CBRA: 1 else: 0) != 0 or (if (unsafe: *code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                    cc = cc + 2
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (((unsafe: *countptr)) = ((unsafe: *countptr)) + 1) > 1000: 1 else: 0) != 0:
                    return -1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while true:
                    if (if branchlength >= (65535 as c_int): 1 else: 0) != 0:
                        (branchlength = 65535)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (cc = nextbranch)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (op = (unsafe: *cc))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    match op
                        OP_COND =>
                            if (if (unsafe: *cs) != OP_ALT: 1 else: 0) != 0:
                                (cc = ((cs + (1 as isize as usize)) + (2 as isize as usize)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            __pc = 1
                            __goto_pending = 1
                            if (if (if cc[(1 + 2)] == OP_RECURSE: 1 else: 0) != 0 and (if cc[(2 * ((1 + 2)))] == OP_KET: 1 else: 0) != 0: 1 else: 0) != 0:
                                (once_fudge = 3)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cc = cc + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if d < 0: 1 else: 0) != 0:
                                return d
                            branchlength = branchlength + d
                            cc = cc + (1 + 2)
                        OP_BRA =>
                            if (if (if cc[(1 + 2)] == OP_RECURSE: 1 else: 0) != 0 and (if cc[(2 * ((1 + 2)))] == OP_KET: 1 else: 0) != 0: 1 else: 0) != 0:
                                (once_fudge = 3)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cc = cc + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if d < 0: 1 else: 0) != 0:
                                return d
                            branchlength = branchlength + d
                            cc = cc + (1 + 2)
                        OP_ONCE =>
                            if (if d < 0: 1 else: 0) != 0:
                                return d
                            branchlength = branchlength + d
                            cc = cc + (1 + 2)
                        OP_CBRA =>
                            if (if dupcapused != 0 or (if recno != prev_cap_recno: 1 else: 0) != 0: 1 else: 0) != 0:
                                (prev_cap_recno = recno)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (prev_cap_d = find_minlength(re, cc, startcode, utf, recurses, countptr, backref_cache))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if prev_cap_d < 0: 1 else: 0) != 0:
                                    return prev_cap_d
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            branchlength = branchlength + prev_cap_d
                            cc = cc + (1 + 2)
                        OP_ACCEPT =>
                            if (if (if op != OP_ALT: 1 else: 0) != 0 or (if length == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                return length
                            cc = cc + (1 + 2)
                            (branchlength = 0)
                            (had_recurse = 0)
                        OP_ALT =>
                            if (if (if op != OP_ALT: 1 else: 0) != 0 or (if length == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                return length
                            cc = cc + (1 + 2)
                            (branchlength = 0)
                            (had_recurse = 0)
                        OP_ASSERT => 0
                        OP_REVERSE => 0
                        OP_CALLOUT_STR => 0
                        OP_BRAZERO =>
                            cc = cc + (1 + 2)
                        OP_CHAR =>
                            cc = cc + 2
                        OP_TYPEPLUS =>
                            cc = cc + (if ((if (if cc[1] == OP_PROP: 1 else: 0) != 0 or (if cc[1] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 4 else: 2)
                        OP_EXACT =>
                            cc = cc + (2 + 2)
                        OP_TYPEEXACT =>
                            cc = cc + ((2 + 2) + ((if ((if (if cc[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if cc[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                        OP_PROP =>
                            (cc = cc + 1)
                        OP_NOT_DIGIT =>
                            (cc = cc + 1)
                        OP_ANYNL =>
                            branchlength = branchlength + 1
                            (cc = cc + 1)
                        OP_ANYBYTE =>
                            (branchlength = branchlength + 1)
                            (cc = cc + 1)
                        OP_TYPESTAR =>
                            cc = cc + _pcre2_OP_lengths_8[op]
                        OP_TYPEUPTO =>
                            cc = cc + _pcre2_OP_lengths_8[op]
                        OP_CLASS =>
                            match (unsafe: *cc)
                                OP_CRPLUS => 0
                                OP_CRSTAR => 0
                                OP_CRRANGE =>
                                    cc = cc + (1 + (2 * 2))
                                _ =>
                                    (branchlength = branchlength + 1)
                        OP_DNREF =>
                            cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)]
                            __pc = 2
                            __goto_pending = 1
                            if (if (if recno <= backref_cache[0]: 1 else: 0) != 0 and (if backref_cache[recno] >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (d = backref_cache[recno])
                            else:
                                (d = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((re.overall_options & 512)) == 0: 1 else: 0) != 0:
                                    (cs = _pcre2_find_bracket_8(startcode, utf, recno))
                                    (ce = cs)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if cs == (null as *const u8): 1 else: 0) != 0:
                                        return -2
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if dupcapused != 0: 0 else: 1) != 0 or (if _pcre2_find_bracket_8(ce, utf, recno) == (null as *const u8): 1 else: 0) != 0: 1 else: 0) != 0:
                                        if (if (if cc > cs: 1 else: 0) != 0 and (if cc < ce: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (had_recurse = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            r = recurses
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (r = recurses)
                                            while (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                if (if r.group == cs: 1 else: 0) != 0:
                                                    break
                                                (r = r.prev)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                (had_recurse = 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                (this_recurse.prev = recurses)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (this_recurse.group = cs)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (d = find_minlength(re, cs, startcode, utf, (&mut this_recurse as *mut recurse_check), countptr, backref_cache))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if d < 0: 1 else: 0) != 0:
                                                    return d
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[recno] = d)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = (backref_cache[0] + 1))
                                while (if i < recno: 1 else: 0) != 0:
                                    (backref_cache[i] = -1)
                                    (i = i + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[0] = recno)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)]
                            match (unsafe: *cc)
                                OP_CRSTAR =>
                                    (cc = cc + 1)
                                OP_CRPLUS =>
                                    (cc = cc + 1)
                                OP_CRRANGE =>
                                    cc = cc + (1 + (2 * 2))
                                _ =>
                                    (min = 1)
                            if (if ((if (if d > 0: 1 else: 0) != 0 and (if ((2147483647 / d)) < min: 1 else: 0) != 0: 1 else: 0)) != 0 or (if ((65535 as c_int) - branchlength) < (min * d): 1 else: 0) != 0: 1 else: 0) != 0:
                                (branchlength = 65535)
                            else:
                                branchlength = branchlength + (min * d)
                        OP_REF =>
                            if (if (if recno <= backref_cache[0]: 1 else: 0) != 0 and (if backref_cache[recno] >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (d = backref_cache[recno])
                            else:
                                (d = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((re.overall_options & 512)) == 0: 1 else: 0) != 0:
                                    (cs = _pcre2_find_bracket_8(startcode, utf, recno))
                                    (ce = cs)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if cs == (null as *const u8): 1 else: 0) != 0:
                                        return -2
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if dupcapused != 0: 0 else: 1) != 0 or (if _pcre2_find_bracket_8(ce, utf, recno) == (null as *const u8): 1 else: 0) != 0: 1 else: 0) != 0:
                                        if (if (if cc > cs: 1 else: 0) != 0 and (if cc < ce: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (had_recurse = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            r = recurses
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (r = recurses)
                                            while (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                if (if r.group == cs: 1 else: 0) != 0:
                                                    break
                                                (r = r.prev)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                (had_recurse = 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                (this_recurse.prev = recurses)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (this_recurse.group = cs)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (d = find_minlength(re, cs, startcode, utf, (&mut this_recurse as *mut recurse_check), countptr, backref_cache))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if d < 0: 1 else: 0) != 0:
                                                    return d
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[recno] = d)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = (backref_cache[0] + 1))
                                while (if i < recno: 1 else: 0) != 0:
                                    (backref_cache[i] = -1)
                                    (i = i + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[0] = recno)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)]
                            match (unsafe: *cc)
                                OP_CRSTAR =>
                                    (cc = cc + 1)
                                OP_CRPLUS =>
                                    (cc = cc + 1)
                                OP_CRRANGE =>
                                    cc = cc + (1 + (2 * 2))
                                _ =>
                                    (min = 1)
                            if (if ((if (if d > 0: 1 else: 0) != 0 and (if ((2147483647 / d)) < min: 1 else: 0) != 0: 1 else: 0)) != 0 or (if ((65535 as c_int) - branchlength) < (min * d): 1 else: 0) != 0: 1 else: 0) != 0:
                                (branchlength = 65535)
                            else:
                                branchlength = branchlength + (min * d)
                        OP_RECURSE =>
                            if (if recno == prev_recurse_recno: 1 else: 0) != 0:
                                branchlength = branchlength + prev_recurse_d
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if cc > cs: 1 else: 0) != 0 and (if cc < ce: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (had_recurse = 1)
                                else:
                                    r = recurses
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (r = recurses)
                                    while (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                        if (if r.group == cs: 1 else: 0) != 0:
                                            break
                                        (r = r.prev)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                        (had_recurse = 1)
                                    else:
                                        (this_recurse.prev = recurses)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (this_recurse.group = cs)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prev_recurse_d = find_minlength(re, cs, startcode, utf, (&mut this_recurse as *mut recurse_check), countptr, backref_cache))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prev_recurse_d < 0: 1 else: 0) != 0:
                                            return prev_recurse_d
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prev_recurse_recno = recno)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        branchlength = branchlength + prev_recurse_d
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cc = cc + (3 +% once_fudge)
                            (once_fudge = 0)
                        OP_UPTO => 0
                        OP_MARK => 0
                        OP_CLOSE => 0
                        _ =>
                            return -3
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return -3
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn set_table_bit(re: *mut pcre2_real_code_8, __param_p: *const u8, caseless: c_int, utf: c_int, ucp: c_int) -> *const u8:
    var p = __param_p
    var c: c_uint = (unsafe: *(p = p + 1))
    utf
    ucp
    return p

fn set_type_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint):
    var c: c_uint
    (c = 0)
    while (if c < table_limit: 1 else: 0) != 0:
        (&re.start_bitmap[0] as *mut u8)[c] = (&re.start_bitmap[0] as *mut u8)[c] | re.tables[((c +% 512) +% cbit_type)]
        (c = c + 1)


fn set_nottype_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint):
    var c: c_uint

fn set_start_bits(re: *mut pcre2_real_code_8, __param_code: *const u8, utf: c_int, ucp: c_int, depthptr: *mut c_int) -> c_int:
    var code = __param_code
    var c: c_uint
    var yield_: c_int = SSB_DONE
    var table_limit: c_int = 32
    (unsafe: *depthptr) = (unsafe: *depthptr) + 1
    if (if (unsafe: *depthptr) > 1000: 1 else: 0) != 0:
        return SSB_TOODEEP

    while true:
        var try_next: c_int = 1
        var tcode: *const u8 = ((code + (1 as isize as usize)) + (2 as isize as usize))
        if (if (if (if (if (unsafe: *code) == OP_CBRA: 1 else: 0) != 0 or (if (unsafe: *code) == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *code) == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            tcode = tcode + 2
        
        while try_next != 0:
            var rc: c_int
            var ncode: *const u8
            var classmap: *const u8 = (null as *const u8)
            match (unsafe: *tcode)
                OP_ACCEPT =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CIRC]
                OP_CIRC =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CIRC]
                OP_PROP =>
                    if (if tcode[1] != 9: 1 else: 0) != 0:
                        return SSB_FAIL
                    var p: *const c_uint = (_pcre2_ucd_caseless_sets_8 + (tcode[2] as isize as usize))
                    (try_next = 0)
                OP_WORD_BOUNDARY => 0
                OP_ASSERT =>
                    ncode = ncode + (1 + 2)
                    var done: c_int = 0
                    while (if done != 0: 0 else: 1) != 0:
                        match (unsafe: *ncode)
                            OP_ASSERT =>
                                ncode = ncode + (1 + 2)
                            OP_WORD_BOUNDARY => 0
                            OP_CALLOUT =>
                                ncode = ncode + _pcre2_OP_lengths_8[OP_CALLOUT]
                            OP_CALLOUT_STR => 0
                            _ =>
                                (done = 1)
                        
                    match (unsafe: *ncode)
                        OP_PROP =>
                            if (if ncode[1] != 9: 1 else: 0) != 0:
                                break
                            continue
                        OP_ANYNL =>
                            continue
                        _ => 0
                    if (if rc == SSB_DONE: 1 else: 0) != 0:
                        (try_next = 0)
                    else:
                        if (if rc == SSB_CONTINUE: 1 else: 0) != 0:
                            tcode = tcode + (1 + 2)
                        else:
                            return rc
                OP_BRA =>
                    if (if rc == SSB_DONE: 1 else: 0) != 0:
                        (try_next = 0)
                    else:
                        if (if rc == SSB_CONTINUE: 1 else: 0) != 0:
                            tcode = tcode + (1 + 2)
                        else:
                            return rc
                OP_ALT =>
                    (yield_ = SSB_CONTINUE)
                    (try_next = 0)
                OP_KET =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CALLOUT]
                OP_CALLOUT =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CALLOUT]
                OP_CALLOUT_STR => 0
                OP_ASSERT_NOT =>
                    tcode = tcode + (1 + 2)
                OP_BRAZERO =>
                    if (if (if (if rc == SSB_FAIL: 1 else: 0) != 0 or (if rc == SSB_UNKNOWN: 1 else: 0) != 0: 1 else: 0) != 0 or (if rc == SSB_TOODEEP: 1 else: 0) != 0: 1 else: 0) != 0:
                        return rc
                    tcode = tcode + (1 + 2)
                OP_SKIPZERO =>
                    (tcode = tcode + 1)
                    tcode = tcode + (1 + 2)
                OP_STAR => 0
                OP_STARI => 0
                OP_UPTO => 0
                OP_UPTOI => 0
                OP_EXACT =>
                    tcode = tcode + 2
                    (try_next = 0)
                OP_CHAR =>
                    (try_next = 0)
                OP_EXACTI =>
                    tcode = tcode + 2
                    (try_next = 0)
                OP_CHARI =>
                    (try_next = 0)
                OP_HSPACE =>
                    (try_next = 0)
                OP_ANYNL =>
                    (try_next = 0)
                OP_NOT_DIGIT =>
                    set_nottype_bits(re, 64, table_limit)
                    (try_next = 0)
                OP_DIGIT =>
                    set_type_bits(re, 64, table_limit)
                    (try_next = 0)
                OP_NOT_WHITESPACE =>
                    set_nottype_bits(re, 0, table_limit)
                    (try_next = 0)
                OP_WHITESPACE =>
                    set_type_bits(re, 0, table_limit)
                    (try_next = 0)
                OP_NOT_WORDCHAR =>
                    set_nottype_bits(re, 160, table_limit)
                    (try_next = 0)
                OP_WORDCHAR =>
                    set_type_bits(re, 160, table_limit)
                    (try_next = 0)
                OP_TYPEPLUS => 0
                OP_TYPEEXACT =>
                    tcode = tcode + (1 + 2)
                OP_TYPEUPTO =>
                    tcode = tcode + 2
                OP_TYPESTAR =>
                    tcode = tcode + 2
                OP_NCLASS =>
                    if (if classmap != (null as *const u8): 1 else: 0) != 0:
                        (c = 0)
                        while (if c < 32: 1 else: 0) != 0:
                            (&re.start_bitmap[0] as *mut u8)[c] = (&re.start_bitmap[0] as *mut u8)[c] | classmap[c]
                            (c = c + 1)
                        
                        
                    match (unsafe: *tcode)
                        OP_CRSTAR => 0
                        OP_CRRANGE => 0
                        _ =>
                            (try_next = 0)
                _ =>
                    return SSB_UNKNOWN
            
        
        if not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0):
            break

    return yield_

// untranslatable fn-like macro
fn BYTES2CU() -> Never:
    comptime_error("untranslatable C macro: BYTES2CU")
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
// untranslatable fn-like macro
fn CHMAX_255() -> Never:
    comptime_error("untranslatable C macro: CHMAX_255")
// untranslatable fn-like macro
fn CU2BYTES() -> Never:
    comptime_error("untranslatable C macro: CU2BYTES")
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
fn GET_UCD() -> Never:
    comptime_error("untranslatable C macro: GET_UCD")
fn HASUTF8EXTRALEN[T](c: T) -> T:
    (c >= 0xc0)
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
    (((ch as c_int) == 0x69) or ((ch as c_int) == 0x0130))
fn UCD_FOLD_I_TURKISH[T](ch: T) -> T:
    (if ((ch as c_int) == 0x0130): 0x69 else: (if ((ch as c_int) == 0x49): 0x0131 else: (ch as c_int)))
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
