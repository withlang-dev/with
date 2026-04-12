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
fn pcre2_match_8(code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, start_offset: c_ulong, __param_options: c_uint, match_data: *mut pcre2_real_match_data_8, __param_mcontext: *mut pcre2_real_match_context_8) -> c_int:
    var subject = __param_subject
    var length = __param_length
    var options = __param_options
    var mcontext = __param_mcontext
    var rc__goto_6993_5: c_int = 0
    var start_bits__goto_6994_16: *const u8 = null
    var re__goto_6995_24: *const pcre2_real_code_8 = null
    var original_options__goto_6996_10: c_uint = 0
    var anchored__goto_6998_6: c_int = 0
    var firstline__goto_6999_6: c_int = 0
    var has_first_cu__goto_7000_6: c_int = 0
    var has_req_cu__goto_7001_6: c_int = 0
    var startline__goto_7002_6: c_int = 0
    var memchr_found_first_cu__goto_7005_12: *const u8 = null
    var memchr_found_first_cu2__goto_7006_12: *const u8 = null
    var first_cu__goto_7009_13: u8 = 0
    var first_cu2__goto_7010_13: u8 = 0
    var req_cu__goto_7011_13: u8 = 0
    var req_cu2__goto_7012_13: u8 = 0
    var null_str__goto_7014_13: [1]u8 = [0 as u8; 1]
    var original_subject__goto_7015_12: *const u8 = null
    var bumpalong_limit__goto_7016_12: *const u8 = null
    var end_subject__goto_7017_12: *const u8 = null
    var true_end_subject__goto_7018_12: *const u8 = null
    var start_match__goto_7019_12: *const u8 = null
    var req_cu_ptr__goto_7020_12: *const u8 = null
    var start_partial__goto_7021_12: *const u8 = null
    var match_partial__goto_7022_12: *const u8 = null
    var utf__goto_7031_6: c_int = 0
    var frame_size__goto_7042_12: c_ulong = 0
    var heapframes_size__goto_7043_12: c_ulong = 0
    var cb__goto_7048_21: pcre2_callout_block_8
    var actual_match_block__goto_7049_13: match_block_8
    var mb__goto_7050_14: *mut match_block_8 = null
    var max_size__goto_7536_14: c_ulong = 0
    var new_start_match__goto_7632_14: *const u8 = null
    var t__goto_7651_18: *const u8 = null
    var ok__goto_7675_14: c_int = 0
    var c__goto_7678_23: u8 = 0
    var pp1__goto_7721_22: *const u8 = null
    var pp2__goto_7722_22: *const u8 = null
    var searchlength__goto_7723_22: c_ulong = 0
    var c__goto_7839_20: c_uint = 0
    var p__goto_7865_18: *const u8 = null
    var check_length__goto_7903_20: c_ulong = 0
    var pp__goto_7917_24: *const u8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                start_bits__goto_6994_16 = (null as *const u8)
                re__goto_6995_24 = (code as *const pcre2_real_code_8)
                original_options__goto_6996_10 = options
                has_first_cu__goto_7000_6 = 0
                has_req_cu__goto_7001_6 = 0
                first_cu__goto_7009_13 = 0
                first_cu2__goto_7010_13 = 0
                req_cu__goto_7011_13 = 0
                req_cu2__goto_7012_13 = 0
                original_subject__goto_7015_12 = subject
                utf__goto_7031_6 = 0
                mb__goto_7050_14 = ((&actual_match_block__goto_7049_13 as *const match_block_8) as *mut match_block_8)
                if ((subject == (null as *const u8)) and (length == 0)):
                    (subject = ((&null_str__goto_7014_13[0] as *mut u8) as *const u8))
                if __goto_pending != 0:
                    continue
                if (match_data == (null as *mut pcre2_real_match_data_8)):
                    return (-51)
                if __goto_pending != 0:
                    continue
                if ((code == (null as *const pcre2_real_code_8)) or (subject == (null as *const u8))):
                    return (match_data.rc = (-51))
                if __goto_pending != 0:
                    continue
                if (((options & (0 - (((((((((((((2147483648 as c_uint) | 536870912) | 1) | 2) | 4) | 8) | 1073741824) | 32) | 16) | 8192) | 16384) | 262144)) - 1))) != 0):
                    return (match_data.rc = (-34))
                if __goto_pending != 0:
                    continue
                (start_match__goto_7019_12 = (subject + start_offset))
                if __goto_pending != 0:
                    continue
                (req_cu_ptr__goto_7020_12 = (start_match__goto_7019_12 - (1 as isize as usize)))
                if __goto_pending != 0:
                    continue
                if (length == ((0 - (0 as c_ulong) - 1))):
                    (length = _pcre2_strlen_8(subject))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                (end_subject__goto_7017_12 = (subject + length))
                (true_end_subject__goto_7018_12 = end_subject__goto_7017_12)
                if __goto_pending != 0:
                    continue
                if (start_offset > length):
                    return (match_data.rc = (-33))
                if __goto_pending != 0:
                    continue
                if (re__goto_6995_24.magic_number != 1346589253):
                    return (match_data.rc = (-31))
                if __goto_pending != 0:
                    continue
                if (((re__goto_6995_24.flags & (((1 | 2) | 4)))) != 1):
                    return (match_data.rc = (-32))
                if __goto_pending != 0:
                    continue
                options = options | (((re__goto_6995_24.flags & ((65536 | 131072)))) / ((((((65536 | 131072)) & (((0 - ((65536 | 131072)) - 1) +% 1)))) / ((((4 | 8)) & (((0 - ((4 | 8)) - 1) +% 1)))))))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.partial = (if (((options & 32)) != 0): 2 else: (if (((options & 16)) != 0): 1 else: 0)))
                if __goto_pending != 0:
                    continue
                if ((mb__goto_7050_14.partial != 0) and (((((re__goto_6995_24.overall_options | options)) & 536870912)) != 0)):
                    return (match_data.rc = (-34))
                if __goto_pending != 0:
                    continue
                if (((mcontext != (null as *mut pcre2_real_match_context_8)) and (mcontext.offset_limit != ((0 - (0 as c_ulong) - 1)))) and (((re__goto_6995_24.overall_options & 8388608)) == 0)):
                    return (match_data.rc = (-56))
                if __goto_pending != 0:
                    continue
                if (((match_data.flags & 1)) != 0):
                    match_data.memctl.free((match_data.subject as *mut c_void), match_data.memctl.memory_data)
                    if __goto_pending != 0:
                        continue
                    match_data.flags = match_data.flags & (0 - 1 - 1)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                (match_data.subject = (null as *const u8))
                if __goto_pending != 0:
                    continue
                (match_data.startchar = 0)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.check_subject = subject)
                if __goto_pending != 0:
                    continue
                if (mcontext == (null as *mut pcre2_real_match_context_8)):
                    (mcontext = ((((&_pcre2_default_match_context_8 as *const pcre2_real_match_context_8) as *mut pcre2_real_match_context_8)) as *mut pcre2_real_match_context_8))
                    if __goto_pending != 0:
                        continue
                    (mb__goto_7050_14.memctl = re__goto_6995_24.memctl)
                    if __goto_pending != 0:
                        continue
                else:
                    (mb__goto_7050_14.memctl = mcontext.memctl)
                if __goto_pending != 0:
                    continue
                (anchored__goto_6998_6 = (if ((((re__goto_6995_24.overall_options | options)) & (2147483648 as c_uint))) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (firstline__goto_6999_6 = (if (not ((anchored__goto_6998_6 != 0))) and (((re__goto_6995_24.overall_options & 256)) != 0): 1 else: 0))
                if __goto_pending != 0:
                    continue
                (startline__goto_7002_6 = (if ((re__goto_6995_24.flags & 512)) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (bumpalong_limit__goto_7016_12 = (if (mcontext.offset_limit == ((0 - (0 as c_ulong) - 1))): true_end_subject__goto_7018_12 else: (subject + mcontext.offset_limit)))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.cb = ((&cb__goto_7048_21 as *const pcre2_callout_block_8) as *mut pcre2_callout_block_8))
                if __goto_pending != 0:
                    continue
                (cb__goto_7048_21.version = 2)
                if __goto_pending != 0:
                    continue
                (cb__goto_7048_21.subject = subject)
                if __goto_pending != 0:
                    continue
                (cb__goto_7048_21.subject_length = ((((end_subject__goto_7017_12 as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                if __goto_pending != 0:
                    continue
                (cb__goto_7048_21.callout_flags = 0)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.callout = mcontext.callout)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.callout_data = mcontext.callout_data)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.start_subject = subject)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.start_offset = start_offset)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.end_subject = end_subject__goto_7017_12)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.true_end_subject = true_end_subject__goto_7018_12)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.hasthen = (if ((re__goto_6995_24.flags & 4096)) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.hasbsk = (if ((re__goto_6995_24.flags & 16777216)) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.allowemptypartial = (if (re__goto_6995_24.max_lookbehind > 0) or (((re__goto_6995_24.flags & 8192)) != 0): 1 else: 0))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.allowlookaroundbsk = (if ((re__goto_6995_24.extra_options & 64)) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.poptions = re__goto_6995_24.overall_options)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.ignore_skip_arg = 0)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.nomatch_mark = (null as *const u8))
                (mb__goto_7050_14.mark = mb__goto_7050_14.nomatch_mark)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.name_table = ((((re__goto_6995_24 as *const u8) + sizeof[pcre2_real_code_8]())) as *const u8))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.name_count = re__goto_6995_24.name_count)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.name_entry_size = re__goto_6995_24.name_entry_size)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.start_code = ((((re__goto_6995_24 as *const u8) + re__goto_6995_24.code_start)) as *const u8))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.bsr_convention = re__goto_6995_24.bsr_convention)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.nltype = 0)
                if __goto_pending != 0:
                    continue
                match re__goto_6995_24.newline_convention
                    1 =>
                        (mb__goto_7050_14.nllen = 1)
                        ((&mb__goto_7050_14.nl[0] as *mut u8)[0] = 13)
                    2 =>
                        (mb__goto_7050_14.nllen = 1)
                        ((&mb__goto_7050_14.nl[0] as *mut u8)[0] = 10)
                    6 =>
                        (mb__goto_7050_14.nllen = 1)
                        ((&mb__goto_7050_14.nl[0] as *mut u8)[0] = 0)
                    3 =>
                        (mb__goto_7050_14.nllen = 2)
                        ((&mb__goto_7050_14.nl[0] as *mut u8)[0] = 13)
                        ((&mb__goto_7050_14.nl[0] as *mut u8)[1] = 10)
                    4 =>
                        (mb__goto_7050_14.nltype = 1)
                    5 =>
                        (mb__goto_7050_14.nltype = 2)
                    _ =>
                        return (match_data.rc = (-44))
                if __goto_pending != 0:
                    continue
                (frame_size__goto_7042_12 = (((((120 +% ((re__goto_6995_24.top_bracket * 2) *% sizeof[c_ulong]())) +% 8) -% 1)) & (0 - ((8 -% 1)) - 1)))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.heap_limit = ((if (mcontext.heap_limit < re__goto_6995_24.limit_heap): mcontext.heap_limit else: re__goto_6995_24.limit_heap)))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.match_limit = (if (mcontext.match_limit < re__goto_6995_24.limit_match): mcontext.match_limit else: re__goto_6995_24.limit_match))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.match_limit_depth = (if (mcontext.depth_limit < re__goto_6995_24.limit_depth): mcontext.depth_limit else: re__goto_6995_24.limit_depth))
                if __goto_pending != 0:
                    continue
                (heapframes_size__goto_7043_12 = (frame_size__goto_7042_12 *% 10))
                if __goto_pending != 0:
                    continue
                if (heapframes_size__goto_7043_12 < 20480):
                    (heapframes_size__goto_7043_12 = 20480)
                if __goto_pending != 0:
                    continue
                if ((heapframes_size__goto_7043_12 / 1024) > mb__goto_7050_14.heap_limit):
                    max_size__goto_7536_14 = (1024 *% mb__goto_7050_14.heap_limit)
                    if __goto_pending != 0:
                        continue
                    if (max_size__goto_7536_14 < frame_size__goto_7042_12):
                        return (match_data.rc = (-63))
                    if __goto_pending != 0:
                        continue
                    (heapframes_size__goto_7043_12 = max_size__goto_7536_14)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (match_data.heapframes_size < heapframes_size__goto_7043_12):
                    match_data.memctl.free((match_data.heapframes as *mut c_void), match_data.memctl.memory_data)
                    if __goto_pending != 0:
                        continue
                    (match_data.heapframes = (match_data.memctl.malloc(heapframes_size__goto_7043_12, match_data.memctl.memory_data) as *mut heapframe))
                    if __goto_pending != 0:
                        continue
                    if (match_data.heapframes == (null as *mut heapframe)):
                        (match_data.heapframes_size = 0)
                        if __goto_pending != 0:
                            continue
                        return (match_data.rc = (-48))
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                    (match_data.heapframes_size = heapframes_size__goto_7043_12)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                with_memset(((((match_data.heapframes) as *mut i8) + 120) as *mut c_void) as *i8, 255, (frame_size__goto_7042_12 -% 120) as i64)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.lcc = (re__goto_6995_24.tables + (0 as isize as usize)))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.fcc = (re__goto_6995_24.tables + (256 as isize as usize)))
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.ctypes = (re__goto_6995_24.tables + (((512 + 320)) as isize as usize)))
                if __goto_pending != 0:
                    continue
                if (((re__goto_6995_24.flags & 16)) != 0):
                    (has_first_cu__goto_7000_6 = 1)
                    if __goto_pending != 0:
                        continue
                    (first_cu2__goto_7010_13 = ((re__goto_6995_24.first_codeunit) as u8))
                    (first_cu__goto_7009_13 = first_cu2__goto_7010_13)
                    if __goto_pending != 0:
                        continue
                    if (((re__goto_6995_24.flags & 32)) != 0):
                        (first_cu2__goto_7010_13 = ((mb__goto_7050_14.fcc)[first_cu__goto_7009_13]))
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                else:
                    if ((not ((startline__goto_7002_6 != 0))) and (((re__goto_6995_24.flags & 64)) != 0)):
                        (start_bits__goto_6994_16 = (&re__goto_6995_24.start_bitmap[0] as *mut u8))
                if __goto_pending != 0:
                    continue
                if (((re__goto_6995_24.flags & 128)) != 0):
                    (has_req_cu__goto_7001_6 = 1)
                    if __goto_pending != 0:
                        continue
                    (req_cu2__goto_7012_13 = ((re__goto_6995_24.last_codeunit) as u8))
                    (req_cu__goto_7011_13 = req_cu2__goto_7012_13)
                    if __goto_pending != 0:
                        continue
                    if (((re__goto_6995_24.flags & 256)) != 0):
                        (req_cu2__goto_7012_13 = ((mb__goto_7050_14.fcc)[req_cu__goto_7011_13]))
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                (match_partial__goto_7022_12 = (null as *const u8))
                (start_partial__goto_7021_12 = match_partial__goto_7022_12)
                if __goto_pending != 0:
                    continue
                (mb__goto_7050_14.hitend = 0)
                if __goto_pending != 0:
                    continue
                (memchr_found_first_cu__goto_7005_12 = (null as *const u8))
                if __goto_pending != 0:
                    continue
                (memchr_found_first_cu2__goto_7006_12 = (null as *const u8))
                if __goto_pending != 0:
                    continue
                while true:
                    if (((re__goto_6995_24.optimization_flags & 4)) != 0):
                        if (firstline__goto_6999_6 != 0):
                            t__goto_7651_18 = start_match__goto_7019_12
                            if __goto_pending != 0:
                                break
                            while ((t__goto_7651_18 < end_subject__goto_7017_12) and (not (((if (mb__goto_7050_14.nltype != 0): ((if ((t__goto_7651_18) < mb__goto_7050_14.end_subject) and (_pcre2_is_newline_8((t__goto_7651_18), mb__goto_7050_14.nltype, mb__goto_7050_14.end_subject, ((&(mb__goto_7050_14.nllen) as *const c_uint) as *mut c_uint), utf__goto_7031_6) != 0): 1 else: 0)) else: ((if (((t__goto_7651_18) <= (mb__goto_7050_14.end_subject - mb__goto_7050_14.nllen)) and ((unsafe: *t__goto_7651_18) == (&mb__goto_7050_14.nl[0] as *mut u8)[0])) and ((mb__goto_7050_14.nllen == 1) or (t__goto_7651_18[1] == (&mb__goto_7050_14.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)))):
                                (t__goto_7651_18 = t__goto_7651_18 + 1)
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            (end_subject__goto_7017_12 = t__goto_7651_18)
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        if (anchored__goto_6998_6 != 0):
                            if ((has_first_cu__goto_7000_6 != 0) or (start_bits__goto_6994_16 != (null as *const u8))):
                                ok__goto_7675_14 = (if start_match__goto_7019_12 < end_subject__goto_7017_12: 1 else: 0)
                                if __goto_pending != 0:
                                    break
                                if (ok__goto_7675_14 != 0):
                                    c__goto_7678_23 = (unsafe: *start_match__goto_7019_12)
                                    if __goto_pending != 0:
                                        break
                                    (ok__goto_7675_14 = (if (has_first_cu__goto_7000_6 != 0) and ((c__goto_7678_23 == first_cu__goto_7009_13) or (c__goto_7678_23 == first_cu2__goto_7010_13)): 1 else: 0))
                                    if __goto_pending != 0:
                                        break
                                    if ((not ((ok__goto_7675_14 != 0))) and (start_bits__goto_6994_16 != (null as *const u8))):
                                        (ok__goto_7675_14 = (if ((start_bits__goto_6994_16[(c__goto_7678_23 / 8)] & ((1 << ((c__goto_7678_23 & 7)))))) != 0: 1 else: 0))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (not ((ok__goto_7675_14 != 0))):
                                    (rc__goto_6993_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                        else:
                            if (has_first_cu__goto_7000_6 != 0):
                                if (first_cu__goto_7009_13 != first_cu2__goto_7010_13):
                                    pp1__goto_7721_22 = (null as *const u8)
                                    if __goto_pending != 0:
                                        break
                                    pp2__goto_7722_22 = (null as *const u8)
                                    if __goto_pending != 0:
                                        break
                                    searchlength__goto_7723_22 = ((end_subject__goto_7017_12 as usize -% start_match__goto_7019_12 as usize) / sizeof[u8]())
                                    if __goto_pending != 0:
                                        break
                                    if ((memchr_found_first_cu__goto_7005_12 == (null as *const u8)) or (start_match__goto_7019_12 > memchr_found_first_cu__goto_7005_12)):
                                        (pp1__goto_7721_22 = (memchr((start_match__goto_7019_12 as *const c_void), first_cu__goto_7009_13, searchlength__goto_7723_22) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        (memchr_found_first_cu__goto_7005_12 = (if (pp1__goto_7721_22 == (null as *const u8)): end_subject__goto_7017_12 else: pp1__goto_7721_22))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (pp1__goto_7721_22 = (if (memchr_found_first_cu__goto_7005_12 == end_subject__goto_7017_12): (null as *const u8) else: memchr_found_first_cu__goto_7005_12))
                                    if __goto_pending != 0:
                                        break
                                    if ((memchr_found_first_cu2__goto_7006_12 == (null as *const u8)) or (start_match__goto_7019_12 > memchr_found_first_cu2__goto_7006_12)):
                                        (pp2__goto_7722_22 = (memchr((start_match__goto_7019_12 as *const c_void), first_cu2__goto_7010_13, searchlength__goto_7723_22) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        (memchr_found_first_cu2__goto_7006_12 = (if (pp2__goto_7722_22 == (null as *const u8)): end_subject__goto_7017_12 else: pp2__goto_7722_22))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (pp2__goto_7722_22 = (if (memchr_found_first_cu2__goto_7006_12 == end_subject__goto_7017_12): (null as *const u8) else: memchr_found_first_cu2__goto_7006_12))
                                    if __goto_pending != 0:
                                        break
                                    if (pp1__goto_7721_22 == (null as *const u8)):
                                        (start_match__goto_7019_12 = (if (pp2__goto_7722_22 == (null as *const u8)): end_subject__goto_7017_12 else: pp2__goto_7722_22))
                                    else:
                                        (start_match__goto_7019_12 = (if ((pp2__goto_7722_22 == (null as *const u8)) or (pp1__goto_7721_22 < pp2__goto_7722_22)): pp1__goto_7721_22 else: pp2__goto_7722_22))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    (start_match__goto_7019_12 = (memchr((start_match__goto_7019_12 as *const c_void), first_cu__goto_7009_13, ((end_subject__goto_7017_12 as usize -% start_match__goto_7019_12 as usize) / sizeof[u8]())) as *const u8))
                                    if __goto_pending != 0:
                                        break
                                    if (start_match__goto_7019_12 == (null as *const u8)):
                                        (start_match__goto_7019_12 = end_subject__goto_7017_12)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((mb__goto_7050_14.partial == 0) and (start_match__goto_7019_12 >= mb__goto_7050_14.end_subject)):
                                    (rc__goto_6993_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            else:
                                if (startline__goto_7002_6 != 0):
                                    if (start_match__goto_7019_12 > (mb__goto_7050_14.start_subject + start_offset)):
                                        while ((start_match__goto_7019_12 < end_subject__goto_7017_12) and (not (((if (mb__goto_7050_14.nltype != 0): ((if ((start_match__goto_7019_12) > mb__goto_7050_14.start_subject) and (_pcre2_was_newline_8((start_match__goto_7019_12), mb__goto_7050_14.nltype, mb__goto_7050_14.start_subject, ((&(mb__goto_7050_14.nllen) as *const c_uint) as *mut c_uint), utf__goto_7031_6) != 0): 1 else: 0)) else: ((if (((start_match__goto_7019_12) >= (mb__goto_7050_14.start_subject + mb__goto_7050_14.nllen)) and ((unsafe: *((start_match__goto_7019_12 - mb__goto_7050_14.nllen))) == (&mb__goto_7050_14.nl[0] as *mut u8)[0])) and ((mb__goto_7050_14.nllen == 1) or ((unsafe: *(((start_match__goto_7019_12 - mb__goto_7050_14.nllen) + (1 as isize as usize)))) == (&mb__goto_7050_14.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)))):
                                            (start_match__goto_7019_12 = start_match__goto_7019_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((((start_match__goto_7019_12[-1] == 13) and ((mb__goto_7050_14.nltype == 1) or (mb__goto_7050_14.nltype == 2))) and (start_match__goto_7019_12 < end_subject__goto_7017_12)) and ((unsafe: *start_match__goto_7019_12) == 10)):
                                            (start_match__goto_7019_12 = start_match__goto_7019_12 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (start_bits__goto_6994_16 != (null as *const u8)):
                                        while (start_match__goto_7019_12 < end_subject__goto_7017_12):
                                            c__goto_7839_20 = (unsafe: *start_match__goto_7019_12)
                                            if __goto_pending != 0:
                                                break
                                            if (((start_bits__goto_6994_16[(c__goto_7839_20 / 8)] & ((1 << ((c__goto_7839_20 & 7)))))) != 0):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (start_match__goto_7019_12 = start_match__goto_7019_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((mb__goto_7050_14.partial == 0) and (start_match__goto_7019_12 >= mb__goto_7050_14.end_subject)):
                                            (rc__goto_6993_5 = 0)
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
                            break
                        (end_subject__goto_7017_12 = mb__goto_7050_14.end_subject)
                        if __goto_pending != 0:
                            break
                        if (mb__goto_7050_14.partial == 0):
                            if (((end_subject__goto_7017_12 as usize -% start_match__goto_7019_12 as usize) / sizeof[u8]()) < re__goto_6995_24.minlength):
                                (rc__goto_6993_5 = 0)
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            (p__goto_7865_18 = (start_match__goto_7019_12 + (((if has_first_cu__goto_7000_6 != 0: 1 else: 0)) as isize as usize)))
                            if __goto_pending != 0:
                                break
                            if ((has_req_cu__goto_7001_6 != 0) and (p__goto_7865_18 > req_cu_ptr__goto_7020_12)):
                                check_length__goto_7903_20 = ((end_subject__goto_7017_12 as usize -% start_match__goto_7019_12 as usize) / sizeof[u8]())
                                if __goto_pending != 0:
                                    break
                                if ((check_length__goto_7903_20 < 5000) or ((not ((anchored__goto_6998_6 != 0))) and (check_length__goto_7903_20 < 5000000))):
                                    if (req_cu__goto_7011_13 != req_cu2__goto_7012_13):
                                        pp__goto_7917_24 = p__goto_7865_18
                                        if __goto_pending != 0:
                                            break
                                        (p__goto_7865_18 = (memchr((pp__goto_7917_24 as *const c_void), req_cu__goto_7011_13, ((end_subject__goto_7017_12 as usize -% pp__goto_7917_24 as usize) / sizeof[u8]())) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        if (p__goto_7865_18 == (null as *const u8)):
                                            (p__goto_7865_18 = (memchr((pp__goto_7917_24 as *const c_void), req_cu2__goto_7012_13, ((end_subject__goto_7017_12 as usize -% pp__goto_7917_24 as usize) / sizeof[u8]())) as *const u8))
                                            if __goto_pending != 0:
                                                break
                                            if (p__goto_7865_18 == (null as *const u8)):
                                                (p__goto_7865_18 = end_subject__goto_7017_12)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (p__goto_7865_18 = (memchr((p__goto_7865_18 as *const c_void), req_cu__goto_7011_13, ((end_subject__goto_7017_12 as usize -% p__goto_7865_18 as usize) / sizeof[u8]())) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        if (p__goto_7865_18 == (null as *const u8)):
                                            (p__goto_7865_18 = end_subject__goto_7017_12)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (p__goto_7865_18 >= end_subject__goto_7017_12):
                                        (rc__goto_6993_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (req_cu_ptr__goto_7020_12 = p__goto_7865_18)
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
                    if (start_match__goto_7019_12 > bumpalong_limit__goto_7016_12):
                        (rc__goto_6993_5 = 0)
                        if __goto_pending != 0:
                            break
                        break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    (cb__goto_7048_21.start_match = ((((start_match__goto_7019_12 as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                    if __goto_pending != 0:
                        break
                    cb__goto_7048_21.callout_flags = cb__goto_7048_21.callout_flags | 1
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.start_used_ptr = start_match__goto_7019_12)
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.last_used_ptr = start_match__goto_7019_12)
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.moptions = options)
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.match_call_count = 0)
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.end_offset_top = 0)
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.skip_arg_count = 0)
                    if __goto_pending != 0:
                        break
                    (rc__goto_6993_5 = match_(start_match__goto_7019_12, mb__goto_7050_14.start_code, re__goto_6995_24.top_bracket, frame_size__goto_7042_12, match_data, mb__goto_7050_14))
                    if __goto_pending != 0:
                        break
                    if ((mb__goto_7050_14.hitend != 0) and (start_partial__goto_7021_12 == (null as *const u8))):
                        (start_partial__goto_7021_12 = mb__goto_7050_14.start_used_ptr)
                        if __goto_pending != 0:
                            break
                        (match_partial__goto_7022_12 = start_match__goto_7019_12)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    match rc__goto_6993_5
                        (-994) =>
                            (new_start_match__goto_7632_14 = start_match__goto_7019_12)
                            (mb__goto_7050_14.ignore_skip_arg = mb__goto_7050_14.skip_arg_count)
                        (-995) =>
                            if (mb__goto_7050_14.verb_skip_ptr > start_match__goto_7019_12):
                                (new_start_match__goto_7632_14 = mb__goto_7050_14.verb_skip_ptr)
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            (new_start_match__goto_7632_14 = (start_match__goto_7019_12 + (1 as isize as usize)))
                        0 =>
                            (new_start_match__goto_7632_14 = (start_match__goto_7019_12 + (1 as isize as usize)))
                        (-997) =>
                            (rc__goto_6993_5 = 0)
                            __pc = 1
                            __goto_pending = 1
                        _ =>
                            __pc = 1
                            __goto_pending = 1
                    if __goto_pending != 0:
                        break
                    (rc__goto_6993_5 = 0)
                    if __goto_pending != 0:
                        break
                    if ((firstline__goto_6999_6 != 0) and ((if (mb__goto_7050_14.nltype != 0): ((if ((start_match__goto_7019_12) < mb__goto_7050_14.end_subject) and (_pcre2_is_newline_8((start_match__goto_7019_12), mb__goto_7050_14.nltype, mb__goto_7050_14.end_subject, ((&(mb__goto_7050_14.nllen) as *const c_uint) as *mut c_uint), utf__goto_7031_6) != 0): 1 else: 0)) else: ((if (((start_match__goto_7019_12) <= (mb__goto_7050_14.end_subject - mb__goto_7050_14.nllen)) and ((unsafe: *start_match__goto_7019_12) == (&mb__goto_7050_14.nl[0] as *mut u8)[0])) and ((mb__goto_7050_14.nllen == 1) or (start_match__goto_7019_12[1] == (&mb__goto_7050_14.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)):
                        break
                    if __goto_pending != 0:
                        break
                    (start_match__goto_7019_12 = new_start_match__goto_7632_14)
                    if __goto_pending != 0:
                        break
                    if ((anchored__goto_6998_6 != 0) or (start_match__goto_7019_12 > end_subject__goto_7017_12)):
                        break
                    if __goto_pending != 0:
                        break
                    if ((((((start_match__goto_7019_12 > (subject + start_offset)) and (start_match__goto_7019_12[-1] == 13)) and (start_match__goto_7019_12 < end_subject__goto_7017_12)) and ((unsafe: *start_match__goto_7019_12) == 10)) and (((re__goto_6995_24.flags & 2048)) == 0)) and (((mb__goto_7050_14.nltype == 1) or (mb__goto_7050_14.nltype == 2)) or (mb__goto_7050_14.nllen == 2))):
                        (start_match__goto_7019_12 = start_match__goto_7019_12 + 1)
                    if __goto_pending != 0:
                        break
                    (mb__goto_7050_14.mark = (null as *const u8))
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // ENDLOOP
                (__goto_pending = 0)
                (match_data.code = re__goto_6995_24)
                if __goto_pending != 0:
                    continue
                (match_data.mark = mb__goto_7050_14.mark)
                if __goto_pending != 0:
                    continue
                (match_data.matchedby = 0)
                if __goto_pending != 0:
                    continue
                (match_data.options = original_options__goto_6996_10)
                if __goto_pending != 0:
                    continue
                if (rc__goto_6993_5 == 1):
                    (match_data.rc = (if ((mb__goto_7050_14.end_offset_top as c_int) >= (2 * match_data.oveccount)): 0 else: (((mb__goto_7050_14.end_offset_top as c_int) / 2) + 1)))
                    if __goto_pending != 0:
                        continue
                    (match_data.subject_length = length)
                    if __goto_pending != 0:
                        continue
                    (match_data.start_offset = start_offset)
                    if __goto_pending != 0:
                        continue
                    (match_data.startchar = ((start_match__goto_7019_12 as usize -% subject as usize) / sizeof[u8]()))
                    if __goto_pending != 0:
                        continue
                    (match_data.leftchar = ((mb__goto_7050_14.start_used_ptr as usize -% subject as usize) / sizeof[u8]()))
                    if __goto_pending != 0:
                        continue
                    (match_data.rightchar = ((((if (mb__goto_7050_14.last_used_ptr > mb__goto_7050_14.end_match_ptr): mb__goto_7050_14.last_used_ptr else: mb__goto_7050_14.end_match_ptr)) as usize -% subject as usize) / sizeof[u8]()))
                    if __goto_pending != 0:
                        continue
                    if (((options & 16384)) != 0):
                        if (length != 0):
                            (match_data.subject = (match_data.memctl.malloc((((length) *% 1)), match_data.memctl.memory_data) as *const u8))
                            if __goto_pending != 0:
                                continue
                            if (match_data.subject == (null as *const u8)):
                                return (match_data.rc = (-48))
                            if __goto_pending != 0:
                                continue
                            with_memcpy((match_data.subject as *mut c_void) as *i8, (subject as *const c_void) as *i8, (((length) *% 1)) as i64)
                            if __goto_pending != 0:
                                continue
                        else:
                            (match_data.subject = (null as *const u8))
                        if __goto_pending != 0:
                            continue
                        match_data.flags = match_data.flags | 1
                        if __goto_pending != 0:
                            continue
                    else:
                        (match_data.subject = original_subject__goto_7015_12)
                    if __goto_pending != 0:
                        continue
                    return match_data.rc
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                (match_data.mark = mb__goto_7050_14.nomatch_mark)
                if __goto_pending != 0:
                    continue
                if ((rc__goto_6993_5 != 0) and (rc__goto_6993_5 != (-2))):
                    (match_data.rc = rc__goto_6993_5)
                else:
                    if (match_partial__goto_7022_12 != (null as *const u8)):
                        (match_data.subject = original_subject__goto_7015_12)
                        if __goto_pending != 0:
                            continue
                        (match_data.subject_length = length)
                        if __goto_pending != 0:
                            continue
                        (match_data.start_offset = start_offset)
                        if __goto_pending != 0:
                            continue
                        ((&match_data.ovector[0] as *mut c_ulong)[0] = ((match_partial__goto_7022_12 as usize -% subject as usize) / sizeof[u8]()))
                        if __goto_pending != 0:
                            continue
                        ((&match_data.ovector[0] as *mut c_ulong)[1] = ((end_subject__goto_7017_12 as usize -% subject as usize) / sizeof[u8]()))
                        if __goto_pending != 0:
                            continue
                        (match_data.startchar = ((match_partial__goto_7022_12 as usize -% subject as usize) / sizeof[u8]()))
                        if __goto_pending != 0:
                            continue
                        (match_data.leftchar = ((start_partial__goto_7021_12 as usize -% subject as usize) / sizeof[u8]()))
                        if __goto_pending != 0:
                            continue
                        (match_data.rightchar = ((end_subject__goto_7017_12 as usize -% subject as usize) / sizeof[u8]()))
                        if __goto_pending != 0:
                            continue
                        (match_data.rc = (-2))
                        if __goto_pending != 0:
                            continue
                    else:
                        (match_data.subject = original_subject__goto_7015_12)
                        if __goto_pending != 0:
                            continue
                        (match_data.subject_length = length)
                        if __goto_pending != 0:
                            continue
                        (match_data.start_offset = start_offset)
                        if __goto_pending != 0:
                            continue
                        (match_data.rc = ((0 -% 1)))
                        if __goto_pending != 0:
                            continue
                if __goto_pending != 0:
                    continue
                return match_data.rc
                if __goto_pending != 0:
                    continue
            _ => break

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
let REPTYPE_MIN: c_uint = 0
let REPTYPE_MAX: c_uint = 1
let REPTYPE_POS: c_uint = 2
var rep_min: [11]c_uint = [0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0]
var rep_max: [11]c_uint = [4294967295, 4294967295, 4294967295, 4294967295, 1, 1, 0, 0, 4294967295, 4294967295, 1]
var rep_typ: [12]c_uint = [1, 0, 1, 0, 1, 0, 1, 0, 2, 2, 2, 2]
let RM1: c_uint = 1
let RM2: c_uint = 2
let RM3: c_uint = 3
let RM4: c_uint = 4
let RM5: c_uint = 5
let RM6: c_uint = 6
let RM7: c_uint = 7
let RM8: c_uint = 8
let RM9: c_uint = 9
let RM10: c_uint = 10
let RM11: c_uint = 11
let RM12: c_uint = 12
let RM13: c_uint = 13
let RM14: c_uint = 14
let RM15: c_uint = 15
let RM16: c_uint = 16
let RM17: c_uint = 17
let RM18: c_uint = 18
let RM19: c_uint = 19
let RM20: c_uint = 20
let RM21: c_uint = 21
let RM22: c_uint = 22
let RM23: c_uint = 23
let RM24: c_uint = 24
let RM25: c_uint = 25
let RM26: c_uint = 26
let RM27: c_uint = 27
let RM28: c_uint = 28
let RM29: c_uint = 29
let RM30: c_uint = 30
let RM31: c_uint = 31
let RM32: c_uint = 32
let RM33: c_uint = 33
let RM34: c_uint = 34
let RM35: c_uint = 35
let RM36: c_uint = 36
let RM37: c_uint = 37
let RM38: c_uint = 38
let RM39: c_uint = 39
fn do_callout(F: *mut heapframe, mb: *mut match_block_8, lengthptr: *mut c_ulong) -> c_int:
    var rc: c_int
    var save0: c_ulong
    var save1: c_ulong
    var callout_ovector: *mut c_ulong
    var cb: *mut pcre2_callout_block_8
    ((unsafe: *lengthptr) = (if ((unsafe: *F.ecode) == OP_CALLOUT): _pcre2_OP_lengths_8[OP_CALLOUT] else: ((((((((F.ecode)[(1 + (2 * 2))] as c_uint) << 8))) | (F.ecode)[(((1 + (2 * 2))) + 1)])) as c_uint)))
    if (mb.callout == (null as *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int)):
        return 0

    (callout_ovector = (((&(F.ovector)[0] as *mut c_ulong) as *mut c_ulong) - (2 as isize as usize)))
    (cb = mb.cb)
    (cb.capture_top = (((F.offset_top as c_uint) / 2) +% 1))
    (cb.capture_last = F.capture_last)
    (cb.offset_vector = callout_ovector)
    (cb.mark = mb.nomatch_mark)
    (cb.current_position = ((((F.eptr as usize -% mb.start_subject as usize) / sizeof[u8]())) as c_ulong))
    (cb.pattern_position = ((((((((F.ecode)[1] as c_uint) << 8))) | (F.ecode)[((1) + 1)])) as c_uint))
    (cb.next_item_length = ((((((((F.ecode)[(1 + 2)] as c_uint) << 8))) | (F.ecode)[(((1 + 2)) + 1)])) as c_uint))
    if ((unsafe: *F.ecode) == OP_CALLOUT):
        (cb.callout_number = F.ecode[(1 + (2 * 2))])
        (cb.callout_string_offset = 0)
        (cb.callout_string = (null as *const u8))
        (cb.callout_string_length = 0)
    else:
        (cb.callout_number = 0)
        (cb.callout_string_offset = ((((((((F.ecode)[(1 + (3 * 2))] as c_uint) << 8))) | (F.ecode)[(((1 + (3 * 2))) + 1)])) as c_uint))
        (cb.callout_string = ((F.ecode + (((1 + (4 * 2))) as isize as usize)) + (1 as isize as usize)))
        (cb.callout_string_length = (((unsafe: *lengthptr) -% 9) -% 2))

    (save0 = callout_ovector[0])
    (save1 = callout_ovector[1])
    (callout_ovector[1] = ((0 - (0 as c_ulong) - 1)))
    (callout_ovector[0] = callout_ovector[1])
    (rc = mb.callout(cb, mb.callout_data))
    (callout_ovector[0] = save0)
    (callout_ovector[1] = save1)
    (cb.callout_flags = 0)
    return rc

fn match_ref(offset: c_ulong, caseless: c_int, caseopts: c_int, F: *mut heapframe, mb: *mut match_block_8, lengthptr: *mut c_ulong) -> c_int:
    var p: *const u8
    var length: c_ulong
    var eptr: *const u8
    var eptr_start: *const u8
    caseopts
    if ((offset >= F.offset_top) or ((&F.ovector[0] as *mut c_ulong)[offset] == ((0 - (0 as c_ulong) - 1)))):
        if (((mb.poptions & 512)) != 0):
            ((unsafe: *lengthptr) = 0)
            return 0
        else:
            return -1
        

    (eptr_start = F.eptr)
    (eptr = eptr_start)
    (p = (mb.start_subject + (&F.ovector[0] as *mut c_ulong)[offset]))
    (length = ((&F.ovector[0] as *mut c_ulong)[(offset +% 1)] -% (&F.ovector[0] as *mut c_ulong)[offset]))
    if (caseless != 0):
        while (length > 0):
            var cc: c_uint
            var cp: c_uint
            if (eptr >= mb.end_subject):
                return 1
            
            (cc = (unsafe: *eptr))
            (cp = (unsafe: *p))
            if (((mb.lcc)[cp]) != ((mb.lcc)[cc])):
                return -1
            
            (p = p + 1)
            (eptr = eptr + 1)
            (length = length - 1)
        
        
    else:
        if (mb.partial != 0):
            while (length > 0):
                if (eptr >= mb.end_subject):
                    return 1
                
                if ((unsafe: *(p = p + 1)) != (unsafe: *(eptr = eptr + 1))):
                    return -1
                
                (length = length - 1)
            
        else:
            if ((((((mb.end_subject as usize -% eptr as usize) / sizeof[u8]())) as c_ulong) < length) or (with_memcmp((p as *const c_void) as *i8, (eptr as *const c_void) as *i8, (((length) *% 1)) as i64) != 0)):
                return -1
            
            eptr = eptr + length
        

    ((unsafe: *lengthptr) = ((eptr as usize -% eptr_start as usize) / sizeof[u8]()))
    return 0

fn recurse_update_offsets(F: *mut heapframe, P: *mut heapframe):
    var dst: *mut c_ulong = (&F.ovector[0] as *mut c_ulong)
    var src: *mut c_ulong = (&P.ovector[0] as *mut c_ulong)
    var offset: c_ulong = 2
    var offset_top: c_ulong = (F.offset_top +% 2)
    var diff: c_ulong
    var ecode: *const u8 = F.ecode
    while true:
        (diff = (((((((((((ecode)[1] as c_uint) << 8))) | (ecode)[((1) + 1)])) as c_uint) << 1)) -% offset))
        ecode = ecode + (1 + 2)
        if ((offset +% diff) >= offset_top):
            while ((unsafe: *ecode) == OP_CREF):
                ecode = ecode + (1 + 2)
            
            break
        
        if (diff == 2):
            (dst[0] = src[0])
            (dst[1] = src[1])
        else:
            if (diff >= 4):
                with_memcpy((dst as *mut c_void) as *i8, (src as *const c_void) as *i8, (diff *% sizeof[c_ulong]()) as i64)
        
        diff = diff + 2
        offset = offset + diff
        dst = dst + diff
        src = src + diff
        if not (((unsafe: *ecode) == OP_CREF)):
            break

    (diff = (offset_top -% offset))
    if (diff == 2):
        (dst[0] = src[0])
        (dst[1] = src[1])
    else:
        if (diff >= 4):
            with_memcpy((dst as *mut c_void) as *i8, (src as *const c_void) as *i8, (diff *% sizeof[c_ulong]()) as i64)

    (F.ecode = ecode)
    (F.offset_top = (if (offset <= P.offset_top): P.offset_top else: ((offset -% 2))))

fn match_(start_eptr: *const u8, __param_start_ecode: *const u8, top_bracket: c_ushort, frame_size: c_ulong, match_data: *mut pcre2_real_match_data_8, mb: *mut match_block_8) -> c_int:
    var start_ecode = __param_start_ecode
    var F__goto_706_12: *mut heapframe = null
    var N__goto_707_12: *mut heapframe = null
    var P__goto_708_12: *mut heapframe = null
    var frames_top__goto_710_12: *mut heapframe = null
    var assert_accept_frame__goto_711_12: *mut heapframe = null
    var frame_copy_size__goto_712_12: c_ulong = 0
    var branch_end__goto_716_12: *const u8 = null
    var branch_start__goto_717_12: *const u8 = null
    var bracode__goto_718_12: *const u8 = null
    var offset__goto_719_12: c_ulong = 0
    var length__goto_720_12: c_ulong = 0
    var rrc__goto_722_5: c_int = 0
    var i__goto_727_10: c_uint = 0
    var fc__goto_728_10: c_uint = 0
    var number__goto_729_10: c_uint = 0
    var reptype__goto_730_10: c_uint = 0
    var group_frame_type__goto_731_10: c_uint = 0
    var condition__goto_733_6: c_int = 0
    var cur_is_word__goto_734_6: c_int = 0
    var prev_is_word__goto_735_6: c_int = 0
    var utf__goto_743_6: c_int = 0
    var new__goto_777_14: *mut heapframe = null
    var newsize__goto_778_14: c_ulong = 0
    var usedsize__goto_779_14: c_ulong = 0
    var old_size__goto_792_16: c_ulong = 0
    var max_delta__goto_797_18: c_ulong = 0
    var over_bytes__goto_798_11: c_int = 0
    var ch__goto_1298_16: c_uint = 0
    var cc__goto_1536_18: c_uint = 0
    var cc__goto_1552_20: c_uint = 0
    var cc__goto_1573_20: c_uint = 0
    var count__goto_5270_11: c_int = 0
    var slot__goto_5271_18: *const u8 = null
    var slength__goto_5357_18: c_ulong = 0
    var slength__goto_5378_20: c_ulong = 0
    var samelengths__goto_5400_12: c_int = 0
    var slength__goto_5406_20: c_ulong = 0
    var slength__goto_5460_24: c_ulong = 0
    var next_ecode__goto_5507_18: *const u8 = null
    var next_ecode__goto_5520_18: *const u8 = null
    var next_ecode__goto_5532_18: *const u8 = null
    var next_ecode__goto_5599_20: *const u8 = null
    var current_branch__goto_5647_18: *const u8 = null
    var next_branch__goto_5648_18: *const u8 = null
    var next_ecode__goto_5699_20: *const u8 = null
    var next_ecode__goto_5761_18: *const u8 = null
    var ecode__goto_5886_18: *const u8 = null
    var count__goto_5887_11: c_int = 0
    var slot__goto_5888_18: *const u8 = null
    var count__goto_6071_13: c_int = 0
    var slot__goto_6072_20: *const u8 = null
    var count__goto_6090_13: c_int = 0
    var slot__goto_6091_20: *const u8 = null
    var diff__goto_6278_17: c_long = 0
    var available__goto_6279_16: c_uint = 0
    var y__goto_6457_18: c_uint = 0
    var lastptr__goto_6724_18: *const u8 = null
    var nextptr__goto_6757_18: *const u8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                N__goto_707_12 = (null as *mut heapframe)
                P__goto_708_12 = (null as *mut heapframe)
                assert_accept_frame__goto_711_12 = (null as *mut heapframe)
                branch_end__goto_716_12 = (null as *const u8)
                reptype__goto_730_10 = 0
                utf__goto_743_6 = 0
                (frame_copy_size__goto_712_12 = (frame_size -% 64))
                if __goto_pending != 0:
                    continue
                (F__goto_706_12 = match_data.heapframes)
                if __goto_pending != 0:
                    continue
                (frames_top__goto_710_12 = ((((F__goto_706_12 as *mut i8) + match_data.heapframes_size)) as *mut heapframe))
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.rdepth = 0)
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.capture_last = 0)
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.current_recurse = (4294967295 as c_uint))
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.eptr = start_eptr)
                (F__goto_706_12.start_match = F__goto_706_12.eptr)
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.mark = (null as *const u8))
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.offset_top = 0)
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.last_group_offset = ((0 - (0 as c_ulong) - 1)))
                if __goto_pending != 0:
                    continue
                (group_frame_type__goto_731_10 = 0)
                if __goto_pending != 0:
                    continue
                __pc = 2
                continue
                __pc = 1
                continue
            1 =>  // MATCH_RECURSE
                (__goto_pending = 0)
                (N__goto_707_12 = ((((F__goto_706_12 as *mut i8) + frame_size)) as *mut heapframe))
                if __goto_pending != 0:
                    continue
                if (((((N__goto_707_12 as *mut i8) + frame_size)) as *mut heapframe) >= frames_top__goto_710_12):
                    usedsize__goto_779_14 = (((N__goto_707_12 as *mut i8) as usize -% ((match_data.heapframes) as *mut i8) as usize) / sizeof[c_char]())
                    if __goto_pending != 0:
                        continue
                    if (match_data.heapframes_size >= ((0 -% 1) / 2)):
                        if (match_data.heapframes_size == ((0 -% 1) -% 1)):
                            return (-48)
                        if __goto_pending != 0:
                            continue
                        (newsize__goto_778_14 = ((0 -% 1) -% 1))
                        if __goto_pending != 0:
                            continue
                    else:
                        (newsize__goto_778_14 = (match_data.heapframes_size *% 2))
                    if __goto_pending != 0:
                        continue
                    if ((newsize__goto_778_14 / 1024) >= mb.heap_limit):
                        old_size__goto_792_16 = (match_data.heapframes_size / 1024)
                        if __goto_pending != 0:
                            continue
                        if (mb.heap_limit <= old_size__goto_792_16):
                            return (-63)
                        else:
                            max_delta__goto_797_18 = (1024 *% ((mb.heap_limit -% old_size__goto_792_16)))
                            if __goto_pending != 0:
                                continue
                            over_bytes__goto_798_11 = (match_data.heapframes_size % 1024)
                            if __goto_pending != 0:
                                continue
                            if (over_bytes__goto_798_11 != 0):
                                max_delta__goto_797_18 = max_delta__goto_797_18 - ((1024 - over_bytes__goto_798_11))
                            if __goto_pending != 0:
                                continue
                            (newsize__goto_778_14 = (match_data.heapframes_size +% max_delta__goto_797_18))
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                    if ((newsize__goto_778_14 -% usedsize__goto_779_14) < frame_size):
                        return (-63)
                    if __goto_pending != 0:
                        continue
                    (new__goto_777_14 = (match_data.memctl.malloc(newsize__goto_778_14, match_data.memctl.memory_data) as *mut heapframe))
                    if __goto_pending != 0:
                        continue
                    if (new__goto_777_14 == (null as *mut heapframe)):
                        return (-48)
                    if __goto_pending != 0:
                        continue
                    with_memcpy((new__goto_777_14 as *mut c_void) as *i8, (match_data.heapframes as *const c_void) as *i8, usedsize__goto_779_14 as i64)
                    if __goto_pending != 0:
                        continue
                    (N__goto_707_12 = ((((new__goto_777_14 as *mut i8) + usedsize__goto_779_14)) as *mut heapframe))
                    if __goto_pending != 0:
                        continue
                    (F__goto_706_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                    if __goto_pending != 0:
                        continue
                    match_data.memctl.free((match_data.heapframes as *mut c_void), match_data.memctl.memory_data)
                    if __goto_pending != 0:
                        continue
                    (match_data.heapframes = new__goto_777_14)
                    if __goto_pending != 0:
                        continue
                    (match_data.heapframes_size = newsize__goto_778_14)
                    if __goto_pending != 0:
                        continue
                    (frames_top__goto_710_12 = ((((new__goto_777_14 as *mut i8) + newsize__goto_778_14)) as *mut heapframe))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                with_memcpy((((N__goto_707_12 as *mut i8) + 64) as *mut c_void) as *i8, (((F__goto_706_12 as *mut i8) + 64) as *const c_void) as *i8, frame_copy_size__goto_712_12 as i64)
                if __goto_pending != 0:
                    continue
                (N__goto_707_12.rdepth = (F__goto_706_12.rdepth +% 1))
                if __goto_pending != 0:
                    continue
                (F__goto_706_12 = N__goto_707_12)
                if __goto_pending != 0:
                    continue
                __pc = 2
                continue
            2 =>  // NEW_FRAME
                (__goto_pending = 0)
                (F__goto_706_12.group_frame_type = group_frame_type__goto_731_10)
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.ecode = start_ecode)
                if __goto_pending != 0:
                    continue
                (F__goto_706_12.back_frame = frame_size)
                if __goto_pending != 0:
                    continue
                if (group_frame_type__goto_731_10 != 0):
                    (F__goto_706_12.last_group_offset = (((F__goto_706_12 as *mut i8) as usize -% (match_data.heapframes as *mut i8) as usize) / sizeof[c_char]()))
                    if __goto_pending != 0:
                        continue
                    if ((((group_frame_type__goto_731_10) & (4294901760 as c_uint))) == 262144):
                        (F__goto_706_12.current_recurse = (((group_frame_type__goto_731_10) & 65535)))
                    if __goto_pending != 0:
                        continue
                    (group_frame_type__goto_731_10 = 0)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if ((mb.match_call_count = mb.match_call_count + 1) >= mb.match_limit):
                    return (-47)
                if __goto_pending != 0:
                    continue
                if (F__goto_706_12.rdepth >= mb.match_limit_depth):
                    return (-53)
                if __goto_pending != 0:
                    continue
                while true:
                    (F__goto_706_12.op = (((unsafe: *F__goto_706_12.ecode)) as u8))
                    if __goto_pending != 0:
                        break
                    match F__goto_706_12.op
                        OP_CLOSE =>
                            if (F__goto_706_12.current_recurse == 4294967295):
                                (number__goto_729_10 = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                (offset__goto_719_12 = F__goto_706_12.last_group_offset)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    if (offset__goto_719_12 == ((0 - (0 as c_ulong) - 1))):
                                        return (-44)
                                    if __goto_pending != 0:
                                        break
                                    (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + offset__goto_719_12)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    if (N__goto_707_12.group_frame_type == ((65536 | number__goto_729_10))):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    (offset__goto_719_12 = P__goto_708_12.last_group_offset)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (offset__goto_719_12 = (((number__goto_729_10 << 1)) -% 2))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.capture_last = number__goto_729_10)
                                if __goto_pending != 0:
                                    break
                                ((&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12] = ((P__goto_708_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                if __goto_pending != 0:
                                    break
                                ((&F__goto_706_12.ovector[0] as *mut c_ulong)[(offset__goto_719_12 +% 1)] = ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                if __goto_pending != 0:
                                    break
                                if (offset__goto_719_12 >= F__goto_706_12.offset_top):
                                    (F__goto_706_12.offset_top = (offset__goto_719_12 +% 2))
                                if __goto_pending != 0:
                                    break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + _pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)]
                        OP_ASSERT_ACCEPT =>
                            if (F__goto_706_12.eptr > mb.last_used_ptr):
                                (mb.last_used_ptr = F__goto_706_12.eptr)
                            (assert_accept_frame__goto_711_12 = F__goto_706_12)
                            while true:
                                (rrc__goto_722_5 = (-999))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (F__goto_706_12.current_recurse != 4294967295):
                                (offset__goto_719_12 = F__goto_706_12.last_group_offset)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    if (offset__goto_719_12 == ((0 - (0 as c_ulong) - 1))):
                                        return (-44)
                                    if __goto_pending != 0:
                                        break
                                    (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + offset__goto_719_12)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    if ((((N__goto_707_12.group_frame_type) & (4294901760 as c_uint))) == 262144):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    (offset__goto_719_12 = P__goto_708_12.last_group_offset)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12.eptr = F__goto_706_12.eptr)
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12.mark = F__goto_706_12.mark)
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12.start_match = F__goto_706_12.start_match)
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12 = P__goto_708_12)
                                if __goto_pending != 0:
                                    break
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                                if __goto_pending != 0:
                                    break
                                continue
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.eptr == F__goto_706_12.start_match) and ((((mb.moptions & 4)) != 0) or ((((mb.moptions & 8)) != 0) and (F__goto_706_12.start_match == (mb.start_subject + mb.start_offset))))):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.eptr < mb.end_subject) and (((((mb.moptions | mb.poptions)) & 536870912)) != 0)):
                                if (F__goto_706_12.op == OP_END):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                return 0
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.start_match < (mb.start_subject + mb.start_offset)) or (F__goto_706_12.start_match > F__goto_706_12.eptr)):
                                if (not ((mb.allowlookaroundbsk != 0))):
                                    return (-75)
                                if __goto_pending != 0:
                                    break
                            (mb.end_match_ptr = F__goto_706_12.eptr)
                            (mb.end_offset_top = F__goto_706_12.offset_top)
                            (mb.mark = F__goto_706_12.mark)
                            if (F__goto_706_12.eptr > mb.last_used_ptr):
                                (mb.last_used_ptr = F__goto_706_12.eptr)
                            ((&match_data.ovector[0] as *mut c_ulong)[0] = ((F__goto_706_12.start_match as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            ((&match_data.ovector[0] as *mut c_ulong)[1] = ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (i__goto_727_10 = (2 * ((if ((top_bracket + 1) > match_data.oveccount): match_data.oveccount else: (top_bracket + 1)))))
                            with_memcpy((((&match_data.ovector[0] as *mut c_ulong) + (2 as isize as usize)) as *mut c_void) as *i8, ((&F__goto_706_12.ovector[0] as *mut c_ulong) as *const c_void) as *i8, (((i__goto_727_10 -% 2)) *% sizeof[c_ulong]()) as i64)
                            while ((i__goto_727_10 = i__goto_727_10 - 1) >= (F__goto_706_12.offset_top +% 2)):
                                ((&match_data.ovector[0] as *mut c_ulong)[i__goto_727_10] = ((0 - (0 as c_ulong) - 1)))
                                if __goto_pending != 0:
                                    break
                            return 1
                        OP_ACCEPT =>
                            if (F__goto_706_12.current_recurse != 4294967295):
                                (offset__goto_719_12 = F__goto_706_12.last_group_offset)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    if (offset__goto_719_12 == ((0 - (0 as c_ulong) - 1))):
                                        return (-44)
                                    if __goto_pending != 0:
                                        break
                                    (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + offset__goto_719_12)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    if ((((N__goto_707_12.group_frame_type) & (4294901760 as c_uint))) == 262144):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    (offset__goto_719_12 = P__goto_708_12.last_group_offset)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12.eptr = F__goto_706_12.eptr)
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12.mark = F__goto_706_12.mark)
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12.start_match = F__goto_706_12.start_match)
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12 = P__goto_708_12)
                                if __goto_pending != 0:
                                    break
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                                if __goto_pending != 0:
                                    break
                                continue
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.eptr == F__goto_706_12.start_match) and ((((mb.moptions & 4)) != 0) or ((((mb.moptions & 8)) != 0) and (F__goto_706_12.start_match == (mb.start_subject + mb.start_offset))))):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.eptr < mb.end_subject) and (((((mb.moptions | mb.poptions)) & 536870912)) != 0)):
                                if (F__goto_706_12.op == OP_END):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                return 0
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.start_match < (mb.start_subject + mb.start_offset)) or (F__goto_706_12.start_match > F__goto_706_12.eptr)):
                                if (not ((mb.allowlookaroundbsk != 0))):
                                    return (-75)
                                if __goto_pending != 0:
                                    break
                            (mb.end_match_ptr = F__goto_706_12.eptr)
                            (mb.end_offset_top = F__goto_706_12.offset_top)
                            (mb.mark = F__goto_706_12.mark)
                            if (F__goto_706_12.eptr > mb.last_used_ptr):
                                (mb.last_used_ptr = F__goto_706_12.eptr)
                            ((&match_data.ovector[0] as *mut c_ulong)[0] = ((F__goto_706_12.start_match as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            ((&match_data.ovector[0] as *mut c_ulong)[1] = ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (i__goto_727_10 = (2 * ((if ((top_bracket + 1) > match_data.oveccount): match_data.oveccount else: (top_bracket + 1)))))
                            with_memcpy((((&match_data.ovector[0] as *mut c_ulong) + (2 as isize as usize)) as *mut c_void) as *i8, ((&F__goto_706_12.ovector[0] as *mut c_ulong) as *const c_void) as *i8, (((i__goto_727_10 -% 2)) *% sizeof[c_ulong]()) as i64)
                            while ((i__goto_727_10 = i__goto_727_10 - 1) >= (F__goto_706_12.offset_top +% 2)):
                                ((&match_data.ovector[0] as *mut c_ulong)[i__goto_727_10] = ((0 - (0 as c_ulong) - 1)))
                                if __goto_pending != 0:
                                    break
                            return 1
                        OP_END =>
                            if ((F__goto_706_12.eptr == F__goto_706_12.start_match) and ((((mb.moptions & 4)) != 0) or ((((mb.moptions & 8)) != 0) and (F__goto_706_12.start_match == (mb.start_subject + mb.start_offset))))):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.eptr < mb.end_subject) and (((((mb.moptions | mb.poptions)) & 536870912)) != 0)):
                                if (F__goto_706_12.op == OP_END):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                return 0
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.start_match < (mb.start_subject + mb.start_offset)) or (F__goto_706_12.start_match > F__goto_706_12.eptr)):
                                if (not ((mb.allowlookaroundbsk != 0))):
                                    return (-75)
                                if __goto_pending != 0:
                                    break
                            (mb.end_match_ptr = F__goto_706_12.eptr)
                            (mb.end_offset_top = F__goto_706_12.offset_top)
                            (mb.mark = F__goto_706_12.mark)
                            if (F__goto_706_12.eptr > mb.last_used_ptr):
                                (mb.last_used_ptr = F__goto_706_12.eptr)
                            ((&match_data.ovector[0] as *mut c_ulong)[0] = ((F__goto_706_12.start_match as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            ((&match_data.ovector[0] as *mut c_ulong)[1] = ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (i__goto_727_10 = (2 * ((if ((top_bracket + 1) > match_data.oveccount): match_data.oveccount else: (top_bracket + 1)))))
                            with_memcpy((((&match_data.ovector[0] as *mut c_ulong) + (2 as isize as usize)) as *mut c_void) as *i8, ((&F__goto_706_12.ovector[0] as *mut c_ulong) as *const c_void) as *i8, (((i__goto_727_10 -% 2)) *% sizeof[c_ulong]()) as i64)
                            while ((i__goto_727_10 = i__goto_727_10 - 1) >= (F__goto_706_12.offset_top +% 2)):
                                ((&match_data.ovector[0] as *mut c_ulong)[i__goto_727_10] = ((0 - (0 as c_ulong) - 1)))
                                if __goto_pending != 0:
                                    break
                            return 1
                        OP_ANY =>
                            if ((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) < mb.end_subject) and (_pcre2_is_newline_8((F__goto_706_12.eptr), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) <= (mb.end_subject - mb.nllen)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (F__goto_706_12.eptr[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if (((((mb.partial != 0) and (F__goto_706_12.eptr == (mb.end_subject - (1 as isize as usize)))) and (mb.nltype == 0)) and (mb.nllen == 2)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])):
                                (mb.hitend = 1)
                                if __goto_pending != 0:
                                    break
                                if (mb.partial > 1):
                                    return (-2)
                                if __goto_pending != 0:
                                    break
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_ALLANY =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_ANYBYTE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_CHAR =>
                            if (((mb.end_subject as usize -% F__goto_706_12.eptr as usize) / sizeof[u8]()) < 1):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
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
                            if (F__goto_706_12.ecode[1] != (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + 2
                            if __goto_pending != 0:
                                break
                        OP_CHARI =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            if (((mb.lcc)[F__goto_706_12.ecode[1]]) != ((mb.lcc)[(unsafe: *F__goto_706_12.eptr)])):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            if __goto_pending != 0:
                                break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + 2
                            if __goto_pending != 0:
                                break
                        OP_NOT =>
                            ch__goto_1298_16 = F__goto_706_12.ecode[1]
                            if __goto_pending != 0:
                                break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            if __goto_pending != 0:
                                break
                            if ((ch__goto_1298_16 == fc__goto_728_10) or ((F__goto_706_12.op == OP_NOTI) and (((mb.fcc)[ch__goto_1298_16]) == fc__goto_728_10))):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + 2
                            if __goto_pending != 0:
                                break
                        OP_EXACT =>
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 3
                            __goto_pending = 1
                        OP_POSUPTO =>
                            (F__goto_706_12.fields.char_repeat.min = 0)
                            (F__goto_706_12.fields.char_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 3
                            __goto_pending = 1
                        OP_UPTO =>
                            (F__goto_706_12.fields.char_repeat.min = 0)
                            (F__goto_706_12.fields.char_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 3
                            __goto_pending = 1
                        OP_MINUPTO =>
                            (F__goto_706_12.fields.char_repeat.min = 0)
                            (F__goto_706_12.fields.char_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 3
                            __goto_pending = 1
                        OP_POSSTAR =>
                            (F__goto_706_12.fields.char_repeat.min = 0)
                            (F__goto_706_12.fields.char_repeat.max = (4294967295 as c_uint))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 3
                            __goto_pending = 1
                        OP_POSPLUS =>
                            (F__goto_706_12.fields.char_repeat.min = 1)
                            (F__goto_706_12.fields.char_repeat.max = (4294967295 as c_uint))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 3
                            __goto_pending = 1
                        OP_POSQUERY =>
                            (F__goto_706_12.fields.char_repeat.min = 0)
                            (F__goto_706_12.fields.char_repeat.max = 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 3
                            __goto_pending = 1
                        OP_STAR =>
                            (F__goto_706_12.fields.char_repeat.min = (&rep_min[0] as *mut c_uint)[fc__goto_728_10])
                            (F__goto_706_12.fields.char_repeat.max = (&rep_max[0] as *mut c_uint)[fc__goto_728_10])
                            (reptype__goto_730_10 = (&rep_typ[0] as *mut c_uint)[fc__goto_728_10])
                            (F__goto_706_12.fields.char_repeat.c = (unsafe: *F__goto_706_12.ecode))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            if (F__goto_706_12.op >= OP_STARI):
                                (F__goto_706_12.fields.char_repeat.oc.oc = mb.fcc[F__goto_706_12.fields.char_repeat.c])
                                if __goto_pending != 0:
                                    break
                                (i__goto_727_10 = 1)
                                while (i__goto_727_10 <= F__goto_706_12.fields.char_repeat.min):
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    (cc__goto_1536_18 = (unsafe: *F__goto_706_12.eptr))
                                    if __goto_pending != 0:
                                        break
                                    if ((F__goto_706_12.fields.char_repeat.c != cc__goto_1536_18) and (F__goto_706_12.fields.char_repeat.oc.oc != cc__goto_1536_18)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = i__goto_727_10 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (F__goto_706_12.fields.char_repeat.min == F__goto_706_12.fields.char_repeat.max):
                                    continue
                                if __goto_pending != 0:
                                    break
                                if (reptype__goto_730_10 == 0):
                                    while true:
                                        while true:
                                            (start_ecode = F__goto_706_12.ecode)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 25)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rrc__goto_722_5 != 0):
                                            while true:
                                                (rrc__goto_722_5 = rrc__goto_722_5)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.char_repeat.min = F__goto_706_12.fields.char_repeat.min + 1) >= F__goto_706_12.fields.char_repeat.max):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
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
                                        (cc__goto_1552_20 = (unsafe: *F__goto_706_12.eptr))
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.char_repeat.c != cc__goto_1552_20) and (F__goto_706_12.fields.char_repeat.oc.oc != cc__goto_1552_20)):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    (F__goto_706_12.fields.char_repeat.start_eptr = F__goto_706_12.eptr)
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = F__goto_706_12.fields.char_repeat.min)
                                    while (i__goto_727_10 < F__goto_706_12.fields.char_repeat.max):
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (cc__goto_1573_20 = (unsafe: *F__goto_706_12.eptr))
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.char_repeat.c != cc__goto_1573_20) and (F__goto_706_12.fields.char_repeat.oc.oc != cc__goto_1573_20)):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_727_10 = i__goto_727_10 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (reptype__goto_730_10 != 2):
                                        while true:
                                            if (F__goto_706_12.eptr == F__goto_706_12.fields.char_repeat.start_eptr):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            while true:
                                                (start_ecode = F__goto_706_12.ecode)
                                                if __goto_pending != 0:
                                                    break
                                                (F__goto_706_12.return_id = 26)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                0
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr - 1)
                                            if __goto_pending != 0:
                                                break
                                            if (rrc__goto_722_5 != 0):
                                                while true:
                                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                            else:
                                (i__goto_727_10 = 1)
                                while (i__goto_727_10 <= F__goto_706_12.fields.char_repeat.min):
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    if (F__goto_706_12.fields.char_repeat.c != (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = i__goto_727_10 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (F__goto_706_12.fields.char_repeat.min == F__goto_706_12.fields.char_repeat.max):
                                    continue
                                if __goto_pending != 0:
                                    break
                                if (reptype__goto_730_10 == 0):
                                    while true:
                                        while true:
                                            (start_ecode = F__goto_706_12.ecode)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 27)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rrc__goto_722_5 != 0):
                                            while true:
                                                (rrc__goto_722_5 = rrc__goto_722_5)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.char_repeat.min = F__goto_706_12.fields.char_repeat.min + 1) >= F__goto_706_12.fields.char_repeat.max):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
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
                                        if (F__goto_706_12.fields.char_repeat.c != (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
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
                                else:
                                    (F__goto_706_12.fields.char_repeat.start_eptr = F__goto_706_12.eptr)
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = F__goto_706_12.fields.char_repeat.min)
                                    while (i__goto_727_10 < F__goto_706_12.fields.char_repeat.max):
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.fields.char_repeat.c != (unsafe: *F__goto_706_12.eptr)):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_727_10 = i__goto_727_10 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (reptype__goto_730_10 != 2):
                                        while true:
                                            if (F__goto_706_12.eptr <= F__goto_706_12.fields.char_repeat.start_eptr):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            while true:
                                                (start_ecode = F__goto_706_12.ecode)
                                                if __goto_pending != 0:
                                                    break
                                                (F__goto_706_12.return_id = 28)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                0
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr - 1)
                                            if __goto_pending != 0:
                                                break
                                            if (rrc__goto_722_5 != 0):
                                                while true:
                                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                        OP_NOTEXACT =>
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTUPTO =>
                            (F__goto_706_12.fields.charnot_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            (reptype__goto_730_10 = 1)
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTMINUPTO =>
                            (F__goto_706_12.fields.charnot_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            (reptype__goto_730_10 = 0)
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTPOSSTAR =>
                            (F__goto_706_12.fields.charnot_repeat.min = 0)
                            (F__goto_706_12.fields.charnot_repeat.max = (4294967295 as c_uint))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTPOSPLUS =>
                            (F__goto_706_12.fields.charnot_repeat.min = 1)
                            (F__goto_706_12.fields.charnot_repeat.max = (4294967295 as c_uint))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTPOSQUERY =>
                            (F__goto_706_12.fields.charnot_repeat.min = 0)
                            (F__goto_706_12.fields.charnot_repeat.max = 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTPOSUPTO =>
                            (F__goto_706_12.fields.charnot_repeat.min = 0)
                            (F__goto_706_12.fields.charnot_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 8
                            __goto_pending = 1
                        OP_NOTSTAR =>
                            (F__goto_706_12.fields.charnot_repeat.min = (&rep_min[0] as *mut c_uint)[fc__goto_728_10])
                            (F__goto_706_12.fields.charnot_repeat.max = (&rep_max[0] as *mut c_uint)[fc__goto_728_10])
                            (reptype__goto_730_10 = (&rep_typ[0] as *mut c_uint)[fc__goto_728_10])
                            (F__goto_706_12.fields.charnot_repeat.c = (unsafe: *F__goto_706_12.ecode))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            0
                            if (F__goto_706_12.op >= OP_NOTSTARI):
                                (F__goto_706_12.fields.charnot_repeat.oc = ((mb.fcc)[F__goto_706_12.fields.charnot_repeat.c]))
                                if __goto_pending != 0:
                                    break
                                (i__goto_727_10 = 1)
                                while (i__goto_727_10 <= F__goto_706_12.fields.charnot_repeat.min):
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    if ((F__goto_706_12.fields.charnot_repeat.c == (unsafe: *F__goto_706_12.eptr)) or (F__goto_706_12.fields.charnot_repeat.oc == (unsafe: *F__goto_706_12.eptr))):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = i__goto_727_10 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if (F__goto_706_12.fields.charnot_repeat.min == F__goto_706_12.fields.charnot_repeat.max):
                                    continue
                                if __goto_pending != 0:
                                    break
                                if (reptype__goto_730_10 == 0):
                                    while true:
                                        while true:
                                            (start_ecode = F__goto_706_12.ecode)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 29)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rrc__goto_722_5 != 0):
                                            while true:
                                                (rrc__goto_722_5 = rrc__goto_722_5)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.charnot_repeat.min = F__goto_706_12.fields.charnot_repeat.min + 1) >= F__goto_706_12.fields.charnot_repeat.max):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
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
                                        if ((F__goto_706_12.fields.charnot_repeat.c == (unsafe: *F__goto_706_12.eptr)) or (F__goto_706_12.fields.charnot_repeat.oc == (unsafe: *F__goto_706_12.eptr))):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    (F__goto_706_12.fields.charnot_repeat.start_eptr = F__goto_706_12.eptr)
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = F__goto_706_12.fields.charnot_repeat.min)
                                    while (i__goto_727_10 < F__goto_706_12.fields.charnot_repeat.max):
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.charnot_repeat.c == (unsafe: *F__goto_706_12.eptr)) or (F__goto_706_12.fields.charnot_repeat.oc == (unsafe: *F__goto_706_12.eptr))):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_727_10 = i__goto_727_10 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (reptype__goto_730_10 != 2):
                                        while true:
                                            if (F__goto_706_12.eptr == F__goto_706_12.fields.charnot_repeat.start_eptr):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            while true:
                                                (start_ecode = F__goto_706_12.ecode)
                                                if __goto_pending != 0:
                                                    break
                                                (F__goto_706_12.return_id = 30)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                0
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if (rrc__goto_722_5 != 0):
                                                while true:
                                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr - 1)
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
                                (i__goto_727_10 = 1)
                                while (i__goto_727_10 <= F__goto_706_12.fields.charnot_repeat.min):
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    if (F__goto_706_12.fields.charnot_repeat.c == (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = i__goto_727_10 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if (F__goto_706_12.fields.charnot_repeat.min == F__goto_706_12.fields.charnot_repeat.max):
                                    continue
                                if __goto_pending != 0:
                                    break
                                if (reptype__goto_730_10 == 0):
                                    while true:
                                        while true:
                                            (start_ecode = F__goto_706_12.ecode)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 31)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rrc__goto_722_5 != 0):
                                            while true:
                                                (rrc__goto_722_5 = rrc__goto_722_5)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if ((F__goto_706_12.fields.charnot_repeat.min = F__goto_706_12.fields.charnot_repeat.min + 1) >= F__goto_706_12.fields.charnot_repeat.max):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
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
                                        if (F__goto_706_12.fields.charnot_repeat.c == (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))):
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
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
                                else:
                                    (F__goto_706_12.fields.charnot_repeat.start_eptr = F__goto_706_12.eptr)
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = F__goto_706_12.fields.charnot_repeat.min)
                                    while (i__goto_727_10 < F__goto_706_12.fields.charnot_repeat.max):
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.fields.charnot_repeat.c == (unsafe: *F__goto_706_12.eptr)):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_727_10 = i__goto_727_10 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (reptype__goto_730_10 != 2):
                                        while true:
                                            if (F__goto_706_12.eptr == F__goto_706_12.fields.charnot_repeat.start_eptr):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            while true:
                                                (start_ecode = F__goto_706_12.ecode)
                                                if __goto_pending != 0:
                                                    break
                                                (F__goto_706_12.return_id = 32)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                0
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if (rrc__goto_722_5 != 0):
                                                while true:
                                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr - 1)
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
                        OP_NCLASS =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 8)) != 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_NOT_DIGIT =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 8)) != 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_DIGIT =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((not ((1 != 0))) or (((mb.ctypes[fc__goto_728_10] & 8)) == 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_NOT_WHITESPACE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 1)) != 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_WHITESPACE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((not ((1 != 0))) or (((mb.ctypes[fc__goto_728_10] & 1)) == 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_NOT_WORDCHAR =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 16)) != 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_WORDCHAR =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            if ((not ((1 != 0))) or (((mb.ctypes[fc__goto_728_10] & 16)) == 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_ANYNL =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            match fc__goto_728_10
                                13 =>
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        if ((unsafe: *F__goto_706_12.eptr) == 10):
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                10 => 0
                                11 => 0
                                _ =>
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        if ((unsafe: *F__goto_706_12.eptr) == 10):
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_NOT_HSPACE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            match fc__goto_728_10
                                9 => 0
                                _ => 0
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_HSPACE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            match fc__goto_728_10
                                9 =>
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                _ =>
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_NOT_VSPACE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            match fc__goto_728_10
                                10 => 0
                                _ => 0
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_VSPACE =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                            0
                            match fc__goto_728_10
                                10 =>
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                _ =>
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_TYPEEXACT =>
                            (F__goto_706_12.fields.type_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            (F__goto_706_12.fields.type_repeat.min = F__goto_706_12.fields.type_repeat.max)
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 15
                            __goto_pending = 1
                        OP_TYPEUPTO =>
                            (F__goto_706_12.fields.type_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            (reptype__goto_730_10 = (if ((unsafe: *F__goto_706_12.ecode) == OP_TYPEMINUPTO): REPTYPE_MIN else: REPTYPE_MAX))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 15
                            __goto_pending = 1
                        OP_TYPEPOSSTAR =>
                            (reptype__goto_730_10 = 2)
                            (F__goto_706_12.fields.type_repeat.min = 0)
                            (F__goto_706_12.fields.type_repeat.max = (4294967295 as c_uint))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 15
                            __goto_pending = 1
                        OP_TYPEPOSPLUS =>
                            (reptype__goto_730_10 = 2)
                            (F__goto_706_12.fields.type_repeat.min = 1)
                            (F__goto_706_12.fields.type_repeat.max = (4294967295 as c_uint))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 15
                            __goto_pending = 1
                        OP_TYPEPOSQUERY =>
                            (reptype__goto_730_10 = 2)
                            (F__goto_706_12.fields.type_repeat.min = 0)
                            (F__goto_706_12.fields.type_repeat.max = 1)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            __pc = 15
                            __goto_pending = 1
                        OP_TYPEPOSUPTO =>
                            (reptype__goto_730_10 = 2)
                            (F__goto_706_12.fields.type_repeat.min = 0)
                            (F__goto_706_12.fields.type_repeat.max = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            __pc = 15
                            __goto_pending = 1
                        OP_TYPESTAR =>
                            (F__goto_706_12.fields.type_repeat.min = (&rep_min[0] as *mut c_uint)[fc__goto_728_10])
                            (F__goto_706_12.fields.type_repeat.max = (&rep_max[0] as *mut c_uint)[fc__goto_728_10])
                            (reptype__goto_730_10 = (&rep_typ[0] as *mut c_uint)[fc__goto_728_10])
                            (F__goto_706_12.fields.type_repeat.ctype = (unsafe: *F__goto_706_12.ecode))
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            if (F__goto_706_12.fields.type_repeat.min > 0):
                                match F__goto_706_12.fields.type_repeat.ctype
                                    12 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) < mb.end_subject) and (_pcre2_is_newline_8((F__goto_706_12.eptr), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) <= (mb.end_subject - mb.nllen)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (F__goto_706_12.eptr[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            if (((((mb.partial != 0) and ((F__goto_706_12.eptr + (1 as isize as usize)) >= mb.end_subject)) and (mb.nltype == 0)) and (mb.nllen == 2)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    13 =>
                                        if (F__goto_706_12.eptr > (mb.end_subject - F__goto_706_12.fields.type_repeat.min)):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            while true:
                                                (rrc__goto_722_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        F__goto_706_12.eptr = F__goto_706_12.eptr + F__goto_706_12.fields.type_repeat.min
                                    17 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            match (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))
                                                13 =>
                                                    if ((F__goto_706_12.eptr < mb.end_subject) and ((unsafe: *F__goto_706_12.eptr) == 10)):
                                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                                10 => 0
                                                11 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                                    if ((F__goto_706_12.eptr < mb.end_subject) and ((unsafe: *F__goto_706_12.eptr) == 10)):
                                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    18 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            match (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))
                                                9 => 0
                                                _ => 0
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    19 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            match (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))
                                                9 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    20 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            match (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))
                                                10 => 0
                                                _ => 0
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    21 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            match (unsafe: *(F__goto_706_12.eptr = F__goto_706_12.eptr + 1))
                                                10 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    6 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) != 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    7 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((not ((1 != 0))) or (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) == 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    8 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 1)) != 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    9 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((not ((1 != 0))) or (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 1)) == 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    10 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 16)) != 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    11 =>
                                        (i__goto_727_10 = 1)
                                        while (i__goto_727_10 <= F__goto_706_12.fields.type_repeat.min):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
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
                                            if ((not ((1 != 0))) or (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 16)) == 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    _ =>
                                        return (-44)
                                if __goto_pending != 0:
                                    break
                            if (F__goto_706_12.fields.type_repeat.min == F__goto_706_12.fields.type_repeat.max):
                                continue
                            if (reptype__goto_730_10 == 0):
                                while true:
                                    while true:
                                        (start_ecode = F__goto_706_12.ecode)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 33)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        while true:
                                            (rrc__goto_722_5 = rrc__goto_722_5)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    if ((F__goto_706_12.fields.type_repeat.min = F__goto_706_12.fields.type_repeat.min + 1) >= F__goto_706_12.fields.type_repeat.max):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    if (F__goto_706_12.eptr >= mb.end_subject):
                                        while true:
                                            if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
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
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    if ((F__goto_706_12.fields.type_repeat.ctype == 12) and ((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) < mb.end_subject) and (_pcre2_is_newline_8((F__goto_706_12.eptr), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) <= (mb.end_subject - mb.nllen)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (F__goto_706_12.eptr[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                    if __goto_pending != 0:
                                        break
                                    match F__goto_706_12.fields.type_repeat.ctype
                                        12 =>
                                            if (((((mb.partial != 0) and (F__goto_706_12.eptr >= mb.end_subject)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (fc__goto_728_10 == (&mb.nl[0] as *mut u8)[0])):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
                                                if __goto_pending != 0:
                                                    break
                                        13 =>
                                            match fc__goto_728_10
                                                13 =>
                                                    if ((F__goto_706_12.eptr < mb.end_subject) and ((unsafe: *F__goto_706_12.eptr) == 10)):
                                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                                10 => 0
                                                11 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                                    if ((F__goto_706_12.eptr < mb.end_subject) and ((unsafe: *F__goto_706_12.eptr) == 10)):
                                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        17 =>
                                            match fc__goto_728_10
                                                13 =>
                                                    if ((F__goto_706_12.eptr < mb.end_subject) and ((unsafe: *F__goto_706_12.eptr) == 10)):
                                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                                10 => 0
                                                11 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                                    if ((F__goto_706_12.eptr < mb.end_subject) and ((unsafe: *F__goto_706_12.eptr) == 10)):
                                                        (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                        18 =>
                                            match fc__goto_728_10
                                                9 => 0
                                                _ => 0
                                        19 =>
                                            match fc__goto_728_10
                                                9 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                        20 =>
                                            match fc__goto_728_10
                                                10 => 0
                                                _ => 0
                                        21 =>
                                            match fc__goto_728_10
                                                10 => 0
                                                _ =>
                                                    while true:
                                                        (rrc__goto_722_5 = 0)
                                                        if __goto_pending != 0:
                                                            break
                                                        __pc = 57
                                                        __goto_pending = 1
                                                        if __goto_pending != 0:
                                                            break
                                                        if __goto_pending != 0:
                                                            break
                                                        if not ((0 != 0)):
                                                            break
                                        6 =>
                                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 8)) != 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        7 =>
                                            if ((not ((1 != 0))) or (((mb.ctypes[fc__goto_728_10] & 8)) == 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        8 =>
                                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 1)) != 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        9 =>
                                            if ((not ((1 != 0))) or (((mb.ctypes[fc__goto_728_10] & 1)) == 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        10 =>
                                            if ((1 != 0) and (((mb.ctypes[fc__goto_728_10] & 16)) != 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        11 =>
                                            if ((not ((1 != 0))) or (((mb.ctypes[fc__goto_728_10] & 16)) == 0)):
                                                while true:
                                                    (rrc__goto_722_5 = 0)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        _ =>
                                            return (-44)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                            else:
                                (F__goto_706_12.fields.type_repeat.start_eptr = F__goto_706_12.eptr)
                                if __goto_pending != 0:
                                    break
                                match F__goto_706_12.fields.type_repeat.ctype
                                    12 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) < mb.end_subject) and (_pcre2_is_newline_8((F__goto_706_12.eptr), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) <= (mb.end_subject - mb.nllen)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (F__goto_706_12.eptr[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if (((((mb.partial != 0) and ((F__goto_706_12.eptr + (1 as isize as usize)) >= mb.end_subject)) and (mb.nltype == 0)) and (mb.nllen == 2)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])):
                                                (mb.hitend = 1)
                                                if __goto_pending != 0:
                                                    break
                                                if (mb.partial > 1):
                                                    return (-2)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    13 =>
                                        if (fc__goto_728_10 > ((((mb.end_subject as usize -% F__goto_706_12.eptr as usize) / sizeof[u8]())) as c_uint)):
                                            (F__goto_706_12.eptr = mb.end_subject)
                                            if __goto_pending != 0:
                                                break
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                            F__goto_706_12.eptr = F__goto_706_12.eptr + fc__goto_728_10
                                    17 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                                            if __goto_pending != 0:
                                                break
                                            if (fc__goto_728_10 == 13):
                                                if ((F__goto_706_12.eptr = F__goto_706_12.eptr + 1) >= mb.end_subject):
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if ((unsafe: *F__goto_706_12.eptr) == 10):
                                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if ((fc__goto_728_10 != 10) and ((mb.bsr_convention == 2) or (((fc__goto_728_10 != 11) and (fc__goto_728_10 != 12)) and (fc__goto_728_10 != 133)))):
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    18 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                9 => 0
                                                _ =>
                                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                9 => 0
                                                _ =>
                                                    __pc = 18
                                                    __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    __pc = 20
                                                    __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    19 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                9 => 0
                                                _ =>
                                                    __pc = 18
                                                    __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    __pc = 20
                                                    __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    20 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    __pc = 20
                                                    __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    21 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            match (unsafe: *F__goto_706_12.eptr)
                                                10 => 0
                                                _ =>
                                                    __pc = 20
                                                    __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                        break
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    6 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    7 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((not ((1 != 0))) or (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 8)) == 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    8 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 1)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    9 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((not ((1 != 0))) or (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 1)) == 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    10 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((1 != 0) and (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 16)) != 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    11 =>
                                        (i__goto_727_10 = F__goto_706_12.fields.type_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.type_repeat.max):
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                                break
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((not ((1 != 0))) or (((mb.ctypes[(unsafe: *F__goto_706_12.eptr)] & 16)) == 0)):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
                                            if __goto_pending != 0:
                                                break
                                    _ =>
                                        return (-44)
                                if __goto_pending != 0:
                                    break
                                if (reptype__goto_730_10 == 2):
                                    continue
                                if __goto_pending != 0:
                                    break
                                while true:
                                    if (F__goto_706_12.eptr == F__goto_706_12.fields.type_repeat.start_eptr):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (start_ecode = F__goto_706_12.ecode)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 34)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        while true:
                                            (rrc__goto_722_5 = rrc__goto_722_5)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.eptr = F__goto_706_12.eptr - 1)
                                    if __goto_pending != 0:
                                        break
                                    if ((((F__goto_706_12.fields.type_repeat.ctype == 17) and (F__goto_706_12.eptr > F__goto_706_12.fields.type_repeat.start_eptr)) and ((unsafe: *F__goto_706_12.eptr) == 10)) and (F__goto_706_12.eptr[-1] == 13)):
                                        (F__goto_706_12.eptr = F__goto_706_12.eptr - 1)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                        OP_DNREF =>
                            (F__goto_706_12.byte2 = (((if (F__goto_706_12.op == OP_DNREFI): F__goto_706_12.ecode[(1 + (2 * 2))] else: 0)) as u8))
                            count__goto_5270_11 = ((((((((F__goto_706_12.ecode)[(1 + 2)] as c_uint) << 8))) | (F__goto_706_12.ecode)[(((1 + 2)) + 1)])) as c_uint)
                            if __goto_pending != 0:
                                break
                            slot__goto_5271_18 = (mb.name_table + (((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint) *% mb.name_entry_size))
                            if __goto_pending != 0:
                                break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + ((1 + (2 * 2)) + ((if (F__goto_706_12.op == OP_DNREFI): 1 else: 0)))
                            if __goto_pending != 0:
                                break
                            while ((count__goto_5270_11 = count__goto_5270_11 - 1) > 0):
                                (F__goto_706_12.fields.ref_repeat.offset = (((((((((((slot__goto_5271_18)[0] as c_uint) << 8))) | (slot__goto_5271_18)[((0) + 1)])) as c_uint) << 1)) -% 2))
                                if __goto_pending != 0:
                                    break
                                if ((F__goto_706_12.fields.ref_repeat.offset < F__goto_706_12.offset_top) and ((&F__goto_706_12.ovector[0] as *mut c_ulong)[F__goto_706_12.fields.ref_repeat.offset] != ((0 - (0 as c_ulong) - 1)))):
                                    break
                                if __goto_pending != 0:
                                    break
                                slot__goto_5271_18 = slot__goto_5271_18 + mb.name_entry_size
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            __pc = 22
                            __goto_pending = 1
                        OP_REF =>
                            (F__goto_706_12.byte2 = (if (F__goto_706_12.op == OP_REFI): F__goto_706_12.ecode[(1 + 2)] else: 0))
                            (F__goto_706_12.fields.ref_repeat.offset = (((((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint) << 1)) -% 2))
                            F__goto_706_12.ecode = F__goto_706_12.ecode + ((1 + 2) + ((if (F__goto_706_12.op == OP_REFI): 1 else: 0)))
                            match (unsafe: *F__goto_706_12.ecode)
                                OP_CRSTAR =>
                                    (F__goto_706_12.fields.ref_repeat.min = (&rep_min[0] as *mut c_uint)[fc__goto_728_10])
                                    (F__goto_706_12.fields.ref_repeat.max = (&rep_max[0] as *mut c_uint)[fc__goto_728_10])
                                    (reptype__goto_730_10 = (&rep_typ[0] as *mut c_uint)[fc__goto_728_10])
                                OP_CRRANGE =>
                                    (F__goto_706_12.fields.ref_repeat.max = ((((((((F__goto_706_12.ecode)[(1 + 2)] as c_uint) << 8))) | (F__goto_706_12.ecode)[(((1 + 2)) + 1)])) as c_uint))
                                    (reptype__goto_730_10 = (&rep_typ[0] as *mut c_uint)[((unsafe: *F__goto_706_12.ecode) - OP_CRSTAR)])
                                    if (F__goto_706_12.fields.ref_repeat.max == 0):
                                        (F__goto_706_12.fields.ref_repeat.max = (4294967295 as c_uint))
                                    F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + (2 * 2))
                                _ =>
                                    (rrc__goto_722_5 = match_ref(F__goto_706_12.fields.ref_repeat.offset, F__goto_706_12.byte1, F__goto_706_12.byte2, F__goto_706_12, mb, ((&length__goto_720_12 as *const c_ulong) as *mut c_ulong)))
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        if (rrc__goto_722_5 > 0):
                                            (F__goto_706_12.eptr = mb.end_subject)
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    F__goto_706_12.eptr = F__goto_706_12.eptr + length__goto_720_12
                                    continue
                            if ((F__goto_706_12.fields.ref_repeat.offset < F__goto_706_12.offset_top) and ((&F__goto_706_12.ovector[0] as *mut c_ulong)[F__goto_706_12.fields.ref_repeat.offset] != ((0 - (0 as c_ulong) - 1)))):
                                if ((&F__goto_706_12.ovector[0] as *mut c_ulong)[F__goto_706_12.fields.ref_repeat.offset] == (&F__goto_706_12.ovector[0] as *mut c_ulong)[(F__goto_706_12.fields.ref_repeat.offset +% 1)]):
                                    continue
                                if __goto_pending != 0:
                                    break
                            else:
                                if ((F__goto_706_12.fields.ref_repeat.min == 0) or (((mb.poptions & 512)) != 0)):
                                    continue
                                if __goto_pending != 0:
                                    break
                            (i__goto_727_10 = 1)
                            while (i__goto_727_10 <= F__goto_706_12.fields.ref_repeat.min):
                                (rrc__goto_722_5 = match_ref(F__goto_706_12.fields.ref_repeat.offset, F__goto_706_12.byte1, F__goto_706_12.byte2, F__goto_706_12, mb, ((&slength__goto_5357_18 as *const c_ulong) as *mut c_ulong)))
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    if (rrc__goto_722_5 > 0):
                                        (F__goto_706_12.eptr = mb.end_subject)
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        if (F__goto_706_12.eptr >= mb.end_subject):
                                            while true:
                                                if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                    (mb.hitend = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if (mb.partial > 1):
                                                        return (-2)
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
                                        if not ((0 != 0)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                F__goto_706_12.eptr = F__goto_706_12.eptr + slength__goto_5357_18
                                if __goto_pending != 0:
                                    break
                                (i__goto_727_10 = i__goto_727_10 + 1)
                                if __goto_pending != 0:
                                    break
                            if (F__goto_706_12.fields.ref_repeat.min == F__goto_706_12.fields.ref_repeat.max):
                                continue
                            if (reptype__goto_730_10 == 0):
                                while true:
                                    while true:
                                        (start_ecode = F__goto_706_12.ecode)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 20)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        while true:
                                            (rrc__goto_722_5 = rrc__goto_722_5)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    if ((F__goto_706_12.fields.ref_repeat.min = F__goto_706_12.fields.ref_repeat.min + 1) >= F__goto_706_12.fields.ref_repeat.max):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    (rrc__goto_722_5 = match_ref(F__goto_706_12.fields.ref_repeat.offset, F__goto_706_12.byte1, F__goto_706_12.byte2, F__goto_706_12, mb, ((&slength__goto_5378_20 as *const c_ulong) as *mut c_ulong)))
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        if (rrc__goto_722_5 > 0):
                                            (F__goto_706_12.eptr = mb.end_subject)
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            if (F__goto_706_12.eptr >= mb.end_subject):
                                                while true:
                                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                                        (mb.hitend = 1)
                                                        if __goto_pending != 0:
                                                            break
                                                        if (mb.partial > 1):
                                                            return (-2)
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
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                    F__goto_706_12.eptr = F__goto_706_12.eptr + slength__goto_5378_20
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            else:
                                samelengths__goto_5400_12 = 1
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.fields.ref_repeat.start = F__goto_706_12.eptr)
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.fields.ref_repeat.length = ((&F__goto_706_12.ovector[0] as *mut c_ulong)[(F__goto_706_12.fields.ref_repeat.offset +% 1)] -% (&F__goto_706_12.ovector[0] as *mut c_ulong)[F__goto_706_12.fields.ref_repeat.offset]))
                                if __goto_pending != 0:
                                    break
                                (i__goto_727_10 = F__goto_706_12.fields.ref_repeat.min)
                                while (i__goto_727_10 < F__goto_706_12.fields.ref_repeat.max):
                                    (rrc__goto_722_5 = match_ref(F__goto_706_12.fields.ref_repeat.offset, F__goto_706_12.byte1, F__goto_706_12.byte2, F__goto_706_12, mb, ((&slength__goto_5406_20 as *const c_ulong) as *mut c_ulong)))
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        if (((rrc__goto_722_5 > 0) and (mb.partial != 0)) and (mb.end_subject > mb.start_used_ptr)):
                                            (mb.hitend = 1)
                                            if __goto_pending != 0:
                                                break
                                            if (mb.partial > 1):
                                                return (-2)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (slength__goto_5406_20 != F__goto_706_12.fields.ref_repeat.length):
                                        (samelengths__goto_5400_12 = 0)
                                    if __goto_pending != 0:
                                        break
                                    F__goto_706_12.eptr = F__goto_706_12.eptr + slength__goto_5406_20
                                    if __goto_pending != 0:
                                        break
                                    (i__goto_727_10 = i__goto_727_10 + 1)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (reptype__goto_730_10 == 2):
                                    break
                                if __goto_pending != 0:
                                    break
                                if (samelengths__goto_5400_12 != 0):
                                    while (F__goto_706_12.eptr >= F__goto_706_12.fields.ref_repeat.start):
                                        while true:
                                            (start_ecode = F__goto_706_12.ecode)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 21)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rrc__goto_722_5 != 0):
                                            while true:
                                                (rrc__goto_722_5 = rrc__goto_722_5)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        F__goto_706_12.eptr = F__goto_706_12.eptr - F__goto_706_12.fields.ref_repeat.length
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    (F__goto_706_12.fields.ref_repeat.max = i__goto_727_10)
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        while true:
                                            (start_ecode = F__goto_706_12.ecode)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 22)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if (rrc__goto_722_5 != 0):
                                            while true:
                                                (rrc__goto_722_5 = rrc__goto_722_5)
                                                if __goto_pending != 0:
                                                    break
                                                __pc = 57
                                                __goto_pending = 1
                                                if __goto_pending != 0:
                                                    break
                                                if __goto_pending != 0:
                                                    break
                                                if not ((0 != 0)):
                                                    break
                                        if __goto_pending != 0:
                                            break
                                        if (F__goto_706_12.eptr == F__goto_706_12.fields.ref_repeat.start):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.eptr = F__goto_706_12.fields.ref_repeat.start)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.fields.ref_repeat.max = F__goto_706_12.fields.ref_repeat.max - 1)
                                        if __goto_pending != 0:
                                            break
                                        (i__goto_727_10 = F__goto_706_12.fields.ref_repeat.min)
                                        while (i__goto_727_10 < F__goto_706_12.fields.ref_repeat.max):
                                            match_ref(F__goto_706_12.fields.ref_repeat.offset, F__goto_706_12.byte1, F__goto_706_12.byte2, F__goto_706_12, mb, ((&slength__goto_5460_24 as *const c_ulong) as *mut c_ulong))
                                            if __goto_pending != 0:
                                                break
                                            F__goto_706_12.eptr = F__goto_706_12.eptr + slength__goto_5460_24
                                            if __goto_pending != 0:
                                                break
                                            (i__goto_727_10 = i__goto_727_10 + 1)
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
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            if __goto_pending != 0:
                                break
                            while true:
                                (start_ecode = F__goto_706_12.ecode)
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 9)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if __goto_pending != 0:
                                break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            (next_ecode__goto_5507_18 = F__goto_706_12.ecode)
                            if __goto_pending != 0:
                                break
                            while true:
                                next_ecode__goto_5507_18 = next_ecode__goto_5507_18 + ((((((((next_ecode__goto_5507_18)[1] as c_uint) << 8))) | (next_ecode__goto_5507_18)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *next_ecode__goto_5507_18) == OP_ALT)):
                                    break
                            if __goto_pending != 0:
                                break
                            (F__goto_706_12.ecode = ((next_ecode__goto_5507_18 + (1 as isize as usize)) + (2 as isize as usize)))
                            if __goto_pending != 0:
                                break
                        OP_BRAZERO =>
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            if __goto_pending != 0:
                                break
                            while true:
                                (start_ecode = F__goto_706_12.ecode)
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 9)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if __goto_pending != 0:
                                break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            (next_ecode__goto_5507_18 = F__goto_706_12.ecode)
                            if __goto_pending != 0:
                                break
                            while true:
                                next_ecode__goto_5507_18 = next_ecode__goto_5507_18 + ((((((((next_ecode__goto_5507_18)[1] as c_uint) << 8))) | (next_ecode__goto_5507_18)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *next_ecode__goto_5507_18) == OP_ALT)):
                                    break
                            if __goto_pending != 0:
                                break
                            (F__goto_706_12.ecode = ((next_ecode__goto_5507_18 + (1 as isize as usize)) + (2 as isize as usize)))
                            if __goto_pending != 0:
                                break
                        OP_BRAMINZERO =>
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                            if __goto_pending != 0:
                                break
                            (next_ecode__goto_5520_18 = F__goto_706_12.ecode)
                            if __goto_pending != 0:
                                break
                            while true:
                                next_ecode__goto_5520_18 = next_ecode__goto_5520_18 + ((((((((next_ecode__goto_5520_18)[1] as c_uint) << 8))) | (next_ecode__goto_5520_18)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *next_ecode__goto_5520_18) == OP_ALT)):
                                    break
                            if __goto_pending != 0:
                                break
                            while true:
                                (start_ecode = ((next_ecode__goto_5520_18 + (1 as isize as usize)) + (2 as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 10)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if __goto_pending != 0:
                                break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                        OP_SKIPZERO =>
                            next_ecode__goto_5532_18 = (F__goto_706_12.ecode + (1 as isize as usize))
                            if __goto_pending != 0:
                                break
                            while true:
                                next_ecode__goto_5532_18 = next_ecode__goto_5532_18 + ((((((((next_ecode__goto_5532_18)[1] as c_uint) << 8))) | (next_ecode__goto_5532_18)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *next_ecode__goto_5532_18) == OP_ALT)):
                                    break
                            if __goto_pending != 0:
                                break
                            (F__goto_706_12.ecode = ((next_ecode__goto_5532_18 + (1 as isize as usize)) + (2 as isize as usize)))
                            if __goto_pending != 0:
                                break
                        OP_BRAPOSZERO =>
                            (F__goto_706_12.byte2 = 1)
                            F__goto_706_12.ecode = F__goto_706_12.ecode + 1
                            if (((unsafe: *F__goto_706_12.ecode) == OP_CBRAPOS) or ((unsafe: *F__goto_706_12.ecode) == OP_SCBRAPOS)):
                                __pc = 29
                                __goto_pending = 1
                            __pc = 28
                            __goto_pending = 1
                        OP_BRAPOS =>
                            (F__goto_706_12.fields.op_brapos.frame_type = 131072)
                            __pc = 30
                            __goto_pending = 1
                        OP_CBRAPOS =>
                            (number__goto_729_10 = ((((((((F__goto_706_12.ecode)[(1 + 2)] as c_uint) << 8))) | (F__goto_706_12.ecode)[(((1 + 2)) + 1)])) as c_uint))
                            (F__goto_706_12.fields.op_brapos.frame_type = (65536 | number__goto_729_10))
                            (F__goto_706_12.byte1 = 0)
                            (F__goto_706_12.fields.op_brapos.start_group = F__goto_706_12.ecode)
                            while true:
                                (F__goto_706_12.fields.op_brapos.start_eptr = F__goto_706_12.eptr)
                                if __goto_pending != 0:
                                    break
                                (group_frame_type__goto_731_10 = F__goto_706_12.fields.op_brapos.frame_type)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 8)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 == (-998)):
                                    (F__goto_706_12.byte1 = 1)
                                    if __goto_pending != 0:
                                        break
                                    if (F__goto_706_12.eptr == F__goto_706_12.fields.op_brapos.start_eptr):
                                        while true:
                                            F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.ecode = F__goto_706_12.fields.op_brapos.start_group)
                                    if __goto_pending != 0:
                                        break
                                    continue
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 == (-993)):
                                    next_ecode__goto_5599_20 = (F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if ((mb.verb_ecode_ptr < next_ecode__goto_5599_20) and (((unsafe: *F__goto_706_12.ecode) == OP_ALT) or ((unsafe: *next_ecode__goto_5599_20) == OP_ALT))):
                                        (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *F__goto_706_12.ecode) != OP_ALT):
                                    break
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.byte1 != 0) or (F__goto_706_12.byte2 != 0)):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (rrc__goto_722_5 = 0)
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if ((mb.hasthen != 0) or (F__goto_706_12.rdepth == 0)):
                                (F__goto_706_12.fields.op_bra.frame_type = 0)
                                if __goto_pending != 0:
                                    break
                                __pc = 33
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                            while true:
                                current_branch__goto_5647_18 = F__goto_706_12.ecode
                                if __goto_pending != 0:
                                    break
                                next_branch__goto_5648_18 = (current_branch__goto_5647_18 + ((((((((current_branch__goto_5647_18)[1] as c_uint) << 8))) | (current_branch__goto_5647_18)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *next_branch__goto_5648_18) != OP_ALT):
                                    break
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.ecode = next_branch__goto_5648_18)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = ((current_branch__goto_5647_18 + (1 as isize as usize)) + (2 as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 1)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_BRA =>
                            if ((mb.hasthen != 0) or (F__goto_706_12.rdepth == 0)):
                                (F__goto_706_12.fields.op_bra.frame_type = 0)
                                if __goto_pending != 0:
                                    break
                                __pc = 33
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                            while true:
                                current_branch__goto_5647_18 = F__goto_706_12.ecode
                                if __goto_pending != 0:
                                    break
                                next_branch__goto_5648_18 = (current_branch__goto_5647_18 + ((((((((current_branch__goto_5647_18)[1] as c_uint) << 8))) | (current_branch__goto_5647_18)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *next_branch__goto_5648_18) != OP_ALT):
                                    break
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.ecode = next_branch__goto_5648_18)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = ((current_branch__goto_5647_18 + (1 as isize as usize)) + (2 as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 1)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_CBRA =>
                            __pc = 33
                            __goto_pending = 1
                        OP_ONCE =>
                            while true:
                                (group_frame_type__goto_731_10 = F__goto_706_12.fields.op_bra.frame_type)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 2)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 == (-993)):
                                    next_ecode__goto_5699_20 = (F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                                    if __goto_pending != 0:
                                        break
                                    if ((mb.verb_ecode_ptr < next_ecode__goto_5699_20) and (((unsafe: *F__goto_706_12.ecode) == OP_ALT) or ((unsafe: *next_ecode__goto_5699_20) == OP_ALT))):
                                        (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *F__goto_706_12.ecode) != OP_ALT):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                            (bracode__goto_718_12 = (mb.start_code + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)))
                            (number__goto_729_10 = (if (bracode__goto_718_12 == mb.start_code): 0 else: ((((((((bracode__goto_718_12)[(1 + 2)] as c_uint) << 8))) | (bracode__goto_718_12)[(((1 + 2)) + 1)])) as c_uint)))
                            if (F__goto_706_12.current_recurse != 4294967295):
                                (offset__goto_719_12 = F__goto_706_12.last_group_offset)
                                if __goto_pending != 0:
                                    break
                                while (offset__goto_719_12 != ((0 - (0 as c_ulong) - 1))):
                                    (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + offset__goto_719_12)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    if (N__goto_707_12.group_frame_type == ((262144 | number__goto_729_10))):
                                        if (((F__goto_706_12.eptr == P__goto_708_12.eptr) and (mb.last_used_ptr == P__goto_708_12.recurse_last_used)) and (((mb.moptions & 262144)) == 0)):
                                            return (-52)
                                        if __goto_pending != 0:
                                            break
                                        break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (offset__goto_719_12 = P__goto_708_12.last_group_offset)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.recurse_last_used = mb.last_used_ptr)
                            (F__goto_706_12.fields.op_recurse.start_branch = bracode__goto_718_12)
                            (F__goto_706_12.fields.op_recurse.frame_type = (262144 | number__goto_729_10))
                            while true:
                                (group_frame_type__goto_731_10 = F__goto_706_12.fields.op_recurse.frame_type)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = (F__goto_706_12.fields.op_recurse.start_branch + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.fields.op_recurse.start_branch)] as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 11)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                (next_ecode__goto_5761_18 = (F__goto_706_12.fields.op_recurse.start_branch + ((((((((F__goto_706_12.fields.op_recurse.start_branch)[1] as c_uint) << 8))) | (F__goto_706_12.fields.op_recurse.start_branch)[((1) + 1)])) as c_uint)))
                                if __goto_pending != 0:
                                    break
                                if (((rrc__goto_722_5 >= (-997)) and (rrc__goto_722_5 <= (-993))) and (mb.verb_current_recurse == ((F__goto_706_12.fields.op_recurse.frame_type ^ 262144)))):
                                    if (((rrc__goto_722_5 == (-993)) and (mb.verb_ecode_ptr < next_ecode__goto_5761_18)) and (((unsafe: *F__goto_706_12.fields.op_recurse.start_branch) == OP_ALT) or ((unsafe: *next_ecode__goto_5761_18) == OP_ALT))):
                                        (rrc__goto_722_5 = 0)
                                    else:
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.fields.op_recurse.start_branch = next_ecode__goto_5761_18)
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *F__goto_706_12.fields.op_recurse.start_branch) != OP_ALT):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                            while true:
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                    break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_RECURSE =>
                            (bracode__goto_718_12 = (mb.start_code + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)))
                            (number__goto_729_10 = (if (bracode__goto_718_12 == mb.start_code): 0 else: ((((((((bracode__goto_718_12)[(1 + 2)] as c_uint) << 8))) | (bracode__goto_718_12)[(((1 + 2)) + 1)])) as c_uint)))
                            if (F__goto_706_12.current_recurse != 4294967295):
                                (offset__goto_719_12 = F__goto_706_12.last_group_offset)
                                if __goto_pending != 0:
                                    break
                                while (offset__goto_719_12 != ((0 - (0 as c_ulong) - 1))):
                                    (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + offset__goto_719_12)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                    if __goto_pending != 0:
                                        break
                                    if (N__goto_707_12.group_frame_type == ((262144 | number__goto_729_10))):
                                        if (((F__goto_706_12.eptr == P__goto_708_12.eptr) and (mb.last_used_ptr == P__goto_708_12.recurse_last_used)) and (((mb.moptions & 262144)) == 0)):
                                            return (-52)
                                        if __goto_pending != 0:
                                            break
                                        break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (offset__goto_719_12 = P__goto_708_12.last_group_offset)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.recurse_last_used = mb.last_used_ptr)
                            (F__goto_706_12.fields.op_recurse.start_branch = bracode__goto_718_12)
                            (F__goto_706_12.fields.op_recurse.frame_type = (262144 | number__goto_729_10))
                            while true:
                                (group_frame_type__goto_731_10 = F__goto_706_12.fields.op_recurse.frame_type)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = (F__goto_706_12.fields.op_recurse.start_branch + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.fields.op_recurse.start_branch)] as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 11)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                (next_ecode__goto_5761_18 = (F__goto_706_12.fields.op_recurse.start_branch + ((((((((F__goto_706_12.fields.op_recurse.start_branch)[1] as c_uint) << 8))) | (F__goto_706_12.fields.op_recurse.start_branch)[((1) + 1)])) as c_uint)))
                                if __goto_pending != 0:
                                    break
                                if (((rrc__goto_722_5 >= (-997)) and (rrc__goto_722_5 <= (-993))) and (mb.verb_current_recurse == ((F__goto_706_12.fields.op_recurse.frame_type ^ 262144)))):
                                    if (((rrc__goto_722_5 == (-993)) and (mb.verb_ecode_ptr < next_ecode__goto_5761_18)) and (((unsafe: *F__goto_706_12.fields.op_recurse.start_branch) == OP_ALT) or ((unsafe: *next_ecode__goto_5761_18) == OP_ALT))):
                                        (rrc__goto_722_5 = 0)
                                    else:
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
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
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.fields.op_recurse.start_branch = next_ecode__goto_5761_18)
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *F__goto_706_12.fields.op_recurse.start_branch) != OP_ALT):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                            while true:
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                    break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_ASSERT =>
                            while true:
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                    break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_ASSERT_NOT =>
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_ASSERT_SCS =>
                            (length__goto_720_12 = 0)
                            ecode__goto_5886_18 = ((F__goto_706_12.ecode + (1 as isize as usize)) + (2 as isize as usize))
                            if __goto_pending != 0:
                                break
                            (offset__goto_719_12 = 0)
                            if __goto_pending != 0:
                                break
                            offset__goto_719_12
                            if __goto_pending != 0:
                                break
                            while true:
                                if ((unsafe: *ecode__goto_5886_18) == OP_CREF):
                                    length__goto_720_12 = length__goto_720_12 + 3
                                    if __goto_pending != 0:
                                        break
                                    (offset__goto_719_12 = (((((((((((ecode__goto_5886_18)[1] as c_uint) << 8))) | (ecode__goto_5886_18)[((1) + 1)])) as c_uint) << 1)) -% 2))
                                    if __goto_pending != 0:
                                        break
                                    ecode__goto_5886_18 = ecode__goto_5886_18 + (1 + 2)
                                    if __goto_pending != 0:
                                        break
                                    if ((offset__goto_719_12 < F__goto_706_12.offset_top) and ((&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12] != ((0 - (0 as c_ulong) - 1)))):
                                        __pc = 39
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    continue
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *ecode__goto_5886_18) != OP_DNCREF):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                (count__goto_5887_11 = ((((((((ecode__goto_5886_18)[(1 + 2)] as c_uint) << 8))) | (ecode__goto_5886_18)[(((1 + 2)) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                (slot__goto_5888_18 = (mb.name_table + (((((((((ecode__goto_5886_18)[1] as c_uint) << 8))) | (ecode__goto_5886_18)[((1) + 1)])) as c_uint) *% mb.name_entry_size)))
                                if __goto_pending != 0:
                                    break
                                length__goto_720_12 = length__goto_720_12 + 5
                                if __goto_pending != 0:
                                    break
                                ecode__goto_5886_18 = ecode__goto_5886_18 + (1 + (2 * 2))
                                if __goto_pending != 0:
                                    break
                                while (count__goto_5887_11 > 0):
                                    (offset__goto_719_12 = (((((((((((slot__goto_5888_18)[0] as c_uint) << 8))) | (slot__goto_5888_18)[((0) + 1)])) as c_uint) << 1)) -% 2))
                                    if __goto_pending != 0:
                                        break
                                    if ((offset__goto_719_12 < F__goto_706_12.offset_top) and ((&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12] != ((0 - (0 as c_ulong) - 1)))):
                                        __pc = 39
                                        __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    slot__goto_5888_18 = slot__goto_5888_18 + mb.name_entry_size
                                    if __goto_pending != 0:
                                        break
                                    (count__goto_5887_11 = count__goto_5887_11 - 1)
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
                            while true:
                                if ((unsafe: *ecode__goto_5886_18) == OP_CREF):
                                    length__goto_720_12 = length__goto_720_12 + 3
                                    if __goto_pending != 0:
                                        break
                                    ecode__goto_5886_18 = ecode__goto_5886_18 + (1 + 2)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if ((unsafe: *ecode__goto_5886_18) == OP_DNCREF):
                                        length__goto_720_12 = length__goto_720_12 + 5
                                        if __goto_pending != 0:
                                            break
                                        ecode__goto_5886_18 = ecode__goto_5886_18 + (1 + (2 * 2))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        break
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            (F__goto_706_12.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                            (F__goto_706_12.fields.op_assert_scs.true_end_extra = ((mb.true_end_subject as usize -% mb.end_subject as usize) / sizeof[u8]()))
                            (F__goto_706_12.fields.op_assert_scs.saved_eptr = F__goto_706_12.eptr)
                            (F__goto_706_12.fields.op_assert_scs.saved_moptions = mb.moptions)
                            (F__goto_706_12.eptr = (mb.start_subject + (&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12]))
                            (mb.end_subject = (mb.start_subject + (&F__goto_706_12.ovector[0] as *mut c_ulong)[(offset__goto_719_12 +% 1)]))
                            (mb.true_end_subject = mb.end_subject)
                            mb.moptions = mb.moptions & (0 - 2 - 1)
                            while true:
                                (group_frame_type__goto_731_10 = 131072)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = (((F__goto_706_12.ecode + (1 as isize as usize)) + (2 as isize as usize)) + length__goto_720_12))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 38)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 == (-999)):
                                    with_memcpy(((&F__goto_706_12.ovector[0] as *mut c_ulong) as *mut c_void) as *i8, (((assert_accept_frame__goto_711_12 as *mut i8) + 120) as *const c_void) as *i8, (assert_accept_frame__goto_711_12.offset_top *% sizeof[c_ulong]()) as i64)
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.offset_top = assert_accept_frame__goto_711_12.offset_top)
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.mark = assert_accept_frame__goto_711_12.mark)
                                    if __goto_pending != 0:
                                        break
                                    (mb.end_subject = F__goto_706_12.fields.op_assert_scs.saved_end_subject)
                                    if __goto_pending != 0:
                                        break
                                    (mb.true_end_subject = (mb.end_subject + F__goto_706_12.fields.op_assert_scs.true_end_extra))
                                    if __goto_pending != 0:
                                        break
                                    (mb.moptions = F__goto_706_12.fields.op_assert_scs.saved_moptions)
                                    if __goto_pending != 0:
                                        break
                                    break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((rrc__goto_722_5 != 0) and (rrc__goto_722_5 != (-993))):
                                    (mb.end_subject = F__goto_706_12.fields.op_assert_scs.saved_end_subject)
                                    if __goto_pending != 0:
                                        break
                                    (mb.true_end_subject = (mb.end_subject + F__goto_706_12.fields.op_assert_scs.true_end_extra))
                                    if __goto_pending != 0:
                                        break
                                    (mb.moptions = F__goto_706_12.fields.op_assert_scs.saved_moptions)
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if ((unsafe: *F__goto_706_12.ecode) != OP_ALT):
                                    (mb.end_subject = F__goto_706_12.fields.op_assert_scs.saved_end_subject)
                                    if __goto_pending != 0:
                                        break
                                    (mb.true_end_subject = (mb.end_subject + F__goto_706_12.fields.op_assert_scs.true_end_extra))
                                    if __goto_pending != 0:
                                        break
                                    (mb.moptions = F__goto_706_12.fields.op_assert_scs.saved_moptions)
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                (length__goto_720_12 = 0)
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                            while true:
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                    break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            (F__goto_706_12.eptr = F__goto_706_12.fields.op_assert_scs.saved_eptr)
                        OP_CALLOUT =>
                            if (rrc__goto_722_5 > 0):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if (rrc__goto_722_5 < 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + length__goto_720_12
                        OP_COND =>
                            if (F__goto_706_12.ecode[F__goto_706_12.fields.op_cond.length] != OP_ALT):
                                F__goto_706_12.fields.op_cond.length = F__goto_706_12.fields.op_cond.length - 3
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                            if (((unsafe: *F__goto_706_12.ecode) == OP_CALLOUT) or ((unsafe: *F__goto_706_12.ecode) == OP_CALLOUT_STR)):
                                (rrc__goto_722_5 = do_callout(F__goto_706_12, mb, ((&length__goto_720_12 as *const c_ulong) as *mut c_ulong)))
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 > 0):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 < 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                F__goto_706_12.ecode = F__goto_706_12.ecode + length__goto_720_12
                                if __goto_pending != 0:
                                    break
                                F__goto_706_12.fields.op_cond.length = F__goto_706_12.fields.op_cond.length - length__goto_720_12
                                if __goto_pending != 0:
                                    break
                            (condition__goto_733_6 = 0)
                            match (unsafe: *F__goto_706_12.ecode)
                                OP_RREF =>
                                    if (F__goto_706_12.current_recurse != 4294967295):
                                        (number__goto_729_10 = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                                        if __goto_pending != 0:
                                            break
                                        (condition__goto_733_6 = ((if (number__goto_729_10 == 65535) or (number__goto_729_10 == F__goto_706_12.current_recurse): 1 else: 0)))
                                        if __goto_pending != 0:
                                            break
                                OP_DNRREF =>
                                    if (F__goto_706_12.current_recurse != 4294967295):
                                        count__goto_6071_13 = ((((((((F__goto_706_12.ecode)[(1 + 2)] as c_uint) << 8))) | (F__goto_706_12.ecode)[(((1 + 2)) + 1)])) as c_uint)
                                        if __goto_pending != 0:
                                            break
                                        slot__goto_6072_20 = (mb.name_table + (((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint) *% mb.name_entry_size))
                                        if __goto_pending != 0:
                                            break
                                        while ((count__goto_6071_13 = count__goto_6071_13 - 1) > 0):
                                            (number__goto_729_10 = ((((((((slot__goto_6072_20)[0] as c_uint) << 8))) | (slot__goto_6072_20)[((0) + 1)])) as c_uint))
                                            if __goto_pending != 0:
                                                break
                                            (condition__goto_733_6 = (if number__goto_729_10 == F__goto_706_12.current_recurse: 1 else: 0))
                                            if __goto_pending != 0:
                                                break
                                            if (condition__goto_733_6 != 0):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            slot__goto_6072_20 = slot__goto_6072_20 + mb.name_entry_size
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                OP_CREF =>
                                    (offset__goto_719_12 = (((((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint) << 1)) -% 2))
                                    (condition__goto_733_6 = (if (offset__goto_719_12 < F__goto_706_12.offset_top) and ((&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12] != ((0 - (0 as c_ulong) - 1))): 1 else: 0))
                                OP_DNCREF =>
                                    count__goto_6090_13 = ((((((((F__goto_706_12.ecode)[(1 + 2)] as c_uint) << 8))) | (F__goto_706_12.ecode)[(((1 + 2)) + 1)])) as c_uint)
                                    if __goto_pending != 0:
                                        break
                                    slot__goto_6091_20 = (mb.name_table + (((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint) *% mb.name_entry_size))
                                    if __goto_pending != 0:
                                        break
                                    while ((count__goto_6090_13 = count__goto_6090_13 - 1) > 0):
                                        (offset__goto_719_12 = (((((((((((slot__goto_6091_20)[0] as c_uint) << 8))) | (slot__goto_6091_20)[((0) + 1)])) as c_uint) << 1)) -% 2))
                                        if __goto_pending != 0:
                                            break
                                        (condition__goto_733_6 = (if (offset__goto_719_12 < F__goto_706_12.offset_top) and ((&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12] != ((0 - (0 as c_ulong) - 1))): 1 else: 0))
                                        if __goto_pending != 0:
                                            break
                                        if (condition__goto_733_6 != 0):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        slot__goto_6091_20 = slot__goto_6091_20 + mb.name_entry_size
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                OP_FALSE =>
                                    (condition__goto_733_6 = 1)
                                OP_TRUE =>
                                    (condition__goto_733_6 = 1)
                                _ =>
                                    (F__goto_706_12.byte1 = (((if ((unsafe: *F__goto_706_12.ecode) == OP_ASSERT) or ((unsafe: *F__goto_706_12.ecode) == OP_ASSERTBACK): 1 else: 0)) as u8))
                                    (F__goto_706_12.fields.op_cond.start_branch = F__goto_706_12.ecode)
                                    while true:
                                        (group_frame_type__goto_731_10 = 196608)
                                        if __goto_pending != 0:
                                            break
                                        while true:
                                            (start_ecode = (F__goto_706_12.fields.op_cond.start_branch + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.fields.op_cond.start_branch)] as isize as usize)))
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.return_id = 5)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 1
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            0
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                        if __goto_pending != 0:
                                            break
                                        match rrc__goto_722_5
                                            (-999) =>
                                                with_memcpy(((&F__goto_706_12.ovector[0] as *mut c_ulong) as *mut c_void) as *i8, (((assert_accept_frame__goto_711_12 as *mut i8) + 120) as *const c_void) as *i8, (assert_accept_frame__goto_711_12.offset_top *% sizeof[c_ulong]()) as i64)
                                                (F__goto_706_12.offset_top = assert_accept_frame__goto_711_12.offset_top)
                                                (condition__goto_733_6 = F__goto_706_12.byte1)
                                            1 =>
                                                (condition__goto_733_6 = F__goto_706_12.byte1)
                                            0 =>
                                                if ((unsafe: *F__goto_706_12.fields.op_cond.start_branch) == OP_ALT):
                                                    continue
                                                (condition__goto_733_6 = (if F__goto_706_12.byte1 != 0: 0 else: 1))
                                            (-997) => 0
                                            _ =>
                                                while true:
                                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                                    if __goto_pending != 0:
                                                        break
                                                    __pc = 57
                                                    __goto_pending = 1
                                                    if __goto_pending != 0:
                                                        break
                                                    if __goto_pending != 0:
                                                        break
                                                    if not ((0 != 0)):
                                                        break
                                        if __goto_pending != 0:
                                            break
                                        break
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                    if (condition__goto_733_6 != 0):
                                        while true:
                                            F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                            if __goto_pending != 0:
                                                break
                                            if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                                break
                                        if __goto_pending != 0:
                                            break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (if condition__goto_733_6 != 0: _pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] else: F__goto_706_12.fields.op_cond.length)
                            if (F__goto_706_12.op == OP_SCOND):
                                (group_frame_type__goto_731_10 = 131072)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = F__goto_706_12.ecode)
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 35)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                        OP_REVERSE =>
                            (number__goto_729_10 = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            if ((number__goto_729_10 as c_long) > ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]())):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            F__goto_706_12.eptr = F__goto_706_12.eptr - number__goto_729_10
                            if __goto_pending != 0:
                                break
                            if (F__goto_706_12.eptr < mb.start_used_ptr):
                                (mb.start_used_ptr = F__goto_706_12.eptr)
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_VREVERSE =>
                            (F__goto_706_12.fields.op_vreverse.min = ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint))
                            (F__goto_706_12.fields.op_vreverse.max = ((((((((F__goto_706_12.ecode)[(1 + 2)] as c_uint) << 8))) | (F__goto_706_12.ecode)[(((1 + 2)) + 1)])) as c_uint))
                            diff__goto_6278_17 = ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]())
                            if __goto_pending != 0:
                                break
                            available__goto_6279_16 = (if (diff__goto_6278_17 > 65535): 65535 else: ((if (diff__goto_6278_17 > 0): (diff__goto_6278_17 as c_int) else: 0)))
                            if __goto_pending != 0:
                                break
                            if (F__goto_706_12.fields.op_vreverse.min > available__goto_6279_16):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if __goto_pending != 0:
                                break
                            if (F__goto_706_12.fields.op_vreverse.max > available__goto_6279_16):
                                (F__goto_706_12.fields.op_vreverse.max = available__goto_6279_16)
                            if __goto_pending != 0:
                                break
                            F__goto_706_12.eptr = F__goto_706_12.eptr - F__goto_706_12.fields.op_vreverse.max
                            if __goto_pending != 0:
                                break
                            while true:
                                while true:
                                    (start_ecode = ((F__goto_706_12.ecode + (1 as isize as usize)) + ((2 * 2) as isize as usize)))
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 37)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                if ((F__goto_706_12.fields.op_vreverse.max = F__goto_706_12.fields.op_vreverse.max - 1) <= F__goto_706_12.fields.op_vreverse.min):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.eptr = F__goto_706_12.eptr + 1)
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                            (branch_end__goto_716_12 = F__goto_706_12.ecode)
                            while true:
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                    break
                        OP_ALT =>
                            (branch_end__goto_716_12 = F__goto_706_12.ecode)
                            while true:
                                F__goto_706_12.ecode = F__goto_706_12.ecode + ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                                if not (((unsafe: *F__goto_706_12.ecode) == OP_ALT)):
                                    break
                        OP_KET =>
                            if (branch_end__goto_716_12 == (null as *const u8)):
                                (branch_end__goto_716_12 = F__goto_706_12.ecode)
                            (branch_start__goto_717_12 = bracode__goto_718_12)
                            while ((branch_start__goto_717_12 + ((((((((branch_start__goto_717_12)[1] as c_uint) << 8))) | (branch_start__goto_717_12)[((1) + 1)])) as c_uint)) != branch_end__goto_716_12):
                                branch_start__goto_717_12 = branch_start__goto_717_12 + ((((((((branch_start__goto_717_12)[1] as c_uint) << 8))) | (branch_start__goto_717_12)[((1) + 1)])) as c_uint)
                                if __goto_pending != 0:
                                    break
                            (branch_end__goto_716_12 = (null as *const u8))
                            if (((unsafe: *bracode__goto_718_12) != OP_BRA) and ((unsafe: *bracode__goto_718_12) != OP_COND)):
                                (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + F__goto_706_12.last_group_offset)) as *mut heapframe))
                                if __goto_pending != 0:
                                    break
                                (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.last_group_offset = P__goto_708_12.last_group_offset)
                                if __goto_pending != 0:
                                    break
                                if (N__goto_707_12.group_frame_type == 196608):
                                    if (((((unsafe: *bracode__goto_718_12) == OP_ASSERTBACK) or ((unsafe: *bracode__goto_718_12) == OP_ASSERTBACK_NOT)) and (branch_start__goto_717_12[(1 + 2)] == OP_VREVERSE)) and (F__goto_706_12.eptr != P__goto_708_12.eptr)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    with_memcpy((((P__goto_708_12 as *mut i8) + 120) as *mut c_void) as *i8, ((&F__goto_706_12.ovector[0] as *mut c_ulong) as *const c_void) as *i8, (F__goto_706_12.offset_top *% sizeof[c_ulong]()) as i64)
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12.offset_top = F__goto_706_12.offset_top)
                                    if __goto_pending != 0:
                                        break
                                    (P__goto_708_12.mark = F__goto_706_12.mark)
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.back_frame = (((F__goto_706_12 as *mut i8) as usize -% (P__goto_708_12 as *mut i8) as usize) / sizeof[c_char]()))
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (rrc__goto_722_5 = 1)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                (P__goto_708_12 = (null as *mut heapframe))
                            match (unsafe: *bracode__goto_718_12)
                                OP_BRA =>
                                    if ((F__goto_706_12.current_recurse != 0) or (F__goto_706_12.ecode[(1 + 2)] != OP_END)):
                                        break
                                    (offset__goto_719_12 = F__goto_706_12.last_group_offset)
                                    if (offset__goto_719_12 == ((0 - (0 as c_ulong) - 1))):
                                        return (-44)
                                    (N__goto_707_12 = ((((match_data.heapframes as *mut i8) + offset__goto_719_12)) as *mut heapframe))
                                    (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                    (F__goto_706_12.last_group_offset = P__goto_708_12.last_group_offset)
                                    (F__goto_706_12.ecode = ((P__goto_708_12.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                    if ((unsafe: *F__goto_706_12.ecode) != OP_CREF):
                                        with_memcpy(((&F__goto_706_12.ovector[0] as *mut c_ulong) as *mut c_void) as *i8, ((&P__goto_708_12.ovector[0] as *mut c_ulong) as *const c_void) as *i8, (F__goto_706_12.offset_top *% sizeof[c_ulong]()) as i64)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.offset_top = P__goto_708_12.offset_top)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        recurse_update_offsets(F__goto_706_12, P__goto_708_12)
                                    (F__goto_706_12.capture_last = P__goto_708_12.capture_last)
                                    (F__goto_706_12.current_recurse = P__goto_708_12.current_recurse)
                                    continue
                                    if ((branch_start__goto_717_12[(1 + 2)] == OP_VREVERSE) and (F__goto_706_12.eptr != P__goto_708_12.eptr)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if (F__goto_706_12.eptr > mb.last_used_ptr):
                                        (mb.last_used_ptr = F__goto_706_12.eptr)
                                    (F__goto_706_12.eptr = P__goto_708_12.eptr)
                                OP_COND =>
                                    if ((branch_start__goto_717_12[(1 + 2)] == OP_VREVERSE) and (F__goto_706_12.eptr != P__goto_708_12.eptr)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if (F__goto_706_12.eptr > mb.last_used_ptr):
                                        (mb.last_used_ptr = F__goto_706_12.eptr)
                                    (F__goto_706_12.eptr = P__goto_708_12.eptr)
                                OP_ASSERTBACK_NA =>
                                    if ((branch_start__goto_717_12[(1 + 2)] == OP_VREVERSE) and (F__goto_706_12.eptr != P__goto_708_12.eptr)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if (F__goto_706_12.eptr > mb.last_used_ptr):
                                        (mb.last_used_ptr = F__goto_706_12.eptr)
                                    (F__goto_706_12.eptr = P__goto_708_12.eptr)
                                OP_ASSERT_NA =>
                                    if (F__goto_706_12.eptr > mb.last_used_ptr):
                                        (mb.last_used_ptr = F__goto_706_12.eptr)
                                    (F__goto_706_12.eptr = P__goto_708_12.eptr)
                                OP_ASSERTBACK =>
                                    if ((branch_start__goto_717_12[(1 + 2)] == OP_VREVERSE) and (F__goto_706_12.eptr != P__goto_708_12.eptr)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if (F__goto_706_12.eptr > mb.last_used_ptr):
                                        (mb.last_used_ptr = F__goto_706_12.eptr)
                                    (F__goto_706_12.eptr = P__goto_708_12.eptr)
                                    (F__goto_706_12.back_frame = ((((F__goto_706_12 as *mut i8) as usize -% (P__goto_708_12 as *mut i8) as usize) / sizeof[c_char]())))
                                    while true:
                                        y__goto_6457_18 = ((((((((P__goto_708_12.ecode)[1] as c_uint) << 8))) | (P__goto_708_12.ecode)[((1) + 1)])) as c_uint)
                                        if __goto_pending != 0:
                                            break
                                        if ((P__goto_708_12.ecode)[y__goto_6457_18] != OP_ALT):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        P__goto_708_12.ecode = P__goto_708_12.ecode + y__goto_6457_18
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                OP_ASSERT =>
                                    if (F__goto_706_12.eptr > mb.last_used_ptr):
                                        (mb.last_used_ptr = F__goto_706_12.eptr)
                                    (F__goto_706_12.eptr = P__goto_708_12.eptr)
                                    (F__goto_706_12.back_frame = ((((F__goto_706_12 as *mut i8) as usize -% (P__goto_708_12 as *mut i8) as usize) / sizeof[c_char]())))
                                    while true:
                                        y__goto_6457_18 = ((((((((P__goto_708_12.ecode)[1] as c_uint) << 8))) | (P__goto_708_12.ecode)[((1) + 1)])) as c_uint)
                                        if __goto_pending != 0:
                                            break
                                        if ((P__goto_708_12.ecode)[y__goto_6457_18] != OP_ALT):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        P__goto_708_12.ecode = P__goto_708_12.ecode + y__goto_6457_18
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                OP_ONCE =>
                                    (F__goto_706_12.back_frame = ((((F__goto_706_12 as *mut i8) as usize -% (P__goto_708_12 as *mut i8) as usize) / sizeof[c_char]())))
                                    while true:
                                        y__goto_6457_18 = ((((((((P__goto_708_12.ecode)[1] as c_uint) << 8))) | (P__goto_708_12.ecode)[((1) + 1)])) as c_uint)
                                        if __goto_pending != 0:
                                            break
                                        if ((P__goto_708_12.ecode)[y__goto_6457_18] != OP_ALT):
                                            break
                                        if __goto_pending != 0:
                                            break
                                        P__goto_708_12.ecode = P__goto_708_12.ecode + y__goto_6457_18
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                OP_ASSERTBACK_NOT =>
                                    if ((branch_start__goto_717_12[(1 + 2)] == OP_VREVERSE) and (F__goto_706_12.eptr != P__goto_708_12.eptr)):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    while true:
                                        (rrc__goto_722_5 = 1)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    (F__goto_706_12.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                                    (mb.end_subject = P__goto_708_12.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + P__goto_708_12.fields.op_assert_scs.true_end_extra))
                                    (F__goto_706_12.eptr = P__goto_708_12.fields.op_assert_scs.saved_eptr)
                                    while true:
                                        (start_ecode = ((F__goto_706_12.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 39)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    (mb.end_subject = F__goto_706_12.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = mb.end_subject)
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                OP_ASSERT_NOT =>
                                    while true:
                                        (rrc__goto_722_5 = 1)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    (F__goto_706_12.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                                    (mb.end_subject = P__goto_708_12.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + P__goto_708_12.fields.op_assert_scs.true_end_extra))
                                    (F__goto_706_12.eptr = P__goto_708_12.fields.op_assert_scs.saved_eptr)
                                    while true:
                                        (start_ecode = ((F__goto_706_12.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 39)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    (mb.end_subject = F__goto_706_12.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = mb.end_subject)
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                OP_ASSERT_SCS =>
                                    (F__goto_706_12.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                                    (mb.end_subject = P__goto_708_12.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + P__goto_708_12.fields.op_assert_scs.true_end_extra))
                                    (F__goto_706_12.eptr = P__goto_708_12.fields.op_assert_scs.saved_eptr)
                                    while true:
                                        (start_ecode = ((F__goto_706_12.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 39)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    (mb.end_subject = F__goto_706_12.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = mb.end_subject)
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                OP_SCRIPT_RUN =>
                                    if (not ((_pcre2_script_run_8(P__goto_708_12.eptr, F__goto_706_12.eptr, utf__goto_743_6) != 0))):
                                        while true:
                                            (rrc__goto_722_5 = 0)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                OP_CBRA =>
                                    if (F__goto_706_12.current_recurse == number__goto_729_10):
                                        (P__goto_708_12 = ((((N__goto_707_12 as *mut i8) - frame_size)) as *mut heapframe))
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.ecode = ((P__goto_708_12.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                        if __goto_pending != 0:
                                            break
                                        if ((unsafe: *F__goto_706_12.ecode) != OP_CREF):
                                            with_memcpy(((&F__goto_706_12.ovector[0] as *mut c_ulong) as *mut c_void) as *i8, ((&P__goto_708_12.ovector[0] as *mut c_ulong) as *const c_void) as *i8, (F__goto_706_12.offset_top *% sizeof[c_ulong]()) as i64)
                                            if __goto_pending != 0:
                                                break
                                            (F__goto_706_12.offset_top = P__goto_708_12.offset_top)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            recurse_update_offsets(F__goto_706_12, P__goto_708_12)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.capture_last = P__goto_708_12.capture_last)
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.current_recurse = P__goto_708_12.current_recurse)
                                        if __goto_pending != 0:
                                            break
                                        continue
                                        if __goto_pending != 0:
                                            break
                                    (offset__goto_719_12 = (((number__goto_729_10 << 1)) -% 2))
                                    (F__goto_706_12.capture_last = number__goto_729_10)
                                    ((&F__goto_706_12.ovector[0] as *mut c_ulong)[offset__goto_719_12] = ((P__goto_708_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                    ((&F__goto_706_12.ovector[0] as *mut c_ulong)[(offset__goto_719_12 +% 1)] = ((F__goto_706_12.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                    if (offset__goto_719_12 >= F__goto_706_12.offset_top):
                                        (F__goto_706_12.offset_top = (offset__goto_719_12 +% 2))
                                _ => 0
                            if ((unsafe: *F__goto_706_12.ecode) == OP_KETRPOS):
                                with_memcpy((((P__goto_708_12 as *mut i8) + 64) as *mut c_void) as *i8, (((F__goto_706_12 as *mut i8) + 64) as *const c_void) as *i8, frame_copy_size__goto_712_12 as i64)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (rrc__goto_722_5 = (-998))
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            if ((F__goto_706_12.op != OP_KET) and ((P__goto_708_12 == (null as *mut heapframe)) or (F__goto_706_12.eptr != P__goto_708_12.eptr))):
                                if (F__goto_706_12.op == OP_KETRMIN):
                                    while true:
                                        (start_ecode = ((F__goto_706_12.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                        if __goto_pending != 0:
                                            break
                                        (F__goto_706_12.return_id = 6)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 1
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        0
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (rrc__goto_722_5 != 0):
                                        while true:
                                            (rrc__goto_722_5 = rrc__goto_722_5)
                                            if __goto_pending != 0:
                                                break
                                            __pc = 57
                                            __goto_pending = 1
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                            if not ((0 != 0)):
                                                break
                                    if __goto_pending != 0:
                                        break
                                    F__goto_706_12.ecode = F__goto_706_12.ecode - ((((((((F__goto_706_12.ecode)[1] as c_uint) << 8))) | (F__goto_706_12.ecode)[((1) + 1)])) as c_uint)
                                    if __goto_pending != 0:
                                        break
                                    break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (start_ecode = bracode__goto_718_12)
                                    if __goto_pending != 0:
                                        break
                                    (F__goto_706_12.return_id = 7)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 1
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    0
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                                if (rrc__goto_722_5 != 0):
                                    while true:
                                        (rrc__goto_722_5 = rrc__goto_722_5)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                            F__goto_706_12.ecode = F__goto_706_12.ecode + (1 + 2)
                        OP_CIRC =>
                            if ((F__goto_706_12.eptr != mb.start_subject) or (((mb.moptions & 1)) != 0)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_SOD =>
                            if (F__goto_706_12.eptr != mb.start_subject):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_DOLL =>
                            if (((mb.moptions & 2)) != 0):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if (((mb.poptions & 16)) == 0):
                                __pc = 47
                                __goto_pending = 1
                            if (F__goto_706_12.eptr < mb.true_end_subject):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if (mb.partial != 0):
                                (mb.hitend = 1)
                                if __goto_pending != 0:
                                    break
                                if (mb.partial > 1):
                                    return (-2)
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_EOD =>
                            if (F__goto_706_12.eptr < mb.true_end_subject):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if (mb.partial != 0):
                                (mb.hitend = 1)
                                if __goto_pending != 0:
                                    break
                                if (mb.partial > 1):
                                    return (-2)
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_EODN =>
                            if ((F__goto_706_12.eptr < mb.true_end_subject) and ((not (((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) < mb.end_subject) and (_pcre2_is_newline_8((F__goto_706_12.eptr), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) <= (mb.end_subject - mb.nllen)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (F__goto_706_12.eptr[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0))) or (F__goto_706_12.eptr != (mb.true_end_subject - mb.nllen)))):
                                if (((((mb.partial != 0) and ((F__goto_706_12.eptr + (1 as isize as usize)) >= mb.end_subject)) and (mb.nltype == 0)) and (mb.nllen == 2)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])):
                                    (mb.hitend = 1)
                                    if __goto_pending != 0:
                                        break
                                    if (mb.partial > 1):
                                        return (-2)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            if (mb.partial != 0):
                                (mb.hitend = 1)
                                if __goto_pending != 0:
                                    break
                                if (mb.partial > 1):
                                    return (-2)
                                if __goto_pending != 0:
                                    break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_CIRCM =>
                            if ((((mb.moptions & 1)) != 0) and (F__goto_706_12.eptr == mb.start_subject)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            if ((F__goto_706_12.eptr != mb.start_subject) and (((F__goto_706_12.eptr == mb.end_subject) and (((mb.poptions & 2097152)) == 0)) or (not (((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) > mb.start_subject) and (_pcre2_was_newline_8((F__goto_706_12.eptr), mb.nltype, mb.start_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) >= (mb.start_subject + mb.nllen)) and ((unsafe: *((F__goto_706_12.eptr - mb.nllen))) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or ((unsafe: *(((F__goto_706_12.eptr - mb.nllen) + (1 as isize as usize)))) == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0))))):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_DOLLM =>
                            if (F__goto_706_12.eptr < mb.end_subject):
                                if (not (((if (mb.nltype != 0): ((if ((F__goto_706_12.eptr) < mb.end_subject) and (_pcre2_is_newline_8((F__goto_706_12.eptr), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_743_6) != 0): 1 else: 0)) else: ((if (((F__goto_706_12.eptr) <= (mb.end_subject - mb.nllen)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (F__goto_706_12.eptr[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0))):
                                    if (((((mb.partial != 0) and ((F__goto_706_12.eptr + (1 as isize as usize)) >= mb.end_subject)) and (mb.nltype == 0)) and (mb.nllen == 2)) and ((unsafe: *F__goto_706_12.eptr) == (&mb.nl[0] as *mut u8)[0])):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
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
                                if (((mb.moptions & 2)) != 0):
                                    while true:
                                        (rrc__goto_722_5 = 0)
                                        if __goto_pending != 0:
                                            break
                                        __pc = 57
                                        __goto_pending = 1
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not ((0 != 0)):
                                            break
                                if __goto_pending != 0:
                                    break
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_SOM =>
                            if (F__goto_706_12.eptr != (mb.start_subject + mb.start_offset)):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_SET_SOM =>
                            (F__goto_706_12.start_match = F__goto_706_12.eptr)
                            (F__goto_706_12.ecode = F__goto_706_12.ecode + 1)
                        OP_NOT_WORD_BOUNDARY =>
                            if (F__goto_706_12.eptr >= mb.end_subject):
                                while true:
                                    if ((mb.partial != 0) and ((F__goto_706_12.eptr > mb.start_used_ptr) or (mb.allowemptypartial != 0))):
                                        (mb.hitend = 1)
                                        if __goto_pending != 0:
                                            break
                                        if (mb.partial > 1):
                                            return (-2)
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
                                (cur_is_word__goto_734_6 = 0)
                                if __goto_pending != 0:
                                    break
                            else:
                                nextptr__goto_6757_18 = (F__goto_706_12.eptr + (1 as isize as usize))
                                if __goto_pending != 0:
                                    break
                                (fc__goto_728_10 = (unsafe: *F__goto_706_12.eptr))
                                if __goto_pending != 0:
                                    break
                                if (nextptr__goto_6757_18 > mb.last_used_ptr):
                                    (mb.last_used_ptr = nextptr__goto_6757_18)
                                if __goto_pending != 0:
                                    break
                                (cur_is_word__goto_734_6 = (if (1 != 0) and (((mb.ctypes[fc__goto_728_10] & 16)) != 0): 1 else: 0))
                                if __goto_pending != 0:
                                    break
                            if ((if (((unsafe: *(F__goto_706_12.ecode = F__goto_706_12.ecode + 1)) == OP_WORD_BOUNDARY) or (F__goto_706_12.op == OP_UCP_WORD_BOUNDARY)): (if cur_is_word__goto_734_6 == prev_is_word__goto_735_6: 1 else: 0) else: (if cur_is_word__goto_734_6 != prev_is_word__goto_735_6: 1 else: 0)) != 0):
                                while true:
                                    (rrc__goto_722_5 = 0)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                        OP_MARK =>
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 12)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if ((rrc__goto_722_5 == (-994)) and (_pcre2_strcmp_8((F__goto_706_12.ecode + (2 as isize as usize)), mb.verb_skip_ptr) == 0)):
                                (mb.verb_skip_ptr = F__goto_706_12.eptr)
                                if __goto_pending != 0:
                                    break
                                while true:
                                    (rrc__goto_722_5 = (-995))
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (rrc__goto_722_5 = rrc__goto_722_5)
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (rrc__goto_722_5 = 0)
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 13)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 36)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 14)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 15)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_FAIL =>
                            while true:
                                (rrc__goto_722_5 = 0)
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 13)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 36)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 14)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 15)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_COMMIT =>
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 13)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 36)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 14)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 15)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_COMMIT_ARG =>
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 36)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-997))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 14)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 15)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_PRUNE =>
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 14)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 15)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_PRUNE_ARG =>
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 15)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-996))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_SKIP =>
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 16)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = F__goto_706_12.eptr)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-995))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_SKIP_ARG =>
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (mb.skip_arg_count <= mb.ignore_skip_arg):
                                F__goto_706_12.ecode = F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] + F__goto_706_12.ecode[1])
                                if __goto_pending != 0:
                                    break
                                break
                                if __goto_pending != 0:
                                    break
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 17)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_skip_ptr = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-994))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_THEN =>
                            while true:
                                (start_ecode = (F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 18)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        OP_THEN_ARG =>
                            (mb.nomatch_mark = (F__goto_706_12.ecode + (2 as isize as usize)))
                            (F__goto_706_12.mark = mb.nomatch_mark)
                            while true:
                                (start_ecode = ((F__goto_706_12.ecode + (_pcre2_OP_lengths_8[(unsafe: *F__goto_706_12.ecode)] as isize as usize)) + (F__goto_706_12.ecode[1] as isize as usize)))
                                if __goto_pending != 0:
                                    break
                                (F__goto_706_12.return_id = 19)
                                if __goto_pending != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                0
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            if (rrc__goto_722_5 != 0):
                                while true:
                                    (rrc__goto_722_5 = rrc__goto_722_5)
                                    if __goto_pending != 0:
                                        break
                                    __pc = 57
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not ((0 != 0)):
                                        break
                            (mb.verb_ecode_ptr = F__goto_706_12.ecode)
                            (mb.verb_current_recurse = F__goto_706_12.current_recurse)
                            while true:
                                (rrc__goto_722_5 = (-993))
                                if __goto_pending != 0:
                                    break
                                __pc = 57
                                __goto_pending = 1
                                if __goto_pending != 0:
                                    break
                                if __goto_pending != 0:
                                    break
                                if not ((0 != 0)):
                                    break
                            return (-44)
                        _ =>
                            return (-44)
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                __pc = 57
                continue
            57 =>  // RETURN_SWITCH
                (__goto_pending = 0)
                if (F__goto_706_12.eptr > mb.last_used_ptr):
                    (mb.last_used_ptr = F__goto_706_12.eptr)
                if __goto_pending != 0:
                    continue
                if (F__goto_706_12.rdepth == 0):
                    return rrc__goto_722_5
                if __goto_pending != 0:
                    continue
                (F__goto_706_12 = ((((F__goto_706_12 as *mut i8) - F__goto_706_12.back_frame)) as *mut heapframe))
                if __goto_pending != 0:
                    continue
                mb.cb.callout_flags = mb.cb.callout_flags | 2
                if __goto_pending != 0:
                    continue
                match F__goto_706_12.return_id
                    1 =>
                        __pc = 32
                        __goto_pending = 1
                    2 =>
                        __pc = 34
                        __goto_pending = 1
                    3 =>
                        __pc = 36
                        __goto_pending = 1
                    4 =>
                        __pc = 37
                        __goto_pending = 1
                    5 =>
                        __pc = 41
                        __goto_pending = 1
                    6 =>
                        __pc = 45
                        __goto_pending = 1
                    7 =>
                        __pc = 46
                        __goto_pending = 1
                    8 =>
                        __pc = 31
                        __goto_pending = 1
                    9 =>
                        __pc = 26
                        __goto_pending = 1
                    10 =>
                        __pc = 27
                        __goto_pending = 1
                    11 =>
                        __pc = 35
                        __goto_pending = 1
                    12 =>
                        __pc = 48
                        __goto_pending = 1
                    13 =>
                        __pc = 49
                        __goto_pending = 1
                    14 =>
                        __pc = 51
                        __goto_pending = 1
                    15 =>
                        __pc = 52
                        __goto_pending = 1
                    16 =>
                        __pc = 53
                        __goto_pending = 1
                    17 =>
                        __pc = 54
                        __goto_pending = 1
                    18 =>
                        __pc = 55
                        __goto_pending = 1
                    19 =>
                        __pc = 56
                        __goto_pending = 1
                    20 =>
                        __pc = 23
                        __goto_pending = 1
                    21 =>
                        __pc = 24
                        __goto_pending = 1
                    22 =>
                        __pc = 25
                        __goto_pending = 1
                    23 =>
                        __pc = 13
                        __goto_pending = 1
                    24 =>
                        __pc = 14
                        __goto_pending = 1
                    25 =>
                        __pc = 4
                        __goto_pending = 1
                    26 =>
                        __pc = 5
                        __goto_pending = 1
                    27 =>
                        __pc = 6
                        __goto_pending = 1
                    28 =>
                        __pc = 7
                        __goto_pending = 1
                    29 =>
                        __pc = 9
                        __goto_pending = 1
                    30 =>
                        __pc = 10
                        __goto_pending = 1
                    31 =>
                        __pc = 11
                        __goto_pending = 1
                    32 =>
                        __pc = 12
                        __goto_pending = 1
                    33 =>
                        __pc = 16
                        __goto_pending = 1
                    34 =>
                        __pc = 21
                        __goto_pending = 1
                    35 =>
                        __pc = 42
                        __goto_pending = 1
                    36 =>
                        __pc = 50
                        __goto_pending = 1
                    37 =>
                        __pc = 43
                        __goto_pending = 1
                    38 =>
                        __pc = 40
                        __goto_pending = 1
                    39 =>
                        __pc = 44
                        __goto_pending = 1
                    _ =>
                        return (-44)
                if __goto_pending != 0:
                    continue
            _ => break

