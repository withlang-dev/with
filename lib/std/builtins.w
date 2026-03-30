// std.builtins — ambient user-facing names provided by the prelude.
//
// These are ordinary std declarations. The compiler may still lower some of
// them with intrinsic semantics later, but name resolution should happen
// through imports, not through hardcoded undefined-name allowlists.

extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_println_i64(n: i64) -> void
extern fn with_println_bool(v: bool) -> void
extern fn with_print_str(s: str) -> void
extern fn with_eprint(s: str) -> void
extern fn with_write(s: str) -> void
extern fn with_ewrite(s: str) -> void
extern fn with_panic(msg: str, file: str, line: i32) -> void
extern fn int_to_string(n: i32) -> str

/// Print a string to stdout without a trailing newline.
pub fn print(s: str) -> void:
    with_print_str(s)

/// Print a string to stderr followed by a newline.
pub fn eprint(s: str) -> void:
    with_eprint(s)

/// Write a string to stdout without a trailing newline.
pub fn write(s: str) -> void:
    with_write(s)

/// Write a string to stderr without a trailing newline.
pub fn ewrite(s: str) -> void:
    with_ewrite(s)

/// Print an i32 to stdout followed by a newline.
pub fn print_i32(n: i32) -> void:
    with_println_i32(n)

/// Print an i64 to stdout followed by a newline.
pub fn print_i64(n: i64) -> void:
    with_println_i64(n)

/// Print a bool to stdout followed by a newline.
pub fn print_bool(v: bool) -> void:
    with_println_bool(v)

/// Assert that a condition is true. Panics with `msg` if false.
pub fn assert(cond: bool, msg: str = "assertion failed") -> void:
    if not cond:
        with_panic(msg, "", 0)

/// Assert that a condition is true. Panics with `msg` if false.
pub fn require(cond: bool, msg: str) -> void:
    if not cond:
        with_panic(msg, "", 0)

/// Assert that a condition is true. Panics with `msg` if false.
pub fn check(cond: bool, msg: str) -> void:
    if not cond:
        with_panic(msg, "", 0)
