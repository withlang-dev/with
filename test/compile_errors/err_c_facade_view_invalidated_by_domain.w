//! expect-check-fail: view `e` borrows from foreign-state domain `errno`, which `note_fail` may have invalidated (§16.2b.7)
//! expect-check-fail: state `preserves domain errno` on fn note_fail in facade notes if it leaves that storage valid, or copy `e` out (`to_owned()`) before the call

// D51 stage 7 (ruling §37: "A value depending on the domain cannot be
// assumed valid across another relevant libc operation unless preservation
// is known"): the diagnostic text borrowed from the `errno` domain is used
// after an operation of the same library that does not preserve it.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain errno process
    fn strerror
        returns borrow CStr from domain errno
    fn note_fail
        lend

fn main:
    let e = strerror(2).unwrap()
    let _ = note_fail(7)
    print(f"{e.len()}")
