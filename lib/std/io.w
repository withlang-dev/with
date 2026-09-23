// std.io — I/O utility functions
//
// Provides basic I/O operations via the runtime interface.
// No c_import — all operations go through with_* runtime functions.

use std.collections
use std.string

extern fn with_print_str(s: &str) -> Unit
extern fn with_println_str(s: &str) -> Unit
extern fn with_println_i32(n: i32) -> Unit
extern fn with_read_line_stdin() -> str
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_write_stdout(s: &str) -> Unit
extern fn with_flush_stdout() -> Unit

pub type Stdin {
    __tag: i32,
}

pub let stdin: Stdin = Stdin { __tag: 0 }

/// Print a string to stdout (no newline).
pub fn print_str(s: str) -> Unit:
    with_print_str(s)

/// Print a string to stdout with newline.
pub fn print_line(s: str) -> Unit:
    with_println_str(s)

/// Print an integer to stdout with newline.
pub fn print_int(n: i32) -> Unit:
    with_println_i32(n)

/// Read a line from stdin (strips trailing newline).
pub fn read_line() -> str:
    with_read_line_stdin()

/// Read exactly N bytes from stdin.
pub fn read_bytes(count: i32) -> str:
    with_read_bytes_stdin(count)

/// Read all of stdin into memory.
// One growing buffer: `out = out ++ chunk` copied everything read so far on
// every 4 KiB chunk, quadratic in the input (#1352).
pub fn read_all() -> str:
    var out = StringBuilder.new()
    while true:
        let chunk = with_read_bytes_stdin(65536)
        if chunk.len() == 0:
            break
        out.push_str(chunk)
    out.to_str()

/// Read stdin as newline-stripped lines.
// A CRLF line loses its `\r` in place. Draining the split with remove(0)
// shifted every remaining line once per line, quadratic in the line count
// (#1352: `with -n` ran over two minutes on 16 MB).
pub fn Stdin.lines(self: &Self) -> Vec[str]:
    let _ = self
    var out = lines(read_all())
    for i in 0..out.len():
        let n = out[i].len()
        if n > 0 and out[i][n - 1] == '\r':
            out[i] = out[i].slice(0, n - 1)
    out

/// Write raw bytes to stdout (no newline, no flush).
pub fn write_raw(s: str) -> Unit:
    with_write_stdout(s)

/// Flush stdout.
pub fn flush() -> Unit:
    with_flush_stdout()
