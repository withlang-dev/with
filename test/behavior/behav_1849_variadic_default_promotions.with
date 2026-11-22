//! expect-stdout: -3
//! expect-stdout: 200
//! expect-stdout: -1000
//! expect-stdout: 1
//! expect-stdout: 1.5

// C11 6.5.2.2p7 (#1849): an argument a `...` receives is passed after the
// default argument promotions — an integer narrower than int becomes int
// keeping its sign (or value), a bool becomes int, f32 becomes f64. The i8
// constant -3 was passed as the byte 0xfd, and printf's `%d` read 253.
use std.string.StringBuilder
use c_import("int snprintf(char *buf, unsigned long n, const char *fmt, ...);\n")

fn show(n: c_int, buf: &[16]u8) -> str:
    var out = StringBuilder.new()
    for i in 0..n:
        out.push_byte(buf[i])
    out.to_str()

fn main:
    var buf: [16]u8 = [0 as u8; 16]
    let b: i8 = -3
    let u: u8 = 200
    let s: i16 = -1000
    let flag = true
    let f: f32 = 1.5
    print(show(unsafe { snprintf(&raw mut buf as *mut c_char, 16, c"%d".ptr, b) }, &buf))
    print(show(unsafe { snprintf(&raw mut buf as *mut c_char, 16, c"%d".ptr, u) }, &buf))
    print(show(unsafe { snprintf(&raw mut buf as *mut c_char, 16, c"%d".ptr, s) }, &buf))
    print(show(unsafe { snprintf(&raw mut buf as *mut c_char, 16, c"%d".ptr, flag) }, &buf))
    print(show(unsafe { snprintf(&raw mut buf as *mut c_char, 16, c"%g".ptr, f) }, &buf))
