//! expect-stdout: 2 30 40
//! expect-stdout: 3 20 30 40
//! expect-stdout: ok

// #3049 (§16.11): `unsafe { slice(p, len) }` constructs a `[]T` slice view
// from `*mut T` or `*const T` and a length, available from the prelude and
// `std.mem`.

use std.mem

unsafe fn inspect_ptr(p: *mut i32, end: *mut i32):
    let q = p + 2
    assert(q != end)
    p[0] = 42
    let s = slice(q, 2)
    print(f"{s.len()} {s[0]} {s[1]}")

fn main:
    var buf: [i32; 4] = [10, 20, 30, 40]
    let p = &raw mut buf[0]
    unsafe:
        inspect_ptr(p, p + 4)
    assert(buf[0] == 42)
    let cp: *const i32 = &raw const buf[1]
    unsafe:
        let cs = mem.slice(cp, 3)
        print(f"{cs.len()} {cs[0]} {cs[1]} {cs[2]}")
    print("ok")
