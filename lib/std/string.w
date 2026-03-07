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

use c_import("string.h")
extern fn with_lines_out(out: &Vec[str], s: str) -> void
extern fn with_parse_i64(s: str) -> i64

// String length (same as s.len())
pub fn string_len(s: str) -> i64:
    strlen(s as *const i8) as i64

// StrView length helper (same as v.len)
pub fn view_len(v: &str) -> i64:
    v.len

// StrView emptiness helper
pub fn view_is_empty(v: &str) -> bool:
    v.len == 0

// StrView equality helper
pub fn view_eq(a: &str, b: &str) -> bool:
    a == b

// String comparison (returns true if equal)
pub fn string_eq(a: str, b: str) -> bool:
    strcmp(a as *const i8, b as *const i8) == 0

// String comparison (returns negative, 0, or positive)
pub fn string_cmp(a: str, b: str) -> i32:
    strcmp(a as *const i8, b as *const i8)

// Check if character is alphabetic
pub fn is_alpha(c: i32) -> bool:
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

// Check if character is a digit
pub fn is_digit(c: i32) -> bool:
    c >= 48 and c <= 57

// Check if character is whitespace
pub fn is_space(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11

// Convert string to integer
pub fn string_to_int(s: str) -> i64:
    with_parse_i64(s)

// Split text by newline boundaries.
pub fn lines(s: str) -> Vec[str]:
    let out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_lines_out(&out, s)
    out

// Parse a trimmed string into i32.
pub fn parse(s: str) -> i32:
    let n = string_to_int(s)
    n as i32
