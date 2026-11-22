//! expect-stdout: 2 8 10
//! expect-stdout: 2 45

// D69 (§13.3, §13.4, #1737): the pipeline stages accept a generator whose
// arguments are views. A stage holds the generator, so it is as ephemeral
// as the generator value; the chain is consumed where the views are live.
use std.generators.{map, filter, take, collect}

gen fn over(xs: &List[i64]) -> &i64:
    for x in xs:
        yield x

fn main:
    let v: List[i64] = [4, 5, 6]
    let firsts = over(&v) |> map(it * 2) |> take(2) |> collect[List]()
    let evens = over(&v) |> filter(*it % 2 == 0) |> map(it * 2) |> collect[List]()
    print(f"{firsts.len()} {firsts[0]} {firsts[1]}")
    let staged = over(&v) |> map(it * 3)
    var total: i64 = 0
    for y in staged:
        total += y
    print(f"{evens.len()} {total}")
