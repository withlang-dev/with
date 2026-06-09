//! expect-error: wrong argument type

use c_import("unsigned long strlen(const char *s);\n")

fn main:
    let s = f"abc{1}"
    let _ = unsafe { strlen(s) }
