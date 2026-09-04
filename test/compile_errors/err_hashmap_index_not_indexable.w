//! expect-error: HashMap is not indexable

// #1012: indexing a keyed map with `[k]` reached MIR lowering as a generic
// call with no concrete contract and aborted the compiler with an internal
// BUG. A map lookup may be absent (D22 §3.4: `get` returns Option[&V]);
// `xs[i]` is the positional element place (D27). Sema now says so.
use std.collections.HashMap

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 2)
    let k: i32 = 1
    let hit = m[k]
    let _ = hit
