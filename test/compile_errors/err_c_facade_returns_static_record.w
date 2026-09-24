//! expect-check-fail: fn 'localeconv': 'returns static lconv' — only 'returns static CStr' is ruled (§16.2b.7); a static pointer of another type stays as C declares it

// D66: "static" stays the strongest case and CStr-only; a record C keeps
// in static storage borrows from a domain (`returns borrow lconv from
// domain locale`), never `returns static lconv`.
use c_import("../behavior/c_facade_record.h")

c facade records:
    fn localeconv
        returns static lconv

fn main:
    print("unreached")
