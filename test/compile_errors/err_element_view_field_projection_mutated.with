//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406 (§3.4): projecting a field out of an element view keeps the
// element's origin `v`. A List field, not a str: binding a Copy field copies
// it, as an i32 field does (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Item { items: List[Tok], n: i32 }

fn main:
    var v: List[Item] = List.new()
    v.push(Item { items: [Tok { id: 1 }], n: 1 })
    let x = v[0].items
    for i in 0..100:
        v.push(Item { items: [Tok { id: 2 }], n: 2 })
    print(x.len())
