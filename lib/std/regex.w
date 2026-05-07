// std.regex — high-level regex facade over the migrated PCRE2 engine.

use std.builtins
use std.collections
use std.option
use std.result

extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn with_regex_error_message(code: i32) -> str
extern fn with_regex_compile(pattern: str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_code_copy(code: *const i8) -> *const i8
extern fn with_regex_code_free(code: *const i8) -> void
extern fn with_regex_capture_count(code: *const i8) -> i32
extern fn with_regex_match_spans_alloc(code: *const i8, text: str, out_count: *mut i32) -> *const i32
extern fn with_regex_group_name_to_index(code: *const i8, name: str) -> i32
extern fn with_free(ptr: *mut u8) -> void

const REGEX_FLAG_GLOBAL: i32 = 1

type Match {
    text: str,
    start: i32,
    end: i32,
}
impl Copy for Match

type RegexError {
    code: i32,
    offset: i32,
    message: str,
}

type RegexFlags {
    options: i32,
    flags: i32,
}
impl Copy for RegexFlags

type Regex {
    ptr: *const i8,
    options: i32,
    flags: i32,
    capture_count: i32,
}

type Captures {
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
                code: 0 - 1000,
                offset: i as i32,
                message: "unknown regex flag",
            })
        i = i + 1
    Ok(regex_make_flags(options, state_flags))

fn Regex.clone(self: &Self) -> Self:
    let copied = with_regex_code_copy(self.ptr)
    if copied as i64 == 0:
        with_panic("Regex.clone(): pcre2_code_copy_8 failed", "", 0)
    Regex {
        ptr: copied,
        options: self.options,
        flags: self.flags,
        capture_count: self.capture_count,
    }

fn Regex.drop(move self: Self):
    if self.ptr as i64 != 0:
        with_regex_code_free(self.ptr)

fn Regex.is_global(self: &Self) -> bool:
    (self.flags & REGEX_FLAG_GLOBAL) != 0

fn Regex.compile(pattern: str) -> Result[Regex, RegexError]:
    Regex.compile_flags(pattern, "")

fn Regex.compile_flags(pattern: str, flags: str) -> Result[Regex, RegexError]:
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
                options: parsed_flags.options,
                flags: parsed_flags.flags,
                capture_count: with_regex_capture_count(compiled),
            })
        }
        Err(err) => Err(err)

fn Regex.__compile_literal(pattern: str, flags: str, file: str, line: i32, col: i32) -> Regex:
    match Regex.compile_flags(pattern, flags):
        Ok(regex) => regex
        Err(err) => {
            let msg = "invalid regex literal at column " ++ col.to_string() ++ ": " ++ err.message
            with_panic(msg, file, line)
            Regex { ptr: null, options: 0, flags: 0, capture_count: 0, }
        }

fn Regex.captures(self: &Self, text: str) -> Option[Captures]:
    if self.ptr as i64 == 0:
        return None
    var ints_count: i32 = 0
    let raw = with_regex_match_spans_alloc(self.ptr, text, &raw mut ints_count)
    if raw as i64 == 0 or ints_count <= 0:
        return None
    let spans: Vec[i32] = Vec.new()
    var i: i32 = 0
    while i < ints_count:
        spans.push(unsafe: *((raw as i64 + i as i64 * 4) as *const i32))
        i = i + 1
    with_free(raw as *mut u8)
    Some(Captures { regex_ptr: self.ptr, subject: text, spans: spans, })

fn Regex.is_match(self: &Self, text: str) -> bool:
    self.captures(text).is_some()

fn Regex.find(self: &Self, text: str) -> Option[Match]:
    match self.captures(text):
        Some(captures) => captures.get(0)
        None => None

fn Regex.replace_all(self: &Self, text: str, repl: str) -> str:
    var out = ""
    var cursor: i64 = 0
    while cursor <= text.len():
        let rest = with_str_slice(text, cursor, text.len())
        match self.find(rest):
            Some(found) => {
                let abs_start = cursor + found.start as i64
                let abs_end = cursor + found.end as i64
                out = out ++ with_str_slice(text, cursor, abs_start) ++ repl
                if abs_end == abs_start:
                    if abs_end >= text.len():
                        cursor = text.len() + 1
                    else:
                        out = out ++ with_str_slice(text, abs_start, abs_start + 1)
                        cursor = abs_start + 1
                else:
                    cursor = abs_end
            }
            None => {
                out = out ++ rest
                break
            }
    out

fn Regex.split(self: &Self, text: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var cursor: i64 = 0
    while cursor <= text.len():
        let rest = with_str_slice(text, cursor, text.len())
        match self.find(rest):
            Some(found) => {
                let abs_start = cursor + found.start as i64
                let abs_end = cursor + found.end as i64
                out.push(with_str_slice(text, cursor, abs_start))
                if abs_end == abs_start:
                    if abs_end >= text.len():
                        cursor = text.len() + 1
                    else:
                        cursor = abs_start + 1
                else:
                    cursor = abs_end
            }
            None => {
                out.push(rest)
                break
            }
    out

fn Captures.get(self: &Self, index: i32) -> Option[Match]:
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

fn Captures.by_name(self: &Self, name: str) -> Option[Match]:
    if self.regex_ptr as i64 == 0:
        return None
    let number = with_regex_group_name_to_index(self.regex_ptr, name)
    if number < 0:
        return None
    self.get(number)
