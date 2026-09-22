//! expect-check-fail: is a live view

// #1317 / §21.1 rule 1, D44: the loop reads `xs` again on its next
// iteration, so clearing it inside the body is rejected even though `e`
// has no lexical use after the mutation — the borrow lasts the loop.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        print(e.key)
        xs.clear()
