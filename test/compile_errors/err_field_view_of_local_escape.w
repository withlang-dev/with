//! expect-check-fail: returned view may outlive its origin 'kv'

// #1297: a field view keeps its root's origin, and a local's storage dies with
// the call. `&kv.value` is a view of the local `kv`, never of anything that
// outlives `bad`.

enum JV { Null | Str(str) }
type KV { key: str, value: JV }

fn bad() -> &JV:
    let kv = KV { key: "k".clone(), value: .Null }
    &kv.value

fn main:
    print("unreachable")
