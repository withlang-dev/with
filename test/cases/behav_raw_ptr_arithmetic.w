//! expect-stdout: ok

use c_import("stdlib.h")

fn main:
    let raw = malloc(16)
    let ptr = raw as *mut i32
    unsafe:
        let p1 = ptr + 1
        *ptr = 7
        *p1 = 9
        *(ptr + 2) = 11
    assert(unsafe: *ptr == 7)
    assert(unsafe: *(ptr + 1) == 9)
    assert(unsafe: *(ptr + 2) == 11)
    let _ = realloc(raw, 0)
    print("ok")
