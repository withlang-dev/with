//! expect-check-fail: cannot mutate `c` while `g` is a live view into it

// D69 (§13.4, #1724): a generator method's generator value holds a view of
// its borrowed receiver, so the receiver cannot change while the value is
// live.
type Counter {
    n: i32,
}

impl Counter:
    gen fn upto() -> i32:
        for i in 0..self.n:
            yield i

fn main:
    var c = Counter { n: 3 }
    let g = c.upto()
    c.n = 10
    for i in g:
        print(i)
