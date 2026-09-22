//! expect-stdout: 2
//! expect-stdout: 2
//! expect-stdout: a
//! expect-stdout: b
//! expect-stdout: 3

// #1317: the loop binding's borrow is keyed on the iterated place's field
// path, so a loop over `self.items` may write a disjoint field, a loop over
// `xs` may push onto another collection, and `xs` is writable again once
// the loop ends.

type KV { key: str, n: i32 }
type Bag { items: Vec[KV], count: i32 }

impl Bag:
    mut fn tally():
        for e in self.items:
            self.count += e.n

fn main:
    var b = Bag { items: Vec.new(), count: 0 }
    b.items.push(KV { key: "a".clone(), n: 1 })
    b.items.push(KV { key: "b".clone(), n: 1 })
    b.tally()
    print(f"{b.count}")
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    xs.push(KV { key: "b".clone(), n: 2 })
    var keys: Vec[str] = Vec.new()
    for e in xs:
        keys.push(e.key.clone())
    for e in xs.iter():
        b.count += 0
    print(f"{keys.len()}")
    for k in keys:
        print(k)
    xs.push(KV { key: "c".clone(), n: 3 })
    print(f"{xs.len()}")
