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
fn pcre2_dfa_match_8(code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, start_offset: c_ulong, __param_options: c_uint, match_data: *mut pcre2_real_match_data_8, mcontext: *mut pcre2_real_match_context_8, workspace: *mut c_int, wscount: c_ulong) -> c_int:
    var subject = __param_subject
    var length = __param_length
    var options = __param_options
    var rc__goto_3360_5: c_int = 0
    var re__goto_3362_24: *const pcre2_real_code_8 = null
    var original_options__goto_3363_10: c_uint = 0
    var null_str__goto_3365_13: [1]u8 = [0 as u8; 1]
    var original_subject__goto_3366_12: *const u8 = null
    var start_match__goto_3367_12: *const u8 = null
    var end_subject__goto_3368_12: *const u8 = null
    var bumpalong_limit__goto_3369_12: *const u8 = null
    var req_cu_ptr__goto_3370_12: *const u8 = null
    var utf__goto_3372_6: c_int = 0
    var anchored__goto_3372_11: c_int = 0
    var startline__goto_3372_21: c_int = 0
    var firstline__goto_3372_32: c_int = 0
    var has_first_cu__goto_3373_6: c_int = 0
    var has_req_cu__goto_3374_6: c_int = 0
    var memchr_found_first_cu__goto_3377_12: *const u8 = null
    var memchr_found_first_cu2__goto_3378_12: *const u8 = null
    var first_cu__goto_3381_13: u8 = 0
    var first_cu2__goto_3382_13: u8 = 0
    var req_cu__goto_3383_13: u8 = 0
    var req_cu2__goto_3384_13: u8 = 0
    var start_bits__goto_3386_16: *const u8 = null
    var cb__goto_3391_21: pcre2_callout_block_8
    var actual_match_block__goto_3392_17: dfa_match_block_8
    var mb__goto_3393_18: *mut dfa_match_block_8 = null
    var base_recursion_workspace__goto_3400_5: [7680]c_int = [0 as c_int; 7680]
    var rws__goto_3401_13: *mut RWS_anchor = null
    var t__goto_3737_18: *const u8 = null
    var ok__goto_3761_14: c_int = 0
    var c__goto_3764_23: u8 = 0
    var pp1__goto_3803_22: *const u8 = null
    var pp2__goto_3804_22: *const u8 = null
    var searchlength__goto_3805_22: c_ulong = 0
    var c__goto_3918_20: c_uint = 0
    var p__goto_3942_18: *const u8 = null
    var check_length__goto_3976_20: c_ulong = 0
    var pp__goto_3990_24: *const u8 = null
    var next__goto_4135_15: *mut RWS_anchor = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                re__goto_3362_24 = (code as *const pcre2_real_code_8)
                original_options__goto_3363_10 = options
                original_subject__goto_3366_12 = subject
                has_first_cu__goto_3373_6 = 0
                has_req_cu__goto_3374_6 = 0
                memchr_found_first_cu__goto_3377_12 = (null as *const u8)
                memchr_found_first_cu2__goto_3378_12 = (null as *const u8)
                first_cu__goto_3381_13 = 0
                first_cu2__goto_3382_13 = 0
                req_cu__goto_3383_13 = 0
                req_cu2__goto_3384_13 = 0
                start_bits__goto_3386_16 = (null as *const u8)
                mb__goto_3393_18 = ((&actual_match_block__goto_3392_17 as *const dfa_match_block_8) as *mut dfa_match_block_8)
                rws__goto_3401_13 = ((&base_recursion_workspace__goto_3400_5[0] as *mut c_int) as *mut RWS_anchor)
                (rws__goto_3401_13.next = (null as *mut RWS_anchor))
                if __goto_pending != 0:
                    continue
                (rws__goto_3401_13.size = 7680)
                if __goto_pending != 0:
                    continue
                (rws__goto_3401_13.free = 7676)
                if __goto_pending != 0:
                    continue
                if ((subject == (null as *const u8)) and (length == 0)):
                    (subject = ((&null_str__goto_3365_13[0] as *mut u8) as *const u8))
                if __goto_pending != 0:
                    continue
                if (match_data == (null as *mut pcre2_real_match_data_8)):
                    return (-51)
                if __goto_pending != 0:
                    continue
                if (((re__goto_3362_24 == (null as *const pcre2_real_code_8)) or (subject == (null as *const u8))) or (workspace == (null as *mut c_int))):
                    (rc__goto_3360_5 = (-51))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (((options & (0 - (((((((((((((2147483648 as c_uint) | 536870912) | 1) | 2) | 4) | 8) | 1073741824) | 32) | 16) | 128) | 64) | 16384)) - 1))) != 0):
                    (rc__goto_3360_5 = (-34))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (length == ((0 - (0 as c_ulong) - 1))):
                    (length = _pcre2_strlen_8(subject))
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (wscount < 20):
                    (rc__goto_3360_5 = (-43))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (start_offset > length):
                    (rc__goto_3360_5 = (-33))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if ((((options & ((32 | 16)))) != 0) and (((((re__goto_3362_24.overall_options | options)) & 536870912)) != 0)):
                    (rc__goto_3360_5 = (-34))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (((re__goto_3362_24.overall_options & 67108864)) != 0):
                    (rc__goto_3360_5 = (-66))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (re__goto_3362_24.magic_number != 1346589253):
                    (rc__goto_3360_5 = (-31))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (((re__goto_3362_24.flags & (((1 | 2) | 4)))) != 1):
                    (rc__goto_3360_5 = (-32))
                    if __goto_pending != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                options = options | (((re__goto_3362_24.flags & ((65536 | 131072)))) / ((((((65536 | 131072)) & (((0 - ((65536 | 131072)) - 1) +% 1)))) / ((((4 | 8)) & (((0 - ((4 | 8)) - 1) +% 1)))))))
                if __goto_pending != 0:
                    continue
                if (((options & 64)) != 0):
                    if (((((workspace[0] & (-2))) != 0) or (workspace[1] < 1)) or (workspace[1] > (((((wscount -% 2)) / 3)) as c_int))):
                        (rc__goto_3360_5 = (-38))
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
                (utf__goto_3372_6 = (if ((re__goto_3362_24.overall_options & 524288)) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (start_match__goto_3367_12 = (subject + start_offset))
                if __goto_pending != 0:
                    continue
                (end_subject__goto_3368_12 = (subject + length))
                if __goto_pending != 0:
                    continue
                (req_cu_ptr__goto_3370_12 = (start_match__goto_3367_12 - (1 as isize as usize)))
                if __goto_pending != 0:
                    continue
                (anchored__goto_3372_11 = (if (((options & (((2147483648 as c_uint) | 64)))) != 0) or (((re__goto_3362_24.overall_options & (2147483648 as c_uint))) != 0): 1 else: 0))
                if __goto_pending != 0:
                    continue
                (startline__goto_3372_21 = (if ((re__goto_3362_24.flags & 512)) != 0: 1 else: 0))
                if __goto_pending != 0:
                    continue
                (firstline__goto_3372_32 = (if (not ((anchored__goto_3372_11 != 0))) and (((re__goto_3362_24.overall_options & 256)) != 0): 1 else: 0))
                if __goto_pending != 0:
                    continue
                (bumpalong_limit__goto_3369_12 = end_subject__goto_3368_12)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.cb = ((&cb__goto_3391_21 as *const pcre2_callout_block_8) as *mut pcre2_callout_block_8))
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.version = 2)
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.subject = subject)
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.subject_length = ((((end_subject__goto_3368_12 as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.callout_flags = 0)
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.capture_top = 1)
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.capture_last = 0)
                if __goto_pending != 0:
                    continue
                (cb__goto_3391_21.mark = (null as *const u8))
                if __goto_pending != 0:
                    continue
                if (mcontext == (null as *mut pcre2_real_match_context_8)):
                    (mb__goto_3393_18.callout = (null as *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int))
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.memctl = re__goto_3362_24.memctl)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.match_limit = _pcre2_default_match_context_8.match_limit)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.match_limit_depth = _pcre2_default_match_context_8.depth_limit)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.heap_limit = _pcre2_default_match_context_8.heap_limit)
                    if __goto_pending != 0:
                        continue
                else:
                    if (mcontext.offset_limit != ((0 - (0 as c_ulong) - 1))):
                        if (((re__goto_3362_24.overall_options & 8388608)) == 0):
                            (rc__goto_3360_5 = (-56))
                            if __goto_pending != 0:
                                continue
                            __pc = 2
                            __goto_pending = 1
                            if __goto_pending != 0:
                                continue
                        if __goto_pending != 0:
                            continue
                        (bumpalong_limit__goto_3369_12 = (subject + mcontext.offset_limit))
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.callout = mcontext.callout)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.callout_data = mcontext.callout_data)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.memctl = mcontext.memctl)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.match_limit = mcontext.match_limit)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.match_limit_depth = mcontext.depth_limit)
                    if __goto_pending != 0:
                        continue
                    (mb__goto_3393_18.heap_limit = mcontext.heap_limit)
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                if (mb__goto_3393_18.match_limit > re__goto_3362_24.limit_match):
                    (mb__goto_3393_18.match_limit = re__goto_3362_24.limit_match)
                if __goto_pending != 0:
                    continue
                if (mb__goto_3393_18.match_limit_depth > re__goto_3362_24.limit_depth):
                    (mb__goto_3393_18.match_limit_depth = re__goto_3362_24.limit_depth)
                if __goto_pending != 0:
                    continue
                if (mb__goto_3393_18.heap_limit > re__goto_3362_24.limit_heap):
                    (mb__goto_3393_18.heap_limit = re__goto_3362_24.limit_heap)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.start_code = ((((re__goto_3362_24 as *const u8) + re__goto_3362_24.code_start)) as *const u8))
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.tables = re__goto_3362_24.tables)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.start_subject = subject)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.end_subject = end_subject__goto_3368_12)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.start_offset = start_offset)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.allowemptypartial = (if (re__goto_3362_24.max_lookbehind > 0) or (((re__goto_3362_24.flags & 8192)) != 0): 1 else: 0))
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.moptions = options)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.poptions = re__goto_3362_24.overall_options)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.match_call_count = 0)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.heap_used = 0)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.bsr_convention = re__goto_3362_24.bsr_convention)
                if __goto_pending != 0:
                    continue
                (mb__goto_3393_18.nltype = 0)
                if __goto_pending != 0:
                    continue
                match re__goto_3362_24.newline_convention
                    1 =>
                        (mb__goto_3393_18.nllen = 1)
                        ((&mb__goto_3393_18.nl[0] as *mut u8)[0] = 13)
                    2 =>
                        (mb__goto_3393_18.nllen = 1)
                        ((&mb__goto_3393_18.nl[0] as *mut u8)[0] = 10)
                    6 =>
                        (mb__goto_3393_18.nllen = 1)
                        ((&mb__goto_3393_18.nl[0] as *mut u8)[0] = 0)
                    3 =>
                        (mb__goto_3393_18.nllen = 2)
                        ((&mb__goto_3393_18.nl[0] as *mut u8)[0] = 13)
                        ((&mb__goto_3393_18.nl[0] as *mut u8)[1] = 10)
                    4 =>
                        (mb__goto_3393_18.nltype = 1)
                    5 =>
                        (mb__goto_3393_18.nltype = 2)
                    _ =>
                        (rc__goto_3360_5 = (-44))
                        __pc = 2
                        __goto_pending = 1
                if __goto_pending != 0:
                    continue
                if (((re__goto_3362_24.flags & 16)) != 0):
                    (has_first_cu__goto_3373_6 = 1)
                    if __goto_pending != 0:
                        continue
                    (first_cu2__goto_3382_13 = ((re__goto_3362_24.first_codeunit) as u8))
                    (first_cu__goto_3381_13 = first_cu2__goto_3382_13)
                    if __goto_pending != 0:
                        continue
                    if (((re__goto_3362_24.flags & 32)) != 0):
                        (first_cu2__goto_3382_13 = (((mb__goto_3393_18.tables + (256 as isize as usize)))[first_cu__goto_3381_13]))
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                else:
                    if ((not ((startline__goto_3372_21 != 0))) and (((re__goto_3362_24.flags & 64)) != 0)):
                        (start_bits__goto_3386_16 = (&re__goto_3362_24.start_bitmap[0] as *mut u8))
                if __goto_pending != 0:
                    continue
                if (((re__goto_3362_24.flags & 128)) != 0):
                    (has_req_cu__goto_3374_6 = 1)
                    if __goto_pending != 0:
                        continue
                    (req_cu2__goto_3384_13 = ((re__goto_3362_24.last_codeunit) as u8))
                    (req_cu__goto_3383_13 = req_cu2__goto_3384_13)
                    if __goto_pending != 0:
                        continue
                    if (((re__goto_3362_24.flags & 256)) != 0):
                        (req_cu2__goto_3384_13 = (((mb__goto_3393_18.tables + (256 as isize as usize)))[req_cu__goto_3383_13]))
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
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
                (match_data.code = re__goto_3362_24)
                if __goto_pending != 0:
                    continue
                (match_data.subject = (null as *const u8))
                if __goto_pending != 0:
                    continue
                (match_data.mark = (null as *const u8))
                if __goto_pending != 0:
                    continue
                (match_data.matchedby = 1)
                if __goto_pending != 0:
                    continue
                (match_data.options = original_options__goto_3363_10)
                if __goto_pending != 0:
                    continue
                while true:
                    if ((((re__goto_3362_24.optimization_flags & 4)) != 0) and (((options & 64)) == 0)):
                        if (firstline__goto_3372_32 != 0):
                            t__goto_3737_18 = start_match__goto_3367_12
                            if __goto_pending != 0:
                                break
                            while ((t__goto_3737_18 < end_subject__goto_3368_12) and (not (((if (mb__goto_3393_18.nltype != 0): ((if ((t__goto_3737_18) < mb__goto_3393_18.end_subject) and (_pcre2_is_newline_8((t__goto_3737_18), mb__goto_3393_18.nltype, mb__goto_3393_18.end_subject, ((&(mb__goto_3393_18.nllen) as *const c_uint) as *mut c_uint), utf__goto_3372_6) != 0): 1 else: 0)) else: ((if (((t__goto_3737_18) <= (mb__goto_3393_18.end_subject - mb__goto_3393_18.nllen)) and ((unsafe: *t__goto_3737_18) == (&mb__goto_3393_18.nl[0] as *mut u8)[0])) and ((mb__goto_3393_18.nllen == 1) or (t__goto_3737_18[1] == (&mb__goto_3393_18.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)))):
                                (t__goto_3737_18 = t__goto_3737_18 + 1)
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                            (end_subject__goto_3368_12 = t__goto_3737_18)
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        if (anchored__goto_3372_11 != 0):
                            if ((has_first_cu__goto_3373_6 != 0) or (start_bits__goto_3386_16 != (null as *const u8))):
                                ok__goto_3761_14 = (if start_match__goto_3367_12 < end_subject__goto_3368_12: 1 else: 0)
                                if __goto_pending != 0:
                                    break
                                if (ok__goto_3761_14 != 0):
                                    c__goto_3764_23 = (unsafe: *start_match__goto_3367_12)
                                    if __goto_pending != 0:
                                        break
                                    (ok__goto_3761_14 = (if (has_first_cu__goto_3373_6 != 0) and ((c__goto_3764_23 == first_cu__goto_3381_13) or (c__goto_3764_23 == first_cu2__goto_3382_13)): 1 else: 0))
                                    if __goto_pending != 0:
                                        break
                                    if ((not ((ok__goto_3761_14 != 0))) and (start_bits__goto_3386_16 != (null as *const u8))):
                                        (ok__goto_3761_14 = (if ((start_bits__goto_3386_16[(c__goto_3764_23 / 8)] & ((1 << ((c__goto_3764_23 & 7)))))) != 0: 1 else: 0))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if (not ((ok__goto_3761_14 != 0))):
                                    break
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                        else:
                            if (has_first_cu__goto_3373_6 != 0):
                                if (first_cu__goto_3381_13 != first_cu2__goto_3382_13):
                                    pp1__goto_3803_22 = (null as *const u8)
                                    if __goto_pending != 0:
                                        break
                                    pp2__goto_3804_22 = (null as *const u8)
                                    if __goto_pending != 0:
                                        break
                                    searchlength__goto_3805_22 = ((end_subject__goto_3368_12 as usize -% start_match__goto_3367_12 as usize) / sizeof[u8]())
                                    if __goto_pending != 0:
                                        break
                                    if ((memchr_found_first_cu__goto_3377_12 == (null as *const u8)) or (start_match__goto_3367_12 > memchr_found_first_cu__goto_3377_12)):
                                        (pp1__goto_3803_22 = (memchr((start_match__goto_3367_12 as *const c_void), first_cu__goto_3381_13, searchlength__goto_3805_22) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        (memchr_found_first_cu__goto_3377_12 = (if (pp1__goto_3803_22 == (null as *const u8)): end_subject__goto_3368_12 else: pp1__goto_3803_22))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (pp1__goto_3803_22 = (if (memchr_found_first_cu__goto_3377_12 == end_subject__goto_3368_12): (null as *const u8) else: memchr_found_first_cu__goto_3377_12))
                                    if __goto_pending != 0:
                                        break
                                    if ((memchr_found_first_cu2__goto_3378_12 == (null as *const u8)) or (start_match__goto_3367_12 > memchr_found_first_cu2__goto_3378_12)):
                                        (pp2__goto_3804_22 = (memchr((start_match__goto_3367_12 as *const c_void), first_cu2__goto_3382_13, searchlength__goto_3805_22) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        (memchr_found_first_cu2__goto_3378_12 = (if (pp2__goto_3804_22 == (null as *const u8)): end_subject__goto_3368_12 else: pp2__goto_3804_22))
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (pp2__goto_3804_22 = (if (memchr_found_first_cu2__goto_3378_12 == end_subject__goto_3368_12): (null as *const u8) else: memchr_found_first_cu2__goto_3378_12))
                                    if __goto_pending != 0:
                                        break
                                    if (pp1__goto_3803_22 == (null as *const u8)):
                                        (start_match__goto_3367_12 = (if (pp2__goto_3804_22 == (null as *const u8)): end_subject__goto_3368_12 else: pp2__goto_3804_22))
                                    else:
                                        (start_match__goto_3367_12 = (if ((pp2__goto_3804_22 == (null as *const u8)) or (pp1__goto_3803_22 < pp2__goto_3804_22)): pp1__goto_3803_22 else: pp2__goto_3804_22))
                                    if __goto_pending != 0:
                                        break
                                else:
                                    (start_match__goto_3367_12 = (memchr((start_match__goto_3367_12 as *const c_void), first_cu__goto_3381_13, ((end_subject__goto_3368_12 as usize -% start_match__goto_3367_12 as usize) / sizeof[u8]())) as *const u8))
                                    if __goto_pending != 0:
                                        break
                                    if (start_match__goto_3367_12 == (null as *const u8)):
                                        (start_match__goto_3367_12 = end_subject__goto_3368_12)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                if ((((mb__goto_3393_18.moptions & ((32 | 16)))) == 0) and (start_match__goto_3367_12 >= mb__goto_3393_18.end_subject)):
                                    break
                                if __goto_pending != 0:
                                    break
                            else:
                                if (startline__goto_3372_21 != 0):
                                    if (start_match__goto_3367_12 > (mb__goto_3393_18.start_subject + start_offset)):
                                        while ((start_match__goto_3367_12 < end_subject__goto_3368_12) and (not (((if (mb__goto_3393_18.nltype != 0): ((if ((start_match__goto_3367_12) > mb__goto_3393_18.start_subject) and (_pcre2_was_newline_8((start_match__goto_3367_12), mb__goto_3393_18.nltype, mb__goto_3393_18.start_subject, ((&(mb__goto_3393_18.nllen) as *const c_uint) as *mut c_uint), utf__goto_3372_6) != 0): 1 else: 0)) else: ((if (((start_match__goto_3367_12) >= (mb__goto_3393_18.start_subject + mb__goto_3393_18.nllen)) and ((unsafe: *((start_match__goto_3367_12 - mb__goto_3393_18.nllen))) == (&mb__goto_3393_18.nl[0] as *mut u8)[0])) and ((mb__goto_3393_18.nllen == 1) or ((unsafe: *(((start_match__goto_3367_12 - mb__goto_3393_18.nllen) + (1 as isize as usize)))) == (&mb__goto_3393_18.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)))):
                                            (start_match__goto_3367_12 = start_match__goto_3367_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((((start_match__goto_3367_12[-1] == 13) and ((mb__goto_3393_18.nltype == 1) or (mb__goto_3393_18.nltype == 2))) and (start_match__goto_3367_12 < end_subject__goto_3368_12)) and ((unsafe: *start_match__goto_3367_12) == 10)):
                                            (start_match__goto_3367_12 = start_match__goto_3367_12 + 1)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (start_bits__goto_3386_16 != (null as *const u8)):
                                        while (start_match__goto_3367_12 < end_subject__goto_3368_12):
                                            c__goto_3918_20 = (unsafe: *start_match__goto_3367_12)
                                            if __goto_pending != 0:
                                                break
                                            if (((start_bits__goto_3386_16[(c__goto_3918_20 / 8)] & ((1 << ((c__goto_3918_20 & 7)))))) != 0):
                                                break
                                            if __goto_pending != 0:
                                                break
                                            (start_match__goto_3367_12 = start_match__goto_3367_12 + 1)
                                            if __goto_pending != 0:
                                                break
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((((mb__goto_3393_18.moptions & ((32 | 16)))) == 0) and (start_match__goto_3367_12 >= mb__goto_3393_18.end_subject)):
                                            break
                                        if __goto_pending != 0:
                                            break
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        (end_subject__goto_3368_12 = mb__goto_3393_18.end_subject)
                        if __goto_pending != 0:
                            break
                        if (((mb__goto_3393_18.moptions & ((32 | 16)))) == 0):
                            if (((end_subject__goto_3368_12 as usize -% start_match__goto_3367_12 as usize) / sizeof[u8]()) < re__goto_3362_24.minlength):
                                __pc = 1
                                __goto_pending = 1
                            if __goto_pending != 0:
                                break
                            (p__goto_3942_18 = (start_match__goto_3367_12 + (((if has_first_cu__goto_3373_6 != 0: 1 else: 0)) as isize as usize)))
                            if __goto_pending != 0:
                                break
                            if ((has_req_cu__goto_3374_6 != 0) and (p__goto_3942_18 > req_cu_ptr__goto_3370_12)):
                                check_length__goto_3976_20 = ((end_subject__goto_3368_12 as usize -% start_match__goto_3367_12 as usize) / sizeof[u8]())
                                if __goto_pending != 0:
                                    break
                                if ((check_length__goto_3976_20 < 5000) or ((not ((anchored__goto_3372_11 != 0))) and (check_length__goto_3976_20 < 5000000))):
                                    if (req_cu__goto_3383_13 != req_cu2__goto_3384_13):
                                        pp__goto_3990_24 = p__goto_3942_18
                                        if __goto_pending != 0:
                                            break
                                        (p__goto_3942_18 = (memchr((pp__goto_3990_24 as *const c_void), req_cu__goto_3383_13, ((end_subject__goto_3368_12 as usize -% pp__goto_3990_24 as usize) / sizeof[u8]())) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        if (p__goto_3942_18 == (null as *const u8)):
                                            (p__goto_3942_18 = (memchr((pp__goto_3990_24 as *const c_void), req_cu2__goto_3384_13, ((end_subject__goto_3368_12 as usize -% pp__goto_3990_24 as usize) / sizeof[u8]())) as *const u8))
                                            if __goto_pending != 0:
                                                break
                                            if (p__goto_3942_18 == (null as *const u8)):
                                                (p__goto_3942_18 = end_subject__goto_3368_12)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        (p__goto_3942_18 = (memchr((p__goto_3942_18 as *const c_void), req_cu__goto_3383_13, ((end_subject__goto_3368_12 as usize -% p__goto_3942_18 as usize) / sizeof[u8]())) as *const u8))
                                        if __goto_pending != 0:
                                            break
                                        if (p__goto_3942_18 == (null as *const u8)):
                                            (p__goto_3942_18 = end_subject__goto_3368_12)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (p__goto_3942_18 >= end_subject__goto_3368_12):
                                        break
                                    if __goto_pending != 0:
                                        break
                                    (req_cu_ptr__goto_3370_12 = p__goto_3942_18)
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
                    if (start_match__goto_3367_12 > bumpalong_limit__goto_3369_12):
                        break
                    if __goto_pending != 0:
                        break
                    (mb__goto_3393_18.start_used_ptr = start_match__goto_3367_12)
                    if __goto_pending != 0:
                        break
                    (mb__goto_3393_18.last_used_ptr = start_match__goto_3367_12)
                    if __goto_pending != 0:
                        break
                    (mb__goto_3393_18.recursive = (null as *mut dfa_recursion_info))
                    if __goto_pending != 0:
                        break
                    (rc__goto_3360_5 = internal_dfa_match(mb__goto_3393_18, mb__goto_3393_18.start_code, start_match__goto_3367_12, start_offset, (&match_data.ovector[0] as *mut c_ulong), ((match_data.oveccount as c_uint) *% 2), workspace, (wscount as c_int), 0, (&base_recursion_workspace__goto_3400_5[0] as *mut c_int)))
                    if __goto_pending != 0:
                        break
                    if ((rc__goto_3360_5 != ((0 -% 1))) or (anchored__goto_3372_11 != 0)):
                        if (rc__goto_3360_5 == ((0 -% 1))):
                            __pc = 1
                            __goto_pending = 1
                        if __goto_pending != 0:
                            break
                        if ((rc__goto_3360_5 == (-2)) and (match_data.oveccount > 0)):
                            ((&match_data.ovector[0] as *mut c_ulong)[0] = ((((start_match__goto_3367_12 as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                            if __goto_pending != 0:
                                break
                            ((&match_data.ovector[0] as *mut c_ulong)[1] = ((((end_subject__goto_3368_12 as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        if ((rc__goto_3360_5 >= 0) or (rc__goto_3360_5 == (-2))):
                            (match_data.subject_length = length)
                            if __goto_pending != 0:
                                break
                            (match_data.start_offset = start_offset)
                            if __goto_pending != 0:
                                break
                            (match_data.leftchar = ((((mb__goto_3393_18.start_used_ptr as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                            if __goto_pending != 0:
                                break
                            (match_data.rightchar = ((((mb__goto_3393_18.last_used_ptr as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                            if __goto_pending != 0:
                                break
                            (match_data.startchar = ((((start_match__goto_3367_12 as usize -% subject as usize) / sizeof[u8]())) as c_ulong))
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        if ((rc__goto_3360_5 >= 0) and (((options & 16384)) != 0)):
                            if (length != 0):
                                (match_data.subject = (match_data.memctl.malloc((((length) *% 1)), match_data.memctl.memory_data) as *const u8))
                                if __goto_pending != 0:
                                    break
                                if (match_data.subject == (null as *const u8)):
                                    (rc__goto_3360_5 = (-48))
                                    if __goto_pending != 0:
                                        break
                                    __pc = 2
                                    __goto_pending = 1
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                with_memcpy((match_data.subject as *mut c_void) as *i8, (subject as *const c_void) as *i8, (((length) *% 1)) as i64)
                                if __goto_pending != 0:
                                    break
                            else:
                                (match_data.subject = (null as *const u8))
                            if __goto_pending != 0:
                                break
                            match_data.flags = match_data.flags | 1
                            if __goto_pending != 0:
                                break
                        else:
                            if ((rc__goto_3360_5 >= 0) or (rc__goto_3360_5 == (-2))):
                                (match_data.subject = original_subject__goto_3366_12)
                                if __goto_pending != 0:
                                    break
                        if __goto_pending != 0:
                            break
                        __pc = 2
                        __goto_pending = 1
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    if ((firstline__goto_3372_32 != 0) and ((if (mb__goto_3393_18.nltype != 0): ((if ((start_match__goto_3367_12) < mb__goto_3393_18.end_subject) and (_pcre2_is_newline_8((start_match__goto_3367_12), mb__goto_3393_18.nltype, mb__goto_3393_18.end_subject, ((&(mb__goto_3393_18.nllen) as *const c_uint) as *mut c_uint), utf__goto_3372_6) != 0): 1 else: 0)) else: ((if (((start_match__goto_3367_12) <= (mb__goto_3393_18.end_subject - mb__goto_3393_18.nllen)) and ((unsafe: *start_match__goto_3367_12) == (&mb__goto_3393_18.nl[0] as *mut u8)[0])) and ((mb__goto_3393_18.nllen == 1) or (start_match__goto_3367_12[1] == (&mb__goto_3393_18.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)):
                        break
                    if __goto_pending != 0:
                        break
                    (start_match__goto_3367_12 = start_match__goto_3367_12 + 1)
                    if __goto_pending != 0:
                        break
                    if (start_match__goto_3367_12 > end_subject__goto_3368_12):
                        break
                    if __goto_pending != 0:
                        break
                    if (((((start_match__goto_3367_12[-1] == 13) and (start_match__goto_3367_12 < end_subject__goto_3368_12)) and ((unsafe: *start_match__goto_3367_12) == 10)) and (((re__goto_3362_24.flags & 2048)) == 0)) and (((mb__goto_3393_18.nltype == 1) or (mb__goto_3393_18.nltype == 2)) or (mb__goto_3393_18.nllen == 2))):
                        (start_match__goto_3367_12 = start_match__goto_3367_12 + 1)
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                __pc = 1
                continue
            1 =>  // NOMATCH_EXIT
                (__goto_pending = 0)
                (match_data.subject = original_subject__goto_3366_12)
                if __goto_pending != 0:
                    continue
                (match_data.subject_length = length)
                if __goto_pending != 0:
                    continue
                (match_data.start_offset = start_offset)
                if __goto_pending != 0:
                    continue
                (rc__goto_3360_5 = ((0 -% 1)))
                if __goto_pending != 0:
                    continue
                __pc = 2
                continue
            2 =>  // EXIT
                (__goto_pending = 0)
                while (rws__goto_3401_13.next != (null as *mut RWS_anchor)):
                    next__goto_4135_15 = rws__goto_3401_13.next
                    if __goto_pending != 0:
                        break
                    (rws__goto_3401_13.next = next__goto_4135_15.next)
                    if __goto_pending != 0:
                        break
                    mb__goto_3393_18.memctl.free((next__goto_4135_15 as *mut c_void), mb__goto_3393_18.memctl.memory_data)
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                (match_data.rc = rc__goto_3360_5)
                if __goto_pending != 0:
                    continue
                return rc__goto_3360_5
                if __goto_pending != 0:
                    continue
            _ => break

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
var coptable: [173]u8 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 3, 3, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 3, 3, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 3, 3, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 3, 3, 3, 1, 1, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var poptable: [173]u8 = [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
type static_assertion_coptable = [1]c_int
type static_assertion_poptable = [1]c_int
var toptable1: [14]u8 = [0, 0, 0, 0, 0, 0, 8, 8, 1, 1, 16, 16, 0, 0]
var toptable2: [14]u8 = [0, 0, 0, 0, 0, 0, 8, 0, 1, 0, 16, 0, 1, 1]
type stateblock { offset: c_int = 0, count: c_int = 0, data: c_int = 0 }
type struct_stateblock = stateblock
type RWS_anchor { next: *mut RWS_anchor = null, size: c_uint = 0, free: c_uint = 0 }
type struct_RWS_anchor = RWS_anchor
fn do_callout_dfa(code: *const u8, offsets: *mut c_ulong, current_subject: *const u8, ptr: *const u8, mb: *mut dfa_match_block_8, extracode: c_ulong, lengthptr: *mut c_ulong) -> c_int:
    var cb: *mut pcre2_callout_block_8 = mb.cb
    ((unsafe: *lengthptr) = (if (code[extracode] == OP_CALLOUT): (_pcre2_OP_lengths_8[OP_CALLOUT] as c_ulong) else: (((((((((code)[(5 +% extracode)] as c_uint) << 8))) | (code)[(((5 +% extracode)) +% 1)])) as c_uint) as c_ulong)))
    if (mb.callout == (null as *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int)):
        return 0

    (cb.offset_vector = offsets)
    (cb.start_match = ((((current_subject as usize -% mb.start_subject as usize) / sizeof[u8]())) as c_ulong))
    (cb.current_position = ((((ptr as usize -% mb.start_subject as usize) / sizeof[u8]())) as c_ulong))
    (cb.pattern_position = ((((((((code)[(1 +% extracode)] as c_uint) << 8))) | (code)[(((1 +% extracode)) +% 1)])) as c_uint))
    (cb.next_item_length = ((((((((code)[(3 +% extracode)] as c_uint) << 8))) | (code)[(((3 +% extracode)) +% 1)])) as c_uint))
    if (code[extracode] == OP_CALLOUT):
        (cb.callout_number = code[(5 +% extracode)])
        (cb.callout_string_offset = 0)
        (cb.callout_string = (null as *const u8))
        (cb.callout_string_length = 0)
    else:
        (cb.callout_number = 0)
        (cb.callout_string_offset = ((((((((code)[(7 +% extracode)] as c_uint) << 8))) | (code)[(((7 +% extracode)) +% 1)])) as c_uint))
        (cb.callout_string = ((code + ((9 +% extracode))) + (1 as isize as usize)))
        (cb.callout_string_length = (((unsafe: *lengthptr) -% 9) -% 2))

    return (mb.callout)(cb, mb.callout_data)

fn more_workspace(rwsptr: *mut *mut RWS_anchor, ovecsize: c_uint, mb: *mut dfa_match_block_8) -> c_int:
    var rws: *mut RWS_anchor = (unsafe: *rwsptr)
    var new: *mut RWS_anchor
    if (rws.next != (null as *mut RWS_anchor)):
        (new = rws.next)
    else:
        var newsize: c_uint
        var newsizeK: c_uint
        if ((newsizeK +% mb.heap_used) > mb.heap_limit):
            (newsizeK = (((mb.heap_limit -% mb.heap_used)) as c_uint))
        
        if (new == (null as *mut RWS_anchor)):
            return (-48)
        
        mb.heap_used = mb.heap_used + newsizeK
        (new.next = (null as *mut RWS_anchor))
        (new.size = newsize)
        (rws.next = new)

    ((unsafe: *rwsptr) = new)
    return 0

fn internal_dfa_match(mb: *mut dfa_match_block_8, this_start_code: *const u8, __param_current_subject: *const u8, start_offset: c_ulong, offsets: *mut c_ulong, __param_offsetcount: c_uint, workspace: *mut c_int, __param_wscount: c_int, __param_rlevel: c_uint, __param_RWS: *mut c_int) -> c_int:
    var current_subject = __param_current_subject
    var offsetcount = __param_offsetcount
    var wscount = __param_wscount
    var rlevel = __param_rlevel
    var RWS = __param_RWS
    var active_states__goto_558_13: *mut stateblock = null
    var new_states__goto_558_29: *mut stateblock = null
    var temp_states__goto_558_42: *mut stateblock = null
    var next_active_state__goto_559_13: *mut stateblock = null
    var next_new_state__goto_559_33: *mut stateblock = null
    var ctypes__goto_560_16: *const u8 = null
    var lcc__goto_560_25: *const u8 = null
    var fcc__goto_560_31: *const u8 = null
    var ptr__goto_561_12: *const u8 = null
    var end_code__goto_562_12: *const u8 = null
    var new_recursive__goto_563_20: dfa_recursion_info
    var active_count__goto_564_5: c_int = 0
    var new_count__goto_564_19: c_int = 0
    var match_count__goto_564_30: c_int = 0
    var start_subject__goto_569_12: *const u8 = null
    var end_subject__goto_570_12: *const u8 = null
    var start_code__goto_571_12: *const u8 = null
    var utf__goto_577_6: c_int = 0
    var reset_could_continue__goto_580_6: c_int = 0
    var max_back__goto_610_10: c_ulong = 0
    var gone_back__goto_611_10: c_ulong = 0
    var back__goto_616_12: c_ulong = 0
    var current_offset__goto_644_12: c_ulong = 0
    var revlen__goto_660_14: c_uint = 0
    var back__goto_661_12: c_ulong = 0
    var bstate__goto_664_11: c_int = 0
    var length__goto_696_9: c_int = 0
    var i__goto_717_7: c_int = 0
    var j__goto_717_10: c_int = 0
    var clen__goto_718_7: c_int = 0
    var dlen__goto_718_13: c_int = 0
    var c__goto_719_12: c_uint = 0
    var d__goto_719_15: c_uint = 0
    var partial_newline__goto_720_8: c_int = 0
    var could_continue__goto_721_8: c_int = 0
    var current_state__goto_769_17: *mut stateblock = null
    var caseless__goto_770_10: c_int = 0
    var code__goto_771_16: *const u8 = null
    var codevalue__goto_772_14: c_uint = 0
    var state_offset__goto_773_9: c_int = 0
    var rrc__goto_774_9: c_int = 0
    var count__goto_775_9: c_int = 0
    var left_word__goto_1116_13: c_int = 0
    var right_word__goto_1116_24: c_int = 0
    var temp__goto_1120_22: *const u8 = null
    var temp__goto_1145_24: *const u8 = null
    var ncount__goto_1606_13: c_int = 0
    var OK__goto_1648_14: c_int = 0
    var OK__goto_1681_14: c_int = 0
    var ncount__goto_1884_13: c_int = 0
    var OK__goto_1934_14: c_int = 0
    var OK__goto_1974_14: c_int = 0
    var ncount__goto_2165_13: c_int = 0
    var OK__goto_2211_14: c_int = 0
    var OK__goto_2247_14: c_int = 0
    var otherd__goto_2437_18: c_uint = 0
    var otherd__goto_2470_18: c_uint = 0
    var otherd__goto_2513_18: c_uint = 0
    var otherd__goto_2554_18: c_uint = 0
    var otherd__goto_2587_18: c_uint = 0
    var otherd__goto_2627_18: c_uint = 0
    var isinclass__goto_2663_14: c_int = 0
    var next_state_offset__goto_2664_13: c_int = 0
    var ecode__goto_2665_20: *const u8 = null
    var max__goto_2769_17: c_int = 0
    var rc__goto_2805_13: c_int = 0
    var local_workspace__goto_2806_14: *mut c_int = null
    var local_offsets__goto_2807_21: *mut c_ulong = null
    var endasscode__goto_2808_20: *const u8 = null
    var rws__goto_2809_21: *mut RWS_anchor = null
    var codelink__goto_2848_13: c_int = 0
    var condcode__goto_2849_21: u8 = 0
    var callout_length__goto_2858_22: c_ulong = 0
    var value__goto_2892_24: c_uint = 0
    var rc__goto_2903_15: c_int = 0
    var local_workspace__goto_2904_16: *mut c_int = null
    var local_offsets__goto_2905_23: *mut c_ulong = null
    var asscode__goto_2906_22: *const u8 = null
    var endasscode__goto_2907_22: *const u8 = null
    var rws__goto_2908_23: *mut RWS_anchor = null
    var rc__goto_2950_13: c_int = 0
    var local_workspace__goto_2951_14: *mut c_int = null
    var local_offsets__goto_2952_21: *mut c_ulong = null
    var rws__goto_2953_21: *mut RWS_anchor = null
    var callpat__goto_2954_20: *const u8 = null
    var recno__goto_2955_18: c_uint = 0
    var ri__goto_2976_34: *mut dfa_recursion_info = null
    var charcount__goto_3021_24: c_ulong = 0
    var rc__goto_3052_13: c_int = 0
    var local_workspace__goto_3053_14: *mut c_int = null
    var local_offsets__goto_3054_21: *mut c_ulong = null
    var charcount__goto_3055_20: c_ulong = 0
    var matched_count__goto_3055_31: c_ulong = 0
    var local_ptr__goto_3056_20: *const u8 = null
    var rws__goto_3057_21: *mut RWS_anchor = null
    var allow_zero__goto_3058_14: c_int = 0
    var end_subpattern__goto_3118_22: *const u8 = null
    var next_state_offset__goto_3119_15: c_int = 0
    var p__goto_3139_24: *const u8 = null
    var pp__goto_3140_24: *const u8 = null
    var rc__goto_3154_13: c_int = 0
    var local_workspace__goto_3155_14: *mut c_int = null
    var local_offsets__goto_3156_21: *mut c_ulong = null
    var rws__goto_3157_21: *mut RWS_anchor = null
    var end_subpattern__goto_3186_22: *const u8 = null
    var charcount__goto_3187_22: c_ulong = 0
    var next_state_offset__goto_3188_15: c_int = 0
    var repeat_state_offset__goto_3188_34: c_int = 0
    var callout_length__goto_3263_20: c_ulong = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                start_subject__goto_569_12 = mb.start_subject
                end_subject__goto_570_12 = mb.end_subject
                start_code__goto_571_12 = mb.start_code
                utf__goto_577_6 = 0
                reset_could_continue__goto_580_6 = 0
                if ((mb.match_call_count = mb.match_call_count + 1) >= mb.match_limit):
                    return (-47)
                if __goto_pending != 0:
                    continue
                if ((rlevel = rlevel + 1) > mb.match_limit_depth):
                    return (-53)
                if __goto_pending != 0:
                    continue
                offsetcount = offsetcount & ((-2) as c_uint)
                if __goto_pending != 0:
                    continue
                wscount = wscount - 2
                if __goto_pending != 0:
                    continue
                (ctypes__goto_560_16 = (mb.tables + (((512 + 320)) as isize as usize)))
                if __goto_pending != 0:
                    continue
                (lcc__goto_560_25 = (mb.tables + (0 as isize as usize)))
                if __goto_pending != 0:
                    continue
                (fcc__goto_560_31 = (mb.tables + (256 as isize as usize)))
                if __goto_pending != 0:
                    continue
                (match_count__goto_564_30 = ((0 -% 1)))
                if __goto_pending != 0:
                    continue
                (active_states__goto_558_13 = (((workspace + (2 as isize as usize))) as *mut stateblock))
                if __goto_pending != 0:
                    continue
                (new_states__goto_558_29 = (active_states__goto_558_13 + (wscount as isize as usize)))
                (next_new_state__goto_559_33 = new_states__goto_558_29)
                if __goto_pending != 0:
                    continue
                (new_count__goto_564_19 = 0)
                if __goto_pending != 0:
                    continue
                if (((unsafe: *this_start_code) == OP_ASSERTBACK) or ((unsafe: *this_start_code) == OP_ASSERTBACK_NOT)):
                    max_back__goto_610_10 = 0
                    if __goto_pending != 0:
                        continue
                    (end_code__goto_562_12 = this_start_code)
                    if __goto_pending != 0:
                        continue
                    while true:
                        back__goto_616_12 = (((((((((end_code__goto_562_12)[(2 + 2)] as c_uint) << 8))) | (end_code__goto_562_12)[(((2 + 2)) + 1)])) as c_uint) as c_ulong)
                        if __goto_pending != 0:
                            break
                        if (back__goto_616_12 > max_back__goto_610_10):
                            (max_back__goto_610_10 = back__goto_616_12)
                        if __goto_pending != 0:
                            break
                        end_code__goto_562_12 = end_code__goto_562_12 + ((((((((end_code__goto_562_12)[1] as c_uint) << 8))) | (end_code__goto_562_12)[((1) + 1)])) as c_uint)
                        if __goto_pending != 0:
                            break
                        if __goto_pending != 0:
                            break
                        if not (((unsafe: *end_code__goto_562_12) == OP_ALT)):
                            break
                    if __goto_pending != 0:
                        continue
                    current_offset__goto_644_12 = ((((current_subject as usize -% start_subject__goto_569_12 as usize) / sizeof[u8]())) as c_ulong)
                    if __goto_pending != 0:
                        continue
                    (gone_back__goto_611_10 = (if (current_offset__goto_644_12 < max_back__goto_610_10): current_offset__goto_644_12 else: max_back__goto_610_10))
                    if __goto_pending != 0:
                        continue
                    current_subject = current_subject - gone_back__goto_611_10
                    if __goto_pending != 0:
                        continue
                    if __goto_pending != 0:
                        continue
                    if (current_subject < mb.start_used_ptr):
                        (mb.start_used_ptr = current_subject)
                    if __goto_pending != 0:
                        continue
                    (end_code__goto_562_12 = this_start_code)
                    if __goto_pending != 0:
                        continue
                    while true:
                        revlen__goto_660_14 = (if (end_code__goto_562_12[(1 + 2)] == OP_REVERSE): (1 + 2) else: 0)
                        if __goto_pending != 0:
                            break
                        back__goto_661_12 = (if (revlen__goto_660_14 == 0): 0 else: (((((((((end_code__goto_562_12)[(2 + 2)] as c_uint) << 8))) | (end_code__goto_562_12)[(((2 + 2)) + 1)])) as c_uint) as c_ulong))
                        if __goto_pending != 0:
                            break
                        if (back__goto_661_12 <= gone_back__goto_611_10):
                            bstate__goto_664_11 = (((((((end_code__goto_562_12 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) + 1) + 2) + revlen__goto_660_14)) as c_int)
                            if __goto_pending != 0:
                                break
                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                (next_new_state__goto_559_33.offset = ((0 - bstate__goto_664_11)))
                                if __goto_pending != 0:
                                    break
                                (next_new_state__goto_559_33.count = (0))
                                if __goto_pending != 0:
                                    break
                                (next_new_state__goto_559_33.data = ((((gone_back__goto_611_10 -% back__goto_661_12)) as c_int)))
                                if __goto_pending != 0:
                                    break
                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                if __goto_pending != 0:
                                    break
                            else:
                                return (-43)
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        end_code__goto_562_12 = end_code__goto_562_12 + ((((((((end_code__goto_562_12)[1] as c_uint) << 8))) | (end_code__goto_562_12)[((1) + 1)])) as c_uint)
                        if __goto_pending != 0:
                            break
                        if __goto_pending != 0:
                            break
                        if not (((unsafe: *end_code__goto_562_12) == OP_ALT)):
                            break
                    if __goto_pending != 0:
                        continue
                else:
                    (end_code__goto_562_12 = this_start_code)
                    if __goto_pending != 0:
                        continue
                    if ((rlevel == 1) and (((mb.moptions & 64)) != 0)):
                        while true:
                            end_code__goto_562_12 = end_code__goto_562_12 + ((((((((end_code__goto_562_12)[1] as c_uint) << 8))) | (end_code__goto_562_12)[((1) + 1)])) as c_uint)
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                            if not (((unsafe: *end_code__goto_562_12) == OP_ALT)):
                                break
                        if __goto_pending != 0:
                            continue
                        (new_count__goto_564_19 = workspace[1])
                        if __goto_pending != 0:
                            continue
                        if (not ((workspace[0] != 0))):
                            with_memcpy((new_states__goto_558_29 as *mut c_void) as *i8, (active_states__goto_558_13 as *const c_void) as *i8, ((new_count__goto_564_19 as c_ulong) *% sizeof[stateblock]()) as i64)
                        if __goto_pending != 0:
                            continue
                    else:
                        length__goto_696_9 = ((1 + 2) + ((if (((((unsafe: *this_start_code) == OP_CBRA) or ((unsafe: *this_start_code) == OP_SCBRA)) or ((unsafe: *this_start_code) == OP_CBRAPOS)) or ((unsafe: *this_start_code) == OP_SCBRAPOS)): 2 else: 0)))
                        if __goto_pending != 0:
                            continue
                        while true:
                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                (next_new_state__goto_559_33.offset = ((((((end_code__goto_562_12 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) + length__goto_696_9)) as c_int)))
                                if __goto_pending != 0:
                                    break
                                (next_new_state__goto_559_33.count = (0))
                                if __goto_pending != 0:
                                    break
                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                if __goto_pending != 0:
                                    break
                            else:
                                return (-43)
                            if __goto_pending != 0:
                                break
                            end_code__goto_562_12 = end_code__goto_562_12 + ((((((((end_code__goto_562_12)[1] as c_uint) << 8))) | (end_code__goto_562_12)[((1) + 1)])) as c_uint)
                            if __goto_pending != 0:
                                break
                            (length__goto_696_9 = (1 + 2))
                            if __goto_pending != 0:
                                break
                            if __goto_pending != 0:
                                break
                            if not (((unsafe: *end_code__goto_562_12) == OP_ALT)):
                                break
                        if __goto_pending != 0:
                            continue
                    if __goto_pending != 0:
                        continue
                if __goto_pending != 0:
                    continue
                (workspace[0] = 0)
                if __goto_pending != 0:
                    continue
                (ptr__goto_561_12 = current_subject)
                if __goto_pending != 0:
                    continue
                while true:
                    partial_newline__goto_720_8 = 0
                    if __goto_pending != 0:
                        break
                    could_continue__goto_721_8 = reset_could_continue__goto_580_6
                    if __goto_pending != 0:
                        break
                    (reset_could_continue__goto_580_6 = 0)
                    if __goto_pending != 0:
                        break
                    if (ptr__goto_561_12 > mb.last_used_ptr):
                        (mb.last_used_ptr = ptr__goto_561_12)
                    if __goto_pending != 0:
                        break
                    (temp_states__goto_558_42 = active_states__goto_558_13)
                    if __goto_pending != 0:
                        break
                    (active_states__goto_558_13 = new_states__goto_558_29)
                    if __goto_pending != 0:
                        break
                    (new_states__goto_558_29 = temp_states__goto_558_42)
                    if __goto_pending != 0:
                        break
                    (active_count__goto_564_5 = new_count__goto_564_19)
                    if __goto_pending != 0:
                        break
                    (new_count__goto_564_19 = 0)
                    if __goto_pending != 0:
                        break
                    workspace[0] = workspace[0] ^ 1
                    if __goto_pending != 0:
                        break
                    (workspace[1] = active_count__goto_564_5)
                    if __goto_pending != 0:
                        break
                    (next_active_state__goto_559_13 = (active_states__goto_558_13 + (active_count__goto_564_5 as isize as usize)))
                    if __goto_pending != 0:
                        break
                    (next_new_state__goto_559_33 = new_states__goto_558_29)
                    if __goto_pending != 0:
                        break
                    if (ptr__goto_561_12 < end_subject__goto_570_12):
                        (clen__goto_718_7 = 1)
                        if __goto_pending != 0:
                            break
                        (c__goto_719_12 = (unsafe: *ptr__goto_561_12))
                        if __goto_pending != 0:
                            break
                    else:
                        (clen__goto_718_7 = 0)
                        if __goto_pending != 0:
                            break
                        (c__goto_719_12 = (4294967295 as c_uint))
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    (i__goto_717_7 = 0)
                    while (i__goto_717_7 < active_count__goto_564_5):
                        current_state__goto_769_17 = (active_states__goto_558_13 + (i__goto_717_7 as isize as usize))
                        if __goto_pending != 0:
                            break
                        caseless__goto_770_10 = 0
                        if __goto_pending != 0:
                            break
                        state_offset__goto_773_9 = current_state__goto_769_17.offset
                        if __goto_pending != 0:
                            break
                        if (state_offset__goto_773_9 < 0):
                            if (current_state__goto_769_17.data > 0):
                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                    (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                    if __goto_pending != 0:
                                        break
                                    (next_new_state__goto_559_33.count = (current_state__goto_769_17.count))
                                    if __goto_pending != 0:
                                        break
                                    (next_new_state__goto_559_33.data = ((current_state__goto_769_17.data - 1)))
                                    if __goto_pending != 0:
                                        break
                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                                if __goto_pending != 0:
                                    break
                                if (could_continue__goto_721_8 != 0):
                                    (reset_could_continue__goto_580_6 = 1)
                                if __goto_pending != 0:
                                    break
                                continue
                                if __goto_pending != 0:
                                    break
                            else:
                                (state_offset__goto_773_9 = (0 - state_offset__goto_773_9))
                                (current_state__goto_769_17.offset = state_offset__goto_773_9)
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        (j__goto_717_10 = 0)
                        while (j__goto_717_10 < i__goto_717_7):
                            if ((active_states__goto_558_13[j__goto_717_10].offset == state_offset__goto_773_9) and (active_states__goto_558_13[j__goto_717_10].count == current_state__goto_769_17.count)):
                                __pc = 7
                                __goto_pending = 1
                            if __goto_pending != 0:
                                break
                            (j__goto_717_10 = j__goto_717_10 + 1)
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        (code__goto_771_16 = (start_code__goto_571_12 + (state_offset__goto_773_9 as isize as usize)))
                        if __goto_pending != 0:
                            break
                        (codevalue__goto_772_14 = (unsafe: *code__goto_771_16))
                        if __goto_pending != 0:
                            break
                        if ((clen__goto_718_7 == 0) and ((&poptable[0] as *mut u8)[codevalue__goto_772_14] != 0)):
                            (could_continue__goto_721_8 = 1)
                        if __goto_pending != 0:
                            break
                        if ((&coptable[0] as *mut u8)[codevalue__goto_772_14] > 0):
                            (dlen__goto_718_13 = 1)
                            if __goto_pending != 0:
                                break
                            (d__goto_719_15 = code__goto_771_16[(&coptable[0] as *mut u8)[codevalue__goto_772_14]])
                            if __goto_pending != 0:
                                break
                            if (codevalue__goto_772_14 >= 85):
                                match d__goto_719_15
                                    14 =>
                                        return (-42)
                                    15 => 0
                                    17 =>
                                        codevalue__goto_772_14 = codevalue__goto_772_14 + 340
                                    22 =>
                                        codevalue__goto_772_14 = codevalue__goto_772_14 + 320
                                    18 => 0
                                    20 => 0
                                    _ => 0
                                if __goto_pending != 0:
                                    break
                            if __goto_pending != 0:
                                break
                        else:
                            (dlen__goto_718_13 = 0)
                            if __goto_pending != 0:
                                break
                            (d__goto_719_15 = (4294967295 as c_uint))
                            if __goto_pending != 0:
                                break
                        if __goto_pending != 0:
                            break
                        match codevalue__goto_772_14
                            122 => 0
                            121 =>
                                while true:
                                    code__goto_771_16 = code__goto_771_16 + ((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                                    if not (((unsafe: *code__goto_771_16) == OP_ALT)):
                                        break
                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                    (next_active_state__goto_559_13.offset = (((((code__goto_771_16 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]())) as c_int)))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13.count = (0))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                            137 => 0
                            139 =>
                                code__goto_771_16 = code__goto_771_16 + ((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint)
                                while ((unsafe: *code__goto_771_16) == OP_ALT):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = (((((((code__goto_771_16 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) + 1) + 2)) as c_int)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                    code__goto_771_16 = code__goto_771_16 + ((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint)
                                    if __goto_pending != 0:
                                        break
                                    if __goto_pending != 0:
                                        break
                            153 =>
                                code__goto_771_16 = code__goto_771_16 + (1 +% ((((((((code__goto_771_16)[2] as c_uint) << 8))) | (code__goto_771_16)[((2) + 1)])) as c_uint))
                                while ((unsafe: *code__goto_771_16) == OP_ALT):
                                    code__goto_771_16 = code__goto_771_16 + ((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint)
                                    if __goto_pending != 0:
                                        break
                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                    (next_active_state__goto_559_13.offset = (((((((code__goto_771_16 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) + 1) + 2)) as c_int)))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13.count = (0))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                            169 =>
                                code__goto_771_16 = code__goto_771_16 + (1 +% ((((((((code__goto_771_16)[2] as c_uint) << 8))) | (code__goto_771_16)[((2) + 1)])) as c_uint))
                                while ((unsafe: *code__goto_771_16) == OP_ALT):
                                    code__goto_771_16 = code__goto_771_16 + ((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint)
                                    if __goto_pending != 0:
                                        break
                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                    (next_active_state__goto_559_13.offset = (((((((code__goto_771_16 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) + 1) + 2)) as c_int)))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13.count = (0))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                            27 =>
                                if ((ptr__goto_561_12 == start_subject__goto_569_12) and (((mb.moptions & 1)) == 0)):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            28 =>
                                if (((ptr__goto_561_12 == start_subject__goto_569_12) and (((mb.moptions & 1)) == 0)) or (((ptr__goto_561_12 != end_subject__goto_570_12) or (((mb.poptions & 2097152)) != 0)) and ((if (mb.nltype != 0): ((if ((ptr__goto_561_12) > mb.start_subject) and (_pcre2_was_newline_8((ptr__goto_561_12), mb.nltype, mb.start_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_577_6) != 0): 1 else: 0)) else: ((if (((ptr__goto_561_12) >= (mb.start_subject + mb.nllen)) and ((unsafe: *((ptr__goto_561_12 - mb.nllen))) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or ((unsafe: *(((ptr__goto_561_12 - mb.nllen) + (1 as isize as usize)))) == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0))):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            24 =>
                                if (ptr__goto_561_12 >= end_subject__goto_570_12):
                                    if (((mb.moptions & 32)) != 0):
                                        return (-2)
                                    else:
                                        if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                            (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            1 =>
                                if (ptr__goto_561_12 == start_subject__goto_569_12):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            2 =>
                                if (ptr__goto_561_12 == (start_subject__goto_569_12 + start_offset)):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            12 =>
                                if ((clen__goto_718_7 > 0) and (not (((if (mb.nltype != 0): ((if ((ptr__goto_561_12) < mb.end_subject) and (_pcre2_is_newline_8((ptr__goto_561_12), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_577_6) != 0): 1 else: 0)) else: ((if (((ptr__goto_561_12) <= (mb.end_subject - mb.nllen)) and ((unsafe: *ptr__goto_561_12) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (ptr__goto_561_12[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)))):
                                    if ((((((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject) and (((mb.moptions & (32))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                        (partial_newline__goto_720_8 = 1)
                                        (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            13 =>
                                if (clen__goto_718_7 > 0):
                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                        (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            23 =>
                                if ((clen__goto_718_7 == 0) or (((if (mb.nltype != 0): ((if ((ptr__goto_561_12) < mb.end_subject) and (_pcre2_is_newline_8((ptr__goto_561_12), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_577_6) != 0): 1 else: 0)) else: ((if (((ptr__goto_561_12) <= (mb.end_subject - mb.nllen)) and ((unsafe: *ptr__goto_561_12) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (ptr__goto_561_12[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0) and (ptr__goto_561_12 == (end_subject__goto_570_12 - mb.nllen)))):
                                    if (((mb.moptions & 32)) != 0):
                                        return (-2)
                                    if __goto_pending != 0:
                                        break
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            25 =>
                                if (((mb.moptions & 2)) == 0):
                                    if ((clen__goto_718_7 == 0) and (((mb.moptions & 32)) != 0)):
                                        (could_continue__goto_721_8 = 1)
                                    else:
                                        if ((clen__goto_718_7 == 0) or (((((mb.poptions & 16)) == 0) and ((if (mb.nltype != 0): ((if ((ptr__goto_561_12) < mb.end_subject) and (_pcre2_is_newline_8((ptr__goto_561_12), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_577_6) != 0): 1 else: 0)) else: ((if (((ptr__goto_561_12) <= (mb.end_subject - mb.nllen)) and ((unsafe: *ptr__goto_561_12) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (ptr__goto_561_12[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0)) and (ptr__goto_561_12 == (end_subject__goto_570_12 - mb.nllen)))):
                                            if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                                (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((((((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject) and (((mb.moptions & ((32 | 16)))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                                if (((mb.moptions & 32)) != 0):
                                                    (reset_could_continue__goto_580_6 = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                        (next_new_state__goto_559_33.offset = ((0 - ((state_offset__goto_773_9 + 1)))))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.count = (0))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.data = (1))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        return (-43)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    (partial_newline__goto_720_8 = 1)
                                                    (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                                if __goto_pending != 0:
                                                    break
                                    if __goto_pending != 0:
                                        break
                            26 =>
                                if (((mb.moptions & 2)) == 0):
                                    if ((clen__goto_718_7 == 0) and (((mb.moptions & 32)) != 0)):
                                        (could_continue__goto_721_8 = 1)
                                    else:
                                        if ((clen__goto_718_7 == 0) or ((((mb.poptions & 16)) == 0) and ((if (mb.nltype != 0): ((if ((ptr__goto_561_12) < mb.end_subject) and (_pcre2_is_newline_8((ptr__goto_561_12), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_577_6) != 0): 1 else: 0)) else: ((if (((ptr__goto_561_12) <= (mb.end_subject - mb.nllen)) and ((unsafe: *ptr__goto_561_12) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (ptr__goto_561_12[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0))):
                                            if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                                (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((((((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject) and (((mb.moptions & ((32 | 16)))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                                if (((mb.moptions & 32)) != 0):
                                                    (reset_could_continue__goto_580_6 = 1)
                                                    if __goto_pending != 0:
                                                        break
                                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                        (next_new_state__goto_559_33.offset = ((0 - ((state_offset__goto_773_9 + 1)))))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.count = (0))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.data = (1))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        return (-43)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    (partial_newline__goto_720_8 = 1)
                                                    (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                                if __goto_pending != 0:
                                                    break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if ((if (mb.nltype != 0): ((if ((ptr__goto_561_12) < mb.end_subject) and (_pcre2_is_newline_8((ptr__goto_561_12), mb.nltype, mb.end_subject, ((&(mb.nllen) as *const c_uint) as *mut c_uint), utf__goto_577_6) != 0): 1 else: 0)) else: ((if (((ptr__goto_561_12) <= (mb.end_subject - mb.nllen)) and ((unsafe: *ptr__goto_561_12) == (&mb.nl[0] as *mut u8)[0])) and ((mb.nllen == 1) or (ptr__goto_561_12[1] == (&mb.nl[0] as *mut u8)[1])): 1 else: 0))) != 0):
                                        if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                            (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 1)))
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                            7 => 0
                            6 => 0
                            5 => 0
                            87 =>
                                if (count__goto_775_9 > 0):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if (clen__goto_718_7 > 0):
                                    if ((((((d__goto_719_15 == 12) and ((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject)) and (((mb.moptions & (32))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                        (partial_newline__goto_720_8 = 1)
                                        (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                            if ((count__goto_775_9 > 0) and (codevalue__goto_772_14 == 95)):
                                                (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            (count__goto_775_9 = count__goto_775_9 + 1)
                                            if __goto_pending != 0:
                                                break
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                    if __goto_pending != 0:
                                        break
                            89 =>
                                if (clen__goto_718_7 > 0):
                                    if ((((((d__goto_719_15 == 12) and ((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject)) and (((mb.moptions & (32))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                        (partial_newline__goto_720_8 = 1)
                                        (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                            if (codevalue__goto_772_14 == 96):
                                                (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 2)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                    if __goto_pending != 0:
                                        break
                            85 =>
                                if (clen__goto_718_7 > 0):
                                    if ((((((d__goto_719_15 == 12) and ((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject)) and (((mb.moptions & (32))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                        (partial_newline__goto_720_8 = 1)
                                        (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                            if (codevalue__goto_772_14 == 94):
                                                (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                    if __goto_pending != 0:
                                        break
                            93 =>
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    if ((((((d__goto_719_15 == 12) and ((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject)) and (((mb.moptions & (32))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                        (partial_newline__goto_720_8 = 1)
                                        (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                            if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = ((((state_offset__goto_773_9 + 1) + 2) + 1)))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (0))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                    if __goto_pending != 0:
                                        break
                            91 =>
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    if ((((((d__goto_719_15 == 12) and ((ptr__goto_561_12 + (1 as isize as usize)) >= mb.end_subject)) and (((mb.moptions & (32))) != 0)) and (mb.nltype == 0)) and (mb.nllen == 2)) and (c__goto_719_12 == (&mb.nl[0] as *mut u8)[0])):
                                        (partial_newline__goto_720_8 = 1)
                                        (could_continue__goto_721_8 = partial_newline__goto_720_8)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                            if (codevalue__goto_772_14 == 97):
                                                (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                            if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = (((state_offset__goto_773_9 + 2) + 2)))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (0))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                    if __goto_pending != 0:
                                        break
                            427 =>
                                if (count__goto_775_9 > 0):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if (clen__goto_718_7 > 0):
                                    ncount__goto_1606_13 = 0
                                    if __goto_pending != 0:
                                        break
                                    match c__goto_719_12
                                        11 =>
                                            __pc = 1
                                            __goto_pending = 1
                                        13 =>
                                            if (((ptr__goto_561_12 + (1 as isize as usize)) < end_subject__goto_570_12) and (ptr__goto_561_12[1] == 10)):
                                                (ncount__goto_1606_13 = 1)
                                            (count__goto_775_9 = count__goto_775_9 + 1)
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - state_offset__goto_773_9)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = (ncount__goto_1606_13))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                        _ => 0
                                    if __goto_pending != 0:
                                        break
                            467 =>
                                if (count__goto_775_9 > 0):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        10 => 0
                                        _ =>
                                            (OK__goto_1648_14 = 0)
                                    if __goto_pending != 0:
                                        break
                                    if (OK__goto_1648_14 == ((if d__goto_719_15 == 21: 1 else: 0))):
                                        if ((count__goto_775_9 > 0) and (codevalue__goto_772_14 == 475)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (count__goto_775_9 = count__goto_775_9 + 1)
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = ((0 - state_offset__goto_773_9)))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (count__goto_775_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.data = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            447 =>
                                if (count__goto_775_9 > 0):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        9 => 0
                                        _ =>
                                            (OK__goto_1681_14 = 0)
                                    if __goto_pending != 0:
                                        break
                                    if (OK__goto_1681_14 == ((if d__goto_719_15 == 19: 1 else: 0))):
                                        if ((count__goto_775_9 > 0) and (codevalue__goto_772_14 == 455)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (count__goto_775_9 = count__goto_775_9 + 1)
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = ((0 - state_offset__goto_773_9)))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (count__goto_775_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.data = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            429 =>
                                __pc = 2
                                __goto_pending = 1
                            425 =>
                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                    (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13.count = (0))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                                if (clen__goto_718_7 > 0):
                                    ncount__goto_1884_13 = 0
                                    if __goto_pending != 0:
                                        break
                                    match c__goto_719_12
                                        11 =>
                                            __pc = 3
                                            __goto_pending = 1
                                        13 =>
                                            if (((ptr__goto_561_12 + (1 as isize as usize)) < end_subject__goto_570_12) and (ptr__goto_561_12[1] == 10)):
                                                (ncount__goto_1884_13 = 1)
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - ((state_offset__goto_773_9 + (count__goto_775_9 as c_int))))))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = (ncount__goto_1884_13))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                        _ => 0
                                    if __goto_pending != 0:
                                        break
                            469 =>
                                __pc = 4
                                __goto_pending = 1
                            465 =>
                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                    (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13.count = (0))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        10 => 0
                                        _ =>
                                            (OK__goto_1934_14 = 0)
                                    if __goto_pending != 0:
                                        break
                                    if (OK__goto_1934_14 == ((if d__goto_719_15 == 21: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 474) or (codevalue__goto_772_14 == 476)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = ((0 - ((state_offset__goto_773_9 + (count__goto_775_9 as c_int))))))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.data = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            449 =>
                                __pc = 5
                                __goto_pending = 1
                            445 =>
                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                    (next_active_state__goto_559_13.offset = ((state_offset__goto_773_9 + 2)))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13.count = (0))
                                    if __goto_pending != 0:
                                        break
                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                    if __goto_pending != 0:
                                        break
                                else:
                                    return (-43)
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        9 => 0
                                        _ =>
                                            (OK__goto_1974_14 = 0)
                                    if __goto_pending != 0:
                                        break
                                    if (OK__goto_1974_14 == ((if d__goto_719_15 == 19: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 454) or (codevalue__goto_772_14 == 456)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = ((0 - ((state_offset__goto_773_9 + (count__goto_775_9 as c_int))))))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.data = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            433 =>
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    ncount__goto_2165_13 = 0
                                    if __goto_pending != 0:
                                        break
                                    match c__goto_719_12
                                        11 =>
                                            __pc = 6
                                            __goto_pending = 1
                                        13 =>
                                            if (((ptr__goto_561_12 + (1 as isize as usize)) < end_subject__goto_570_12) and (ptr__goto_561_12[1] == 10)):
                                                (ncount__goto_2165_13 = 1)
                                            if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = ((0 - (((state_offset__goto_773_9 + 2) + 2)))))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (0))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.data = (ncount__goto_2165_13))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = ((0 - state_offset__goto_773_9)))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.data = (ncount__goto_2165_13))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                        _ => 0
                                    if __goto_pending != 0:
                                        break
                            473 =>
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        10 => 0
                                        _ =>
                                            (OK__goto_2211_14 = 0)
                                    if __goto_pending != 0:
                                        break
                                    if (OK__goto_2211_14 == ((if d__goto_719_15 == 21: 1 else: 0))):
                                        if (codevalue__goto_772_14 == 477):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - (((state_offset__goto_773_9 + 2) + 2)))))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - state_offset__goto_773_9)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            453 =>
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        9 => 0
                                        _ =>
                                            (OK__goto_2247_14 = 0)
                                    if __goto_pending != 0:
                                        break
                                    if (OK__goto_2247_14 == ((if d__goto_719_15 == 19: 1 else: 0))):
                                        if (codevalue__goto_772_14 == 457):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - (((state_offset__goto_773_9 + 2) + 2)))))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - state_offset__goto_773_9)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            29 =>
                                if ((clen__goto_718_7 > 0) and (c__goto_719_12 == d__goto_719_15)):
                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                        (next_new_state__goto_559_33.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            30 =>
                                if (clen__goto_718_7 == 0):
                                    break
                                if (((lcc__goto_560_25)[c__goto_719_12]) == ((lcc__goto_560_25)[d__goto_719_15])):
                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                        (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 2)))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                            17 =>
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        11 =>
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                        10 =>
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                        13 =>
                                            if ((ptr__goto_561_12 + (1 as isize as usize)) >= end_subject__goto_570_12):
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (0))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                                if (((mb.moptions & 32)) != 0):
                                                    (reset_could_continue__goto_580_6 = 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                if (ptr__goto_561_12[1] == 10):
                                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                        (next_new_state__goto_559_33.offset = ((0 - ((state_offset__goto_773_9 + 1)))))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.count = (0))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.data = (1))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        return (-43)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                        (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33.count = (0))
                                                        if __goto_pending != 0:
                                                            break
                                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                        if __goto_pending != 0:
                                                            break
                                                    else:
                                                        return (-43)
                                                    if __goto_pending != 0:
                                                        break
                                        _ => 0
                            20 =>
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        10 =>
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                        _ =>
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                            21 =>
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        10 => 0
                                        _ => 0
                            18 =>
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        9 =>
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                        _ =>
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((state_offset__goto_773_9 + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                            19 =>
                                if (clen__goto_718_7 > 0):
                                    match c__goto_719_12
                                        9 => 0
                                        _ => 0
                            31 =>
                                if ((clen__goto_718_7 > 0) and (c__goto_719_12 != d__goto_719_15)):
                                    if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                        (next_new_state__goto_559_33.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                            32 =>
                                if (clen__goto_718_7 > 0):
                                    (otherd__goto_2437_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                    if __goto_pending != 0:
                                        break
                                    if ((c__goto_719_12 != d__goto_719_15) and (c__goto_719_12 != otherd__goto_2437_18)):
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            48 =>
                                codevalue__goto_772_14 = codevalue__goto_772_14 - 13
                                if (count__goto_775_9 > 0):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2470_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2470_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2470_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((count__goto_775_9 > 0) and ((codevalue__goto_772_14 == 43) or (codevalue__goto_772_14 == 69))):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (count__goto_775_9 = count__goto_775_9 + 1)
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (count__goto_775_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            35 =>
                                if (count__goto_775_9 > 0):
                                    if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                        (next_active_state__goto_559_13.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13.count = (0))
                                        if __goto_pending != 0:
                                            break
                                        (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        return (-43)
                                    if __goto_pending != 0:
                                        break
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2470_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2470_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2470_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((count__goto_775_9 > 0) and ((codevalue__goto_772_14 == 43) or (codevalue__goto_772_14 == 69))):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        (count__goto_775_9 = count__goto_775_9 + 1)
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (count__goto_775_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            50 =>
                                codevalue__goto_772_14 = codevalue__goto_772_14 - 13
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2513_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2513_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2513_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 44) or (codevalue__goto_772_14 == 70)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            37 =>
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2513_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2513_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2513_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 44) or (codevalue__goto_772_14 == 70)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (((state_offset__goto_773_9 + dlen__goto_718_13) + 1)))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            46 =>
                                codevalue__goto_772_14 = codevalue__goto_772_14 - 13
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2554_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2554_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2554_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 42) or (codevalue__goto_772_14 == 68)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            33 =>
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2554_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2554_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2554_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 42) or (codevalue__goto_772_14 == 68)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                            (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            54 =>
                                codevalue__goto_772_14 = codevalue__goto_772_14 - 13
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2587_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2587_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2587_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((((state_offset__goto_773_9 + dlen__goto_718_13) + 1) + 2)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            41 =>
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2587_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2587_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2587_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((((state_offset__goto_773_9 + dlen__goto_718_13) + 1) + 2)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            52 =>
                                codevalue__goto_772_14 = codevalue__goto_772_14 - 13
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2627_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2627_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2627_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 45) or (codevalue__goto_772_14 == 71)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((((state_offset__goto_773_9 + dlen__goto_718_13) + 1) + 2)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            39 =>
                                (count__goto_775_9 = current_state__goto_769_17.count)
                                if (clen__goto_718_7 > 0):
                                    otherd__goto_2627_18 = 4294967295
                                    if __goto_pending != 0:
                                        break
                                    if (caseless__goto_770_10 != 0):
                                        (otherd__goto_2627_18 = ((fcc__goto_560_31)[d__goto_719_15]))
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                    if (((if (c__goto_719_12 == d__goto_719_15) or (c__goto_719_12 == otherd__goto_2627_18): 1 else: 0)) == ((if codevalue__goto_772_14 < 59: 1 else: 0))):
                                        if ((codevalue__goto_772_14 == 45) or (codevalue__goto_772_14 == 71)):
                                            (active_count__goto_564_5 = active_count__goto_564_5 - 1)
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 - 1)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        if ((count__goto_775_9 = count__goto_775_9 + 1) >= (((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint) as c_int)):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((((state_offset__goto_773_9 + dlen__goto_718_13) + 1) + 2)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (state_offset__goto_773_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (count__goto_775_9))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                            110 => 0
                            165 => 0
                            128 => 0
                            141 => 0
                            118 =>
                                rws__goto_2953_21 = (RWS as *mut RWS_anchor)
                                if __goto_pending != 0:
                                    break
                                callpat__goto_2954_20 = (start_code__goto_571_12 + ((((((((code__goto_771_16)[1] as c_uint) << 8))) | (code__goto_771_16)[((1) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                recno__goto_2955_18 = (if (callpat__goto_2954_20 == mb.start_code): 0 else: ((((((((callpat__goto_2954_20)[(1 + 2)] as c_uint) << 8))) | (callpat__goto_2954_20)[(((1 + 2)) + 1)])) as c_uint))
                                if __goto_pending != 0:
                                    break
                                if (code__goto_771_16[(1 + 2)] == OP_CREF):
                                    return (-42)
                                if __goto_pending != 0:
                                    break
                                (local_offsets__goto_2952_21 = ((((RWS + rws__goto_2953_21.size) - rws__goto_2953_21.free)) as *mut c_ulong))
                                if __goto_pending != 0:
                                    break
                                ri__goto_2976_34 = mb.recursive
                                while (ri__goto_2976_34 != (null as *mut dfa_recursion_info)):
                                    if (((recno__goto_2955_18 == ri__goto_2976_34.group_num) and (ptr__goto_561_12 == ri__goto_2976_34.subject_position)) and (mb.last_used_ptr == ri__goto_2976_34.last_used_ptr)):
                                        return (-52)
                                    if __goto_pending != 0:
                                        break
                                    (ri__goto_2976_34 = ri__goto_2976_34.prevrec)
                                    if __goto_pending != 0:
                                        break
                                if __goto_pending != 0:
                                    break
                                (new_recursive__goto_563_20.group_num = recno__goto_2955_18)
                                if __goto_pending != 0:
                                    break
                                (new_recursive__goto_563_20.subject_position = ptr__goto_561_12)
                                if __goto_pending != 0:
                                    break
                                (new_recursive__goto_563_20.last_used_ptr = mb.last_used_ptr)
                                if __goto_pending != 0:
                                    break
                                (new_recursive__goto_563_20.prevrec = mb.recursive)
                                if __goto_pending != 0:
                                    break
                                (mb.recursive = ((&new_recursive__goto_563_20 as *const dfa_recursion_info) as *mut dfa_recursion_info))
                                if __goto_pending != 0:
                                    break
                                (rc__goto_2950_13 = internal_dfa_match(mb, callpat__goto_2954_20, ptr__goto_561_12, ((((ptr__goto_561_12 as usize -% start_subject__goto_569_12 as usize) / sizeof[u8]())) as c_ulong), local_offsets__goto_2952_21, 1000, local_workspace__goto_2951_14, 1000, rlevel, RWS))
                                if __goto_pending != 0:
                                    break
                                (mb.recursive = new_recursive__goto_563_20.prevrec)
                                if __goto_pending != 0:
                                    break
                                if (rc__goto_2950_13 == 0):
                                    return (-39)
                                if __goto_pending != 0:
                                    break
                                if (rc__goto_2950_13 > 0):
                                    (rc__goto_2950_13 = ((rc__goto_2950_13 * 2) - 2))
                                    while (rc__goto_2950_13 >= 0):
                                        charcount__goto_3021_24 = (local_offsets__goto_2952_21[(rc__goto_2950_13 + 1)] -% local_offsets__goto_2952_21[rc__goto_2950_13])
                                        if __goto_pending != 0:
                                            break
                                        if (charcount__goto_3021_24 > 0):
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - (((state_offset__goto_773_9 + 2) + 1)))))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = ((((charcount__goto_3021_24 -% 1)) as c_int)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                                (next_active_state__goto_559_13.offset = (((state_offset__goto_773_9 + 2) + 1)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                        if __goto_pending != 0:
                                            break
                                        rc__goto_2950_13 = rc__goto_2950_13 - 2
                                        if __goto_pending != 0:
                                            break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_2950_13 != ((0 -% 1))):
                                        return rc__goto_2950_13
                                if __goto_pending != 0:
                                    break
                            138 => 0
                            135 =>
                                rws__goto_3157_21 = (RWS as *mut RWS_anchor)
                                if __goto_pending != 0:
                                    break
                                (local_offsets__goto_3156_21 = ((((RWS + rws__goto_3157_21.size) - rws__goto_3157_21.free)) as *mut c_ulong))
                                if __goto_pending != 0:
                                    break
                                (rc__goto_3154_13 = internal_dfa_match(mb, code__goto_771_16, ptr__goto_561_12, ((((ptr__goto_561_12 as usize -% start_subject__goto_569_12 as usize) / sizeof[u8]())) as c_ulong), local_offsets__goto_3156_21, 2, local_workspace__goto_3155_14, 1000, rlevel, RWS))
                                if __goto_pending != 0:
                                    break
                                if (rc__goto_3154_13 >= 0):
                                    end_subpattern__goto_3186_22 = code__goto_771_16
                                    if __goto_pending != 0:
                                        break
                                    charcount__goto_3187_22 = (local_offsets__goto_3156_21[1] -% local_offsets__goto_3156_21[0])
                                    if __goto_pending != 0:
                                        break
                                    while true:
                                        end_subpattern__goto_3186_22 = end_subpattern__goto_3186_22 + ((((((((end_subpattern__goto_3186_22)[1] as c_uint) << 8))) | (end_subpattern__goto_3186_22)[((1) + 1)])) as c_uint)
                                        if __goto_pending != 0:
                                            break
                                        if __goto_pending != 0:
                                            break
                                        if not (((unsafe: *end_subpattern__goto_3186_22) == OP_ALT)):
                                            break
                                    if __goto_pending != 0:
                                        break
                                    (next_state_offset__goto_3188_15 = ((((((end_subpattern__goto_3186_22 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) + 2) + 1)) as c_int))
                                    if __goto_pending != 0:
                                        break
                                    (repeat_state_offset__goto_3188_34 = (if (((unsafe: *end_subpattern__goto_3186_22) == OP_KETRMAX) or ((unsafe: *end_subpattern__goto_3186_22) == OP_KETRMIN)): (((((end_subpattern__goto_3186_22 as usize -% start_code__goto_571_12 as usize) / sizeof[u8]()) - ((((((((end_subpattern__goto_3186_22)[1] as c_uint) << 8))) | (end_subpattern__goto_3186_22)[((1) + 1)])) as c_uint))) as c_int) else: -1))
                                    if __goto_pending != 0:
                                        break
                                    if (charcount__goto_3187_22 == 0):
                                        if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                            (next_active_state__goto_559_13.offset = (next_state_offset__goto_3188_15))
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13.count = (0))
                                            if __goto_pending != 0:
                                                break
                                            (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            return (-43)
                                        if __goto_pending != 0:
                                            break
                                    else:
                                        if (((i__goto_717_7 + 1) >= active_count__goto_564_5) and (new_count__goto_564_19 == 0)):
                                            ptr__goto_561_12 = ptr__goto_561_12 + charcount__goto_3187_22
                                            if __goto_pending != 0:
                                                break
                                            (clen__goto_718_7 = 0)
                                            if __goto_pending != 0:
                                                break
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = (next_state_offset__goto_3188_15))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                            if (repeat_state_offset__goto_3188_34 >= 0):
                                                (next_active_state__goto_559_13 = active_states__goto_558_13)
                                                if __goto_pending != 0:
                                                    break
                                                (active_count__goto_564_5 = 0)
                                                if __goto_pending != 0:
                                                    break
                                                (i__goto_717_7 = -1)
                                                if __goto_pending != 0:
                                                    break
                                                if ((active_count__goto_564_5 = active_count__goto_564_5 + 1) < wscount):
                                                    (next_active_state__goto_559_13.offset = (repeat_state_offset__goto_3188_34))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_active_state__goto_559_13.count = (0))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_active_state__goto_559_13 = next_active_state__goto_559_13 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                        else:
                                            if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                (next_new_state__goto_559_33.offset = ((0 - next_state_offset__goto_3188_15)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.count = (0))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33.data = ((((charcount__goto_3187_22 -% 1)) as c_int)))
                                                if __goto_pending != 0:
                                                    break
                                                (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                if __goto_pending != 0:
                                                    break
                                            else:
                                                return (-43)
                                            if __goto_pending != 0:
                                                break
                                            if (repeat_state_offset__goto_3188_34 >= 0):
                                                if ((new_count__goto_564_19 = new_count__goto_564_19 + 1) < wscount):
                                                    (next_new_state__goto_559_33.offset = ((0 - repeat_state_offset__goto_3188_34)))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.count = (0))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33.data = ((((charcount__goto_3187_22 -% 1)) as c_int)))
                                                    if __goto_pending != 0:
                                                        break
                                                    (next_new_state__goto_559_33 = next_new_state__goto_559_33 + 1)
                                                    if __goto_pending != 0:
                                                        break
                                                else:
                                                    return (-43)
                                                if __goto_pending != 0:
                                                    break
                                            if __goto_pending != 0:
                                                break
                                    if __goto_pending != 0:
                                        break
                                else:
                                    if (rc__goto_3154_13 != ((0 -% 1))):
                                        return rc__goto_3154_13
                                if __goto_pending != 0:
                                    break
                            119 => 0
                            _ =>
                                return (-42)
                        if __goto_pending != 0:
                            break
                        continue
                        if __goto_pending != 0:
                            break
                        (i__goto_717_7 = i__goto_717_7 + 1)
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    if (new_count__goto_564_19 <= 0):
                        if (((could_continue__goto_721_8 != 0) and ((((mb.moptions & 32)) != 0) or ((((mb.moptions & 16)) != 0) and (match_count__goto_564_30 < 0)))) and ((partial_newline__goto_720_8 != 0) or ((ptr__goto_561_12 >= end_subject__goto_570_12) and ((ptr__goto_561_12 > mb.start_used_ptr) or (mb.allowemptypartial != 0))))):
                            (match_count__goto_564_30 = (-2))
                        if __goto_pending != 0:
                            break
                        break
                        if __goto_pending != 0:
                            break
                    if __goto_pending != 0:
                        break
                    ptr__goto_561_12 = ptr__goto_561_12 + clen__goto_718_7
                    if __goto_pending != 0:
                        break
                    if __goto_pending != 0:
                        break
                if __goto_pending != 0:
                    continue
                if (((match_count__goto_564_30 >= 0) and (((((mb.moptions | mb.poptions)) & 536870912)) != 0)) and (ptr__goto_561_12 < end_subject__goto_570_12)):
                    (match_count__goto_564_30 = ((0 -% 1)))
                if __goto_pending != 0:
                    continue
                return match_count__goto_564_30
                if __goto_pending != 0:
                    continue
            _ => break

