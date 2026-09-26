//! expect-check-fail: g.pull() (§13.4: a generator stepped by next() on its own fiber) is not implemented yet (#1725)

// D69 (§13.4) specifies `g.pull()`; until #1725 lands it is a loud error.
gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn main:
    var steps = upto(3).pull()
    print(steps.next().unwrap())
