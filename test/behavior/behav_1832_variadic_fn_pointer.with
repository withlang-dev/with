//! expect-stdout: 7/-2
//! expect-stdout: 12-345
//! expect-stdout: 1.5

// #1832, §16.2b.5: `extern "C" fn(A, ..., ...) -> R` is the C variadic
// function-pointer type. A variadic extern used as a value has it; a call
// through it is raw and passes its `...` arguments with the variadic
// convention after the default argument promotions; `unsafe` is implied, so
// both spellings are one type. c_import renders a variadic typedef in this
// spelling, which did not parse ("expected type").
use std.string.StringBuilder
use c_import("int snprintf(char *buf, unsigned long n, const char *fmt, ...);\ntypedef int (*fmt_fn)(char *buf, unsigned long n, const char *fmt, ...);\nstatic inline int fmt_via(fmt_fn f, char *buf) { return f(buf, 16, \"%d-%d\", 12, 345); }\n")

type Formatter { f: extern "C" fn(*mut c_char, c_ulong, *const c_char, ...) -> c_int }

fn show(n: c_int, buf: &[16]u8) -> str:
    var out = StringBuilder.new()
    for i in 0..n:
        out.push_byte(buf[i])
    out.to_str()

fn narrow(x: i8) -> i8: x

fn main:
    var buf: [16]u8 = [0 as u8; 16]
    let f: extern "C" fn(*mut c_char, c_ulong, *const c_char, ...) -> c_int = snprintf
    print(show(unsafe { f(&raw mut buf as *mut c_char, 16, c"%d/%d".ptr, 7, narrow(-2)) }, &buf))
    print(show(unsafe { fmt_via(snprintf, &raw mut buf as *mut c_char) }, &buf))
    let g: unsafe extern "C" fn(*mut c_char, c_ulong, *const c_char, ...) -> c_int = f
    let holder = Formatter { f: g }
    let x: f32 = 1.5
    print(show(unsafe { (holder.f)(&raw mut buf as *mut c_char, 16, c"%g".ptr, x) }, &buf))
