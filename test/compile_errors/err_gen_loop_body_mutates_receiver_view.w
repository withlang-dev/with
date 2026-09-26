//! expect-check-fail: cannot mutate `c` while `c.walk(…)` is a live view into it

// D69 (§13.4, §21.1, #1734): a generator method holds a view of its borrowed receiver;
// the body cannot mutate the receiver while the producer walks it — not even
// right before a `break`, since the stopped generator still leaves through
// its own scopes.
type Counter {
    items: Vec[i32],
}

impl Counter:
    gen fn walk() -> i32:
        for x in self.items:
            yield x

fn main:
    var c = Counter { items: [1, 2, 3] }
    for x in c.walk():
        if x == 2:
            c.items.push(9)
            break
    print(c.items.len())
