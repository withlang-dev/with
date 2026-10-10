//! expect-stdout: 5 6 4

// §4.2.1 rule 1 (D114): a demanded range types its untyped bounds, as a
// demanded collection types its elements; `2..7` bound as a `Range[i32]` is
// one, never a Range[isize] refused by the annotation.
fn count(r: Range[i32]) -> i32:
    var n: i32 = 0
    for _ in r: n += 1
    n

fn main:
    let half: Range[i32] = 2..7
    let closed: RangeInclusive[i32] = 2..=7
    var m: i32 = 0
    for _ in closed: m += 1
    print(f"{count(half)} {m} {count(1..5)}")
