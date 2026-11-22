//! expect-build-stderr-not: narrows to

// #2261 (Eric 2026-11-18): the D183 warning names a declaration to widen.
// Where that declaration is a C header's, the programmer cannot widen it
// and `as` would remove the check, so nothing is said. The build is quiet.
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
