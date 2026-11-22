//! expect-check-fail: :?

// #1565 (§15.4.8): a struct has no default display, with or without a
// width; the programmer spells `:?`.

type Point { x: i32, y: i32 }

fn main:
    let p = Point { x: 1, y: 2 }
    print(f"[{p:>8}]")
