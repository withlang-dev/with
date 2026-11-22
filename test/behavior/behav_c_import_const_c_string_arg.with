//! expect-stdout: ok

// §16.3c, D47: a `str` is lent to a c_imported `const char *` parameter as
// NUL-terminated input text, a literal and a runtime string alike.

use c_import("unsigned long strlen(const char *s);\n")

fn main:
    assert(strlen("hello") == 5usize)
    let s = f"abc{1}"
    assert(strlen(s) == 4usize)
    print("ok")
