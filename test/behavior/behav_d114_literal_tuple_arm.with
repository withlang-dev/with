//! expect-stdout: 7 3

// D114 (§4.2.1 through an aggregate, #1996): a tuple of untyped literals as a
// join arm takes the typed arm's tuple type, as a bare literal arm takes a
// number's; `(1, 0)` beside an `(i32, i32)` was `(isize, isize)` and the
// join reached MIR with two tuple types.
fn take(x: i32): x

fn line_col(x: i32) -> (i32, i32): (x, x + 1)

fn main:
    let off: i32 = 3
    let (line, col) = if off > 0: line_col(off) else: (1, 0)
    let (none_line, none_col) = if off < 0: line_col(off) else: (1, 2)
    print(f"{take(line) + take(col)} {take(none_line) + take(none_col)}")
