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

use c_import("#include <string.h>\n#include <stdlib.h>\n#include <stdio.h>\n#include <ctype.h>")

// String length (same as s.len())
pub fn string_len(s: str) -> i64:
    strlen(s) as i64

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
    strcmp(a, b) == 0

// String comparison (returns negative, 0, or positive)
pub fn string_cmp(a: str, b: str) -> i32:
    strcmp(a, b)

// Check if character is alphabetic
pub fn is_alpha(c: i32) -> bool:
    isalpha(c) != 0

// Check if character is a digit
pub fn is_digit(c: i32) -> bool:
    isdigit(c) != 0

// Check if character is whitespace
pub fn is_space(c: i32) -> bool:
    isspace(c) != 0

// Convert string to integer
pub fn string_to_int(s: str) -> i64:
    atol(s)
