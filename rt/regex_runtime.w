// rt/regex_runtime.w -- embedded regex runtime wrappers over migrated PCRE2
//
// Compiled with --no-prelude --emit-obj and linked beside rt_core.o.

use std.re.defs
use std.re.pcre2_tables
use std.re.pcre2_ucd
use std.re.pcre2_chartables
use std.re.pcre2_string_utils
use std.re.pcre2_newline
use std.re.pcre2_valid_utf
use std.re.pcre2_ord2utf
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_error
use std.re.pcre2_extuni
use std.re.pcre2_find_bracket
use std.re.pcre2_auto_possess
use std.re.pcre2_study
use std.re.pcre2_xclass
use std.re.pcre2_chkdint
use std.re.pcre2_compile_class
use std.re.pcre2_compile_cgroup
use std.re.pcre2_config
use std.re.pcre2_jit_compile
use std.re.pcre2_maketables
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_match_next
use std.re.pcre2_dfa_match
use std.re.pcre2_substitute
use std.re.pcre2_substring
use std.re.pcre2_pattern_info
use std.re.pcre2_serialize
use std.re.pcre2_convert
use std.re.pcre2_script_run

extern fn with_panic(msg: str, file: str, line: i32) -> void
extern fn with_str_clone(s: str) -> str
extern fn with_str_from_cstr(s: *const u8) -> str
extern fn with_str_from_bytes(s: *const u8, len: i64) -> str

fn regex_runtime_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    let _ = data
    with_alloc(size as i64) as *mut c_void

fn regex_runtime_free(ptr: *mut c_void, data: *mut c_void):
    let _ = data
    with_free(ptr as *i8)

fn regex_to_cstr(s: str) -> *const u8:
    let out = with_alloc(s.len() + 1)
    var i: i64 = 0
    while i < s.len():
        unsafe *((out as i64 + i) as *mut u8) = s.byte_at(i)
        i = i + 1
    unsafe *((out as i64 + s.len()) as *mut u8) = 0
    out as *const u8

@[c_export("with_regex_error_message")]
pub fn regex_error_message_impl(code: i32) -> str:
    let buf = with_alloc(256)
    let rc = pcre2_get_error_message_8(code, buf as *mut u8, 256)
    if rc < 0:
        with_free(buf)
        return "regex error"
    let text = with_str_clone(with_str_from_cstr(buf as *const u8))
    with_free(buf)
    text

@[c_export("with_regex_compile")]
pub fn regex_compile_impl(pattern: str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8:
    let gcontext = pcre2_general_context_create_8(regex_runtime_malloc, regex_runtime_free, null)
    if gcontext as i64 == 0:
        with_panic("with_regex_compile(): general context creation failed", "", 0)
        return null
    var ccontext = _pcre2_default_compile_context_8
    ((unsafe *(&raw mut ccontext as *mut pcre2_memctl)) = (unsafe *(gcontext as *mut pcre2_memctl)))
    (ccontext.max_pattern_length = (0 -% 1) as c_ulong)
    (ccontext.max_pattern_compiled_length = (0 -% 1) as c_ulong)
    (ccontext.parens_nest_limit = 250)
    (ccontext.max_varlookbehind = 255)
    (ccontext.newline_convention = 2)
    (ccontext.bsr_convention = 0)
    (ccontext.optimization_flags = 4294967295)
    let tables = pcre2_maketables_8(gcontext)
    (ccontext.tables = tables)
    let c_pattern = regex_to_cstr(pattern)
    var raw_err_code: c_int = 0
    var raw_err_offset: c_ulong = 0
    let compiled = pcre2_compile_8(
        c_pattern,
        pattern.len() as c_ulong,
        options as c_uint,
        &raw mut raw_err_code,
        &raw mut raw_err_offset,
        &raw mut ccontext
    )
    with_free(c_pattern as *i8)
    pcre2_general_context_free_8(gcontext)
    if err_code as i64 != 0:
        unsafe *err_code = raw_err_code
    if err_offset as i64 != 0:
        unsafe *err_offset = raw_err_offset as i32
    compiled as *const i8

@[c_export("with_regex_code_copy")]
pub fn regex_code_copy_impl(code: *const i8) -> *const i8:
    if code as i64 == 0:
        return null
    pcre2_code_copy_8(code as *const pcre2_real_code_8) as *const i8

@[c_export("with_regex_code_free")]
pub fn regex_code_free_impl(code: *const i8):
    if code as i64 != 0:
        pcre2_code_free_8(code as *mut pcre2_real_code_8)

@[c_export("with_regex_capture_count")]
pub fn regex_capture_count_impl(code: *const i8) -> i32:
    if code as i64 == 0:
        return 0
    var capture_count: c_uint = 0
    let rc = pcre2_pattern_info_8(
        code as *const pcre2_real_code_8,
        PCRE2_INFO_CAPTURECOUNT as c_uint,
        (&raw mut capture_count) as *mut c_void
    )
    if rc < 0:
        with_panic("with_regex_capture_count(): pattern info failed", "", 0)
        return 0
    capture_count as i32

@[c_export("with_regex_match_spans_alloc")]
pub fn regex_match_spans_alloc_impl(code: *const i8, text: str, out_count: *mut i32) -> *const i32:
    regex_match_spans_alloc_at_impl(code, text, 0, out_count)

@[c_export("with_regex_match_spans_alloc_at")]
pub fn regex_match_spans_alloc_at_impl(code: *const i8, text: str, start_offset: i32, out_count: *mut i32) -> *const i32:
    if out_count as i64 != 0:
        unsafe *out_count = 0
    if code as i64 == 0 or start_offset < 0 or start_offset as i64 > text.len():
        return null
    let gcontext = pcre2_general_context_create_8(regex_runtime_malloc, regex_runtime_free, null)
    if gcontext as i64 == 0:
        with_panic("with_regex_match_spans_alloc_at(): general context creation failed", "", 0)
        return null
    let match_data = pcre2_match_data_create_from_pattern_8(code as *const pcre2_real_code_8, gcontext)
    if match_data as i64 == 0:
        pcre2_general_context_free_8(gcontext)
        with_panic("with_regex_match_spans_alloc_at(): match data creation failed", "", 0)
        return null
    let rc = pcre2_match_8(
        code as *const pcre2_real_code_8,
        text as *const u8,
        text.len() as c_ulong,
        start_offset as c_ulong,
        0,
        match_data,
        null
    )
    if rc < 0:
        pcre2_match_data_free_8(match_data)
        pcre2_general_context_free_8(gcontext)
        return null
    let ovector = pcre2_get_ovector_pointer_8(match_data)
    let count = pcre2_get_ovector_count_8(match_data) as i32
    let ints_count = count * 2
    let out = with_alloc(ints_count as i64 * 4) as *mut i32
    if out as i64 == 0:
        pcre2_match_data_free_8(match_data)
        pcre2_general_context_free_8(gcontext)
        with_panic("with_regex_match_spans_alloc_at(): span allocation failed", "", 0)
        return null
    var i: i32 = 0
    while i < count:
        let start = unsafe *((ovector as i64 + i as i64 * 16) as *const c_ulong) as i32
        let end = unsafe *((ovector as i64 + i as i64 * 16 + 8) as *const c_ulong) as i32
        unsafe *((out as i64 + i as i64 * 8) as *mut i32) = start
        unsafe *((out as i64 + i as i64 * 8 + 4) as *mut i32) = end
        i = i + 1
    pcre2_match_data_free_8(match_data)
    pcre2_general_context_free_8(gcontext)
    if out_count as i64 != 0:
        unsafe *out_count = ints_count
    out as *const i32

@[c_export("with_regex_capture_name_count")]
pub fn regex_capture_name_count_impl(code: *const i8) -> i32:
    if code as i64 == 0:
        return 0
    var name_count: c_uint = 0
    let rc = pcre2_pattern_info_8(
        code as *const pcre2_real_code_8,
        PCRE2_INFO_NAMECOUNT as c_uint,
        (&raw mut name_count) as *mut c_void
    )
    if rc < 0:
        with_panic("with_regex_capture_name_count(): pattern info failed", "", 0)
        return 0
    name_count as i32

@[c_export("with_regex_capture_name_at")]
pub fn regex_capture_name_at_impl(code: *const i8, index: i32) -> str:
    if code as i64 == 0 or index < 0:
        return ""
    var name_count: c_uint = 0
    var entry_size: c_uint = 0
    var table: *const u8 = null
    var rc = pcre2_pattern_info_8(
        code as *const pcre2_real_code_8,
        PCRE2_INFO_NAMECOUNT as c_uint,
        (&raw mut name_count) as *mut c_void
    )
    if rc < 0:
        with_panic("with_regex_capture_name_at(): name count lookup failed", "", 0)
        return ""
    if index >= name_count as i32:
        return ""
    rc = pcre2_pattern_info_8(
        code as *const pcre2_real_code_8,
        PCRE2_INFO_NAMEENTRYSIZE as c_uint,
        (&raw mut entry_size) as *mut c_void
    )
    if rc < 0:
        with_panic("with_regex_capture_name_at(): entry size lookup failed", "", 0)
        return ""
    rc = pcre2_pattern_info_8(
        code as *const pcre2_real_code_8,
        PCRE2_INFO_NAMETABLE as c_uint,
        (&raw mut table) as *mut c_void
    )
    if rc < 0:
        with_panic("with_regex_capture_name_at(): name table lookup failed", "", 0)
        return ""
    let entry = (table as i64 + index as i64 * entry_size as i64 + 2) as *const u8
    with_str_clone(with_str_from_cstr(entry))

@[c_export("with_regex_group_name_to_index")]
pub fn regex_group_name_to_index_impl(code: *const i8, name: str) -> i32:
    if code as i64 == 0:
        return -1
    let cname = regex_to_cstr(name)
    let out = pcre2_substring_number_from_name_8(code as *const pcre2_real_code_8, cname)
    with_free(cname as *i8)
    if out < 0:
        return -1
    out

@[c_export("with_regex_substitute")]
pub fn regex_substitute_impl(code: *const i8, text: str, repl: str, replace_all: i32) -> str:
    if code as i64 == 0:
        return text
    let gcontext = pcre2_general_context_create_8(regex_runtime_malloc, regex_runtime_free, null)
    if gcontext as i64 == 0:
        with_panic("with_regex_substitute(): general context creation failed", "", 0)
        return ""
    let match_data = pcre2_match_data_create_from_pattern_8(code as *const pcre2_real_code_8, gcontext)
    if match_data as i64 == 0:
        pcre2_general_context_free_8(gcontext)
        with_panic("with_regex_substitute(): match data creation failed", "", 0)
        return ""
    let c_repl = regex_to_cstr(repl)
    var options: c_uint = (PCRE2_SUBSTITUTE_UNSET_EMPTY | PCRE2_SUBSTITUTE_OVERFLOW_LENGTH) as c_uint
    if replace_all != 0:
        options = options | PCRE2_SUBSTITUTE_GLOBAL
    var buffer_len: c_ulong = (text.len() + repl.len() + 64) as c_ulong
    if buffer_len < 64:
        buffer_len = 64
    var buffer = with_alloc(buffer_len as i64 + 1) as *mut u8
    var rc = pcre2_substitute_8(
        code as *const pcre2_real_code_8,
        text as *const u8,
        text.len() as c_ulong,
        0,
        options,
        match_data,
        null,
        c_repl,
        repl.len() as c_ulong,
        buffer,
        &raw mut buffer_len
    )
    if rc == PCRE2_ERROR_NOMEMORY:
        with_free(buffer as *mut u8)
        buffer = with_alloc(buffer_len as i64 + 1) as *mut u8
        rc = pcre2_substitute_8(
            code as *const pcre2_real_code_8,
            text as *const u8,
            text.len() as c_ulong,
            0,
            options,
            match_data,
            null,
            c_repl,
            repl.len() as c_ulong,
            buffer,
            &raw mut buffer_len
        )
    if rc < 0:
        let msg = "with_regex_substitute(): " ++ regex_error_message_impl(rc as i32)
        with_free(c_repl as *i8)
        with_free(buffer as *mut u8)
        pcre2_match_data_free_8(match_data)
        pcre2_general_context_free_8(gcontext)
        with_panic(msg, "", 0)
        return ""
    unsafe *((buffer as i64 + buffer_len as i64) as *mut u8) = 0
    let result = with_str_from_bytes(buffer as *const u8, buffer_len as i64)
    with_free(c_repl as *i8)
    with_free(buffer as *mut u8)
    pcre2_match_data_free_8(match_data)
    pcre2_general_context_free_8(gcontext)
    result
