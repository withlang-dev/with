//! expect-stdout: ok

// #737: a generic parameter declared `&C` borrows (§3.8) — the plain call
// spelling auto-refs, infers C from the place type, and does NOT consume
// the argument, so the caller keeps using it after the call.

use std.collections

fn count_all[C: Iterable[i32]](c: &C) -> i32:
    var walker = c.iter()
    var n = 0
    while true:
        let nx = walker.next()
        if not nx.is_some():
            break
        n = n + 1
    n

fn peek_first[T](x: &T) -> i64: 1

fn main:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    assert(count_all(v) == 2)
    assert(count_all(&v) == 2)
    let vr = &v
    assert(count_all(vr) == 2)
    assert(v.len() == 2)
    assert(peek_first(v) == 1)
    assert(v.get(0) == 1)
    print("ok")
