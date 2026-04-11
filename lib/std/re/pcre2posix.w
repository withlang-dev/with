// Migrated from PCRE2
use std.re.defs

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
fn pcre2_regcomp(preg: *mut regex_t, pattern: *const i8, cflags: c_int) -> c_int:
    var erroffset: c_ulong
    var patlen: c_ulong
    var errorcode: c_int
    var options: c_int = 0
    var re_nsub: c_int = 0
    (preg.re_match_data = null)
    (preg.re_pcre2_code = null)
    (patlen = (if ((if ((cflags & 2048)) != 0: 1 else: 0)) != 0: ((((preg.re_endp as usize -% pattern as usize) / sizeof[c_char]())) as c_ulong) else: ((0 -% 1))))
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
    (preg.re_pcre2_code = (pcre2_compile_8((pattern as *const u8), patlen, options, (&mut errorcode as *mut c_int), (&mut erroffset as *mut c_ulong), (null as *mut pcre2_real_compile_context_8)) as *mut c_void))
    (preg.re_erroffset = erroffset)
    if (if preg.re_pcre2_code == null: 1 else: 0) != 0:
        var i: c_uint
        if (if errorcode < 100: 1 else: 0) != 0:
            return REG_BADPAT
        
        errorcode = errorcode - 100
        (i = 0)
        while true:
            if (if errorcode == (&eint2[0] as *mut c_int)[i]: 1 else: 0) != 0:
                return (&eint2[0] as *mut c_int)[(i +% 1)]
            i = i + 2
        
        return REG_BADPAT

    pcre2_pattern_info_8((preg.re_pcre2_code as *const pcre2_real_code_8), 4, ((&mut re_nsub as *mut c_int) as *mut c_void))
    (preg.re_nsub = (re_nsub as c_ulong))
    (preg.re_match_data = (pcre2_match_data_create_8((re_nsub + 1), (null as *mut pcre2_real_general_context_8)) as *mut c_void))
    (preg.re_erroffset = ((-1) as c_ulong))
    if (if preg.re_match_data == null: 1 else: 0) != 0:
        pcre2_code_free_8((preg.re_pcre2_code as *mut pcre2_real_code_8))
        (preg.re_pcre2_code = null)
        return REG_ESPACE

    return 0

fn pcre2_regexec(preg: *const regex_t, string: *const i8, __param_nmatch: c_ulong, pmatch: *mut regmatch_t, eflags: c_int) -> c_int:
    var nmatch = __param_nmatch
    var rc: c_int
    var so: c_int
    var eo: c_int
    var options: c_int = 0
    var md: *mut pcre2_real_match_data_8 = (preg.re_match_data as *mut pcre2_real_match_data_8)
    if (if string == (null as *const i8): 1 else: 0) != 0:
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

    (rc = pcre2_match_8((preg.re_pcre2_code as *const pcre2_real_code_8), ((string as *const u8) + (so as isize as usize)), ((eo - so)), 0, options, md, (null as *mut pcre2_real_match_context_8)))
    if (if rc >= 0: 1 else: 0) != 0:
        var i: c_ulong
        var ovector: *mut c_ulong = pcre2_get_ovector_pointer_8(md)
        if (if (rc as c_ulong) > nmatch: 1 else: 0) != 0:
            (rc = (nmatch as c_int))
        
        (i = 0)
        while (if i < (rc as c_ulong): 1 else: 0) != 0:
            (pmatch[i].rm_so = (if ((if ovector[(i *% 2)] == ((0 -% 1)): 1 else: 0)) != 0: -1 else: (((ovector[(i *% 2)] +% so)) as c_int)))
            (pmatch[i].rm_eo = (if ((if ovector[((i *% 2) +% 1)] == ((0 -% 1)): 1 else: 0)) != 0: -1 else: (((ovector[((i *% 2) +% 1)] +% so)) as c_int)))
            (i = i + 1)
        
        while (if i < nmatch: 1 else: 0) != 0:
            (pmatch[i].rm_eo = -1)
            (pmatch[i].rm_so = pmatch[i].rm_eo)
            (i = i + 1)
        
        return 0

    if (if (if rc <= (-3): 1 else: 0) != 0 and (if rc >= (-23): 1 else: 0) != 0: 1 else: 0) != 0:
        return REG_INVARG

    match rc
        (-63) =>
            return REG_ESPACE
        (-1) =>
            return REG_NOMATCH
        (-32) =>
            return REG_INVARG
        (-31) =>
            return REG_INVARG
        (-34) =>
            return REG_INVARG
        (-36) =>
            return REG_INVARG
        (-47) =>
            return REG_ESPACE
        (-48) =>
            return REG_ESPACE
        (-51) =>
            return REG_INVARG
        _ =>
            return REG_ASSERT


fn pcre2_regerror(errcode: c_int, preg: *const regex_t, errbuf: *mut i8, errbuf_size: c_ulong) -> c_ulong:
    var message: *const i8
    var offset_buf: [23]c_char
    var snprintf_rc: c_int
    var have_offset: c_int = 0
    var i: c_ulong
    (i = 0)
    while (if (unsafe: *message) != 0: 1 else: 0) != 0:
        if (if (i +% 1) < errbuf_size: 1 else: 0) != 0:
            (errbuf[i] = (unsafe: *message))

    if have_offset != 0:
        (message = ((&offset_buf[0] as *mut c_char) as *const i8))
        while (if (unsafe: *message) != 0: 1 else: 0) != 0:
            if (if (i +% 1) < errbuf_size: 1 else: 0) != 0:
                (errbuf[i] = (unsafe: *message))
        

    if (if errbuf_size > 0: 1 else: 0) != 0:
        (errbuf[(if ((if i < errbuf_size: 1 else: 0)) != 0: i else: (errbuf_size -% 1))] = 0)

    (i = i + 1)
    return (i as c_int)

fn pcre2_regfree(preg: *mut regex_t):
    pcre2_match_data_free_8((preg.re_match_data as *mut pcre2_real_match_data_8))
    pcre2_code_free_8((preg.re_pcre2_code as *mut pcre2_real_code_8))

var eint1: [24]c_int = [0, REG_EESCAPE, REG_EESCAPE, REG_EESCAPE, REG_BADBR, REG_BADBR, REG_EBRACK, REG_ECTYPE, REG_ERANGE, REG_BADRPT, REG_ASSERT, REG_BADPAT, REG_BADPAT, REG_BADPAT, REG_EPAREN, REG_ESUBREG, REG_INVARG, REG_INVARG, REG_EPAREN, REG_ESIZE, REG_ESIZE, REG_ESPACE, REG_EPAREN, REG_ASSERT]
var eint2: [16]c_int = [30, REG_ECTYPE, 32, REG_INVARG, 37, REG_EESCAPE, 56, REG_INVARG, 92, REG_INVARG, 98, REG_EESCAPE, 99, REG_EESCAPE, 102, REG_EESCAPE]
var pstring: [18]*const i8 = ["", "internal error", "invalid repeat counts in {}", "pattern error", "? * + invalid", "unbalanced {}", "unbalanced []", "collation error - not relevant", "bad class", "bad escape sequence", "empty expression", "unbalanced ()", "bad range inside []", "expression too big", "failed to get memory", "bad back reference", "bad argument", "match failed"]
// untranslatable fn-like macro
fn ARR_SIZE() -> Never:
    comptime_error("untranslatable C macro: ARR_SIZE")
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
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
let PCRE2regcomp: c_int = pcre2_regcomp
let PCRE2regerror: c_int = pcre2_regerror
let PCRE2regexec: c_int = pcre2_regexec
let PCRE2regfree: c_int = pcre2_regfree
fn PRIV[T](name: T) -> T:
    name
let REG_DOTALL: c_int = 0x0010
let REG_EXTENDED: c_int = 0
let REG_ICASE: c_int = 0x0001
let REG_NEWLINE: c_int = 0x0002
let REG_NOSPEC: c_int = 0x1000
let REG_NOSUB: c_int = 0x0020
let REG_NOTBOL: c_int = 0x0004
let REG_NOTEMPTY: c_int = 0x0100
let REG_NOTEOL: c_int = 0x0008
let REG_PEND: c_int = 0x0800
let REG_STARTEND: c_int = 0x0080
let REG_UCP: c_int = 0x0400
let REG_UNGREEDY: c_int = 0x0200
let REG_UTF: c_int = 0x0040
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
let regcomp: c_int = pcre2_regcomp
let regerror: c_int = pcre2_regerror
let regexec: c_int = pcre2_regexec
let regfree: c_int = pcre2_regfree
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
