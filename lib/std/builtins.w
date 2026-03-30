// std.builtins — ambient user-facing names provided by the prelude.
//
// These are ordinary std declarations. The compiler may still lower some of
// them with intrinsic semantics later, but name resolution should happen
// through imports, not through hardcoded undefined-name allowlists.

extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_println_i64(n: i64) -> void
extern fn with_println_bool(v: bool) -> void
extern fn with_eprint(s: str) -> void
extern fn with_write(s: str) -> void
extern fn with_ewrite(s: str) -> void
extern fn with_panic(msg: str, file: str, line: i32) -> void
extern fn int_to_string(n: i32) -> str

// print: stdout + newline
pub fn print(s: str) -> void:
    with_println_str(s)

// eprint: stderr + newline
pub fn eprint(s: str) -> void:
    with_eprint(s)

// write: stdout, no newline
pub fn write(s: str) -> void:
    with_write(s)

// ewrite: stderr, no newline
pub fn ewrite(s: str) -> void:
    with_ewrite(s)

pub fn print_i32(n: i32) -> void:
    with_println_i32(n)

pub fn print_i64(n: i64) -> void:
    with_println_i64(n)

pub fn print_bool(v: bool) -> void:
    with_println_bool(v)

pub fn assert(cond: bool, msg: str = "assertion failed") -> void:
    if not cond:
        with_panic(msg, "", 0)

pub fn require(cond: bool, msg: str) -> void:
    if not cond:
        with_panic(msg, "", 0)

pub fn check(cond: bool, msg: str) -> void:
    if not cond:
        with_panic(msg, "", 0)
