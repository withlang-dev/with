//! expect-check-fail: wrong argument type in call to 'count'

// A range holds its bounds at its element type, so a `Range[isize]` is not
// a `Range[i32]` (D114: `2..7` bound to a local is a Range[isize]). It was
// accepted and reached codegen as `{i64, i64, i1}` for `{i32, i32, i1}`.
fn count(r: Range[i32]) -> i32:
    var n: i32 = 0
    for _ in r: n += 1
    n

fn main:
    let half = 2..7
    print(count(half))
