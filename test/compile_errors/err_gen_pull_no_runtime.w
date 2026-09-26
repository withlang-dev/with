//! expect-error: g.pull() requires the fiber runtime
//! args: --no-runtime

// D69 (§13.4 Pulling): pull() allocates a fiber stack, so it is unavailable
// in no_runtime builds.
gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn main:
    var steps = upto(3).pull()
    print(steps.next().unwrap())
