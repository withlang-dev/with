//! expect-check-fail: returned view may outlive its origin 'h'

// D66 (spec §16.2b.6): "a view whose lifetime is its origin's … cannot be
// stored beyond its origin".
use c_import("../behavior/c_facade_record.h")

c facade records:
    resource Hold wraps *mut hold
        from hold_new
        drop hold_free
    fn hold_rec
        returns borrow rec from param 0

fn peek() -> &rec:
    let h = Hold.new(3).unwrap()
    h.rec().unwrap()

fn main:
    print(f"{peek().age}")
