//! expect-error: call to unsafe function pointer requires unsafe context

// #1832, §16.3c: a call through a C variadic function pointer is raw,
// whether or not its type spells `unsafe`.
use c_import("int snprintf(char *buf, unsigned long n, const char *fmt, ...);\n")

fn main:
    let f: extern "C" fn(*mut c_char, c_ulong, *const c_char, ...) -> c_int = snprintf
    print(f(null, 0, c"%d".ptr, 1))
