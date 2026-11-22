//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #2011: a closure literal passed by value to a generic method call
// (std.generators' `collect` calls `g.each(x => ..)` on a `take` stage)
// moves into the callee. The temp that held it kept its scope-exit drop
// ("drop of _4 after a path reaching it moved it out"); only language
// machinery (`s.spawn(..)`, D63) had its move registered.
use std.generators.{take, collect}

gen fn nums -> i32:
    var i = 0
    while true:
        yield i
        i = i + 1

fn main:
    let v = nums() |> take(3) |> collect[List]()
    print(f"{v.len()}")
