// std.regex — high-level regex facade over the migrated PCRE2 engine.

use std.builtins
use std.collections
use std.option
use std.result

extern fn with_str_slice_ref(s: &str, start: i64, end: i64) -> str
extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_from_byte(b: i32) -> str
extern fn with_regex_error_message(code: i32) -> str
extern fn with_regex_compile(pattern: &str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_code_copy(code: *const i8) -> *const i8
extern fn with_regex_code_free(code: *const i8) -> Unit
extern fn with_regex_capture_count(code: *const i8) -> i32
extern fn with_regex_match_spans_alloc_at(code: *const i8, text: &str, start_offset: i32, out_count: *mut i32) -> *const i32
extern fn with_regex_capture_name_count(code: *const i8) -> i32
extern fn with_regex_capture_name_at(code: *const i8, index: i32) -> str
extern fn with_regex_group_name_to_index(code: *const i8, name: &str) -> i32
extern fn with_regex_substitute(code: *const i8, text: &str, repl: &str, replace_all: i32) -> str
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

fn regex_error_message(code: i32) -> str:
    with_regex_error_message(code)

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
        let copied = with_regex_code_copy(self.ptr)
        if copied as i64 == 0:
            with_panic("Regex.clone(): pcre2_code_copy_8 failed", "", 0)
        Regex {
            ptr: copied,
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
            with_regex_code_free(self.ptr)

    pub fn is_global() -> bool:
        (self.flags & REGEX_FLAG_GLOBAL) != 0

pub fn Regex.compile(pattern: str) -> Result[Regex, RegexError]:
    Regex.compile_flags(pattern, "")

pub fn Regex.compile_flags(pattern: str, flags: str) -> Result[Regex, RegexError]:
    match regex_compile_flags(flags):
        Ok(parsed_flags) => {
            var err_code: i32 = 0
            var err_offset: i32 = 0
            let compiled = with_regex_compile(pattern, parsed_flags.options, &raw mut err_code, &raw mut err_offset)
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
                capture_count: with_regex_capture_count(compiled),
                owned: 1,
                global_pos: null,
                global_subject_ptr: null,
                global_subject_len: null,
            })
        }
        Err(err) => Err(err)

pub unsafe fn Regex.__literal_code(slot: *mut *const i8, pattern: &str, options: i32) -> *const i8:
    if slot as i64 == 0:
        return null
    let existing = *slot
    if existing as i64 != 0:
        return existing
    var err_code: i32 = 0
    var err_offset: i32 = 0
    let compiled = with_regex_compile(pattern, options, &raw mut err_code, &raw mut err_offset)
    if compiled as i64 == 0:
        with_panic("invalid regex literal: " ++ regex_error_message(err_code), "", 0)
    *slot = compiled
    compiled

impl Regex:
    pub fn pattern() -> str:
        self.pattern_text.clone()

    pub fn num_captures() -> i32:
        self.capture_count

    pub fn capture_index(name: &str) -> Option[i32]:
        if self.ptr as i64 == 0:
            return None
        let number = with_regex_group_name_to_index(self.ptr, name)
        if number < 0:
            return None
        Some(number)

    pub fn capture_names() -> Vec[str]:
        let out: Vec[str] = Vec.new()
        if self.ptr as i64 == 0:
            return out
        let count = with_regex_capture_name_count(self.ptr)
        var i: i32 = 0
        while i < count:
            out.push(with_regex_capture_name_at(self.ptr, i))
            i = i + 1
        out

    pub fn captures(text: &str) -> Option[Captures]:
        self.captures_at(text, 0)

    pub fn captures_at(text: &str, start_offset: i32) -> Option[Captures]:
        if self.ptr as i64 == 0:
            return None
        var ints_count: i32 = 0
        let raw = with_regex_match_spans_alloc_at(self.ptr, text, start_offset, &raw mut ints_count)
        if raw as i64 == 0 or ints_count <= 0:
            return None
        let spans: Vec[i32] = Vec.new()
        var i: i32 = 0
        while i < ints_count:
            spans.push(unsafe *((raw as i64 + i as i64 * 4) as *const i32))
            i = i + 1
        with_free(raw as *mut u8)
        Some(Captures { regex_ptr: self.ptr, subject: with_str_clone_ref(text), spans: spans, })

    pub fn is_match(text: &str) -> bool:
        self.captures(text).is_some()

    pub fn captures_match_op(text: &str) -> Option[Captures]:
        if not self.is_global() or self.global_pos as i64 == 0 or self.global_subject_ptr as i64 == 0 or self.global_subject_len as i64 == 0:
            return self.captures(text)
        let subject_ptr = unsafe **(&text as *const *const *const u8) as i64
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
        number = number * 10 + (repl[i] - 48)
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
        with_regex_substitute(self.ptr, text, repl, if self.is_global(): 1 else: 0)

    pub fn replace_all(text: &str, repl: &str) -> str:
        with_regex_substitute(self.ptr, text, repl, 1)

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
        if self.regex_ptr as i64 == 0:
            return None
        let number = with_regex_group_name_to_index(self.regex_ptr, name)
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
