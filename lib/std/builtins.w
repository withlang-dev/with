// std.builtins — ambient user-facing names provided by the prelude.
//
// These are ordinary std declarations. The compiler may still lower some of
// them with intrinsic semantics later, but name resolution should happen
// through imports, not through hardcoded undefined-name allowlists.

// Opaque C void type for pointer interop (void * → *mut c_void).
// Provided here so c_import users don't depend on symbol scoping.
pub type c_void = opaque

extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_println_i64(n: i64) -> void
extern fn with_println_bool(v: bool) -> void
extern fn with_print_str(s: str) -> void
extern fn with_eprint(s: str) -> void
extern fn with_write(s: str) -> void
extern fn with_ewrite(s: str) -> void
extern fn with_panic(msg: str, file: str, line: i32) -> void
extern fn with_i32_to_str(n: i32) -> str
extern fn with_i64_to_str(n: i64) -> str
extern fn with_fmt_u32(n: u32) -> str
extern fn with_fmt_u64(n: u64) -> str
extern fn with_bool_to_str(b: bool) -> str

/// Print a string to stdout followed by a newline.
pub fn print(s: str) -> void:
    with_println_str(s)

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
pub fn assert(cond: bool, msg: str = "assertion failed", loc: str = src()) -> void:
    if not cond:
        with_panic(msg, loc, 0)

/// Assert that a condition is true. Panics with `msg` if false.
pub fn require(cond: bool, msg: str, loc: str = src()) -> void:
    if not cond:
        with_panic(msg, loc, 0)

/// Assert that a condition is true. Panics with `msg` if false.
pub fn check(cond: bool, msg: str, loc: str = src()) -> void:
    if not cond:
        with_panic(msg, loc, 0)

// ── ToString trait and impls ────────────────────────────────────

pub trait ToString =
    fn to_string(self: &Self) -> str

impl ToString for i32 =
    fn to_string(self: &i32) -> str:
        with_i64_to_str(*self as i64)

impl ToString for i64 =
    fn to_string(self: &i64) -> str:
        with_i64_to_str(*self)

impl ToString for u32 =
    fn to_string(self: &u32) -> str:
        with_fmt_u32(*self)

impl ToString for u64 =
    fn to_string(self: &u64) -> str:
        with_fmt_u64(*self)

impl ToString for bool =
    fn to_string(self: &bool) -> str:
        with_bool_to_str(*self)

// Generic free function — call as int_to_string(x) for any numeric type.
pub fn int_to_string(n: i64) -> str:
    with_i64_to_str(n)
