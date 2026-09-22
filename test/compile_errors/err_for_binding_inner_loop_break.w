//! expect-check-fail: is a live view

// #1317: the `break` after the push ends the inner `while`, not the `for`
// that views `xs`, so the next `for` iteration reads the grown buffer.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        while true:
            xs.push(KV { key: "b".clone(), n: 2 })
            break
        print(e.key)
