use c_import("#define PASTE(a, b) a ## b")
fn main:
    let x = PASTE(1, 2)
    print("unreachable")
