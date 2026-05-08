// std.io — I/O utility functions
//
// Provides basic I/O operations via the runtime interface.
// No c_import — all operations go through with_* runtime functions.

use std.collections
use std.string

extern fn with_print_str(s: str) -> void
extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_read_line_stdin() -> str
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_write_stdout(s: str) -> void
extern fn with_flush_stdout() -> void

pub type Stdin {
    __tag: i32,
}

pub let stdin: Stdin = Stdin { __tag: 0 }

/// Print a string to stdout (no newline).
pub fn print_str(s: str) -> void:
    with_print_str(s)

/// Print a string to stdout with newline.
pub fn print_line(s: str) -> void:
    with_println_str(s)

/// Print an integer to stdout with newline.
pub fn print_int(n: i32) -> void:
    with_println_i32(n)

/// Read a line from stdin (strips trailing newline).
pub fn read_line() -> str:
    with_read_line_stdin()

/// Read exactly N bytes from stdin.
pub fn read_bytes(count: i32) -> str:
    with_read_bytes_stdin(count)

/// Read all of stdin into memory.
pub fn read_all() -> str:
    var out = ""
    while true:
        let chunk = with_read_bytes_stdin(4096)
        if chunk.len() == 0:
            break
        out = out ++ chunk
    out

fn io_strip_trailing_cr(s: str) -> str:
    if s.len() > 0 and s.byte_at(s.len() - 1) == 13:
        return s.slice(0, s.len() - 1)
    s

/// Read stdin as newline-stripped lines.
pub fn Stdin.lines(self: &Self) -> Vec[str]:
    let _ = self
    let raw_lines = lines(read_all())
    let out: Vec[str] = Vec.new()
    for line in raw_lines:
        out.push(io_strip_trailing_cr(line))
    out

/// Write raw bytes to stdout (no newline, no flush).
pub fn write_raw(s: str) -> void:
    with_write_stdout(s)

/// Flush stdout.
pub fn flush() -> void:
    with_flush_stdout()
