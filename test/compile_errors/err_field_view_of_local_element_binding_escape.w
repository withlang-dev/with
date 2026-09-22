//! expect-check-fail: may outlive its origin

// #1297: the element view bound by `let e = xs.get(0)` and by `for e in xs`
// carries the local `xs` as its origin; `&e.value` inherits it and cannot
// escape either way. (The accepted forms over a `&Vec[KV]` parameter are in
// behav_field_view_of_borrowed_collection_returns.)

enum JV { Null | Str(str) }
type KV { key: str, value: JV }

fn bad_let() -> &JV:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "k".clone(), value: .Null })
    let e = xs.get(0)
    &e.value

fn bad_for() -> &JV:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "k".clone(), value: .Null })
    for e in xs:
        return &e.value
    panic("empty")

fn main:
    print("unreachable")
