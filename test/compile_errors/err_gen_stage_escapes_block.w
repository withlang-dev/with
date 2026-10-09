//! expect-error: view may outlive its origin 'v', which is dropped at the end of this block

// D69 (§13.4, §5.2, #1737): a stage over a generator whose argument views a
// block-local place is as ephemeral as that generator value: it cannot
// leave the block. The inner block's tail is an ephemeral VALUE, judged
// exactly as a tail view is.
use std.generators.{map, collect}

gen fn over(xs: &List[i64]) -> &i64:
    for x in xs:
        yield x

fn main:
    let staged = {
        let v: List[i64] = [4, 5, 6]
        over(&v) |> map(it * 3)
    }
    let all = staged |> collect[List]()
    print(all.len())
