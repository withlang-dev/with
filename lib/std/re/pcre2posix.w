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
@[c_export("pcre2_regcomp")]
fn pcre2_regcomp(preg: *mut regex_t, pattern: *const i8, cflags: c_int) -> c_int:
    var erroffset: c_ulong
    var patlen: c_ulong
    var errorcode: c_int
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

    (preg.re_match_data = (pcre2_match_data_create_8((re_nsub + 1), (null as *mut pcre2_real_general_context_8)) as *mut c_void))
    if (if preg.re_match_data == null: 1 else: 0) != 0:
        pcre2_code_free_8((preg.re_pcre2_code as *mut pcre2_real_code_8))
        (preg.re_pcre2_code = null)
        return REG_ESPACE

    return 0

@[c_export("pcre2_regexec")]
fn pcre2_regexec(preg: *const regex_t, string: *const i8, __param_nmatch: c_ulong, pmatch: *mut regmatch_t, eflags: c_int) -> c_int:
    var nmatch = __param_nmatch
    var rc: c_int
    var so: c_int
    var eo: c_int
    var options: c_int = 0
    var md: *mut pcre2_real_match_data_8
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

    if (if rc >= 0: 1 else: 0) != 0:
        var i: c_ulong
        var ovector: *mut c_ulong
        while (if i < nmatch: 1 else: 0) != 0:
            (pmatch[i].rm_eo = -1)
            (pmatch[i].rm_so = pmatch[i].rm_eo)
            (i = i + 1)
        
        return 0

    match rc
        _ =>
            return REG_ASSERT


@[c_export("pcre2_regerror")]
fn pcre2_regerror(errcode: c_int, preg: *const regex_t, errbuf: *mut i8, errbuf_size: c_ulong) -> c_ulong:
    var message: *const i8
    var offset_buf: [23]c_char
    var snprintf_rc: c_int
    var have_offset: c_int = 0
    var i: c_ulong
    (i = 0)
    while (if unsafe: *message != 0: 1 else: 0) != 0:
        if (if (i +% 1) < errbuf_size: 1 else: 0) != 0:
            (errbuf[i] = unsafe: *message)

    if have_offset != 0:
        (message = ((&offset_buf[0] as *mut c_char) as *const i8))
        while (if unsafe: *message != 0: 1 else: 0) != 0:
            if (if (i +% 1) < errbuf_size: 1 else: 0) != 0:
                (errbuf[i] = unsafe: *message)
        

    if (if errbuf_size > 0: 1 else: 0) != 0:
        (errbuf[(if ((if i < errbuf_size: 1 else: 0)) != 0: i else: (errbuf_size -% 1))] = 0)

    (i = i + 1)
    return (i as c_int)

@[c_export("pcre2_regfree")]
fn pcre2_regfree(preg: *mut regex_t):
    pcre2_match_data_free_8((preg.re_match_data as *mut pcre2_real_match_data_8))
    pcre2_code_free_8((preg.re_pcre2_code as *mut pcre2_real_code_8))

extern var eint1: [24]c_int
extern var eint2: [16]c_int
extern var pstring: [18]*const i8
let ARG_MAX: c_int = 1048576
// untranslatable fn-like macro
fn ARR_SIZE() -> Never:
    comptime_error("untranslatable C macro: ARR_SIZE")
let BC_BASE_MAX: c_int = 99
let BC_DIM_MAX: c_int = 2048
let BC_SCALE_MAX: c_int = 99
let BC_STRING_MAX: c_int = 1000
let BUFSIZ: c_int = 1024
let BUS_ADRALN: c_int = 1
let BUS_ADRERR: c_int = 2
let BUS_NOOP: c_int = 0
let BUS_OBJERR: c_int = 3
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
let CHARCLASS_NAME_MAX: c_int = 14
let CHAR_BIT: c_int = 8
let CHAR_MAX: c_int = 127
let CHILD_MAX: c_int = 266
let CLD_CONTINUED: c_int = 6
let CLD_DUMPED: c_int = 3
let CLD_EXITED: c_int = 1
let CLD_KILLED: c_int = 2
let CLD_NOOP: c_int = 0
let CLD_STOPPED: c_int = 5
let CLD_TRAPPED: c_int = 4
let COLL_WEIGHTS_MAX: c_int = 2
let COMPILE_ERROR_BASE: c_int = 100
let CPUMON_MAKE_FATAL: c_int = 0x1000
let EOF: c_int = -1
let EQUIV_CLASS_MAX: c_int = 2
let EXIT_FAILURE: c_int = 1
let EXIT_SUCCESS: c_int = 0
let EXPR_NEST_MAX: c_int = 32
let FILENAME_MAX: c_int = 1024
let FOOTPRINT_INTERVAL_RESET: c_int = 0x1
let FOPEN_MAX: c_int = 20
let FPE_FLTDIV: c_int = 1
let FPE_FLTINV: c_int = 5
let FPE_FLTOVF: c_int = 2
let FPE_FLTRES: c_int = 4
let FPE_FLTSUB: c_int = 6
let FPE_FLTUND: c_int = 3
let FPE_INTDIV: c_int = 7
let FPE_INTOVF: c_int = 8
let FPE_NOOP: c_int = 0
let GID_MAX: c_uint = 2147483647
let HAVE_CONFIG_H: c_int = 1
let HEAP_LIMIT: c_int = 20000000
// untranslatable fn-like macro
fn HTONL() -> Never:
    comptime_error("untranslatable C macro: HTONL")
// untranslatable fn-like macro
fn HTONLL() -> Never:
    comptime_error("untranslatable C macro: HTONLL")
// untranslatable fn-like macro
fn HTONS() -> Never:
    comptime_error("untranslatable C macro: HTONS")
let ILL_BADSTK: c_int = 8
let ILL_COPROC: c_int = 7
let ILL_ILLADR: c_int = 5
let ILL_ILLOPC: c_int = 1
let ILL_ILLOPN: c_int = 4
let ILL_ILLTRP: c_int = 2
let ILL_NOOP: c_int = 0
let ILL_PRVOPC: c_int = 3
let ILL_PRVREG: c_int = 6
fn INT16_C[T](v: T) -> T:
    v
let INT16_MAX: c_int = 32767
let INT16_MIN: c_int = -32768
fn INT32_C[T](v: T) -> T:
    v
let INT32_MAX: c_int = 2147483647
let INT32_MIN: c_int = -2147483646
fn INT64_C[T](v: T) -> i64:
    (v as i64)
let INT64_MAX: c_longlong = 9223372036854775807
let INT64_MIN: c_int = -9223372036854775806
fn INT8_C[T](v: T) -> T:
    v
let INT8_MAX: c_int = 127
let INT8_MIN: c_int = -128
fn INTMAX_C[T](v: T) -> i64:
    (v as i64)
let INTMAX_MAX: c_int = INTMAX_C(9223372036854775807)
let INTMAX_MIN: c_int = ((0 - INTMAX_MAX) - 1)
let INTPTR_MAX: c_long = 9223372036854775807
let INTPTR_MIN: c_int = -9223372036854775806
let INT_FAST16_MAX: c_int = 32767
let INT_FAST16_MIN: c_int = -32768
let INT_FAST32_MAX: c_int = 2147483647
let INT_FAST32_MIN: c_int = -2147483646
let INT_FAST64_MAX: c_int = 9223372036854775807
let INT_FAST64_MIN: c_int = -9223372036854775806
let INT_FAST8_MAX: c_int = 127
let INT_FAST8_MIN: c_int = -128
let INT_LEAST16_MAX: c_int = 32767
let INT_LEAST16_MIN: c_int = -32768
let INT_LEAST32_MAX: c_int = 2147483647
let INT_LEAST32_MIN: c_int = -2147483646
let INT_LEAST64_MAX: c_int = 9223372036854775807
let INT_LEAST64_MIN: c_int = -9223372036854775806
let INT_LEAST8_MAX: c_int = 127
let INT_LEAST8_MIN: c_int = -128
let INT_MAX: c_int = 2147483647
let INT_MIN: c_int = -2147483646
let IOPOL_ATIME_UPDATES_DEFAULT: c_int = 0
let IOPOL_ATIME_UPDATES_OFF: c_int = 1
let IOPOL_DEFAULT: c_int = 0
let IOPOL_IMPORTANT: c_int = 1
let IOPOL_MATERIALIZE_DATALESS_FILES_BASIC_MASK: c_int = 3
let IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT: c_int = 0
let IOPOL_MATERIALIZE_DATALESS_FILES_OFF: c_int = 1
let IOPOL_MATERIALIZE_DATALESS_FILES_ON: c_int = 2
let IOPOL_MATERIALIZE_DATALESS_FILES_ORIG: c_int = 4
let IOPOL_NORMAL: c_int = 1
let IOPOL_PASSIVE: c_int = 2
let IOPOL_SCOPE_DARWIN_BG: c_int = 2
let IOPOL_SCOPE_PROCESS: c_int = 0
let IOPOL_SCOPE_THREAD: c_int = 1
let IOPOL_STANDARD: c_int = 5
let IOPOL_THROTTLE: c_int = 3
let IOPOL_TYPE_DISK: c_int = 0
let IOPOL_TYPE_VFS_ALLOW_LOW_SPACE_WRITES: c_int = 9
let IOPOL_TYPE_VFS_ATIME_UPDATES: c_int = 2
let IOPOL_TYPE_VFS_DISALLOW_RW_FOR_O_EVTONLY: c_int = 10
let IOPOL_TYPE_VFS_ENTITLED_RESERVE_ACCESS: c_int = 14
let IOPOL_TYPE_VFS_IGNORE_CONTENT_PROTECTION: c_int = 6
let IOPOL_TYPE_VFS_IGNORE_PERMISSIONS: c_int = 7
let IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES: c_int = 3
let IOPOL_TYPE_VFS_SKIP_MTIME_UPDATE: c_int = 8
let IOPOL_TYPE_VFS_STATFS_NO_DATA_VOLUME: c_int = 4
let IOPOL_TYPE_VFS_TRIGGER_RESOLVE: c_int = 5
let IOPOL_UTILITY: c_int = 4
let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_OFF: c_int = 0
let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_ON: c_int = 1
let IOPOL_VFS_CONTENT_PROTECTION_DEFAULT: c_int = 0
let IOPOL_VFS_CONTENT_PROTECTION_IGNORE: c_int = 1
let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_DEFAULT: c_int = 0
let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_ON: c_int = 1
let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_OFF: c_int = 0
let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_ON: c_int = 1
let IOPOL_VFS_IGNORE_PERMISSIONS_OFF: c_int = 0
let IOPOL_VFS_IGNORE_PERMISSIONS_ON: c_int = 1
let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_DEFAULT: c_int = 0
let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_ON: c_int = 1
let IOPOL_VFS_SKIP_MTIME_UPDATE_IGNORE: c_int = 2
let IOPOL_VFS_SKIP_MTIME_UPDATE_OFF: c_int = 0
let IOPOL_VFS_SKIP_MTIME_UPDATE_ON: c_int = 1
let IOPOL_VFS_STATFS_FORCE_NO_DATA_VOLUME: c_int = 1
let IOPOL_VFS_STATFS_NO_DATA_VOLUME_DEFAULT: c_int = 0
let IOPOL_VFS_TRIGGER_RESOLVE_DEFAULT: c_int = 0
let IOPOL_VFS_TRIGGER_RESOLVE_OFF: c_int = 1
let IOV_MAX: c_int = 1024
let LINE_MAX: c_int = 2048
let LINK_MAX: c_int = 32767
let LINK_SIZE: c_int = 2
let LLONG_MAX: c_int = 9223372036854775807
let LLONG_MIN: c_int = -9223372036854775806
let LONG_BIT: c_int = 64
let LONG_LONG_MAX: c_int = 9223372036854775807
let LONG_LONG_MIN: c_int = -9223372036854775806
let LONG_MAX: c_int = 9223372036854775807
let LONG_MIN: c_int = -9223372036854775806
let LT_OBJDIR = ".libs/"
let L_ctermid: c_int = 1024
let L_tmpnam: c_int = 1024
let MATCH_LIMIT: c_int = 10000000
let MATCH_LIMIT_DEPTH: c_int = 10000000
let MAX_CANON: c_int = 1024
let MAX_INPUT: c_int = 1024
let MAX_NAME_COUNT: c_int = 10000
let MAX_NAME_SIZE: c_int = 128
let MAX_VARLOOKBEHIND: c_int = 255
let MB_LEN_MAX: c_int = 6
let MINSIGSTKSZ: c_int = 32768
let NAME_MAX: c_int = 255
let NEWLINE_DEFAULT: c_int = 2
let NGROUPS_MAX: c_int = 16
let NL_ARGMAX: c_int = 9
let NL_LANGMAX: c_int = 14
let NL_MSGMAX: c_int = 32767
let NL_NMAX: c_int = 1
let NL_SETMAX: c_int = 255
let NL_TEXTMAX: c_int = 2048
// untranslatable fn-like macro
fn NTOHL() -> Never:
    comptime_error("untranslatable C macro: NTOHL")
// untranslatable fn-like macro
fn NTOHLL() -> Never:
    comptime_error("untranslatable C macro: NTOHLL")
// untranslatable fn-like macro
fn NTOHS() -> Never:
    comptime_error("untranslatable C macro: NTOHS")
let NZERO: c_int = 20
let OFF_MAX: c_int = 9223372036854775807
let OFF_MIN: c_int = -9223372036854775806
let OPEN_MAX: c_int = 10240
let PACKAGE = "pcre2"
let PACKAGE_BUGREPORT = ""
let PACKAGE_NAME = "PCRE2"
let PACKAGE_STRING = "PCRE2 10.48-DEV"
let PACKAGE_TARNAME = "pcre2"
let PACKAGE_URL = ""
let PACKAGE_VERSION = "10.48-DEV"
let PARENS_NEST_LIMIT: c_int = 250
let PASS_MAX: c_int = 128
let PATH_MAX: c_int = 1024
let PCRE2GREP_BUFSIZE: c_int = 20480
let PCRE2GREP_MAX_BUFSIZE: c_int = 1048576
let PCRE2_ALLOW_EMPTY_CLASS: c_uint = 0x00000001
let PCRE2_ALT_BSUX: c_uint = 0x00000002
let PCRE2_ALT_CIRCUMFLEX: c_uint = 0x00200000
let PCRE2_ALT_EXTENDED_CLASS: c_uint = 0x08000000
let PCRE2_ALT_VERBNAMES: c_uint = 0x00400000
let PCRE2_ANCHORED: c_uint = 0x80000000
// untranslatable fn-like macro
fn PCRE2_ASSERT() -> Never:
    comptime_error("untranslatable C macro: PCRE2_ASSERT")
let PCRE2_AUTO_CALLOUT: c_uint = 0x00000004
let PCRE2_AUTO_POSSESS: c_int = 64
let PCRE2_AUTO_POSSESS_OFF: c_int = 65
let PCRE2_BSR_ANYCRLF: c_int = 2
let PCRE2_BSR_UNICODE: c_int = 1
let PCRE2_CALLOUT_BACKTRACK: c_uint = 0x00000002
let PCRE2_CALLOUT_STARTMATCH: c_uint = 0x00000001
let PCRE2_CASELESS: c_uint = 0x00000008
let PCRE2_CODE_UNIT_WIDTH: c_int = 8
let PCRE2_CONFIG_BSR: c_int = 0
let PCRE2_CONFIG_COMPILED_WIDTHS: c_int = 14
let PCRE2_CONFIG_DEPTHLIMIT: c_int = 7
let PCRE2_CONFIG_EFFECTIVE_LINKSIZE: c_int = 16
let PCRE2_CONFIG_HEAPLIMIT: c_int = 12
let PCRE2_CONFIG_JIT: c_int = 1
let PCRE2_CONFIG_JITTARGET: c_int = 2
let PCRE2_CONFIG_LINKSIZE: c_int = 3
let PCRE2_CONFIG_MATCHLIMIT: c_int = 4
let PCRE2_CONFIG_NEVER_BACKSLASH_C: c_int = 13
let PCRE2_CONFIG_NEWLINE: c_int = 5
let PCRE2_CONFIG_PARENSLIMIT: c_int = 6
let PCRE2_CONFIG_RECURSIONLIMIT: c_int = 7
let PCRE2_CONFIG_STACKRECURSE: c_int = 8
let PCRE2_CONFIG_TABLES_LENGTH: c_int = 15
let PCRE2_CONFIG_UNICODE: c_int = 9
let PCRE2_CONFIG_UNICODE_VERSION: c_int = 10
let PCRE2_CONFIG_VERSION: c_int = 11
let PCRE2_CONVERT_GLOB: c_uint = 0x00000010
let PCRE2_CONVERT_GLOB_NO_STARSTAR: c_uint = 0x00000050
let PCRE2_CONVERT_GLOB_NO_WILD_SEPARATOR: c_uint = 0x00000030
let PCRE2_CONVERT_NO_UTF_CHECK: c_uint = 0x00000002
let PCRE2_CONVERT_POSIX_BASIC: c_uint = 0x00000004
let PCRE2_CONVERT_POSIX_EXTENDED: c_uint = 0x00000008
let PCRE2_CONVERT_UTF: c_uint = 0x00000001
let PCRE2_COPY_MATCHED_SUBJECT: c_uint = 0x00004000
let PCRE2_DATE: c_int = 1994
// untranslatable fn-like macro
fn PCRE2_DEBUG_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_DEBUG_UNREACHABLE")
let PCRE2_DFA_RESTART: c_uint = 0x00000040
let PCRE2_DFA_SHORTEST: c_uint = 0x00000080
let PCRE2_DISABLE_RECURSELOOP_CHECK: c_uint = 0x00040000
let PCRE2_DOLLAR_ENDONLY: c_uint = 0x00000010
let PCRE2_DOTALL: c_uint = 0x00000020
let PCRE2_DOTSTAR_ANCHOR: c_int = 66
let PCRE2_DOTSTAR_ANCHOR_OFF: c_int = 67
let PCRE2_DUPNAMES: c_uint = 0x00000040
let PCRE2_ENDANCHORED: c_uint = 0x20000000
let PCRE2_ERROR_ALPHA_ASSERTION_UNKNOWN: c_int = 195
let PCRE2_ERROR_BACKSLASH_C_CALLER_DISABLED: c_int = 183
let PCRE2_ERROR_BACKSLASH_C_LIBRARY_DISABLED: c_int = 185
let PCRE2_ERROR_BACKSLASH_C_SYNTAX: c_int = 168
let PCRE2_ERROR_BACKSLASH_G_SYNTAX: c_int = 157
let PCRE2_ERROR_BACKSLASH_K_IN_LOOKAROUND: c_int = 199
let PCRE2_ERROR_BACKSLASH_K_SYNTAX: c_int = 169
let PCRE2_ERROR_BACKSLASH_N_IN_CLASS: c_int = 171
let PCRE2_ERROR_BACKSLASH_O_MISSING_BRACE: c_int = 155
let PCRE2_ERROR_BACKSLASH_U_CODE_POINT_TOO_BIG: c_int = 177
let PCRE2_ERROR_BADDATA: c_int = -29
let PCRE2_ERROR_BADMAGIC: c_int = -31
let PCRE2_ERROR_BADMODE: c_int = -32
let PCRE2_ERROR_BADOFFSET: c_int = -33
let PCRE2_ERROR_BADOFFSETLIMIT: c_int = -56
let PCRE2_ERROR_BADOPTION: c_int = -34
let PCRE2_ERROR_BADREPESCAPE: c_int = -57
let PCRE2_ERROR_BADREPLACEMENT: c_int = -35
let PCRE2_ERROR_BADSERIALIZEDDATA: c_int = -62
let PCRE2_ERROR_BADSUBSPATTERN: c_int = -60
let PCRE2_ERROR_BADSUBSTITUTION: c_int = -59
let PCRE2_ERROR_BADUTFOFFSET: c_int = -36
let PCRE2_ERROR_BAD_BACKSLASH_K: c_int = -75
let PCRE2_ERROR_BAD_LITERAL_OPTIONS: c_int = 192
let PCRE2_ERROR_BAD_OPTIONS: c_int = 117
let PCRE2_ERROR_BAD_RELATIVE_REFERENCE: c_int = 129
let PCRE2_ERROR_BAD_SUBPATTERN_REFERENCE: c_int = 115
let PCRE2_ERROR_CALLOUT: c_int = -37
let PCRE2_ERROR_CALLOUT_BAD_STRING_DELIMITER: c_int = 182
let PCRE2_ERROR_CALLOUT_CALLER_DISABLED: c_int = 203
let PCRE2_ERROR_CALLOUT_NO_STRING_DELIMITER: c_int = 181
let PCRE2_ERROR_CALLOUT_NUMBER_TOO_BIG: c_int = 138
let PCRE2_ERROR_CALLOUT_STRING_TOO_LONG: c_int = 172
let PCRE2_ERROR_CLASS_INVALID_RANGE: c_int = 150
let PCRE2_ERROR_CLASS_RANGE_ORDER: c_int = 108
let PCRE2_ERROR_CODE_POINT_TOO_BIG: c_int = 134
let PCRE2_ERROR_CONDITION_ASSERTION_EXPECTED: c_int = 128
let PCRE2_ERROR_CONVERT_SYNTAX: c_int = -64
let PCRE2_ERROR_DEFINE_TOO_MANY_BRANCHES: c_int = 154
let PCRE2_ERROR_DEPTHLIMIT: c_int = -53
let PCRE2_ERROR_DFA_BADRESTART: c_int = -38
let PCRE2_ERROR_DFA_RECURSE: c_int = -39
let PCRE2_ERROR_DFA_UCOND: c_int = -40
let PCRE2_ERROR_DFA_UFUNC: c_int = -41
let PCRE2_ERROR_DFA_UINVALID_UTF: c_int = -66
let PCRE2_ERROR_DFA_UITEM: c_int = -42
let PCRE2_ERROR_DFA_WSSIZE: c_int = -43
let PCRE2_ERROR_DIFFSUBSOFFSET: c_int = -73
let PCRE2_ERROR_DIFFSUBSOPTIONS: c_int = -74
let PCRE2_ERROR_DIFFSUBSPATTERN: c_int = -71
let PCRE2_ERROR_DIFFSUBSSUBJECT: c_int = -72
let PCRE2_ERROR_DUPLICATE_SUBPATTERN_NAME: c_int = 143
let PCRE2_ERROR_ECLASS_EXPECTED_OPERAND: c_int = 210
let PCRE2_ERROR_ECLASS_HINT_SQUARE_BRACKET: c_int = 212
let PCRE2_ERROR_ECLASS_INVALID_OPERATOR: c_int = 208
let PCRE2_ERROR_ECLASS_MIXED_OPERATORS: c_int = 211
let PCRE2_ERROR_ECLASS_NEST_TOO_DEEP: c_int = 207
let PCRE2_ERROR_ECLASS_UNEXPECTED_OPERATOR: c_int = 209
let PCRE2_ERROR_END_BACKSLASH: c_int = 101
let PCRE2_ERROR_END_BACKSLASH_C: c_int = 102
let PCRE2_ERROR_ESCAPE_INVALID_IN_CLASS: c_int = 107
let PCRE2_ERROR_ESCAPE_INVALID_IN_VERB: c_int = 140
let PCRE2_ERROR_EXPECTED_CAPTURE_GROUP: c_int = 217
let PCRE2_ERROR_EXTRA_CASING_INCOMPATIBLE: c_int = 206
let PCRE2_ERROR_EXTRA_CASING_REQUIRES_UNICODE: c_int = 204
let PCRE2_ERROR_HEAPLIMIT: c_int = -63
let PCRE2_ERROR_HEAP_FAILED: c_int = 121
let PCRE2_ERROR_INTERNAL: c_int = -44
let PCRE2_ERROR_INTERNAL_BAD_CODE: c_int = 189
let PCRE2_ERROR_INTERNAL_BAD_CODE_AUTO_POSSESS: c_int = 180
let PCRE2_ERROR_INTERNAL_BAD_CODE_IN_SKIP: c_int = 190
let PCRE2_ERROR_INTERNAL_BAD_CODE_LOOKBEHINDS: c_int = 170
let PCRE2_ERROR_INTERNAL_CODE_OVERFLOW: c_int = 123
let PCRE2_ERROR_INTERNAL_DUPMATCH: c_int = -65
let PCRE2_ERROR_INTERNAL_MISSING_SUBPATTERN: c_int = 153
let PCRE2_ERROR_INTERNAL_OVERRAN_WORKSPACE: c_int = 152
let PCRE2_ERROR_INTERNAL_PARSED_OVERFLOW: c_int = 163
let PCRE2_ERROR_INTERNAL_STUDY_ERROR: c_int = 131
let PCRE2_ERROR_INTERNAL_UNEXPECTED_REPEAT: c_int = 110
let PCRE2_ERROR_INTERNAL_UNKNOWN_NEWLINE: c_int = 156
let PCRE2_ERROR_INVALIDOFFSET: c_int = -67
let PCRE2_ERROR_INVALID_AFTER_PARENS_QUERY: c_int = 111
let PCRE2_ERROR_INVALID_HEXADECIMAL: c_int = 167
let PCRE2_ERROR_INVALID_HYPHEN_IN_OPTIONS: c_int = 194
let PCRE2_ERROR_INVALID_OCTAL: c_int = 164
let PCRE2_ERROR_INVALID_SUBPATTERN_NAME: c_int = 144
let PCRE2_ERROR_JIT_BADOPTION: c_int = -45
let PCRE2_ERROR_JIT_STACKLIMIT: c_int = -46
let PCRE2_ERROR_JIT_UNSUPPORTED: c_int = -68
let PCRE2_ERROR_LOOKBEHIND_INVALID_BACKSLASH_C: c_int = 136
let PCRE2_ERROR_LOOKBEHIND_NOT_FIXED_LENGTH: c_int = 125
let PCRE2_ERROR_LOOKBEHIND_TOO_COMPLICATED: c_int = 135
let PCRE2_ERROR_LOOKBEHIND_TOO_LONG: c_int = 187
let PCRE2_ERROR_MALFORMED_UNICODE_PROPERTY: c_int = 146
let PCRE2_ERROR_MARK_MISSING_ARGUMENT: c_int = 166
let PCRE2_ERROR_MATCHLIMIT: c_int = -47
let PCRE2_ERROR_MAX_VAR_LOOKBEHIND_EXCEEDED: c_int = 200
let PCRE2_ERROR_MISSING_CALLOUT_CLOSING: c_int = 139
let PCRE2_ERROR_MISSING_CLOSING_PARENTHESIS: c_int = 114
let PCRE2_ERROR_MISSING_COMMENT_CLOSING: c_int = 118
let PCRE2_ERROR_MISSING_CONDITION_CLOSING: c_int = 124
let PCRE2_ERROR_MISSING_NAME_TERMINATOR: c_int = 142
let PCRE2_ERROR_MISSING_NUMBER_TERMINATOR: c_int = 219
let PCRE2_ERROR_MISSING_OCTAL_DIGIT: c_int = 198
let PCRE2_ERROR_MISSING_OCTAL_OR_HEX_DIGITS: c_int = 178
let PCRE2_ERROR_MISSING_OPENING_PARENTHESIS: c_int = 218
let PCRE2_ERROR_MISSING_SQUARE_BRACKET: c_int = 106
let PCRE2_ERROR_MIXEDTABLES: c_int = -30
let PCRE2_ERROR_NOMATCH: c_int = -1
let PCRE2_ERROR_NOMEMORY: c_int = -48
let PCRE2_ERROR_NOSUBSTRING: c_int = -49
let PCRE2_ERROR_NOUNIQUESUBSTRING: c_int = -50
let PCRE2_ERROR_NO_SURROGATES_IN_UTF16: c_int = 191
let PCRE2_ERROR_NULL: c_int = -51
let PCRE2_ERROR_NULL_ERROROFFSET: c_int = 220
let PCRE2_ERROR_NULL_PATTERN: c_int = 116
let PCRE2_ERROR_OCTAL_BYTE_TOO_BIG: c_int = 151
let PCRE2_ERROR_OVERSIZE_PYTHON_OCTAL: c_int = 202
let PCRE2_ERROR_PARENS_QUERY_R_MISSING_CLOSING: c_int = 158
let PCRE2_ERROR_PARENTHESES_NEST_TOO_DEEP: c_int = 119
let PCRE2_ERROR_PARENTHESES_STACK_CHECK: c_int = 133
let PCRE2_ERROR_PARTIAL: c_int = -2
let PCRE2_ERROR_PARTIALSUBS: c_int = -76
let PCRE2_ERROR_PATTERN_COMPILED_SIZE_TOO_BIG: c_int = 201
let PCRE2_ERROR_PATTERN_STRING_TOO_LONG: c_int = 188
let PCRE2_ERROR_PATTERN_TOO_COMPLICATED: c_int = 186
let PCRE2_ERROR_PATTERN_TOO_LARGE: c_int = 120
let PCRE2_ERROR_PERL_ECLASS_EMPTY_EXPR: c_int = 214
let PCRE2_ERROR_PERL_ECLASS_MISSING_CLOSE: c_int = 215
let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_CHAR: c_int = 216
let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_EXPR: c_int = 213
let PCRE2_ERROR_POSIX_CLASS_NOT_IN_CLASS: c_int = 112
let PCRE2_ERROR_POSIX_NO_SUPPORT_COLLATING: c_int = 113
let PCRE2_ERROR_QUANTIFIER_INVALID: c_int = 109
let PCRE2_ERROR_QUANTIFIER_OUT_OF_ORDER: c_int = 104
let PCRE2_ERROR_QUANTIFIER_TOO_BIG: c_int = 105
let PCRE2_ERROR_QUERY_BARJX_NEST_TOO_DEEP: c_int = 184
let PCRE2_ERROR_RECURSELOOP: c_int = -52
let PCRE2_ERROR_RECURSIONLIMIT: c_int = -53
let PCRE2_ERROR_REPLACECASE: c_int = -69
let PCRE2_ERROR_REPMISSINGBRACE: c_int = -58
let PCRE2_ERROR_SCRIPT_RUN_NOT_AVAILABLE: c_int = 196
let PCRE2_ERROR_SUBPATTERN_NAMES_MISMATCH: c_int = 165
let PCRE2_ERROR_SUBPATTERN_NAME_EXPECTED: c_int = 162
let PCRE2_ERROR_SUBPATTERN_NAME_TOO_LONG: c_int = 148
let PCRE2_ERROR_SUBPATTERN_NUMBER_TOO_BIG: c_int = 161
let PCRE2_ERROR_SUPPORTED_ONLY_IN_UNICODE: c_int = 193
let PCRE2_ERROR_TOOLARGEREPLACE: c_int = -70
let PCRE2_ERROR_TOOMANYREPLACE: c_int = -61
let PCRE2_ERROR_TOO_MANY_CAPTURES: c_int = 197
let PCRE2_ERROR_TOO_MANY_CONDITION_BRANCHES: c_int = 127
let PCRE2_ERROR_TOO_MANY_NAMED_SUBPATTERNS: c_int = 149
let PCRE2_ERROR_TURKISH_CASING_REQUIRES_UTF: c_int = 205
let PCRE2_ERROR_UCP_IS_DISABLED: c_int = 175
let PCRE2_ERROR_UNAVAILABLE: c_int = -54
let PCRE2_ERROR_UNICODE_DISALLOWED_CODE_POINT: c_int = 173
let PCRE2_ERROR_UNICODE_NOT_SUPPORTED: c_int = 132
let PCRE2_ERROR_UNICODE_PROPERTIES_UNAVAILABLE: c_int = 145
let PCRE2_ERROR_UNKNOWN_ESCAPE: c_int = 103
let PCRE2_ERROR_UNKNOWN_POSIX_CLASS: c_int = 130
let PCRE2_ERROR_UNKNOWN_UNICODE_PROPERTY: c_int = 147
let PCRE2_ERROR_UNMATCHED_CLOSING_PARENTHESIS: c_int = 122
let PCRE2_ERROR_UNRECOGNIZED_AFTER_QUERY_P: c_int = 141
let PCRE2_ERROR_UNSET: c_int = -55
let PCRE2_ERROR_UNSUPPORTED_ESCAPE_SEQUENCE: c_int = 137
let PCRE2_ERROR_UTF16_ERR1: c_int = -24
let PCRE2_ERROR_UTF16_ERR2: c_int = -25
let PCRE2_ERROR_UTF16_ERR3: c_int = -26
let PCRE2_ERROR_UTF32_ERR1: c_int = -27
let PCRE2_ERROR_UTF32_ERR2: c_int = -28
let PCRE2_ERROR_UTF8_ERR1: c_int = -3
let PCRE2_ERROR_UTF8_ERR10: c_int = -12
let PCRE2_ERROR_UTF8_ERR11: c_int = -13
let PCRE2_ERROR_UTF8_ERR12: c_int = -14
let PCRE2_ERROR_UTF8_ERR13: c_int = -15
let PCRE2_ERROR_UTF8_ERR14: c_int = -16
let PCRE2_ERROR_UTF8_ERR15: c_int = -17
let PCRE2_ERROR_UTF8_ERR16: c_int = -18
let PCRE2_ERROR_UTF8_ERR17: c_int = -19
let PCRE2_ERROR_UTF8_ERR18: c_int = -20
let PCRE2_ERROR_UTF8_ERR19: c_int = -21
let PCRE2_ERROR_UTF8_ERR2: c_int = -4
let PCRE2_ERROR_UTF8_ERR20: c_int = -22
let PCRE2_ERROR_UTF8_ERR21: c_int = -23
let PCRE2_ERROR_UTF8_ERR3: c_int = -5
let PCRE2_ERROR_UTF8_ERR4: c_int = -6
let PCRE2_ERROR_UTF8_ERR5: c_int = -7
let PCRE2_ERROR_UTF8_ERR6: c_int = -8
let PCRE2_ERROR_UTF8_ERR7: c_int = -9
let PCRE2_ERROR_UTF8_ERR8: c_int = -10
let PCRE2_ERROR_UTF8_ERR9: c_int = -11
let PCRE2_ERROR_UTF_IS_DISABLED: c_int = 174
let PCRE2_ERROR_VERB_ARGUMENT_NOT_ALLOWED: c_int = 159
let PCRE2_ERROR_VERB_NAME_TOO_LONG: c_int = 176
let PCRE2_ERROR_VERB_UNKNOWN: c_int = 160
let PCRE2_ERROR_VERSION_CONDITION_SYNTAX: c_int = 179
let PCRE2_ERROR_ZERO_RELATIVE_REFERENCE: c_int = 126
let PCRE2_EXTENDED: c_uint = 0x00000080
let PCRE2_EXTENDED_MORE: c_uint = 0x01000000
let PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK: c_uint = 0x00000040
let PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES: c_uint = 0x00000001
let PCRE2_EXTRA_ALT_BSUX: c_uint = 0x00000020
let PCRE2_EXTRA_ASCII_BSD: c_uint = 0x00000100
let PCRE2_EXTRA_ASCII_BSS: c_uint = 0x00000200
let PCRE2_EXTRA_ASCII_BSW: c_uint = 0x00000400
let PCRE2_EXTRA_ASCII_DIGIT: c_uint = 0x00001000
let PCRE2_EXTRA_ASCII_POSIX: c_uint = 0x00000800
let PCRE2_EXTRA_BAD_ESCAPE_IS_LITERAL: c_uint = 0x00000002
let PCRE2_EXTRA_CASELESS_RESTRICT: c_uint = 0x00000080
let PCRE2_EXTRA_ESCAPED_CR_IS_LF: c_uint = 0x00000010
let PCRE2_EXTRA_MATCH_LINE: c_uint = 0x00000008
let PCRE2_EXTRA_MATCH_WORD: c_uint = 0x00000004
let PCRE2_EXTRA_NEVER_CALLOUT: c_uint = 0x00008000
let PCRE2_EXTRA_NO_BS0: c_uint = 0x00004000
let PCRE2_EXTRA_PYTHON_OCTAL: c_uint = 0x00002000
let PCRE2_EXTRA_TURKISH_CASING: c_uint = 0x00010000
let PCRE2_FIRSTLINE: c_uint = 0x00000100
// untranslatable fn-like macro
fn PCRE2_GLUE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_GLUE")
let PCRE2_INFO_ALLOPTIONS: c_int = 0
let PCRE2_INFO_ARGOPTIONS: c_int = 1
let PCRE2_INFO_BACKREFMAX: c_int = 2
let PCRE2_INFO_BSR: c_int = 3
let PCRE2_INFO_CAPTURECOUNT: c_int = 4
let PCRE2_INFO_DEPTHLIMIT: c_int = 21
let PCRE2_INFO_EXTRAOPTIONS: c_int = 26
let PCRE2_INFO_FIRSTBITMAP: c_int = 7
let PCRE2_INFO_FIRSTCODETYPE: c_int = 6
let PCRE2_INFO_FIRSTCODEUNIT: c_int = 5
let PCRE2_INFO_FRAMESIZE: c_int = 24
let PCRE2_INFO_HASBACKSLASHC: c_int = 23
let PCRE2_INFO_HASCRORLF: c_int = 8
let PCRE2_INFO_HEAPLIMIT: c_int = 25
let PCRE2_INFO_JCHANGED: c_int = 9
let PCRE2_INFO_JITSIZE: c_int = 10
let PCRE2_INFO_LASTCODETYPE: c_int = 12
let PCRE2_INFO_LASTCODEUNIT: c_int = 11
let PCRE2_INFO_MATCHEMPTY: c_int = 13
let PCRE2_INFO_MATCHLIMIT: c_int = 14
let PCRE2_INFO_MAXLOOKBEHIND: c_int = 15
let PCRE2_INFO_MINLENGTH: c_int = 16
let PCRE2_INFO_NAMECOUNT: c_int = 17
let PCRE2_INFO_NAMEENTRYSIZE: c_int = 18
let PCRE2_INFO_NAMETABLE: c_int = 19
let PCRE2_INFO_NEWLINE: c_int = 20
let PCRE2_INFO_RECURSIONLIMIT: c_int = 21
let PCRE2_INFO_SIZE: c_int = 22
let PCRE2_JIT_COMPLETE: c_uint = 0x00000001
let PCRE2_JIT_INVALID_UTF: c_uint = 0x00000100
let PCRE2_JIT_PARTIAL_HARD: c_uint = 0x00000004
let PCRE2_JIT_PARTIAL_SOFT: c_uint = 0x00000002
let PCRE2_JIT_TEST_ALLOC: c_uint = 0x00000200
// untranslatable fn-like macro
fn PCRE2_JOIN() -> Never:
    comptime_error("untranslatable C macro: PCRE2_JOIN")
let PCRE2_LITERAL: c_uint = 0x02000000
let PCRE2_MAJOR: c_int = 10
let PCRE2_MATCH_INVALID_UTF: c_uint = 0x04000000
let PCRE2_MATCH_UNSET_BACKREF: c_uint = 0x00000200
let PCRE2_MINOR: c_int = 48
let PCRE2_MULTILINE: c_uint = 0x00000400
let PCRE2_NEVER_BACKSLASH_C: c_uint = 0x00100000
let PCRE2_NEVER_UCP: c_uint = 0x00000800
let PCRE2_NEVER_UTF: c_uint = 0x00001000
let PCRE2_NEWLINE_ANY: c_int = 4
let PCRE2_NEWLINE_ANYCRLF: c_int = 5
let PCRE2_NEWLINE_CR: c_int = 1
let PCRE2_NEWLINE_CRLF: c_int = 3
let PCRE2_NEWLINE_LF: c_int = 2
let PCRE2_NEWLINE_NUL: c_int = 6
let PCRE2_NOTBOL: c_uint = 0x00000001
let PCRE2_NOTEMPTY: c_uint = 0x00000004
let PCRE2_NOTEMPTY_ATSTART: c_uint = 0x00000008
let PCRE2_NOTEOL: c_uint = 0x00000002
let PCRE2_NO_AUTO_CAPTURE: c_uint = 0x00002000
let PCRE2_NO_AUTO_POSSESS: c_uint = 0x00004000
let PCRE2_NO_DOTSTAR_ANCHOR: c_uint = 0x00008000
let PCRE2_NO_JIT: c_uint = 0x00002000
let PCRE2_NO_START_OPTIMIZE: c_uint = 0x00010000
let PCRE2_NO_UTF_CHECK: c_uint = 0x40000000
let PCRE2_OPTIMIZATION_FULL: c_int = 1
let PCRE2_OPTIMIZATION_NONE: c_int = 0
let PCRE2_PARTIAL_HARD: c_uint = 0x00000020
let PCRE2_PARTIAL_SOFT: c_uint = 0x00000010
let PCRE2_START_OPTIMIZE: c_int = 68
let PCRE2_START_OPTIMIZE_OFF: c_int = 69
let PCRE2_SUBSTITUTE_CASE_LOWER: c_int = 1
let PCRE2_SUBSTITUTE_CASE_TITLE_FIRST: c_int = 3
let PCRE2_SUBSTITUTE_CASE_UPPER: c_int = 2
let PCRE2_SUBSTITUTE_EXTENDED: c_uint = 0x00000200
let PCRE2_SUBSTITUTE_GLOBAL: c_uint = 0x00000100
let PCRE2_SUBSTITUTE_LITERAL: c_uint = 0x00008000
let PCRE2_SUBSTITUTE_MATCHED: c_uint = 0x00010000
let PCRE2_SUBSTITUTE_OVERFLOW_LENGTH: c_uint = 0x00001000
let PCRE2_SUBSTITUTE_REPLACEMENT_ONLY: c_uint = 0x00020000
let PCRE2_SUBSTITUTE_UNKNOWN_UNSET: c_uint = 0x00000800
let PCRE2_SUBSTITUTE_UNSET_EMPTY: c_uint = 0x00000400
fn PCRE2_SUFFIX[T](a: T) -> T:
    PCRE2_GLUE(a, PCRE2_CODE_UNIT_WIDTH)
let PCRE2_UCP: c_uint = 0x00020000
let PCRE2_UNGREEDY: c_uint = 0x00040000
// untranslatable fn-like macro
fn PCRE2_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_UNREACHABLE")
let PCRE2_USE_OFFSET_LIMIT: c_uint = 0x00800000
let PCRE2_UTF: c_uint = 0x00080000
let PCRE2regcomp: c_int = pcre2_regcomp
let PCRE2regerror: c_int = pcre2_regerror
let PCRE2regexec: c_int = pcre2_regexec
let PCRE2regfree: c_int = pcre2_regfree
let PIPE_BUF: c_int = 512
let POLL_ERR: c_int = 4
let POLL_HUP: c_int = 6
let POLL_IN: c_int = 1
let POLL_MSG: c_int = 3
let POLL_OUT: c_int = 2
let POLL_PRI: c_int = 5
let PRIO_DARWIN_BG: c_int = 0x1000
let PRIO_DARWIN_NONUI: c_int = 0x1001
let PRIO_DARWIN_PROCESS: c_int = 4
let PRIO_DARWIN_THREAD: c_int = 3
let PRIO_MAX: c_int = 20
let PRIO_MIN: c_int = -20
let PRIO_PGRP: c_int = 1
let PRIO_PROCESS: c_int = 0
let PRIO_USER: c_int = 2
fn PRIV[T](name: T) -> T:
    name
let PRIX16 = "hX"
let PRIX32 = "X"
let PRIXFAST16: c_int = PRIX16
let PRIXFAST32: c_int = PRIX32
let PRIXLEAST16: c_int = PRIX16
let PRIXLEAST32: c_int = PRIX32
let PRIXPTR = "lX"
let PRId16 = "hd"
let PRId32 = "d"
let PRIdFAST16: c_int = PRId16
let PRIdFAST32: c_int = PRId32
let PRIdLEAST16: c_int = PRId16
let PRIdLEAST32: c_int = PRId32
let PRIdPTR = "ld"
let PRIi16 = "hi"
let PRIi32 = "i"
let PRIiFAST16: c_int = PRIi16
let PRIiFAST32: c_int = PRIi32
let PRIiLEAST16: c_int = PRIi16
let PRIiLEAST32: c_int = PRIi32
let PRIiPTR = "li"
let PRIo16 = "ho"
let PRIo32 = "o"
let PRIoFAST16: c_int = PRIo16
let PRIoFAST32: c_int = PRIo32
let PRIoLEAST16: c_int = PRIo16
let PRIoLEAST32: c_int = PRIo32
let PRIoPTR = "lo"
let PRIu16 = "hu"
let PRIu32 = "u"
let PRIuFAST16: c_int = PRIu16
let PRIuFAST32: c_int = PRIu32
let PRIuLEAST16: c_int = PRIu16
let PRIuLEAST32: c_int = PRIu32
let PRIuPTR = "lu"
let PRIx16 = "hx"
let PRIx32 = "x"
let PRIxFAST16: c_int = PRIx16
let PRIxFAST32: c_int = PRIx32
let PRIxLEAST16: c_int = PRIx16
let PRIxLEAST32: c_int = PRIx32
let PRIxPTR = "lx"
let PTHREAD_DESTRUCTOR_ITERATIONS: c_int = 4
let PTHREAD_KEYS_MAX: c_int = 512
let PTHREAD_STACK_MIN: c_int = 16384
let PTRDIFF_MAX: c_int = INTMAX_MAX
let PTRDIFF_MIN: c_int = INTMAX_MIN
let P_tmpdir = "/var/tmp/"
let QUAD_MAX: c_int = 9223372036854775807
let QUAD_MIN: c_int = -9223372036854775806
let RAND_MAX: c_int = 0x7fffffff
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
let RENAME_EXCL: c_int = 0x00000004
let RENAME_NOFOLLOW_ANY: c_int = 0x00000010
let RENAME_RESERVED1: c_int = 0x00000008
let RENAME_RESOLVE_BENEATH: c_int = 0x00000020
let RENAME_SECLUDE: c_int = 0x00000001
let RENAME_SWAP: c_int = 0x00000002
let RE_DUP_MAX: c_int = 255
let RLIMIT_AS: c_int = 5
let RLIMIT_CORE: c_int = 4
let RLIMIT_CPU: c_int = 0
let RLIMIT_CPU_USAGE_MONITOR: c_int = 0x2
let RLIMIT_DATA: c_int = 2
let RLIMIT_FOOTPRINT_INTERVAL: c_int = 0x4
let RLIMIT_FSIZE: c_int = 1
let RLIMIT_MEMLOCK: c_int = 6
let RLIMIT_NOFILE: c_int = 8
let RLIMIT_NPROC: c_int = 7
let RLIMIT_RSS: c_int = 5
let RLIMIT_STACK: c_int = 3
let RLIMIT_THREAD_CPULIMITS: c_int = 0x3
let RLIMIT_WAKEUPS_MONITOR: c_int = 0x1
let RLIM_NLIMITS: c_int = 9
let RUSAGE_CHILDREN: c_int = -1
let RUSAGE_INFO_V0: c_int = 0
let RUSAGE_INFO_V1: c_int = 1
let RUSAGE_INFO_V2: c_int = 2
let RUSAGE_INFO_V3: c_int = 3
let RUSAGE_INFO_V4: c_int = 4
let RUSAGE_INFO_V5: c_int = 5
let RUSAGE_INFO_V6: c_int = 6
let RUSAGE_SELF: c_int = 0
let RU_PROC_RUNS_RESLIDE: c_int = 0x00000001
let SA_64REGSET: c_int = 0x0200
let SA_NOCLDSTOP: c_int = 0x0008
let SA_NOCLDWAIT: c_int = 0x0020
let SA_NODEFER: c_int = 0x0010
let SA_ONSTACK: c_int = 0x0001
let SA_RESETHAND: c_int = 0x0004
let SA_RESTART: c_int = 0x0002
let SA_SIGINFO: c_int = 0x0040
let SA_USERSPACE_MASK: c_int = 127
let SA_USERTRAMP: c_int = 0x0100
let SCHAR_MAX: c_int = 127
let SCHAR_MIN: c_int = -126
let SCNd16 = "hd"
let SCNd32 = "d"
let SCNdFAST16: c_int = SCNd16
let SCNdFAST32: c_int = SCNd32
let SCNdLEAST16: c_int = SCNd16
let SCNdLEAST32: c_int = SCNd32
let SCNdPTR = "ld"
let SCNi16 = "hi"
let SCNi32 = "i"
let SCNiFAST16: c_int = SCNi16
let SCNiFAST32: c_int = SCNi32
let SCNiLEAST16: c_int = SCNi16
let SCNiLEAST32: c_int = SCNi32
let SCNiPTR = "li"
let SCNo16 = "ho"
let SCNo32 = "o"
let SCNoFAST16: c_int = SCNo16
let SCNoFAST32: c_int = SCNo32
let SCNoLEAST16: c_int = SCNo16
let SCNoLEAST32: c_int = SCNo32
let SCNoPTR = "lo"
let SCNu16 = "hu"
let SCNu32 = "u"
let SCNuFAST16: c_int = SCNu16
let SCNuFAST32: c_int = SCNu32
let SCNuLEAST16: c_int = SCNu16
let SCNuLEAST32: c_int = SCNu32
let SCNuPTR = "lu"
let SCNx16 = "hx"
let SCNx32 = "x"
let SCNxFAST16: c_int = SCNx16
let SCNxFAST32: c_int = SCNx32
let SCNxLEAST16: c_int = SCNx16
let SCNxLEAST32: c_int = SCNx32
let SCNxPTR = "lx"
let SEEK_CUR: c_int = 1
let SEEK_DATA: c_int = 4
let SEEK_END: c_int = 2
let SEEK_HOLE: c_int = 3
let SEEK_SET: c_int = 0
let SEGV_ACCERR: c_int = 2
let SEGV_MAPERR: c_int = 1
let SEGV_NOOP: c_int = 0
let SHRT_MAX: c_int = 32767
let SHRT_MIN: c_int = -32766
let SIGABRT: c_int = 6
let SIGALRM: c_int = 14
let SIGBUS: c_int = 10
let SIGCHLD: c_int = 20
let SIGCONT: c_int = 19
let SIGEMT: c_int = 7
let SIGEV_KEVENT: c_int = 4
let SIGEV_NONE: c_int = 0
let SIGEV_SIGNAL: c_int = 1
let SIGEV_THREAD: c_int = 3
let SIGFPE: c_int = 8
let SIGHUP: c_int = 1
let SIGILL: c_int = 4
let SIGINFO: c_int = 29
let SIGINT: c_int = 2
let SIGIO: c_int = 23
let SIGIOT: c_int = 6
let SIGKILL: c_int = 9
let SIGPIPE: c_int = 13
let SIGPROF: c_int = 27
let SIGQUIT: c_int = 3
let SIGSEGV: c_int = 11
let SIGSTKSZ: c_int = 131072
let SIGSTOP: c_int = 17
let SIGSYS: c_int = 12
let SIGTERM: c_int = 15
let SIGTRAP: c_int = 5
let SIGTSTP: c_int = 18
let SIGTTIN: c_int = 21
let SIGTTOU: c_int = 22
let SIGURG: c_int = 16
let SIGUSR1: c_int = 30
let SIGUSR2: c_int = 31
let SIGVTALRM: c_int = 26
let SIGWINCH: c_int = 28
let SIGXCPU: c_int = 24
let SIGXFSZ: c_int = 25
let SIG_ATOMIC_MAX: c_int = 2147483647
let SIG_ATOMIC_MIN: c_int = -2147483646
let SIG_BLOCK: c_int = 1
let SIG_SETMASK: c_int = 3
let SIG_UNBLOCK: c_int = 2
let SI_ASYNCIO: c_int = 0x10004
let SI_MESGQ: c_int = 0x10005
let SI_QUEUE: c_int = 0x10002
let SI_TIMER: c_int = 0x10003
let SI_USER: c_int = 0x10001
let SSIZE_MAX: c_int = 9223372036854775807
let SS_DISABLE: c_int = 0x0004
let SS_ONSTACK: c_int = 0x0001
let SUPPORT_PCRE2_8: c_int = 1
let SV_INTERRUPT: c_int = 0x0002
let SV_NOCLDSTOP: c_int = 0x0008
let SV_NODEFER: c_int = 0x0010
let SV_ONSTACK: c_int = 0x0001
let SV_RESETHAND: c_int = 0x0004
let SV_SIGINFO: c_int = 0x0040
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
let TMP_MAX: c_int = 308915776
let TRAP_BRKPT: c_int = 1
let TRAP_TRACE: c_int = 2
let UCHAR_MAX: c_int = 255
let UID_MAX: c_uint = 2147483647
fn UINT16_C[T](v: T) -> T:
    v
let UINT16_MAX: c_int = 65535
fn UINT32_C[T](v: T) -> u32:
    (v as u32)
let UINT32_MAX: c_uint = 4294967295
fn UINT64_C[T](v: T) -> u64:
    (v as u64)
let UINT64_MAX: c_ulonglong = 18446744073709551615
fn UINT8_C[T](v: T) -> T:
    v
let UINT8_MAX: c_int = 255
fn UINTMAX_C[T](v: T) -> u64:
    (v as u64)
let UINTMAX_MAX: c_int = UINTMAX_C(18446744073709551615)
let UINTPTR_MAX: c_ulong = 18446744073709551615
let UINT_FAST16_MAX: c_int = 65535
let UINT_FAST32_MAX: c_int = 4294967295
let UINT_FAST64_MAX: c_int = 18446744073709551615
let UINT_FAST8_MAX: c_int = 255
let UINT_LEAST16_MAX: c_int = 65535
let UINT_LEAST32_MAX: c_int = 4294967295
let UINT_LEAST64_MAX: c_int = 18446744073709551615
let UINT_LEAST8_MAX: c_int = 255
let UINT_MAX: c_int = 4294967295
let ULLONG_MAX: c_int = -1
let ULONG_LONG_MAX: c_int = -1
let ULONG_MAX: c_int = -1
let UQUAD_MAX: c_int = -1
let USHRT_MAX: c_int = 65535
let VERSION = "10.48-DEV"
let WAIT_ANY: c_int = -1
let WAIT_MYPGRP: c_int = 0
let WAKEMON_DISABLE: c_int = 0x02
let WAKEMON_ENABLE: c_int = 0x01
let WAKEMON_GET_PARAMS: c_int = 0x04
let WAKEMON_MAKE_FATAL: c_int = 0x10
let WAKEMON_SET_DEFAULTS: c_int = 0x08
let WCONTINUED: c_int = 0x00000010
// untranslatable fn-like macro
fn WCOREDUMP() -> Never:
    comptime_error("untranslatable C macro: WCOREDUMP")
let WCOREFLAG: c_int = 0200
let WEXITED: c_int = 0x00000004
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
let WINT_MAX: c_int = 2147483647
let WINT_MIN: c_int = -2147483646
let WNOHANG: c_int = 0x00000001
let WNOWAIT: c_int = 0x00000020
let WORD_BIT: c_int = 32
let WSTOPPED: c_int = 0x00000008
// untranslatable fn-like macro
fn WSTOPSIG() -> Never:
    comptime_error("untranslatable C macro: WSTOPSIG")
// untranslatable fn-like macro
fn WTERMSIG() -> Never:
    comptime_error("untranslatable C macro: WTERMSIG")
let WUNTRACED: c_int = 0x00000002
fn W_EXITCODE[T](ret: T, sig: T) -> T:
    ((ret << 8) | sig)
// untranslatable fn-like macro
fn W_STOPCODE() -> Never:
    comptime_error("untranslatable C macro: W_STOPCODE")
// untranslatable fn-like macro
fn alloca() -> Never:
    comptime_error("untranslatable C macro: alloca")
fn bcopy() -> Never:
    comptime_error("variadic macro — use direct call")
fn bzero() -> Never:
    comptime_error("variadic macro — use direct call")
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
