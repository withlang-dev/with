//! expect-check-fail: fn 'hold_age' returns i32, not a pointer to 'rec'; 'returns borrow rec' describes the record C points at (§16.2b.6, §16.2b.13)

// D66 (spec §16.2b.6, §16.2b.13): the clause is verified against the
// declaration.
use c_import("../behavior/c_facade_record.h")

c facade records:
    resource Hold wraps *mut hold
        from hold_new
        drop hold_free
    fn hold_age
        returns borrow rec from param 0

fn main:
    print("unreached")
