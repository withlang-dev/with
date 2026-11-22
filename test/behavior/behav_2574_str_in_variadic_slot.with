//! expect-stdout: compress|7 compress|8

// #2574 (§16.3c): a `str` in a variadic C slot is lent as its NUL-terminated
// pointer, as a `*const c_char` parameter lends it; passed as its fat value,
// C read the length word as the next argument.
use std.libc
fn main:
    printf(c"%s|%d ".ptr, "compress", 7)
    printf(c"%s|%d\n".ptr, c"compress".ptr, 8)
