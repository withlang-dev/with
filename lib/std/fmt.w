// std.fmt — Formatting utility functions
//
// Provides formatted output helpers via the runtime interface.
// No c_import — all formatting goes through with_fmt_* runtime functions.

extern fn with_fmt_i32(n: i32) -> str
extern fn with_fmt_i64(n: i64) -> str
extern fn with_fmt_f64(x: f64) -> str
extern fn with_fmt_bool(v: i32) -> str

/// Format an integer to a string.
pub fn fmt_int(n: i32) -> str:
    with_fmt_i32(n)

/// Format a 64-bit integer to a string.
pub fn fmt_int64(n: i64) -> str:
    with_fmt_i64(n)

/// Format a float to a string.
pub fn fmt_float(x: f64) -> str:
    with_fmt_f64(x)

/// Format a boolean to "true" or "false".
pub fn fmt_bool(v: bool) -> str:
    with_fmt_bool(if v: 1 else: 0)
