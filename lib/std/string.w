// std.string — String utility functions
//
// Provides common string operations wrapping C stdlib functions.

use c_import("#include <string.h>\n#include <stdlib.h>\n#include <stdio.h>\n#include <ctype.h>")

// String length
pub fn string_len(s: str) -> i64 =
    strlen(s)

// String comparison (returns true if equal)
pub fn string_eq(a: str, b: str) -> bool =
    strcmp(a, b) == 0

// String comparison (returns negative, 0, or positive)
pub fn string_cmp(a: str, b: str) -> i32 =
    strcmp(a, b)

// Check if string contains a substring
pub fn string_contains(haystack: str, needle: str) -> bool =
    strstr(haystack, needle) != 0

// Check if string starts with prefix
pub fn starts_with(s: str, prefix: str) -> bool =
    strncmp(s, prefix, strlen(prefix)) == 0

// Convert character to uppercase (ASCII)
pub fn char_to_upper(c: i32) -> i32 =
    toupper(c)

// Convert character to lowercase (ASCII)
pub fn char_to_lower(c: i32) -> i32 =
    tolower(c)

// Check if character is alphabetic
pub fn is_alpha(c: i32) -> bool =
    isalpha(c) != 0

// Check if character is a digit
pub fn is_digit(c: i32) -> bool =
    isdigit(c) != 0

// Check if character is whitespace
pub fn is_space(c: i32) -> bool =
    isspace(c) != 0

// Convert string to integer
pub fn string_to_int(s: str) -> i64 =
    atol(s)
