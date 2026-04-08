// Migrated from PCRE2
use std.re.defs

type PCRE2_UCHAR8 = u8
type PCRE2_UCHAR16 = c_ushort
type PCRE2_UCHAR32 = c_uint
type PCRE2_SPTR8 = *const u8
type PCRE2_SPTR16 = *const c_ushort
type PCRE2_SPTR32 = *const c_uint
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
let REG_ASSERT: c_uint = 1
let REG_BADBR: c_uint = 2
let REG_BADPAT: c_uint = 3
let REG_BADRPT: c_uint = 4
let REG_EBRACE: c_uint = 5
let REG_EBRACK: c_uint = 6
let REG_ECOLLATE: c_uint = 7
let REG_ECTYPE: c_uint = 8
let REG_EESCAPE: c_uint = 9
let REG_EMPTY: c_uint = 10
let REG_EPAREN: c_uint = 11
let REG_ERANGE: c_uint = 12
let REG_ESIZE: c_uint = 13
let REG_ESPACE: c_uint = 14
let REG_ESUBREG: c_uint = 15
let REG_INVARG: c_uint = 16
let REG_NOMATCH: c_uint = 17
type regex_t { re_pcre2_code: *mut c_void = null, re_match_data: *mut c_void = null, re_endp: *const i8 = null, re_nsub: c_ulong = 0, re_erroffset: c_ulong = 0, re_cflags: c_int = 0 }
type struct_regex_t = regex_t
type regoff_t = c_int
type regmatch_t { rm_so: c_int = 0, rm_eo: c_int = 0 }
type struct_regmatch_t = regmatch_t
@[c_export("pcre2_regcomp")]
fn pcre2_regcomp(preg: *mut regex_t, pattern: *const i8, cflags: c_int) -> c_int:
    var erroffset: c_ulong = 0 // init: untranslatable
    var patlen: c_ulong = 0 // init: untranslatable
    var errorcode: c_int = 0
    var options: c_int = 0
    var re_nsub: c_int = 0
    (preg.re_match_data = null)
    (preg.re_pcre2_code = null)
    if (if ((cflags & 1)) != 0: 1 else: 0) != 0:
        options = options | 8

    if (if ((cflags & 2)) != 0: 1 else: 0) != 0:
        options = options | 1024

    if (if ((cflags & 16)) != 0: 1 else: 0) != 0:
        options = options | 32

    if (if ((cflags & 4096)) != 0: 1 else: 0) != 0:
        options = options | 33554432

    if (if ((cflags & 64)) != 0: 1 else: 0) != 0:
        options = options | 524288

    if (if ((cflags & 1024)) != 0: 1 else: 0) != 0:
        options = options | 131072

    if (if ((cflags & 512)) != 0: 1 else: 0) != 0:
        options = options | 262144

    (preg.re_cflags = cflags)
    (preg.re_erroffset = erroffset)
    if (if preg.re_pcre2_code == null: 1 else: 0) != 0:
        var i: c_uint = 0
        if (if errorcode < 100: 1 else: 0) != 0:
            return REG_BADPAT

        errorcode = errorcode - 100
        (i = 0)
        while true:
            if (if errorcode == eint2[i]: 1 else: 0) != 0:
                return eint2[(i +% 1)]
            i = i + 2

        return REG_BADPAT

    (preg.re_match_data = pcre2_match_data_create_8((re_nsub + 1), null))
    if (if preg.re_match_data == null: 1 else: 0) != 0:
        pcre2_code_free_8(preg.re_pcre2_code)
        (preg.re_pcre2_code = null)
        return REG_ESPACE

    return 0

@[c_export("pcre2_regexec")]
fn pcre2_regexec(preg: *const regex_t, string: *const i8, __param_nmatch: c_ulong, pmatch: *mut regmatch_t, eflags: c_int) -> c_int:
    var nmatch = __param_nmatch
    var rc: c_int = 0
    var so: c_int = 0
    var eo: c_int = 0
    var options: c_int = 0
    var md: *mut pcre2_real_match_data_8 = null // init: untranslatable
    if (if string == null: 1 else: 0) != 0:
        return REG_INVARG

    if (if ((eflags & 4)) != 0: 1 else: 0) != 0:
        options = options | 1

    if (if ((eflags & 8)) != 0: 1 else: 0) != 0:
        options = options | 2

    if (if ((eflags & 256)) != 0: 1 else: 0) != 0:
        options = options | 4

    if (if (if ((preg.re_cflags & 32)) != 0: 1 else: 0) != 0 or (if pmatch == null: 1 else: 0) != 0: 1 else: 0) != 0:
        (nmatch = 0)

    if (if ((eflags & 128)) != 0: 1 else: 0) != 0:
        if (if pmatch == null: 1 else: 0) != 0:
            return REG_INVARG

        (so = pmatch[0].rm_so)
        (eo = pmatch[0].rm_eo)
    else:
        (so = 0)
        (eo = (string_len(string) as c_int))

    if (if rc >= 0: 1 else: 0) != 0:
        var i: c_ulong = 0 // init: untranslatable
        var ovector: *mut c_ulong = null // init: untranslatable
        while (if i < nmatch: 1 else: 0) != 0:
            pmatch[i].rm_eo = -1
            pmatch[i].rm_so = -1
            i = i + 1

        return 0

    match rc
        _ =>
            return REG_ASSERT


@[c_export("pcre2_regerror")]
fn pcre2_regerror(errcode: c_int, preg: *const regex_t, errbuf: *mut i8, errbuf_size: c_ulong) -> c_ulong:
    var message: *const i8 = null
    var offset_buf: [23]c_char = (11 + 12)
    var snprintf_rc: c_int = 0
    var have_offset: c_int = 0
    var i: c_ulong = 0 // init: untranslatable
    (i = 0)
    while (if unsafe: *message != 0: 1 else: 0) != 0:
if (if (i +% 1) < errbuf_size: 1 else: 0) != 0:
            (errbuf[i] = unsafe: *message)

    if have_offset != 0:
        (message = offset_buf)
        while (if unsafe: *message != 0: 1 else: 0) != 0:
if (if (i +% 1) < errbuf_size: 1 else: 0) != 0:
                (errbuf[i] = unsafe: *message)


    if (if errbuf_size > 0: 1 else: 0) != 0:
        (errbuf[(if ((if i < errbuf_size: 1 else: 0)) != 0: i else: (errbuf_size -% 1))] = 0)

    (i = i + 1)
    return (i as c_int)

@[c_export("pcre2_regfree")]
fn pcre2_regfree(preg: *mut regex_t):
    pcre2_match_data_free_8(preg.re_match_data)
    pcre2_code_free_8(preg.re_pcre2_code)

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
