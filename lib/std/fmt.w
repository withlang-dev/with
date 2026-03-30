// std.fmt — Formatting utility functions
//
// Provides formatted output helpers wrapping C printf family.

use c_import("stdio.h")
use c_import("stdlib.h")

/// Format an integer into a string buffer. Returns number of characters written.
pub fn fmt_int(buf: *i8, size: i32, n: i32) -> i32:
    snprintf(buf, size, "%d" as *const i8, n)

/// Format a float into a string buffer. Returns number of characters written.
pub fn fmt_float(buf: *i8, size: i32, x: f64) -> i32:
    snprintf(buf, size, "%f" as *const i8, x)

/// Format an integer as hexadecimal into a string buffer.
pub fn fmt_hex(buf: *i8, size: i32, n: i32) -> i32:
    snprintf(buf, size, "0x%x" as *const i8, n)
