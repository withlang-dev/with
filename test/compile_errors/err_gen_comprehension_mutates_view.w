//! expect-check-fail: cannot mutate `c` while `over(…)` is a live view into it

// D69 (§13.4, §21.1, #1734): a comprehension clause over a generator runs the rest of
// the comprehension while the generator runs, so its element cannot mutate a
// place the generator views.
type Counter {
    items: Vec[i32],
}

impl Counter:
    mut fn add(x: i32) -> i32:
        self.items.push(x)
        x

gen fn over(xs: &Vec[i32]) -> i32:
    for x in xs:
        yield x

fn main:
    var c = Counter { items: [1, 2, 3] }
    let v = [c.add(x) for x in over(&c.items)]
    print(v.len())
