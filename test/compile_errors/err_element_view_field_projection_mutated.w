//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406 (§3.4): projecting a field out of an element view keeps the
// element's origin `v`.

type Item { name: str, n: i32 }

fn main:
    var v: Vec[Item] = Vec.new()
    v.push(Item { name: "a".clone(), n: 1 })
    let x = v[0].name
    for i in 0..100:
        v.push(Item { name: "b".clone(), n: 2 })
    print(x)
