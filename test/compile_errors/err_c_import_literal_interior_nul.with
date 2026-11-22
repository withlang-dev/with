//! expect-error: a string literal passed to a C string parameter has an interior NUL byte

// §16.3c: a proven interior NUL is a compile error. C reads a string up to
// its first zero byte, so "ab\0cd" would silently arrive as "ab".

use c_import("unsigned long strlen(const char *s);\n")

fn main:
    let n = strlen("ab\0cd")
    print("unreachable")
