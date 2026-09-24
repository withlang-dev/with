//! expect-stdout: error: No such file or directory
//! expect-stdout: after pure: No such file or directory 2
//! expect-stdout: ok

// Ruling §35: a facade "may also merge domains from distinct imports when
// they refer to the same actual state". Two facades over one import each
// declare `domain errno thread`: one errno. `notes` borrows `strerror`'s
// text from it and states `note_pure` preserves it; `checks` describes
// `note_fail` and says nothing, so it invalidates the same domain (the
// refused spelling is err_c_facade_domain_merged_invalidated). The runtime's
// own domain rows (rt/*.w, ruling §52) meet a program's libc facade this
// way in one unit.

use c_import("c_facade_text.h")

c facade notes:
    domain errno thread
    fn strerror
        returns borrow CStr from domain errno
    fn note_pure
        preserves domain errno

c facade checks:
    domain errno thread
    fn note_fail
        lend

fn main:
    let e = strerror(2).unwrap()
    print(f"error: {e.to_str().unwrap()}")
    let two = note_pure(1)
    print(f"after pure: {e.to_str().unwrap()} {two}")
    let _ = note_fail(7)
    print("ok")
