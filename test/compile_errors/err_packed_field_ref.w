//! expect-error: cannot create reference to packed field

@[repr(packed)]
type P {
    a: u8,
    b: i32,
}

fn main:
    var p = P { a: 1, b: 2 }
    let r = &raw const p.b
    print("x")
