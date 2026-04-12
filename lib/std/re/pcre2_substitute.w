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
fn pcre2_substitute_8(code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, __param_start_offset: c_ulong, __param_options: c_uint, __param_match_data: *mut pcre2_real_match_data_8, mcontext: *mut pcre2_real_match_context_8, __param_replacement: *const u8, __param_rlength: c_ulong, buffer: *mut u8, blength: *mut c_ulong) -> c_int:
    var subject = __param_subject
    var length = __param_length
    var start_offset = __param_start_offset
    var options = __param_options
    var match_data = __param_match_data
    var replacement = __param_replacement
    var rlength = __param_rlength
    var rc__goto_764_5: c_int = 0
    var subs__goto_765_5: c_int = 0
    var ovector_count__goto_766_10: c_uint = 0
    var goptions__goto_767_10: c_uint = 0
    var suboptions__goto_768_10: c_uint = 0
    var internal_match_data__goto_769_19: *mut pcre2_real_match_data_8 = null
    var escaped_literal__goto_770_6: c_int = 0
    var overflowed__goto_771_6: c_int = 0
    var use_existing_match__goto_772_6: c_int = 0
    var replacement_only__goto_773_6: c_int = 0
    var utf__goto_774_6: c_int = 0
    var partial__goto_775_6: c_int = 0
    var temp__goto_776_13: [6]u8 = [0 as u8; 6]
    var null_str__goto_777_13: [1]u8 = [0 as u8; 1]
    var original_subject__goto_778_12: *const u8 = null
    var ptr__goto_779_12: *const u8 = null
    var repend__goto_780_12: *const u8 = null
    var extra_needed__goto_781_12: c_ulong = 0
    var buff_offset__goto_782_12: c_ulong = 0
    var buff_length__goto_782_25: c_ulong = 0
    var lengthleft__goto_782_38: c_ulong = 0
    var fraglength__goto_782_50: c_ulong = 0
    var ovector__goto_783_13: *mut c_ulong = null
    var ovecsave__goto_784_12: [2]c_ulong = [0 as c_ulong; 2]
    var scb__goto_785_32: pcre2_substitute_callout_block_8
    var sub_start_extra_needed__goto_786_12: c_ulong = 0
    var substitute_case_callout__goto_787_14: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null
    var substitute_case_callout_data__goto_789_7: *mut c_void = null
    var gcontext__goto_905_25: pcre2_real_general_context_8
    var pairs__goto_916_7: c_int = 0
    var gcontext__goto_917_25: pcre2_real_general_context_8
    var chkmc_length__goto_981_24: c_ulong = 0
    var ptrstack__goto_989_14: [20]*const u8 = [null as *const u8; 20]
    var ptrstackptr__goto_990_12: c_uint = 0
    var forcecase__goto_991_14: case_state
    var casestart_offset__goto_992_14: c_ulong = 0
    var casestart_extra_needed__goto_993_14: c_ulong = 0
    var chkmc_length__goto_1061_26: c_ulong = 0
    var chkmc_length__goto_1072_5: c_ulong = 0
    var ch__goto_1082_14: c_uint = 0
    var chlen__goto_1083_18: c_uint = 0
    var group__goto_1084_9: c_int = 0
    var special__goto_1085_14: c_uint = 0
    var text1_start__goto_1086_16: *const u8 = null
    var text1_end__goto_1087_16: *const u8 = null
    var text2_start__goto_1088_16: *const u8 = null
    var text2_end__goto_1089_16: *const u8 = null
    var name__goto_1090_17: [129]u8 = [0 as u8; 129]
    var inparens__goto_1119_12: c_int = 0
    var inangle__goto_1120_12: c_int = 0
    var star__goto_1121_12: c_int = 0
    var sublength__goto_1122_18: c_ulong = 0
    var next__goto_1123_19: u8 = 0
    var subptr__goto_1124_18: *const u8 = null
    var subptrend__goto_1124_26: *const u8 = null
    var name_len__goto_1289_20: c_ulong = 0
    var name_start__goto_1290_20: *const u8 = null
    var mark__goto_1356_22: *const u8 = null
    var chkcc_length__goto_1364_15: c_ulong = 0
    var chkcc_rc__goto_1364_15: c_ulong = 0
    var chkmc_length__goto_1366_15: c_ulong = 0
    var first__goto_1385_22: *const u8 = null
    var last__goto_1385_29: *const u8 = null
    var entry__goto_1385_35: *const u8 = null
    var ng__goto_1397_24: c_uint = 0
    var chkcc_length__goto_1477_11: c_ulong = 0
    var chkcc_rc__goto_1477_11: c_ulong = 0
    var chkmc_length__goto_1479_11: c_ulong = 0
    var errorcode__goto_1491_11: c_int = 0
    var new_forcecase__goto_1492_18: case_state
    var chars_outstanding__goto_1550_11: c_ulong = 0
    var guess__goto_1550_11: c_ulong = 0
    var chkcc_length__goto_1550_11: c_ulong = 0
    var chkcc_rc__goto_1550_11: c_ulong = 0
    var chkcc_length__goto_1589_11: c_ulong = 0
    var chkcc_rc__goto_1589_11: c_ulong = 0
    var chkmc_length__goto_1591_11: c_ulong = 0
    var name_len__goto_1596_22: c_ulong = 0
    var name_start__goto_1597_22: *const u8 = null
    var ch_start__goto_1635_18: *const u8 = null
    var chkcc_length__goto_1644_9: c_ulong = 0
    var chkcc_rc__goto_1644_9: c_ulong = 0
    var chkmc_length__goto_1646_9: c_ulong = 0
    var chars_outstanding__goto_1659_5: c_ulong = 0
    var guess__goto_1659_5: c_ulong = 0
    var chkcc_length__goto_1659_5: c_ulong = 0
    var chkcc_rc__goto_1659_5: c_ulong = 0
    var newlength__goto_1680_20: c_ulong = 0
    var oldlength__goto_1681_20: c_ulong = 0
    var chkmc_length__goto_1685_32: c_ulong = 0
    var newlength_buf__goto_1704_18: c_ulong = 0
    var newlength_extra__goto_1705_18: c_ulong = 0
    var newlength__goto_1706_18: c_ulong = 0
    var oldlength__goto_1709_18: c_ulong = 0
    var additional__goto_1716_20: c_ulong = 0
    var chkmc_length__goto_1754_3: c_ulong = 0
    var chkmc_length__goto_1758_1: c_ulong = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                goptions__goto_767_10 = 0
                internal_match_data__goto_769_19 = (null as *mut pcre2_real_match_data_8)
                escaped_literal__goto_770_6 = 0
                overflowed__goto_771_6 = 0
                utf__goto_774_6 = (if ((code.overall_options & 524288)) != 0: 1 else: 0)
                partial__goto_775_6 = (if ((options & ((32 | 16)))) != 0: 1 else: 0)
                original_subject__goto_778_12 = subject
                repend__goto_780_12 = (null as *const u8)
                extra_needed__goto_781_12 = 0
                substitute_case_callout__goto_787_14 = (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)
                substitute_case_callout_data__goto_789_7 = null
                (buff_offset__goto_782_12 = 0)
                if __goto_pending != 0:
                    continue
                (buff_length__goto_782_25 = (unsafe: *blength))
                (lengthleft__goto_782_38 = buff_length__goto_782_25)
                if __goto_pending != 0:
                    continue
                ((unsafe: *blength) = ((0 - (0 as c_ulong) - 1)))
                if __goto_pending != 0:
                    continue
                if (mcontext != (null as *mut pcre2_real_match_context_8)):
                    (substitute_case_callout__goto_787_14 = mcontext.substitute_case_callout)
                    if __goto_pending != 0:
                        continue
                    (substitute_case_callout_data__goto_789_7 = mcontext.substitute_case_callout_data)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if ((partial__goto_775_6 != 0) and (((options & 131072)) == 0)):
                    return (-34)
                if __goto_pending != 0:
                    continue
                if (replacement == (null as *const u8)):
                    if (rlength != 0):
                        return (-51)
                    if __goto_pending != 0:
                        continue
                    (replacement = ((&null_str__goto_777_13[0] as *mut u8) as *const u8))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (rlength == ((0 - (0 as c_ulong) - 1))):
                    (rlength = _pcre2_strlen_8(replacement))
                if __goto_pending != 0:
                    continue
                (repend__goto_780_12 = (replacement + rlength))
                if __goto_pending != 0:
                    continue
                if (subject == (null as *const u8)):
                    if (length != 0):
                        return (-51)
                    if __goto_pending != 0:
                        continue
                    (subject = ((&null_str__goto_777_13[0] as *mut u8) as *const u8))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (length == ((0 - (0 as c_ulong) - 1))):
                    (length = _pcre2_strlen_8(subject))
                if __goto_pending != 0:
                    continue
                (use_existing_match__goto_772_6 = ((if ((options & 65536)) != 0: 1 else: 0)))
                if __goto_pending != 0:
                    continue
                (replacement_only__goto_773_6 = ((if ((options & 131072)) != 0: 1 else: 0)))
                if __goto_pending != 0:
                    continue
                if ((use_existing_match__goto_772_6 != 0) and (match_data == (null as *mut pcre2_real_match_data_8))):
                    return (-51)
                if __goto_pending != 0:
                    continue
                if (use_existing_match__goto_772_6 != 0):
                    if ((match_data.rc < 0) and (match_data.rc != ((0 -% 1)))):
                        return match_data.rc
                    if __goto_pending != 0:
                        continue
                    if (match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER):
                        return (-41)
                    if __goto_pending != 0:
                        continue
                    if (code != match_data.code):
                        return (-71)
                    if __goto_pending != 0:
                        continue
                    if ((length != match_data.subject_length) or (not (((original_subject__goto_778_12 == match_data.subject) or ((((match_data.flags & 1)) != 0) and ((length == 0) or (with_memcmp((subject as *const c_void) as *i8, (match_data.subject as *const c_void) as *i8, (((length) *% 1)) as i64) == 0))))))):
                        return (-72)
                    if __goto_pending != 0:
                        continue
                    if (start_offset != match_data.start_offset):
                        return (-73)
                    if __goto_pending != 0:
                        continue
                    if (((options & (0 - ((((((((((512 | 256) | 32768) | 65536) | 4096) | 131072) | 2048) | 1024)) | 1073741824)) - 1))) != ((match_data.options & (0 - 1073741824 - 1)))):
                        return (-74)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (match_data == (null as *mut pcre2_real_match_data_8)):
                    (gcontext__goto_905_25.memctl = (if (mcontext == (null as *mut pcre2_real_match_context_8)): ((code as *mut pcre2_real_code_8)).memctl else: ((mcontext as *mut pcre2_real_match_context_8)).memctl))
                    if __goto_pending != 0:
                        continue
                    (internal_match_data__goto_769_19 = pcre2_match_data_create_from_pattern_8(code, ((&gcontext__goto_905_25 as *const pcre2_real_general_context_8) as *mut pcre2_real_general_context_8)))
                    (match_data = internal_match_data__goto_769_19)
                    if __goto_pending != 0:
                        continue
                    if (internal_match_data__goto_769_19 == (null as *mut pcre2_real_match_data_8)):
                        return (-48)
                    if __goto_pending != 0:
                        continue
                else:
                    if (use_existing_match__goto_772_6 != 0):
                        (gcontext__goto_917_25.memctl = (if (mcontext == (null as *mut pcre2_real_match_context_8)): ((code as *mut pcre2_real_code_8)).memctl else: ((mcontext as *mut pcre2_real_match_context_8)).memctl))
                        if __goto_pending != 0:
                            continue
                        (pairs__goto_916_7 = (if ((code.top_bracket + 1) < match_data.oveccount): (code.top_bracket + 1) else: match_data.oveccount))
                        if __goto_pending != 0:
                            continue
                        (internal_match_data__goto_769_19 = pcre2_match_data_create_8(match_data.oveccount, ((&gcontext__goto_917_25 as *const pcre2_real_general_context_8) as *mut pcre2_real_general_context_8)))
                        if __goto_pending != 0:
                            continue
                        if (internal_match_data__goto_769_19 == (null as *mut pcre2_real_match_data_8)):
                            return (-48)
                        if __goto_pending != 0:
                            continue
                        with_memcpy((internal_match_data__goto_769_19 as *mut c_void) as *i8, (match_data as *const c_void) as *i8, (120 +% ((2 * pairs__goto_916_7) *% sizeof[c_ulong]())) as i64)
                        if __goto_pending != 0:
                            continue
                        (internal_match_data__goto_769_19.heapframes = (null as *mut heapframe))
                        if __goto_pending != 0:
                            continue
                        (internal_match_data__goto_769_19.heapframes_size = 0)
                        if __goto_pending != 0:
                            continue
                        internal_match_data__goto_769_19.flags = internal_match_data__goto_769_19.flags & (0 - 1 - 1)
                        if __goto_pending != 0:
                            continue
                        (match_data = internal_match_data__goto_769_19)
                        if __goto_pending != 0:
                            continue
                if __goto_pending != 0:
                    continue
                if (internal_match_data__goto_769_19 != (null as *mut pcre2_real_match_data_8)):
                    options = options & (0 - 16384 - 1)
                if __goto_pending != 0:
                    continue
                (ovector__goto_783_13 = pcre2_get_ovector_pointer_8(match_data))
                if __goto_pending != 0:
                    continue
                (ovector_count__goto_766_10 = pcre2_get_ovector_count_8(match_data))
                if __goto_pending != 0:
                    continue
                (scb__goto_785_32.version = 0)
                if __goto_pending != 0:
                    continue
                (scb__goto_785_32.input = subject)
                if __goto_pending != 0:
                    continue
                (scb__goto_785_32.output = (buffer as *const u8))
                if __goto_pending != 0:
                    continue
                (scb__goto_785_32.ovector = ovector__goto_783_13)
                if __goto_pending != 0:
                    continue
                (suboptions__goto_768_10 = (options & ((((((((512 | 256) | 32768) | 65536) | 4096) | 131072) | 2048) | 1024))))
                if __goto_pending != 0:
                    continue
                options = options & (0 - ((((((((512 | 256) | 32768) | 65536) | 4096) | 131072) | 2048) | 1024)) - 1)
                if __goto_pending != 0:
                    continue
                if (start_offset > length):
                    (match_data.leftchar = 0)
                    if __goto_pending != 0:
                        continue
                    (rc__goto_764_5 = (-33))
                    if __goto_pending != 0:
                        continue
                    __pc = 6
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (not ((replacement_only__goto_773_6 != 0))):
                    while true:
                        if (overflowed__goto_771_6 != 0):
                            if (chkmc_length__goto_981_24 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                __pc = 9
                                __goto_pending = 1
                            if __goto_pending != 0:
                                break
                            extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_981_24
                            if __goto_pending != 0:
                                break
                        else:
                            if (lengthleft__goto_782_38 < chkmc_length__goto_981_24):
                                if (((suboptions__goto_768_10 & 4096)) == 0):
                                    __pc = 7
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                (overflowed__goto_771_6 = 1)
                                if __goto_pending != 0:
                                    break
                                (extra_needed__goto_781_12 = (chkmc_length__goto_981_24 -% lengthleft__goto_782_38))
                                if __goto_pending != 0:
                                    break
                            else:
                                with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, (subject as *const c_void) as *i8, (((chkmc_length__goto_981_24) *% 1)) as i64)
                                if __goto_pending != 0:
                                    break
                                buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_981_24
                                if __goto_pending != 0:
                                    break
                                lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_981_24
                                if __goto_pending != 0:
                                    break
                        if __goto_pending != 0:
                            break
                        if __goto_pending != 0:
                            break
                        if not ((0 != 0)):
                            break
                if __goto_pending != 0:
                    continue
                (subs__goto_765_5 = 0)
                if __goto_pending != 0:
                    continue
                while true:
                    ptrstackptr__goto_990_12 = 0
                    if __goto_pending != 0:
                        break
                    forcecase__goto_991_14 = case_state { to_case: 0, single_char: 0 }
                    if __goto_pending != 0:
                        break
                    casestart_offset__goto_992_14 = 0
                    if __goto_pending != 0:
                        break
                    casestart_extra_needed__goto_993_14 = 0
                    if __goto_pending != 0:
                        break
                    if (use_existing_match__goto_772_6 != 0):
                        (rc__goto_764_5 = match_data.rc)
                        if __goto_pending != 0:
                            break
                        (use_existing_match__goto_772_6 = 0)
                        if __goto_pending != 0:
                            break
                    else:
                        (rc__goto_764_5 = pcre2_match_8(code, subject, length, start_offset, (options | goptions__goto_767_10), match_data, mcontext))
                    if __goto_pending != 0:
                        break
                    if (rc__goto_764_5 == ((0 -% 1))):
                        break
                    if __goto_pending != 0:
                        break
                    if (rc__goto_764_5 < 0):
                        __pc = 6
                        __goto_pending = 1
                    if __goto_pending != 0:
                        break
                    if ((ovector__goto_783_13[1] < ovector__goto_783_13[0]) or (ovector__goto_783_13[0] < start_offset)):
                        (rc__goto_764_5 = (-60))
                        if __goto_pending != 0:
                            break
                        __pc = 6
                        __goto_pending = 1
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    if ((subs__goto_765_5 > 0) and (not (((ovector__goto_783_13[1] > (&ovecsave__goto_784_12[0] as *mut c_ulong)[1]) or (((ovector__goto_783_13[1] == ovector__goto_783_13[0]) and ((&ovecsave__goto_784_12[0] as *mut c_ulong)[1] > (&ovecsave__goto_784_12[0] as *mut c_ulong)[0])) and (ovector__goto_783_13[1] == (&ovecsave__goto_784_12[0] as *mut c_ulong)[1])))))):
                        (rc__goto_764_5 = (-65))
                        if __goto_pending != 0:
                            break
                        __pc = 6
                        __goto_pending = 1
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    ((&ovecsave__goto_784_12[0] as *mut c_ulong)[0] = ovector__goto_783_13[0])
                    if __goto_pending != 0:
                        break
                    ((&ovecsave__goto_784_12[0] as *mut c_ulong)[1] = ovector__goto_783_13[1])
                    if __goto_pending != 0:
                        break
                    if (subs__goto_765_5 == 2147483647):
                        (rc__goto_764_5 = (-61))
                        if __goto_pending != 0:
                            break
                        __pc = 6
                        __goto_pending = 1
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    (subs__goto_765_5 = subs__goto_765_5 + 1)
                    if __goto_pending != 0:
                        break
                    if (rc__goto_764_5 == 0):
                        (rc__goto_764_5 = ovector_count__goto_766_10)
                    if __goto_pending != 0:
                        break
                    (fraglength__goto_782_50 = (ovector__goto_783_13[0] -% start_offset))
                    if __goto_pending != 0:
                        break
                    if (not ((replacement_only__goto_773_6 != 0))):
                        while true:
                            if (overflowed__goto_771_6 != 0):
                                if (chkmc_length__goto_1061_26 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                    __pc = 9
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1061_26
                                if __goto_pending != 0:
                                    break
                            else:
                                if (lengthleft__goto_782_38 < chkmc_length__goto_1061_26):
                                    if (((suboptions__goto_768_10 & 4096)) == 0):
                                        __pc = 7
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    (overflowed__goto_771_6 = 1)
                                    if __goto_pending != 0:
                                        break
                                    (extra_needed__goto_781_12 = (chkmc_length__goto_1061_26 -% lengthleft__goto_782_38))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, ((subject + start_offset) as *const c_void) as *i8, (((chkmc_length__goto_1061_26) *% 1)) as i64)
                                    if __goto_pending != 0:
                                        break
                                    buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1061_26
                                    if __goto_pending != 0:
                                        break
                                    lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1061_26
                                    if __goto_pending != 0:
                                        break
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                            if not ((0 != 0)):
                                break
                    if __goto_pending != 0:
                        break
                    ((&scb__goto_785_32.output_offsets[0] as *mut c_ulong)[0] = buff_offset__goto_782_12)
                    if __goto_pending != 0:
                        break
                    (scb__goto_785_32.oveccount = rc__goto_764_5)
                    if __goto_pending != 0:
                        break
                    (sub_start_extra_needed__goto_786_12 = extra_needed__goto_781_12)
                    if __goto_pending != 0:
                        break
                    (ptr__goto_779_12 = replacement)
                    if __goto_pending != 0:
                        break
                    if (((suboptions__goto_768_10 & 32768)) != 0):
                        while true:
                            if (overflowed__goto_771_6 != 0):
                                if (chkmc_length__goto_1072_5 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                    __pc = 9
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1072_5
                                if __goto_pending != 0:
                                    break
                            else:
                                if (lengthleft__goto_782_38 < chkmc_length__goto_1072_5):
                                    if (((suboptions__goto_768_10 & 4096)) == 0):
                                        __pc = 7
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    (overflowed__goto_771_6 = 1)
                                    if __goto_pending != 0:
                                        break
                                    (extra_needed__goto_781_12 = (chkmc_length__goto_1072_5 -% lengthleft__goto_782_38))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, (ptr__goto_779_12 as *const c_void) as *i8, (((chkmc_length__goto_1072_5) *% 1)) as i64)
                                    if __goto_pending != 0:
                                        break
                                    buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1072_5
                                    if __goto_pending != 0:
                                        break
                                    lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1072_5
                                    if __goto_pending != 0:
                                        break
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                            if not ((0 != 0)):
                                break
                        if __goto_pending != 0:
                            break
                    else:
                        while true:
                            text1_start__goto_1086_16 = (null as *const u8)
                            if __goto_pending != 0:
                                break
                            text1_end__goto_1087_16 = (null as *const u8)
                            if __goto_pending != 0:
                                break
                            text2_start__goto_1088_16 = (null as *const u8)
                            if __goto_pending != 0:
                                break
                            text2_end__goto_1089_16 = (null as *const u8)
                            if __goto_pending != 0:
                                break
                            if (ptr__goto_779_12 >= repend__goto_780_12):
                                if (ptrstackptr__goto_990_12 == 0):
                                    break
                                if __goto_pending != 0:
                                    break
                                (repend__goto_780_12 = (&ptrstack__goto_989_14[0] as *mut *const u8)[(ptrstackptr__goto_990_12 = ptrstackptr__goto_990_12 - 1)])
                                if __goto_pending != 0:
                                    break
                                (ptr__goto_779_12 = (&ptrstack__goto_989_14[0] as *mut *const u8)[(ptrstackptr__goto_990_12 = ptrstackptr__goto_990_12 - 1)])
                                if __goto_pending != 0:
                                    break
                                continue
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if (escaped_literal__goto_770_6 != 0):
                                if (((ptr__goto_779_12[0] == 92) and (ptr__goto_779_12 < (repend__goto_780_12 - (1 as isize as usize)))) and (ptr__goto_779_12[1] == 69)):
                                    (escaped_literal__goto_770_6 = 0)
                                    if __goto_pending != 0:
                                        break
                                    ptr__goto_779_12 = ptr__goto_779_12 + 2
                                    if __goto_pending != 0:
                                        break
                                    continue
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                __pc = 5
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if ((unsafe: *ptr__goto_779_12) == 36):
                                if ((ptr__goto_779_12 = ptr__goto_779_12 + 1) >= repend__goto_780_12):
                                    __pc = 10
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if (((next__goto_1123_19 = (unsafe: *ptr__goto_779_12))) == 36):
                                    __pc = 5
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                (special__goto_1085_14 = 0)
                                if __goto_pending != 0:
                                    break
                                (text1_start__goto_1086_16 = (null as *const u8))
                                if __goto_pending != 0:
                                    break
                                (text1_end__goto_1087_16 = (null as *const u8))
                                if __goto_pending != 0:
                                    break
                                (text2_start__goto_1088_16 = (null as *const u8))
                                if __goto_pending != 0:
                                    break
                                (text2_end__goto_1089_16 = (null as *const u8))
                                if __goto_pending != 0:
                                    break
                                (group__goto_1084_9 = -1)
                                if __goto_pending != 0:
                                    break
                                (inparens__goto_1119_12 = 0)
                                if __goto_pending != 0:
                                    break
                                (inangle__goto_1120_12 = 0)
                                if __goto_pending != 0:
                                    break
                                (star__goto_1121_12 = 0)
                                if __goto_pending != 0:
                                    break
                                (subptr__goto_1124_18 = (null as *const u8))
                                if __goto_pending != 0:
                                    break
                                (subptrend__goto_1124_26 = (null as *const u8))
                                if __goto_pending != 0:
                                    break
                                if (next__goto_1123_19 == 38):
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                    (group__goto_1084_9 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((next__goto_1123_19 == 96) or (next__goto_1123_19 == 39)):
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                    (rc__goto_764_5 = pcre2_substring_length_bynumber_8(match_data, 0, ((&sublength__goto_1122_18 as *const c_ulong) as *mut c_ulong)))
                                    if __goto_pending != 0:
                                        break
                                    if (rc__goto_764_5 < 0):
                                        __pc = 12
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (next__goto_1123_19 == 96):
                                        (subptr__goto_1124_18 = subject)
                                        if __goto_pending != 0:
                                            break
                                        (subptrend__goto_1124_26 = (subject + ovector__goto_783_13[0]))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        if (partial__goto_775_6 != 0):
                                            (rc__goto_764_5 = (-76))
                                            if __goto_pending != 0:
                                                break
                                            __pc = 12
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (subptr__goto_1124_18 = (subject + ovector__goto_783_13[1]))
                                        if __goto_pending != 0:
                                            break
                                        (subptrend__goto_1124_26 = (subject + length))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (next__goto_1123_19 == 95):
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                    if (partial__goto_775_6 != 0):
                                        (rc__goto_764_5 = (-76))
                                        if __goto_pending != 0:
                                            break
                                        __pc = 12
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (subptr__goto_1124_18 = subject)
                                    if __goto_pending != 0:
                                        break
                                    (subptrend__goto_1124_26 = (subject + length))
                                    if __goto_pending != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((next__goto_1123_19 == 43) and (not ((((ptr__goto_779_12 + (1 as isize as usize)) < repend__goto_780_12) and (ptr__goto_779_12[1] == 123))))):
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                    if (code.top_bracket == 0):
                                        if (((suboptions__goto_768_10 & 2048)) == 0):
                                            (rc__goto_764_5 = (-49))
                                            if __goto_pending != 0:
                                                break
                                            __pc = 12
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (group__goto_1084_9 = 0)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        if (match_data.oveccount < (code.top_bracket + 1)):
                                            (rc__goto_764_5 = (-54))
                                            if __goto_pending != 0:
                                                break
                                            __pc = 12
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (group__goto_1084_9 = code.top_bracket)
                                        while (group__goto_1084_9 > 0):
                                            if (ovector__goto_783_13[(2 * group__goto_1084_9)] != ((0 - (0 as c_ulong) - 1))):
                                                break
                                            (group__goto_1084_9 = group__goto_1084_9 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (group__goto_1084_9 == 0):
                                        if (((suboptions__goto_768_10 & 1024)) != 0):
                                            continue
                                        if __goto_pending != 0:
                                            break
                                        (rc__goto_764_5 = (-55))
                                        if __goto_pending != 0:
                                            break
                                        __pc = 12
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (next__goto_1123_19 == 123):
                                    if ((ptr__goto_779_12 = ptr__goto_779_12 + 1) >= repend__goto_780_12):
                                        __pc = 10
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    (next__goto_1123_19 = (unsafe: *ptr__goto_779_12))
                                    if __goto_pending != 0:
                                        break
                                    (inparens__goto_1119_12 = 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (next__goto_1123_19 == 60):
                                        if ((ptr__goto_779_12 = ptr__goto_779_12 + 1) >= repend__goto_780_12):
                                            __pc = 10
                                            __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        (next__goto_1123_19 = (unsafe: *ptr__goto_779_12))
                                        if __goto_pending != 0:
                                            break
                                        (inangle__goto_1120_12 = 1)
                                        if __goto_pending != 0:
                                            break
                                if __goto_pending != 0:
                                    break
                                if ((not ((inangle__goto_1120_12 != 0))) and (next__goto_1123_19 == 42)):
                                    if ((ptr__goto_779_12 = ptr__goto_779_12 + 1) >= repend__goto_780_12):
                                        __pc = 10
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    (next__goto_1123_19 = (unsafe: *ptr__goto_779_12))
                                    if __goto_pending != 0:
                                        break
                                    (star__goto_1121_12 = 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((((not ((star__goto_1121_12 != 0))) and (not ((inangle__goto_1120_12 != 0)))) and (next__goto_1123_19 >= 48)) and (next__goto_1123_19 <= 57)):
                                    (group__goto_1084_9 = (next__goto_1123_19 - 48))
                                    if __goto_pending != 0:
                                        break
                                    while ((ptr__goto_779_12 = ptr__goto_779_12 + 1) < repend__goto_780_12):
                                        (next__goto_1123_19 = (unsafe: *ptr__goto_779_12))
                                        if __goto_pending != 0:
                                            break
                                        if ((next__goto_1123_19 < 48) or (next__goto_1123_19 > 57)):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        (group__goto_1084_9 = ((group__goto_1084_9 * 10) + ((next__goto_1123_19 - 48))))
                                        if __goto_pending != 0:
                                            break
                                        if (group__goto_1084_9 > code.top_bracket):
                                            if (((suboptions__goto_768_10 & 2048)) != 0):
                                                while ((((ptr__goto_779_12 = ptr__goto_779_12 + 1) < repend__goto_780_12) and ((unsafe: *ptr__goto_779_12) >= 48)) and ((unsafe: *ptr__goto_779_12) <= 57)):
                                                    0
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                (rc__goto_764_5 = (-49))
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 12
                                                __goto_pending = 1
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
                                else:
                                    name_start__goto_1290_20 = ptr__goto_779_12
                                    if __goto_pending != 0:
                                        break
                                    if (not ((read_name_subst(((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, utf__goto_774_6, (code.tables + (((512 + 320)) as isize as usize))) != 0))):
                                        __pc = 10
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    (name_len__goto_1289_20 = ((ptr__goto_779_12 as usize -% name_start__goto_1290_20 as usize) / sizeof[u8]()))
                                    if __goto_pending != 0:
                                        break
                                    with_memcpy(((&name__goto_1090_17[0] as *mut u8) as *mut c_void) as *i8, (name_start__goto_1290_20 as *const c_void) as *i8, (((name_len__goto_1289_20) *% 1)) as i64)
                                    if __goto_pending != 0:
                                        break
                                    ((&name__goto_1090_17[0] as *mut u8)[name_len__goto_1289_20] = 0)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (next__goto_1123_19 = 0)
                                if __goto_pending != 0:
                                    break
                                next__goto_1123_19
                                if __goto_pending != 0:
                                    break
                                if (inparens__goto_1119_12 != 0):
                                    if ((((((suboptions__goto_768_10 & 512)) != 0) and (not ((star__goto_1121_12 != 0)))) and (ptr__goto_779_12 < (repend__goto_780_12 - (2 as isize as usize)))) and ((unsafe: *ptr__goto_779_12) == 58)):
                                        (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                        (special__goto_1085_14 = (unsafe: *ptr__goto_779_12))
                                        if __goto_pending != 0:
                                            break
                                        if ((special__goto_1085_14 != 43) and (special__goto_1085_14 != 45)):
                                            (rc__goto_764_5 = (-59))
                                            if __goto_pending != 0:
                                                break
                                            __pc = 12
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                        (text1_start__goto_1086_16 = ptr__goto_779_12)
                                        if __goto_pending != 0:
                                            break
                                        (rc__goto_764_5 = find_text_end(code, ((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, (if special__goto_1085_14 == 45: 1 else: 0)))
                                        if __goto_pending != 0:
                                            break
                                        if (rc__goto_764_5 != 0):
                                            __pc = 12
                                            __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        (text1_end__goto_1087_16 = ptr__goto_779_12)
                                        if __goto_pending != 0:
                                            break
                                        if ((special__goto_1085_14 == 43) and ((unsafe: *ptr__goto_779_12) == 58)):
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            (text2_start__goto_1088_16 = ptr__goto_779_12)
                                            if __goto_pending != 0:
                                                break
                                            (rc__goto_764_5 = find_text_end(code, ((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, 1))
                                            if __goto_pending != 0:
                                                break
                                            if (rc__goto_764_5 != 0):
                                                __pc = 12
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (text2_end__goto_1089_16 = ptr__goto_779_12)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 125)):
                                            (rc__goto_764_5 = (-58))
                                            if __goto_pending != 0:
                                                break
                                            __pc = 12
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (inangle__goto_1120_12 != 0):
                                    if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 62)):
                                        __pc = 10
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (star__goto_1121_12 != 0):
                                    if (_pcre2_strcmp_c8_8(((&name__goto_1090_17[0] as *mut u8) as *const u8), ((&STRING_MARK[0] as *mut c_char) as *const i8)) == 0):
                                        mark__goto_1356_22 = pcre2_get_mark_8(match_data)
                                        if __goto_pending != 0:
                                            break
                                        if (mark__goto_1356_22 != (null as *const u8)):
                                            (fraglength__goto_782_50 = mark__goto_1356_22[-1])
                                            if __goto_pending != 0:
                                                break
                                            if ((forcecase__goto_991_14.to_case != 0) and (substitute_case_callout__goto_787_14 == (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong))):
                                                while true:
                                                    (chkcc_rc__goto_1364_15 = default_substitute_case_callout(mark__goto_1356_22, chkcc_length__goto_1364_15, (buffer + buff_offset__goto_782_12), (if overflowed__goto_771_6 != 0: 0 else: lengthleft__goto_782_38), ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), code))
                                                    if __goto_pending != 0:
                                                        break
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (chkcc_rc__goto_1364_15 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkcc_rc__goto_1364_15
                                                        if __goto_pending != 0:
                                                            break
                                                        break
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if (lengthleft__goto_782_38 < chkcc_rc__goto_1364_15):
                                                        if (((suboptions__goto_768_10 & 4096)) == 0):
                                                            __pc = 7
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        (overflowed__goto_771_6 = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        (extra_needed__goto_781_12 = (chkcc_rc__goto_1364_15 -% lengthleft__goto_782_38))
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1364_15
                                                        if __goto_pending != 0:
                                                            break
                                                        lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1364_15
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            else:
                                                while true:
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (chkmc_length__goto_1366_15 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1366_15
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        if (lengthleft__goto_782_38 < chkmc_length__goto_1366_15):
                                                            if (((suboptions__goto_768_10 & 4096)) == 0):
                                                                __pc = 7
                                                                __goto_pending = 1
                                                            if __goto_pending != 0:
                                                                break
                                                            (overflowed__goto_771_6 = 1)
                                                            if __goto_pending != 0:
                                                                break
                                                            (extra_needed__goto_781_12 = (chkmc_length__goto_1366_15 -% lengthleft__goto_782_38))
                                                            if __goto_pending != 0:
                                                                break
                                                        else:
                                                            with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, (mark__goto_1356_22 as *const c_void) as *i8, (((chkmc_length__goto_1366_15) *% 1)) as i64)
                                                            if __goto_pending != 0:
                                                                break
                                                            buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1366_15
                                                            if __goto_pending != 0:
                                                                break
                                                            lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1366_15
                                                            if __goto_pending != 0:
                                                                break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        __pc = 10
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (group__goto_1084_9 < 0):
                                        (rc__goto_764_5 = pcre2_substring_nametable_scan_8(code, ((&name__goto_1090_17[0] as *mut u8) as *const u8), ((&first__goto_1385_22 as *const *const u8) as *mut *const u8), ((&last__goto_1385_29 as *const *const u8) as *mut *const u8)))
                                        if __goto_pending != 0:
                                            break
                                        if ((rc__goto_764_5 == (-49)) and (((suboptions__goto_768_10 & 2048)) != 0)):
                                            (group__goto_1084_9 = (code.top_bracket + 1))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if (rc__goto_764_5 < 0):
                                                __pc = 12
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (entry__goto_1385_35 = first__goto_1385_22)
                                            while (entry__goto_1385_35 <= last__goto_1385_29):
                                                ng__goto_1397_24 = ((((((((entry__goto_1385_35)[0] as c_uint) << 8))) | (entry__goto_1385_35)[((0) + 1)])) as c_uint)
                                                if __goto_pending != 0:
                                                    break
                                                if (ng__goto_1397_24 < ovector_count__goto_766_10):
                                                    if (group__goto_1084_9 < 0):
                                                        (group__goto_1084_9 = ng__goto_1397_24)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (ovector__goto_783_13[(ng__goto_1397_24 *% 2)] != ((0 - (0 as c_ulong) - 1))):
                                                        (group__goto_1084_9 = ng__goto_1397_24)
                                                        if __goto_pending != 0:
                                                            break
                                                        break
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                                entry__goto_1385_35 = entry__goto_1385_35 + rc__goto_764_5
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if (group__goto_1084_9 < 0):
                                                (group__goto_1084_9 = ((((((((first__goto_1385_22)[0] as c_uint) << 8))) | (first__goto_1385_22)[((0) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (rc__goto_764_5 = pcre2_substring_length_bynumber_8(match_data, group__goto_1084_9, ((&sublength__goto_1122_18 as *const c_ulong) as *mut c_ulong)))
                                    if __goto_pending != 0:
                                        break
                                    if (rc__goto_764_5 < 0):
                                        if ((rc__goto_764_5 == (-49)) and (((suboptions__goto_768_10 & 2048)) != 0)):
                                            (rc__goto_764_5 = (-55))
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rc__goto_764_5 != (-55)):
                                            __pc = 12
                                            __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if (special__goto_1085_14 == 0):
                                            if (((suboptions__goto_768_10 & 1024)) != 0):
                                                continue
                                            if __goto_pending != 0:
                                                break
                                            __pc = 12
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (special__goto_1085_14 != 0):
                                        if (special__goto_1085_14 == 45):
                                            if (rc__goto_764_5 == 0):
                                                __pc = 2
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (text2_start__goto_1088_16 = text1_start__goto_1086_16)
                                            if __goto_pending != 0:
                                                break
                                            (text2_end__goto_1089_16 = text1_end__goto_1087_16)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (ptrstackptr__goto_990_12 >= 20):
                                            __pc = 10
                                            __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        ((&ptrstack__goto_989_14[0] as *mut *const u8)[(ptrstackptr__goto_990_12 = ptrstackptr__goto_990_12 + 1)] = ptr__goto_779_12)
                                        if __goto_pending != 0:
                                            break
                                        ((&ptrstack__goto_989_14[0] as *mut *const u8)[(ptrstackptr__goto_990_12 = ptrstackptr__goto_990_12 + 1)] = repend__goto_780_12)
                                        if __goto_pending != 0:
                                            break
                                        if (rc__goto_764_5 == 0):
                                            (ptr__goto_779_12 = text1_start__goto_1086_16)
                                            if __goto_pending != 0:
                                                break
                                            (repend__goto_780_12 = text1_end__goto_1087_16)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            (ptr__goto_779_12 = text2_start__goto_1088_16)
                                            if __goto_pending != 0:
                                                break
                                            (repend__goto_780_12 = text2_end__goto_1089_16)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        continue
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (subptr__goto_1124_18 = (subject + ovector__goto_783_13[(group__goto_1084_9 * 2)]))
                                    if __goto_pending != 0:
                                        break
                                    (subptrend__goto_1124_26 = (subject + ovector__goto_783_13[((group__goto_1084_9 * 2) + 1)]))
                                    if __goto_pending != 0:
                                        break
                                    if ((forcecase__goto_991_14.to_case != 0) and (substitute_case_callout__goto_787_14 == (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong))):
                                        while true:
                                            (chkcc_rc__goto_1477_11 = default_substitute_case_callout(subptr__goto_1124_18, chkcc_length__goto_1477_11, (buffer + buff_offset__goto_782_12), (if overflowed__goto_771_6 != 0: 0 else: lengthleft__goto_782_38), ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), code))
                                            if __goto_pending != 0:
                                                break
                                            if (overflowed__goto_771_6 != 0):
                                                if (chkcc_rc__goto_1477_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                    __pc = 9
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkcc_rc__goto_1477_11
                                                if __goto_pending != 0:
                                                    break
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if (lengthleft__goto_782_38 < chkcc_rc__goto_1477_11):
                                                if (((suboptions__goto_768_10 & 4096)) == 0):
                                                    __pc = 7
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                (overflowed__goto_771_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                                (extra_needed__goto_781_12 = (chkcc_rc__goto_1477_11 -% lengthleft__goto_782_38))
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1477_11
                                                if __goto_pending != 0:
                                                    break
                                                lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1477_11
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    else:
                                        while true:
                                            if (overflowed__goto_771_6 != 0):
                                                if (chkmc_length__goto_1479_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                    __pc = 9
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1479_11
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if (lengthleft__goto_782_38 < chkmc_length__goto_1479_11):
                                                    if (((suboptions__goto_768_10 & 4096)) == 0):
                                                        __pc = 7
                                                        __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    (overflowed__goto_771_6 = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    (extra_needed__goto_781_12 = (chkmc_length__goto_1479_11 -% lengthleft__goto_782_38))
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, (subptr__goto_1124_18 as *const c_void) as *i8, (((chkmc_length__goto_1479_11) *% 1)) as i64)
                                                    if __goto_pending != 0:
                                                        break
                                                    buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1479_11
                                                    if __goto_pending != 0:
                                                        break
                                                    lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1479_11
                                                    if __goto_pending != 0:
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            else:
                                if ((((suboptions__goto_768_10 & 512)) != 0) and ((unsafe: *ptr__goto_779_12) == 92)):
                                    new_forcecase__goto_1492_18 = case_state { to_case: 0, single_char: 0 }
                                    if __goto_pending != 0:
                                        break
                                    if (ptr__goto_779_12 < (repend__goto_780_12 - (1 as isize as usize))):
                                        match ptr__goto_779_12[1]
                                            76 =>
                                                (new_forcecase__goto_1492_18.to_case = 1)
                                                (new_forcecase__goto_1492_18.single_char = 0)
                                                ptr__goto_779_12 = ptr__goto_779_12 + 2
                                            108 =>
                                                (new_forcecase__goto_1492_18.to_case = 1)
                                                (new_forcecase__goto_1492_18.single_char = 1)
                                                ptr__goto_779_12 = ptr__goto_779_12 + 2
                                                if ((((ptr__goto_779_12 + (2 as isize as usize)) < repend__goto_780_12) and (ptr__goto_779_12[0] == 92)) and (ptr__goto_779_12[1] == 85)):
                                                    (new_forcecase__goto_1492_18.to_case = 4)
                                                    if __goto_pending != 0:
                                                        break
                                                    (new_forcecase__goto_1492_18.single_char = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    ptr__goto_779_12 = ptr__goto_779_12 + 2
                                                    if __goto_pending != 0:
                                                        break
                                            85 =>
                                                (new_forcecase__goto_1492_18.to_case = 2)
                                                (new_forcecase__goto_1492_18.single_char = 0)
                                                ptr__goto_779_12 = ptr__goto_779_12 + 2
                                            117 =>
                                                (new_forcecase__goto_1492_18.to_case = 3)
                                                (new_forcecase__goto_1492_18.single_char = 1)
                                                ptr__goto_779_12 = ptr__goto_779_12 + 2
                                                if ((((ptr__goto_779_12 + (2 as isize as usize)) < repend__goto_780_12) and (ptr__goto_779_12[0] == 92)) and (ptr__goto_779_12[1] == 76)):
                                                    (new_forcecase__goto_1492_18.to_case = 3)
                                                    if __goto_pending != 0:
                                                        break
                                                    (new_forcecase__goto_1492_18.single_char = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    ptr__goto_779_12 = ptr__goto_779_12 + 2
                                                    if __goto_pending != 0:
                                                        break
                                            _ => 0
                                    if __goto_pending != 0:
                                        break
                                    if (new_forcecase__goto_1492_18.to_case != 0):
                                        if ((substitute_case_callout__goto_787_14 != (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)) and (forcecase__goto_991_14.to_case != 0)):
                                            while true:
                                                if (chars_outstanding__goto_1550_11 > 0):
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (guess__goto_1550_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + guess__goto_1550_11
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        lengthleft__goto_782_38 = lengthleft__goto_782_38 + ((buff_offset__goto_782_12 -% casestart_offset__goto_992_14))
                                                        if __goto_pending != 0:
                                                            break
                                                        (buff_offset__goto_782_12 = casestart_offset__goto_992_14)
                                                        if __goto_pending != 0:
                                                            break
                                                        while true:
                                                            (chkcc_rc__goto_1550_11 = do_case_copy((buffer + buff_offset__goto_782_12), chkcc_length__goto_1550_11, lengthleft__goto_782_38, ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), utf__goto_774_6, substitute_case_callout__goto_787_14, substitute_case_callout_data__goto_789_7))
                                                            if __goto_pending != 0:
                                                                break
                                                            if (chkcc_rc__goto_1550_11 == (0 - (0 as c_ulong) - 1)):
                                                                __pc = 8
                                                                __goto_pending = 1
                                                            if __goto_pending != 0:
                                                                break
                                                            if __goto_pending != 0:
                                                                break
                                                            if (lengthleft__goto_782_38 < chkcc_rc__goto_1550_11):
                                                                if (((suboptions__goto_768_10 & 4096)) == 0):
                                                                    __pc = 7
                                                                    __goto_pending = 1
                                                                if __goto_pending != 0:
                                                                    break
                                                                (overflowed__goto_771_6 = 1)
                                                                if __goto_pending != 0:
                                                                    break
                                                                (extra_needed__goto_781_12 = (chkcc_rc__goto_1550_11 -% lengthleft__goto_782_38))
                                                                if __goto_pending != 0:
                                                                    break
                                                            else:
                                                                buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1550_11
                                                                if __goto_pending != 0:
                                                                    break
                                                                lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1550_11
                                                                if __goto_pending != 0:
                                                                    break
                                                            if __goto_pending != 0:
                                                                break
                                                            if __goto_pending != 0:
                                                                break
                                                            if not ((0 != 0)):
                                                                break
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        (forcecase__goto_991_14 = new_forcecase__goto_1492_18)
                                        if __goto_pending != 0:
                                            break
                                        (casestart_offset__goto_992_14 = buff_offset__goto_782_12)
                                        if __goto_pending != 0:
                                            break
                                        (casestart_extra_needed__goto_993_14 = extra_needed__goto_781_12)
                                        if __goto_pending != 0:
                                            break
                                        continue
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                    (rc__goto_764_5 = _pcre2_check_escape_8(((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, ((&ch__goto_1082_14 as *const c_uint) as *mut c_uint), ((&errorcode__goto_1491_11 as *const c_int) as *mut c_int), code.overall_options, code.extra_options, code.top_bracket, 0, (null as *mut compile_block_8)))
                                    if __goto_pending != 0:
                                        break
                                    if (errorcode__goto_1491_11 != 0):
                                        __pc = 11
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    match rc__goto_764_5
                                        ESC_E =>
                                            __pc = 4
                                            __goto_pending = 1
                                        ESC_Q =>
                                            (escaped_literal__goto_770_6 = 1)
                                            continue
                                            if (rc__goto_764_5 == ESC_v):
                                                (ch__goto_1082_14 = 11)
                                            ((&temp__goto_776_13[0] as *mut u8)[0] = ch__goto_1082_14)
                                            if __goto_pending != 0:
                                                break
                                            (chlen__goto_1083_18 = 1)
                                            if __goto_pending != 0:
                                                break
                                            if ((forcecase__goto_991_14.to_case != 0) and (substitute_case_callout__goto_787_14 == (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong))):
                                                while true:
                                                    (chkcc_rc__goto_1589_11 = default_substitute_case_callout(((&temp__goto_776_13[0] as *mut u8) as *const u8), chkcc_length__goto_1589_11, (buffer + buff_offset__goto_782_12), (if overflowed__goto_771_6 != 0: 0 else: lengthleft__goto_782_38), ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), code))
                                                    if __goto_pending != 0:
                                                        break
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (chkcc_rc__goto_1589_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkcc_rc__goto_1589_11
                                                        if __goto_pending != 0:
                                                            break
                                                        break
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if (lengthleft__goto_782_38 < chkcc_rc__goto_1589_11):
                                                        if (((suboptions__goto_768_10 & 4096)) == 0):
                                                            __pc = 7
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        (overflowed__goto_771_6 = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        (extra_needed__goto_781_12 = (chkcc_rc__goto_1589_11 -% lengthleft__goto_782_38))
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1589_11
                                                        if __goto_pending != 0:
                                                            break
                                                        lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1589_11
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            else:
                                                while true:
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (chkmc_length__goto_1591_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1591_11
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        if (lengthleft__goto_782_38 < chkmc_length__goto_1591_11):
                                                            if (((suboptions__goto_768_10 & 4096)) == 0):
                                                                __pc = 7
                                                                __goto_pending = 1
                                                            if __goto_pending != 0:
                                                                break
                                                            (overflowed__goto_771_6 = 1)
                                                            if __goto_pending != 0:
                                                                break
                                                            (extra_needed__goto_781_12 = (chkmc_length__goto_1591_11 -% lengthleft__goto_782_38))
                                                            if __goto_pending != 0:
                                                                break
                                                        else:
                                                            with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, ((&temp__goto_776_13[0] as *mut u8) as *const c_void) as *i8, (((chkmc_length__goto_1591_11) *% 1)) as i64)
                                                            if __goto_pending != 0:
                                                                break
                                                            buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1591_11
                                                            if __goto_pending != 0:
                                                                break
                                                            lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1591_11
                                                            if __goto_pending != 0:
                                                                break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            continue
                                            if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 60)):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            (name_start__goto_1597_22 = ptr__goto_779_12)
                                            if __goto_pending != 0:
                                                break
                                            if (not ((read_name_subst(((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, utf__goto_774_6, (code.tables + (((512 + 320)) as isize as usize))) != 0))):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (name_len__goto_1596_22 = ((ptr__goto_779_12 as usize -% name_start__goto_1597_22 as usize) / sizeof[u8]()))
                                            if __goto_pending != 0:
                                                break
                                            if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 62)):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            (special__goto_1085_14 = 0)
                                            if __goto_pending != 0:
                                                break
                                            (group__goto_1084_9 = -1)
                                            if __goto_pending != 0:
                                                break
                                            with_memcpy(((&name__goto_1090_17[0] as *mut u8) as *mut c_void) as *i8, (name_start__goto_1597_22 as *const c_void) as *i8, (((name_len__goto_1596_22) *% 1)) as i64)
                                            if __goto_pending != 0:
                                                break
                                            ((&name__goto_1090_17[0] as *mut u8)[name_len__goto_1596_22] = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if (rc__goto_764_5 < 0):
                                                (special__goto_1085_14 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                (group__goto_1084_9 = ((0 - rc__goto_764_5) - 1))
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                            __pc = 11
                                            __goto_pending = 1
                                        0 =>
                                            if (rc__goto_764_5 == ESC_v):
                                                (ch__goto_1082_14 = 11)
                                            ((&temp__goto_776_13[0] as *mut u8)[0] = ch__goto_1082_14)
                                            if __goto_pending != 0:
                                                break
                                            (chlen__goto_1083_18 = 1)
                                            if __goto_pending != 0:
                                                break
                                            if ((forcecase__goto_991_14.to_case != 0) and (substitute_case_callout__goto_787_14 == (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong))):
                                                while true:
                                                    (chkcc_rc__goto_1589_11 = default_substitute_case_callout(((&temp__goto_776_13[0] as *mut u8) as *const u8), chkcc_length__goto_1589_11, (buffer + buff_offset__goto_782_12), (if overflowed__goto_771_6 != 0: 0 else: lengthleft__goto_782_38), ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), code))
                                                    if __goto_pending != 0:
                                                        break
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (chkcc_rc__goto_1589_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkcc_rc__goto_1589_11
                                                        if __goto_pending != 0:
                                                            break
                                                        break
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if (lengthleft__goto_782_38 < chkcc_rc__goto_1589_11):
                                                        if (((suboptions__goto_768_10 & 4096)) == 0):
                                                            __pc = 7
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        (overflowed__goto_771_6 = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        (extra_needed__goto_781_12 = (chkcc_rc__goto_1589_11 -% lengthleft__goto_782_38))
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1589_11
                                                        if __goto_pending != 0:
                                                            break
                                                        lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1589_11
                                                        if __goto_pending != 0:
                                                            break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            else:
                                                while true:
                                                    if (overflowed__goto_771_6 != 0):
                                                        if (chkmc_length__goto_1591_11 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                            __pc = 9
                                                            __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1591_11
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        if (lengthleft__goto_782_38 < chkmc_length__goto_1591_11):
                                                            if (((suboptions__goto_768_10 & 4096)) == 0):
                                                                __pc = 7
                                                                __goto_pending = 1
                                                            if __goto_pending != 0:
                                                                break
                                                            (overflowed__goto_771_6 = 1)
                                                            if __goto_pending != 0:
                                                                break
                                                            (extra_needed__goto_781_12 = (chkmc_length__goto_1591_11 -% lengthleft__goto_782_38))
                                                            if __goto_pending != 0:
                                                                break
                                                        else:
                                                            with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, ((&temp__goto_776_13[0] as *mut u8) as *const c_void) as *i8, (((chkmc_length__goto_1591_11) *% 1)) as i64)
                                                            if __goto_pending != 0:
                                                                break
                                                            buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1591_11
                                                            if __goto_pending != 0:
                                                                break
                                                            lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1591_11
                                                            if __goto_pending != 0:
                                                                break
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            continue
                                            if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 60)):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            (name_start__goto_1597_22 = ptr__goto_779_12)
                                            if __goto_pending != 0:
                                                break
                                            if (not ((read_name_subst(((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, utf__goto_774_6, (code.tables + (((512 + 320)) as isize as usize))) != 0))):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (name_len__goto_1596_22 = ((ptr__goto_779_12 as usize -% name_start__goto_1597_22 as usize) / sizeof[u8]()))
                                            if __goto_pending != 0:
                                                break
                                            if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 62)):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            (special__goto_1085_14 = 0)
                                            if __goto_pending != 0:
                                                break
                                            (group__goto_1084_9 = -1)
                                            if __goto_pending != 0:
                                                break
                                            with_memcpy(((&name__goto_1090_17[0] as *mut u8) as *mut c_void) as *i8, (name_start__goto_1597_22 as *const c_void) as *i8, (((name_len__goto_1596_22) *% 1)) as i64)
                                            if __goto_pending != 0:
                                                break
                                            ((&name__goto_1090_17[0] as *mut u8)[name_len__goto_1596_22] = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if (rc__goto_764_5 < 0):
                                                (special__goto_1085_14 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                (group__goto_1084_9 = ((0 - rc__goto_764_5) - 1))
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                            __pc = 11
                                            __goto_pending = 1
                                        ESC_g =>
                                            if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 60)):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            (name_start__goto_1597_22 = ptr__goto_779_12)
                                            if __goto_pending != 0:
                                                break
                                            if (not ((read_name_subst(((&ptr__goto_779_12 as *const *const u8) as *mut *const u8), repend__goto_780_12, utf__goto_774_6, (code.tables + (((512 + 320)) as isize as usize))) != 0))):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (name_len__goto_1596_22 = ((ptr__goto_779_12 as usize -% name_start__goto_1597_22 as usize) / sizeof[u8]()))
                                            if __goto_pending != 0:
                                                break
                                            if ((ptr__goto_779_12 >= repend__goto_780_12) or ((unsafe: *ptr__goto_779_12) != 62)):
                                                __pc = 11
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            (special__goto_1085_14 = 0)
                                            if __goto_pending != 0:
                                                break
                                            (group__goto_1084_9 = -1)
                                            if __goto_pending != 0:
                                                break
                                            with_memcpy(((&name__goto_1090_17[0] as *mut u8) as *mut c_void) as *i8, (name_start__goto_1597_22 as *const c_void) as *i8, (((name_len__goto_1596_22) *% 1)) as i64)
                                            if __goto_pending != 0:
                                                break
                                            ((&name__goto_1090_17[0] as *mut u8)[name_len__goto_1596_22] = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if (rc__goto_764_5 < 0):
                                                (special__goto_1085_14 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                (group__goto_1084_9 = ((0 - rc__goto_764_5) - 1))
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                            __pc = 11
                                            __goto_pending = 1
                                        _ =>
                                            if (rc__goto_764_5 < 0):
                                                (special__goto_1085_14 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                (group__goto_1084_9 = ((0 - rc__goto_764_5) - 1))
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                            __pc = 11
                                            __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                else:
                                    (ch_start__goto_1635_18 = ptr__goto_779_12)
                                    if __goto_pending != 0:
                                        break
                                    (ch__goto_1082_14 = (unsafe: *ptr__goto_779_12))
                                    (ptr__goto_779_12 = ptr__goto_779_12 + 1)
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    ch__goto_1082_14
                                    if __goto_pending != 0:
                                        break
                                    if ((forcecase__goto_991_14.to_case != 0) and (substitute_case_callout__goto_787_14 == (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong))):
                                        while true:
                                            (chkcc_rc__goto_1644_9 = default_substitute_case_callout(ch_start__goto_1635_18, chkcc_length__goto_1644_9, (buffer + buff_offset__goto_782_12), (if overflowed__goto_771_6 != 0: 0 else: lengthleft__goto_782_38), ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), code))
                                            if __goto_pending != 0:
                                                break
                                            if (overflowed__goto_771_6 != 0):
                                                if (chkcc_rc__goto_1644_9 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                    __pc = 9
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkcc_rc__goto_1644_9
                                                if __goto_pending != 0:
                                                    break
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if (lengthleft__goto_782_38 < chkcc_rc__goto_1644_9):
                                                if (((suboptions__goto_768_10 & 4096)) == 0):
                                                    __pc = 7
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                (overflowed__goto_771_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                                (extra_needed__goto_781_12 = (chkcc_rc__goto_1644_9 -% lengthleft__goto_782_38))
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1644_9
                                                if __goto_pending != 0:
                                                    break
                                                lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1644_9
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    else:
                                        while true:
                                            if (overflowed__goto_771_6 != 0):
                                                if (chkmc_length__goto_1646_9 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                    __pc = 9
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1646_9
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if (lengthleft__goto_782_38 < chkmc_length__goto_1646_9):
                                                    if (((suboptions__goto_768_10 & 4096)) == 0):
                                                        __pc = 7
                                                        __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    (overflowed__goto_771_6 = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    (extra_needed__goto_781_12 = (chkmc_length__goto_1646_9 -% lengthleft__goto_782_38))
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, (ch_start__goto_1635_18 as *const c_void) as *i8, (((chkmc_length__goto_1646_9) *% 1)) as i64)
                                                    if __goto_pending != 0:
                                                        break
                                                    buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1646_9
                                                    if __goto_pending != 0:
                                                        break
                                                    lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1646_9
                                                    if __goto_pending != 0:
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                    if __goto_pending != 0:
                        break
                    if ((substitute_case_callout__goto_787_14 != (null as *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)) and (forcecase__goto_991_14.to_case != 0)):
                        while true:
                            if (chars_outstanding__goto_1659_5 > 0):
                                if (overflowed__goto_771_6 != 0):
                                    if (guess__goto_1659_5 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                        __pc = 9
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    extra_needed__goto_781_12 = extra_needed__goto_781_12 + guess__goto_1659_5
                                    if __goto_pending != 0:
                                        break
                                else:
                                    lengthleft__goto_782_38 = lengthleft__goto_782_38 + ((buff_offset__goto_782_12 -% casestart_offset__goto_992_14))
                                    if __goto_pending != 0:
                                        break
                                    (buff_offset__goto_782_12 = casestart_offset__goto_992_14)
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (chkcc_rc__goto_1659_5 = do_case_copy((buffer + buff_offset__goto_782_12), chkcc_length__goto_1659_5, lengthleft__goto_782_38, ((&forcecase__goto_991_14 as *const case_state) as *mut case_state), utf__goto_774_6, substitute_case_callout__goto_787_14, substitute_case_callout_data__goto_789_7))
                                        if __goto_pending != 0:
                                            break
                                        if (chkcc_rc__goto_1659_5 == (0 - (0 as c_ulong) - 1)):
                                            __pc = 8
                                            __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if (lengthleft__goto_782_38 < chkcc_rc__goto_1659_5):
                                            if (((suboptions__goto_768_10 & 4096)) == 0):
                                                __pc = 7
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (overflowed__goto_771_6 = 1)
                                            if __goto_pending != 0:
                                                break
                                            (extra_needed__goto_781_12 = (chkcc_rc__goto_1659_5 -% lengthleft__goto_782_38))
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkcc_rc__goto_1659_5
                                            if __goto_pending != 0:
                                                break
                                            lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkcc_rc__goto_1659_5
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                            if not ((0 != 0)):
                                break
                    if __goto_pending != 0:
                        break
                    if ((mcontext != (null as *mut pcre2_real_match_context_8)) and (mcontext.substitute_callout != (null as *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int))):
                        if (not ((overflowed__goto_771_6 != 0))):
                            (scb__goto_785_32.subscount = subs__goto_765_5)
                            if __goto_pending != 0:
                                break
                            ((&scb__goto_785_32.output_offsets[0] as *mut c_ulong)[1] = buff_offset__goto_782_12)
                            if __goto_pending != 0:
                                break
                            (rc__goto_764_5 = mcontext.substitute_callout(((&scb__goto_785_32 as *const pcre2_substitute_callout_block_8) as *mut pcre2_substitute_callout_block_8), mcontext.substitute_callout_data))
                            if __goto_pending != 0:
                                break
                            if (rc__goto_764_5 != 0):
                                newlength__goto_1680_20 = ((&scb__goto_785_32.output_offsets[0] as *mut c_ulong)[1] -% (&scb__goto_785_32.output_offsets[0] as *mut c_ulong)[0])
                                if __goto_pending != 0:
                                    break
                                oldlength__goto_1681_20 = (ovector__goto_783_13[1] -% ovector__goto_783_13[0])
                                if __goto_pending != 0:
                                    break
                                buff_offset__goto_782_12 = buff_offset__goto_782_12 - newlength__goto_1680_20
                                if __goto_pending != 0:
                                    break
                                lengthleft__goto_782_38 = lengthleft__goto_782_38 + newlength__goto_1680_20
                                if __goto_pending != 0:
                                    break
                                if (not ((replacement_only__goto_773_6 != 0))):
                                    while true:
                                        if (overflowed__goto_771_6 != 0):
                                            if (chkmc_length__goto_1685_32 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                                __pc = 9
                                                __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1685_32
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if (lengthleft__goto_782_38 < chkmc_length__goto_1685_32):
                                                if (((suboptions__goto_768_10 & 4096)) == 0):
                                                    __pc = 7
                                                    __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                (overflowed__goto_771_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                                (extra_needed__goto_781_12 = (chkmc_length__goto_1685_32 -% lengthleft__goto_782_38))
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, ((subject + ovector__goto_783_13[0]) as *const c_void) as *i8, (((chkmc_length__goto_1685_32) *% 1)) as i64)
                                                if __goto_pending != 0:
                                                    break
                                                buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1685_32
                                                if __goto_pending != 0:
                                                    break
                                                lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1685_32
                                                if __goto_pending != 0:
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                if (rc__goto_764_5 < 0):
                                    suboptions__goto_768_10 = suboptions__goto_768_10 & ((0 - 256 - 1))
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                        else:
                            newlength_buf__goto_1704_18 = (buff_offset__goto_782_12 -% (&scb__goto_785_32.output_offsets[0] as *mut c_ulong)[0])
                            if __goto_pending != 0:
                                break
                            newlength_extra__goto_1705_18 = (extra_needed__goto_781_12 -% sub_start_extra_needed__goto_786_12)
                            if __goto_pending != 0:
                                break
                            newlength__goto_1706_18 = (if (newlength_extra__goto_1705_18 > ((0 - (0 as c_ulong) - 1) -% newlength_buf__goto_1704_18)): (0 - (0 as c_ulong) - 1) else: (newlength_buf__goto_1704_18 +% newlength_extra__goto_1705_18))
                            if __goto_pending != 0:
                                break
                            oldlength__goto_1709_18 = (ovector__goto_783_13[1] -% ovector__goto_783_13[0])
                            if __goto_pending != 0:
                                break
                            if (oldlength__goto_1709_18 > newlength__goto_1706_18):
                                additional__goto_1716_20 = (oldlength__goto_1709_18 -% newlength__goto_1706_18)
                                if __goto_pending != 0:
                                    break
                                if (additional__goto_1716_20 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                    __pc = 9
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                extra_needed__goto_781_12 = extra_needed__goto_781_12 + additional__goto_1716_20
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    if ((((suboptions__goto_768_10 & 256)) == 0) or (not ((pcre2_next_match_8(match_data, ((&start_offset as *const c_ulong) as *mut c_ulong), ((&goptions__goto_767_10 as *const c_uint) as *mut c_uint)) != 0)))):
                        (start_offset = ovector__goto_783_13[1])
                        if __goto_pending != 0:
                            break
                        break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                if (not ((replacement_only__goto_773_6 != 0))):
                    (fraglength__goto_782_50 = (length -% start_offset))
                    if __goto_pending != 0:
                        continue
                    while true:
                        if (overflowed__goto_771_6 != 0):
                            if (chkmc_length__goto_1754_3 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                                __pc = 9
                                __goto_pending = 1
                            if __goto_pending != 0:
                                break
                            extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1754_3
                            if __goto_pending != 0:
                                break
                        else:
                            if (lengthleft__goto_782_38 < chkmc_length__goto_1754_3):
                                if (((suboptions__goto_768_10 & 4096)) == 0):
                                    __pc = 7
                                    __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                (overflowed__goto_771_6 = 1)
                                if __goto_pending != 0:
                                    break
                                (extra_needed__goto_781_12 = (chkmc_length__goto_1754_3 -% lengthleft__goto_782_38))
                                if __goto_pending != 0:
                                    break
                            else:
                                with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, ((subject + start_offset) as *const c_void) as *i8, (((chkmc_length__goto_1754_3) *% 1)) as i64)
                                if __goto_pending != 0:
                                    break
                                buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1754_3
                                if __goto_pending != 0:
                                    break
                                lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1754_3
                                if __goto_pending != 0:
                                    break
                        if __goto_pending != 0:
                            break
                        if __goto_pending != 0:
                            break
                        if not ((0 != 0)):
                            break
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                ((&temp__goto_776_13[0] as *mut u8)[0] = 0)
                if __goto_pending != 0:
                    continue
                while true:
                    if (overflowed__goto_771_6 != 0):
                        if (chkmc_length__goto_1758_1 > ((0 - (0 as c_ulong) - 1) -% extra_needed__goto_781_12)):
                            __pc = 9
                            __goto_pending = 1
                        if __goto_pending != 0:
                            break
                        extra_needed__goto_781_12 = extra_needed__goto_781_12 + chkmc_length__goto_1758_1
                        if __goto_pending != 0:
                            break
                    else:
                        if (lengthleft__goto_782_38 < chkmc_length__goto_1758_1):
                            if (((suboptions__goto_768_10 & 4096)) == 0):
                                __pc = 7
                                __goto_pending = 1
                            if __goto_pending != 0:
                                break
                            (overflowed__goto_771_6 = 1)
                            if __goto_pending != 0:
                                break
                            (extra_needed__goto_781_12 = (chkmc_length__goto_1758_1 -% lengthleft__goto_782_38))
                            if __goto_pending != 0:
                                break
                        else:
                            with_memcpy(((buffer + buff_offset__goto_782_12) as *mut c_void) as *i8, ((&temp__goto_776_13[0] as *mut u8) as *const c_void) as *i8, (((chkmc_length__goto_1758_1) *% 1)) as i64)
                            if __goto_pending != 0:
                                break
                            buff_offset__goto_782_12 = buff_offset__goto_782_12 + chkmc_length__goto_1758_1
                            if __goto_pending != 0:
                                break
                            lengthleft__goto_782_38 = lengthleft__goto_782_38 - chkmc_length__goto_1758_1
                            if __goto_pending != 0:
                                break
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                    if not ((0 != 0)):
                        break
                if __goto_pending != 0:
                    continue
                if (overflowed__goto_771_6 != 0):
                    (rc__goto_764_5 = (-48))
                    if __goto_pending != 0:
                        continue
                    if (extra_needed__goto_781_12 > ((0 - (0 as c_ulong) - 1) -% buff_length__goto_782_25)):
                        __pc = 9
                        __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                    ((unsafe: *blength) = (buff_length__goto_782_25 +% extra_needed__goto_781_12))
                    if __goto_pending != 0:
                        continue
                else:
                    (rc__goto_764_5 = subs__goto_765_5)
                    if __goto_pending != 0:
                        continue
                    ((unsafe: *blength) = (buff_offset__goto_782_12 -% 1))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                __pc = 6
                continue
            6 =>  // EXIT
                (__goto_pending = 0)
                if (internal_match_data__goto_769_19 != (null as *mut pcre2_real_match_data_8)):
                    pcre2_match_data_free_8(internal_match_data__goto_769_19)
                else:
                    (match_data.rc = rc__goto_764_5)
                if __goto_pending != 0:
                    continue
                return rc__goto_764_5
                if __goto_pending != 0:
                    continue
                __pc = 7
                continue
            7 =>  // NOROOM
                (__goto_pending = 0)
                (rc__goto_764_5 = (-48))
                if __goto_pending != 0:
                    continue
                __pc = 6
                continue
                __pc = 8
                continue
            8 =>  // CASEERROR
                (__goto_pending = 0)
                (rc__goto_764_5 = (-69))
                if __goto_pending != 0:
                    continue
                __pc = 6
                continue
                __pc = 9
                continue
            9 =>  // TOOLARGEREPLACE
                (__goto_pending = 0)
                (rc__goto_764_5 = (-70))
                if __goto_pending != 0:
                    continue
                __pc = 6
                continue
                __pc = 10
                continue
            10 =>  // BAD
                (__goto_pending = 0)
                (rc__goto_764_5 = (-35))
                if __goto_pending != 0:
                    continue
                __pc = 12
                continue
                __pc = 11
                continue
            11 =>  // BADESCAPE
                (__goto_pending = 0)
                (rc__goto_764_5 = (-57))
                if __goto_pending != 0:
                    continue
                __pc = 12
                continue
            12 =>  // PTREXIT
                (__goto_pending = 0)
                ((unsafe: *blength) = ((((ptr__goto_779_12 as usize -% replacement as usize) / sizeof[u8]())) as c_ulong))
                if __goto_pending != 0:
                    continue
                __pc = 6
                continue
            _ => break

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
fn find_text_end(code: *const pcre2_real_code_8, ptrptr: *mut *const u8, ptrend: *const u8, last: c_int) -> c_int:
    var rc__goto_96_5: c_int = 0
    var nestlevel__goto_97_10: c_uint = 0
    var literal__goto_98_6: c_int = 0
    var ptr__goto_99_12: *const u8 = null
    var erc__goto_131_9: c_int = 0
    var errorcode__goto_132_9: c_int = 0
    var ch__goto_133_14: c_uint = 0
    var esc_end_ptr__goto_134_16: *const u8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                rc__goto_96_5 = 0
                nestlevel__goto_97_10 = 0
                literal__goto_98_6 = 0
                ptr__goto_99_12 = (unsafe: *ptrptr)
                while (ptr__goto_99_12 < ptrend):
                    if (literal__goto_98_6 != 0):
                        if (((ptr__goto_99_12[0] == 92) and (ptr__goto_99_12 < (ptrend - (1 as isize as usize)))) and (ptr__goto_99_12[1] == 69)):
                            (literal__goto_98_6 = 0)
                            if __goto_pending != 0:
                                break
                            ptr__goto_99_12 = ptr__goto_99_12 + 1
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                    else:
                        if ((unsafe: *ptr__goto_99_12) == 125):
                            if (nestlevel__goto_97_10 == 0):
                                __pc = 1
                                __goto_pending = 1
                            if __goto_pending != 0:
                                break
                            (nestlevel__goto_97_10 = nestlevel__goto_97_10 - 1)
                            if __goto_pending != 0:
                                break
                        else:
                            if ((((unsafe: *ptr__goto_99_12) == 58) and (not ((last != 0)))) and (nestlevel__goto_97_10 == 0)):
                                __pc = 1
                                __goto_pending = 1
                            else:
                                if ((unsafe: *ptr__goto_99_12) == 36):
                                    if ((ptr__goto_99_12 < (ptrend - (1 as isize as usize))) and (ptr__goto_99_12[1] == 123)):
                                        (nestlevel__goto_97_10 = nestlevel__goto_97_10 + 1)
                                        if __goto_pending != 0:
                                            break
                                        ptr__goto_99_12 = ptr__goto_99_12 + 1
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if ((unsafe: *ptr__goto_99_12) == 92):
                                        if (ptr__goto_99_12 < (ptrend - (1 as isize as usize))):
                                            match ptr__goto_99_12[1]
                                                76 =>
                                                    continue
                                                _ => 0
                                        if __goto_pending != 0:
                                            break
                                        ptr__goto_99_12 = ptr__goto_99_12 + 1
                                        if __goto_pending != 0:
                                            break
                                        (erc__goto_131_9 = _pcre2_check_escape_8(((&ptr__goto_99_12 as *const *const u8) as *mut *const u8), ptrend, ((&ch__goto_133_14 as *const c_uint) as *mut c_uint), ((&errorcode__goto_132_9 as *const c_int) as *mut c_int), code.overall_options, code.extra_options, code.top_bracket, 0, (null as *mut compile_block_8)))
                                        if __goto_pending != 0:
                                            break
                                        if (errorcode__goto_132_9 != 0):
                                            (rc__goto_96_5 = (-57))
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (esc_end_ptr__goto_134_16 = ptr__goto_99_12)
                                        if __goto_pending != 0:
                                            break
                                        ptr__goto_99_12 = ptr__goto_99_12 - 1
                                        if __goto_pending != 0:
                                            break
                                        match erc__goto_131_9
                                            0 =>
                                                (literal__goto_98_6 = 1)
                                            ESC_Q =>
                                                (literal__goto_98_6 = 1)
                                            ESC_g => 0
                                            _ =>
                                                if (erc__goto_131_9 < 0):
                                                    break
                                                (ptr__goto_99_12 = esc_end_ptr__goto_134_16)
                                                (rc__goto_96_5 = (-57))
                                                __pc = 1
                                                __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                    if __goto_pending != 0:
                        break
                    (ptr__goto_99_12 = ptr__goto_99_12 + 1)
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                (rc__goto_96_5 = (-58))
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr__goto_99_12)
                if __goto_pending != 0:
                    continue
                return rc__goto_96_5
                if __goto_pending != 0:
                    continue
            _ => break

fn read_name_subst(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, ctypes: *const u8) -> c_int:
    var ptr__goto_221_12: *const u8 = null
    var nameptr__goto_222_12: *const u8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr__goto_221_12 = (unsafe: *ptrptr)
                nameptr__goto_222_12 = ptr__goto_221_12
                if (ptr__goto_221_12 >= ptrend):
                    __pc = 1
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                utf
                if __goto_pending != 0:
                    continue
                while (((ptr__goto_221_12 < ptrend) and (1 != 0)) and (((ctypes[(unsafe: *ptr__goto_221_12)] & 16)) != 0)):
                    (ptr__goto_221_12 = ptr__goto_221_12 + 1)
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                if __goto_pending != 0:
                    continue
                if (((ptr__goto_221_12 as usize -% nameptr__goto_222_12 as usize) / sizeof[u8]()) > 128):
                    __pc = 1
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                if (ptr__goto_221_12 == nameptr__goto_222_12):
                    __pc = 1
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                ((unsafe: *ptrptr) = ptr__goto_221_12)
                if __goto_pending != 0:
                    continue
                return 1
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // FAILED
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr__goto_221_12)
                if __goto_pending != 0:
                    continue
                return 0
                if __goto_pending != 0:
                    continue
            _ => break

type case_state { to_case: c_int = 0, single_char: c_int = 0 }
type struct_case_state = case_state
fn pessimistic_case_inflation(len: c_ulong) -> c_ulong:
    return (((len >> 3)) +% 10)

fn default_substitute_case_callout(__param_input: *const u8, input_len: c_ulong, __param_output: *mut u8, __param_output_cap: c_ulong, state: *mut case_state, code: *const pcre2_real_code_8) -> c_ulong:
    var input = __param_input
    var output = __param_output
    var output_cap = __param_output_cap
    var input_end: *const u8 = (input + input_len)
    var temp: [6]u8
    var next_to_upper: c_int
    var rest_to_upper: c_int
    var single_char: c_int
    var overflow: c_int = 0
    var written: c_ulong = 0
    if (input_len == 0):
        return 0

    match state.to_case
        1 => 0
        3 =>
            (next_to_upper = 1)
            (rest_to_upper = 0)
            (state.to_case = 1)
        4 =>
            (next_to_upper = 0)
            (rest_to_upper = 1)
            (state.to_case = 2)
        _ =>
            return 0

    (single_char = state.single_char)
    if (single_char != 0):
        (state.to_case = 0)

    while (input < input_end):
        var ch: c_uint
        var chlen: c_uint
        (ch = (unsafe: *input))
        (input = input + 1)
        0
        if (1 != 0):
            if ((((((code.tables + (512 as isize as usize)) + (((if next_to_upper != 0: 96 else: 128)) as isize as usize)))[(ch / 8)] & ((1 << ((ch % 8)))))) == 0):
                (ch = ((code.tables + (256 as isize as usize)))[ch])
            
        
        ((&temp[0] as *mut u8)[0] = ch)
        (chlen = 1)
        
        if ((not ((overflow != 0))) and (chlen <= output_cap)):
            with_memcpy((output as *mut c_void) as *i8, ((&temp[0] as *mut u8) as *const c_void) as *i8, (((chlen) *% 1)) as i64)
            output = output + chlen
            output_cap = output_cap - chlen
        else:
            (overflow = 1)
        
        if (chlen > ((0 - (0 as c_ulong) - 1) -% written)):
            return (0 - (0 as c_ulong) - 1)
        
        written = written + chlen
        (next_to_upper = rest_to_upper)
        if (single_char != 0):
            var rest_len: c_ulong = ((input_end as usize -% input as usize) / sizeof[u8]())
            if ((not ((overflow != 0))) and (rest_len <= output_cap)):
                with_memcpy((output as *mut c_void) as *i8, (input as *const c_void) as *i8, (((rest_len) *% 1)) as i64)
            
            if (rest_len > ((0 - (0 as c_ulong) - 1) -% written)):
                return (0 - (0 as c_ulong) - 1)
            
            written = written + rest_len
            return written
        

    return written

fn do_case_copy(input_output: *mut u8, input_len: c_ulong, output_cap: c_ulong, state: *mut case_state, utf: c_int, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, substitute_case_callout_data: *mut c_void) -> c_ulong:
    var input: *const u8 = (input_output as *const u8)
    var output: *mut u8 = input_output
    var rc: c_ulong
    var rc2: c_ulong
    var ch1_to_case: c_int
    var rest_to_case: c_int
    var ch1: [6]u8
    var ch1_len: c_ulong
    var rest: *const u8
    var rest_len: c_ulong
    var ch1_overflow: c_int = 0
    var rest_overflow: c_int = 0
    utf
    match state.to_case
        1 =>
            (ch1_to_case = state.to_case)
            (rest_to_case = 0)
        4 =>
            (ch1_to_case = 1)
            (rest_to_case = 2)
        _ =>
            return 0

        var ch_end: *const u8 = input
    var ch: c_uint
    (ch = (unsafe: *ch_end))
    (ch_end = ch_end + 1)
    0
    ch
    (ch1_len = ((ch_end as usize -% input as usize) / sizeof[u8]()))
    with_memcpy(((&ch1[0] as *mut u8) as *mut c_void) as *i8, (input as *const c_void) as *i8, (((ch1_len) *% 1)) as i64)

    (rest = (input + ch1_len))
    (rest_len = (input_len -% ch1_len))
        var ch1_cap: c_ulong
    var max_ch1_cap: c_ulong
    (ch1_cap = ch1_len)
    (max_ch1_cap = (output_cap -% rest_len))
    while (1 != 0):
        (rc = substitute_case_callout(((&ch1[0] as *mut u8) as *const u8), ch1_len, output, ch1_cap, ch1_to_case, substitute_case_callout_data))
        if (rc == (0 - (0 as c_ulong) - 1)):
            return rc
        
        if (rc <= ch1_cap):
            break
        
        if (rc > max_ch1_cap):
            (ch1_overflow = 1)
            break
        
        with_memmove(((input_output + rc) as *mut c_void) as *i8, (rest as *const c_void) as *i8, (((rest_len) *% 1)) as i64)
        (rest = (input + rc))
        (ch1_cap = rc)


    if (rest_to_case == 0):
        if (not ((ch1_overflow != 0))):
            with_memmove(((output + rc) as *mut c_void) as *i8, (rest as *const c_void) as *i8, (((rest_len) *% 1)) as i64)
        
        (rc2 = rest_len)
        (state.to_case = 0)
    else:
        var dummy: [1]u8
        (rc2 = substitute_case_callout(rest, rest_len, (if ch1_overflow != 0: (&dummy[0] as *mut u8) else: (output + rc)), (if ch1_overflow != 0: 0 else: (output_cap -% rc)), rest_to_case, substitute_case_callout_data))
        if (rc2 == (0 - (0 as c_ulong) - 1)):
            return rc2
        
        if ((not ((ch1_overflow != 0))) and (rc2 > (output_cap -% rc))):
            (rest_overflow = 1)
        
        if ((ch1_overflow != 0) and (rc2 < rest_len)):
            (rc2 = rest_len)
        
        (state.to_case = 2)

    if (rc2 > ((0 - (0 as c_ulong) - 1) -% rc)):
        return (0 - (0 as c_ulong) - 1)

    rest_overflow
    return (rc +% rc2)

