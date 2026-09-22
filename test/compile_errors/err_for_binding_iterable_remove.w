//! expect-check-fail: is a live view

// #1317 / §21.1 rule 1, D44: `remove` transfers an element out of the
// collection the loop binding views; the binding may now point at a
// shifted or freed slot.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        if e.n == 1:
            xs.remove(0)
        print(e.key)
