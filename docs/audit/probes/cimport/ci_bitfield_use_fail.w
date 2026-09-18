use c_import("struct BITS { unsigned int a : 3; unsigned int b : 5; };")
fn main:
    let b = BITS { a: 1, b: 2 }
    print("unreachable")
