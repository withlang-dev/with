//! expect-error: cannot mutate `v` while `staged` is a live view into it

// D69 (§13.4, #1737): a stage chain over a generator whose argument is a
// view keeps that view live while the chain runs, so the viewed place
// cannot be written by a stage's closure nor before the chain is consumed.
use std.generators.{map, collect}

gen fn over(xs: &List[i64]) -> &i64:
    for x in xs:
        yield x

fn main:
    var v: List[i64] = [4, 5, 6]
    let staged = over(&v) |> map(it * 3)
    v.push(7)
    let all = staged |> collect[List]()
    print(all.len())
