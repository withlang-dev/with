// std.regex — high-level regex facade over the migrated PCRE2 engine.

use std.builtins
use std.collections
use std.option
use std.result

extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_regex_error_message(code: i32) -> str
extern fn with_regex_compile(pattern: str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_code_copy(code: *const i8) -> *const i8
extern fn with_regex_code_free(code: *const i8) -> void
extern fn with_regex_capture_count(code: *const i8) -> i32
extern fn with_regex_match_spans_alloc(code: *const i8, text: str, out_count: *mut i32) -> *const i32
extern fn with_regex_match_spans_alloc_at(code: *const i8, text: str, start_offset: i32, out_count: *mut i32) -> *const i32
extern fn with_regex_capture_name_count(code: *const i8) -> i32
extern fn with_regex_capture_name_at(code: *const i8, index: i32) -> str
extern fn with_regex_group_name_to_index(code: *const i8, name: str) -> i32
extern fn with_free(ptr: *mut u8) -> void

const REGEX_FLAG_GLOBAL: i32 = 1

pub type Match {
    text: str,
    start: i32,
    end: i32,
}
impl Copy for Match

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

fn regex_compile_flags(flags: str) -> Result[RegexFlags, RegexError]:
    var options: i32 = 0
    var state_flags: i32 = 0
    var i: i64 = 0
    while i < flags.len():
        let flag_byte = flags.byte_at(i)
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

pub fn Regex.clone(self: &Self) -> Self:
    let copied = with_regex_code_copy(self.ptr)
    if copied as i64 == 0:
        with_panic("Regex.clone(): pcre2_code_copy_8 failed", "", 0)
    Regex {
        ptr: copied,
        pattern_text: self.pattern_text,
        flags_text: self.flags_text,
        options: self.options,
        flags: self.flags,
        capture_count: self.capture_count,
    }

fn Regex.drop(move self: Self):
    if self.ptr as i64 != 0:
        with_regex_code_free(self.ptr)

pub fn Regex.is_global(self: &Self) -> bool:
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
            })
        }
        Err(err) => Err(err)

pub fn Regex.__compile_literal(pattern: str, flags: str, file: str, line: i32, col: i32) -> Regex:
    match Regex.compile_flags(pattern, flags):
        Ok(regex) => regex.clone()
        Err(err) => {
            let msg = "invalid regex literal at column " ++ col.to_string() ++ ": " ++ err.message
            with_panic(msg, file, line)
            Regex { ptr: null, pattern_text: pattern, flags_text: flags, options: 0, flags: 0, capture_count: 0, }
        }

pub fn Regex.pattern(self: &Self) -> str:
    self.pattern_text

pub fn Regex.num_captures(self: &Self) -> i32:
    self.capture_count

pub fn Regex.capture_index(self: &Self, name: str) -> Option[i32]:
    if self.ptr as i64 == 0:
        return None
    let number = with_regex_group_name_to_index(self.ptr, name)
    if number < 0:
        return None
    Some(number)

pub fn Regex.capture_names(self: &Self) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    if self.ptr as i64 == 0:
        return out
    let count = with_regex_capture_name_count(self.ptr)
    var i: i32 = 0
    while i < count:
        out.push(with_regex_capture_name_at(self.ptr, i))
        i = i + 1
    out

pub fn Regex.captures(self: &Self, text: str) -> Option[Captures]:
    self.captures_at(text, 0)

pub fn Regex.captures_at(self: &Self, text: str, start_offset: i32) -> Option[Captures]:
    if self.ptr as i64 == 0:
        return None
    var ints_count: i32 = 0
    let raw = with_regex_match_spans_alloc_at(self.ptr, text, start_offset, &raw mut ints_count)
    if raw as i64 == 0 or ints_count <= 0:
        return None
    let spans: Vec[i32] = Vec.new()
    var i: i32 = 0
    while i < ints_count:
        spans.push(unsafe: *((raw as i64 + i as i64 * 4) as *const i32))
        i = i + 1
    with_free(raw as *mut u8)
    Some(Captures { regex_ptr: self.ptr, subject: text, spans: spans, })

pub fn Regex.is_match(self: &Self, text: str) -> bool:
    self.captures(text).is_some()

pub fn Regex.find(self: &Self, text: str) -> Option[Match]:
    self.find_at(text, 0)

pub fn Regex.find_at(self: &Self, text: str, start_offset: i32) -> Option[Match]:
    match self.captures_at(text, start_offset):
        Some(captures) => captures.get(0)
        None => None

pub fn Regex.find_all(self: &Self, text: str) -> Vec[Match]:
    let out: Vec[Match] = Vec.new()
    var cursor: i32 = 0
    while cursor <= text.len() as i32:
        match self.find_at(text, cursor):
            Some(found) => {
                out.push(found)
                if found.end == found.start:
                    if found.end >= text.len() as i32:
                        break
                    cursor = found.end + 1
                else:
                    cursor = found.end
            }
            None => break
    out

pub fn Regex.captures_all(self: &Self, text: str) -> Vec[Captures]:
    let out: Vec[Captures] = Vec.new()
    var cursor: i32 = 0
    while cursor <= text.len() as i32:
        match self.captures_at(text, cursor):
            Some(captures) => {
                match captures.get(0):
                    Some(found) => {
                        out.push(captures)
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

fn regex_expand_numbered_capture(captures: &Captures, repl: str, start: i64, end: i64) -> str:
    var number: i32 = 0
    var i = start
    while i < end:
        number = number * 10 + (repl.byte_at(i) - 48)
        i = i + 1
    match captures.get(number):
        Some(found) => found.text
        None => ""

fn regex_is_name_start(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 95

fn regex_is_name_continue(ch: i32) -> bool:
    regex_is_name_start(ch) or (ch >= 48 and ch <= 57)

fn regex_expand_replacement(captures: &Captures, repl: str) -> str:
    var out = ""
    var i: i64 = 0
    while i < repl.len():
        let ch = repl.byte_at(i)
        if ch != 36:
            out = out ++ str_from_byte(ch)
            i = i + 1
            continue
        if i + 1 >= repl.len():
            out = out ++ "$"
            i = i + 1
            continue
        let next = repl.byte_at(i + 1)
        if next == 36:
            out = out ++ "$"
            i = i + 2
            continue
        if next >= 48 and next <= 57:
            let digit_start = i + 1
            var digit_end = digit_start
            while digit_end < repl.len() and repl.byte_at(digit_end) >= 48 and repl.byte_at(digit_end) <= 57:
                digit_end = digit_end + 1
            out = out ++ regex_expand_numbered_capture(captures, repl, digit_start, digit_end)
            i = digit_end
            continue
        if next == 123:
            var name_end = i + 2
            while name_end < repl.len() and repl.byte_at(name_end) != 125:
                name_end = name_end + 1
            if name_end < repl.len():
                let name = with_str_slice(repl, i + 2, name_end)
                match captures.name(name):
                    Some(found) => out = out ++ found.text
                    None => {}
                i = name_end + 1
                continue
        if regex_is_name_start(next):
            let name_start = i + 1
            var name_end = name_start
            while name_end < repl.len() and regex_is_name_continue(repl.byte_at(name_end)):
                name_end = name_end + 1
            let name = with_str_slice(repl, name_start, name_end)
            match captures.name(name):
                Some(found) => out = out ++ found.text
                None => {}
            i = name_end
            continue
        out = out ++ "$"
        i = i + 1
    out

fn Regex.replace_impl(self: &Self, text: str, repl: str, replace_all: bool) -> str:
    var out = ""
    var cursor: i32 = 0
    while cursor <= text.len() as i32:
        match self.captures_at(text, cursor):
            Some(captures) => {
                match captures.get(0):
                    Some(found) => {
                        out = out ++ with_str_slice(text, cursor as i64, found.start as i64) ++ regex_expand_replacement(&captures, repl)
                        if not replace_all:
                            out = out ++ with_str_slice(text, found.end as i64, text.len())
                            break
                        if found.end == found.start:
                            if found.end >= text.len() as i32:
                                cursor = text.len() as i32 + 1
                            else:
                                out = out ++ with_str_slice(text, found.start as i64, found.start as i64 + 1)
                                cursor = found.start + 1
                        else:
                            cursor = found.end
                    }
                    None => {
                        out = out ++ with_str_slice(text, cursor as i64, text.len())
                        break
                    }
            }
            None => {
                out = out ++ with_str_slice(text, cursor as i64, text.len())
                break
            }
    out

pub fn Regex.replace(self: &Self, text: str, repl: str) -> str:
    self.replace_impl(text, repl, false)

pub fn Regex.replace_all(self: &Self, text: str, repl: str) -> str:
    self.replace_impl(text, repl, true)

pub fn Regex.split(self: &Self, text: str) -> Vec[str]:
    self.splitn(text, 0)

pub fn Regex.splitn(self: &Self, text: str, n: i32) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var cursor: i32 = 0
    while cursor <= text.len() as i32:
        if n > 0 and out.len() as i32 >= n - 1:
            out.push(with_str_slice(text, cursor as i64, text.len()))
            return out
        match self.find_at(text, cursor):
            Some(found) => {
                out.push(with_str_slice(text, cursor as i64, found.start as i64))
                if found.end == found.start:
                    if found.end >= text.len() as i32:
                        cursor = text.len() as i32 + 1
                    else:
                        cursor = found.start + 1
                else:
                    cursor = found.end
            }
            None => {
                out.push(with_str_slice(text, cursor as i64, text.len()))
                break
            }
    out

pub fn Captures.get(self: &Self, index: i32) -> Option[Match]:
    let base = index * 2
    if base < 0 or base + 1 >= self.spans.len() as i32:
        return None
    let start = self.spans.get(base as i64)
    let end = self.spans.get((base + 1) as i64)
    if start < 0 or end < 0:
        return None
    Some(Match {
        text: with_str_slice(self.subject, start as i64, end as i64),
        start: start,
        end: end,
    })

pub fn Captures.len(self: &Self) -> i32:
    (self.spans.len() as i32) / 2

pub fn Captures.by_name(self: &Self, name: str) -> Option[Match]:
    if self.regex_ptr as i64 == 0:
        return None
    let number = with_regex_group_name_to_index(self.regex_ptr, name)
    if number < 0:
        return None
    self.get(number)

pub fn Captures.name(self: &Self, name: str) -> Option[Match]:
    self.by_name(name)
