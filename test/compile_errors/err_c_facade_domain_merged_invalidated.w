//! expect-check-fail: state `preserves domain errno` on fn note_fail in facade checks if it leaves that storage valid, or copy `e` out (`to_owned()`) before the call

// Ruling §35: two facades declaring `domain errno thread` name one errno.
// `checks` describes `note_fail` and states nothing about the domain, so
// the call invalidates the text `notes` borrowed from it (§38: unknown
// effect means invalidate) — the merge is real, not two unrelated domains
// (behav_c_facade_domain_merged is the accepted spelling).

use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain errno thread
    fn strerror
        returns borrow CStr from domain errno

c facade checks:
    domain errno thread
    fn note_fail
        lend

fn main:
    let e = strerror(2).unwrap()
    let _ = note_fail(7)
    print(f"stale: {e.to_str().unwrap()}")
