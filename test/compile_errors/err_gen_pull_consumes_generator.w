//! expect-check-fail: use of moved value

// D69 (§13.4): a generator value is consumed once; `g.pull()` consumes it.
gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn main:
    let g = upto(3)
    var steps = g.pull()
    print(steps.next().unwrap())
    for x in g:
        print(x)
