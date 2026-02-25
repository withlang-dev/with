// std.string — String utility functions
//
// Provides common string operations wrapping C stdlib functions.

use c_import("#include <string.h>\n#include <stdlib.h>\n#include <stdio.h>")

// String length
pub fn string_len(s: str) -> i64 =
    strlen(s)

// String comparison (returns 0 if equal)
pub fn string_eq(a: str, b: str) -> bool =
    strcmp(a, b) == 0

// String comparison (returns negative, 0, or positive)
pub fn string_cmp(a: str, b: str) -> i32 =
    strcmp(a, b)
