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
type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong, ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
type struct_pcre2_substitute_callout_block_8 = pcre2_substitute_callout_block_8
extern fn pcre2_config_8(__p0: c_uint, __p1: *mut c_void) -> c_int
extern fn pcre2_general_context_copy_8(__p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_create_8(__p0: *const fn(c_ulong, *mut c_void) -> *mut c_void, __p1: *const fn(*mut c_void, *mut c_void) -> void, __p2: *mut c_void) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_free_8(__p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_compile_context_copy_8(__p0: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_create_8(__p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_free_8(__p0: *mut pcre2_real_compile_context_8) -> void
extern fn pcre2_set_bsr_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_character_tables_8(__p0: *mut pcre2_real_compile_context_8, __p1: *const u8) -> c_int
extern fn pcre2_set_compile_extra_options_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_max_pattern_length_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_ulong) -> c_int
extern fn pcre2_set_max_pattern_compiled_length_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_ulong) -> c_int
extern fn pcre2_set_max_varlookbehind_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_newline_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_parens_nest_limit_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_compile_recursion_guard_8(__p0: *mut pcre2_real_compile_context_8, __p1: *const fn(c_uint, *mut c_void) -> c_int, __p2: *mut c_void) -> c_int
extern fn pcre2_set_optimize_8(__p0: *mut pcre2_real_compile_context_8, __p1: c_uint) -> c_int
extern fn pcre2_convert_context_copy_8(__p0: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_create_8(__p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_free_8(__p0: *mut pcre2_real_convert_context_8) -> void
extern fn pcre2_set_glob_escape_8(__p0: *mut pcre2_real_convert_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_glob_separator_8(__p0: *mut pcre2_real_convert_context_8, __p1: c_uint) -> c_int
extern fn pcre2_pattern_convert_8(__p0: *const u8, __p1: c_ulong, __p2: c_uint, __p3: *mut *mut u8, __p4: *mut c_ulong, __p5: *mut pcre2_real_convert_context_8) -> c_int
extern fn pcre2_converted_pattern_free_8(__p0: *mut u8) -> void
extern fn pcre2_match_context_copy_8(__p0: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_create_8(__p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_free_8(__p0: *mut pcre2_real_match_context_8) -> void
extern fn pcre2_set_callout_8(__p0: *mut pcre2_real_match_context_8, __p1: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, __p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_callout_8(__p0: *mut pcre2_real_match_context_8, __p1: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, __p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_case_callout_8(__p0: *mut pcre2_real_match_context_8, __p1: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, __p2: *mut c_void) -> c_int
extern fn pcre2_set_depth_limit_8(__p0: *mut pcre2_real_match_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_heap_limit_8(__p0: *mut pcre2_real_match_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_match_limit_8(__p0: *mut pcre2_real_match_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_offset_limit_8(__p0: *mut pcre2_real_match_context_8, __p1: c_ulong) -> c_int
extern fn pcre2_set_recursion_limit_8(__p0: *mut pcre2_real_match_context_8, __p1: c_uint) -> c_int
extern fn pcre2_set_recursion_memory_management_8(__p0: *mut pcre2_real_match_context_8, __p1: *const fn(c_ulong, *mut c_void) -> *mut c_void, __p2: *const fn(*mut c_void, *mut c_void) -> void, __p3: *mut c_void) -> c_int
extern fn pcre2_compile_8(__p0: *const u8, __p1: c_ulong, __p2: c_uint, __p3: *mut c_int, __p4: *mut c_ulong, __p5: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8
extern fn pcre2_code_free_8(__p0: *mut pcre2_real_code_8) -> void
extern fn pcre2_code_copy_8(__p0: *const pcre2_real_code_8) -> *mut pcre2_real_code_8
extern fn pcre2_code_copy_with_tables_8(__p0: *const pcre2_real_code_8) -> *mut pcre2_real_code_8
extern fn pcre2_pattern_info_8(__p0: *const pcre2_real_code_8, __p1: c_uint, __p2: *mut c_void) -> c_int
extern fn pcre2_callout_enumerate_8(__p0: *const pcre2_real_code_8, __p1: *const fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, __p2: *mut c_void) -> c_int
extern fn pcre2_match_data_create_8(__p0: c_uint, __p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_create_from_pattern_8(__p0: *const pcre2_real_code_8, __p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_free_8(__p0: *mut pcre2_real_match_data_8) -> void
extern fn pcre2_dfa_match_8(__p0: *const pcre2_real_code_8, __p1: *const u8, __p2: c_ulong, __p3: c_ulong, __p4: c_uint, __p5: *mut pcre2_real_match_data_8, __p6: *mut pcre2_real_match_context_8, __p7: *mut c_int, __p8: c_ulong) -> c_int
extern fn pcre2_match_8(__p0: *const pcre2_real_code_8, __p1: *const u8, __p2: c_ulong, __p3: c_ulong, __p4: c_uint, __p5: *mut pcre2_real_match_data_8, __p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_get_mark_8(__p0: *mut pcre2_real_match_data_8) -> *const u8
extern fn pcre2_get_match_data_size_8(__p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_match_data_heapframes_size_8(__p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_ovector_count_8(__p0: *mut pcre2_real_match_data_8) -> c_uint
extern fn pcre2_get_ovector_pointer_8(__p0: *mut pcre2_real_match_data_8) -> *mut c_ulong
extern fn pcre2_get_startchar_8(__p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_next_match_8(__p0: *mut pcre2_real_match_data_8, __p1: *mut c_ulong, __p2: *mut c_uint) -> c_int
@[c_export("pcre2_substring_copy_byname_8")]
fn pcre2_substring_copy_byname_8(__p0: *mut pcre2_real_match_data_8, __p1: *const u8, __p2: *mut u8, __p3: *mut c_ulong) -> c_int:
    var match_data = __p0
    var stringname = __p1
    var buffer = __p2
    var sizeptr = __p3
    var failrc: c_int = 0
    var entrysize: c_int = 0
    (entrysize = pcre2_substring_nametable_scan_8(match_data.code, stringname, &first, &last))
    if (if entrysize < 0: 1 else: 0) != 0:
        return entrysize

    return failrc

@[c_export("pcre2_substring_copy_bynumber_8")]
fn pcre2_substring_copy_bynumber_8(__p0: *mut pcre2_real_match_data_8, __p1: c_uint, __p2: *mut u8, __p3: *mut c_ulong) -> c_int:
    var match_data = __p0
    var stringnumber = __p1
    var buffer = __p2
    var sizeptr = __p3
    var rc: c_int = 0
    (rc = pcre2_substring_length_bynumber_8(match_data, stringnumber, &size))
    if (if rc < 0: 1 else: 0) != 0:
        return rc

    (buffer[size] = 0)
    (unsafe: *sizeptr = size)
    return 0

@[c_export("pcre2_substring_free_8")]
fn pcre2_substring_free_8(__p0: *mut u8):
    var string = __p0
    if (if string != ((0 as *mut c_void)): 1 else: 0) != 0:
        memctl.free(memctl, memctl.memory_data)


@[c_export("pcre2_substring_get_byname_8")]
fn pcre2_substring_get_byname_8(__p0: *mut pcre2_real_match_data_8, __p1: *const u8, __p2: *mut *mut u8, __p3: *mut c_ulong) -> c_int:
    var match_data = __p0
    var stringname = __p1
    var stringptr = __p2
    var sizeptr = __p3
    var failrc: c_int = 0
    var entrysize: c_int = 0
    (entrysize = pcre2_substring_nametable_scan_8(match_data.code, stringname, &first, &last))
    if (if entrysize < 0: 1 else: 0) != 0:
        return entrysize

    return failrc

@[c_export("pcre2_substring_get_bynumber_8")]
fn pcre2_substring_get_bynumber_8(__p0: *mut pcre2_real_match_data_8, __p1: c_uint, __p2: *mut *mut u8, __p3: *mut c_ulong) -> c_int:
    var match_data = __p0
    var stringnumber = __p1
    var stringptr = __p2
    var sizeptr = __p3
    var rc: c_int = 0
    (rc = pcre2_substring_length_bynumber_8(match_data, stringnumber, &size))
    if (if rc < 0: 1 else: 0) != 0:
        return rc

    (yield_[size] = 0)
    (unsafe: *stringptr = yield_)
    (unsafe: *sizeptr = size)
    return 0

@[c_export("pcre2_substring_length_byname_8")]
fn pcre2_substring_length_byname_8(__p0: *mut pcre2_real_match_data_8, __p1: *const u8, __p2: *mut c_ulong) -> c_int:
    var match_data = __p0
    var stringname = __p1
    var sizeptr = __p2
    var failrc: c_int = 0
    var entrysize: c_int = 0
    (entrysize = pcre2_substring_nametable_scan_8(match_data.code, stringname, &first, &last))
    if (if entrysize < 0: 1 else: 0) != 0:
        return entrysize

    return failrc

@[c_export("pcre2_substring_length_bynumber_8")]
fn pcre2_substring_length_bynumber_8(__p0: *mut pcre2_real_match_data_8, __p1: c_uint, __p2: *mut c_ulong) -> c_int:
    var match_data = __p0
    var stringnumber = __p1
    var sizeptr = __p2
    var count: c_int = match_data.rc
    (left = match_data.ovector[(stringnumber *% 2)])
    (right = match_data.ovector[((stringnumber *% 2) +% 1)])
    if (if sizeptr != ((0 as *mut c_void)): 1 else: 0) != 0:
        (unsafe: *sizeptr = (if ((if left > right: 1 else: 0)) != 0: 0 else: (right -% left)))

    return 0

@[c_export("pcre2_substring_nametable_scan_8")]
fn pcre2_substring_nametable_scan_8(__p0: *const pcre2_real_code_8, __p1: *const u8, __p2: *mut *const u8, __p3: *mut *const u8) -> c_int:
    var code = __p0
    var stringname = __p1
    var firstptr = __p2
    var lastptr = __p3
    while (if top > bot: 1 else: 0) != 0:
        var c: c_int = _pcre2_strcmp_8(stringname, (entry + (2 as isize as usize)))
        if (if c == 0: 1 else: 0) != 0:
            (lastentry = (nametable + ((entrysize * ((code.name_count - 1))) as isize as usize)))
            (first = (last = entry))
            while (if first > nametable: 1 else: 0) != 0:
                if (if _pcre2_strcmp_8(stringname, (((first - (entrysize as isize as usize)) + (2 as isize as usize)))) != 0: 1 else: 0) != 0:
                    break

                first = first - entrysize

            while (if last < lastentry: 1 else: 0) != 0:
                if (if _pcre2_strcmp_8(stringname, (((last + (entrysize as isize as usize)) + (2 as isize as usize)))) != 0: 1 else: 0) != 0:
                    break

                last = last + entrysize

            (unsafe: *firstptr = first)
            (unsafe: *lastptr = last)
            return entrysize

        if (if c > 0: 1 else: 0) != 0:
            (bot = (mid + 1))
        else:
            (top = mid)



@[c_export("pcre2_substring_number_from_name_8")]
fn pcre2_substring_number_from_name_8(__p0: *const pcre2_real_code_8, __p1: *const u8) -> c_int:
    var code = __p0
    var stringname = __p1
    return pcre2_substring_nametable_scan_8(code, stringname, ((0 as *mut c_void)), ((0 as *mut c_void)))

@[c_export("pcre2_substring_list_free_8")]
fn pcre2_substring_list_free_8(__p0: *mut *mut u8):
    var list = __p0
    if (if list != ((0 as *mut c_void)): 1 else: 0) != 0:
        memctl.free(memctl, memctl.memory_data)


@[c_export("pcre2_substring_list_get_8")]
fn pcre2_substring_list_get_8(__p0: *mut pcre2_real_match_data_8, __p1: *mut *mut *mut u8, __p2: *mut *mut c_ulong) -> c_int:
    var match_data = __p0
    var listptr = __p1
    var lengthsptr = __p2
    var i: c_int = 0
    var count: c_int = 0
    var count2: c_int = 0
    if (if ((count = match_data.rc)) < 0: 1 else: 0) != 0:
        return count

    if (if count == 0: 1 else: 0) != 0:
        (count = match_data.oveccount)

    (count2 = (2 * count))
    (ovector = match_data.ovector)
    (size = (sizeof[pcre2_memctl]() +% sizeof[u8]()))
    if (if lengthsptr != ((0 as *mut c_void)): 1 else: 0) != 0:
        size = size + (sizeof[c_ulong]() *% count)

    (i = 0)
    while (if i < count2: 1 else: 0) != 0:
        size = size + (sizeof[u8]() +% 1)
        i = i + 2

    if (if lengthsptr == ((0 as *mut c_void)): 1 else: 0) != 0:
        (lensp = ((0 as *mut c_void)))
    else:
        (unsafe: *lengthsptr = lensp)

    (i = 0)
    while (if i < count2: 1 else: 0) != 0:
        (size = (if ((if ovector[(i + 1)] > ovector[i]: 1 else: 0)) != 0: ((ovector[(i + 1)] -% ovector[i])) else: 0))
        (unsafe: *(listp = listp + 1) = sp)
        if (if lensp != ((0 as *mut c_void)): 1 else: 0) != 0:
            (unsafe: *(lensp = lensp + 1) = size)

        sp = sp + size
        (unsafe: *(sp = sp + 1) = 0)
        i = i + 2

    (unsafe: *listp = ((0 as *mut c_void)))
    return 0

extern fn pcre2_serialize_encode_8(__p0: *mut *const pcre2_real_code_8, __p1: c_int, __p2: *mut *mut u8, __p3: *mut c_ulong, __p4: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_decode_8(__p0: *mut *mut pcre2_real_code_8, __p1: c_int, __p2: *const u8, __p3: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_get_number_of_codes_8(__p0: *const u8) -> c_int
extern fn pcre2_serialize_free_8(__p0: *mut u8) -> void
extern fn pcre2_substitute_8(__p0: *const pcre2_real_code_8, __p1: *const u8, __p2: c_ulong, __p3: c_ulong, __p4: c_uint, __p5: *mut pcre2_real_match_data_8, __p6: *mut pcre2_real_match_context_8, __p7: *const u8, __p8: c_ulong, __p9: *mut u8, __p10: *mut c_ulong) -> c_int
extern fn pcre2_jit_compile_8(__p0: *mut pcre2_real_code_8, __p1: c_uint) -> c_int
extern fn pcre2_jit_match_8(__p0: *const pcre2_real_code_8, __p1: *const u8, __p2: c_ulong, __p3: c_ulong, __p4: c_uint, __p5: *mut pcre2_real_match_data_8, __p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_jit_free_unused_memory_8(__p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_jit_stack_create_8(__p0: c_ulong, __p1: c_ulong, __p2: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8
extern fn pcre2_jit_stack_assign_8(__p0: *mut pcre2_real_match_context_8, __p1: *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8, __p2: *mut c_void) -> void
extern fn pcre2_jit_stack_free_8(__p0: *mut pcre2_real_jit_stack_8) -> void
extern fn pcre2_get_error_message_8(__p0: c_int, __p1: *mut u8, __p2: c_ulong) -> c_int
extern fn pcre2_maketables_8(__p0: *mut pcre2_real_general_context_8) -> *const u8
extern fn pcre2_maketables_free_8(__p0: *mut pcre2_real_general_context_8, __p1: *const u8) -> void
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
