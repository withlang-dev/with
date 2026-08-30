//! expect-check-fail: a borrow does not cast to an integer

// D31 (§16.11): `&place as <integer-type>` is a compile error — under the
// D22 §6.2 cast-target demand the `&` would be an unnecessary character
// that only misleads. The fix-it offers both intents:
//   &raw const place as u64   (the address)
//   place as u64              (the value)
fn main:
    var target: [u8; 4] = [65u8, 66u8, 67u8, 0u8]
    let bad = &target[0] as u64
    let _ = bad
