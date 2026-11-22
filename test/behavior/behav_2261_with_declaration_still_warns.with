//! expect-build-stderr: `isize` narrows to `i32` with a range check: widen the `i32` declaration it flows into, or write `as i32` for the wrap (§4.2.6, D183)

// #2261: the warning stays where the narrower declaration is the program's
// own, since widening it is real advice there.
fn main:
    let text = "hello"
    let n: i32 = text.len()
    print(n)
