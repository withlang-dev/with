//! expect-exit: 0

// #782 arm 2 companion: project BEFORE the destructure, and Copy-only
// tuples stay freely usable after destructuring.

fn pair() -> (i32, str): (42, "x" ++ "")

fn main:
    let t = pair()
    if t.0 != 42:
        return 1
    let (a, b) = t
    if a != 42 or b != "x":
        return 2
    let nums = (1, 2)
    let (x, y) = nums
    // Copy tuple: still whole after destructuring.
    if nums.0 + nums.1 != x + y:
        return 3
    0
