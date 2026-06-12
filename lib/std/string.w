// std.string — String utility functions
//
// Most string methods are built-in on the str type:
//   s.len()         → i64    — string length
//   s.is_empty()    → bool   — true if length is 0
//   s.contains(sub) → bool   — true if sub is found in s
//   s.starts_with(p)→ bool   — true if s starts with prefix p
//   s.ends_with(sf) → bool   — true if s ends with suffix sf
//   s.find(sub)     → i64    — index of first occurrence, or -1
//   s.to_upper()    → str    — new uppercase string
//   s.to_lower()    → str    — new lowercase string
//   s.trim()        → str    — string with leading/trailing whitespace removed
//   s.repeat(n)     → str    — string repeated n times
//   s.slice(a, b)   → str    — substring from index a to b
//   s.replace(o, n) → str    — replace all occurrences of o with n
//   s.split(delim)  → Vec[str] — split by delimiter
//
// This module provides additional utility functions.
// No c_import — uses with_* runtime functions.

use std.collections
extern fn with_lines_out(out: *mut c_void, s: str) -> Unit
extern fn with_parse_i64(s: str) -> i64
extern fn with_str_len(s: str) -> i64
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_str_from_vec_u8(bytes: *const Vec[u8]) -> str

/// Amortized string builder for code that appends in loops.
///
/// `++` is fine for short expressions, but repeated `out = out ++ part`
/// copies the whole prefix on every append. StringBuilder stores bytes in a
/// Vec[u8], so appending N total bytes grows geometrically and finishes with
/// one materialized str.
pub type StringBuilder {
    bytes: Vec[u8],
}

/// Create an empty builder.
pub fn StringBuilder.new() -> Self:
    StringBuilder { bytes: Vec[u8].new() }

/// Create an empty builder with room for at least `capacity` bytes.
pub fn StringBuilder.with_capacity(capacity: i64) -> Self:
    let cap = if capacity > 0: capacity else: 0
    StringBuilder { bytes: Vec[u8].with_capacity(cap) }

/// Append raw UTF-8 bytes from a string.
pub fn StringBuilder.push_str(mut self: Self, s: str) -> Unit:
    for i in 0..s.len():
        self.bytes.push(s.byte_at(i) as u8)
    return

/// Append one byte.
pub fn StringBuilder.push_byte(mut self: Self, b: u8) -> Unit:
    self.bytes.push(b)
    return

/// Append one byte from an integer code point.
pub fn StringBuilder.push_char(mut self: Self, b: i32) -> Unit:
    self.bytes.push(b as u8)
    return

/// Number of bytes appended so far.
pub fn StringBuilder.len(self: &Self) -> i64:
    self.bytes.len

/// True when no bytes have been appended.
pub fn StringBuilder.is_empty(self: &Self) -> bool:
    self.bytes.len == 0

/// Materialize the accumulated bytes as an owned str.
pub fn StringBuilder.to_str(self: &Self) -> str:
    with_str_from_vec_u8(&self.bytes)

/// String length (same as `s.len()`).
pub fn string_len(s: str) -> i64:
    with_str_len(s)

/// StrView length helper.
pub fn view_len(v: &str) -> i64:
    v.len

/// StrView emptiness helper.
pub fn view_is_empty(v: &str) -> bool:
    v.len == 0

/// StrView equality helper.
pub fn view_eq(a: &str, b: &str) -> bool:
    a == b

/// C string byte length, excluding the trailing NUL.
pub fn CStr.len(self: &Self) -> i64:
    self.len

/// Compare two strings for equality. Returns true if equal.
pub fn string_eq(a: str, b: str) -> bool:
    with_str_eq(a, b) != 0

/// Compare two strings lexicographically. Returns negative, 0, or positive.
pub fn string_cmp(a: str, b: str) -> i32:
    // Byte-by-byte comparison
    let al = a.len()
    let bl = b.len()
    let min_len = if al < bl: al else: bl
    var i: i64 = 0
    while i < min_len:
        let ca = a.byte_at(i)
        let cb = b.byte_at(i)
        if ca != cb:
            return ca - cb
        i = i + 1
    if al < bl: return -1
    if al > bl: return 1
    0

/// Returns true if the character code is alphabetic (A-Z, a-z).
pub fn is_alpha(c: i32) -> bool:
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

/// Returns true if the character code is a decimal digit (-9).
pub fn is_digit(c: i32) -> bool:
    c >= 48 and c <= 57

/// Returns true if the character code is whitespace (space, tab, newline, etc.).
pub fn is_space(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11

/// Returns true if the character code is alphanumeric (letter or digit).
pub fn is_alnum(c: i32) -> bool:
    is_alpha(c) or is_digit(c)

/// Returns true if the character code is an uppercase letter (A-Z).
pub fn is_upper(c: i32) -> bool:
    c >= 65 and c <= 90

/// Returns true if the character code is a lowercase letter (a-z).
pub fn is_lower(c: i32) -> bool:
    c >= 97 and c <= 122

/// Returns true if the character code is a hex digit (-9, a-f, A-F).
pub fn is_xdigit(c: i32) -> bool:
    (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)

/// Returns true if the character code is printable (0x20-0x7E).
pub fn is_print(c: i32) -> bool:
    c >= 32 and c <= 126

/// Convert uppercase to lowercase (ASCII). Returns unchanged if not uppercase.
pub fn to_lower(c: i32) -> i32:
    if c >= 65 and c <= 90: c + 32 else: c

/// Convert lowercase to uppercase (ASCII). Returns unchanged if not lowercase.
pub fn to_upper(c: i32) -> i32:
    if c >= 97 and c <= 122: c - 32 else: c

/// Convert a string to an i64 integer. Returns 0 on invalid input.
pub fn string_to_int(s: str) -> i64:
    with_parse_i64(s)

/// Split text into lines. Returns a Vec of strings, one per line.
pub fn lines(s: str) -> Vec[str]:
    var out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_lines_out((&raw mut out) as *mut c_void, s)
    out

/// Parse a string as an i32 integer.
pub fn parse(s: str) -> i32:
    let n = string_to_int(s)
    n as i32
