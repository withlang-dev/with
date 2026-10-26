//! expect-error: `b` binds a view into a temporary `str` that is freed when this statement ends
//! expect-error: `c` binds a view into a temporary `str` that is freed when this statement ends
// #2659 (§21.1, D22): a view into a temporary is refused through parentheses
// as without them. `(read_file(p) ?? "").trim()` was accepted while
// `read_file(p).unwrap().trim()` was refused, and `b` read freed memory (a
// 141-byte title reached a child process as 142 empty arguments).
use std.fs

fn main:
    let p = "missing.txt"
    let b = (read_file(p) ?? "").trim()
    let c = (read_file(p).unwrap()).trim()
    print(b.len() + c.len())
