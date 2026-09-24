//! expect-stdout: after pure: No such file or directory 2
//! expect-stdout: ok

// Two facade blocks describing one function word for word state the same
// facts once: the runtime's files each carry a block that names
// `rt_libc_exit` identically and meet in one unit (D30 rt-in-unit, ruling
// §52). A restatement with different clauses is refused
// (err_c_facade_fn_restated_differently).

use c_import("c_facade_text.h")

c facade notes:
    domain errno thread
    fn strerror
        returns borrow CStr from domain errno
    fn note_pure
        preserves domain errno

c facade notes_again:
    domain errno thread
    fn note_pure
        preserves domain errno

fn main:
    let e = strerror(2).unwrap()
    let two = note_pure(1)
    print(f"after pure: {e.to_str().unwrap()} {two}")
    print("ok")
