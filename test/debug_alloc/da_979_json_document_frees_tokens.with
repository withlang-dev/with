//! expect-debug-alloc: leak count=0
//! expect-stdout: 10
// #979: JsonDocument owns the token buffer JsonDocument.parse allocates; it
// had no Drop, so each parse leaked 256 tokens (debug-alloc: leak count=10).
use std.json

fn main:
    var total = 0
    for _ in 0..10:
        let d = JsonDocument.parse("{\"a\": 1}")
        if d.root().field("a").raw() == "1": total += 1
    print(total)
