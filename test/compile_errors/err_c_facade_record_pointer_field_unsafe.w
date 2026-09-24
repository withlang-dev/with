//! expect-check-fail: unsafe function call requires unsafe context

// D66 (spec §16.2b.6): "A pointer-typed field of a borrowed record is not
// modeled by the record's lifetime alone: it stays a raw pointer until a
// field-level facade fact states its contract" — reading `decimal_point`
// yields the raw `*mut i8`; making text of it is the raw surface.
use c_import("../behavior/c_facade_record.h")

c facade records:
    domain locale process
    fn localeconv
        returns borrow lconv from domain locale

fn main:
    let lc = localeconv().unwrap()
    let point = CStr.from_ptr(lc.decimal_point as *const i8)
    print(f"{point.len()}")
