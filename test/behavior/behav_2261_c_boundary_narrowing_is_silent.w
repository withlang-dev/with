//! expect-stdout: 5 5 5 3

// #2261 (§4.2.6, D183; Eric 2026-11-18): an integer that meets a narrower or
// differently signed declaration converts with a range check. Where that
// declaration was imported from C (a parameter, a return, a record field, a
// global) the conversion happens as everywhere else.
use c_import("typedef struct { unsigned int avail; } stream;\nstatic unsigned int c_limit;\nstatic inline unsigned long count_bytes(unsigned long n) { return n; }\nstatic inline unsigned long five(void) { return 5; }\nstatic inline stream stream_new(void) { stream s; s.avail = 0; return s; }\n")

fn main:
    let text = "hello"
    // An argument of a C function.
    let a = count_bytes(text.len())
    // A C function's return into a With declaration.
    let b: isize = five()
    // A field of a C record, written and read.
    var s = stream_new()
    s.avail = text.len()
    let c: i32 = s.avail
    // A C global, written and read.
    unsafe:
        c_limit = text.len() - 2
    let d: i32 = unsafe { c_limit }
    print(f"{a} {b} {c} {d}")
