//! expect-error: use of moved value
//! expect-check-fail-not: shadowing
// #1741 (§13.4 "A generator value is consumed once", §2.2): `g |> take(1)`
// is `take(g, 1)`, whose by-value parameter consumes `g`; the pipeline
// spelling never marked it moved, so the loop below ran over the blanked
// value and printed nothing.

use std.generators.{take, collect}

gen fn words(all: List[str]) -> str:
    for s in all:
        yield s

fn main:
    let g = words(["a".clone(), "b".clone()])
    let v = g |> take(1) |> collect()
    print(v.len())
    for x in g:
        print(x)
