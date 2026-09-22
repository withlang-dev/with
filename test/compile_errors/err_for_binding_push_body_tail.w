//! expect-check-fail: is a live view

// #1317: the push is the body's last statement and `e` has no use after it,
// but the next iteration reads `xs` through the loop's view again. `print`
// is generic; its first instantiation checked its body in the middle of this
// one and discarded this body's borrow of `xs`, so this compiled.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        print(e.key)
        xs.push(KV { key: "b".clone(), n: 2 })
