//! expect-error: constant `BIG` does not fit `u8`

// D88 (§4.2.1): an untyped constant is typed as its initializer would be at
// each use, so a use that demands a type its value does not fit is an
// error there, as the literal would be.

const BIG = 200 + 100

fn main:
    let b: u8 = BIG
    print(f"{b}")
