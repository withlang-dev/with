//! skip-windows: issue #799: c_import behavior fails on native Windows MSVC headers
//! expect-stdout: 0
// §16.3c (#602): a BORROWED c_import cstr param (no retains:) still accepts a
// str — the call-scoped temporary is valid for the duration of the call.
use c_import("int strcmp(const char* a, const char* b);\n")
use std.builtins.print_i32
fn main:
    print_i32(strcmp("a", "a"))
