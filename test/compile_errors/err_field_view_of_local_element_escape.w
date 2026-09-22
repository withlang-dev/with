//! expect-check-fail: returned view may outlive its origin 'xs'

// #1297: `xs.get(0)` is a view whose origin is the local `xs`; projecting
// `.value` out of it keeps that origin, so the field view cannot escape.

enum JV { Null | Str(str) }
type KV { key: str, value: JV }

fn bad() -> &JV:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "k".clone(), value: .Null })
    &xs.get(0).value

fn main:
    print("unreachable")
