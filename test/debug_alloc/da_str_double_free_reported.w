//! expect-debug-alloc: DOUBLE FREE
// #1363: the str drop path frees only a pointer that is an owned payload
// start. Whether a freed small block still passes that check depends on the
// heap's layout; when it does not, a second free of a str buffer was a silent
// no-op — `read_file(p).unwrap_or("")` freed its result twice under
// `leak count=0`. The ledger now decides: a str naming a freed block is a
// DOUBLE FREE whichever way the ownership check falls.
use std.fs
extern fn with_str_free(s: *mut u8)
fn main:
    let path = "out/tmp/da_str_double_free_reported.txt"
    let _mk = mkdir_p("out/tmp")
    let _w = write_file(path, "hello world small file payload")
    let s = read_file(path) ?? ""
    let _rm = remove_file(path)
    unsafe:
        var alias = *(&raw const s)
        with_str_free(&raw mut alias as *mut u8)
