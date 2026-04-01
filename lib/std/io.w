// std.io — I/O utility functions
//
// Provides basic I/O operations via the runtime interface.
// No c_import — all operations go through with_* runtime functions.

extern fn with_print_str(s: str) -> void
extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_read_line_stdin() -> str
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_write_stdout(s: str) -> void
extern fn with_flush_stdout() -> void

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

/// Write raw bytes to stdout (no newline, no flush).
pub fn write_raw(s: str) -> void:
    with_write_stdout(s)

/// Flush stdout.
pub fn flush() -> void:
    with_flush_stdout()
