//! expect-error: expected ':' or '{' to introduce body
// D39: bodyless declarations exist only in interface input (.wi); ordinary
// source never acquires C-header-style forward declarations.
pub fn forward(x: i32) -> i32

fn main:
    print("x")
