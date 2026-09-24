//! expect-stdout: error: No such file or directory
//! expect-stdout: error after pure: No such file or directory 2
//! expect-stdout: error after fail: No such file or directory
//! expect-stdout: static: note 1.0
//! expect-stdout: find: llo none
//! expect-stdout: ok

// D51 stage 7, the `errno` domain example (ruling §33, §37: "An operation
// that may set errno mutates this domain. A value depending on the domain
// cannot be assumed valid across another relevant libc operation unless
// preservation is known"; §38, §40). `strerror` is no resource's
// method — its C name is the surface — and returns a text borrowed from the
// domain `errno`: `note_pure` states `preserves domain errno`, so the text
// survives it; `note_fail` states nothing, so the program borrows again
// after it (the refused spelling is err_c_facade_view_invalidated_by_domain).
// `note_version` is static storage, valid for the whole program. `strchr`
// returns text borrowed from the `&str` it is lent (param 0).

use c_import("c_facade_text.h")

c facade notes:
    domain errno process
    fn strerror
        returns borrow CStr from domain errno
    fn note_pure
        preserves domain errno
    fn note_fail
        lend
    fn note_version
        returns static CStr
    fn strchr
        returns borrow CStr from param 0
        preserves domain errno

fn main:
    let e = strerror(2).unwrap()
    print(f"error: {e.to_str().unwrap()}")
    let two = note_pure(1)
    print(f"error after pure: {e.to_str().unwrap()} {two}")
    let _ = note_fail(7)
    print(f"error after fail: {strerror(2).unwrap().to_str().unwrap()}")
    let v = note_version().unwrap()
    print(f"static: {v.to_str().unwrap()}")
    let s = "hello"
    let hit = strchr(s, 'l')
    let miss = strchr(s, 'z')
    print(f"find: {hit.unwrap().to_str().unwrap()} {if miss.is_none(): "none" else: "some"}")
    print("ok")
