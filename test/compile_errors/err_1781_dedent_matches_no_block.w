//! expect-error: unexpected indentation

// #1781 (§29.13 Form 2): a block's statements share its column. The `if`
// body takes column 12 from its first line; the `print` at column 8 matches
// no enclosing block (main's body is at 4). It used to join main's body
// silently and run with `c` false, reading `x` from the arm that never ran.
fn main:
    let c = false
    if c:
            let x = 1
        print(f"inner {x}")
    print("end")
