//! expect-error: implicit integer narrowing or sign change from `u16` to `u8`

// §4.2.1 (#1820): a suffixed literal never retypes; the unsuffixed 1 takes
// u16 from it, and a u16 sum does not narrow into u8 implicitly.
fn main:
    let x: u8 = 1 + 2u16
    print(f"{x}")
