//! expect-error: return type mismatch

// #1229: a returned slice of an array literal would view a dead temporary.
// The literal is its array type; it does not become a slice on the way out.
fn view() -> []i32: [1, 2]

fn main:
    print(f"{view()[0]}")
