//! expect-error: unexpected indentation

// #1781 (§29.13 Form 2): a line indented deeper than the statement before
// it, with no ':' opening a body, belongs to no block.
fn main:
    let a = 1
        let b = 2
    print(f"{a} {b}")
