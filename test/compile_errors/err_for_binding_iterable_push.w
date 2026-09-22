//! expect-check-fail: is a live view

// #1317 / §21.1 rule 1, D44: `for e in xs` is `xs.iter()`, so `e` is a live
// view into `xs` for the whole loop. Pushing onto `xs` inside the body can
// reallocate the buffer `e` points into; the loop binding registered no
// borrow, so this compiled and read `e.key` through freed memory.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        xs.push(KV { key: "b".clone(), n: 2 })
        print(e.key)
