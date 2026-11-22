//! expect-stdout: 7
// §16.3c (#602): a `retains:` c_import param accepts a pointer into caller-owned
// storage kept alive past the call (no str temporary). strlen is marked retained
// only to exercise the owned-argument path; it returns the length of "literal".
// (Uses `match` rather than `.unwrap()` to avoid the unrelated Result-of-Drop
// unwrap double-free, #648.)
use c_import("unsigned long strlen(const char* s);\n", retains: ["strlen(0)"])

fn main:
    match "literal".to_cstring():
        .Ok(c) => print_i32(strlen(c.as_cstr().ptr()) as i32)
        .Err(_) => print("err")
