// std.fmt — Formatting utility functions
//
// Provides formatted output helpers wrapping C printf family.

use c_import("#include <stdio.h>\n#include <stdlib.h>")

// Format an integer to a string buffer (returns chars written)
pub fn fmt_int(buf: *i8, size: i32, n: i32) -> i32 =
    snprintf(buf, size, "%d", n)

// Format a float to a string buffer
pub fn fmt_float(buf: *i8, size: i32, x: f64) -> i32 =
    snprintf(buf, size, "%f", x)

// Format a hex integer
pub fn fmt_hex(buf: *i8, size: i32, n: i32) -> i32 =
    snprintf(buf, size, "0x%x", n)
