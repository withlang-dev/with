// Migrated from PCRE2
use std.re.defs

type BOOL = c_int
extern fn imaxabs(j: c_long) -> c_long
type imaxdiv_t { quot: c_long = 0, rem: c_long = 0 }
type struct_imaxdiv_t = imaxdiv_t
extern fn imaxdiv(__numer: c_long, __denom: c_long) -> imaxdiv_t
extern fn strtoimax(__nptr: *const i8, __endptr: *mut *mut i8, __base: c_int) -> c_long
extern fn strtoumax(__nptr: *const i8, __endptr: *mut *mut i8, __base: c_int) -> c_ulong
extern fn wcstoimax(__nptr: *const c_int, __endptr: *mut *mut c_int, __base: c_int) -> c_long
extern fn wcstoumax(__nptr: *const c_int, __endptr: *mut *mut c_int, __base: c_int) -> c_ulong
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
type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong, ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
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
@[c_export("pcre2_match_8")]
fn pcre2_match_8(code: *const pcre2_real_code_8, subject: *const u8, length: c_ulong, start_offset: c_ulong, options: c_uint, match_data: *mut pcre2_real_match_data_8, mcontext: *mut pcre2_real_match_context_8) -> c_int:
    var subject = subject
    var length = length
    var options = options
    var mcontext = mcontext
    var rc: c_int = 0
    var start_bits: *const u8 = null
    var re: *const pcre2_real_code_8 = null
    var original_options: c_uint = 0
    var anchored: c_int = 0
    var firstline: c_int = 0
    var has_first_cu: c_int = 0
    var has_req_cu: c_int = 0
    var startline: c_int = 0
    var memchr_found_first_cu: *const u8 = null
    var memchr_found_first_cu2: *const u8 = null
    var first_cu: u8 = 0
    var first_cu2: u8 = 0
    var req_cu: u8 = 0
    var req_cu2: u8 = 0
    var original_subject: *const u8 = null
    var bumpalong_limit: *const u8 = null
    var end_subject: *const u8 = null
    var true_end_subject: *const u8 = null
    var start_match: *const u8 = null
    var req_cu_ptr: *const u8 = null
    var start_partial: *const u8 = null
    var match_partial: *const u8 = null
    var utf: c_int = 0
    var frame_size: c_ulong = 0
    var heapframes_size: c_ulong = 0
    var mb: *mut match_block_8 = null
    var max_size: c_ulong = 0
    var new_start_match: *const u8 = null
    var t: *const u8 = null
    var ok: c_int = 0
    var c: u8 = 0
    var pp1: *const u8 = null
    var pp2: *const u8 = null
    var searchlength: c_ulong = 0
    var p: *const u8 = null
    var check_length: c_ulong = 0
    var pp: *const u8 = null
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                if (if (if subject == null: 1 else: 0) != 0 and (if length == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (subject = null_str)

                (start_match = (subject + start_offset))
                (req_cu_ptr = (start_match - (1 as isize as usize)))
                (true_end_subject = (end_subject = (subject + length)))
                (mb.partial = (if ((if ((options & 32)) != 0: 1 else: 0)) != 0: 2 else: (if ((if ((options & 16)) != 0: 1 else: 0)) != 0: 1 else: 0)))
                if (if ((match_data.flags & 1)) != 0: 1 else: 0) != 0:
                    match_data.memctl.free((match_data.subject as *mut c_void), match_data.memctl.memory_data)
                    match_data.flags = match_data.flags & (0 - 1 - 1)

                (match_data.subject = null)
                (match_data.startchar = 0)
                (mb.check_subject = subject)
                if (if mcontext == null: 1 else: 0) != 0:
                    (mb.memctl = re.memctl)
                else:
                    (mb.memctl = mcontext.memctl)

                (anchored = (if ((((re.overall_options | options)) & 2147483648)) != 0: 1 else: 0))
                (firstline = (if (not anchored) != 0 and (if ((re.overall_options & 256)) != 0: 1 else: 0) != 0: 1 else: 0))
                (startline = (if ((re.flags & 512)) != 0: 1 else: 0))
                (mb.cb = &cb)
                (cb.version = 2)
                (cb.subject = subject)
                (cb.callout_flags = 0)
                (mb.callout = mcontext.callout)
                (mb.callout_data = mcontext.callout_data)
                (mb.start_subject = subject)
                (mb.start_offset = start_offset)
                (mb.end_subject = end_subject)
                (mb.true_end_subject = true_end_subject)
                (mb.hasthen = (if ((re.flags & 4096)) != 0: 1 else: 0))
                (mb.hasbsk = (if ((re.flags & 16777216)) != 0: 1 else: 0))
                (mb.allowemptypartial = (if ((if re.max_lookbehind > 0: 1 else: 0)) != 0 or (if ((re.flags & 8192)) != 0: 1 else: 0) != 0: 1 else: 0))
                (mb.allowlookaroundbsk = (if ((re.extra_options & 64)) != 0: 1 else: 0))
                (mb.poptions = re.overall_options)
                (mb.ignore_skip_arg = 0)
                (mb.mark = (mb.nomatch_mark = null))
                (mb.name_count = re.name_count)
                (mb.name_entry_size = re.name_entry_size)
                (mb.bsr_convention = re.bsr_convention)
                (mb.nltype = 0)
                match re.newline_convention
                    1 =>
                        (mb.nllen = 1)
                        (mb.nl[0] = 13)
                    2 =>
                        (mb.nllen = 1)
                        (mb.nl[0] = 10)
                    6 =>
                        (mb.nllen = 1)
                        (mb.nl[0] = 0)
                    3 =>
                        (mb.nllen = 2)
                        (mb.nl[0] = 13)
                        (mb.nl[1] = 10)
                    4 =>
                        (mb.nltype = 1)
                    5 =>
                        (mb.nltype = 2)
                    _ => 0

                (frame_size = (((((120 +% ((re.top_bracket * 2) *% sizeof[c_ulong]())) +% 8) -% 1)) & (0 - ((8 -% 1)) - 1)))
                (mb.heap_limit = ((if ((if mcontext.heap_limit < re.limit_heap: 1 else: 0)) != 0: mcontext.heap_limit else: re.limit_heap)))
                (mb.match_limit = (if ((if mcontext.match_limit < re.limit_match: 1 else: 0)) != 0: mcontext.match_limit else: re.limit_match))
                (mb.match_limit_depth = (if ((if mcontext.depth_limit < re.limit_depth: 1 else: 0)) != 0: mcontext.depth_limit else: re.limit_depth))
                (heapframes_size = (frame_size *% 10))
                if (if heapframes_size < 20480: 1 else: 0) != 0:
                    (heapframes_size = 20480)

                if (if (heapframes_size / 1024) > mb.heap_limit: 1 else: 0) != 0:
                    var max_size: c_ulong = 0 // init failed
                    (heapframes_size = max_size)

                if (if match_data.heapframes_size < heapframes_size: 1 else: 0) != 0:
                    match_data.memctl.free(match_data.heapframes, match_data.memctl.memory_data)
                    (match_data.heapframes = match_data.memctl.malloc(heapframes_size, match_data.memctl.memory_data))
                    if (if match_data.heapframes == null: 1 else: 0) != 0:
                        (match_data.heapframes_size = 0)

                    (match_data.heapframes_size = heapframes_size)

                with_memset((((match_data.heapframes) as *mut i8) + 120) as *i8, 255, (frame_size -% 120) as i64)
                (mb.lcc = (re.tables + (0 as isize as usize)))
                (mb.fcc = (re.tables + (256 as isize as usize)))
                if (if ((re.flags & 16)) != 0: 1 else: 0) != 0:
                    (has_first_cu = 1)
                    if (if ((re.flags & 32)) != 0: 1 else: 0) != 0:
                        (first_cu2 = ((mb.fcc)[first_cu]))

                else:
                    if (if (not startline) != 0 and (if ((re.flags & 64)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        (start_bits = re.start_bitmap)


                if (if ((re.flags & 128)) != 0: 1 else: 0) != 0:
                    (has_req_cu = 1)
                    if (if ((re.flags & 256)) != 0: 1 else: 0) != 0:
                        (req_cu2 = ((mb.fcc)[req_cu]))


                (start_partial = (match_partial = null))
                (mb.hitend = 0)
                (memchr_found_first_cu = null)
                (memchr_found_first_cu2 = null)
                while true:
                    var new_start_match: *const u8 = null // init: untranslatable
                    if (if ((re.optimization_flags & 4)) != 0: 1 else: 0) != 0:
                        if firstline != 0:
                            var t: *const u8 = null // init: untranslatable
                            (end_subject = t)

                        if anchored != 0:
                            if (if has_first_cu != 0 or (if start_bits != null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var ok: c_int = 0 // init: untranslatable
                                if ok != 0:
                                    var c: u8 = 0 // init: untranslatable
                                    (ok = (if has_first_cu != 0 and ((if (if c == first_cu: 1 else: 0) != 0 or (if c == first_cu2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0))
                                    if (if (not ok) != 0 and (if start_bits != null: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (ok = (if ((start_bits[(c / 8)] & ((1 << ((c & 7)))))) != 0: 1 else: 0))


                                if (not ok) != 0:
                                    (rc = 0)
                                    break


                        else:
                            if has_first_cu != 0:
                                if (if first_cu != first_cu2: 1 else: 0) != 0:
                                    var pp1: *const u8 = null // init: untranslatable
                                    var pp2: *const u8 = null // init: untranslatable
                                    var searchlength: c_ulong = 0 // init: untranslatable
                                    if (if (if memchr_found_first_cu == null: 1 else: 0) != 0 or (if start_match > memchr_found_first_cu: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (pp1 = memchr(start_match, first_cu, searchlength))
                                        (memchr_found_first_cu = (if ((if pp1 == null: 1 else: 0)) != 0: end_subject else: pp1))
                                    else:
                                        (pp1 = (if ((if memchr_found_first_cu == end_subject: 1 else: 0)) != 0: null else: memchr_found_first_cu))

                                    if (if (if memchr_found_first_cu2 == null: 1 else: 0) != 0 or (if start_match > memchr_found_first_cu2: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (pp2 = memchr(start_match, first_cu2, searchlength))
                                        (memchr_found_first_cu2 = (if ((if pp2 == null: 1 else: 0)) != 0: end_subject else: pp2))
                                    else:
                                        (pp2 = (if ((if memchr_found_first_cu2 == end_subject: 1 else: 0)) != 0: null else: memchr_found_first_cu2))

                                    if (if pp1 == null: 1 else: 0) != 0:
                                        (start_match = (if ((if pp2 == null: 1 else: 0)) != 0: end_subject else: pp2))
                                    else:
                                        (start_match = (if ((if (if pp2 == null: 1 else: 0) != 0 or (if pp1 < pp2: 1 else: 0) != 0: 1 else: 0)) != 0: pp1 else: pp2))

                                else:
                                    (start_match = memchr(start_match, first_cu, ((end_subject as usize -% start_match as usize) / sizeof[u8]())))
                                    if (if start_match == null: 1 else: 0) != 0:
                                        (start_match = end_subject)


                                if (if (if mb.partial == 0: 1 else: 0) != 0 and (if start_match >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (rc = 0)
                                    break

                            else:
                                if startline != 0:
                                    if (if start_match > (mb.start_subject + start_offset): 1 else: 0) != 0:
                                        if (if (if (if (if start_match[(0 - 1)] == 13: 1 else: 0) != 0 and ((if (if mb.nltype == 1: 1 else: 0) != 0 or (if mb.nltype == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and (if start_match < end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *start_match == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (start_match = start_match + 1)


                                else:
                                    if (if start_bits != null: 1 else: 0) != 0:
                                        while (if start_match < end_subject: 1 else: 0) != 0:
                                            var c: c_uint = 0 // init: untranslatable
                                            if (if ((start_bits[(c / 8)] & ((1 << ((c & 7)))))) != 0: 1 else: 0) != 0:
                                                break

                                            (start_match = start_match + 1)

                                        if (if (if mb.partial == 0: 1 else: 0) != 0 and (if start_match >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (rc = 0)
                                            break





                        (end_subject = mb.end_subject)
                        if (if mb.partial == 0: 1 else: 0) != 0:
                            var p: *const u8 = null // init: untranslatable
                            if (if ((end_subject as usize -% start_match as usize) / sizeof[u8]()) < re.minlength: 1 else: 0) != 0:
                                (rc = 0)
                                break

                            (p = (start_match + (((if has_first_cu != 0: 1 else: 0)) as isize as usize)))
                            if (if has_req_cu != 0 and (if p > req_cu_ptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                var check_length: c_ulong = 0 // init: untranslatable
                                if (if (if check_length < 5000: 1 else: 0) != 0 or ((if (not anchored) != 0 and (if check_length < 5000000: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    if (if req_cu != req_cu2: 1 else: 0) != 0:
                                        var pp: *const u8 = null // init: untranslatable
                                        (p = memchr(pp, req_cu, ((end_subject as usize -% pp as usize) / sizeof[u8]())))
                                        if (if p == null: 1 else: 0) != 0:
                                            (p = memchr(pp, req_cu2, ((end_subject as usize -% pp as usize) / sizeof[u8]())))
                                            if (if p == null: 1 else: 0) != 0:
                                                (p = end_subject)


                                    else:
                                        (p = memchr(p, req_cu, ((end_subject as usize -% p as usize) / sizeof[u8]())))
                                        if (if p == null: 1 else: 0) != 0:
                                            (p = end_subject)


                                    if (if p >= end_subject: 1 else: 0) != 0:
                                        (rc = 0)
                                        break

                                    (req_cu_ptr = p)




                    if (if start_match > bumpalong_limit: 1 else: 0) != 0:
                        (rc = 0)
                        break

                    cb.callout_flags = cb.callout_flags | 1
                    (mb.start_used_ptr = start_match)
                    (mb.last_used_ptr = start_match)
                    (mb.moptions = options)
                    (mb.match_call_count = 0)
                    (mb.end_offset_top = 0)
                    (mb.skip_arg_count = 0)
                    (rc = match_(start_match, mb.start_code, re.top_bracket, frame_size, match_data, mb))
                    if (if mb.hitend != 0 and (if start_partial == null: 1 else: 0) != 0: 1 else: 0) != 0:
                        (start_partial = mb.start_used_ptr)
                        (match_partial = start_match)

                    match rc
                        0 =>
                            (new_start_match = (start_match + (1 as isize as usize)))
                        _ =>
                            comptime_error("goto not supported")

                    (rc = 0)
                    (start_match = new_start_match)
                    if (if anchored != 0 or (if start_match > end_subject: 1 else: 0) != 0: 1 else: 0) != 0:
                        break

                    if (if (if (if (if (if (if start_match > (subject + start_offset): 1 else: 0) != 0 and (if start_match[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0 and (if start_match < end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *start_match == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((re.flags & 2048)) == 0: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if (if mb.nltype == 1: 1 else: 0) != 0 or (if mb.nltype == 2: 1 else: 0) != 0: 1 else: 0) != 0 or (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (start_match = start_match + 1)

                    (mb.mark = null)

                __pc = 1
                continue
            1 =>  // ENDLOOP
                (match_data.code = re)
                (match_data.mark = mb.mark)
                (match_data.matchedby = 0)
                (match_data.options = original_options)
                if (if rc == 1: 1 else: 0) != 0:
                    (match_data.rc = (if ((if (mb.end_offset_top as c_int) >= (2 * match_data.oveccount): 1 else: 0)) != 0: 0 else: (((mb.end_offset_top as c_int) / 2) + 1)))
                    (match_data.subject_length = length)
                    (match_data.start_offset = start_offset)
                    (match_data.startchar = ((start_match as usize -% subject as usize) / sizeof[u8]()))
                    (match_data.leftchar = ((mb.start_used_ptr as usize -% subject as usize) / sizeof[u8]()))
                    (match_data.rightchar = ((((if ((if mb.last_used_ptr > mb.end_match_ptr: 1 else: 0)) != 0: mb.last_used_ptr else: mb.end_match_ptr)) as usize -% subject as usize) / sizeof[u8]()))
                    if (if ((options & 16384)) != 0: 1 else: 0) != 0:
                        match_data.flags = match_data.flags | 1
                    else:
                        (match_data.subject = original_subject)

                    return match_data.rc

                (match_data.mark = mb.nomatch_mark)
                return match_data.rc
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
let ucp_C: c_uint = 0
let ucp_L: c_uint = 1
let ucp_M: c_uint = 2
let ucp_N: c_uint = 3
let ucp_P: c_uint = 4
let ucp_S: c_uint = 5
let ucp_Z: c_uint = 6
let ucp_Cc: c_uint = 0
let ucp_Cf: c_uint = 1
let ucp_Cn: c_uint = 2
let ucp_Co: c_uint = 3
let ucp_Cs: c_uint = 4
let ucp_Ll: c_uint = 5
let ucp_Lm: c_uint = 6
let ucp_Lo: c_uint = 7
let ucp_Lt: c_uint = 8
let ucp_Lu: c_uint = 9
let ucp_Mc: c_uint = 10
let ucp_Me: c_uint = 11
let ucp_Mn: c_uint = 12
let ucp_Nd: c_uint = 13
let ucp_Nl: c_uint = 14
let ucp_No: c_uint = 15
let ucp_Pc: c_uint = 16
let ucp_Pd: c_uint = 17
let ucp_Pe: c_uint = 18
let ucp_Pf: c_uint = 19
let ucp_Pi: c_uint = 20
let ucp_Po: c_uint = 21
let ucp_Ps: c_uint = 22
let ucp_Sc: c_uint = 23
let ucp_Sk: c_uint = 24
let ucp_Sm: c_uint = 25
let ucp_So: c_uint = 26
let ucp_Zl: c_uint = 27
let ucp_Zp: c_uint = 28
let ucp_Zs: c_uint = 29
let ucp_ASCII: c_uint = 0
let ucp_ASCII_Hex_Digit: c_uint = 1
let ucp_Alphabetic: c_uint = 2
let ucp_Bidi_Control: c_uint = 3
let ucp_Bidi_Mirrored: c_uint = 4
let ucp_Case_Ignorable: c_uint = 5
let ucp_Cased: c_uint = 6
let ucp_Changes_When_Casefolded: c_uint = 7
let ucp_Changes_When_Casemapped: c_uint = 8
let ucp_Changes_When_Lowercased: c_uint = 9
let ucp_Changes_When_Titlecased: c_uint = 10
let ucp_Changes_When_Uppercased: c_uint = 11
let ucp_Dash: c_uint = 12
let ucp_Default_Ignorable_Code_Point: c_uint = 13
let ucp_Deprecated: c_uint = 14
let ucp_Diacritic: c_uint = 15
let ucp_Emoji: c_uint = 16
let ucp_Emoji_Component: c_uint = 17
let ucp_Emoji_Modifier: c_uint = 18
let ucp_Emoji_Modifier_Base: c_uint = 19
let ucp_Emoji_Presentation: c_uint = 20
let ucp_Extended_Pictographic: c_uint = 21
let ucp_Extender: c_uint = 22
let ucp_Grapheme_Base: c_uint = 23
let ucp_Grapheme_Extend: c_uint = 24
let ucp_Grapheme_Link: c_uint = 25
let ucp_Hex_Digit: c_uint = 26
let ucp_IDS_Binary_Operator: c_uint = 27
let ucp_IDS_Trinary_Operator: c_uint = 28
let ucp_IDS_Unary_Operator: c_uint = 29
let ucp_ID_Compat_Math_Continue: c_uint = 30
let ucp_ID_Compat_Math_Start: c_uint = 31
let ucp_ID_Continue: c_uint = 32
let ucp_ID_Start: c_uint = 33
let ucp_Ideographic: c_uint = 34
let ucp_InCB: c_uint = 35
let ucp_Join_Control: c_uint = 36
let ucp_Logical_Order_Exception: c_uint = 37
let ucp_Lowercase: c_uint = 38
let ucp_Math: c_uint = 39
let ucp_Modifier_Combining_Mark: c_uint = 40
let ucp_Noncharacter_Code_Point: c_uint = 41
let ucp_Pattern_Syntax: c_uint = 42
let ucp_Pattern_White_Space: c_uint = 43
let ucp_Prepended_Concatenation_Mark: c_uint = 44
let ucp_Quotation_Mark: c_uint = 45
let ucp_Radical: c_uint = 46
let ucp_Regional_Indicator: c_uint = 47
let ucp_Sentence_Terminal: c_uint = 48
let ucp_Soft_Dotted: c_uint = 49
let ucp_Terminal_Punctuation: c_uint = 50
let ucp_Unified_Ideograph: c_uint = 51
let ucp_Uppercase: c_uint = 52
let ucp_Variation_Selector: c_uint = 53
let ucp_White_Space: c_uint = 54
let ucp_XID_Continue: c_uint = 55
let ucp_XID_Start: c_uint = 56
let ucp_Bprop_Count: c_uint = 57
let ucp_bidiAL: c_uint = 0
let ucp_bidiAN: c_uint = 1
let ucp_bidiB: c_uint = 2
let ucp_bidiBN: c_uint = 3
let ucp_bidiCS: c_uint = 4
let ucp_bidiEN: c_uint = 5
let ucp_bidiES: c_uint = 6
let ucp_bidiET: c_uint = 7
let ucp_bidiFSI: c_uint = 8
let ucp_bidiL: c_uint = 9
let ucp_bidiLRE: c_uint = 10
let ucp_bidiLRI: c_uint = 11
let ucp_bidiLRO: c_uint = 12
let ucp_bidiNSM: c_uint = 13
let ucp_bidiON: c_uint = 14
let ucp_bidiPDF: c_uint = 15
let ucp_bidiPDI: c_uint = 16
let ucp_bidiR: c_uint = 17
let ucp_bidiRLE: c_uint = 18
let ucp_bidiRLI: c_uint = 19
let ucp_bidiRLO: c_uint = 20
let ucp_bidiS: c_uint = 21
let ucp_bidiWS: c_uint = 22
let ucp_gbCR: c_uint = 0
let ucp_gbLF: c_uint = 1
let ucp_gbControl: c_uint = 2
let ucp_gbExtend: c_uint = 3
let ucp_gbPrepend: c_uint = 4
let ucp_gbSpacingMark: c_uint = 5
let ucp_gbL: c_uint = 6
let ucp_gbV: c_uint = 7
let ucp_gbT: c_uint = 8
let ucp_gbLV: c_uint = 9
let ucp_gbLVT: c_uint = 10
let ucp_gbRegional_Indicator: c_uint = 11
let ucp_gbOther: c_uint = 12
let ucp_gbZWJ: c_uint = 13
let ucp_gbExtended_Pictographic: c_uint = 14
let ucp_Latin: c_uint = 0
let ucp_Greek: c_uint = 1
let ucp_Cyrillic: c_uint = 2
let ucp_Armenian: c_uint = 3
let ucp_Hebrew: c_uint = 4
let ucp_Arabic: c_uint = 5
let ucp_Syriac: c_uint = 6
let ucp_Thaana: c_uint = 7
let ucp_Devanagari: c_uint = 8
let ucp_Bengali: c_uint = 9
let ucp_Gurmukhi: c_uint = 10
let ucp_Gujarati: c_uint = 11
let ucp_Oriya: c_uint = 12
let ucp_Tamil: c_uint = 13
let ucp_Telugu: c_uint = 14
let ucp_Kannada: c_uint = 15
let ucp_Malayalam: c_uint = 16
let ucp_Sinhala: c_uint = 17
let ucp_Thai: c_uint = 18
let ucp_Tibetan: c_uint = 19
let ucp_Myanmar: c_uint = 20
let ucp_Georgian: c_uint = 21
let ucp_Hangul: c_uint = 22
let ucp_Ethiopic: c_uint = 23
let ucp_Cherokee: c_uint = 24
let ucp_Runic: c_uint = 25
let ucp_Mongolian: c_uint = 26
let ucp_Hiragana: c_uint = 27
let ucp_Katakana: c_uint = 28
let ucp_Bopomofo: c_uint = 29
let ucp_Han: c_uint = 30
let ucp_Yi: c_uint = 31
let ucp_Gothic: c_uint = 32
let ucp_Tagalog: c_uint = 33
let ucp_Hanunoo: c_uint = 34
let ucp_Buhid: c_uint = 35
let ucp_Tagbanwa: c_uint = 36
let ucp_Limbu: c_uint = 37
let ucp_Tai_Le: c_uint = 38
let ucp_Linear_B: c_uint = 39
let ucp_Shavian: c_uint = 40
let ucp_Cypriot: c_uint = 41
let ucp_Buginese: c_uint = 42
let ucp_Coptic: c_uint = 43
let ucp_Glagolitic: c_uint = 44
let ucp_Tifinagh: c_uint = 45
let ucp_Syloti_Nagri: c_uint = 46
let ucp_Phags_Pa: c_uint = 47
let ucp_Nko: c_uint = 48
let ucp_Kayah_Li: c_uint = 49
let ucp_Lycian: c_uint = 50
let ucp_Carian: c_uint = 51
let ucp_Lydian: c_uint = 52
let ucp_Avestan: c_uint = 53
let ucp_Samaritan: c_uint = 54
let ucp_Lisu: c_uint = 55
let ucp_Javanese: c_uint = 56
let ucp_Old_Turkic: c_uint = 57
let ucp_Kaithi: c_uint = 58
let ucp_Mandaic: c_uint = 59
let ucp_Chakma: c_uint = 60
let ucp_Meroitic_Hieroglyphs: c_uint = 61
let ucp_Sharada: c_uint = 62
let ucp_Takri: c_uint = 63
let ucp_Caucasian_Albanian: c_uint = 64
let ucp_Duployan: c_uint = 65
let ucp_Elbasan: c_uint = 66
let ucp_Grantha: c_uint = 67
let ucp_Khojki: c_uint = 68
let ucp_Linear_A: c_uint = 69
let ucp_Mahajani: c_uint = 70
let ucp_Manichaean: c_uint = 71
let ucp_Modi: c_uint = 72
let ucp_Old_Permic: c_uint = 73
let ucp_Psalter_Pahlavi: c_uint = 74
let ucp_Khudawadi: c_uint = 75
let ucp_Tirhuta: c_uint = 76
let ucp_Multani: c_uint = 77
let ucp_Old_Hungarian: c_uint = 78
let ucp_Adlam: c_uint = 79
let ucp_Newa: c_uint = 80
let ucp_Osage: c_uint = 81
let ucp_Tangut: c_uint = 82
let ucp_Masaram_Gondi: c_uint = 83
let ucp_Dogra: c_uint = 84
let ucp_Gunjala_Gondi: c_uint = 85
let ucp_Hanifi_Rohingya: c_uint = 86
let ucp_Sogdian: c_uint = 87
let ucp_Nandinagari: c_uint = 88
let ucp_Yezidi: c_uint = 89
let ucp_Cypro_Minoan: c_uint = 90
let ucp_Old_Uyghur: c_uint = 91
let ucp_Toto: c_uint = 92
let ucp_Garay: c_uint = 93
let ucp_Gurung_Khema: c_uint = 94
let ucp_Ol_Onal: c_uint = 95
let ucp_Sunuwar: c_uint = 96
let ucp_Todhri: c_uint = 97
let ucp_Tulu_Tigalari: c_uint = 98
let ucp_Unknown: c_uint = 99
let ucp_Common: c_uint = 100
let ucp_Lao: c_uint = 101
let ucp_Canadian_Aboriginal: c_uint = 102
let ucp_Ogham: c_uint = 103
let ucp_Khmer: c_uint = 104
let ucp_Old_Italic: c_uint = 105
let ucp_Deseret: c_uint = 106
let ucp_Inherited: c_uint = 107
let ucp_Ugaritic: c_uint = 108
let ucp_Osmanya: c_uint = 109
let ucp_Braille: c_uint = 110
let ucp_New_Tai_Lue: c_uint = 111
let ucp_Old_Persian: c_uint = 112
let ucp_Kharoshthi: c_uint = 113
let ucp_Balinese: c_uint = 114
let ucp_Cuneiform: c_uint = 115
let ucp_Phoenician: c_uint = 116
let ucp_Sundanese: c_uint = 117
let ucp_Lepcha: c_uint = 118
let ucp_Ol_Chiki: c_uint = 119
let ucp_Vai: c_uint = 120
let ucp_Saurashtra: c_uint = 121
let ucp_Rejang: c_uint = 122
let ucp_Cham: c_uint = 123
let ucp_Tai_Tham: c_uint = 124
let ucp_Tai_Viet: c_uint = 125
let ucp_Egyptian_Hieroglyphs: c_uint = 126
let ucp_Bamum: c_uint = 127
let ucp_Meetei_Mayek: c_uint = 128
let ucp_Imperial_Aramaic: c_uint = 129
let ucp_Old_South_Arabian: c_uint = 130
let ucp_Inscriptional_Parthian: c_uint = 131
let ucp_Inscriptional_Pahlavi: c_uint = 132
let ucp_Batak: c_uint = 133
let ucp_Brahmi: c_uint = 134
let ucp_Meroitic_Cursive: c_uint = 135
let ucp_Miao: c_uint = 136
let ucp_Sora_Sompeng: c_uint = 137
let ucp_Bassa_Vah: c_uint = 138
let ucp_Pahawh_Hmong: c_uint = 139
let ucp_Mende_Kikakui: c_uint = 140
let ucp_Mro: c_uint = 141
let ucp_Old_North_Arabian: c_uint = 142
let ucp_Nabataean: c_uint = 143
let ucp_Palmyrene: c_uint = 144
let ucp_Pau_Cin_Hau: c_uint = 145
let ucp_Siddham: c_uint = 146
let ucp_Warang_Citi: c_uint = 147
let ucp_Ahom: c_uint = 148
let ucp_Anatolian_Hieroglyphs: c_uint = 149
let ucp_Hatran: c_uint = 150
let ucp_SignWriting: c_uint = 151
let ucp_Bhaiksuki: c_uint = 152
let ucp_Marchen: c_uint = 153
let ucp_Nushu: c_uint = 154
let ucp_Soyombo: c_uint = 155
let ucp_Zanabazar_Square: c_uint = 156
let ucp_Makasar: c_uint = 157
let ucp_Medefaidrin: c_uint = 158
let ucp_Old_Sogdian: c_uint = 159
let ucp_Elymaic: c_uint = 160
let ucp_Nyiakeng_Puachue_Hmong: c_uint = 161
let ucp_Wancho: c_uint = 162
let ucp_Chorasmian: c_uint = 163
let ucp_Dives_Akuru: c_uint = 164
let ucp_Khitan_Small_Script: c_uint = 165
let ucp_Tangsa: c_uint = 166
let ucp_Vithkuqi: c_uint = 167
let ucp_Kawi: c_uint = 168
let ucp_Nag_Mundari: c_uint = 169
let ucp_Kirat_Rai: c_uint = 170
let ucp_Sidetic: c_uint = 171
let ucp_Tai_Yo: c_uint = 172
let ucp_Tolong_Siki: c_uint = 173
let ucp_Beria_Erfe: c_uint = 174
let ucp_Script_Count: c_uint = 175
let PCRE2_MATCHEDBY_INTERPRETER: c_uint = 0
let PCRE2_MATCHEDBY_DFA_INTERPRETER: c_uint = 1
let PCRE2_MATCHEDBY_JIT: c_uint = 2
let ESC_A: c_uint = 1
let ESC_G: c_uint = 2
let ESC_K: c_uint = 3
let ESC_B: c_uint = 4
let ESC_b: c_uint = 5
let ESC_D: c_uint = 6
let ESC_d: c_uint = 7
let ESC_S: c_uint = 8
let ESC_s: c_uint = 9
let ESC_W: c_uint = 10
let ESC_w: c_uint = 11
let ESC_N: c_uint = 12
let ESC_dum: c_uint = 13
let ESC_C: c_uint = 14
let ESC_P: c_uint = 15
let ESC_p: c_uint = 16
let ESC_R: c_uint = 17
let ESC_H: c_uint = 18
let ESC_h: c_uint = 19
let ESC_V: c_uint = 20
let ESC_v: c_uint = 21
let ESC_X: c_uint = 22
let ESC_Z: c_uint = 23
let ESC_z: c_uint = 24
let ESC_E: c_uint = 25
let ESC_Q: c_uint = 26
let ESC_g: c_uint = 27
let ESC_k: c_uint = 28
let ESC_ub: c_uint = 29
let OP_END: c_uint = 0
let OP_SOD: c_uint = 1
let OP_SOM: c_uint = 2
let OP_SET_SOM: c_uint = 3
let OP_NOT_WORD_BOUNDARY: c_uint = 4
let OP_WORD_BOUNDARY: c_uint = 5
let OP_NOT_DIGIT: c_uint = 6
let OP_DIGIT: c_uint = 7
let OP_NOT_WHITESPACE: c_uint = 8
let OP_WHITESPACE: c_uint = 9
let OP_NOT_WORDCHAR: c_uint = 10
let OP_WORDCHAR: c_uint = 11
let OP_ANY: c_uint = 12
let OP_ALLANY: c_uint = 13
let OP_ANYBYTE: c_uint = 14
let OP_NOTPROP: c_uint = 15
let OP_PROP: c_uint = 16
let OP_ANYNL: c_uint = 17
let OP_NOT_HSPACE: c_uint = 18
let OP_HSPACE: c_uint = 19
let OP_NOT_VSPACE: c_uint = 20
let OP_VSPACE: c_uint = 21
let OP_EXTUNI: c_uint = 22
let OP_EODN: c_uint = 23
let OP_EOD: c_uint = 24
let OP_DOLL: c_uint = 25
let OP_DOLLM: c_uint = 26
let OP_CIRC: c_uint = 27
let OP_CIRCM: c_uint = 28
let OP_CHAR: c_uint = 29
let OP_CHARI: c_uint = 30
let OP_NOT: c_uint = 31
let OP_NOTI: c_uint = 32
let OP_STAR: c_uint = 33
let OP_MINSTAR: c_uint = 34
let OP_PLUS: c_uint = 35
let OP_MINPLUS: c_uint = 36
let OP_QUERY: c_uint = 37
let OP_MINQUERY: c_uint = 38
let OP_UPTO: c_uint = 39
let OP_MINUPTO: c_uint = 40
let OP_EXACT: c_uint = 41
let OP_POSSTAR: c_uint = 42
let OP_POSPLUS: c_uint = 43
let OP_POSQUERY: c_uint = 44
let OP_POSUPTO: c_uint = 45
let OP_STARI: c_uint = 46
let OP_MINSTARI: c_uint = 47
let OP_PLUSI: c_uint = 48
let OP_MINPLUSI: c_uint = 49
let OP_QUERYI: c_uint = 50
let OP_MINQUERYI: c_uint = 51
let OP_UPTOI: c_uint = 52
let OP_MINUPTOI: c_uint = 53
let OP_EXACTI: c_uint = 54
let OP_POSSTARI: c_uint = 55
let OP_POSPLUSI: c_uint = 56
let OP_POSQUERYI: c_uint = 57
let OP_POSUPTOI: c_uint = 58
let OP_NOTSTAR: c_uint = 59
let OP_NOTMINSTAR: c_uint = 60
let OP_NOTPLUS: c_uint = 61
let OP_NOTMINPLUS: c_uint = 62
let OP_NOTQUERY: c_uint = 63
let OP_NOTMINQUERY: c_uint = 64
let OP_NOTUPTO: c_uint = 65
let OP_NOTMINUPTO: c_uint = 66
let OP_NOTEXACT: c_uint = 67
let OP_NOTPOSSTAR: c_uint = 68
let OP_NOTPOSPLUS: c_uint = 69
let OP_NOTPOSQUERY: c_uint = 70
let OP_NOTPOSUPTO: c_uint = 71
let OP_NOTSTARI: c_uint = 72
let OP_NOTMINSTARI: c_uint = 73
let OP_NOTPLUSI: c_uint = 74
let OP_NOTMINPLUSI: c_uint = 75
let OP_NOTQUERYI: c_uint = 76
let OP_NOTMINQUERYI: c_uint = 77
let OP_NOTUPTOI: c_uint = 78
let OP_NOTMINUPTOI: c_uint = 79
let OP_NOTEXACTI: c_uint = 80
let OP_NOTPOSSTARI: c_uint = 81
let OP_NOTPOSPLUSI: c_uint = 82
let OP_NOTPOSQUERYI: c_uint = 83
let OP_NOTPOSUPTOI: c_uint = 84
let OP_TYPESTAR: c_uint = 85
let OP_TYPEMINSTAR: c_uint = 86
let OP_TYPEPLUS: c_uint = 87
let OP_TYPEMINPLUS: c_uint = 88
let OP_TYPEQUERY: c_uint = 89
let OP_TYPEMINQUERY: c_uint = 90
let OP_TYPEUPTO: c_uint = 91
let OP_TYPEMINUPTO: c_uint = 92
let OP_TYPEEXACT: c_uint = 93
let OP_TYPEPOSSTAR: c_uint = 94
let OP_TYPEPOSPLUS: c_uint = 95
let OP_TYPEPOSQUERY: c_uint = 96
let OP_TYPEPOSUPTO: c_uint = 97
let OP_CRSTAR: c_uint = 98
let OP_CRMINSTAR: c_uint = 99
let OP_CRPLUS: c_uint = 100
let OP_CRMINPLUS: c_uint = 101
let OP_CRQUERY: c_uint = 102
let OP_CRMINQUERY: c_uint = 103
let OP_CRRANGE: c_uint = 104
let OP_CRMINRANGE: c_uint = 105
let OP_CRPOSSTAR: c_uint = 106
let OP_CRPOSPLUS: c_uint = 107
let OP_CRPOSQUERY: c_uint = 108
let OP_CRPOSRANGE: c_uint = 109
let OP_CLASS: c_uint = 110
let OP_NCLASS: c_uint = 111
let OP_XCLASS: c_uint = 112
let OP_ECLASS: c_uint = 113
let OP_REF: c_uint = 114
let OP_REFI: c_uint = 115
let OP_DNREF: c_uint = 116
let OP_DNREFI: c_uint = 117
let OP_RECURSE: c_uint = 118
let OP_CALLOUT: c_uint = 119
let OP_CALLOUT_STR: c_uint = 120
let OP_ALT: c_uint = 121
let OP_KET: c_uint = 122
let OP_KETRMAX: c_uint = 123
let OP_KETRMIN: c_uint = 124
let OP_KETRPOS: c_uint = 125
let OP_REVERSE: c_uint = 126
let OP_VREVERSE: c_uint = 127
let OP_ASSERT: c_uint = 128
let OP_ASSERT_NOT: c_uint = 129
let OP_ASSERTBACK: c_uint = 130
let OP_ASSERTBACK_NOT: c_uint = 131
let OP_ASSERT_NA: c_uint = 132
let OP_ASSERTBACK_NA: c_uint = 133
let OP_ASSERT_SCS: c_uint = 134
let OP_ONCE: c_uint = 135
let OP_SCRIPT_RUN: c_uint = 136
let OP_BRA: c_uint = 137
let OP_BRAPOS: c_uint = 138
let OP_CBRA: c_uint = 139
let OP_CBRAPOS: c_uint = 140
let OP_COND: c_uint = 141
let OP_SBRA: c_uint = 142
let OP_SBRAPOS: c_uint = 143
let OP_SCBRA: c_uint = 144
let OP_SCBRAPOS: c_uint = 145
let OP_SCOND: c_uint = 146
let OP_CREF: c_uint = 147
let OP_DNCREF: c_uint = 148
let OP_RREF: c_uint = 149
let OP_DNRREF: c_uint = 150
let OP_FALSE: c_uint = 151
let OP_TRUE: c_uint = 152
let OP_BRAZERO: c_uint = 153
let OP_BRAMINZERO: c_uint = 154
let OP_BRAPOSZERO: c_uint = 155
let OP_MARK: c_uint = 156
let OP_PRUNE: c_uint = 157
let OP_PRUNE_ARG: c_uint = 158
let OP_SKIP: c_uint = 159
let OP_SKIP_ARG: c_uint = 160
let OP_THEN: c_uint = 161
let OP_THEN_ARG: c_uint = 162
let OP_COMMIT: c_uint = 163
let OP_COMMIT_ARG: c_uint = 164
let OP_FAIL: c_uint = 165
let OP_ACCEPT: c_uint = 166
let OP_ASSERT_ACCEPT: c_uint = 167
let OP_CLOSE: c_uint = 168
let OP_SKIPZERO: c_uint = 169
let OP_DEFINE: c_uint = 170
let OP_NOT_UCP_WORD_BOUNDARY: c_uint = 171
let OP_UCP_WORD_BOUNDARY: c_uint = 172
let OP_TABLE_LENGTH: c_uint = 173
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
type pcre2_real_code_8 { memctl: pcre2_memctl, tables: *const u8 = null, executable_jit: *mut c_void = null, start_bitmap: [32]u8, blocksize: c_ulong = 0, code_start: c_ulong = 0, magic_number: c_uint = 0, compile_options: c_uint = 0, overall_options: c_uint = 0, extra_options: c_uint = 0, flags: c_uint = 0, limit_heap: c_uint = 0, limit_match: c_uint = 0, limit_depth: c_uint = 0, first_codeunit: c_uint = 0, last_codeunit: c_uint = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, max_lookbehind: c_ushort = 0, minlength: c_ushort = 0, top_bracket: c_ushort = 0, top_backref: c_ushort = 0, name_entry_size: c_ushort = 0, name_count: c_ushort = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_code_8 = pcre2_real_code_8
type pcre2_real_match_data_8 { memctl: pcre2_memctl, code: *const pcre2_real_code_8 = null, subject: *const u8 = null, mark: *const u8 = null, heapframes: *mut heapframe = null, heapframes_size: c_ulong = 0, subject_length: c_ulong = 0, start_offset: c_ulong = 0, leftchar: c_ulong = 0, rightchar: c_ulong = 0, startchar: c_ulong = 0, matchedby: u8 = 0, flags: u8 = 0, oveccount: c_ushort = 0, options: c_uint = 0, rc: c_int = 0, ovector: [131072]c_ulong }
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
type class_bits_storage { classbits: [32]u8, classwords: [8]c_uint }
type struct_class_bits_storage = class_bits_storage
type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong, erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8, class_op_used: [15]u8, req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null }
type struct_compile_block_8 = compile_block_8
type pcre2_real_jit_stack_8 { memctl: pcre2_memctl, stack: *mut c_void = null }
type struct_pcre2_real_jit_stack_8 = pcre2_real_jit_stack_8
type dfa_recursion_info { prevrec: *mut dfa_recursion_info = null, subject_position: *const u8 = null, last_used_ptr: *const u8 = null, group_num: c_uint = 0 }
type struct_dfa_recursion_info = dfa_recursion_info
// .reference/pcre2/src/pcre2_intmodedep.h:696:8: demoted to opaque
type heapframe = opaque
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
// .reference/pcre2/src/pcre2_intmodedep.h:1024:16: demoted to opaque
type heapframe_align = opaque
type struct_heapframe_align = heapframe_align
type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null }
type struct_match_block_8 = match_block_8
type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8, bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, recursive: *mut dfa_recursion_info = null }
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
extern var rep_min: [11]c_uint
extern var rep_max: [11]c_uint
extern var rep_typ: [12]c_uint
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
    var rc: c_int = 0
    var save0: c_ulong = 0 // init: untranslatable
    var save1: c_ulong = 0 // init: untranslatable
    var callout_ovector: *mut c_ulong = null // init: untranslatable
    var cb: *mut pcre2_callout_block_8 = null // init: untranslatable
    if (if mb.callout == null: 1 else: 0) != 0:
        return 0

    (cb = mb.cb)
    (cb.capture_last = F.capture_last)
    (cb.offset_vector = callout_ovector)
    (cb.mark = mb.nomatch_mark)
    if (if unsafe: *F.ecode == OP_CALLOUT: 1 else: 0) != 0:
        (cb.callout_number = F.ecode[(1 + (2 * 2))])
        (cb.callout_string_offset = 0)
        (cb.callout_string = null)
        (cb.callout_string_length = 0)
    else:
        (cb.callout_number = 0)
        (cb.callout_string = ((F.ecode + (((1 + (4 * 2))) as isize as usize)) + (1 as isize as usize)))
        (cb.callout_string_length = ((unsafe: *lengthptr -% 9) -% 2))

    (save0 = callout_ovector[0])
    (save1 = callout_ovector[1])
    (rc = mb.callout(cb, mb.callout_data))
    (callout_ovector[0] = save0)
    (callout_ovector[1] = save1)
    (cb.callout_flags = 0)
    return rc

fn match_ref(offset: c_ulong, caseless: c_int, caseopts: c_int, F: *mut heapframe, mb: *mut match_block_8, lengthptr: *mut c_ulong) -> c_int:
    var p: *const u8 = null // init: untranslatable
    var length: c_ulong = 0 // init: untranslatable
    var eptr: *const u8 = null // init: untranslatable
    var eptr_start: *const u8 = null // init: untranslatable
    caseopts
    (eptr = (eptr_start = F.eptr))
    (p = (mb.start_subject + F.ovector[offset]))
    (length = (F.ovector[(offset +% 1)] -% F.ovector[offset]))
    if caseless != 0:
                while (if length > 0: 1 else: 0) != 0:
            var cc: c_uint = 0 // init: untranslatable
            var cp: c_uint = 0 // init: untranslatable
            if (if eptr >= mb.end_subject: 1 else: 0) != 0:
                return 1

            (cc = unsafe: *eptr)
            (cp = unsafe: *p)
            if (if ((mb.lcc)[cp]) != ((mb.lcc)[cc]): 1 else: 0) != 0:
                return (0 - 1)

            (p = p + 1)
            (eptr = eptr + 1)
            (length = length - 1)


    else:
        if (if mb.partial != 0: 1 else: 0) != 0:
            while (if length > 0: 1 else: 0) != 0:
                if (if eptr >= mb.end_subject: 1 else: 0) != 0:
                    return 1

                if (if unsafe: *(p = p + 1) != unsafe: *(eptr = eptr + 1): 1 else: 0) != 0:
                    return (0 - 1)

                (length = length - 1)

        else:
            eptr = eptr + length


    (unsafe: *lengthptr = ((eptr as usize -% eptr_start as usize) / sizeof[u8]()))
    return 0

fn recurse_update_offsets(F: *mut heapframe, P: *mut heapframe):
    var dst: *mut c_ulong = null // init: untranslatable
    var src: *mut c_ulong = null // init: untranslatable
    var offset: c_ulong = 0 // init: untranslatable
    var offset_top: c_ulong = 0 // init: untranslatable
    var diff: c_ulong = 0 // init: untranslatable
    var ecode: *const u8 = null // init: untranslatable
    while true:
        ecode = ecode + (1 + 2)
        if (if (offset +% diff) >= offset_top: 1 else: 0) != 0:
            while (if unsafe: *ecode == OP_CREF: 1 else: 0) != 0:
ecode = ecode + (1 + 2)
            break

        if (if diff == 2: 1 else: 0) != 0:
            (dst[0] = src[0])
            (dst[1] = src[1])
        else:
            if (if diff >= 4: 1 else: 0) != 0:
                with_memcpy(dst as *i8, src as *i8, (diff *% sizeof[c_ulong]()) as i64)


        diff = diff + 2
        offset = offset + diff
        dst = dst + diff
        src = src + diff
        if not ((if unsafe: *ecode == OP_CREF: 1 else: 0) != 0):
            break

    (diff = (offset_top -% offset))
    if (if diff == 2: 1 else: 0) != 0:
        (dst[0] = src[0])
        (dst[1] = src[1])
    else:
        if (if diff >= 4: 1 else: 0) != 0:
            with_memcpy(dst as *i8, src as *i8, (diff *% sizeof[c_ulong]()) as i64)


    (F.ecode = ecode)
    (F.offset_top = (if ((if offset <= P.offset_top: 1 else: 0)) != 0: P.offset_top else: ((offset -% 2))))

fn match_(start_eptr: *const u8, start_ecode: *const u8, top_bracket: c_ushort, frame_size: c_ulong, match_data: *mut pcre2_real_match_data_8, mb: *mut match_block_8) -> c_int:
    var F: *mut heapframe = null
    var N: *mut heapframe = null
    var P: *mut heapframe = null
    var frames_top: *mut heapframe = null
    var assert_accept_frame: *mut heapframe = null
    var frame_copy_size: c_ulong = 0
    var branch_end: *const u8 = null
    var branch_start: *const u8 = null
    var bracode: *const u8 = null
    var offset: c_ulong = 0
    var length: c_ulong = 0
    var rrc: c_int = 0
    var i: c_uint = 0
    var fc: c_uint = 0
    var number: c_uint = 0
    var reptype: c_uint = 0
    var group_frame_type: c_uint = 0
    var condition: c_int = 0
    var cur_is_word: c_int = 0
    var prev_is_word: c_int = 0
    var utf: c_int = 0
    var new: *mut heapframe = null
    var newsize: c_ulong = 0
    var usedsize: c_ulong = 0
    var old_size: c_ulong = 0
    var max_delta: c_ulong = 0
    var over_bytes: c_int = 0
    var ch: c_uint = 0
    var cc: c_uint = 0
    var count: c_int = 0
    var slot: *const u8 = null
    var slength: c_ulong = 0
    var samelengths: c_int = 0
    var next_ecode: *const u8 = null
    var current_branch: *const u8 = null
    var next_branch: *const u8 = null
    var ecode: *const u8 = null
    var diff: c_long = 0
    var available: c_uint = 0
    var y: c_uint = 0
    var lastptr: *const u8 = null
    var nextptr: *const u8 = null
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                (frame_copy_size = (frame_size -% 64))
                (F = match_data.heapframes)
                (F.rdepth = 0)
                (F.capture_last = 0)
                (F.current_recurse = 4294967295)
                (F.start_match = (F.eptr = start_eptr))
                (F.mark = null)
                (F.offset_top = 0)
                (group_frame_type = 0)
                __pc = 2
                continue
                __pc = 1
                continue
            1 =>  // MATCH_RECURSE
                with_memcpy(((N as *mut i8) + 64) as *i8, ((F as *mut i8) + 64) as *i8, frame_copy_size as i64)
                (N.rdepth = (F.rdepth +% 1))
                (F = N)
                __pc = 2
                continue
            2 =>  // NEW_FRAME
                (F.group_frame_type = group_frame_type)
                (F.ecode = start_ecode)
                (F.back_frame = frame_size)
                if (if group_frame_type != 0: 1 else: 0) != 0:
                    (F.last_group_offset = (((F as *mut i8) as usize -% (match_data.heapframes as *mut i8) as usize) / sizeof[c_char]()))
                    (group_frame_type = 0)

                while true:
                    match F.op
                        OP_CLOSE =>
                            if (if F.current_recurse == 4294967295: 1 else: 0) != 0:
                                (offset = F.last_group_offset)
                                while true:
                                    if (if N.group_frame_type == ((65536 | number)): 1 else: 0) != 0:
                                        break

                                    (offset = P.last_group_offset)

                                (offset = (((number << 1)) -% 2))
                                (F.capture_last = number)
                                (F.ovector[offset] = ((P.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                (F.ovector[(offset +% 1)] = ((F.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                if (if offset >= F.offset_top: 1 else: 0) != 0:
                                    (F.offset_top = (offset +% 2))


                            F.ecode = F.ecode + _pcre2_OP_lengths_8[unsafe: *F.ecode]
                        OP_ASSERT_ACCEPT =>
                            if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                (mb.last_used_ptr = F.eptr)

                            (assert_accept_frame = F)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                (offset = F.last_group_offset)
                                while true:
                                    (offset = P.last_group_offset)

                                (P.eptr = F.eptr)
                                (P.mark = F.mark)
                                (P.start_match = F.start_match)
                                (F = P)
                                F.ecode = F.ecode + (1 + 2)
                                continue

                            if (if (if F.eptr == F.start_match: 1 else: 0) != 0 and ((if (if ((mb.moptions & 4)) != 0: 1 else: 0) != 0 or ((if (if ((mb.moptions & 8)) != 0: 1 else: 0) != 0 and (if F.start_match == (mb.start_subject + mb.start_offset): 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if ((((mb.moptions | mb.poptions)) & 536870912)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if F.op == OP_END: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                return 0

                            (mb.end_match_ptr = F.eptr)
                            (mb.end_offset_top = F.offset_top)
                            (mb.mark = F.mark)
                            if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                (mb.last_used_ptr = F.eptr)

                            (match_data.ovector[0] = ((F.start_match as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (match_data.ovector[1] = ((F.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (i = (2 * ((if ((if (top_bracket + 1) > match_data.oveccount: 1 else: 0)) != 0: match_data.oveccount else: (top_bracket + 1)))))
                            with_memcpy((match_data.ovector + (2 as isize as usize)) as *i8, F.ovector as *i8, (((i -% 2)) *% sizeof[c_ulong]()) as i64)
                            return 1
                        OP_ACCEPT =>
                            if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                (offset = F.last_group_offset)
                                while true:
                                    (offset = P.last_group_offset)

                                (P.eptr = F.eptr)
                                (P.mark = F.mark)
                                (P.start_match = F.start_match)
                                (F = P)
                                F.ecode = F.ecode + (1 + 2)
                                continue

                            if (if (if F.eptr == F.start_match: 1 else: 0) != 0 and ((if (if ((mb.moptions & 4)) != 0: 1 else: 0) != 0 or ((if (if ((mb.moptions & 8)) != 0: 1 else: 0) != 0 and (if F.start_match == (mb.start_subject + mb.start_offset): 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if ((((mb.moptions | mb.poptions)) & 536870912)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if F.op == OP_END: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                return 0

                            (mb.end_match_ptr = F.eptr)
                            (mb.end_offset_top = F.offset_top)
                            (mb.mark = F.mark)
                            if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                (mb.last_used_ptr = F.eptr)

                            (match_data.ovector[0] = ((F.start_match as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (match_data.ovector[1] = ((F.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (i = (2 * ((if ((if (top_bracket + 1) > match_data.oveccount: 1 else: 0)) != 0: match_data.oveccount else: (top_bracket + 1)))))
                            with_memcpy((match_data.ovector + (2 as isize as usize)) as *i8, F.ovector as *i8, (((i -% 2)) *% sizeof[c_ulong]()) as i64)
                            return 1
                        OP_END =>
                            if (if (if F.eptr == F.start_match: 1 else: 0) != 0 and ((if (if ((mb.moptions & 4)) != 0: 1 else: 0) != 0 or ((if (if ((mb.moptions & 8)) != 0: 1 else: 0) != 0 and (if F.start_match == (mb.start_subject + mb.start_offset): 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if ((((mb.moptions | mb.poptions)) & 536870912)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if F.op == OP_END: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                return 0

                            (mb.end_match_ptr = F.eptr)
                            (mb.end_offset_top = F.offset_top)
                            (mb.mark = F.mark)
                            if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                (mb.last_used_ptr = F.eptr)

                            (match_data.ovector[0] = ((F.start_match as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (match_data.ovector[1] = ((F.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                            (i = (2 * ((if ((if (top_bracket + 1) > match_data.oveccount: 1 else: 0)) != 0: match_data.oveccount else: (top_bracket + 1)))))
                            with_memcpy((match_data.ovector + (2 as isize as usize)) as *i8, F.ovector as *i8, (((i -% 2)) *% sizeof[c_ulong]()) as i64)
                            return 1
                        OP_ANY =>
                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if F.eptr == (mb.end_subject - (1 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                (mb.hitend = 1)

                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.eptr = F.eptr + 1)
                            (F.ecode = F.ecode + 1)
                        OP_ALLANY =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.eptr = F.eptr + 1)
                            (F.ecode = F.ecode + 1)
                        OP_ANYBYTE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.eptr = F.eptr + 1)
                            (F.ecode = F.ecode + 1)
                        OP_CHAR =>
                                                        if (if ((mb.end_subject as usize -% F.eptr as usize) / sizeof[u8]()) < 1: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if F.ecode[1] != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            F.ecode = F.ecode + 2

                        OP_CHARI =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                                                        if (if ((mb.lcc)[F.ecode[1]]) != ((mb.lcc)[unsafe: *F.eptr]): 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.eptr = F.eptr + 1)
                            F.ecode = F.ecode + 2

                        OP_NOT =>
                                                        var ch: c_uint = 0 // init: untranslatable
                            (fc = unsafe: *(F.eptr = F.eptr + 1))
                            if (if (if ch == fc: 1 else: 0) != 0 or ((if (if F.op == OP_NOTI: 1 else: 0) != 0 and (if ((mb.fcc)[ch]) == fc: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            F.ecode = F.ecode + 2

                        OP_EXACT =>
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 1)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_POSUPTO =>
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 1)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_UPTO =>
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 1)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_MINUPTO =>
                            (F.fields.char_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 1)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_POSSTAR =>
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 1)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_POSPLUS =>
                            (F.fields.char_repeat.min = 1)
                            (F.fields.char_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_POSQUERY =>
                            (F.fields.char_repeat.min = 0)
                            (F.fields.char_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_STAR =>
                            (F.fields.char_repeat.min = rep_min[fc])
                            (F.fields.char_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATCHAR
(F.fields.char_repeat.c = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.op >= OP_STARI: 1 else: 0) != 0:
                                (F.fields.char_repeat.oc.oc = mb.fcc[F.fields.char_repeat.c])
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    var cc: c_uint = 0 // init: untranslatable
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (cc = unsafe: *F.eptr)
                                    if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        var cc: c_uint = 0 // init: untranslatable
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM25
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)

                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        var cc: c_uint = 0 // init: untranslatable
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        (cc = unsafe: *F.eptr)
                                        if (if (if F.fields.char_repeat.c != cc: 1 else: 0) != 0 and (if F.fields.char_repeat.oc.oc != cc: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM26
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break





                            else:
                                (i = 1)
                                while (if i <= F.fields.char_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)

                                if (if F.fields.char_repeat.min == F.fields.char_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM27
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.char_repeat.min = F.fields.char_repeat.min + 1) >= F.fields.char_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.char_repeat.c != unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break



                                else:
                                    (F.fields.char_repeat.start_eptr = F.eptr)
                                    (i = F.fields.char_repeat.min)
                                    while (if i < F.fields.char_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.char_repeat.c != unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr <= F.fields.char_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM28
// (empty)
                                                if not (0 != 0):
                                                    break

                                            (F.eptr = F.eptr - 1)
                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break






                        OP_NOTEXACT =>
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (reptype = 1)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (reptype = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 1)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTUPTO =>
                            (reptype = 1)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (reptype = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 1)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTMINUPTO =>
                            (reptype = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 1)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTPOSSTAR =>
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 1)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTPOSPLUS =>
                            (F.fields.charnot_repeat.min = 1)
                            (F.fields.charnot_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTPOSQUERY =>
                            (F.fields.charnot_repeat.min = 0)
                            (F.fields.charnot_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTPOSUPTO =>
                            (F.fields.charnot_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NOTSTAR =>
                            (F.fields.charnot_repeat.min = rep_min[fc])
                            (F.fields.charnot_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATNOTCHAR

                            // (empty)
                            if (if F.op >= OP_NOTSTARI: 1 else: 0) != 0:
                                (F.fields.charnot_repeat.oc = ((mb.fcc)[F.fields.charnot_repeat.c]))
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr + 1)
                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM29
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        (F.eptr = F.eptr + 1)


                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0 or (if F.fields.charnot_repeat.oc == unsafe: *F.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM30
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)




                            else:
                                                                (i = 1)
                                while (if i <= F.fields.charnot_repeat.min: 1 else: 0) != 0:
                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (i = i + 1)


                                if (if F.fields.charnot_repeat.min == F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                    continue

                                if (if reptype == 0: 1 else: 0) != 0:
                                                                        while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM31
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if (F.fields.charnot_repeat.min = F.fields.charnot_repeat.min + 1) >= F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.fields.charnot_repeat.c == unsafe: *(F.eptr = F.eptr + 1): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break




                                else:
                                    (F.fields.charnot_repeat.start_eptr = F.eptr)
                                                                        (i = F.fields.charnot_repeat.min)
                                    while (if i < F.fields.charnot_repeat.max: 1 else: 0) != 0:
                                        if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                            break

                                        if (if F.fields.charnot_repeat.c == unsafe: *F.eptr: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.eptr + 1)
                                        (i = i + 1)

                                    if (if reptype != 2: 1 else: 0) != 0:
                                        while true:
                                            if (if F.eptr == F.fields.charnot_repeat.start_eptr: 1 else: 0) != 0:
                                                break

                                            while true:
                                                comptime_error("goto not supported")
                                                // label: L_RM32
// (empty)
                                                if not (0 != 0):
                                                    break

                                            if (if rrc != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr - 1)





                        OP_NCLASS =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_NOT_DIGIT =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_DIGIT =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_NOT_WHITESPACE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_WHITESPACE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_NOT_WORDCHAR =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_WORDCHAR =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_ANYNL =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            match fc
                                _ =>
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                13 => 0
                                10 => 0
                                11 => 0

                            (F.ecode = F.ecode + 1)
                        OP_NOT_HSPACE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            match fc
                                9 => 0
                                _ => 0

                            (F.ecode = F.ecode + 1)
                        OP_HSPACE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            match fc
                                9 =>
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                _ =>
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                            (F.ecode = F.ecode + 1)
                        OP_NOT_VSPACE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            match fc
                                10 => 0
                                _ => 0

                            (F.ecode = F.ecode + 1)
                        OP_VSPACE =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            // (empty)
                            match fc
                                10 =>
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                _ =>
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                            (F.ecode = F.ecode + 1)
                        OP_TYPEEXACT =>
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (reptype = (if ((if unsafe: *F.ecode == OP_TYPEMINUPTO: 1 else: 0)) != 0: REPTYPE_MIN else: REPTYPE_MAX))
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 1)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_TYPEUPTO =>
                            (reptype = (if ((if unsafe: *F.ecode == OP_TYPEMINUPTO: 1 else: 0)) != 0: REPTYPE_MIN else: REPTYPE_MAX))
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 1)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_TYPEPOSSTAR =>
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 1)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_TYPEPOSPLUS =>
                            (reptype = 2)
                            (F.fields.type_repeat.min = 1)
                            (F.fields.type_repeat.max = 4294967295)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_TYPEPOSQUERY =>
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            (F.fields.type_repeat.max = 1)
                            (F.ecode = F.ecode + 1)
                            comptime_error("goto not supported")
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_TYPEPOSUPTO =>
                            (reptype = 2)
                            (F.fields.type_repeat.min = 0)
                            F.ecode = F.ecode + (1 + 2)
                            comptime_error("goto not supported")
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_TYPESTAR =>
                            (F.fields.type_repeat.min = rep_min[fc])
                            (F.fields.type_repeat.max = rep_max[fc])
                            (reptype = rep_typ[fc])
                            // label: REPEATTYPE
(F.fields.type_repeat.ctype = unsafe: *(F.ecode = F.ecode + 1))
                            if (if F.fields.type_repeat.min > 0: 1 else: 0) != 0:
                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (if (if (if (if mb.partial != 0: 1 else: 0) != 0 and (if (F.eptr + (1 as isize as usize)) >= mb.end_subject: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nltype == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.nllen == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == mb.nl[0]: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (mb.hitend = 1)

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 =>
                                        if (if F.eptr > (mb.end_subject - F.fields.type_repeat.min): 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr + F.fields.type_repeat.min
                                    17 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                            (i = i + 1)

                                    18 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ => 0
                                                9 => 0

                                            (i = i + 1)

                                    19 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                            (i = i + 1)

                                    20 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                10 => 0
                                                _ => 0

                                            (i = i + 1)

                                    21 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            match unsafe: *(F.eptr = F.eptr + 1)
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                            (i = i + 1)

                                    6 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = 1)
                                        while (if i <= F.fields.type_repeat.min: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0


                            if (if F.fields.type_repeat.min == F.fields.type_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                                                while true:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM33
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.type_repeat.min = F.fields.type_repeat.min + 1) >= F.fields.type_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (fc = unsafe: *(F.eptr = F.eptr + 1))
                                    match F.fields.type_repeat.ctype
                                        12 => 0
                                        13 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        17 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                13 =>
                                                    if (if (if F.eptr < mb.end_subject: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (F.eptr = F.eptr + 1)

                                                10 => 0
                                                11 => 0

                                        18 =>
                                            match fc
                                                _ => 0
                                                9 => 0

                                        19 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                9 => 0

                                        20 =>
                                            match fc
                                                _ => 0
                                                10 => 0

                                        21 =>
                                            match fc
                                                _ =>
                                                    while true:
                                                        comptime_error("goto not supported")
                                                        if not (0 != 0):
                                                            break

                                                10 => 0

                                        6 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        7 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        8 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        9 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        10 =>
                                            if (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        11 =>
                                            if (if (not 1) != 0 or (if ((mb.ctypes[fc] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        _ => 0



                            else:
                                (F.fields.type_repeat.start_eptr = F.eptr)
                                                                match F.fields.type_repeat.ctype
                                    12 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    13 => 0
                                    17 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            (fc = unsafe: *F.eptr)
                                            if (if fc == 13: 1 else: 0) != 0:
                                                if (if (F.eptr = F.eptr + 1) >= mb.end_subject: 1 else: 0) != 0:
                                                    break

                                                if (if unsafe: *F.eptr == 10: 1 else: 0) != 0:
                                                    (F.eptr = F.eptr + 1)

                                            else:
                                                if (if (if fc != 10: 1 else: 0) != 0 and ((if (if mb.bsr_convention == 2: 1 else: 0) != 0 or ((if (if (if fc != 11: 1 else: 0) != 0 and (if fc != 12: 1 else: 0) != 0: 1 else: 0) != 0 and (if fc != 133: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                    break

                                                (F.eptr = F.eptr + 1)

                                            (i = i + 1)

                                    18 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP00
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    19 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                9 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP01
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    20 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    (F.eptr = F.eptr + 1)
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP02
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    21 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            match unsafe: *F.eptr
                                                _ =>
                                                    comptime_error("goto not supported")
                                                10 => 0

                                            (i = i + 1)

                                        // label: ENDLOOP03
break
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    6 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 8)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    7 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 8)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    8 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    9 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 1)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    10 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if 1 != 0 and (if ((mb.ctypes[unsafe: *F.eptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    11 =>
                                        (i = F.fields.type_repeat.min)
                                        while (if i < F.fields.type_repeat.max: 1 else: 0) != 0:
                                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                                break

                                            if (if (not 1) != 0 or (if ((mb.ctypes[unsafe: *F.eptr] & 16)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                break

                                            (F.eptr = F.eptr + 1)
                                            (i = i + 1)

                                    _ => 0

                                if (if reptype == 2: 1 else: 0) != 0:
                                    continue

                                while true:
                                    if (if F.eptr == F.fields.type_repeat.start_eptr: 1 else: 0) != 0:
                                        break

                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM34
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (F.eptr = F.eptr - 1)
                                    if (if (if (if (if F.fields.type_repeat.ctype == 17: 1 else: 0) != 0 and (if F.eptr > F.fields.type_repeat.start_eptr: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *F.eptr == 10: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr[(0 - 1)] == 13: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (F.eptr = F.eptr - 1)




                        OP_DNREF =>
                                                        var count: c_int = 0 // init: untranslatable
                            var slot: *const u8 = null // init: untranslatable
                            F.ecode = F.ecode + ((1 + (2 * 2)) + ((if (if F.op == OP_DNREFI: 1 else: 0) != 0: 1 else: 0)))
                            while (if (count = count - 1) > 0: 1 else: 0) != 0:
                                slot = slot + mb.name_entry_size


                            comptime_error("goto not supported")
                            (F.byte2 = (if ((if F.op == OP_REFI: 1 else: 0)) != 0: F.ecode[(1 + 2)] else: 0))
                            F.ecode = F.ecode + ((1 + 2) + ((if (if F.op == OP_REFI: 1 else: 0) != 0: 1 else: 0)))
                            // label: REF_REPEAT
match unsafe: *F.ecode
                                OP_CRSTAR =>
                                    (F.fields.ref_repeat.min = rep_min[fc])
                                    (F.fields.ref_repeat.max = rep_max[fc])
                                    (reptype = rep_typ[fc])
                                OP_CRRANGE =>
                                    (reptype = rep_typ[(unsafe: *F.ecode - OP_CRSTAR)])
                                    if (if F.fields.ref_repeat.max == 0: 1 else: 0) != 0:
                                        (F.fields.ref_repeat.max = 4294967295)

                                    F.ecode = F.ecode + (1 + (2 * 2))
                                _ =>
                                                                        (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &length))
                                    if (if rrc != 0: 1 else: 0) != 0:
                                        if (if rrc > 0: 1 else: 0) != 0:
                                            (F.eptr = mb.end_subject)

                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break



                                    F.eptr = F.eptr + length
                                    continue

                            (i = 1)
                            while (if i <= F.fields.ref_repeat.min: 1 else: 0) != 0:
                                var slength: c_ulong = 0 // init: untranslatable
                                (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength))
                                if (if rrc != 0: 1 else: 0) != 0:
                                    if (if rrc > 0: 1 else: 0) != 0:
                                        (F.eptr = mb.end_subject)

                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                F.eptr = F.eptr + slength
                                (i = i + 1)

                            if (if F.fields.ref_repeat.min == F.fields.ref_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                while true:
                                    var slength: c_ulong = 0 // init: untranslatable
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM20
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.ref_repeat.min = F.fields.ref_repeat.min + 1) >= F.fields.ref_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength))
                                    if (if rrc != 0: 1 else: 0) != 0:
                                        if (if rrc > 0: 1 else: 0) != 0:
                                            (F.eptr = mb.end_subject)

                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    F.eptr = F.eptr + slength

                            else:
                                var samelengths: c_int = 0 // init: untranslatable
                                (F.fields.ref_repeat.start = F.eptr)
                                (F.fields.ref_repeat.length = (F.ovector[(F.fields.ref_repeat.offset +% 1)] -% F.ovector[F.fields.ref_repeat.offset]))
                                (i = F.fields.ref_repeat.min)
                                while (if i < F.fields.ref_repeat.max: 1 else: 0) != 0:
                                    var slength: c_ulong = 0 // init: untranslatable
                                    (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength))
                                    if (if rrc != 0: 1 else: 0) != 0:
                                        if (if (if (if rrc > 0: 1 else: 0) != 0 and (if mb.partial != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.end_subject > mb.start_used_ptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (mb.hitend = 1)

                                        break

                                    if (if slength != F.fields.ref_repeat.length: 1 else: 0) != 0:
                                        (samelengths = 0)

                                    F.eptr = F.eptr + slength
                                    (i = i + 1)

                                if (if reptype == 2: 1 else: 0) != 0:
                                    break

                                if samelengths != 0:
                                    while (if F.eptr >= F.fields.ref_repeat.start: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM21
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr - F.fields.ref_repeat.length

                                else:
                                    (F.fields.ref_repeat.max = i)
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM22
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr == F.fields.ref_repeat.start: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.fields.ref_repeat.start)
                                        (F.fields.ref_repeat.max = F.fields.ref_repeat.max - 1)
                                        (i = F.fields.ref_repeat.min)
                                        while (if i < F.fields.ref_repeat.max: 1 else: 0) != 0:
                                            var slength: c_ulong = 0 // init: untranslatable
                                            match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength)
                                            F.eptr = F.eptr + slength
                                            (i = i + 1)



                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                                                        var next_ecode: *const u8 = null // init: untranslatable
                            (F.ecode = F.ecode + 1)
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM9
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (next_ecode = F.ecode)
                            (F.ecode = ((next_ecode + (1 as isize as usize)) + (2 as isize as usize)))

                        OP_REF =>
                            (F.byte2 = (if ((if F.op == OP_REFI: 1 else: 0)) != 0: F.ecode[(1 + 2)] else: 0))
                            F.ecode = F.ecode + ((1 + 2) + ((if (if F.op == OP_REFI: 1 else: 0) != 0: 1 else: 0)))
                            // label: REF_REPEAT
match unsafe: *F.ecode
                                OP_CRSTAR =>
                                    (F.fields.ref_repeat.min = rep_min[fc])
                                    (F.fields.ref_repeat.max = rep_max[fc])
                                    (reptype = rep_typ[fc])
                                OP_CRRANGE =>
                                    (reptype = rep_typ[(unsafe: *F.ecode - OP_CRSTAR)])
                                    if (if F.fields.ref_repeat.max == 0: 1 else: 0) != 0:
                                        (F.fields.ref_repeat.max = 4294967295)

                                    F.ecode = F.ecode + (1 + (2 * 2))
                                _ =>
                                                                        (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &length))
                                    if (if rrc != 0: 1 else: 0) != 0:
                                        if (if rrc > 0: 1 else: 0) != 0:
                                            (F.eptr = mb.end_subject)

                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break



                                    F.eptr = F.eptr + length
                                    continue

                            (i = 1)
                            while (if i <= F.fields.ref_repeat.min: 1 else: 0) != 0:
                                var slength: c_ulong = 0 // init: untranslatable
                                (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength))
                                if (if rrc != 0: 1 else: 0) != 0:
                                    if (if rrc > 0: 1 else: 0) != 0:
                                        (F.eptr = mb.end_subject)

                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                F.eptr = F.eptr + slength
                                (i = i + 1)

                            if (if F.fields.ref_repeat.min == F.fields.ref_repeat.max: 1 else: 0) != 0:
                                continue

                            if (if reptype == 0: 1 else: 0) != 0:
                                while true:
                                    var slength: c_ulong = 0 // init: untranslatable
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM20
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if (F.fields.ref_repeat.min = F.fields.ref_repeat.min + 1) >= F.fields.ref_repeat.max: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength))
                                    if (if rrc != 0: 1 else: 0) != 0:
                                        if (if rrc > 0: 1 else: 0) != 0:
                                            (F.eptr = mb.end_subject)

                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    F.eptr = F.eptr + slength

                            else:
                                var samelengths: c_int = 0 // init: untranslatable
                                (F.fields.ref_repeat.start = F.eptr)
                                (F.fields.ref_repeat.length = (F.ovector[(F.fields.ref_repeat.offset +% 1)] -% F.ovector[F.fields.ref_repeat.offset]))
                                (i = F.fields.ref_repeat.min)
                                while (if i < F.fields.ref_repeat.max: 1 else: 0) != 0:
                                    var slength: c_ulong = 0 // init: untranslatable
                                    (rrc = match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength))
                                    if (if rrc != 0: 1 else: 0) != 0:
                                        if (if (if (if rrc > 0: 1 else: 0) != 0 and (if mb.partial != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if mb.end_subject > mb.start_used_ptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (mb.hitend = 1)

                                        break

                                    if (if slength != F.fields.ref_repeat.length: 1 else: 0) != 0:
                                        (samelengths = 0)

                                    F.eptr = F.eptr + slength
                                    (i = i + 1)

                                if (if reptype == 2: 1 else: 0) != 0:
                                    break

                                if samelengths != 0:
                                    while (if F.eptr >= F.fields.ref_repeat.start: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM21
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        F.eptr = F.eptr - F.fields.ref_repeat.length

                                else:
                                    (F.fields.ref_repeat.max = i)
                                    while true:
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM22
// (empty)
                                            if not (0 != 0):
                                                break

                                        if (if rrc != 0: 1 else: 0) != 0:
                                            while true:
                                                comptime_error("goto not supported")
                                                if not (0 != 0):
                                                    break


                                        if (if F.eptr == F.fields.ref_repeat.start: 1 else: 0) != 0:
                                            break

                                        (F.eptr = F.fields.ref_repeat.start)
                                        (F.fields.ref_repeat.max = F.fields.ref_repeat.max - 1)
                                        (i = F.fields.ref_repeat.min)
                                        while (if i < F.fields.ref_repeat.max: 1 else: 0) != 0:
                                            var slength: c_ulong = 0 // init: untranslatable
                                            match_ref(F.fields.ref_repeat.offset, F.byte1, F.byte2, F, mb, &slength)
                                            F.eptr = F.eptr + slength
                                            (i = i + 1)



                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                                                        var next_ecode: *const u8 = null // init: untranslatable
                            (F.ecode = F.ecode + 1)
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM9
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (next_ecode = F.ecode)
                            (F.ecode = ((next_ecode + (1 as isize as usize)) + (2 as isize as usize)))

                        OP_BRAZERO =>
                                                        var next_ecode: *const u8 = null // init: untranslatable
                            (F.ecode = F.ecode + 1)
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM9
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (next_ecode = F.ecode)
                            (F.ecode = ((next_ecode + (1 as isize as usize)) + (2 as isize as usize)))

                        OP_BRAMINZERO =>
                                                        var next_ecode: *const u8 = null // init: untranslatable
                            (F.ecode = F.ecode + 1)
                            (next_ecode = F.ecode)
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM10
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break



                        OP_SKIPZERO =>
                                                        var next_ecode: *const u8 = null // init: untranslatable
                            (F.ecode = ((next_ecode + (1 as isize as usize)) + (2 as isize as usize)))

                        OP_BRAPOSZERO =>
                            (F.byte2 = 1)
                            F.ecode = F.ecode + 1
                            if (if (if unsafe: *F.ecode == OP_CBRAPOS: 1 else: 0) != 0 or (if unsafe: *F.ecode == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                                comptime_error("goto not supported")

                            comptime_error("goto not supported")
                            // label: POSSESSIVE_NON_CAPTURE
(F.fields.op_brapos.frame_type = 131072)
                            comptime_error("goto not supported")
                            // label: POSSESSIVE_CAPTURE

                            (F.fields.op_brapos.frame_type = (65536 | number))
                            // label: POSSESSIVE_GROUP
(F.byte1 = 0)
                            (F.fields.op_brapos.start_group = F.ecode)
                            while true:
                                (F.fields.op_brapos.start_eptr = F.eptr)
                                (group_frame_type = F.fields.op_brapos.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM8
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if unsafe: *F.ecode != OP_ALT: 1 else: 0) != 0:
                                    break


                            if (if F.byte1 != 0 or F.byte2 != 0: 1 else: 0) != 0:
                                F.ecode = F.ecode + (1 + 2)
                                break

                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            if (if mb.hasthen != 0 or (if F.rdepth == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (F.fields.op_bra.frame_type = 0)
                                comptime_error("goto not supported")

                            while true:
                                var current_branch: *const u8 = null // init: untranslatable
                                var next_branch: *const u8 = null // init: untranslatable
                                if (if unsafe: *next_branch != OP_ALT: 1 else: 0) != 0:
                                    break

                                (F.ecode = next_branch)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM1
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_BRAPOS =>
                            // label: POSSESSIVE_NON_CAPTURE
(F.fields.op_brapos.frame_type = 131072)
                            comptime_error("goto not supported")
                            // label: POSSESSIVE_CAPTURE

                            (F.fields.op_brapos.frame_type = (65536 | number))
                            // label: POSSESSIVE_GROUP
(F.byte1 = 0)
                            (F.fields.op_brapos.start_group = F.ecode)
                            while true:
                                (F.fields.op_brapos.start_eptr = F.eptr)
                                (group_frame_type = F.fields.op_brapos.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM8
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if unsafe: *F.ecode != OP_ALT: 1 else: 0) != 0:
                                    break


                            if (if F.byte1 != 0 or F.byte2 != 0: 1 else: 0) != 0:
                                F.ecode = F.ecode + (1 + 2)
                                break

                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            if (if mb.hasthen != 0 or (if F.rdepth == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (F.fields.op_bra.frame_type = 0)
                                comptime_error("goto not supported")

                            while true:
                                var current_branch: *const u8 = null // init: untranslatable
                                var next_branch: *const u8 = null // init: untranslatable
                                if (if unsafe: *next_branch != OP_ALT: 1 else: 0) != 0:
                                    break

                                (F.ecode = next_branch)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM1
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_CBRAPOS =>
                            // label: POSSESSIVE_CAPTURE

                            (F.fields.op_brapos.frame_type = (65536 | number))
                            // label: POSSESSIVE_GROUP
(F.byte1 = 0)
                            (F.fields.op_brapos.start_group = F.ecode)
                            while true:
                                (F.fields.op_brapos.start_eptr = F.eptr)
                                (group_frame_type = F.fields.op_brapos.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM8
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if unsafe: *F.ecode != OP_ALT: 1 else: 0) != 0:
                                    break


                            if (if F.byte1 != 0 or F.byte2 != 0: 1 else: 0) != 0:
                                F.ecode = F.ecode + (1 + 2)
                                break

                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            if (if mb.hasthen != 0 or (if F.rdepth == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (F.fields.op_bra.frame_type = 0)
                                comptime_error("goto not supported")

                            while true:
                                var current_branch: *const u8 = null // init: untranslatable
                                var next_branch: *const u8 = null // init: untranslatable
                                if (if unsafe: *next_branch != OP_ALT: 1 else: 0) != 0:
                                    break

                                (F.ecode = next_branch)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM1
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_BRA =>
                            if (if mb.hasthen != 0 or (if F.rdepth == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (F.fields.op_bra.frame_type = 0)
                                comptime_error("goto not supported")

                            while true:
                                var current_branch: *const u8 = null // init: untranslatable
                                var next_branch: *const u8 = null // init: untranslatable
                                if (if unsafe: *next_branch != OP_ALT: 1 else: 0) != 0:
                                    break

                                (F.ecode = next_branch)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM1
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_CBRA =>
                            comptime_error("goto not supported")
                            // label: GROUPLOOP
while true:
                                (group_frame_type = F.fields.op_bra.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM2
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if unsafe: *F.ecode != OP_ALT: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                (offset = F.last_group_offset)

                            (F.recurse_last_used = mb.last_used_ptr)
                            (F.fields.op_recurse.start_branch = bracode)
                            (F.fields.op_recurse.frame_type = (262144 | number))
                            while true:
                                var next_ecode: *const u8 = null // init: untranslatable
                                (group_frame_type = F.fields.op_recurse.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM11
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                (F.fields.op_recurse.start_branch = next_ecode)
                                if (if unsafe: *F.fields.op_recurse.start_branch != OP_ALT: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_ONCE =>
                            // label: GROUPLOOP
while true:
                                (group_frame_type = F.fields.op_bra.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM2
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if unsafe: *F.ecode != OP_ALT: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                (offset = F.last_group_offset)

                            (F.recurse_last_used = mb.last_used_ptr)
                            (F.fields.op_recurse.start_branch = bracode)
                            (F.fields.op_recurse.frame_type = (262144 | number))
                            while true:
                                var next_ecode: *const u8 = null // init: untranslatable
                                (group_frame_type = F.fields.op_recurse.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM11
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                (F.fields.op_recurse.start_branch = next_ecode)
                                if (if unsafe: *F.fields.op_recurse.start_branch != OP_ALT: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_RECURSE =>
                            if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                (offset = F.last_group_offset)

                            (F.recurse_last_used = mb.last_used_ptr)
                            (F.fields.op_recurse.start_branch = bracode)
                            (F.fields.op_recurse.frame_type = (262144 | number))
                            while true:
                                var next_ecode: *const u8 = null // init: untranslatable
                                (group_frame_type = F.fields.op_recurse.frame_type)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM11
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                (F.fields.op_recurse.start_branch = next_ecode)
                                if (if unsafe: *F.fields.op_recurse.start_branch != OP_ALT: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_ASSERT =>
                            F.ecode = F.ecode + (1 + 2)
                        OP_ASSERT_NOT =>
                            // label: ASSERT_NOT_FAILED
F.ecode = F.ecode + (1 + 2)
                        OP_ASSERT_SCS =>
                            (length = 0)
                                                        var ecode: *const u8 = null // init: untranslatable
                            var count: c_int = 0
                            var slot: *const u8 = null // init: untranslatable
                            (offset = 0)
                            offset
                            while true:
                                if (if unsafe: *ecode == OP_CREF: 1 else: 0) != 0:
                                    length = length + 3
                                    ecode = ecode + (1 + 2)
                                    continue

                                if (if unsafe: *ecode != OP_DNCREF: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                length = length + 5
                                ecode = ecode + (1 + (2 * 2))
                                while (if count > 0: 1 else: 0) != 0:
                                    slot = slot + mb.name_entry_size
                                    (count = count - 1)


                            // label: SCS_OFFSET_FOUND
while true:
                                if (if unsafe: *ecode == OP_CREF: 1 else: 0) != 0:
                                    length = length + 3
                                    ecode = ecode + (1 + 2)
                                else:
                                    if (if unsafe: *ecode == OP_DNCREF: 1 else: 0) != 0:
                                        length = length + 5
                                        ecode = ecode + (1 + (2 * 2))
                                    else:
                                        break




                            (F.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                            (F.fields.op_assert_scs.true_end_extra = ((mb.true_end_subject as usize -% mb.end_subject as usize) / sizeof[u8]()))
                            (F.fields.op_assert_scs.saved_eptr = F.eptr)
                            (F.fields.op_assert_scs.saved_moptions = mb.moptions)
                            (F.eptr = (mb.start_subject + F.ovector[offset]))
                            (mb.true_end_subject = (mb.end_subject = (mb.start_subject + F.ovector[(offset +% 1)])))
                            mb.moptions = mb.moptions & (0 - 2 - 1)
                            while true:
                                (group_frame_type = 131072)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM38
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if unsafe: *F.ecode != OP_ALT: 1 else: 0) != 0:
                                    (mb.end_subject = F.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + F.fields.op_assert_scs.true_end_extra))
                                    (mb.moptions = F.fields.op_assert_scs.saved_moptions)
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                (length = 0)

                            F.ecode = F.ecode + (1 + 2)
                            (F.eptr = F.fields.op_assert_scs.saved_eptr)
                        OP_CALLOUT =>
                            if (if rrc > 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if rrc < 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            F.ecode = F.ecode + length
                        OP_COND =>
                            if (if F.ecode[F.fields.op_cond.length] != OP_ALT: 1 else: 0) != 0:
                                F.fields.op_cond.length = F.fields.op_cond.length - 3

                            F.ecode = F.ecode + (1 + 2)
                            if (if (if unsafe: *F.ecode == OP_CALLOUT: 1 else: 0) != 0 or (if unsafe: *F.ecode == OP_CALLOUT_STR: 1 else: 0) != 0: 1 else: 0) != 0:
                                (rrc = do_callout(F, mb, &length))
                                if (if rrc > 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if rrc < 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                F.ecode = F.ecode + length
                                F.fields.op_cond.length = F.fields.op_cond.length - length

                            (condition = 0)
                            match unsafe: *F.ecode
                                OP_RREF =>
                                    if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                        (condition = ((if (if number == 65535: 1 else: 0) != 0 or (if number == F.current_recurse: 1 else: 0) != 0: 1 else: 0)))

                                OP_DNRREF =>
                                    if (if F.current_recurse != 4294967295: 1 else: 0) != 0:
                                        var count: c_int = 0 // init: untranslatable
                                        var slot: *const u8 = null // init: untranslatable
                                        while (if (count = count - 1) > 0: 1 else: 0) != 0:
                                            (condition = (if number == F.current_recurse: 1 else: 0))
                                            if condition != 0:
                                                break

                                            slot = slot + mb.name_entry_size


                                OP_CREF => 0
                                OP_DNCREF =>
                                                                        var count: c_int = 0 // init: untranslatable
                                    var slot: *const u8 = null // init: untranslatable
                                    while (if (count = count - 1) > 0: 1 else: 0) != 0:
                                        if condition != 0:
                                            break

                                        slot = slot + mb.name_entry_size


                                OP_FALSE =>
                                    (condition = 1)
                                OP_TRUE =>
                                    (condition = 1)
                                _ =>
                                    (F.fields.op_cond.start_branch = F.ecode)
                                    while true:
                                        (group_frame_type = 196608)
                                        while true:
                                            comptime_error("goto not supported")
                                            // label: L_RM5
// (empty)
                                            if not (0 != 0):
                                                break

                                        match rrc
                                            1 =>
                                                (condition = F.byte1)
                                            0 =>
                                                if (if unsafe: *F.fields.op_cond.start_branch == OP_ALT: 1 else: 0) != 0:
                                                    continue

                                                (condition = (not F.byte1))
                                            _ =>
                                                while true:
                                                    comptime_error("goto not supported")
                                                    if not (0 != 0):
                                                        break


                                        break


                            F.ecode = F.ecode + (if condition != 0: _pcre2_OP_lengths_8[unsafe: *F.ecode] else: F.fields.op_cond.length)
                            if (if F.op == OP_SCOND: 1 else: 0) != 0:
                                (group_frame_type = 131072)
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM35
// (empty)
                                    if not (0 != 0):
                                        break

                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                        OP_REVERSE =>
                                                        F.eptr = F.eptr - number

                            if (if F.eptr < mb.start_used_ptr: 1 else: 0) != 0:
                                (mb.start_used_ptr = F.eptr)

                            F.ecode = F.ecode + (1 + 2)
                        OP_VREVERSE =>
                                                        var diff: c_long = 0 // init: untranslatable
                            var available: c_uint = 0 // init: untranslatable
                            if (if F.fields.op_vreverse.min > available: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if F.fields.op_vreverse.max > available: 1 else: 0) != 0:
                                (F.fields.op_vreverse.max = available)

                            F.eptr = F.eptr - F.fields.op_vreverse.max

                            while true:
                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM37
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                if (if (F.fields.op_vreverse.max = F.fields.op_vreverse.max - 1) <= F.fields.op_vreverse.min: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                                (F.eptr = F.eptr + 1)

                            (branch_end = F.ecode)
                        OP_ALT =>
                            (branch_end = F.ecode)
                        OP_KET =>
                            if (if branch_end == null: 1 else: 0) != 0:
                                (branch_end = F.ecode)

                            (branch_start = bracode)
                            (branch_end = null)
                            if (if (if unsafe: *bracode != OP_BRA: 1 else: 0) != 0 and (if unsafe: *bracode != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0:
                                (F.last_group_offset = P.last_group_offset)
                                if (if N.group_frame_type == 196608: 1 else: 0) != 0:
                                    if (if (if ((if (if unsafe: *bracode == OP_ASSERTBACK: 1 else: 0) != 0 or (if unsafe: *bracode == OP_ASSERTBACK_NOT: 1 else: 0) != 0: 1 else: 0)) != 0 and (if branch_start[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0: 1 else: 0) != 0 and (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    (P.offset_top = F.offset_top)
                                    (P.mark = F.mark)
                                    (F.back_frame = (((F as *mut i8) as usize -% (P as *mut i8) as usize) / sizeof[c_char]()))
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break


                            else:
                                (P = null)

                            match unsafe: *bracode
                                OP_BRA =>
                                    if (if (if F.current_recurse != 0: 1 else: 0) != 0 or (if F.ecode[(1 + 2)] != OP_END: 1 else: 0) != 0: 1 else: 0) != 0:
                                        break

                                    (offset = F.last_group_offset)
                                    (F.last_group_offset = P.last_group_offset)
                                    (F.ecode = ((P.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                    if (if unsafe: *F.ecode != OP_CREF: 1 else: 0) != 0:
                                        (F.offset_top = P.offset_top)
                                    else:
                                        recurse_update_offsets(F, P)

                                    (F.capture_last = P.capture_last)
                                    (F.current_recurse = P.current_recurse)
                                    continue
                                    if (if (if branch_start[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0 and (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                        (mb.last_used_ptr = F.eptr)

                                    (F.eptr = P.eptr)
                                OP_COND =>
                                    if (if (if branch_start[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0 and (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                        (mb.last_used_ptr = F.eptr)

                                    (F.eptr = P.eptr)
                                OP_ASSERTBACK_NA =>
                                    if (if (if branch_start[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0 and (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                        (mb.last_used_ptr = F.eptr)

                                    (F.eptr = P.eptr)
                                OP_ASSERT_NA =>
                                    if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                        (mb.last_used_ptr = F.eptr)

                                    (F.eptr = P.eptr)
                                OP_ASSERTBACK =>
                                    if (if (if branch_start[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0 and (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                        (mb.last_used_ptr = F.eptr)

                                    (F.eptr = P.eptr)
                                    (F.back_frame = ((((F as *mut i8) as usize -% (P as *mut i8) as usize) / sizeof[c_char]())))
                                    while true:
                                        var y: c_uint = 0 // init: untranslatable
                                        if (if (P.ecode)[y] != OP_ALT: 1 else: 0) != 0:
                                            break

                                        P.ecode = P.ecode + y

                                OP_ASSERT =>
                                    if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                                        (mb.last_used_ptr = F.eptr)

                                    (F.eptr = P.eptr)
                                    (F.back_frame = ((((F as *mut i8) as usize -% (P as *mut i8) as usize) / sizeof[c_char]())))
                                    while true:
                                        var y: c_uint = 0 // init: untranslatable
                                        if (if (P.ecode)[y] != OP_ALT: 1 else: 0) != 0:
                                            break

                                        P.ecode = P.ecode + y

                                OP_ONCE =>
                                    (F.back_frame = ((((F as *mut i8) as usize -% (P as *mut i8) as usize) / sizeof[c_char]())))
                                    while true:
                                        var y: c_uint = 0 // init: untranslatable
                                        if (if (P.ecode)[y] != OP_ALT: 1 else: 0) != 0:
                                            break

                                        P.ecode = P.ecode + y

                                OP_ASSERTBACK_NOT =>
                                    if (if (if branch_start[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0 and (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                    (F.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                                    (mb.end_subject = P.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + P.fields.op_assert_scs.true_end_extra))
                                    (F.eptr = P.fields.op_assert_scs.saved_eptr)
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM39
// (empty)
                                        if not (0 != 0):
                                            break

                                    (mb.end_subject = F.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = mb.end_subject)
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                OP_ASSERT_NOT =>
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                    (F.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                                    (mb.end_subject = P.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + P.fields.op_assert_scs.true_end_extra))
                                    (F.eptr = P.fields.op_assert_scs.saved_eptr)
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM39
// (empty)
                                        if not (0 != 0):
                                            break

                                    (mb.end_subject = F.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = mb.end_subject)
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                OP_ASSERT_SCS =>
                                    (F.fields.op_assert_scs.saved_end_subject = mb.end_subject)
                                    (mb.end_subject = P.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = (mb.end_subject + P.fields.op_assert_scs.true_end_extra))
                                    (F.eptr = P.fields.op_assert_scs.saved_eptr)
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM39
// (empty)
                                        if not (0 != 0):
                                            break

                                    (mb.end_subject = F.fields.op_assert_scs.saved_end_subject)
                                    (mb.true_end_subject = mb.end_subject)
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break

                                OP_SCRIPT_RUN =>
                                    if (not _pcre2_script_run_8(P.eptr, F.eptr, utf)) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                OP_CBRA =>
                                    if (if F.current_recurse == number: 1 else: 0) != 0:
                                        (F.ecode = ((P.ecode + (1 as isize as usize)) + (2 as isize as usize)))
                                        if (if unsafe: *F.ecode != OP_CREF: 1 else: 0) != 0:
                                            (F.offset_top = P.offset_top)
                                        else:
                                            recurse_update_offsets(F, P)

                                        (F.capture_last = P.capture_last)
                                        (F.current_recurse = P.current_recurse)
                                        continue

                                    (offset = (((number << 1)) -% 2))
                                    (F.capture_last = number)
                                    (F.ovector[offset] = ((P.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                    (F.ovector[(offset +% 1)] = ((F.eptr as usize -% mb.start_subject as usize) / sizeof[u8]()))
                                    if (if offset >= F.offset_top: 1 else: 0) != 0:
                                        (F.offset_top = (offset +% 2))

                                _ => 0

                            if (if unsafe: *F.ecode == OP_KETRPOS: 1 else: 0) != 0:
                                with_memcpy(((P as *mut i8) + 64) as *i8, ((F as *mut i8) + 64) as *i8, frame_copy_size as i64)
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if (if F.op != OP_KET: 1 else: 0) != 0 and ((if (if P == null: 1 else: 0) != 0 or (if F.eptr != P.eptr: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                if (if F.op == OP_KETRMIN: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        // label: L_RM6
// (empty)
                                        if not (0 != 0):
                                            break

                                    if (if rrc != 0: 1 else: 0) != 0:
                                        while true:
                                            comptime_error("goto not supported")
                                            if not (0 != 0):
                                                break


                                    break

                                while true:
                                    comptime_error("goto not supported")
                                    // label: L_RM7
// (empty)
                                    if not (0 != 0):
                                        break

                                if (if rrc != 0: 1 else: 0) != 0:
                                    while true:
                                        comptime_error("goto not supported")
                                        if not (0 != 0):
                                            break



                            F.ecode = F.ecode + (1 + 2)
                        OP_CIRC =>
                            if (if (if F.eptr != mb.start_subject: 1 else: 0) != 0 or (if ((mb.moptions & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_SOD =>
                            if (if F.eptr != mb.start_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_DOLL =>
                            if (if ((mb.moptions & 2)) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if ((mb.poptions & 16)) == 0: 1 else: 0) != 0:
                                comptime_error("goto not supported")

                            if (if F.eptr < mb.true_end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if mb.partial != 0: 1 else: 0) != 0:
                                (mb.hitend = 1)

                            (F.ecode = F.ecode + 1)
                        OP_EOD =>
                            if (if F.eptr < mb.true_end_subject: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            if (if mb.partial != 0: 1 else: 0) != 0:
                                (mb.hitend = 1)

                            (F.ecode = F.ecode + 1)
                        OP_EODN =>
                            // label: ASSERT_NL_OR_EOS

                            if (if mb.partial != 0: 1 else: 0) != 0:
                                (mb.hitend = 1)

                            (F.ecode = F.ecode + 1)
                        OP_CIRCM =>
                            if (if (if ((mb.moptions & 1)) != 0: 1 else: 0) != 0 and (if F.eptr == mb.start_subject: 1 else: 0) != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_DOLLM =>
                            (F.ecode = F.ecode + 1)
                        OP_SOM =>
                            if (if F.eptr != (mb.start_subject + mb.start_offset): 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (F.ecode = F.ecode + 1)
                        OP_SET_SOM =>
                            (F.start_match = F.eptr)
                            (F.ecode = F.ecode + 1)
                        OP_NOT_WORD_BOUNDARY =>
                            if (if F.eptr >= mb.end_subject: 1 else: 0) != 0:
                                (cur_is_word = 0)
                            else:
                                var nextptr: *const u8 = null // init: untranslatable
                                (fc = unsafe: *F.eptr)
                                if (if nextptr > mb.last_used_ptr: 1 else: 0) != 0:
                                    (mb.last_used_ptr = nextptr)

                                (cur_is_word = (if 1 != 0 and (if ((mb.ctypes[fc] & 16)) != 0: 1 else: 0) != 0: 1 else: 0))

                            if (if ((if (if unsafe: *(F.ecode = F.ecode + 1) == OP_WORD_BOUNDARY: 1 else: 0) != 0 or (if F.op == OP_UCP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0)) != 0: (if cur_is_word == prev_is_word: 1 else: 0) else: (if cur_is_word != prev_is_word: 1 else: 0)) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                        OP_MARK =>
                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM12
// (empty)
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM13
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM36
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM14
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM15
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_FAIL =>
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM13
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM36
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM14
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM15
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_COMMIT =>
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM13
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM36
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM14
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM15
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_COMMIT_ARG =>
                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM36
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM14
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM15
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_PRUNE =>
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM14
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM15
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_PRUNE_ARG =>
                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM15
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_SKIP =>
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM16
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = F.eptr)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_SKIP_ARG =>
                            (mb.skip_arg_count = mb.skip_arg_count + 1)
                            if (if mb.skip_arg_count <= mb.ignore_skip_arg: 1 else: 0) != 0:
                                F.ecode = F.ecode + (_pcre2_OP_lengths_8[unsafe: *F.ecode] + F.ecode[1])
                                break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM17
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_skip_ptr = (F.ecode + (2 as isize as usize)))
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_THEN =>
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM18
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        OP_THEN_ARG =>
                            (F.mark = (mb.nomatch_mark = (F.ecode + (2 as isize as usize))))
                            while true:
                                comptime_error("goto not supported")
                                // label: L_RM19
// (empty)
                                if not (0 != 0):
                                    break

                            if (if rrc != 0: 1 else: 0) != 0:
                                while true:
                                    comptime_error("goto not supported")
                                    if not (0 != 0):
                                        break


                            (mb.verb_ecode_ptr = F.ecode)
                            (mb.verb_current_recurse = F.current_recurse)
                            while true:
                                comptime_error("goto not supported")
                                if not (0 != 0):
                                    break

                        _ => 0


                __pc = 57
                continue
            57 =>  // RETURN_SWITCH
                if (if F.eptr > mb.last_used_ptr: 1 else: 0) != 0:
                    (mb.last_used_ptr = F.eptr)

                if (if F.rdepth == 0: 1 else: 0) != 0:
                    return rrc

                mb.cb.callout_flags = mb.cb.callout_flags | 2
                match F.return_id
                    1 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    2 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    3 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    4 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    5 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    6 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    7 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    8 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    9 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    10 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    11 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    12 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    13 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    14 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    15 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    16 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    17 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    18 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    19 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    20 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    21 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    22 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    23 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    24 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    25 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    26 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    27 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    28 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    29 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    30 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    31 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    32 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    33 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    34 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    35 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    36 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    37 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    38 =>
                        comptime_error("goto not supported")
                        comptime_error("goto not supported")
                    39 =>
                        comptime_error("goto not supported")
                    _ => 0

            _ => break

let TARGET_IPHONE_SIMULATOR: c_int = 0
let TARGET_OS_ARROW: c_int = 1
let TARGET_OS_BRIDGE: c_int = 0
let TARGET_OS_DRIVERKIT: c_int = 0
let TARGET_OS_EMBEDDED: c_int = 0
let TARGET_OS_IOS: c_int = 0
let TARGET_OS_IOSMAC: c_int = 0
let TARGET_OS_IPHONE: c_int = 0
let TARGET_OS_LINUX: c_int = 0
let TARGET_OS_MAC: c_int = 1
let TARGET_OS_MACCATALYST: c_int = 0
let TARGET_OS_NANO: c_int = 0
let TARGET_OS_OSX: c_int = 1
let TARGET_OS_SIMULATOR: c_int = 0
let TARGET_OS_TV: c_int = 0
let TARGET_OS_UIKITFORMAC: c_int = 0
let TARGET_OS_UNIX: c_int = 0
let TARGET_OS_VISION: c_int = 0
let TARGET_OS_WATCH: c_int = 0
let TARGET_OS_WIN32: c_int = 0
let TARGET_OS_WINDOWS: c_int = 0
let TARGET_OS_XR: c_int = 0
