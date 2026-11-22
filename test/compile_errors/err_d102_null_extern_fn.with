//! expect-check-fail: `null` is not a value of `extern "C" fn(i32) -> i32`; a function pointer that may be null is `Option[extern "C" fn(i32) -> i32]` (§16.6)

// D102 (#2216): `extern "C" fn` is non-null. A null held in the safe type
// could be called from safe code, which trapped with no diagnostic.
fn main:
    let f: extern "C" fn(i32) -> i32 = null
    print(f(1))
