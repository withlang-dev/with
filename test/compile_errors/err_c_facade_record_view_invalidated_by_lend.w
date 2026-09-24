//! expect-check-fail: view `r` borrows from `h`, which `hold_bump` may have invalidated (§16.2b.7)

// D66 (spec §16.2b.6): a record view backed by a resource is invalidated
// by the resource's operations that state no preservation (§16.2b.7:
// unknown effect means invalidate).
use c_import("../behavior/c_facade_record.h")

c facade records:
    resource Hold wraps *mut hold
        from hold_new
        drop hold_free
    fn hold_rec
        returns borrow rec from param 0
    fn hold_bump
        lend

fn main:
    let h = Hold.new(3).unwrap()
    let r = h.rec().unwrap()
    h.bump()
    print(f"{r.version_num}")
