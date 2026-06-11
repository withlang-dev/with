//! expect-stdout: ok

use c_import("unsigned long strlen(const char *s);\n")

fn main:
    assert(strlen("hello") == 5usize)
    let s = f"abc{1}"
    assert(strlen(s) == 4usize)
    print("ok")
