//! expect-check-fail: g.pull() of generator 'labels': this yield hands out a view of the generator's own local

// D69 (§13.4 Pulling): next() returns an element its caller keeps, so a
// generator that yields a view of its own locals cannot be pulled; the
// error names the yield.
gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf

fn main:
    var steps = labels(2).pull()
    print(steps.next().unwrap())
