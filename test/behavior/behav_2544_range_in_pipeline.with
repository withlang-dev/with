//! expect-stdout: 7 14
//! expect-stdout: 2 4 6
//! expect-stdout: 9 0 4
//! expect-stdout: 3

// #2544 (§4.7, §13.5): a range is a sequence, so it iterates on the left
// of `|>` by the `for` rule (D142), through std's range_iter; a range has
// `iter()`, and its bounds are `start` and `end`. `for` keeps its counter
// loop.
fn span[T](r: Range[T]) -> T: r.end - r.start

fn main:
    let a = (0..10) |> map(it * 2) |> filter(it > 4) |> collect[List]()
    print(f"{a.len()} {a[4]}")
    let b = (1..=3) |> map(it * 2) |> collect[List]()
    print(f"{b[0]} {b[1]} {b[2]}")
    var ri = (0..3).iter()
    var n = 0
    while let Some(x) = ri.next(): n += x + 2
    let r = 0..4
    print(f"{n} {r.start} {r.end}")
    print(f"{span(2..5)}")
