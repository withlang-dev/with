//! expect-error: not C-ABI-expressible

// §16.5: exporting a function that takes a non-@[repr(C)] struct by value has
// no defined C layout.

type Plain { x: i32, y: i32 }

@[c_export("take_plain")]
fn take_plain(p: Plain) -> i32:
    p.x

fn main:
    print("x")
