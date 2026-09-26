//! expect-stdout: title a+b lines 2
//! expect-stdout: count 3 items 3
//! expect-stdout: other 6 xs 3
//! expect-stdout: after 4

// D69 (§13.4, §21.1, #1734): a generator's views are live for the loop over
// it, path-precisely (#1530): the body may write a sibling field of the
// viewed field and any place the generator does not view, and may read what
// it views. After the loop the viewed place is free again.
type Doc {
    lines: Vec[str],
    title: str,
}

type Counter {
    items: Vec[i32],
}

impl Counter:
    gen fn walk() -> i32:
        for x in self.items:
            yield x

gen fn each_line(lines: &Vec[str]) -> &str:
    for line in lines:
        yield line

gen fn over(xs: &Vec[i32]) -> i32:
    for x in xs:
        yield x

fn main:
    var d = Doc { lines: ["a".clone(), "b".clone()], title: "".clone() }
    for l in each_line(&d.lines):
        d.title = if d.title.len() == 0: l.clone() else: d.title ++ "+" ++ l
    print(f"title {d.title} lines {d.lines.len()}")

    let c = Counter { items: [1, 2, 3] }
    var count = 0
    for x in c.walk():
        count += 1
    print(f"count {count} items {c.items.len()}")

    var xs: Vec[i32] = [1, 2, 3]
    var other: Vec[i32] = []
    var sum = 0
    for x in over(&xs):
        other.push(x)
        sum += x
    print(f"other {sum} xs {other.len()}")
    xs.push(4)
    print(f"after {xs.len()}")
