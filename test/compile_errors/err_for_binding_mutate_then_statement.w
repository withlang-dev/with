//! expect-check-fail: is a live view

// #1317: a statement after the mutation that neither returns nor breaks
// leaves the loop running, so the next iteration reads the cleared `xs`.

type KV { key: str, n: i32 }

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    for e in xs:
        print(e.key)
        xs.clear()
        print("z")
