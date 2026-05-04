//! expect-check-pass

const A: i32 = comptime 1 + 1

fn main:
    // comptime inline colon
    let x: i32 = comptime: 2 + 2

    // comptime indented colon
    let y: i32 = comptime:
        3 + 3

    // comptime braced
    let z: i32 = comptime { 4 + 4 }

    // comptime as expression prefix (no colon — should still work)
    let w: i32 = comptime 5 + 5
