//! expect-stdout: 3 2 1,2,3 a,b,xs hi true 2.5 1
//! expect-stdout: {"a":1,"b":{"c":"hi","t":true,"n":null},"xs":[1,2,3],"f":2.5}
//! expect-stdout: [
//! expect-stdout:   1,
//! expect-stdout:   2,
//! expect-stdout:   3
//! expect-stdout: ]
// #961: a JsonView reads arrays and objects (jq's `.[i]`, `.[]`, `keys`,
// typed values, `-c` and pretty output). The view had raw() and field()
// only; "unknown method 'at' for type 'JsonView'".
use std.json

fn main:
    let d = JsonDocument.parse("{\"a\": 1, \"b\": {\"c\": \"hi\", \"t\": true, \"n\": null}, \"xs\": [1, 2, 3], \"f\": 2.5}")
    let root = d.root()
    let xs = root.field("xs")
    var joined = ""
    for v in xs.items():
        joined = if joined.len() == 0: v.raw() else: joined ++ "," ++ v.raw()
    let keys = root.keys()
    let b = root.field("b")
    print(f"{xs.len()} {xs.at(1).as_i64()} {joined} {keys[0]},{keys[1]},{keys[2]} {b.field("c").as_str()} {b.field("t").as_bool()} {root.field("f").as_f64()} {if b.field("n").is_null(): 1 else: 0}")
    print(root.compact())
    print(xs.pretty())
