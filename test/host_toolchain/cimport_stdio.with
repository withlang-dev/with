//! expect-stdout: SEEK_END 2, abs 42

// #1915 (:no-host-toolchain): c_import of libc headers reads the compiler's
// own darwin sysroot, and the program links against its libSystem stub.

use c_import("stdio.h")
use c_import("stdlib.h")

fn main:
    print(f"SEEK_END {SEEK_END}, abs {abs(-42)}")
