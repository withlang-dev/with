//! expect-stdout: [42]
// §29.13/§13.5b (#640): a function whose tail expression follows a labeled
// statement returns the tail value, not the type default. (Was [0].)
fn f() -> i32:
    let s = 42
    'done:
        s
fn main:
    print(f"[{f()}]")
