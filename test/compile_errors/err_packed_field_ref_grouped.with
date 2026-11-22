//! expect-error: cannot create reference to packed field

@[repr(packed)]
type Packed {
    a: u8,
    b: i32,
}

fn main:
    var packed = Packed { a: 1, b: 2 }
    let ptr = &raw const (packed.b)
    print("no")
