//! expect-stdout: ok

let bytes: [2]u8 = [97, 0]
let ptr: *const u8 = &(unsafe (&raw const bytes[0] as *const u8)[0]) as *const u8

fn main:
    assert(unsafe ptr[0] == 97, "annotated top-level runtime initializer")
    print("ok")
