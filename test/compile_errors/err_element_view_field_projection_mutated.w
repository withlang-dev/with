//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406 (§3.4): projecting a field out of an element view keeps the
// element's origin `v`. A Vec field, not a str: binding a Copy field copies
// it, as an i32 field does (D111).

type Item { items: Vec[i32], n: i32 }

fn main:
    var v: Vec[Item] = Vec.new()
    v.push(Item { items: [1], n: 1 })
    let x = v[0].items
    for i in 0..100:
        v.push(Item { items: [2], n: 2 })
    print(x.len())
