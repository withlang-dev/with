//! expect-check-fail: view `e` borrows from foreign-state domain `errno`, which `note_fail` may have invalidated (§16.2b.7)
//! expect-check-fail: describe note_fail with an fn item in a facade and state `preserves domain errno` if it leaves that storage valid, or copy `e` out (`to_owned()`) before the call

// D51 stage 7 (ruling §34, §38): a library operation the facade does not
// describe still touches every domain of that library — unknown effect
// means invalidate — and the help says how to state otherwise.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain errno process
    fn strerror
        returns borrow CStr from domain errno

fn main:
    let e = strerror(2).unwrap()
    let _ = note_fail(7)
    print(f"{e.len()}")
