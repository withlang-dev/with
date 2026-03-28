// std.builtins — ambient user-facing names provided by the prelude.
//
// These are ordinary std declarations. The compiler may still lower some of
// them with intrinsic semantics later, but name resolution should happen
// through imports, not through hardcoded undefined-name allowlists.

extern fn print(s: str) -> void
extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_println_i64(n: i64) -> void
extern fn with_println_bool(v: bool) -> void
extern fn with_panic(msg: str, file: str, line: i32) -> void
extern fn int_to_string(n: i32) -> str

pub fn println(s: str) -> void:
    with_println_str(s)

pub fn println_i32(n: i32) -> void:
    with_println_i32(n)

pub fn println_i64(n: i64) -> void:
    with_println_i64(n)

pub fn println_bool(v: bool) -> void:
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
