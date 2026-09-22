//! expect-check-fail: is a live view

// #1317: `continue` starts the next iteration, which reads `xs` through the
// loop's view again — only `break` of that loop or `return` ends it.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        if e.n == 1:
            xs.push(KV { key: "b".clone(), n: 2 })
            continue
        print(e.key)
