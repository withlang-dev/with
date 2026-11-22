//! expect-check-fail: retains the C-string pointer past the call
// §16.3c (#602): a c_import param annotated `retains:` keeps the pointer past
// the call, so a `str` (a call-scoped temporary) is rejected — the caller must
// pass a pointer into owned storage.
use c_import("int ci_retain(const char* s);\n", retains: ["ci_retain(0)"])
use std.builtins.print_i32

fn main:
    let r = ci_retain("literal")
    print_i32(r)
