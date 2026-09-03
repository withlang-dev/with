// std.regex — high-level regex facade over the migrated PCRE2 engine.
//
// The engine is the pcre2 .wo bundle (docs/wo_bundles.md, decisions.md D38,
// D39): `use std.re.*` resolves to the bundle's interface, the calls below
// are ordinary With calls, and the link selects the bundle on demand.

use std.builtins
use std.collections
use std.option
use std.result
use std.re.defs
use std.re.pcre2_compile
use std.re.pcre2_context
use std.re.pcre2_error
use std.re.pcre2_maketables
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_pattern_info
use std.re.pcre2_substitute
use std.re.pcre2_substring

extern fn with_str_slice_ref(s: &str, start: i64, end: i64) -> str
extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_from_byte(b: i32) -> str
extern fn with_str_from_bytes(s: *const u8, len: i64) -> str
extern fn with_free(ptr: *mut u8) -> Unit

const REGEX_FLAG_GLOBAL: i32 = 1

pub type Match {
    text: str,
    start: i32,
    end: i32,
}
// #747: str field — owned, non-Copy now; moves/clones spell intent.

pub type RegexError {
    code: i32,
    offset: i32,
    message: str,
}

pub type RegexFlags {
    options: i32,
    flags: i32,
}
impl Copy for RegexFlags

// Ten fields in this order: codegen builds a regex literal's value field by
// field (CodegenDispatch.gen_regex_literal_value).
pub type Regex {
    ptr: *const i8,
    pattern_text: str,
    flags_text: str,
    options: i32,
    flags: i32,
    capture_count: i32,
    owned: i32,
    global_pos: *mut i32,
    global_subject_ptr: *mut i64,
    global_subject_len: *mut i64,
}

pub type Captures {
    regex_ptr: *const i8,
    subject: str,
    spans: Vec[i32],
}

fn regex_make_flags(options: i32, flags: i32) -> RegexFlags:
    RegexFlags { options: options, flags: flags, }

// ── The engine (pcre2 through std.re) ────────────────────────────────

fn regex_engine_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    with_alloc(size as i64) as *mut c_void

fn regex_engine_free(ptr: *mut c_void, data: *mut c_void):
    with_free(ptr as *mut u8)

fn regex_general_context(what: &str) -> *mut pcre2_real_general_context_8:
    let gcontext = unsafe { pcre2_general_context_create_8(regex_engine_malloc, regex_engine_free, null) }
    if gcontext as i64 == 0:
        with_panic(what ++ ": general context creation failed", "", 0)
    gcontext

fn regex_match_data(code: *const i8, gcontext: *mut pcre2_real_general_context_8, what: &str) -> *mut pcre2_real_match_data_8:
    let match_data = unsafe { pcre2_match_data_create_from_pattern_8(code as *const pcre2_real_code_8, gcontext) }
    if match_data as i64 == 0:
        unsafe { pcre2_general_context_free_8(gcontext) }
        with_panic(what ++ ": match data creation failed", "", 0)
    match_data

// A NUL-terminated copy of `s` for the engine; the caller frees it.
fn regex_cstr(s: &str) -> *const u8:
    let out = with_alloc(s.len() + 1)
    var i: i64 = 0
    while i < s.len():
        unsafe { *((out as i64 + i) as *mut u8) = s.byte_at(i) }
        i = i + 1
    unsafe { *((out as i64 + s.len()) as *mut u8) = 0 }
    out as *const u8

fn regex_str_data(s: &str) -> *const u8:
    unsafe { **(&s as *const *const *const u8) }

unsafe fn regex_owned_cstr(s: *const u8) -> str:
    if s as i64 == 0:
        return ""
    var len: i64 = 0
    while s[len] != 0:
        len = len + 1
    with_str_from_bytes(s, len)

fn regex_error_message(code: i32) -> str:
    let buf = with_alloc(256)
    let rc = unsafe { pcre2_get_error_message_8(code, buf, 256) }
    let text = if rc < 0: "regex error" else: unsafe { regex_owned_cstr(buf as *const u8) }
    with_free(buf)
    text

// The compiled pattern, or null with `*err_code`/`*err_offset` set.
unsafe fn regex_compile_code(pattern: &str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8:
    let gcontext = regex_general_context("Regex.compile")
    var ccontext = _pcre2_default_compile_context_8
    ccontext.memctl = (*gcontext).memctl
    ccontext.max_pattern_length = ~(0 as c_ulong)
    ccontext.max_pattern_compiled_length = ~(0 as c_ulong)
    ccontext.parens_nest_limit = 250
    ccontext.max_varlookbehind = 255
    ccontext.newline_convention = 2
    ccontext.bsr_convention = 0
    ccontext.optimization_flags = 4294967295
    ccontext.tables = pcre2_maketables_8(gcontext)
    let c_pattern = regex_cstr(pattern)
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
    with_free(c_pattern as *mut u8)
    pcre2_general_context_free_8(gcontext)
    if err_code as i64 != 0:
        *err_code = raw_err_code
    if err_offset as i64 != 0:
        *err_offset = raw_err_offset as i32
    compiled as *const i8

fn regex_pattern_info(code: *const i8, what: c_int, where_: *mut c_void, label: &str):
    let rc = unsafe { pcre2_pattern_info_8(code as *const pcre2_real_code_8, what as c_uint, where_) }
    if rc < 0:
        with_panic("Regex." ++ label ++ ": pattern info failed", "", 0)

fn regex_pattern_info_count(code: *const i8, what: c_int, label: &str) -> i32:
    var count: c_uint = 0
    regex_pattern_info(code, what, (&raw mut count) as *mut c_void, label)
    count as i32

// The match ovector as [start, end] pairs; empty when nothing matched.
fn regex_match_spans_at(code: *const i8, text: &str, start_offset: i32) -> Vec[i32]:
    let spans: Vec[i32] = Vec.new()
    if code as i64 == 0 or start_offset < 0 or start_offset as i64 > text.len():
        return spans
    let gcontext = regex_general_context("Regex.captures_at")
    let match_data = regex_match_data(code, gcontext, "Regex.captures_at")
    let rc = unsafe { pcre2_match_8(
        code as *const pcre2_real_code_8,
        regex_str_data(text),
        text.len() as c_ulong,
        start_offset as c_ulong,
        0,
        match_data,
        null
    ) }
    if rc >= 0:
        let ovector = unsafe { pcre2_get_ovector_pointer_8(match_data) }
        let count = unsafe { pcre2_get_ovector_count_8(match_data) } as i32
        for i in 0..count:
            spans.push(unsafe { *((ovector as i64 + i as i64 * 16) as *const c_ulong) } as i32)
            spans.push(unsafe { *((ovector as i64 + i as i64 * 16 + 8) as *const c_ulong) } as i32)
    unsafe { pcre2_match_data_free_8(match_data) }
    unsafe { pcre2_general_context_free_8(gcontext) }
    spans

fn regex_group_index(code: *const i8, name: &str) -> i32:
    if code as i64 == 0:
        return -1
    let cname = regex_cstr(name)
    let number = unsafe { pcre2_substring_number_from_name_8(code as *const pcre2_real_code_8, cname) }
    with_free(cname as *mut u8)
    if number < 0: -1 else: number

fn regex_substitute_into(code: *const i8, text: &str, c_repl: *const u8, repl_len: i64, options: c_uint, match_data: *mut pcre2_real_match_data_8, buffer: *mut u8, buffer_len: *mut c_ulong) -> c_int:
    unsafe { pcre2_substitute_8(
        code as *const pcre2_real_code_8,
        regex_str_data(text),
        text.len() as c_ulong,
        0,
        options,
        match_data,
        null,
        c_repl,
        repl_len as c_ulong,
        buffer,
        buffer_len
    ) }

fn regex_substitute(code: *const i8, text: &str, repl: &str, replace_all: bool) -> str:
    if code as i64 == 0:
        return with_str_clone_ref(text)
    let gcontext = regex_general_context("Regex.replace")
    let match_data = regex_match_data(code, gcontext, "Regex.replace")
    let c_repl = regex_cstr(repl)
    var options: c_uint = PCRE2_SUBSTITUTE_UNSET_EMPTY | PCRE2_SUBSTITUTE_OVERFLOW_LENGTH
    if replace_all:
        options = options | PCRE2_SUBSTITUTE_GLOBAL
    var buffer_len: c_ulong = (text.len() + repl.len() + 64) as c_ulong
    var buffer = with_alloc(buffer_len as i64 + 1)
    var rc = regex_substitute_into(code, text, c_repl, repl.len(), options, match_data, buffer, &raw mut buffer_len)
    if rc == PCRE2_ERROR_NOMEMORY:
        // The engine reported the length it needs (PCRE2_SUBSTITUTE_OVERFLOW_LENGTH).
        with_free(buffer)
        buffer = with_alloc(buffer_len as i64 + 1)
        rc = regex_substitute_into(code, text, c_repl, repl.len(), options, match_data, buffer, &raw mut buffer_len)
    if rc < 0:
        let msg = "Regex.replace: " ++ regex_error_message(rc as i32)
        with_free(c_repl as *mut u8)
        with_free(buffer)
        unsafe { pcre2_match_data_free_8(match_data) }
        unsafe { pcre2_general_context_free_8(gcontext) }
        with_panic(msg, "", 0)
    unsafe { *((buffer as i64 + buffer_len as i64) as *mut u8) = 0 }
    let result = with_str_from_bytes(buffer as *const u8, buffer_len as i64)
    with_free(c_repl as *mut u8)
    with_free(buffer)
    unsafe { pcre2_match_data_free_8(match_data) }
    unsafe { pcre2_general_context_free_8(gcontext) }
    result

// ── Flags ────────────────────────────────────────────────────────────

fn regex_compile_flags(flags: &str) -> Result[RegexFlags, RegexError]:
    var options: i32 = 0
    var state_flags: i32 = 0
    var i: i64 = 0
    while i < flags.len():
        let flag_byte = flags[i]
        if flag_byte == 103:
            state_flags = state_flags | REGEX_FLAG_GLOBAL
        else if flag_byte == 105:
            options = options | 8
        else if flag_byte == 109:
            options = options | 1024
        else if flag_byte == 115:
            options = options | 32
        else if flag_byte == 120:
            options = options | 128
        else if flag_byte == 85:
            options = options | 262144
        else if flag_byte == 117:
            options = options | 524288 | 131072
        else:
            return Err(RegexError {
                code: -1000,
                offset: i as i32,
                message: "unknown regex flag",
            })
        i = i + 1
    Ok(regex_make_flags(options, state_flags))

impl Regex:
    pub fn clone() -> Self:
        let copied = unsafe { pcre2_code_copy_8(self.ptr as *const pcre2_real_code_8) }
        if copied as i64 == 0:
            with_panic("Regex.clone(): pcre2_code_copy_8 failed", "", 0)
        Regex {
            ptr: copied as *const i8,
            pattern_text: with_str_clone_ref(self.pattern_text),
            flags_text: with_str_clone_ref(self.flags_text),
            options: self.options,
            flags: self.flags,
            capture_count: self.capture_count,
            owned: 1,
            global_pos: null,
            global_subject_ptr: null,
            global_subject_len: null,
        }

    move fn drop():
        if self.owned != 0 and self.ptr as i64 != 0:
            unsafe { pcre2_code_free_8(self.ptr as *mut pcre2_real_code_8) }

    pub fn is_global() -> bool:
        (self.flags & REGEX_FLAG_GLOBAL) != 0

pub fn Regex.compile(pattern: str) -> Result[Regex, RegexError]:
    Regex.compile_flags(pattern, "")

pub fn Regex.compile_flags(pattern: str, flags: str) -> Result[Regex, RegexError]:
    match regex_compile_flags(flags):
        Ok(parsed_flags) => {
            var err_code: i32 = 0
            var err_offset: i32 = 0
            let compiled = unsafe { regex_compile_code(pattern, parsed_flags.options, &raw mut err_code, &raw mut err_offset) }
            if compiled as i64 == 0:
                return Err(RegexError {
                    code: err_code,
                    offset: err_offset,
                    message: regex_error_message(err_code),
                })
            Ok(Regex {
                ptr: compiled,
                pattern_text: pattern,
                flags_text: flags,
                options: parsed_flags.options,
                flags: parsed_flags.flags,
                capture_count: Regex.__capture_count(compiled),
                owned: 1,
                global_pos: null,
                global_subject_ptr: null,
                global_subject_len: null,
            })
        }
        Err(err) => Err(err)

// The regex-literal entry points (CodegenDispatch.gen_regex_literal_value):
// a literal compiles once into its slot, and its value carries the capture
// count. Compiled code has no With type here; its raw pointer is opaque.
pub unsafe fn Regex.__literal_code(slot: *mut *const i8, pattern: &str, options: i32) -> *const i8:
    if slot as i64 == 0:
        return null
    let existing = *slot
    if existing as i64 != 0:
        return existing
    var err_code: i32 = 0
    var err_offset: i32 = 0
    let compiled = regex_compile_code(pattern, options, &raw mut err_code, &raw mut err_offset)
    if compiled as i64 == 0:
        with_panic("invalid regex literal: " ++ regex_error_message(err_code), "", 0)
    *slot = compiled
    compiled

pub fn Regex.__capture_count(code: *const i8) -> i32:
    if code as i64 == 0:
        return 0
    regex_pattern_info_count(code, PCRE2_INFO_CAPTURECOUNT, "num_captures")

impl Regex:
    pub fn pattern() -> str:
        self.pattern_text.clone()

    pub fn num_captures() -> i32:
        self.capture_count

    pub fn capture_index(name: &str) -> Option[i32]:
        let number = regex_group_index(self.ptr, name)
        if number < 0:
            return None
        Some(number)

    pub fn capture_names() -> Vec[str]:
        let out: Vec[str] = Vec.new()
        if self.ptr as i64 == 0:
            return out
        let count = regex_pattern_info_count(self.ptr, PCRE2_INFO_NAMECOUNT, "capture_names")
        if count == 0:
            return out
        let entry_size = regex_pattern_info_count(self.ptr, PCRE2_INFO_NAMEENTRYSIZE, "capture_names")
        var table: *const u8 = null
        regex_pattern_info(self.ptr, PCRE2_INFO_NAMETABLE, (&raw mut table) as *mut c_void, "capture_names")
        // Each entry: a two-byte group number, then the NUL-terminated name.
        for i in 0..count:
            out.push(unsafe { regex_owned_cstr((table as i64 + i as i64 * entry_size as i64 + 2) as *const u8) })
        out

    pub fn captures(text: &str) -> Option[Captures]:
        self.captures_at(text, 0)

    pub fn captures_at(text: &str, start_offset: i32) -> Option[Captures]:
        let spans = regex_match_spans_at(self.ptr, text, start_offset)
        if spans.len() == 0:
            return None
        Some(Captures { regex_ptr: self.ptr, subject: with_str_clone_ref(text), spans: spans, })

    pub fn is_match(text: &str) -> bool:
        self.captures(text).is_some()

    pub fn captures_match_op(text: &str) -> Option[Captures]:
        if not self.is_global() or self.global_pos as i64 == 0 or self.global_subject_ptr as i64 == 0 or self.global_subject_len as i64 == 0:
            return self.captures(text)
        let subject_ptr = regex_str_data(text) as i64
        let subject_len = text.len()
        if unsafe *self.global_subject_ptr != subject_ptr or unsafe *self.global_subject_len != subject_len:
            unsafe *self.global_subject_ptr = subject_ptr
            unsafe *self.global_subject_len = subject_len
            unsafe *self.global_pos = 0
        let start_offset = unsafe *self.global_pos
        match self.captures_at(text, start_offset):
            Some(captures) => {
                match captures.get(0):
                    Some(found) => {
                        if found.end == found.start:
                            if found.end >= text.len() as i32:
                                unsafe *self.global_pos = text.len() as i32 + 1
                            else:
                                unsafe *self.global_pos = found.end + 1
                        else:
                            unsafe *self.global_pos = found.end
                        Some(captures)
                    }
                    None => {
                        unsafe *self.global_pos = 0
                        None
                    }
            }
            None => {
                unsafe *self.global_pos = 0
                None
            }

    pub fn find(text: &str) -> Option[Match]:
        self.find_at(text, 0)

    pub fn find_at(text: &str, start_offset: i32) -> Option[Match]:
        match self.captures_at(text, start_offset):
            Some(captures) => captures.get(0)
            None => None

    pub fn find_all(text: &str) -> Vec[Match]:
        let out: Vec[Match] = Vec.new()
        var cursor: i32 = 0
        while cursor <= text.len() as i32:
            match self.find_at(text, cursor):
                Some(found) => {
                    // #747: Match is non-Copy — read the span before the push
                    // transfers ownership into the result vector.
                    let f_start = found.start
                    let f_end = found.end
                    out.push(found)
                    if f_end == f_start:
                        if f_end >= text.len() as i32:
                            break
                        cursor = f_end + 1
                    else:
                        cursor = f_end
                }
                None => break
        out

    pub fn captures_all(text: &str) -> Vec[Captures]:
        let out: Vec[Captures] = Vec.new()
        var cursor: i32 = 0
        while cursor <= text.len() as i32:
            match self.captures_at(text, cursor):
                Some(captures) => {
                    match captures.get(0):
                        Some(found) => {
                            out.push(move captures)
                            if found.end == found.start:
                                if found.end >= text.len() as i32:
                                    break
                                cursor = found.end + 1
                            else:
                                cursor = found.end
                        }
                        None => break
                }
                None => break
        out

fn regex_expand_numbered_capture(captures: &Captures, repl: &str, start: i64, end: i64) -> str:
    var number: i32 = 0
    var i = start
    while i < end:
        number = number * 10 + (repl[i] as i32 - 48)
        i = i + 1
    match captures.get(number):
        Some(found) => { var taken = found; let out = move taken.text; out }
        None => ""

fn regex_is_name_start(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 95

fn regex_is_name_continue(ch: i32) -> bool:
    regex_is_name_start(ch) or (ch >= 48 and ch <= 57)

fn regex_expand_replacement(captures: &Captures, repl: &str) -> str:
    var out = ""
    var i: i64 = 0
    while i < repl.len():
        let ch = repl[i]
        if ch != 36:
            out = out ++ with_str_from_byte(ch)
            i = i + 1
            continue
        if i + 1 >= repl.len():
            out = out ++ "$"
            i = i + 1
            continue
        let next = repl[i + 1]
        if next == 36:
            out = out ++ "$"
            i = i + 2
            continue
        if next >= 48 and next <= 57:
            let digit_start = i + 1
            var digit_end = digit_start
            while digit_end < repl.len() and repl[digit_end] >= 48 and repl[digit_end] <= 57:
                digit_end = digit_end + 1
            out = out ++ regex_expand_numbered_capture(captures, repl, digit_start, digit_end)
            i = digit_end
            continue
        if next == 123:
            var name_end = i + 2
            while name_end < repl.len() and repl[name_end] != 125:
                name_end = name_end + 1
            if name_end < repl.len():
                let name = with_str_slice_ref(repl, i + 2, name_end)
                match captures.name(name):
                    Some(found) => out = out ++ found.text
                    None => {}
                i = name_end + 1
                continue
        if regex_is_name_start(next):
            let name_start = i + 1
            var name_end = name_start
            while name_end < repl.len() and regex_is_name_continue(repl[name_end]):
                name_end = name_end + 1
            let name = with_str_slice_ref(repl, name_start, name_end)
            match captures.name(name):
                Some(found) => out = out ++ found.text
                None => {}
            i = name_end
            continue
        out = out ++ "$"
        i = i + 1
    out

impl Regex:
    fn replace_impl(text: &str, repl: &str, replace_all: bool) -> str:
        var out = ""
        var cursor: i32 = 0
        while cursor <= text.len() as i32:
            match self.captures_at(text, cursor):
                Some(captures) => {
                    match captures.get(0):
                        Some(found) => {
                            out = out ++ with_str_slice_ref(text, cursor as i64, found.start as i64) ++ regex_expand_replacement(&captures, repl)
                            if not replace_all:
                                out = out ++ with_str_slice_ref(text, found.end as i64, text.len())
                                break
                            if found.end == found.start:
                                if found.end >= text.len() as i32:
                                    cursor = text.len() as i32 + 1
                                else:
                                    out = out ++ with_str_slice_ref(text, found.start as i64, found.start as i64 + 1)
                                    cursor = found.start + 1
                            else:
                                cursor = found.end
                        }
                        None => {
                            out = out ++ with_str_slice_ref(text, cursor as i64, text.len())
                            break
                        }
                }
                None => {
                    out = out ++ with_str_slice_ref(text, cursor as i64, text.len())
                    break
                }
        out

    pub fn replace(text: &str, repl: &str) -> str:
        regex_substitute(self.ptr, text, repl, self.is_global())

    pub fn replace_all(text: &str, repl: &str) -> str:
        regex_substitute(self.ptr, text, repl, true)

    pub fn replace_fn(text: &str, replacement_callback: fn(&Captures) -> str) -> str:
        var out = ""
        var cursor: i32 = 0
        while cursor <= text.len() as i32:
            match self.captures_at(text, cursor):
                Some(captures) => {
                    match captures.get(0):
                        Some(found) => {
                            out = out ++ with_str_slice_ref(text, cursor as i64, found.start as i64) ++ replacement_callback(&captures)
                            out = out ++ with_str_slice_ref(text, found.end as i64, text.len())
                            return out
                        }
                        None => break
                }
                None => break
        with_str_clone_ref(text)

    pub fn replace_all_fn(text: &str, replacement_callback: fn(&Captures) -> str) -> str:
        var out = ""
        var cursor: i32 = 0
        while cursor <= text.len() as i32:
            match self.captures_at(text, cursor):
                Some(captures) => {
                    match captures.get(0):
                        Some(found) => {
                            out = out ++ with_str_slice_ref(text, cursor as i64, found.start as i64) ++ replacement_callback(&captures)
                            if found.end == found.start:
                                if found.end >= text.len() as i32:
                                    cursor = text.len() as i32 + 1
                                else:
                                    out = out ++ with_str_slice_ref(text, found.start as i64, found.start as i64 + 1)
                                    cursor = found.start + 1
                            else:
                                cursor = found.end
                        }
                        None => {
                            out = out ++ with_str_slice_ref(text, cursor as i64, text.len())
                            return out
                        }
                }
                None => {
                    out = out ++ with_str_slice_ref(text, cursor as i64, text.len())
                    return out
                }
        out

    pub fn split(text: &str) -> Vec[str]:
        self.splitn(text, 0)

    pub fn splitn(text: &str, n: i32) -> Vec[str]:
        let out: Vec[str] = Vec.new()
        var cursor: i32 = 0
        while cursor <= text.len() as i32:
            if n > 0 and out.len() as i32 >= n - 1:
                out.push(with_str_slice_ref(text, cursor as i64, text.len()))
                return out
            match self.find_at(text, cursor):
                Some(found) => {
                    out.push(with_str_slice_ref(text, cursor as i64, found.start as i64))
                    if found.end == found.start:
                        if found.end >= text.len() as i32:
                            cursor = text.len() as i32 + 1
                        else:
                            cursor = found.start + 1
                    else:
                        cursor = found.end
                }
                None => {
                    out.push(with_str_slice_ref(text, cursor as i64, text.len()))
                    break
                }
        out

impl Captures:
    pub fn get(index: i32) -> Option[Match]:
        let base = index * 2
        if base < 0 or base + 1 >= self.spans.len() as i32:
            return None
        let start = self.spans[base]
        let end = self.spans[(base + 1)]
        if start < 0 or end < 0:
            return None
        Some(Match {
            text: with_str_slice_ref(self.subject, start as i64, end as i64),
            start: start,
            end: end,
        })

    pub fn len() -> i32:
        (self.spans.len() as i32) / 2

    pub fn by_name(name: &str) -> Option[Match]:
        let number = regex_group_index(self.regex_ptr, name)
        if number < 0:
            return None
        self.get(number)

    pub fn name(name: &str) -> Option[Match]:
        self.by_name(name)

    pub fn text(index: i32) -> str:
        match self.get(index):
            Some(found) => { var taken = found; let out = move taken.text; out }
            None => ""

    pub fn name_text(name: &str) -> str:
        let lookup_name = if name.len() > 0 and name[0] == 36:
            with_str_slice_ref(name, 1, name.len())
        else:
            with_str_clone_ref(name)
        match self.name(lookup_name):
            Some(found) => { var taken = found; let out = move taken.text; out }
            None => ""

impl Regex:
    pub fn capture_text(text: &str, index: i32) -> str:
        match self.captures(text):
            Some(captures) => {
                match captures.get(index):
                    Some(found) => { var taken = found; let out = move taken.text; out }
                    None => ""
            }
            None => ""

    pub fn capture_name_text(text: &str, name: &str) -> str:
        let lookup_name = if name.len() > 0 and name[0] == 36:
            with_str_slice_ref(name, 1, name.len())
        else:
            with_str_clone_ref(name)
        match self.captures(text):
            Some(captures) => {
                match captures.name(lookup_name):
                    Some(found) => { var taken = found; let out = move taken.text; out }
                    None => ""
            }
            None => ""
