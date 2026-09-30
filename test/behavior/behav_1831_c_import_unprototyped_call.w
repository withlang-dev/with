//! expect-stdout: -0.242268
//! expect-stdout: 0.030604
//! expect-stdout: -12

// #1831: `double jn();` declares no prototype. C calls it with the default
// argument promotions (C11 6.5.2.2p6: i8 -> int keeping its sign, f32 ->
// double) and the fixed-argument convention. c_import spelled it
// `extern fn jn(...)` and called it variadic, which on darwin arm64 put
// every argument on the stack while jn reads x0/d0: the first two lines
// printed 1 and 0.
use c_import("double jn();\nlong strtol();\n")

fn narrow(x: i8) -> i8: x
fn single(x: f32) -> f32: x

fn main:
    print(unsafe { jn(narrow(-1), single(0.5)) })
    print(unsafe { jn(2, 0.5) })
    print(unsafe { strtol(c"-12".ptr, null, narrow(10)) })
