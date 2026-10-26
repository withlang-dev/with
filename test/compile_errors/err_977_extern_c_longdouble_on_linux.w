//! only-on: linux
//! expect-check-fail: `c_longdouble` is f64, and C's `long double` on Linux
// #977 (§16.1, D155): `c_longdouble` is f64 on every target and never crosses
// to C as a wider long double. A hand-written extern naming it was accepted
// on Linux, where C's long double is 16 bytes, and passed a double.
extern fn ld_take(x: c_longdouble) -> c_longdouble

fn main:
    print(sizeof[c_longdouble]())
