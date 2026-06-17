//! expect-error: interior NUL

// §16.3c: a string literal with a proven interior NUL must not coerce to a C
// string — C would silently truncate at the NUL.

use c_import("unsigned long c_nul_strlen(const char *s);\n")

fn main:
    let n = c_nul_strlen("abc\0def")
    print("x")
